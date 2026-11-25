import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/storage/app_database.dart';
import '../../../core/sync/sync_service.dart';
import 'logistics_remote.dart';
import '../domain/logistics_models.dart';

class LogisticsRepository {
  LogisticsRepository({
    required this.remote,
    required this.database,
    this.syncService,
  });

  final LogisticsRemoteDataSource remote;
  final AppDatabase database;
  final SyncService? syncService;
  static const _uuid = Uuid();
  static const _localPaymentCandidatesKey =
      'logistics:local-payment-candidates';
  static const _remoteChangesPrefix = 'sync:unapplied-changes:';

  /// Applies changes received by the generic sync service to logistics caches.
  ///
  /// A check-in is kept until its stops cache exists, because the sync payload
  /// identifies the stop but does not contain the complete stop projection.
  Future<void> applyRemoteChanges(String userId) async {
    final key = '$_remoteChangesPrefix$userId';
    final changes = await _readCache(key);
    if (changes == null || changes.isEmpty) return;

    final remaining = <Map<String, dynamic>>[];
    for (final change in changes) {
      final entity = change['entity'] as String?;
      final payload = Map<String, dynamic>.from(
        (change['payload'] as Map?)?.cast<String, dynamic>() ?? const {},
      );
      final applied = switch (entity) {
        'trip' => await _applyRemoteTrip(userId, change, payload),
        'checkin' => await _applyRemoteCheckin(userId, payload),
        'incident' => await _applyRemoteIncident(userId, change, payload),
        _ => true,
      };
      if (!applied) remaining.add(change);
    }
    if (remaining.isEmpty) {
      await (database.delete(database.syncState)
            ..where((row) => row.key.equals(key)))
          .go();
    } else {
      await _saveCache(key, remaining);
    }
  }

  Future<List<OrderCandidate>> getCandidates(String userId) async {
    final cacheKey = 'logistics:$userId:candidates';
    List<OrderCandidate> values;
    try {
      values = (await remote.getCandidates())
          .map(OrderCandidate.fromJson)
          .toList(growable: false);
      await _saveCache(cacheKey, values.map((e) => e.toJson()).toList());
    } catch (_) {
      final cached = await _readCache(cacheKey);
      values = cached?.map(OrderCandidate.fromJson).toList() ?? [];
    }
    final localPayments = await _readCache(_localPaymentCandidatesKey) ?? [];
    final candidates = <String, OrderCandidate>{
      for (final item in values) item.orderId: item,
      for (final item in localPayments.map(OrderCandidate.fromJson))
        item.orderId: item,
    };
    final queued = await _queuedOrderIds(userId);
    return candidates.values
        .where((candidate) => !queued.contains(candidate.orderId))
        .toList(growable: false);
  }

  Future<bool> _applyRemoteTrip(String userId, Map<String, dynamic> change,
      Map<String, dynamic> payload) async {
    final id = change['entityId'] as String?;
    if (id == null) return true;
    final key = 'logistics:$userId:trips';
    final trips = await _readCache(key) ?? [];
    final index = trips.indexWhere((trip) => trip['id'] == id);
    final current = index >= 0 ? trips[index] : <String, dynamic>{};
    final version = _asInt(payload['version'], current['version'] ?? 1);
    if (index >= 0 && version < _asInt(current['version'], 1)) return true;
    final merged = <String, dynamic>{
      ...current,
      'id': id,
      'status': payload['status'] as String? ?? current['status'] ?? 'planned',
      'version': version,
      'plannedAt': current['plannedAt'] ??
          (change['occurredAt'] as String? ??
              DateTime.now().toUtc().toIso8601String()),
      'isLocalOnly': false,
    };
    if (index >= 0) {
      trips[index] = merged;
    } else {
      trips.add(merged);
    }
    await _saveCache(key, trips);
    return true;
  }

  Future<bool> _applyRemoteCheckin(
      String userId, Map<String, dynamic> payload) async {
    final tripId = payload['tripId'] as String?;
    final stopId = payload['stopId'] as String?;
    if (tripId == null || stopId == null) return true;
    final key = 'logistics:$userId:stops:$tripId';
    final stops = await _readCache(key);
    if (stops == null) return false;
    final index = stops.indexWhere((stop) => stop['id'] == stopId);
    if (index < 0) return true;
    stops[index]['completedAt'] =
        payload['clientAt'] ?? DateTime.now().toUtc().toIso8601String();
    await _saveCache(key, stops);
    return true;
  }

  int _asInt(dynamic value, int fallback) =>
      value is num ? value.toInt() : int.tryParse('$value') ?? fallback;

  Future<CarrierProfile?> getCarrierProfile(String userId) async {
    final cacheKey = 'logistics:$userId:profile';
    try {
      final profile = CarrierProfile.fromJson(await remote.getCarrierProfile());
      await _saveCache(cacheKey, [profile.toJson()]);
      return profile;
    } catch (_) {
      final cached = await _readCache(cacheKey);
      if (cached != null && cached.isNotEmpty) {
        return CarrierProfile.fromJson(cached.first);
      }
      return null;
    }
  }

  Future<void> saveCarrierProfile({
    required String userId,
    required CarrierProfile profile,
  }) async {
    await _saveCache('logistics:$userId:profile', [profile.toJson()]);
    await _enqueue(
      ownerUserId: userId,
      entity: 'carrier_profile',
      entityId: userId,
      type: 'update',
      payload: profile.toJson(),
    );
    await syncPending(userId);
  }

  Future<List<CarrierTrip>> getTrips(String userId) async {
    final cacheKey = 'logistics:$userId:trips';
    try {
      final values = (await remote.getTrips())
          .map(CarrierTrip.fromJson)
          .toList(growable: false);
      await _saveCache(cacheKey, values.map((e) => e.toJson()).toList());
      return await _mergePendingTrips(userId, values);
    } catch (_) {
      final cached = await _readCache(cacheKey);
      if (cached == null) rethrow;
      return _mergePendingTrips(
          userId, cached.map(CarrierTrip.fromJson).toList());
    }
  }

  Future<List<TripStop>> getStops(String userId, String tripId) async {
    final cacheKey = 'logistics:$userId:stops:$tripId';
    final localTrips = await _readCache('logistics:$userId:local-trips') ?? [];
    if (localTrips.any((trip) => trip['id'] == tripId)) {
      final stops = await _readCache(cacheKey) ?? [];
      return stops.map(TripStop.fromJson).toList(growable: false);
    }
    try {
      final values = (await remote.getStops(tripId))
          .map(TripStop.fromJson)
          .toList(growable: false);
      await _saveCache(cacheKey, values.map((e) => e.toJson()).toList());
      return values;
    } catch (_) {
      final cached = await _readCache(cacheKey);
      if (cached == null) rethrow;
      return cached.map(TripStop.fromJson).toList(growable: false);
    }
  }

  Future<bool> createTrip(String userId, List<String> orderIds) async {
    final candidates = await getCandidates(userId);
    final selected = candidates
        .where((candidate) => orderIds.contains(candidate.orderId))
        .toList(growable: false);
    final localSelected =
        selected.where((candidate) => candidate.isLocalPayment).toList();
    if (localSelected.isNotEmpty) {
      if (localSelected.length != orderIds.length) {
        throw StateError('No mezcles pedidos locales y sincronizados.');
      }
      if (await getCarrierProfile(userId) == null) {
        throw StateError(
            'Completa el perfil del vehículo para crear el viaje.');
      }
      await _createLocalTrip(userId, localSelected);
      return true;
    }
    final tripId = _uuid.v7();
    await _enqueue(
      ownerUserId: userId,
      entity: 'trip',
      entityId: tripId,
      type: 'create',
      payload: {'orderIds': orderIds},
    );
    await syncPending(userId);
    return false;
  }

  Future<void> startTrip(String userId, CarrierTrip trip) async {
    if (trip.isLocalOnly) {
      await _updateLocalTrip(
        userId,
        trip.id,
        (current) => current.copyWith(
          status: 'in_progress',
          version: current.version + 1,
        ),
      );
      return;
    }
    await _enqueue(
      ownerUserId: userId,
      entity: 'trip',
      entityId: trip.id,
      type: 'transition',
      baseVersion: trip.version,
      payload: {'action': 'start'},
    );
    await syncPending(userId);
  }

  Future<void> checkIn({
    required String userId,
    required TripStop stop,
    required String kind,
    required int baseVersion,
  }) async {
    if (await _markLocalStopComplete(userId, stop.id)) return;
    await _enqueue(
      ownerUserId: userId,
      entity: 'checkin',
      entityId: _uuid.v7(),
      type: 'create',
      baseVersion: baseVersion,
      payload: {
        'stopId': stop.id,
        'kind': kind,
        'clientAt': DateTime.now().toUtc().toIso8601String(),
      },
    );
    await syncPending(userId);
  }

  Future<void> openIncident({
    required String userId,
    required String tripId,
    required String orderId,
    required String type,
    required String description,
  }) async {
    final incidentId = _uuid.v7();
    final key = 'logistics:$userId:local-incidents';
    final incidents = await _readCache(key) ?? [];
    incidents.add({
      'id': incidentId,
      'tripId': tripId,
      'orderId': orderId,
      'type': type,
      'description': description,
      'status': 'open',
      'openedAt': DateTime.now().toUtc().toIso8601String(),
      'closedAt': null,
    });
    await _saveCache(key, incidents);
    await _enqueue(
      ownerUserId: userId,
      entity: 'incident',
      entityId: incidentId,
      type: 'create',
      payload: {
        'id': incidentId,
        'tripId': tripId,
        'orderId': orderId,
        'type': type,
        'description': description,
      },
    );
    await syncPending(userId);
  }

  Future<bool> _applyRemoteIncident(String userId, Map<String, dynamic> change,
      Map<String, dynamic> payload) async {
    final id = change['entityId'] as String?;
    if (id == null) return true;
    final key = 'logistics:$userId:local-incidents';
    final incidents = await _readCache(key) ?? [];
    final value = <String, dynamic>{
      ...payload,
      'id': id,
      'isLocalOnly': false,
    };
    final index = incidents.indexWhere((item) => item['id'] == id);
    if (index >= 0) {
      incidents[index] = {...incidents[index], ...value};
    } else {
      incidents.add(value);
    }
    await _saveCache(key, incidents);
    return true;
  }

  Future<int> pendingCount(String userId) async => (await (database
              .select(database.outboxOperations)
            ..where((row) =>
                row.ownerUserId.equals(userId) & row.status.equals('pending')))
          .get())
      .length;

  Future<int> failedCount(String userId) async =>
      (await (database.select(database.outboxOperations)
                ..where((row) =>
                    row.ownerUserId.equals(userId) &
                    (row.status.equals('rejected') |
                        row.status.equals('conflict'))))
              .get())
          .length;

  Future<String?> lastSyncError(String userId) async {
    final operation = await (database.select(database.outboxOperations)
          ..where((row) =>
              row.ownerUserId.equals(userId) & row.lastError.isNotNull())
          ..orderBy([(row) => OrderingTerm.desc(row.clientTs)])
          ..limit(1))
        .getSingleOrNull();
    return operation?.lastError;
  }

  Future<void> syncPending(String userId) async {
    await syncService?.pushPending(userId: userId);
  }

  Future<void> _enqueue({
    required String ownerUserId,
    required String entity,
    required String entityId,
    required String type,
    required Map<String, dynamic> payload,
    int? baseVersion,
  }) async {
    final now = DateTime.now().toUtc();
    await database.into(database.outboxOperations).insert(
          OutboxOperationsCompanion.insert(
            opId: _uuid.v7(),
            ownerUserId: Value(ownerUserId),
            entity: entity,
            entityId: entityId,
            type: type,
            payloadJson: jsonEncode(payload),
            baseVersion: Value(baseVersion),
            clientTs: now,
            status: 'pending',
            attempts: 0,
            nextAttemptAt: now,
          ),
        );
  }

  Future<void> _saveCache(String key, List<Map<String, dynamic>> value) async {
    await database.into(database.syncState).insertOnConflictUpdate(
          SyncStateCompanion.insert(key: key, value: jsonEncode(value)),
        );
  }

  Future<Set<String>> _queuedOrderIds(String userId) async {
    final operations = await (database.select(database.outboxOperations)
          ..where((row) =>
              row.entity.equals('trip') &
              row.type.equals('create') &
              row.ownerUserId.equals(userId) &
              row.status.equals('pending')))
        .get();
    final orderIds = operations.expand((operation) {
      final payload = jsonDecode(operation.payloadJson) as Map<String, dynamic>;
      return (payload['orderIds'] as List).cast<String>();
    }).toSet();
    final localTrips = await _readCache('logistics:$userId:local-trips') ?? [];
    for (final trip in localTrips) {
      final stops =
          await _readCache('logistics:$userId:stops:${trip['id']}') ?? [];
      orderIds.addAll(stops.map((stop) => stop['orderId'] as String));
    }
    return orderIds;
  }

  Future<List<CarrierTrip>> _mergePendingTrips(
      String userId, List<CarrierTrip> trips) async {
    final operations = await (database.select(database.outboxOperations)
          ..where((row) =>
              row.entity.equals('trip') &
              row.type.equals('create') &
              row.ownerUserId.equals(userId) &
              row.status.equals('pending')))
        .get();
    final known = trips.map((trip) => trip.id).toSet();
    final localTrips = await _readCache('logistics:$userId:local-trips') ?? [];
    return [
      ...trips,
      for (final trip in localTrips.map(CarrierTrip.fromJson))
        if (!known.contains(trip.id)) trip,
      for (final operation in operations)
        if (!known.contains(operation.entityId))
          CarrierTrip(
            id: operation.entityId,
            status: 'sync_pending',
            version: 1,
            plannedAt: operation.clientTs,
          ),
    ];
  }

  Future<void> _createLocalTrip(
      String userId, List<OrderCandidate> candidates) async {
    final trip = CarrierTrip(
      id: _uuid.v7(),
      status: 'assigned',
      version: 1,
      plannedAt: DateTime.now().toUtc(),
      isLocalOnly: true,
    );
    final stops = <Map<String, dynamic>>[];
    var sequence = 1;
    for (final candidate in candidates) {
      for (final zone in candidate.pickupZones) {
        stops.add(TripStop(
          id: _uuid.v7(),
          orderId: candidate.orderId,
          kind: 'pickup',
          sequence: sequence++,
          zone: zone,
          completedAt: null,
        ).toJson());
      }
      stops.add(TripStop(
        id: _uuid.v7(),
        orderId: candidate.orderId,
        kind: 'delivery',
        sequence: sequence++,
        zone: candidate.deliveryZone,
        completedAt: null,
      ).toJson());
    }
    final key = 'logistics:$userId:local-trips';
    final trips = await _readCache(key) ?? [];
    trips.add(trip.toJson());
    await _saveCache(key, trips);
    await _saveCache('logistics:$userId:stops:${trip.id}', stops);
  }

  Future<void> _updateLocalTrip(
    String userId,
    String tripId,
    CarrierTrip Function(CarrierTrip) update,
  ) async {
    final key = 'logistics:$userId:local-trips';
    final trips = await _readCache(key) ?? [];
    final index = trips.indexWhere((item) => item['id'] == tripId);
    if (index < 0) throw StateError('Viaje local no encontrado.');
    trips[index] = update(CarrierTrip.fromJson(trips[index])).toJson();
    await _saveCache(key, trips);
  }

  Future<bool> _markLocalStopComplete(String userId, String stopId) async {
    final trips = await _readCache('logistics:$userId:local-trips') ?? [];
    for (final trip in trips) {
      final tripId = trip['id'] as String;
      final key = 'logistics:$userId:stops:$tripId';
      final stops = await _readCache(key) ?? [];
      final index = stops.indexWhere((stop) => stop['id'] == stopId);
      if (index < 0) continue;
      stops[index]['completedAt'] = DateTime.now().toUtc().toIso8601String();
      await _saveCache(key, stops);
      return true;
    }
    return false;
  }

  Future<List<Map<String, dynamic>>?> _readCache(String key) async {
    final row = await (database.select(database.syncState)
          ..where((value) => value.key.equals(key)))
        .getSingleOrNull();
    if (row == null) return null;
    return (jsonDecode(row.value) as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList(growable: false);
  }
}
