import 'dart:async';
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
  Future<void> _syncQueue = Future<void>.value();

  static const cursorKeyPrefix = 'sync:pull-cursor:';
  static const unappliedChangesKeyPrefix = 'sync:unapplied-changes:';
  static const lotTombstoneKeyPrefix = 'sync:lot-tombstone:';

  Future<SyncResult> pull({required String userId, int limit = 200}) {
    return _exclusive(() => _pullPage(userId: userId, limit: limit));
  }

  Future<SyncResult> _pullPage(
      {required String userId, int limit = 200}) async {
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

  Future<void> pushPending({required String userId}) {
    return _exclusive(() => _pushPending(userId: userId));
  }

  Future<void> _pushPending({required String userId}) async {
    final connection = await Connectivity().checkConnectivity();
    if (!connection.any((item) => item != ConnectivityResult.none)) return;
    final pending = await (_database.select(_database.outboxOperations)
          ..where((row) =>
              row.ownerUserId.equals(userId) &
              row.status.equals('pending') &
              row.nextAttemptAt.isSmallerOrEqualValue(DateTime.now().toUtc()))
          ..orderBy([(row) => OrderingTerm.asc(row.clientTs)])
          ..limit(50))
        .get();
    if (pending.isEmpty) return;
    try {
      final response = await _client.instance.post('/sync/push', data: {
        'operations': pending
            .map((operation) => <String, dynamic>{
                  'opId': operation.opId,
                  'entity': operation.entity,
                  'entityId': operation.entityId,
                  'type': operation.type,
                  'payload': jsonDecode(operation.payloadJson),
                  if (operation.baseVersion != null)
                    'baseVersion': operation.baseVersion,
                })
            .toList(growable: false),
      });
      final results = (response.data['results'] as List<dynamic>)
          .map((item) => Map<String, dynamic>.from(item as Map));
      for (final result in results) {
        final opId = result['opId'] as String;
        if (result['status'] == 'applied') {
          final serverVersion = result['serverVersion'];
          if (serverVersion is num) {
            await _applyServerVersion(
                pending.firstWhere((operation) => operation.opId == opId),
                serverVersion.toInt());
          }
          await (_database.delete(_database.outboxOperations)
                ..where((row) => row.opId.equals(opId)))
              .go();
        } else {
          await (_database.update(_database.outboxOperations)
                ..where((row) => row.opId.equals(opId)))
              .write(OutboxOperationsCompanion(
            status: Value(result['status'] as String? ?? 'rejected'),
            lastError: Value(_syncFailureDescription(result)),
          ));
        }
      }
    } catch (error) {
      for (final operation in pending) {
        await (_database.update(_database.outboxOperations)
              ..where((row) => row.opId.equals(operation.opId)))
            .write(OutboxOperationsCompanion(
          attempts: Value(operation.attempts + 1),
          nextAttemptAt:
              Value(DateTime.now().toUtc().add(const Duration(minutes: 1))),
          lastError: Value(error.toString()),
        ));
      }
    }
  }

  Future<SyncResult> pullAll(
      {required String userId, int pageSize = 200}) async {
    return _exclusive(() => _pullAll(userId: userId, pageSize: pageSize));
  }

  Future<SyncResult> _pullAll(
      {required String userId, int pageSize = 200}) async {
    var total = 0;
    var hasMore = true;
    SyncResult? last;
    while (hasMore) {
      last = await _pullPage(userId: userId, limit: pageSize);
      total += last.applied;
      if (!last.online || !last.hasMore) {
        hasMore = false;
      }
    }
    return (last ?? const SyncResult(online: true)).copyWith(applied: total);
  }

  Future<T> _exclusive<T>(Future<T> Function() action) async {
    final previous = _syncQueue;
    final release = Completer<void>();
    _syncQueue = previous.then((_) => release.future);
    await previous;
    try {
      return await action();
    } finally {
      release.complete();
    }
  }

  Future<void> _applyServerVersion(dynamic operation, int serverVersion) async {
    if (operation.entity != 'lot') return;
    await (_database.update(_database.lots)
          ..where((row) => row.id.equals(operation.entityId)))
        .write(LotsCompanion(
      version: Value(serverVersion),
      syncState: const Value('synced'),
      updatedAt: Value(DateTime.now().toUtc()),
    ));
    await _updateCachedLotVersion(operation.entityId, serverVersion);
  }

  Future<void> _updateCachedLotVersion(String lotId, int version) async {
    final rows = await (_database.select(_database.syncState)
          ..where((row) => row.key.like('catalog_%')))
        .get();
    for (final row in rows) {
      final decoded = jsonDecode(row.value);
      var changed = false;
      if (decoded is Map<String, dynamic> && decoded['id'] == lotId) {
        decoded['version'] = version;
        changed = true;
      } else if (decoded is Map<String, dynamic> && decoded['items'] is List) {
        for (final item in decoded['items']) {
          if (item is Map && item['id'] == lotId) {
            item['version'] = version;
            changed = true;
          }
        }
      }
      if (changed) await _writeState(row.key, jsonEncode(decoded));
    }
  }

  Future<String> currentCursor(String userId) => _readCursor(userId);

  Future<int> unappliedChangeCount(String userId) async {
    final raw = await _readState('$unappliedChangesKeyPrefix$userId');
    if (raw == null) return 0;
    final value = jsonDecode(raw);
    return value is List ? value.length : 0;
  }

  Future<List<SyncOperationInfo>> operations(String userId) async {
    final rows = await (_database.select(_database.outboxOperations)
          ..where((row) => row.ownerUserId.equals(userId))
          ..orderBy([(row) => OrderingTerm.desc(row.clientTs)]))
        .get();
    return rows
        .map((row) => SyncOperationInfo(
              opId: row.opId,
              entity: row.entity,
              entityId: row.entityId,
              type: row.type,
              status: row.status,
              attempts: row.attempts,
              lastError: row.lastError,
              createdAt: row.clientTs,
            ))
        .toList(growable: false);
  }

  Future<void> retryOperation(String opId) async {
    await (_database.update(_database.outboxOperations)
          ..where((row) => row.opId.equals(opId)))
        .write(OutboxOperationsCompanion(
      status: const Value('pending'),
      attempts: const Value(0),
      nextAttemptAt: Value(DateTime.now().toUtc()),
      lastError: const Value(null),
    ));
  }

  Future<void> discardOperation(String opId) async {
    await (_database.delete(_database.outboxOperations)
          ..where((row) => row.opId.equals(opId)))
        .go();
  }

  Future<Map<String, String>> lotOperationStatuses(String userId) async {
    final rows = await (_database.select(_database.outboxOperations)
          ..where((row) =>
              row.ownerUserId.equals(userId) & row.entity.equals('lot'))
          ..orderBy([(row) => OrderingTerm.desc(row.clientTs)]))
        .get();
    final statuses = <String, String>{};
    for (final row in rows) {
      statuses.putIfAbsent(row.entityId, () => row.status);
    }
    return statuses;
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
      await _writeTombstone(id, _asInt(payload['version']));
      await (_database.delete(_database.lots)
            ..where((row) => row.id.equals(id)))
          .go();
      return;
    }
    final existing = await (_database.select(_database.lots)
          ..where((row) => row.id.equals(id)))
        .getSingleOrNull();
    final version = _asInt(payload['version']);
    final tombstone = await _readTombstone(id);
    if (tombstone != null && tombstone >= version) return;
    if (tombstone != null) await _clearTombstone(id);
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
      value is num ? value.toInt() : int.tryParse('$value') ?? 0;

  String _syncFailureDescription(Map<String, dynamic> result) {
    final code = result['code'] as String? ?? 'sync_failed';
    final serverVersion = result['serverVersion'];
    return serverVersion is num
        ? '$code · versión del servidor: ${serverVersion.toInt()}'
        : code;
  }

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

  Future<int?> _readTombstone(String lotId) async {
    final raw = await _readState('$lotTombstoneKeyPrefix$lotId');
    return raw == null ? null : int.tryParse(raw);
  }

  Future<void> _writeTombstone(String lotId, int version) =>
      _writeState('$lotTombstoneKeyPrefix$lotId', '$version');

  Future<void> _clearTombstone(String lotId) async {
    await (_database.delete(_database.syncState)
          ..where((row) => row.key.equals('$lotTombstoneKeyPrefix$lotId')))
        .go();
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

class SyncOperationInfo {
  const SyncOperationInfo({
    required this.opId,
    required this.entity,
    required this.entityId,
    required this.type,
    required this.status,
    required this.attempts,
    required this.lastError,
    required this.createdAt,
  });

  final String opId;
  final String entity;
  final String entityId;
  final String type;
  final String status;
  final int attempts;
  final String? lastError;
  final DateTime createdAt;
}
