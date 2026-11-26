import '../../../../core/network/dio_client.dart';

class LogisticsRemoteDataSource {
  LogisticsRemoteDataSource(this._client);
  final DioClient _client;

  Future<Map<String, dynamic>> getCarrierProfile() async =>
      Map<String, dynamic>.from(
          (await _client.instance.get('/logistics/carrier-profile')).data
              as Map);

  Future<List<Map<String, dynamic>>> getCandidates() async {
    final data = (await _client.instance.get('/logistics/orders/candidates'))
        .data as List;
    return data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> getTrips() async {
    final data =
        (await _client.instance.get('/logistics/trips/mine')).data as List;
    return data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> getStops(String tripId) async {
    final data = (await _client.instance.get('/logistics/trips/$tripId/stops'))
        .data as List;
    return data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<Map<String, dynamic>> push(
          List<Map<String, dynamic>> operations) async =>
      Map<String, dynamic>.from((await _client.instance
              .post('/sync/push', data: {'operations': operations}))
          .data as Map);
}
