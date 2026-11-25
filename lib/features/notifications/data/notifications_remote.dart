import '../../../../core/network/dio_client.dart';

class NotificationsRemoteDataSource {
  NotificationsRemoteDataSource(this._client);

  final DioClient _client;

  Future<Map<String, dynamic>> getInbox({int limit = 50}) async =>
      Map<String, dynamic>.from((await _client.instance
              .get('/me/inbox', queryParameters: {'limit': limit}))
          .data as Map);

  Future<Map<String, dynamic>> markRead(String id) async =>
      Map<String, dynamic>.from(
          (await _client.instance.post('/me/inbox/$id/read')).data as Map);

  Future<Map<String, dynamic>> getPreferences() async =>
      Map<String, dynamic>.from(
          (await _client.instance.get('/me/notification-preferences')).data
              as Map);

  Future<Map<String, dynamic>> savePreferences(
          Map<String, dynamic> preferences) async =>
      Map<String, dynamic>.from((await _client.instance.put(
        '/me/notification-preferences',
        data: preferences,
      ))
          .data as Map);
}
