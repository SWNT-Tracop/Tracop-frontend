import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:tracop_mobile/core/result/result.dart';
import 'package:tracop_mobile/core/storage/app_database.dart';
import 'package:tracop_mobile/features/logistics/data/logistics_remote.dart';
import 'package:tracop_mobile/features/logistics/data/logistics_repository.dart';
import 'package:tracop_mobile/features/ordering/data/remote/order_remote.dart';
import 'package:tracop_mobile/features/ordering/data/repository/order_repository_impl.dart';
import 'package:tracop_mobile/features/ordering/domain/entities/order.dart';

void main() {
  late AppDatabase database;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    await database.delete(database.syncState).go();
    await database.delete(database.outboxOperations).go();
  });

  tearDown(() => database.close());

  test('local payment exposes a candidate and stores its trip without pushing',
      () async {
    const orderId = '018f47a2-8b45-7cc2-9a1e-123456789abc';
    final orderRemote = _OrderRemote(_orderJson(orderId));
    final orders = OrderRepositoryImpl(remote: orderRemote, db: database);
    final order = OrderResponse.fromJson(_orderJson(orderId));

    final payment = await orders.simulatePaymentLocally(order);
    final paidOrder = payment.map(ok: (value) => value.value, err: (_) => null);
    expect(paidOrder?.status, 'paid');
    expect(paidOrder?.isLocallyPaid, isTrue);
    expect(orderRemote.acceptCalls, 0);
    final cachedOrderResult = await orders.getOrderById(orderId);
    final cachedOrder =
        cachedOrderResult.map(ok: (value) => value.value, err: (_) => null);
    expect(cachedOrder?.status, 'paid');
    expect(cachedOrder?.isLocallyPaid, isTrue);

    final logisticsRemote = _LogisticsRemote();
    final logistics = LogisticsRepository(
      remote: logisticsRemote,
      database: database,
    );
    final candidates = await logistics.getCandidates('carrier-user');
    expect(candidates, hasLength(1));
    expect(candidates.single.orderId, orderId);
    expect(candidates.single.isLocalPayment, isTrue);
    expect(candidates.single.deliveryZone, 'bogotá');
    expect(candidates.single.toJson().containsKey('deliveryAddress'), isFalse);

    final createdLocally =
        await logistics.createTrip('carrier-user', [orderId]);
    expect(createdLocally, isTrue);
    expect(logisticsRemote.pushCalls, 0);

    final trips = await logistics.getTrips('carrier-user');
    expect(trips, hasLength(1));
    expect(trips.single.isLocalOnly, isTrue);
    final stops = await logistics.getStops('carrier-user', trips.single.id);
    expect(stops.map((stop) => stop.kind), ['pickup', 'delivery']);
    expect(logisticsRemote.stopCalls, 0);
  });

  test('does not locally mark a quote as paid before it is accepted', () async {
    final orders = OrderRepositoryImpl(
      remote: _OrderRemote(
          _orderJson('018f47a2-8b45-7cc2-9a1e-123456789abd', status: 'quoted')),
      db: database,
    );
    final result = await orders.simulatePaymentLocally(
      OrderResponse.fromJson(
          _orderJson('018f47a2-8b45-7cc2-9a1e-123456789abd', status: 'quoted')),
    );

    expect(result, isA<Err>());
    expect(await database.select(database.syncState).get(), isEmpty);
  });
}

Map<String, dynamic> _orderJson(String id, {String status = 'accepted'}) => {
      'id': id,
      'status': status,
      'version': 2,
      'createdAt': '2026-11-20T12:00:00.000Z',
      'lines': [
        {
          'lotId': '018f47a2-8b45-7cc2-9a1e-123456789abd',
          'quantityMilli': '2000',
          'unit': 'kg',
          'unitPrice': '5000',
        },
      ],
      'subtotal': '10000',
      'freight': '1000',
      'commission': '200',
      'total': '11000',
      'providerNet': '9800',
      'provider': {
        'displayName': 'Finca El Roble',
        'municipality': 'Tunja',
        'department': 'Boyacá',
      },
      'deliveryAddress': 'Calle 10 # 2-3, Bogotá',
      'deliveryWindow': null,
      'acceptedAt': '2026-11-20T11:00:00.000Z',
      'cancelReason': null,
      'quoteValidUntil': '2026-11-21T12:00:00.000Z',
    };

class _OrderRemote implements OrderRemoteDataSource {
  _OrderRemote(this.order);
  final Map<String, dynamic> order;
  int acceptCalls = 0;

  @override
  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> body) async =>
      order;

  @override
  Future<Map<String, dynamic>> listOrders(
          String endpoint, Map<String, dynamic> query) async =>
      {
        'items': [order]
      };

  @override
  Future<Map<String, dynamic>> getOrder(String id) async => order;

  @override
  Future<Map<String, dynamic>> acceptQuote(
      String id, Map<String, dynamic> body) async {
    acceptCalls++;
    return order;
  }

  @override
  Future<Map<String, dynamic>> cancelOrder(
          String id, Map<String, dynamic> body) async =>
      order;
}

class _LogisticsRemote implements LogisticsRemoteDataSource {
  int pushCalls = 0;
  int stopCalls = 0;

  @override
  Future<Map<String, dynamic>> getCarrierProfile() async => {
        'vehicleType': 'Camión',
        'capacityKg': 2000,
        'plate': 'ABC123',
      };

  @override
  Future<List<Map<String, dynamic>>> getCandidates() async => [];

  @override
  Future<List<Map<String, dynamic>>> getTrips() async => [];

  @override
  Future<List<Map<String, dynamic>>> getStops(String tripId) async {
    stopCalls++;
    return [];
  }

  @override
  Future<Map<String, dynamic>> push(
      List<Map<String, dynamic>> operations) async {
    pushCalls++;
    return {'results': []};
  }
}
