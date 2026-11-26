import '../../../core/network/dio_client.dart';

class RecommendationsRemoteDataSource {
  RecommendationsRemoteDataSource(this._client);

  final DioClient _client;

  Future<Map<String, dynamic>> priceSuggestion({
    required String productId,
    required String unit,
  }) async =>
      Map<String, dynamic>.from((await _client.instance.get(
        '/pricing/suggestion',
        queryParameters: {'productId': productId, 'unit': unit},
      ))
          .data as Map);

  Future<Map<String, dynamic>> recommendedLots({
    int limit = 20,
    double? lat,
    double? lng,
    int? radiusKm,
    String? cursor,
  }) async =>
      Map<String, dynamic>.from((await _client.instance.get(
        '/recommendations/lots',
        queryParameters: {
          'limit': limit,
          if (lat != null) 'lat': lat,
          if (lng != null) 'lng': lng,
          if (radiusKm != null) 'radiusKm': radiusKm,
          if (cursor != null) 'cursor': cursor,
        },
      ))
          .data as Map);

  Future<Map<String, dynamic>> alerts() async => Map<String, dynamic>.from(
      (await _client.instance.get('/alerts')).data as Map);

  Future<Map<String, dynamic>> createAlert(Map<String, dynamic> body) async =>
      Map<String, dynamic>.from(
          (await _client.instance.post('/alerts', data: body)).data as Map);

  Future<void> deleteAlert(String id) async {
    await _client.instance.delete('/alerts/$id');
  }

  Future<Map<String, dynamic>> mappings({String? productId}) async =>
      Map<String, dynamic>.from((await _client.instance.get(
        '/pricing/mappings',
        queryParameters: {
          if (productId != null) 'productId': productId,
        },
      ))
          .data as Map);

  Future<Map<String, dynamic>> createMapping(Map<String, dynamic> body) async =>
      Map<String, dynamic>.from((await _client.instance.post(
        '/pricing/mappings',
        data: body,
      ))
          .data as Map);

  Future<void> deleteMapping(String id) async {
    await _client.instance.delete('/pricing/mappings/$id');
  }
}
