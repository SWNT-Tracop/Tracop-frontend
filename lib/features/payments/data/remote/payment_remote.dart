import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';

abstract interface class PaymentRemoteDataSource {
  Future<Map<String, dynamic>> initiate(
      String orderId, Map<String, dynamic> body);
  Future<Map<String, dynamic>> getForOrder(String orderId);
  Future<Map<String, dynamic>> getById(String paymentId);
  Future<Map<String, dynamic>> requestProofUpload(String paymentId);
  Future<Map<String, dynamic>> confirmProof(String paymentId);
  Future<Map<String, dynamic>> dispute(
      String paymentId, Map<String, dynamic> body);
  Future<Map<String, dynamic>> reviewQueue(int limit);
  Future<Map<String, dynamic>> verify(
      String paymentId, Map<String, dynamic> body);
  Future<Map<String, dynamic>> reject(
      String paymentId, Map<String, dynamic> body);
  Future<Map<String, dynamic>> resolveDispute(
      String paymentId, Map<String, dynamic> body);

  /// POST multipart directo al almacenamiento con la política prefirmada.
  Future<void> uploadProofObject({
    required String url,
    required Map<String, String> fields,
    required String filename,
    required List<int> bytes,
  });
}

class PaymentRemoteDataSourceImpl implements PaymentRemoteDataSource {
  PaymentRemoteDataSourceImpl(this._client, {Dio Function()? storageClient})
      : _storageClient = storageClient ?? _defaultStorageClient;

  final DioClient _client;
  final Dio Function() _storageClient;

  static Dio _defaultStorageClient() => Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 90),
        receiveTimeout: const Duration(seconds: 30),
      ));

  Future<Map<String, dynamic>> _get(String path,
          {Map<String, dynamic>? query}) async =>
      Map<String, dynamic>.from(
          (await _client.instance.get(path, queryParameters: query)).data
              as Map);

  Future<Map<String, dynamic>> _post(String path,
          [Map<String, dynamic>? body]) async =>
      Map<String, dynamic>.from(
          (await _client.instance.post(path, data: body)).data as Map);

  @override
  Future<Map<String, dynamic>> initiate(
          String orderId, Map<String, dynamic> body) =>
      _post('/orders/$orderId/payment', body);

  @override
  Future<Map<String, dynamic>> getForOrder(String orderId) =>
      _get('/orders/$orderId/payment');

  @override
  Future<Map<String, dynamic>> getById(String paymentId) =>
      _get('/payments/$paymentId');

  @override
  Future<Map<String, dynamic>> requestProofUpload(String paymentId) =>
      _post('/payments/$paymentId/proof');

  @override
  Future<Map<String, dynamic>> confirmProof(String paymentId) =>
      _post('/payments/$paymentId/proof/confirm');

  @override
  Future<Map<String, dynamic>> dispute(
          String paymentId, Map<String, dynamic> body) =>
      _post('/payments/$paymentId/dispute', body);

  @override
  Future<Map<String, dynamic>> reviewQueue(int limit) =>
      _get('/payments/review', query: {'limit': limit});

  @override
  Future<Map<String, dynamic>> verify(
          String paymentId, Map<String, dynamic> body) =>
      _post('/payments/$paymentId/verify', body);

  @override
  Future<Map<String, dynamic>> reject(
          String paymentId, Map<String, dynamic> body) =>
      _post('/payments/$paymentId/reject', body);

  @override
  Future<Map<String, dynamic>> resolveDispute(
          String paymentId, Map<String, dynamic> body) =>
      _post('/payments/$paymentId/dispute/resolve', body);

  @override
  Future<void> uploadProofObject({
    required String url,
    required Map<String, String> fields,
    required String filename,
    required List<int> bytes,
  }) async {
    // Igual que en catálogo: un Dio aparte, sin el interceptor ni el header
    // Authorization del API, para no enviar el token al almacenamiento.
    final storage = _storageClient();
    try {
      // Todos los campos de la política primero y el archivo al final.
      final form = FormData();
      form.fields.addAll(fields.entries);
      form.files.add(
          MapEntry('file', MultipartFile.fromBytes(bytes, filename: filename)));
      await storage.post<void>(
        url,
        data: form,
        options: Options(
          contentType: Headers.multipartFormDataContentType,
          responseType: ResponseType.plain,
        ),
      );
    } finally {
      storage.close(force: true);
    }
  }
}
