import '../../../../core/network/dio_client.dart';

abstract interface class OrderRemoteDataSource {
  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> body);
  Future<Map<String, dynamic>> listOrders(
      String endpoint, Map<String, dynamic> query);
  Future<Map<String, dynamic>> getOrder(String id);
  Future<Map<String, dynamic>> acceptQuote(
      String id, Map<String, dynamic> body);
  Future<Map<String, dynamic>> cancelOrder(
      String id, Map<String, dynamic> body);
}

class OrderRemoteDataSourceImpl implements OrderRemoteDataSource {
  OrderRemoteDataSourceImpl(this._client);
  final DioClient _client;

  @override
  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> body) async =>
      Map<String, dynamic>.from(
          (await _client.instance.post('/orders', data: body)).data as Map);

  @override
  Future<Map<String, dynamic>> listOrders(
          String endpoint, Map<String, dynamic> query) async =>
      Map<String, dynamic>.from(
          (await _client.instance.get(endpoint, queryParameters: query)).data
              as Map);

  @override
  Future<Map<String, dynamic>> getOrder(String id) async =>
      Map<String, dynamic>.from(
          (await _client.instance.get('/orders/$id')).data as Map);

  @override
  Future<Map<String, dynamic>> acceptQuote(
          String id, Map<String, dynamic> body) async =>
      Map<String, dynamic>.from(
          (await _client.instance.post('/orders/$id/accept', data: body)).data
              as Map);

  @override
  Future<Map<String, dynamic>> cancelOrder(
          String id, Map<String, dynamic> body) async =>
      Map<String, dynamic>.from(
          (await _client.instance.post('/orders/$id/cancel', data: body)).data
              as Map);
}
