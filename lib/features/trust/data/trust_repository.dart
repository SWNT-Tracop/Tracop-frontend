import 'package:dio/dio.dart';

import '../../../core/result/result.dart';
import '../domain/rating.dart';
import 'trust_remote.dart';

class TrustRepository {
  TrustRepository({required this.remote});

  final TrustRemoteDataSource remote;

  Future<Result<RatingResult, DomainFailure>> submitRating(
      RatingSubmission submission) async {
    try {
      final json = await remote.submitRating(submission.toJson());
      return Ok(RatingResult.fromJson(json));
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
                'No se pudo registrar la valoración.'
            : 'No se pudo registrar la valoración.',
      ));
    } catch (_) {
      return const Err(DomainFailure(
        statusCode: 500,
        code: 'unknown',
        message: 'No se pudo registrar la valoración.',
      ));
    }
  }
}
