import '../../../../core/result/result.dart';
import '../../domain/entities/audit_entry.dart';
import '../../domain/entities/ledger.dart';
import '../../domain/entities/payments_metrics.dart';
import '../../domain/entities/settlement.dart';
import '../../domain/repository/payment_backoffice_repository.dart';
import '../remote/payment_backoffice_remote.dart';
import 'payment_repository_impl.dart' show paymentFailure;

/// Siempre en línea, igual que los pagos: el estado lo decide el servidor
/// (`expectedVersion`) y no hay acciones del personal sin conexión.
class PaymentBackofficeRepositoryImpl implements PaymentBackofficeRepository {
  PaymentBackofficeRepositoryImpl({required this.remote});

  final PaymentBackofficeRemoteDataSource remote;

  @override
  Future<Result<List<Settlement>, DomainFailure>> settlements(
          {SettlementStatus? status, int limit = 100}) =>
      _guard(() async {
        final json = await remote.listSettlements({
          if (status != null) 'status': status.wire,
          'limit': limit.clamp(1, 100),
        });
        return _items(json, Settlement.fromJson);
      });

  @override
  Future<Result<Settlement, DomainFailure>> markSettlementPaid(
      String settlementId, int expectedVersion, String? reference) {
    final trimmed = reference?.trim() ?? '';
    // El esquema es estricto: solo estas dos claves.
    final body = <String, dynamic>{
      'expectedVersion': expectedVersion,
      'reference': trimmed.isEmpty ? null : trimmed,
    };
    return _guard(() async => Settlement.fromJson(
        await remote.markSettlementPaid(settlementId, body)));
  }

  @override
  Future<Result<List<LedgerEntry>, DomainFailure>> ledgerForOrder(
          String orderId) =>
      _guard(() async =>
          _items(await remote.ledgerForOrder(orderId), LedgerEntry.fromJson));

  @override
  Future<Result<PaymentsMetrics, DomainFailure>> metrics() =>
      _guard(() async => PaymentsMetrics.fromJson(await remote.metrics()));

  @override
  Future<Result<AuditPage, DomainFailure>> audit({
    required String entity,
    required String entityId,
    String? action,
    String? cursor,
    int limit = 50,
  }) =>
      _guard(() async {
        // `auditQuerySchema` es estricto: solo claves que acepta, sin nulos.
        final query = <String, dynamic>{
          'entity': entity,
          'entityId': entityId,
          if (action != null) 'action': action,
          if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
          'limit': limit.clamp(1, 100),
        };
        return AuditPage.fromJson(await remote.audit(query));
      });

  static List<T> _items<T>(Map<String, dynamic> json,
          T Function(Map<String, dynamic> json) parse) =>
      (json['items'] as List)
          .map((item) => parse(Map<String, dynamic>.from(item as Map)))
          .toList(growable: false);

  Future<Result<T, DomainFailure>> _guard<T>(Future<T> Function() call) async {
    try {
      return Ok(await call());
    } on Object catch (error) {
      return Err(paymentFailure(error));
    }
  }
}
