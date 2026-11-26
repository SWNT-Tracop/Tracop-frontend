import 'package:dio/dio.dart';

import '../../../../core/result/result.dart';
import '../../domain/entities/payment.dart';
import '../../domain/proof_upload_cancellation.dart';
import '../../domain/repository/payment_repository.dart';
import '../remote/payment_remote.dart';

/// Pagos siempre en línea: no se cachean en drift ni se encolan, porque
/// incluyen URLs firmadas (`proofUrl`) y dependen del estado del servidor.
class PaymentRepositoryImpl implements PaymentRepository {
  PaymentRepositoryImpl({required this.remote});

  final PaymentRemoteDataSource remote;

  @override
  Future<Result<Payment?, DomainFailure>> getForOrder(String orderId) async {
    try {
      return Ok(Payment.fromJson(await remote.getForOrder(orderId)));
    } on Object catch (error) {
      final failure = paymentFailure(error);
      // 404: el pedido todavía no tiene pago (o no es visible para el actor).
      if (failure.statusCode == 404) return const Ok(null);
      return Err(failure);
    }
  }

  @override
  Future<Result<Payment, DomainFailure>> getById(String paymentId) =>
      _payment(() => remote.getById(paymentId));

  @override
  Future<Result<Payment, DomainFailure>> initiate({
    required String orderId,
    required String paymentId,
    required PaymentMethod method,
  }) =>
      _payment(() => remote.initiate(orderId, {
            'id': paymentId,
            'method': method.wire,
          }));

  @override
  Future<Result<Payment, DomainFailure>> uploadProof(
      String paymentId, ProofFile file,
      {ProofUploadCancellation? cancellation}) async {
    // Un token por carga: al cancelar se corta el POST al almacenamiento.
    final cancelToken = CancelToken();
    cancellation?.whenCancelled.then((_) {
      if (!cancelToken.isCancelled) cancelToken.cancel();
    });
    bool cancelled() => cancellation?.isCancelled ?? false;
    // Dos intentos como máximo: si la autorización venció (403 del
    // almacenamiento o 410 en la confirmación) se pide una nueva una vez.
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        if (cancelled()) return const Err(_cancelledFailure);
        final policy = ProofUploadPolicy.fromJson(
            await remote.requestProofUpload(paymentId));
        if (cancelled()) return const Err(_cancelledFailure);
        await _sendToStorage(policy, file, cancelToken);
        // La confirmación no se cancela a mitad de camino (el servidor
        // podría registrarla igual); solo no se inicia si ya se canceló. El
        // objeto subido sin confirmar no cambia el pago.
        if (cancelled()) return const Err(_cancelledFailure);
        return Ok(Payment.fromJson(await remote.confirmProof(paymentId)));
      } on _PolicyExpired {
        continue;
      } on _UploadCancelled {
        return const Err(_cancelledFailure);
      } on Object catch (error) {
        final failure = paymentFailure(error);
        if (failure.code == 'proof_expired') continue;
        if (failure.code == 'proof_upload_missing' ||
            failure.code == 'invalid_transition') {
          // Reintento tras una confirmación cuya respuesta se perdió: solo es
          // éxito si el pago está en un estado al que se llega con el
          // comprobante registrado. `rejected`, `refunded` o un estado
          // desconocido no confirman esta carga.
          final current = await getById(paymentId);
          if (current case Ok(value: final payment)
              when proofRegisteredStatuses.contains(payment.status)) {
            return Ok(payment);
          }
        }
        return Err(failure);
      }
    }
    return const Err(DomainFailure(
      statusCode: 410,
      code: 'proof_expired',
      message: 'La autorización para cargar el comprobante venció.',
    ));
  }

  Future<void> _sendToStorage(
      ProofUploadPolicy policy, ProofFile file, CancelToken cancelToken) async {
    try {
      await remote.uploadProofObject(
        url: policy.url,
        fields: policy.fields,
        filename: file.filename,
        bytes: file.bytes,
        cancelToken: cancelToken,
      );
    } on DioException catch (error) {
      if (error.type == DioExceptionType.cancel) throw const _UploadCancelled();
      // Errores del almacenamiento externo: su mensaje incluye la URL
      // firmada, así que se traducen a un código sin conservar el detalle.
      final status = error.response?.statusCode;
      final body = '${error.response?.data ?? ''}'.toLowerCase();
      // S3 responde 403 AccessDenied con "Request has expired" o
      // "Policy expired". Otros 403 no se tratan como vencimiento.
      if (status == 403 && body.contains('expired')) {
        throw const _PolicyExpired();
      }
      if (status == 400 && body.contains('entitytoolarge')) {
        throw const DomainFailure(
          statusCode: 422,
          code: 'proof_size_invalid',
          message: 'El comprobante supera el tamaño permitido.',
        );
      }
      if (error.response == null) {
        throw DomainFailure(
          statusCode: 503,
          code: _isOffline(error) ? 'offline' : 'network_error',
          message: 'No se pudo conectar con el almacenamiento.',
        );
      }
      throw const DomainFailure(
        statusCode: 502,
        code: 'storage_upload_failed',
        message: 'No se pudo cargar el comprobante al almacenamiento.',
      );
    }
  }

  @override
  Future<Result<Payment, DomainFailure>> dispute(
          String paymentId, int expectedVersion, String reason) =>
      _payment(() => remote.dispute(paymentId, {
            'expectedVersion': expectedVersion,
            'reason': reason.trim(),
          }));

  @override
  Future<Result<List<Payment>, DomainFailure>> reviewQueue(
      {int limit = 100}) async {
    try {
      final json = await remote.reviewQueue(limit.clamp(1, 100));
      return Ok((json['items'] as List)
          .map((item) =>
              Payment.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(growable: false));
    } on Object catch (error) {
      return Err(paymentFailure(error));
    }
  }

  @override
  Future<Result<Payment, DomainFailure>> verify(
          String paymentId, int expectedVersion) =>
      _payment(
          () => remote.verify(paymentId, {'expectedVersion': expectedVersion}));

  @override
  Future<Result<Payment, DomainFailure>> reject(
          String paymentId, int expectedVersion, String reason) =>
      _payment(() => remote.reject(paymentId, {
            'expectedVersion': expectedVersion,
            'reason': reason.trim(),
          }));

  @override
  Future<Result<Payment, DomainFailure>> resolveDispute(
    String paymentId,
    int expectedVersion,
    DisputeOutcome outcome,
    String note,
  ) =>
      _payment(() => remote.resolveDispute(paymentId, {
            'expectedVersion': expectedVersion,
            'outcome': outcome.wire,
            'note': note.trim(),
          }));

  Future<Result<Payment, DomainFailure>> _payment(
      Future<Map<String, dynamic>> Function() call) async {
    try {
      return Ok(Payment.fromJson(await call()));
    } on Object catch (error) {
      return Err(paymentFailure(error));
    }
  }
}

/// Estados que implican que el comprobante quedó registrado.
const proofRegisteredStatuses = {
  PaymentStatus.proofUploaded,
  PaymentStatus.verified,
  PaymentStatus.held,
  PaymentStatus.settled,
  PaymentStatus.disputed,
};

class _PolicyExpired implements Exception {
  const _PolicyExpired();
}

class _UploadCancelled implements Exception {
  const _UploadCancelled();
}

/// Resultado de una carga cancelada por el usuario (no es un error).
const _cancelledFailure = DomainFailure(
  statusCode: 499,
  code: proofUploadCancelledCode,
  message: 'Carga cancelada.',
);

bool _isOffline(DioException error) =>
    error.type == DioExceptionType.connectionError ||
    error.type == DioExceptionType.connectionTimeout;

/// Convierte cualquier error en `DomainFailure` sin copiar mensajes técnicos
/// (que pueden incluir URLs firmadas) a la interfaz.
DomainFailure paymentFailure(Object error) {
  if (error is DomainFailure) return error;
  if (error is DioException && error.error is DomainFailure) {
    return error.error! as DomainFailure;
  }
  if (error is DioException) {
    final status = error.response?.statusCode;
    final data = error.response?.data;
    final code = data is Map ? data['code'] as String? : null;
    return DomainFailure(
      statusCode: status ?? 503,
      code: code ??
          (status == null
              ? (_isOffline(error) ? 'offline' : 'network_error')
              : 'http_error'),
      message: 'No se pudo conectar con TRACOP. Intenta de nuevo.',
    );
  }
  if (error is FormatException || error is TypeError) {
    return const DomainFailure(
      statusCode: 502,
      code: 'invalid_response',
      message: 'La respuesta del servidor no tiene el formato esperado.',
    );
  }
  return const DomainFailure(
    statusCode: 500,
    code: 'unknown',
    message: 'No se pudo completar la operación del pago.',
  );
}
