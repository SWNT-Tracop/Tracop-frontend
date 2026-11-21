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
  static const _localPaymentCandidatesKey =
      'logistics:local-payment-candidates';

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
      final hydrated = OrderPage(
        items: await _applyLocalPaymentState(merged.items),
        nextCursor: merged.nextCursor,
        isFromCache: merged.isFromCache,
      );
      await _write(key, hydrated.toJson());
      for (final order in hydrated.items) {
        await _write('ordering_detail_${order.id}', order.toJson());
      }
      return Ok(hydrated);
    } on Object catch (error) {
      final cached = await _readPage(key);
      if (cached != null) {
        return Ok(OrderPage(
          items: await _applyLocalPaymentState(cached.items),
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
      final hydrated = (await _applyLocalPaymentState([order])).single;
      await _write('ordering_detail_$id', hydrated.toJson());
      return Ok(hydrated);
    } on Object catch (error) {
      final cached = await _readJson('ordering_detail_$id');
      if (cached != null) {
        final order = OrderResponse.fromJson(cached);
        return Ok((await _applyLocalPaymentState([order])).single);
      }
      return Err(_failure(error));
    }
  }

  @override
  Future<Result<OrderResponse, DomainFailure>> simulatePaymentLocally(
      OrderResponse order) async {
    if (order.isLocallyPaid) return Ok(order);
    if (order.status != 'accepted' && order.status != 'payment_pending') {
      return const Err(DomainFailure(
        statusCode: 409,
        code: 'payment_not_ready',
        message: 'El pedido todavía no está listo para registrar el pago.',
      ));
    }
    final candidate = _localCandidateFor(order);
    final candidates = await _readLocalPaymentCandidates();
    candidates.removeWhere((item) => item['orderId'] == order.id);
    candidates.add(candidate);
    await _writeLocalPaymentCandidates(candidates);
    final updated = order.copyWith(status: 'paid', isLocallyPaid: true);
    await _write('ordering_detail_${order.id}', updated.toJson());
    return Ok(updated);
  }

  Map<String, dynamic> _localCandidateFor(OrderResponse order) {
    final provider = order.provider ?? const <String, dynamic>{};
    final pickupZone = _firstText([
      provider['municipality'],
      provider['department'],
      provider['displayName'],
    ]);
    return {
      'orderId': order.id,
      'deliveryZone': _deliveryZone(order.deliveryAddress),
      'deliveryWindow': order.deliveryWindow?.toIso8601String(),
      'pickupZones': [pickupZone],
      'lines': order.lines
          .map((line) => {
                'lotId': line.lotId,
                'quantityMilli': line.quantityMilli,
                'unit': line.unit,
              })
          .toList(growable: false),
      'isLocalPayment': true,
    };
  }

  String _firstText(List<dynamic> values) {
    for (final value in values) {
      if (value is String && value.trim().isNotEmpty) {
        return value.trim().toLowerCase();
      }
    }
    return 'sin-zona';
  }

  String _deliveryZone(String? address) {
    final parts = (address ?? '')
        .split(',')
        .map(
            (part) => part.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' '))
        .where((part) => part.isNotEmpty);
    final streetTerms = RegExp(
        r'\d|#|\b(calle|cll|carrera|cra|avenida|av|diagonal|diag|transversal|tv|autopista|kil[oó]metro|km)\b');
    for (final part in parts.toList().reversed) {
      if (!streetTerms.hasMatch(part)) return part;
    }
    return 'zona de entrega';
  }

  Future<List<OrderResponse>> _applyLocalPaymentState(
      List<OrderResponse> orders) async {
    final paidIds = (await _readLocalPaymentCandidates())
        .map((item) => item['orderId'] as String?)
        .whereType<String>()
        .toSet();
    return orders
        .map((order) => paidIds.contains(order.id)
            ? order.copyWith(status: 'paid', isLocallyPaid: true)
            : order)
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> _readLocalPaymentCandidates() async {
    final row = await (db.select(db.syncState)
          ..where((value) => value.key.equals(_localPaymentCandidatesKey)))
        .getSingleOrNull();
    if (row == null) return [];
    return (jsonDecode(row.value) as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<void> _writeLocalPaymentCandidates(
      List<Map<String, dynamic>> candidates) async {
    await db.into(db.syncState).insertOnConflictUpdate(
          SyncStateCompanion.insert(
            key: _localPaymentCandidatesKey,
            value: jsonEncode(candidates),
          ),
        );
  }

  @override
  Future<Result<OrderResponse, DomainFailure>> acceptQuote(
          String id, int expectedVersion) =>
      _mutate(() async => OrderResponse.fromJson(await remote.acceptQuote(
          id, AcceptQuoteRequest(expectedVersion: expectedVersion).toJson())));

  @override
  Future<Result<OrderResponse, DomainFailure>> cancelOrder(
      String id, int expectedVersion,
      {String? reason}) async {
    final result = await _mutate(() async => OrderResponse.fromJson(
        await remote.cancelOrder(
            id,
            CancelOrderRequest(expectedVersion: expectedVersion, reason: reason)
                .toJson())));
    if (result is Ok<OrderResponse, DomainFailure>) {
      final candidates = await _readLocalPaymentCandidates();
      candidates.removeWhere((item) => item['orderId'] == id);
      await _writeLocalPaymentCandidates(candidates);
    }
    return result;
  }

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
