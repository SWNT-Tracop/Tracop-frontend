import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracop_mobile/app/app.dart';
import 'package:tracop_mobile/app/responsive_shell.dart';
import 'package:tracop_mobile/core/result/result.dart';
import 'package:tracop_mobile/features/home/presentation/home_screen.dart';
import 'package:tracop_mobile/features/auth/domain/repository/auth_repository.dart';
import 'package:tracop_mobile/features/auth/domain/entities/auth_session.dart'
    show UpdateMeRequest;
import 'package:tracop_mobile/features/auth/domain/entities/user.dart';
import 'package:tracop_mobile/features/auth/presentation/auth_screens.dart'
    show RegisterScreen;
import 'package:tracop_mobile/features/auth/presentation/profile_screen.dart';
import 'package:tracop_mobile/features/auth/presentation/providers/auth_provider.dart'
    show AuthNotifier, authProvider, authRepositoryProvider;
import 'package:tracop_mobile/app/router.dart' show AuthenticatedShell, router;
import 'package:tracop_mobile/features/catalog/domain/entities/lot.dart'
    hide Category, Product;
import 'package:tracop_mobile/features/catalog/domain/entities/category.dart';
import 'package:tracop_mobile/features/catalog/domain/entities/product.dart';
import 'package:tracop_mobile/features/catalog/presentation/catalog_search_screen.dart';
import 'package:tracop_mobile/features/catalog/domain/repository/catalog_repository.dart';
import 'package:tracop_mobile/features/catalog/presentation/providers/catalog_provider.dart'
    show catalogRepositoryProvider;

void main() {
  setUp(() => router.go('/'));
  testWidgets('Buyer home has one primary search action', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => _HomeAuthNotifier()),
          homeUserProvider.overrideWith((ref) async => null),
          homeLotsProvider.overrideWith((ref) async => const []),
          homeConnectivityProvider
              .overrideWith((ref) => Stream<bool>.value(true)),
          catalogRepositoryProvider.overrideWithValue(_HomeCatalogRepository()),
        ],
        child: const TracopApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      Theme.of(tester.element(find.text('Inicio').first)).brightness,
      Brightness.dark,
    );
    expect(find.text('Buscar lotes'), findsOneWidget);
    expect(find.text('Explorar lotes'), findsNothing);
    expect(find.text('Conexión disponible'), findsNothing);
    await tester.tap(find.text('Buscar lotes'));
    await tester.pumpAndSettle();
    expect(find.byType(CatalogSearchScreen), findsOneWidget);

    await tester.tap(find.text('Inicio').last);
    await tester.pumpAndSettle();
    expect(find.text('Buscar lotes'), findsOneWidget);
  });

  testWidgets('New seller sees first-lot action above the fold',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => _HomeAuthNotifier()),
          homeUserProvider.overrideWith((ref) async => _testUser()),
          homeLotsProvider.overrideWith((ref) async => const []),
          homeConnectivityProvider
              .overrideWith((ref) => Stream<bool>.value(true)),
        ],
        child: const TracopApp(),
      ),
    );
    await tester.pumpAndSettle();

    final publishAction = find.text('Publicar mi primer lote');
    expect(publishAction, findsOneWidget);
    expect(find.text('Buscar lotes'), findsNothing);
    expect(tester.getRect(publishAction).bottom, lessThan(760));
  });

  testWidgets('Seller home keeps activity in the desktop content',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => _HomeAuthNotifier()),
          homeUserProvider.overrideWith((ref) async => _testUser()),
          homeLotsProvider.overrideWith((ref) async => const []),
          homeConnectivityProvider
              .overrideWith((ref) => Stream<bool>.value(true)),
        ],
        child: const TracopApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tu actividad'), findsOneWidget);
    expect(find.text('A mano'), findsNothing);
    expect(find.text('Mi perfil'), findsNothing);
    expect(find.text('Mis lotes'), findsOneWidget); // Sidebar destination only.
  });

  testWidgets('Draft metric opens the lots destination', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => _HomeAuthNotifier()),
          homeUserProvider.overrideWith((ref) async => _testUser()),
          homeLotsProvider.overrideWith((ref) async => [
                _testLot(id: 'published-lot', status: 'published'),
                _testLot(id: 'draft-lot', status: 'draft'),
              ]),
          homeConnectivityProvider
              .overrideWith((ref) => Stream<bool>.value(true)),
        ],
        child: const TracopApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Publicados'), findsOneWidget);
    expect(find.text('Borradores'), findsOneWidget);
    await tester.tap(find.text('Borradores'));
    await tester.pumpAndSettle();
    expect(find.text('Mis lotes'), findsWidgets);
    await tester.tap(find.text('Inicio').last);
    await tester.pumpAndSettle();
  });

  testWidgets('Home keeps one retry action when lot loading fails',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => _HomeAuthNotifier()),
          homeUserProvider.overrideWith((ref) async => _testUser()),
          homeLotsProvider
              .overrideWith((ref) async => throw Exception('offline')),
          homeConnectivityProvider
              .overrideWith((ref) => Stream<bool>.value(true)),
        ],
        child: const TracopApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No pudimos actualizar tus lotes.'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.text('No se pudo actualizar'), findsNothing);
  });

  testWidgets('Protected shell shows login when there is no session',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider
              .overrideWith((ref) => _HomeAuthNotifier(authenticated: false)),
        ],
        child: const MaterialApp(
          home: AuthenticatedShell(
            currentLocation: '/',
            child: Text('Contenido privado'),
          ),
        ),
      ),
    );

    expect(find.text('INICIAR SESIÓN'), findsOneWidget);
    expect(find.text('Contenido privado'), findsNothing);
  });

  testWidgets('Registration opens privacy and terms drafts separately',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeConnectivityProvider
              .overrideWith((ref) => Stream<bool>.value(true)),
        ],
        child: const MaterialApp(home: RegisterScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Leer términos de uso'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Leer términos de uso'));
    await tester.pumpAndSettle();
    expect(find.text('Términos de uso — borrador'), findsOneWidget);
    await tester.tap(find.text('Cerrar'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Leer aviso de privacidad'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Leer aviso de privacidad'));
    await tester.pumpAndSettle();
    expect(find.text('Aviso de privacidad — borrador'), findsOneWidget);
  });

  testWidgets('Profile name can be edited and saved', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _ProfileAuthRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          homeConnectivityProvider
              .overrideWith((ref) => Stream<bool>.value(true)),
        ],
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Editar nombre'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'A');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(
      find.text('Escribe un nombre de entre 2 y 160 caracteres.'),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField), 'Nombre actualizado');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('Nombre actualizado'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Editar nombre'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.text('Nombre actualizado'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Mobile header places online status before the profile',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeUserProvider.overrideWith(
            (ref) async => const User(
              id: 'header-test-user',
              role: 'producer',
              fullName: 'Karo Test',
              phone: '+573001234567',
              status: 'active',
              locale: 'es-CO',
            ),
          ),
          homeConnectivityProvider
              .overrideWith((ref) => Stream<bool>.value(true)),
        ],
        child: const MaterialApp(
          home: ResponsiveShell(
            currentLocation: '/buscar',
            child: SizedBox.expand(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final status = tester.getTopLeft(find.byIcon(Icons.cloud_done_outlined));
    final avatar = tester.getTopLeft(find.byType(CircleAvatar));
    expect(status.dx, lessThan(avatar.dx));
    expect(find.text('Karo Test'), findsNothing);
    expect(tester.widget<AppBar>(find.byType(AppBar)).toolbarHeight, 61);
  });
}

User _testUser({String role = 'producer'}) => User(
      id: 'home-test-user',
      role: role,
      fullName: 'Karo Test',
      phone: '+573001234567',
      status: 'active',
      locale: 'es-CO',
    );

class _HomeCatalogRepository implements CatalogRepository {
  @override
  Future<Result<List<Category>, DomainFailure>> getCategories() async =>
      const Ok([]);

  @override
  Future<Result<List<Product>, DomainFailure>> getProducts(
          {String? categoryId, String? q}) async =>
      const Ok([]);

  @override
  Future<Result<LotPage, DomainFailure>> searchLots({
    String? cursor,
    int limit = 20,
    String? categoryId,
    String? productId,
    String? q,
    int? minPrice,
    int? maxPrice,
    DateTime? availableFrom,
    DateTime? availableUntil,
    double? lat,
    double? lng,
    int? radiusKm,
    String sort = 'recent',
  }) async =>
      const Ok(LotPage(items: []));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Lot _testLot({required String id, required String status}) {
  final now = DateTime(2026, 1, 1);
  return Lot(
    id: id,
    productId: 'product-1',
    quantityMilli: '1000',
    unit: 'kg',
    unitPrice: '2500',
    availableFrom: now,
    availableUntil: now.add(const Duration(days: 1)),
    status: status,
    version: 1,
  );
}

class _HomeAuthNotifier extends AuthNotifier {
  _HomeAuthNotifier({bool authenticated = true})
      : super(_UnusedAuthRepository()) {
    state = authenticated
        ? AsyncValue.data(AuthSession(
            accessToken: 'test-access-token',
            refreshToken: 'test-refresh-token',
            accessTokenExpiresIn: 900,
            refreshTokenExpiresAt: DateTime.utc(2030),
            user: const User(
              id: 'test-user',
              role: 'buyer',
              fullName: 'Usuario de prueba',
              phone: '+573001234567',
              status: 'active',
              locale: 'es-CO',
            ),
          ))
        : const AsyncValue.data(null);
  }

  @override
  Future<bool> restoreSession() async => true;
}

class _UnusedAuthRepository implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ProfileAuthRepository implements AuthRepository {
  User user = const User(
    id: 'profile-test-user',
    role: 'producer',
    fullName: 'Nombre anterior',
    phone: '+573001234567',
    status: 'active',
    locale: 'es-CO',
  );

  @override
  Future<Result<User, DomainFailure>> getMe() async => Ok(user);

  @override
  Future<Result<User, DomainFailure>> updateMe(UpdateMeRequest request) async {
    user = User(
      id: user.id,
      role: user.role,
      fullName: request.fullName ?? user.fullName,
      phone: user.phone,
      status: user.status,
      locale: request.locale ?? user.locale,
    );
    return Ok(user);
  }

  @override
  Future<Result<User?, DomainFailure>> getStoredUser() async => Ok(user);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
