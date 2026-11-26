import '../../../../core/network/dio_client.dart';

class TrustRemoteDataSource {
  TrustRemoteDataSource(this._client);

  final DioClient _client;

  Future<Map<String, dynamic>> submitRating(Map<String, dynamic> body) async =>
      Map<String, dynamic>.from(
          (await _client.instance.post('/trust/ratings', data: body)).data
              as Map);

  Future<Map<String, dynamic>> getMyReputation() async =>
      Map<String, dynamic>.from(
          (await _client.instance.get('/trust/me')).data as Map);
}
