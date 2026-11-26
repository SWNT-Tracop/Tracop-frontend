import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tracop_mobile/core/i18n/strings.dart';
import 'package:tracop_mobile/core/result/result.dart';
import 'package:tracop_mobile/features/auth/domain/entities/auth_session.dart';
import 'package:tracop_mobile/features/auth/domain/entities/user.dart';
import 'package:tracop_mobile/features/auth/domain/repository/auth_repository.dart';
import 'package:tracop_mobile/features/auth/presentation/provider_profile_screen.dart';
import 'package:tracop_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:tracop_mobile/features/home/presentation/home_screen.dart';
import 'package:tracop_mobile/core/config/colombia_locations.dart';
import 'package:tracop_mobile/core/location/device_location.dart';

void main() {
  _backAndEditTests();
  _locationTests();
  testWidgets('provider profile validates location and saves required fields',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _ProviderProfileRepository();
    final router = GoRouter(
      initialLocation: '/provider',
      routes: [
        GoRoute(
          path: '/provider',
          builder: (context, state) => const ProviderProfileScreen(),
        ),
        GoRoute(
          path: '/perfil',
          builder: (context, state) => const Scaffold(body: Text('Mi cuenta')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          authProvider.overrideWith((ref) => _ProducerAuthNotifier(repository)),
          homeConnectivityProvider
              .overrideWith((ref) => Stream<bool>.value(true)),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    await tester.enterText(find.byType(TextField).first, 'Finca Prueba');
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    await _pick(tester, 'Departamento', 'boyaca', 'Boyacá');
    await _pick(tester, 'Municipio', 'tunja', 'Tunja');
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    expect(find.text(ProviderProfileStrings.pointRequired), findsOneWidget);
    await tester
        .tap(find.text(ProviderProfileStrings.useMunicipalityCentre('Tunja')));
    await tester.pumpAndSettle();
    expect(find.text(ProviderProfileStrings.pointChosen), findsOneWidget);
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar perfil'));
    await tester.pumpAndSettle();

    expect(repository.saved?.displayName, 'Finca Prueba');
    expect(repository.saved?.municipality, 'Tunja');
    expect(repository.saved?.department, 'Boyacá');
    final tunja = ColombiaLocations.municipality('Boyacá', 'Tunja')!;
    expect(repository.saved?.lat, tunja.lat);
    expect(repository.saved?.lng, tunja.lng);
    expect(find.text('¡Perfil guardado!'), findsOneWidget);
  });
}

void _backAndEditTests() {
  testWidgets('atras del sistema regresa un paso y revisar permite editar',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _ProviderProfileRepository();
    final router = GoRouter(
      initialLocation: '/perfil',
      routes: [
        GoRoute(
          path: '/perfil',
          builder: (context, state) => const Scaffold(body: Text('Mi cuenta')),
          routes: [
            GoRoute(
              path: 'proveedor',
              builder: (context, state) => const ProviderProfileScreen(),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        authProvider.overrideWith((ref) => _ProducerAuthNotifier(repository)),
        homeConnectivityProvider
            .overrideWith((ref) => Stream<bool>.value(true)),
      ],
      child: MaterialApp.router(routerConfig: router),
    ));
    router.push('/perfil/proveedor');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Finca Prueba');
    await tester.tap(find.text(CommonStrings.next));
    await tester.pumpAndSettle();
    expect(find.textContaining(ProviderProfileStrings.steps[1]), findsWidgets);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.textContaining(ProviderProfileStrings.steps[0]), findsWidgets);
    expect(find.text('Mi cuenta'), findsNothing);

    await tester.tap(find.text(CommonStrings.next));
    await tester.pumpAndSettle();
    await _pick(tester, ProviderProfileStrings.department, 'boyaca', 'Boyacá');
    await _pick(tester, ProviderProfileStrings.municipality, 'tunja', 'Tunja');
    await tester.tap(find.text(CommonStrings.next));
    await tester.pumpAndSettle();
    await tester
        .tap(find.text(ProviderProfileStrings.useMunicipalityCentre('Tunja')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(CommonStrings.next));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip(ProviderProfileStrings.editSection(
        ProviderProfileStrings.reviewLocation.toLowerCase())));
    await tester.pumpAndSettle();
    expect(find.textContaining(ProviderProfileStrings.steps[1]), findsWidgets);
  });
}

class _ProviderProfileRepository implements AuthRepository {
  UpsertProviderProfileRequest? saved;

  @override
  Future<Result<UpsertProviderProfileRequest?, DomainFailure>>
      getStoredProviderProfile() async => const Ok(null);

  @override
  Future<Result<void, DomainFailure>> upsertProviderProfile(
      UpsertProviderProfileRequest request) async {
    saved = request;
    return const Ok(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ProducerAuthNotifier extends AuthNotifier {
  _ProducerAuthNotifier(super.repository) {
    state = AsyncValue.data(AuthSession(
      accessToken: 'test-access',
      refreshToken: 'test-refresh',
      accessTokenExpiresIn: 900,
      refreshTokenExpiresAt: DateTime.utc(2030),
      user: const User(
        id: 'producer-test',
        role: 'producer',
        fullName: 'Productor de prueba',
        phone: '+57000000000',
        status: 'active',
        locale: 'es-CO',
      ),
    ));
  }
}

/// Opens a searchable selector, filters it and picks the option.
Future<void> _pick(
    WidgetTester tester, String label, String query, String option) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
  await tester.enterText(find.widgetWithText(TextField, 'Buscar'), query);
  await tester.pumpAndSettle();
  await tester.tap(find.text(option).last);
  await tester.pumpAndSettle();
}

/// Opens the profile on the pickup-point step, with the device location replaced.
Future<void> _openPointStep(
    WidgetTester tester, DeviceLocationResult location) async {
  await tester.binding.setSurfaceSize(const Size(390, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final repository = _ProviderProfileRepository();
  final router = GoRouter(initialLocation: '/provider', routes: [
    GoRoute(
        path: '/provider',
        builder: (context, state) => const ProviderProfileScreen()),
  ]);
  addTearDown(router.dispose);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(repository),
      authProvider.overrideWith((ref) => _ProducerAuthNotifier(repository)),
      homeConnectivityProvider.overrideWith((ref) => Stream<bool>.value(true)),
      deviceLocatorProvider.overrideWithValue(() async => location),
    ],
    child: MaterialApp.router(routerConfig: router),
  ));
  await tester.pump(const Duration(milliseconds: 400));
  await tester.enterText(find.byType(TextField).first, 'Finca Prueba');
  await tester.tap(find.text(CommonStrings.next));
  await tester.pumpAndSettle();
  await _pick(tester, ProviderProfileStrings.department, 'boyaca', 'Boyacá');
  await _pick(
      tester, ProviderProfileStrings.municipality, 'ventaq', 'Ventaquemada');
  await tester.tap(find.text(CommonStrings.next));
  await tester.pumpAndSettle();
}

void _locationTests() {
  testWidgets('the GPS marks the pickup point when the phone is in Colombia',
      (tester) async {
    await _openPointStep(tester, const DeviceLocationFound(5.36, -73.52));
    expect(
        find.text(ProviderProfileStrings.useMunicipalityCentre('Ventaquemada')),
        findsOneWidget);
    await tester.tap(find.text(ProviderProfileStrings.useGps));
    await tester.pumpAndSettle();
    expect(find.text(ProviderProfileStrings.pointChosen), findsOneWidget);
  });

  testWidgets('a disabled GPS says so and offers the settings', (tester) async {
    await _openPointStep(tester,
        const DeviceLocationFailed(DeviceLocationProblem.serviceDisabled));
    await tester.tap(find.text(ProviderProfileStrings.useGps));
    await tester.pumpAndSettle();
    expect(
        find.text(ProviderProfileStrings.gpsServiceDisabled), findsOneWidget);
    expect(find.text(ProviderProfileStrings.openSettings), findsOneWidget);
    expect(find.text(ProviderProfileStrings.pointChosen), findsNothing);
  });

  testWidgets('a denied permission explains it without a settings detour',
      (tester) async {
    await _openPointStep(tester,
        const DeviceLocationFailed(DeviceLocationProblem.permissionDenied));
    await tester.tap(find.text(ProviderProfileStrings.useGps));
    await tester.pumpAndSettle();
    expect(
        find.text(ProviderProfileStrings.gpsPermissionDenied), findsOneWidget);
    expect(find.text(ProviderProfileStrings.openSettings), findsNothing);
  });

  testWidgets('a position outside Colombia is not used', (tester) async {
    await _openPointStep(tester, const DeviceLocationFound(40.4, -3.7));
    await tester.tap(find.text(ProviderProfileStrings.useGps));
    await tester.pumpAndSettle();
    expect(find.text(ProviderProfileStrings.gpsOutside), findsOneWidget);
    expect(find.text(ProviderProfileStrings.pointChosen), findsNothing);
  });
}
