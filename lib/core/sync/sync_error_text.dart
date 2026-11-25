import 'package:dio/dio.dart';

import '../result/result.dart';
import '../i18n/strings.dart';

String syncErrorText(String? value) {
  final normalized = (value ?? '').toLowerCase();
  if (normalized.contains('network_error') ||
      normalized.contains('connection') ||
      normalized.contains('timeout') ||
      normalized.contains('socket')) {
    return SyncStrings.syncNoConnection;
  }
  if (normalized.contains('server_error') ||
      normalized.contains('status code 500') ||
      normalized.contains('status code: 500')) {
    return SyncStrings.syncServerUnavailable;
  }
  if (normalized.contains('rate_limited') || normalized.contains('429')) {
    return SyncStrings.syncRateLimited;
  }
  if (normalized.contains('unauthorized') ||
      normalized.contains('invalid_session') ||
      normalized.contains('status code 401')) {
    return SyncStrings.syncSessionExpired;
  }
  if (normalized.contains('version_conflict') ||
      normalized.contains('conflict')) {
    return SyncStrings.syncConflict;
  }
  if (normalized.contains('forbidden') ||
      normalized.contains('status code 403')) {
    return SyncStrings.syncForbidden;
  }
  return SyncStrings.syncGenericFailure;
}

String syncErrorFromException(Object error) {
  if (error is DomainFailure) return syncErrorText(error.code);
  if (error is DioException) {
    final failure = error.error;
    if (failure is DomainFailure) return syncErrorText(failure.code);
    final statusCode = error.response?.statusCode;
    if (statusCode != null) return syncErrorText('status code $statusCode');
  }
  return syncErrorText(error.toString());
}
