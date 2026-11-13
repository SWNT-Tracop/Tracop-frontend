import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tracop_mobile/core/result/result.dart';
import 'package:tracop_mobile/features/auth/domain/entities/auth_session.dart';
import 'package:tracop_mobile/features/auth/domain/entities/user.dart';
import 'package:tracop_mobile/features/auth/domain/repository/auth_repository.dart';
import 'package:tracop_mobile/features/auth/presentation/provider_profile_screen.dart';
import 'package:tracop_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:tracop_mobile/features/home/presentation/home_screen.dart';

void main() {
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
    await tester.tap(find.text('Departamento'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Boyacá').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Municipio'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tunja').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Elige el punto de recogida'), findsOneWidget);
    await tester.tap(find.text('Ingresar coordenadas manualmente'));
    await tester.pumpAndSettle();
    final coordinates = find.byType(TextField);
    await tester.enterText(coordinates.at(0), '14');
    await tester.enterText(coordinates.at(1), '-73.3');
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('Elige un punto dentro de Colombia.'), findsOneWidget);
    await tester.enterText(coordinates.at(0), '5.5353');
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar perfil'));
    await tester.pumpAndSettle();

    expect(repository.saved?.displayName, 'Finca Prueba');
    expect(repository.saved?.municipality, 'Tunja');
    expect(repository.saved?.department, 'Boyacá');
    expect(repository.saved?.lat, 5.5353);
    expect(repository.saved?.lng, -73.3);
    expect(find.text('¡Perfil guardado!'), findsOneWidget);
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
