import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/result/result.dart';
import '../../../../core/storage/app_database.dart';
import '../../domain/entities/order.dart';
import '../../domain/repository/order_repository.dart';
import '../remote/order_remote.dart';

class OrderRepositoryImpl implements OrderRepository {
  OrderRepositoryImpl({required this.remote, required this.db});

  final OrderRemoteDataSource remote;
  final AppDatabase db;

  @override
  Future<Result<OrderResponse, DomainFailure>> createOrder(
          CreateOrderRequest request) =>
      _mutate(() async =>
          OrderResponse.fromJson(await remote.createOrder(request.toJson())));

  @override
  Future<Result<OrderPage, DomainFailure>> listMyOrders(
          {String? cursor, int limit = 20}) =>
      _list('mine', cursor: cursor, limit: limit);

  @override
  Future<Result<OrderPage, DomainFailure>> listIncomingOrders(
          {String? cursor, int limit = 20}) =>
      _list('incoming', cursor: cursor, limit: limit);

  Future<Result<OrderPage, DomainFailure>> _list(String name,
      {String? cursor, required int limit}) async {
    final key = 'ordering_$name';
    try {
      final json = await remote.listOrders('/orders/$name', {
        'limit': limit,
        if (cursor != null) 'cursor': cursor,
      });
      final page = OrderPage.fromJson(json);
      final cached = cursor == null ? null : await _readPage(key);
      final merged = OrderPage(
        items: cached == null
            ? page.items
            : [
                ...cached.items.where((old) =>
                    !page.items.any((current) => current.id == old.id)),
                ...page.items,
              ],
        nextCursor: page.nextCursor,
      );
      await _write(key, merged.toJson());
      for (final order in page.items) {
        await _write('ordering_detail_${order.id}', order.toJson());
      }
      return Ok(page);
    } on Object catch (error) {
      final cached = await _readPage(key);
      if (cached != null) {
        return Ok(OrderPage(
          items: cached.items,
          nextCursor: cached.nextCursor,
          isFromCache: true,
        ));
      }
      return Err(_failure(error));
    }
  }

  @override
  Future<Result<OrderResponse, DomainFailure>> getOrderById(String id) async {
    try {
      final order = OrderResponse.fromJson(await remote.getOrder(id));
      await _write('ordering_detail_$id', order.toJson());
      return Ok(order);
    } on Object catch (error) {
      final cached = await _readJson('ordering_detail_$id');
      if (cached != null) return Ok(OrderResponse.fromJson(cached));
      return Err(_failure(error));
    }
  }

  @override
  Future<Result<OrderResponse, DomainFailure>> acceptQuote(
          String id, int expectedVersion) =>
      _mutate(() async => OrderResponse.fromJson(await remote.acceptQuote(
          id, AcceptQuoteRequest(expectedVersion: expectedVersion).toJson())));

  @override
  Future<Result<OrderResponse, DomainFailure>> cancelOrder(
          String id, int expectedVersion, {String? reason}) =>
      _mutate(() async => OrderResponse.fromJson(await remote.cancelOrder(
          id,
          CancelOrderRequest(expectedVersion: expectedVersion, reason: reason)
              .toJson())));

  Future<Result<OrderResponse, DomainFailure>> _mutate(
      Future<OrderResponse> Function() action) async {
    // Ordering has no sync push handler; these writes are intentionally online-only.
    try {
      final order = await action();
      await _write('ordering_detail_${order.id}', order.toJson());
      return Ok(order);
    } on Object catch (error) {
      return Err(_failure(error));
    }
  }

  DomainFailure _failure(Object error) {
    if (error is DomainFailure) return error;
    if (error is DioException && error.error is DomainFailure) {
      return error.error! as DomainFailure;
    }
    if (error is DioException) {
      final code = (error.response?.data is Map)
          ? (error.response!.data as Map)['code'] as String?
          : null;
      return DomainFailure(
        statusCode: error.response?.statusCode ?? 503,
        code: code ??
            (error.type == DioExceptionType.connectionError
                ? 'offline'
                : 'network_error'),
        message: 'No se pudo conectar con TRACOP. Intenta de nuevo.',
      );
    }
    return const DomainFailure(
        statusCode: 500,
        code: 'unknown',
        message: 'No se pudo cargar el pedido.');
  }

  Future<void> _write(String key, Map<String, dynamic> data) async {
    await db.into(db.syncState).insertOnConflictUpdate(
          SyncStateCompanion.insert(key: key, value: jsonEncode(data)),
        );
  }

  Future<Map<String, dynamic>?> _readJson(String key) async {
    final row = await (db.select(db.syncState)
          ..where((row) => row.key.equals(key)))
        .getSingleOrNull();
    if (row == null) return null;
    return Map<String, dynamic>.from(jsonDecode(row.value) as Map);
  }

  Future<OrderPage?> _readPage(String key) async {
    final json = await _readJson(key);
    return json == null
        ? null
        : OrderPage.fromJson({...json, '_fromCache': true});
  }
}
