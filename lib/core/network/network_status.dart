import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';

Future<bool> hasServerConnection(String baseUrl) async {
  final transport = await Connectivity().checkConnectivity();
  // The Android emulator can report no transport while 10.0.2.2 is reachable.
  // In that environment the health request is the authoritative check.
  if (!transport.any((item) => item != ConnectivityResult.none) &&
      !baseUrl.contains('10.0.2.2')) {
    return false;
  }
  final client = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 3),
    receiveTimeout: const Duration(seconds: 3),
    sendTimeout: const Duration(seconds: 3),
  ));
  try {
    final response = await client.get<void>('/health');
    return response.statusCode != null && response.statusCode! < 500;
  } catch (_) {
    return false;
  } finally {
    client.close(force: true);
  }
}
