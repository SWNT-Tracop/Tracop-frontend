import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/providers/auth_provider.dart';
import '../data/notifications_repository.dart';
import '../domain/notification.dart';

final notificationsRepositoryProvider =
    Provider<NotificationsRepository>((ref) => throw UnimplementedError());

final notificationsProvider =
    FutureProvider<List<NotificationEntry>>((ref) async {
  final userId = ref.watch(authProvider).valueOrNull?.user.id;
  if (userId == null) return const <NotificationEntry>[];
  final result = await ref.read(notificationsRepositoryProvider).inbox(userId);
  return result.map(
    ok: (value) => value.value,
    err: (failure) => throw failure.error,
  );
});
