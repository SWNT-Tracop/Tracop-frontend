import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracop_mobile/core/network/dio_client.dart';
import 'package:tracop_mobile/core/storage/app_database.dart';
import 'package:tracop_mobile/core/sync/sync_service.dart';

void main() {
  test('uses capped exponential retry delays', () {
    expect(syncRetryDelay(1), const Duration(minutes: 1));
    expect(syncRetryDelay(2), const Duration(minutes: 2));
    expect(syncRetryDelay(3), const Duration(minutes: 4));
    expect(syncRetryDelay(5), const Duration(minutes: 16));
    expect(syncRetryDelay(6), const Duration(minutes: 30));
  });

  late AppDatabase database;
  late SyncService service;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    service = SyncService(
      client: DioClient(baseUrl: 'http://localhost'),
      database: database,
    );
  });

  tearDown(() async => database.close());

  test('reports the newest outbox status for each lot', () async {
    final now = DateTime.now().toUtc();
    await database.batch((batch) {
      batch.insertAll(database.outboxOperations, [
        OutboxOperationsCompanion.insert(
          opId: 'old',
          ownerUserId: const Value('user-1'),
          entity: 'lot',
          entityId: 'lot-1',
          type: 'update',
          payloadJson: '{}',
          clientTs: now.subtract(const Duration(minutes: 1)),
          status: 'pending',
          attempts: 0,
          nextAttemptAt: now,
        ),
        OutboxOperationsCompanion.insert(
          opId: 'new',
          ownerUserId: const Value('user-1'),
          entity: 'lot',
          entityId: 'lot-1',
          type: 'transition',
          payloadJson: '{}',
          clientTs: now,
          status: 'conflict',
          attempts: 1,
          nextAttemptAt: now,
        ),
      ]);
    });

    expect(await service.lotOperationStatuses('user-1'), {'lot-1': 'conflict'});
  });

  test(
      'persists the last completed synchronization separately from connectivity',
      () async {
    expect(await service.lastSuccessfulSync('user-1'), null);

    await service.recordSuccessfulSync('user-1');
    final timestamp = await service.lastSuccessfulSync('user-1');

    expect(timestamp, isNot(null));
    expect(timestamp!.isBefore(DateTime.now().toUtc()), isTrue);
    expect(await service.lastSuccessfulSync('user-2'), null);
  });

  test('retries and discards an operation without touching other users',
      () async {
    final now = DateTime.now().toUtc();
    await database.into(database.outboxOperations).insert(
          OutboxOperationsCompanion.insert(
            opId: 'op-1',
            ownerUserId: const Value('user-1'),
            entity: 'lot',
            entityId: 'lot-1',
            type: 'update',
            payloadJson: '{}',
            clientTs: now,
            status: 'conflict',
            attempts: 3,
            nextAttemptAt: now,
            lastError: const Value('version_conflict'),
          ),
        );

    await service.retryOperation('op-1');
    final retried = await (database.select(database.outboxOperations)
          ..where((row) => row.opId.equals('op-1')))
        .getSingle();
    expect(retried.status, 'pending');
    expect(retried.attempts, 0);
    expect(retried.lastError, null);

    await service.discardOperation('op-1');
    expect(await (database.select(database.outboxOperations)).get(), isEmpty);
  });
}
