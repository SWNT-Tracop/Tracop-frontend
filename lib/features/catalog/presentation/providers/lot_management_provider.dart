import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/sync/sync_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../home/presentation/home_screen.dart' show homeUserProvider;
import '../../domain/entities/lot.dart' hide Category, Product;
import '../../domain/entities/category.dart' as catalog;
import '../../domain/entities/product.dart';
import 'catalog_provider.dart';

/// Lotes del proveedor autenticado, en todos sus estados.
final myLotsProvider = FutureProvider<List<Lot>>((ref) async {
  ref.watch(syncRevisionProvider);
  ref.watch(authProvider);
  final result = await ref.read(catalogRepositoryProvider).getMyLots();
  return result.map(
    ok: (value) => value.value,
    err: (failure) => throw failure,
  );
});

/// Frontend-only timestamps for edits made in this client; does not alter API data.
final localLotModifiedAtProvider =
    StateProvider<Map<String, DateTime>>((ref) => const {});

final lotSyncStatusesProvider = FutureProvider<Map<String, String>>((ref) {
  ref.watch(syncRevisionProvider);
  final userId = ref.watch(homeUserProvider).valueOrNull?.id;
  if (userId == null) return Future.value(const {});
  return ref.read(syncServiceProvider).lotOperationStatuses(userId);
});

/// Lote individual usado para editar un borrador.
final lotByIdProvider = FutureProvider.family<Lot, String>((ref, id) async {
  ref.watch(syncRevisionProvider);
  ref.watch(authProvider);
  final result = await ref.read(catalogRepositoryProvider).getLot(id);
  return result.map(
    ok: (value) => value.value,
    err: (failure) => throw failure,
  );
});

/// Catálogo de productos disponible para seleccionar en el formulario.
final catalogProductsProvider = FutureProvider<List<Product>>((ref) async {
  ref.watch(syncRevisionProvider);
  final result = await ref.read(catalogRepositoryProvider).getProducts();
  return result.map(
    ok: (value) => value.value,
    err: (failure) => throw failure,
  );
});

/// Categorías disponibles al registrar un producto nuevo.
final catalogCategoriesProvider =
    FutureProvider<List<catalog.Category>>((ref) async {
  ref.watch(syncRevisionProvider);
  final result = await ref.read(catalogRepositoryProvider).getCategories();
  return result.map(
    ok: (value) => value.value,
    err: (failure) => throw failure,
  );
});
