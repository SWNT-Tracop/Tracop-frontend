import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/lot.dart' hide Category, Product;
import '../../domain/entities/product.dart';
import '../../domain/repository/catalog_repository.dart';

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  throw UnimplementedError(
      'CatalogRepository requires CatalogRemoteDataSource and AppDatabase setup.');
});

final catalogProvider =
    StateNotifierProvider<CatalogNotifier, AsyncValue<Map<String, dynamic>>>(
        (ref) {
  final repo = ref.watch(catalogRepositoryProvider);
  return CatalogNotifier(repo);
});

class CatalogNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  final CatalogRepository _repo;

  CatalogNotifier(this._repo) : super(const AsyncValue.data({}));

  Future<void> loadCategories() async {
    state = const AsyncValue.loading();
    final result = await _repo.getCategories();
    state = result.map(
      ok: (ok) => AsyncValue.data({'categories': ok.value}),
      err: (err) => AsyncValue.error(err.error, StackTrace.current),
    );
  }

  Future<void> loadProducts({String? categoryId, String? q}) async {
    state = const AsyncValue.loading();
    final result = await _repo.getProducts(categoryId: categoryId, q: q);
    state = result.map(
      ok: (ok) => AsyncValue.data({'products': ok.value}),
      err: (err) => AsyncValue.error(err.error, StackTrace.current),
    );
  }

  Future<void> searchLots({
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
    state = const AsyncValue.loading();
    final result = await _repo.searchLots(
      cursor: cursor,
      limit: limit,
      categoryId: categoryId,
      productId: productId,
      q: q,
      minPrice: minPrice,
      maxPrice: maxPrice,
      availableFrom: availableFrom,
      availableUntil: availableUntil,
      lat: lat,
      lng: lng,
      radiusKm: radiusKm,
      sort: sort,
    );
    state = result.map(
      ok: (ok) => AsyncValue.data({'lots': ok.value}),
      err: (err) => AsyncValue.error(err.error, StackTrace.current),
    );
  }

  List<Category> get categories {
    final data = state.valueOrNull;
    if (data == null || data['categories'] == null) return const [];
    return List<Category>.from(data['categories'] as List);
  }

  List<Product> get products {
    final data = state.valueOrNull;
    if (data == null || data['products'] == null) return const [];
    return List<Product>.from(data['products'] as List);
  }

  LotPage get lotsPage {
    final data = state.valueOrNull;
    if (data == null || data['lots'] == null) return const LotPage(items: []);
    return data['lots'] as LotPage;
  }
}
