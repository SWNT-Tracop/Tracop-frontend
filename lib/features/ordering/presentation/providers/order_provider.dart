import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/catalog_config.dart';

import '../../domain/entities/order.dart';
import '../../domain/repository/order_repository.dart';
import '../../../catalog/domain/entities/lot.dart' hide Category, Product;
import '../../../catalog/presentation/providers/catalog_provider.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  throw UnimplementedError(
      'OrderRepository requires OrderRemoteDataSource and AppDatabase setup.');
});

/// Published lots shown in the buyer checkout selector.
final orderLotsProvider = FutureProvider<List<Lot>>((ref) async {
  final result = await ref
      .read(catalogRepositoryProvider)
      .searchLots(limit: CatalogConfig.pageSize);
  return result.map(
      ok: (value) => value.value.items, err: (failure) => throw failure.error);
});

final myOrdersProvider =
    FutureProvider.family<OrderPage, String?>((ref, cursor) async {
  final result =
      await ref.read(orderRepositoryProvider).listMyOrders(cursor: cursor);
  return result.map(
      ok: (value) => value.value, err: (failure) => throw failure.error);
});

final incomingOrdersProvider =
    FutureProvider.family<OrderPage, String?>((ref, cursor) async {
  final result = await ref
      .read(orderRepositoryProvider)
      .listIncomingOrders(cursor: cursor);
  return result.map(
      ok: (value) => value.value, err: (failure) => throw failure.error);
});

final orderDetailProvider =
    FutureProvider.family<OrderResponse, String>((ref, id) async {
  final result = await ref.read(orderRepositoryProvider).getOrderById(id);
  return result.map(
      ok: (value) => value.value, err: (failure) => throw failure.error);
});
