import '../../../../core/network/dio_client.dart';

/// Endpoints del personal: liquidaciones, libro del pedido y métricas.
abstract interface class PaymentBackofficeRemoteDataSource {
  Future<Map<String, dynamic>> listSettlements(Map<String, dynamic> query);
  Future<Map<String, dynamic>> markSettlementPaid(
      String settlementId, Map<String, dynamic> body);
  Future<Map<String, dynamic>> ledgerForOrder(String orderId);
  Future<Map<String, dynamic>> metrics();
}

class PaymentBackofficeRemoteDataSourceImpl
    implements PaymentBackofficeRemoteDataSource {
  PaymentBackofficeRemoteDataSourceImpl(this._client);

  final DioClient _client;

  Future<Map<String, dynamic>> _get(String path,
          {Map<String, dynamic>? query}) async =>
      Map<String, dynamic>.from(
          (await _client.instance.get(path, queryParameters: query)).data
              as Map);

  @override
  Future<Map<String, dynamic>> listSettlements(Map<String, dynamic> query) =>
      _get('/settlements', query: query);

  @override
  Future<Map<String, dynamic>> markSettlementPaid(
          String settlementId, Map<String, dynamic> body) async =>
      Map<String, dynamic>.from((await _client.instance
              .post('/settlements/$settlementId/paid', data: body))
          .data as Map);

  @override
  Future<Map<String, dynamic>> ledgerForOrder(String orderId) =>
      _get('/orders/$orderId/ledger');

  @override
  Future<Map<String, dynamic>> metrics() => _get('/backoffice/metrics');
}
