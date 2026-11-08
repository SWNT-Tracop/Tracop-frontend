import '../../../../core/network/dio_client.dart';

abstract class AuthRemoteDataSource {
  Future<void> setAuthToken(String? token);
  Future<Map<String, dynamic>> register(Map<String, dynamic> body);
  Future<Map<String, dynamic>> requestOtp(Map<String, dynamic> body);
  Future<Map<String, dynamic>> verifyOtp(Map<String, dynamic> body);
  Future<Map<String, dynamic>> refreshSession(Map<String, dynamic> body);
  Future<Map<String, dynamic>> logout();
  Future<Map<String, dynamic>> getMe();
  Future<Map<String, dynamic>> updateMe(Map<String, dynamic> body);
  Future<Map<String, dynamic>> upsertProviderProfile(Map<String, dynamic> body);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient dioClient;

  AuthRemoteDataSourceImpl(this.dioClient);

  @override
  Future<void> setAuthToken(String? token) => dioClient.setAuthToken(token);

  @override
  Future<Map<String, dynamic>> register(Map<String, dynamic> body) async {
    final response =
        await dioClient.instance.post('/auth/register', data: body);
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> requestOtp(Map<String, dynamic> body) async {
    final response =
        await dioClient.instance.post('/auth/otp/request', data: body);
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> verifyOtp(Map<String, dynamic> body) async {
    final response =
        await dioClient.instance.post('/auth/otp/verify', data: body);
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> refreshSession(Map<String, dynamic> body) async {
    final response = await dioClient.instance.post('/auth/refresh', data: body);
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> logout() async {
    final response = await dioClient.instance.post('/auth/logout');
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> getMe() async {
    final response = await dioClient.instance.get('/me');
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> updateMe(Map<String, dynamic> body) async {
    final response = await dioClient.instance.patch('/me', data: body);
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> upsertProviderProfile(
      Map<String, dynamic> body) async {
    final response =
        await dioClient.instance.put('/me/provider-profile', data: body);
    return response.data as Map<String, dynamic>;
  }
}
