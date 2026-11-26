import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class Users extends Table {
  TextColumn get id => text()();
  TextColumn get role => text()();
  TextColumn get fullName => text()();
  TextColumn get phone => text()();
  TextColumn get status => text()();
  TextColumn get locale => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class ProviderProfiles extends Table {
  TextColumn get userId => text()();
  TextColumn get displayName => text()();
  TextColumn get municipality => text()();
  TextColumn get department => text()();
  RealColumn get lat => real()();
  RealColumn get lng => real()();
  TextColumn get description => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {userId};
}

class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn? get parentId => text().nullable()();
  IntColumn get depth => integer()();
  DateTimeColumn get syncedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class Products extends Table {
  TextColumn get id => text()();
  TextColumn get categoryId => text()();
  TextColumn get name => text()();
  TextColumn get unit => text()();
  TextColumn get attributesJson => text()();
  DateTimeColumn get syncedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class Lots extends Table {
  TextColumn get id => text()();
  TextColumn get providerId => text()();
  TextColumn get productId => text()();
  IntColumn get quantityMilli => integer()();
  TextColumn get unit => text()();
  IntColumn get unitPrice => integer()();
  TextColumn? get qualityGrade => text().nullable()();
  DateTimeColumn get availableFrom => dateTime()();
  DateTimeColumn get availableUntil => dateTime()();
  TextColumn get status => text()();
  IntColumn get version => integer()();
  TextColumn? get providerSummaryJson => text().nullable()();
  RealColumn? get distanceKm => real().nullable()();
  BoolColumn get isMine => boolean()();
  TextColumn get syncState => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class OutboxOperations extends Table {
  TextColumn get opId => text()();
  TextColumn get ownerUserId => text().nullable()();
  TextColumn get entity => text()();
  TextColumn get entityId => text()();
  TextColumn get type => text()();
  TextColumn get payloadJson => text()();
  IntColumn? get baseVersion => integer().nullable()();
  DateTimeColumn get clientTs => dateTime()();
  TextColumn get status => text()();
  IntColumn get attempts => integer()();
  DateTimeColumn get nextAttemptAt => dateTime()();
  TextColumn? get lastError => text().nullable()();

  @override
  Set<Column> get primaryKey => {opId};
}

class SyncState extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

class ConsentState extends Table {
  TextColumn get version => text()();
  DateTimeColumn get acceptedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {version};
}

@DriftDatabase(tables: [
  Users,
  ProviderProfiles,
  Categories,
  Products,
  Lots,
  OutboxOperations,
  SyncState,
  ConsentState,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase._internal(super.e);

  @visibleForTesting
  AppDatabase.forTesting(super.e);

  static Future<AppDatabase> create() async => AppDatabase._internal(
        driftDatabase(
          name: 'tracop',
          web: DriftWebOptions(
            sqlite3Wasm: Uri.parse('sqlite3.wasm'),
            driftWorker: Uri.parse('drift_worker.js'),
          ),
        ),
      );

  @override
  int get schemaVersion => 2;

  Future<void> init() async {
    if (!kIsWeb) await customStatement('PRAGMA journal_mode = WAL');
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          await init();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.addColumn(outboxOperations, outboxOperations.ownerUserId);
          }
        },
      );
}
