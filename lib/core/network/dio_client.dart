import 'package:dio/dio.dart';
import '../result/result.dart';

class DioClient {
  final Dio _dio;
  final String baseUrl;
  Future<String?> Function()? _refreshHandler;
  Future<String?>? _refreshing;

  DioClient({required this.baseUrl})
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          sendTimeout: const Duration(seconds: 15),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        )) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException error, ErrorInterceptorHandler handler) async {
          final response = error.response;
          final request = error.requestOptions;
          final isPublicAuthRequest = <String>{
            '/auth/register',
            '/auth/otp/request',
            '/auth/otp/verify',
            '/auth/refresh',
          }.contains(request.path);
          if (response?.statusCode == 401 &&
              request.extra['authRetry'] != true &&
              !isPublicAuthRequest &&
              _refreshHandler != null) {
            try {
              _refreshing ??= _refreshHandler!();
              final token = await _refreshing;
              _refreshing = null;
              if (token != null && token.isNotEmpty) {
                request.extra['authRetry'] = true;
                request.headers['Authorization'] = 'Bearer $token';
                return handler.resolve(await _dio.fetch(request));
              }
            } catch (_) {
              _refreshing = null;
            }
          }
          if (response != null) {
            final data = response.data;
            final code = data is Map && data.containsKey('code')
                ? data['code'] as String?
                : null;
            final message = data is Map && data.containsKey('message')
                ? data['message'] as String?
                : 'Error interno.';
            return handler.reject(
              DioException(
                requestOptions: error.requestOptions,
                response: response,
                error: DomainFailure(
                  statusCode: response.statusCode ?? 500,
                  code: code ?? 'unknown',
                  message: message ?? 'Error interno.',
                ),
              ),
            );
          }
          return handler.next(error);
        },
      ),
    );
  }

  Dio get instance => _dio;

  Future<void> setAuthToken(String? token) async {
    if (token == null) {
      _dio.options.headers.remove('Authorization');
    } else {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  void setRefreshHandler(Future<String?> Function()? handler) {
    _refreshHandler = handler;
  }

  Future<void> close() async => _dio.close();
}
