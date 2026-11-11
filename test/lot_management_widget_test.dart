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
  testWidgets('my lots lists drafts and publishes them', (tester) async {
    app_router.router.go('/lotes');
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _LotRepository();
    await tester.pumpWidget(_testApp(repository));
    await tester.pumpAndSettle();

    expect(find.text('Mis lotes').first, findsOneWidget);
    expect(find.text('Tomate chonto'), findsOneWidget);
    expect(find.text('Borrador'), findsOneWidget);

    await tester.tap(find.text('Publicar').first);
    await tester.pumpAndSettle();
    expect(find.text('Publicar lote'), findsOneWidget);
    await tester.tap(find.text('Publicar').last);
    await tester.pumpAndSettle();

    expect(repository.publishCalls, 1);
    expect(find.text('Lote publicado.'), findsOneWidget);
  });

  testWidgets('lot form validates fields and creates a draft', (tester) async {
    app_router.router.go('/lotes/nuevo');
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _LotRepository();
    await tester.pumpWidget(_testApp(repository));
    await tester.pumpAndSettle();

    expect(find.text('Nuevo lote'), findsOneWidget);
    await _scrollTo(tester, find.text('Guardar borrador').last);
    await tester.tap(find.text('Guardar borrador').last);
    await tester.pumpAndSettle();
    expect(find.text('Completa los campos marcados para continuar.'),
        findsOneWidget);
    expect(find.text('Elige el producto que vas a ofrecer.'), findsOneWidget);
    expect(find.text('Escribe una cantidad mayor que cero (máx. 3 decimales).'),
        findsOneWidget);
    expect(
        find.text('Escribe un precio entero mayor que cero.'), findsOneWidget);
    expect(find.text('Escribe una latitud válida.'), findsOneWidget);
    expect(find.text('Escribe una longitud válida.'), findsOneWidget);
    expect(
        tester
            .getTopLeft(
                find.text('Completa los campos marcados para continuar.'))
            .dy,
        lessThan(844));
    expect(repository.created, isNull);

    await _scrollTo(tester, find.byType(DropdownButtonFormField<String>));
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tomate chonto · kg').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Cantidad'), '25.5');
    await tester.enterText(
        find.widgetWithText(TextField, 'Precio por unidad'), '3200');
    await tester.enterText(find.widgetWithText(TextField, 'Latitud'), '14');
    await tester.enterText(find.widgetWithText(TextField, 'Longitud'), '-73.3');

    await _scrollTo(tester, find.text('Guardar borrador').last);
    await tester.tap(find.text('Guardar borrador').last);
    await tester.pumpAndSettle();
    expect(find.text('Completa los campos marcados para continuar.'),
        findsOneWidget);
    expect(find.text('Revisa la ubicación.'), findsOneWidget);
    expect(
        find.text('Las coordenadas deben estar en Colombia.'), findsOneWidget);
    expect(repository.created, isNull);

    await tester.enterText(find.widgetWithText(TextField, 'Latitud'), '5.5353');
    await _scrollTo(tester, find.text('Guardar borrador').last);
    await tester.tap(find.text('Guardar borrador').last);
    await tester.pumpAndSettle();

    final created = repository.created;
    expect(created, isNotNull);
    expect(created!.quantityMilli, '25500');
    expect(created.unitPrice, 3200);
    expect(created.unit, 'kg');
    expect(created.qualityGrade, isNull);
    expect(created.locationLat, 5.5353);
    expect(created.locationLng, -73.3);
    expect(find.text('Mis lotes').first, findsOneWidget);
  });

  testWidgets('save and publish creates the lot before publishing it',
      (tester) async {
    app_router.router.go('/lotes/nuevo');
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _LotRepository();
    await tester.pumpWidget(_testApp(repository));
    await tester.pumpAndSettle();

    await _scrollTo(tester, find.byType(DropdownButtonFormField<String>));
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tomate chonto · kg').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Cantidad'), '25');
    await tester.enterText(
        find.widgetWithText(TextField, 'Precio por unidad'), '3200');
    await tester.enterText(find.widgetWithText(TextField, 'Latitud'), '5.5353');
    await tester.enterText(find.widgetWithText(TextField, 'Longitud'), '-73.3');

    await _scrollTo(tester, find.text('Guardar y publicar'));
    await tester.tap(find.text('Guardar y publicar'));
    await tester.pumpAndSettle();

    expect(repository.created, isNotNull);
    expect(repository.publishCalls, 1);
    expect(find.text('Lote publicado.'), findsOneWidget);
  });

  testWidgets('offline save button explains why it cannot save',
      (tester) async {
    app_router.router.go('/lotes/nuevo');
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _LotRepository();
    await tester.pumpWidget(_testApp(repository, connected: false));
    await tester.pumpAndSettle();

    await _scrollTo(tester, find.text('Guardar borrador').last);
    await tester.tap(find.text('Guardar borrador').last);
    await tester.pumpAndSettle();

    expect(
      find.text('Conéctate a internet para guardar el lote.'),
      findsOneWidget,
    );
    expect(repository.created, isNull);
  });

  testWidgets('producer can create a product from the lot form',
      (tester) async {
    app_router.router.go('/lotes/nuevo');
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _LotRepository();
    await tester.pumpWidget(_testApp(repository));
    await tester.pumpAndSettle();

    await _scrollTo(
        tester, find.text('No encuentro mi producto · Crear producto'));
    await tester.tap(find.text('No encuentro mi producto · Crear producto'));
    await tester.pumpAndSettle();

    expect(find.text('Crear producto'), findsOneWidget);
    await tester.enterText(
        find.byKey(const ValueKey('new-product-name')), 'Papa criolla');
    await tester.tap(find.byKey(const ValueKey('new-product-category')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tubérculos').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Crear y usar producto'));
    await tester.pumpAndSettle();

    expect(repository.createdProduct?.name, 'Papa criolla');
    expect(repository.createdProduct?.unit, 'kg');
    expect(repository.createdProduct?.categoryId, 'category-test');
    expect(find.text('Papa criolla · kg'), findsOneWidget);
  });
}

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    280,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

Widget _testApp(CatalogRepository repository, {bool connected = true}) =>
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(_AuthRepository()),
        authProvider.overrideWith((ref) => _ProducerAuthNotifier()),
        catalogRepositoryProvider.overrideWithValue(repository),
        homeUserProvider.overrideWith((ref) async => const User(
              id: 'producer-test',
              role: 'producer',
              fullName: 'Productor prueba',
              phone: '+57000000000',
              status: 'active',
              locale: 'es-CO',
            )),
        homeLotsProvider.overrideWith((ref) async => const []),
        homeConnectivityProvider.overrideWith((ref) => Stream.value(connected)),
      ],
      child: const TracopApp(),
    );

class _LotRepository implements CatalogRepository {
  int publishCalls = 0;
  int cancelCalls = 0;
  int deleteCalls = 0;
  CreateLotRequest? created;
  CreateProductRequest? createdProduct;
  UpdateLotRequest? updated;

  Lot _lot({String status = 'draft', int version = 1}) => Lot(
        id: 'lot-test',
        providerId: 'producer-test',
        productId: 'product-test',
        quantityMilli: '25000',
        unit: 'kg',
        unitPrice: '3200',
        qualityGrade: 'Primera',
        availableFrom: DateTime.utc(2026, 11, 10),
        availableUntil: DateTime.utc(2026, 11, 20),
        status: status,
        version: version,
        locationLat: 5.5353,
        locationLng: -73.3678,
        isMine: true,
      );

  @override
  Future<Result<List<Category>, DomainFailure>> getCategories() async =>
      const Ok([
        Category(id: 'category-test', name: 'Tubérculos', depth: 1),
      ]);

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
  Future<Result<Product, DomainFailure>> createProduct(
      CreateProductRequest request) async {
    createdProduct = request;
    return Ok(Product(
      id: request.id,
      categoryId: request.categoryId,
      name: request.name,
      unit: request.unit,
      attributes: const {},
    ));
  }

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
      Ok(LotPage(items: [_lot()]));

  @override
  Future<Result<Lot, DomainFailure>> getLot(String id) async => Ok(_lot());

  @override
  Future<Result<List<Lot>, DomainFailure>> getMyLots() async => Ok([_lot()]);

  @override
  Future<Result<Lot, DomainFailure>> createLot(CreateLotRequest request) async {
    created = request;
    return Ok(_lot());
  }

  @override
  Future<Result<Lot, DomainFailure>> updateLot(
      String id, UpdateLotRequest request) async {
    updated = request;
    return Ok(_lot(version: request.version + 1));
  }

  @override
  Future<Result<Lot, DomainFailure>> publishLot(String id, int version) async {
    publishCalls++;
    return Ok(_lot(status: 'published', version: version + 1));
  }

  @override
  Future<Result<Lot, DomainFailure>> cancelLot(String id, int version) async {
    cancelCalls++;
    return Ok(_lot(status: 'cancelled', version: version + 1));
  }

  @override
  Future<Result<void, DomainFailure>> deleteLot(String id, int version) async {
    deleteCalls++;
    return const Ok(null);
  }
}

class _ProducerAuthNotifier extends AuthNotifier {
  _ProducerAuthNotifier() : super(_AuthRepository()) {
    state = AsyncValue.data(AuthSession(
      accessToken: 'test-token',
      refreshToken: 'test-refresh',
      accessTokenExpiresIn: 900,
      refreshTokenExpiresAt: DateTime.utc(2030),
      user: const User(
        id: 'producer-test',
        role: 'producer',
        fullName: 'Productor prueba',
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
