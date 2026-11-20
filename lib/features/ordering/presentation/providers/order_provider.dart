import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/order.dart';
import '../../domain/repository/order_repository.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  throw UnimplementedError(
      'OrderRepository requires OrderRemoteDataSource and AppDatabase setup.');
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
