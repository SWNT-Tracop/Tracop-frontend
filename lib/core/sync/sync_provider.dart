import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'sync_service.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  throw UnimplementedError('SyncService requires DioClient and AppDatabase.');
});

final syncRevisionProvider = StateProvider<int>((ref) => 0);
