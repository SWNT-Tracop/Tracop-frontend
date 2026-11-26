import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracop_mobile/core/i18n/strings.dart';
import 'package:tracop_mobile/core/storage/app_database.dart' hide User;
import 'package:tracop_mobile/features/auth/domain/entities/user.dart';
import 'package:tracop_mobile/features/home/presentation/home_screen.dart';
import 'package:tracop_mobile/features/logistics/data/logistics_remote.dart';
import 'package:tracop_mobile/features/logistics/data/logistics_repository.dart';
import 'package:tracop_mobile/features/logistics/domain/logistics_models.dart';
import 'package:tracop_mobile/features/logistics/presentation/logistics_provider.dart';
import 'package:tracop_mobile/features/logistics/presentation/logistics_screen.dart';

const _carrier = User(
  id: 'carrier-1',
  role: 'carrier',
  fullName: 'Transportista',
  phone: '+573000000004',
  status: 'active',
  locale: 'es-CO',
);

class _OfflineRemote implements LogisticsRemoteDataSource {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError('offline');
}

void main() {
  testWidgets(
      'the vehicle type is picked from the provisional list, never typed',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final repository =
        LogisticsRepository(remote: _OfflineRemote(), database: database);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        logisticsRepositoryProvider.overrideWithValue(repository),
        logisticsUserProvider.overrideWithValue(_carrier),
        homeUserProvider.overrideWith((ref) async => _carrier),
        homeConnectivityProvider
            .overrideWith((ref) => Stream<bool>.value(true)),
        carrierProfileProvider('carrier-1').overrideWith((ref) async =>
            const CarrierProfile(
                vehicleType: 'Aa', capacityKg: 50, plate: 'YFX123')),
        logisticsCandidatesProvider('carrier-1')
            .overrideWith((ref) async => const []),
        carrierTripsProvider('carrier-1').overrideWith((ref) async => const []),
      ],
      child: const MaterialApp(home: Scaffold(body: LogisticsScreen())),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text(CommonStrings.edit));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNWidgets(2),
        reason: 'only capacity and plate are typed');
    expect(
        find.descendant(
            of: find.byType(AlertDialog), matching: find.text('Aa')),
        findsNothing,
        reason: 'a value outside the list must be picked again');

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    for (final type in LogisticsStrings.vehicleTypes) {
      expect(find.text(type), findsWidgets);
    }
    await tester.tap(find.text('Camión').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(CommonStrings.save));
    await tester.pumpAndSettle();

    final queued = await database.select(database.outboxOperations).get();
    final payload =
        jsonDecode(queued.single.payloadJson) as Map<String, dynamic>;
    expect(payload['vehicleType'], 'Camión');
  });
}
