import 'dart:convert';

import '../../../core/result/result.dart';
import '../../../core/storage/app_database.dart';
import '../domain/notification.dart';
import 'notifications_remote.dart';

class NotificationsRepository {
  NotificationsRepository({required this.remote, required this.database});

  final NotificationsRemoteDataSource remote;
  final AppDatabase database;

  static String _inboxKey(String userId) => 'notifications:inbox:$userId';

  Future<Result<List<NotificationEntry>, DomainFailure>> inbox(
      String userId) async {
    try {
      final response = await remote.getInbox();
      final items = (response['items'] as List<dynamic>? ?? const [])
          .map((item) => NotificationEntry.fromJson(
              Map<String, dynamic>.from(item as Map)))
          .toList(growable: false);
      await _write(userId, items);
      return Ok(items);
    } catch (error) {
      final cached = await _read(userId);
      if (cached != null) return Ok(cached);
      return Err(_failure(error));
    }
  }

  Future<Result<NotificationEntry, DomainFailure>> markRead(
      String userId, NotificationEntry entry) async {
    try {
      final json = await remote.markRead(entry.id);
      final updated = NotificationEntry.fromJson(json);
      final items = await _read(userId) ?? <NotificationEntry>[];
      await _write(userId, [
        for (final item in items) item.id == updated.id ? updated : item,
      ]);
      return Ok(updated);
    } catch (error) {
      return Err(_failure(error));
    }
  }

  Future<List<NotificationEntry>?> _read(String userId) async {
    final row = await (database.select(database.syncState)
          ..where((item) => item.key.equals(_inboxKey(userId))))
        .getSingleOrNull();
    if (row == null) return null;
    return (jsonDecode(row.value) as List<dynamic>)
        .map((item) =>
            NotificationEntry.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList(growable: false);
  }

  Future<void> _write(String userId, List<NotificationEntry> items) async {
    await database.into(database.syncState).insertOnConflictUpdate(
          SyncStateCompanion.insert(
            key: _inboxKey(userId),
            value: jsonEncode([
              for (final item in items)
                {
                  'id': item.id,
                  'kind': item.kind,
                  'title': item.title,
                  'body': item.body,
                  'createdAt': item.createdAt.toIso8601String(),
                  'readAt': item.readAt?.toIso8601String(),
                },
            ]),
          ),
        );
  }

  DomainFailure _failure(Object error) => const DomainFailure(
        statusCode: 503,
        code: 'network_error',
        message: 'No se pudieron cargar las notificaciones.',
      );
}
