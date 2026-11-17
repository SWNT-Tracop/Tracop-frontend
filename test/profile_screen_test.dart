import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracop_mobile/core/i18n/strings.dart';
import 'package:tracop_mobile/core/result/result.dart';
import 'package:tracop_mobile/features/auth/domain/entities/auth_session.dart';
import 'package:tracop_mobile/features/auth/domain/entities/user.dart';
import 'package:tracop_mobile/features/auth/domain/repository/auth_repository.dart';
import 'package:tracop_mobile/features/auth/presentation/profile_screen.dart';
import 'package:tracop_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:tracop_mobile/features/home/presentation/home_screen.dart';

void main() {
  Future<void> pumpProfile(WidgetTester tester, _Repo repo,
      {bool online = true}) async {
    await tester.binding.setSurfaceSize(const Size(390, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(repo),
        homeConnectivityProvider
            .overrideWith((ref) => Stream<bool>.value(online)),
      ],
      child: const MaterialApp(home: Scaffold(body: ProfileScreen())),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('productor sin perfil de proveedor ve el pendiente',
      (tester) async {
    await pumpProfile(tester, _Repo(provider: null));
    expect(find.text(ProfileStrings.providerPending), findsOneWidget);
    expect(find.text(ProfileStrings.completeNow), findsOneWidget);
  });

  testWidgets('productor con perfil de proveedor no ve el aviso de avance',
      (tester) async {
    await pumpProfile(
        tester,
        _Repo(
            provider: const UpsertProviderProfileRequest(
                displayName: 'Finca Prueba',
                municipality: 'Tunja',
                department: 'Boyacá',
                lat: 5.5,
                lng: -73.3,
                description: '')));
    expect(find.text(ProfileStrings.providerReady('Finca Prueba', 'Tunja')),
        findsOneWidget);
    expect(find.text(ProfileStrings.completeNow), findsNothing);
  });

  testWidgets('sin conexion explica por que no se puede editar',
      (tester) async {
    await pumpProfile(tester, _Repo(provider: null), online: false);
    expect(find.text(ProfileStrings.offlineEditHint), findsOneWidget);
    expect(find.byTooltip(ProfileStrings.editName), findsNothing);
  });
}

class _Repo implements AuthRepository {
  _Repo({required this.provider});
  final UpsertProviderProfileRequest? provider;
  final user = const User(
      id: 'u1',
      role: 'producer',
      fullName: 'María Prueba',
      phone: '+573001234567',
      status: 'active',
      locale: 'es-CO');

  @override
  Future<Result<User, DomainFailure>> getMe() async => Ok(user);

  @override
  Future<Result<User?, DomainFailure>> getStoredUser() async => Ok(user);

  @override
  Future<Result<UpsertProviderProfileRequest?, DomainFailure>>
      getStoredProviderProfile() async => Ok(provider);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
