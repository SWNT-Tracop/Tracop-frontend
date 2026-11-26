import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'sync_service.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  throw UnimplementedError('SyncService requires DioClient and AppDatabase.');
});

final syncRevisionProvider = StateProvider<int>((ref) => 0);

final lastSuccessfulSyncProvider =
    FutureProvider.family<DateTime?, String>((ref, userId) {
  ref.watch(syncRevisionProvider);
  return ref.read(syncServiceProvider).lastSuccessfulSync(userId);
});

final catalogReadErrorProvider = StateProvider<String?>((ref) => null);
