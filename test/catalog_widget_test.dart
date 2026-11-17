import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracop_mobile/app/app.dart';
import 'package:tracop_mobile/app/router.dart' as app_router;
import 'package:tracop_mobile/core/result/result.dart';
import 'package:tracop_mobile/features/auth/domain/entities/user.dart';
import 'package:tracop_mobile/features/auth/domain/repository/auth_repository.dart';
import 'package:tracop_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:tracop_mobile/features/catalog/domain/entities/category.dart';
import 'package:tracop_mobile/features/catalog/domain/entities/lot.dart'
    hide Category, Product;
import 'package:tracop_mobile/features/catalog/domain/entities/product.dart';
import 'package:tracop_mobile/features/catalog/domain/repository/catalog_repository.dart';
import 'package:tracop_mobile/features/catalog/presentation/providers/catalog_provider.dart';
import 'package:tracop_mobile/features/home/presentation/home_screen.dart';

void main() {
  testWidgets('search displays mocked lot and opens cached detail route',
      (tester) async {
    app_router.router.go('/');
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _CatalogRepository();
    await tester.pumpWidget(_testApp(repository));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buscar lotes'));
    await tester.pumpAndSettle();

    expect(find.text('Tomate chonto'), findsOneWidget);
    expect(find.textContaining('Bogotá'), findsWidgets);
    await tester.tap(find.text('Tomate chonto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver lote'));
    await tester.pumpAndSettle();

    expect(find.text('Detalle del lote'), findsOneWidget);
    expect(find.text('Ubicación de recogida'), findsNothing);
    expect(find.text('Precio por kg'), findsNothing); // Buyer price leads.
    expect(find.textContaining('3.000'), findsOneWidget);
    expect(find.text('12 kg'), findsOneWidget);
    expect(find.text('Disponible'), findsOneWidget);
    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.flip_rounded).first);
    await tester.pumpAndSettle();
    expect(find.text('Buscar lotes'), findsOneWidget);
    expect(find.text('Tomate chonto'), findsOneWidget);
  });

  testWidgets('web search uses a responsive two-column result grid',
      (tester) async {
    app_router.router.go('/');
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_testApp(_CatalogRepository()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buscar lotes'));
    await tester.pumpAndSettle();

    expect(find.text('Tomate chonto'), findsOneWidget);
    expect(find.text('Ordenar:'), findsOneWidget);
    expect(find.text('1 lote cargado'), findsOneWidget);
  });

  testWidgets('buyer search debounces text and sends supported filters',
      (tester) async {
    app_router.router.go('/');
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _CatalogRepository();
    await tester.pumpWidget(_testApp(repository));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buscar lotes'));
    await tester.pumpAndSettle();

    expect(repository.lastSort, 'price');
    await tester.enterText(find.byType(TextField).first, 'tomate');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(repository.lastQuery, 'tomate');

    await tester.tap(find.byTooltip('Abrir filtros'));
    await tester.pumpAndSettle();
    expect(find.text('Filtros'), findsOneWidget);
    expect(find.text('Categoría'), findsOneWidget);
    expect(find.text('Precio mínimo (COP)'), findsOneWidget);
    await tester.enterText(
        find.widgetWithText(TextField, 'Precio mínimo (COP)'), '2500');
    await tester.tap(find.text('Ver resultados'));
    await tester.pumpAndSettle();
    expect(repository.lastMinimumPrice, 2500);
    expect(find.textContaining('Precio desde'), findsOneWidget);
    expect(find.textContaining('2.500'), findsOneWidget);
  });

  testWidgets('price filter blocks an inverted range', (tester) async {
    app_router.router.go('/');
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _CatalogRepository();
    await tester.pumpWidget(_testApp(repository));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buscar lotes'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Abrir filtros'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextField, 'Precio mínimo (COP)'), '9000');
    await tester.enterText(
        find.widgetWithText(TextField, 'Precio máximo (COP)'), '1000');
    await tester.pump();
    expect(find.text('El mínimo no puede ser mayor que el máximo.'),
        findsOneWidget);
    final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Ver resultados'));
    expect(button.onPressed, isNull);

    await tester.enterText(
        find.widgetWithText(TextField, 'Precio máximo (COP)'), '12000');
    await tester.pump();
    await tester.tap(find.text('Ver resultados'));
    await tester.pumpAndSettle();
    expect(repository.lastMinimumPrice, 9000);
  });

  testWidgets('offline catalog labels cached results and their update time',
      (tester) async {
    app_router.router.go('/');
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _CatalogRepository(fromCache: true);
    await tester.pumpWidget(_testApp(repository, connected: false));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buscar lotes'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Sin conexión.'), findsOneWidget);
    expect(find.textContaining('Última actualización:'), findsOneWidget);
    expect(find.text('Tomate chonto'), findsOneWidget);
  });

  testWidgets('search failure offers a working retry', (tester) async {
    app_router.router.go('/');
    final repository = _CatalogRepository(failSearch: true);
    await tester.pumpWidget(_testApp(repository));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buscar lotes'));
    await tester.pumpAndSettle();

    expect(find.textContaining('No pudimos cargar los lotes'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
    final initialCalls = repository.searchCalls;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(repository.searchCalls, greaterThan(initialCalls));
  });
}

Widget _testApp(CatalogRepository repository, {bool connected = true}) =>
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(_AuthRepository()),
        authProvider.overrideWith((ref) => _AuthNotifier()),
        catalogRepositoryProvider.overrideWithValue(repository),
        homeUserProvider.overrideWith((ref) async => const User(
              id: 'user-test',
              role: 'buyer',
              fullName: 'Usuario prueba',
              phone: '+57000000000',
              status: 'active',
              locale: 'es-CO',
            )),
        homeLotsProvider.overrideWith((ref) async => const []),
        homeConnectivityProvider.overrideWith((ref) => Stream.value(connected)),
      ],
      child: const TracopApp(),
    );

class _CatalogRepository implements CatalogRepository {
  _CatalogRepository({this.failSearch = false, this.fromCache = false});
  final bool failSearch;
  final bool fromCache;
  int searchCalls = 0;
  String? lastQuery;
  String? lastSort;
  int? lastMinimumPrice;
  final lot = Lot(
    id: 'lot-test',
    productId: 'product-test',
    quantityMilli: '12000',
    unit: 'kg',
    unitPrice: '3000',
    availableFrom: DateTime.utc(2026, 11, 8),
    availableUntil: DateTime.utc(2026, 11, 20),
    status: 'published',
    version: 1,
    provider: const ProviderSummary(
      displayName: 'Finca de prueba',
      municipality: 'Bogotá',
      department: 'Cundinamarca',
    ),
  );

  @override
  Future<Result<List<Category>, DomainFailure>> getCategories() async =>
      const Ok([Category(id: 'category-test', name: 'Hortalizas', depth: 1)]);

  @override
  Future<Result<List<Product>, DomainFailure>> getProducts(
          {String? categoryId, String? q}) async =>
      const Ok([
        Product(
          id: 'product-test',
          categoryId: 'category-test',
          name: 'Tomate chonto',
          unit: 'kg',
          attributes: {},
        )
      ]);

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
  }) async {
    searchCalls++;
    if (failSearch) {
      return const Err(DomainFailure(
          statusCode: 503,
          code: 'unavailable',
          message: 'Catalog temporarily unavailable'));
    }
    lastQuery = q;
    lastSort = sort;
    lastMinimumPrice = minPrice;
    return Ok(LotPage(
      items: [lot],
      cachedAt: DateTime.utc(2026, 11, 8),
      isFromCache: fromCache,
    ));
  }

  @override
  Future<Result<Lot, DomainFailure>> getLot(String id) async => Ok(lot);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _AuthNotifier extends AuthNotifier {
  _AuthNotifier() : super(_AuthRepository()) {
    state = AsyncValue.data(AuthSession(
      accessToken: 'test-token',
      refreshToken: 'test-refresh',
      accessTokenExpiresIn: 900,
      refreshTokenExpiresAt: DateTime.utc(2030),
      user: const User(
        id: 'user-test',
        role: 'buyer',
        fullName: 'Usuario prueba',
        phone: '+57000000000',
        status: 'active',
        locale: 'es-CO',
      ),
    ));
  }

  @override
  Future<bool> restoreSession() async => true;
}

class _AuthRepository implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
