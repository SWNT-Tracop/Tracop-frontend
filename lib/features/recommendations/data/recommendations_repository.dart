import 'package:dio/dio.dart';

import '../../../core/result/result.dart';
import 'recommendations_remote.dart';

class RecommendationsRepository {
  RecommendationsRepository({required this.remote});

  final RecommendationsRemoteDataSource remote;

  Future<Result<T, DomainFailure>> guard<T>(Future<T> Function() call) async {
    try {
      return Ok(await call());
    } on DomainFailure catch (error) {
      return Err(error);
    } on DioException catch (error) {
      final data = error.response?.data;
      return Err(DomainFailure(
        statusCode: error.response?.statusCode ?? 503,
        code: data is Map
            ? data['code']?.toString() ?? 'network_error'
            : 'network_error',
        message: data is Map
            ? data['message']?.toString() ??
                'No se pudo cargar recomendaciones.'
            : 'No se pudo cargar recomendaciones.',
      ));
    } catch (_) {
      return const Err(DomainFailure(
        statusCode: 500,
        code: 'unknown',
        message: 'No se pudo cargar recomendaciones.',
      ));
    }
  }
}
