import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracop_mobile/core/storage/app_database.dart';
import 'package:tracop_mobile/features/logistics/data/logistics_remote.dart';
import 'package:tracop_mobile/features/logistics/data/logistics_repository.dart';

const _pickup = {
  'id': 'stop-pickup',
  'orderId': 'order-1',
  'kind': 'pickup',
  'sequence': 1,
  'zone': 'bogotá',
  'completedAt': null,
};

/// The API answers the stops once, then the phone goes offline (every call fails).
class _OfflineAfterFirstRemote implements LogisticsRemoteDataSource {
  bool offline = false;

  @override
  Future<List<Map<String, dynamic>>> getStops(String tripId) async {
    if (offline) throw StateError('offline');
    return [Map<String, dynamic>.from(_pickup)];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('offline: ${invocation.memberName}');
}

void main() {
  late AppDatabase database;
  late _OfflineAfterFirstRemote remote;
  late LogisticsRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    remote = _OfflineAfterFirstRemote();
    repository = LogisticsRepository(remote: remote, database: database);
  });

  tearDown(() => database.close());

  Future<List<String>> queuedCheckInStops() async {
    final rows = await database.select(database.outboxOperations).get();
    return [
      for (final row in rows)
        if (row.entity == 'checkin')
          (jsonDecode(row.payloadJson) as Map<String, dynamic>)['stopId']
              as String,
    ];
  }

  test(
      'an offline check-in shows the stop as done and a second tap queues nothing',
      () async {
    final stop = (await repository.getStops('carrier-1', 'trip-1')).single;
    remote.offline = true;

    await repository.checkIn(
        userId: 'carrier-1', stop: stop, kind: 'pickup', baseVersion: 3);
    await repository.checkIn(
        userId: 'carrier-1', stop: stop, kind: 'pickup', baseVersion: 3);

    expect(await queuedCheckInStops(), ['stop-pickup']);
    final cached = (await repository.getStops('carrier-1', 'trip-1')).single;
    expect(cached.completedAt, isNotNull);
  });

  test('two taps at the same time still queue one check-in', () async {
    final stop = (await repository.getStops('carrier-1', 'trip-1')).single;
    remote.offline = true;

    await Future.wait([
      repository.checkIn(
          userId: 'carrier-1', stop: stop, kind: 'pickup', baseVersion: 3),
      repository.checkIn(
          userId: 'carrier-1', stop: stop, kind: 'pickup', baseVersion: 3),
    ]);

    expect(await queuedCheckInStops(), ['stop-pickup']);
  });
}
