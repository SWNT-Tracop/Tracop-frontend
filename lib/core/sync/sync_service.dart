import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';

import '../network/dio_client.dart';
import '../storage/app_database.dart' hide Category, Product, Lot;

/// Pulls server changes and applies them to the local database.
///
/// The cursor is a server sequence, not a client timestamp. Changes are
/// applied transactionally and only advance the cursor after the whole page
/// has been stored successfully.
class SyncService {
  SyncService({required DioClient client, required AppDatabase database})
      : _client = client,
        _database = database;

  final DioClient _client;
  final AppDatabase _database;

  static const cursorKeyPrefix = 'sync:pull-cursor:';
  static const unappliedChangesKeyPrefix = 'sync:unapplied-changes:';

  Future<SyncResult> pull({required String userId, int limit = 200}) async {
    final connection = await Connectivity().checkConnectivity();
    if (!connection.any((item) => item != ConnectivityResult.none)) {
      return const SyncResult(online: false);
    }

    final cursor = await _readCursor(userId);
    final response = await _client.instance.get('/sync/pull', queryParameters: {
      'cursor': cursor,
      'limit': limit,
    });
    final body = Map<String, dynamic>.from(response.data as Map);
    final changes = (body['changes'] as List<dynamic>? ?? const [])
        .map((change) => Map<String, dynamic>.from(change as Map))
        .toList(growable: false);

    await _database.transaction(() async {
      for (final change in changes) {
        await _applyChange(userId, change);
      }
      final nextCursor = body['nextCursor'];
      if (nextCursor is String) await _writeCursor(userId, nextCursor);
    });

    return SyncResult(
      online: true,
      applied: changes.length,
      hasMore: body['hasMore'] == true,
      nextCursor: body['nextCursor'] as String?,
    );
  }

  Future<SyncResult> pullAll(
      {required String userId, int pageSize = 200}) async {
    var total = 0;
    var hasMore = true;
    SyncResult? last;
    while (hasMore) {
      last = await pull(userId: userId, limit: pageSize);
      total += last.applied;
      if (!last.online || !last.hasMore) {
        hasMore = false;
      }
    }
    return (last ?? const SyncResult(online: true)).copyWith(applied: total);
  }

  Future<String> currentCursor(String userId) => _readCursor(userId);

  Future<int> unappliedChangeCount(String userId) async {
    final raw = await _readState('$unappliedChangesKeyPrefix$userId');
    if (raw == null) return 0;
    final value = jsonDecode(raw);
    return value is List ? value.length : 0;
  }

  Future<void> _applyChange(String userId, Map<String, dynamic> change) async {
    final entity = change['entity'] as String?;
    final entityId = change['entityId'] as String?;
    final operation = change['op'] as String?;
    final payload = Map<String, dynamic>.from(
      (change['payload'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
    if (entity == null || entityId == null || operation == null) return;

    switch (entity) {
      case 'category':
        await _applyCategory(entityId, operation, payload);
      case 'product':
        await _applyProduct(entityId, operation, payload);
      case 'lot':
        await _applyLot(entityId, operation, payload);
      case 'trip':
      case 'checkin':
      case 'incident':
        // These entities have feature-specific caches. Keep the complete
        // server change until the logistics repository consumes it, rather
        // than silently dropping a remote update.
        await _storeUnappliedChange(userId, change);
    }
  }

  Future<void> _applyCategory(
      String id, String operation, Map<String, dynamic> payload) async {
    if (_isDelete(operation, payload)) {
      await (_database.delete(_database.categories)
            ..where((row) => row.id.equals(id)))
          .go();
      return;
    }
    await _database.into(_database.categories).insertOnConflictUpdate(
          CategoriesCompanion(
            id: Value(id),
            name: Value(payload['name'] as String? ?? ''),
            parentId: Value(payload['parentId'] as String?),
            depth: Value(_asInt(payload['depth'])),
            syncedAt: Value(DateTime.now().toUtc()),
          ),
        );
  }

  Future<void> _applyProduct(
      String id, String operation, Map<String, dynamic> payload) async {
    if (_isDelete(operation, payload)) {
      await (_database.delete(_database.products)
            ..where((row) => row.id.equals(id)))
          .go();
      return;
    }
    await _database.into(_database.products).insertOnConflictUpdate(
          ProductsCompanion(
            id: Value(id),
            categoryId: Value(payload['categoryId'] as String? ?? ''),
            name: Value(payload['name'] as String? ?? ''),
            unit: Value(payload['unit'] as String? ?? ''),
            attributesJson:
                Value(jsonEncode(payload['attributes'] ?? const {})),
            syncedAt: Value(DateTime.now().toUtc()),
          ),
        );
  }

  Future<void> _applyLot(
      String id, String operation, Map<String, dynamic> payload) async {
    if (_isDelete(operation, payload)) {
      await (_database.delete(_database.lots)
            ..where((row) => row.id.equals(id)))
          .go();
      return;
    }
    final existing = await (_database.select(_database.lots)
          ..where((row) => row.id.equals(id)))
        .getSingleOrNull();
    final version = _asInt(payload['version']);
    if (existing != null && version < existing.version) return;

    await _database.into(_database.lots).insertOnConflictUpdate(
          LotsCompanion(
            id: Value(id),
            // The sync payload intentionally omits providerId for privacy.
            // Preserve the local owner when updating an existing lot.
            providerId: Value(existing?.providerId ?? ''),
            productId: Value(payload['productId'] as String? ?? ''),
            quantityMilli: Value(_asInt(payload['quantityMilli'])),
            unit: Value(payload['unit'] as String? ?? ''),
            unitPrice: Value(_asInt(payload['unitPrice'])),
            qualityGrade: Value(payload['qualityGrade'] as String?),
            availableFrom: Value(_asDate(payload['availableFrom'])),
            availableUntil: Value(_asDate(payload['availableUntil'])),
            status: Value(payload['status'] as String? ?? 'draft'),
            version: Value(version),
            providerSummaryJson: Value(existing?.providerSummaryJson),
            distanceKm: Value(existing?.distanceKm),
            isMine: Value(existing?.isMine ?? false),
            syncState: const Value('synced'),
            updatedAt: Value(DateTime.now().toUtc()),
          ),
        );
  }

  bool _isDelete(String operation, Map<String, dynamic> payload) =>
      operation == 'delete' ||
      operation == 'cancel' ||
      payload['tombstone'] == true;

  Future<void> _storeUnappliedChange(
      String userId, Map<String, dynamic> change) async {
    final keyName = '$unappliedChangesKeyPrefix$userId';
    final current = await _readState(keyName);
    final changes =
        current == null ? <dynamic>[] : (jsonDecode(current) as List<dynamic>);
    final key = '${change['entity']}:${change['entityId']}';
    changes
        .removeWhere((item) => '${item['entity']}:${item['entityId']}' == key);
    changes.add(change);
    await _writeState(keyName, jsonEncode(changes));
  }

  int _asInt(dynamic value) =>
      value is num ? value.toInt() : int.parse('$value');

  DateTime _asDate(dynamic value) => DateTime.parse('$value').toUtc();

  Future<String> _readCursor(String userId) async =>
      await _readState('$cursorKeyPrefix$userId') ?? '0';

  Future<String?> _readState(String key) async {
    final row = await (_database.select(_database.syncState)
          ..where((item) => item.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> _writeCursor(String userId, String cursor) =>
      _writeState('$cursorKeyPrefix$userId', cursor);

  Future<void> _writeState(String key, String value) async {
    await _database.into(_database.syncState).insertOnConflictUpdate(
          SyncStateCompanion.insert(key: key, value: value),
        );
  }
}

class SyncResult {
  const SyncResult({
    required this.online,
    this.applied = 0,
    this.hasMore = false,
    this.nextCursor,
  });

  final bool online;
  final int applied;
  final bool hasMore;
  final String? nextCursor;

  SyncResult copyWith({int? applied}) => SyncResult(
        online: online,
        applied: applied ?? this.applied,
        hasMore: hasMore,
        nextCursor: nextCursor,
      );
}
