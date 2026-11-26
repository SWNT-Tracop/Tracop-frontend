import '../../../../core/network/dio_client.dart';

class BackofficeRemoteDataSource {
  BackofficeRemoteDataSource(this._client);

  final DioClient _client;

  Future<Map<String, dynamic>> _get(String path,
          {Map<String, dynamic>? query}) async =>
      Map<String, dynamic>.from(
          (await _client.instance.get(path, queryParameters: query)).data
              as Map);

  Future<Map<String, dynamic>> metrics() => _get('/backoffice/metrics');

  Future<Map<String, dynamic>> parameters() => _get('/backoffice/parameters');

  Future<Map<String, dynamic>> updateParameter(
          String key, String value) async =>
      Map<String, dynamic>.from((await _client.instance.put(
              '/backoffice/parameters/${Uri.encodeComponent(key)}',
              data: {'value': value}))
          .data as Map);

  Future<Map<String, dynamic>> audit(Map<String, dynamic> query) =>
      _get('/backoffice/audit', query: query);

  Future<Map<String, dynamic>> verifications(
          {String? status, int limit = 50}) =>
      _get('/trust/staff/verifications', query: {
        if (status != null) 'status': status,
        'limit': limit,
      });

  Future<Map<String, dynamic>> subject(String userId) =>
      _get('/trust/staff/subjects/$userId');

  Future<void> unlinkChannel(String userId, String channel) async {
    await _client.instance
        .post('/staff/users/$userId/channels/$channel/unlink');
  }

  Future<Map<String, dynamic>> approveVerification(
          String providerId, Map<String, dynamic> checks) async =>
      Map<String, dynamic>.from((await _client.instance.post(
              '/trust/staff/verifications/$providerId/approve',
              data: {'checks': checks}))
          .data as Map);

  Future<Map<String, dynamic>> rejectVerification(
          String providerId, String reason) async =>
      Map<String, dynamic>.from((await _client.instance.post(
              '/trust/staff/verifications/$providerId/reject',
              data: {'reason': reason}))
          .data as Map);

  Future<Map<String, dynamic>> revokeVerification(
          String providerId, String reason) async =>
      Map<String, dynamic>.from((await _client.instance.post(
              '/trust/staff/verifications/$providerId/revoke',
              data: {'reason': reason}))
          .data as Map);

  Future<Map<String, dynamic>> hideRating(String ratingId) async =>
      Map<String, dynamic>.from(
          (await _client.instance.post('/trust/staff/ratings/$ratingId/hide'))
              .data as Map);

  Future<List<dynamic>> proposals() async =>
      (await _client.instance.get('/catalog/product-proposals')).data as List;

  Future<Map<String, dynamic>> approveProposal(String id) async =>
      Map<String, dynamic>.from((await _client.instance
              .post('/catalog/product-proposals/$id/approve'))
          .data as Map);

  Future<Map<String, dynamic>> rejectProposal(String id, String reason) async =>
      Map<String, dynamic>.from((await _client.instance.post(
              '/catalog/product-proposals/$id/reject',
              data: {'rejectionReason': reason}))
          .data as Map);

  Future<List<dynamic>> categories() async =>
      ((await _client.instance.get('/catalog/categories')).data as List);

  Future<List<dynamic>> products({String? q, String? categoryId}) async =>
      ((await _client.instance.get('/catalog/products', queryParameters: {
        if (q != null && q.isNotEmpty) 'q': q,
        if (categoryId != null) 'categoryId': categoryId,
      }))
          .data as List);

  Future<Map<String, dynamic>> createCategory(
          Map<String, dynamic> body) async =>
      Map<String, dynamic>.from(
          (await _client.instance.post('/catalog/categories', data: body)).data
              as Map);

  Future<Map<String, dynamic>> updateCategory(String id, String name) async =>
      Map<String, dynamic>.from((await _client.instance
              .patch('/catalog/categories/$id', data: {'name': name}))
          .data as Map);

  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> body) async =>
      Map<String, dynamic>.from(
          (await _client.instance.post('/catalog/products', data: body)).data
              as Map);

  Future<Map<String, dynamic>> updateProduct(
          String id, Map<String, dynamic> body) async =>
      Map<String, dynamic>.from(
          (await _client.instance.patch('/catalog/products/$id', data: body))
              .data as Map);

  Future<List<dynamic>> carriers({int limit = 100}) async =>
      ((await _client.instance.get('/logistics/carriers', queryParameters: {
        'limit': limit,
      }))
          .data as List);

  Future<List<dynamic>> trips({int limit = 100}) async =>
      ((await _client.instance.get('/logistics/trips', queryParameters: {
        'limit': limit,
      }))
          .data as List);

  Future<Map<String, dynamic>> trip(String id) => _get('/logistics/trips/$id');

  Future<List<dynamic>> tripStops(String id) async =>
      (await _client.instance.get('/logistics/trips/$id/stops')).data as List;

  Future<Map<String, dynamic>> reassignTrip(
          String id, String carrierId, int expectedVersion) async =>
      Map<String, dynamic>.from(
          (await _client.instance.post('/logistics/trips/$id/reassign', data: {
        'carrierId': carrierId,
        'expectedVersion': expectedVersion,
      }))
              .data as Map);

  Future<Map<String, dynamic>> cancelTrip(
          String id, int expectedVersion, String reason) async =>
      Map<String, dynamic>.from(
          (await _client.instance.post('/logistics/trips/$id/cancel', data: {
        'expectedVersion': expectedVersion,
        'reason': reason,
      }))
              .data as Map);

  Future<Map<String, dynamic>> conflicts() => _get('/logistics/conflicts');

  Future<List<dynamic>> incidents({int limit = 100}) async =>
      ((await _client.instance.get('/logistics/incidents', queryParameters: {
        'limit': limit,
      }))
          .data as List);

  Future<Map<String, dynamic>> resolveIncident(String id) async =>
      Map<String, dynamic>.from(
          (await _client.instance.post('/logistics/incidents/$id/resolve')).data
              as Map);
}
