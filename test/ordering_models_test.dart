import 'package:flutter_test/flutter_test.dart';
import 'package:tracop_mobile/features/ordering/domain/entities/order.dart';

void main() {
  group('CreateOrderRequest', () {
    test('serializes exact API fields and keeps quantities as milli strings',
        () {
      const request = CreateOrderRequest(
        id: '018f47a2-8b45-7cc2-9a1e-123456789abc',
        lines: [
          OrderLineInput(
            lotId: '018f47a2-8b45-7cc2-9a1e-123456789abd',
            quantityMilli: '1250',
          ),
        ],
        deliveryAddress: '  Calle 1, Bogotá  ',
      );

      expect(request.toJson(), {
        'id': '018f47a2-8b45-7cc2-9a1e-123456789abc',
        'lines': [
          {
            'lotId': '018f47a2-8b45-7cc2-9a1e-123456789abd',
            'quantityMilli': '1250',
          },
        ],
        'deliveryAddress': 'Calle 1, Bogotá',
      });
    });

    test('serializes optional delivery window as UTC ISO date', () {
      final request = CreateOrderRequest(
        id: '018f47a2-8b45-7cc2-9a1e-123456789abc',
        lines: const [],
        deliveryAddress: 'Calle 1',
        deliveryWindow: DateTime.utc(2026, 11, 20, 8),
      );

      expect(request.toJson()['deliveryWindow'], '2026-11-20T08:00:00.000Z');
    });
  });

  test('parses private buyer fields as optional and preserves order version',
      () {
    final order = OrderResponse.fromJson({
      'id': '018f47a2-8b45-7cc2-9a1e-123456789abc',
      'status': 'quoted',
      'version': 3,
      'createdAt': '2026-11-17T12:00:00.000Z',
      'lines': [
        {
          'lotId': '018f47a2-8b45-7cc2-9a1e-123456789abd',
          'quantityMilli': '1250',
          'unit': 'kg',
          'unitPrice': '3000',
        },
      ],
      'subtotal': '3750',
      'freight': '1000',
      'commission': '100',
      'total': '4750',
      'providerNet': '3650',
      'acceptedAt': null,
      'cancelReason': null,
      'quoteValidUntil': '2026-11-20T12:00:00.000Z',
    });

    expect(order.version, 3);
    expect(order.amounts.total, '4750');
    expect(order.deliveryAddress, isNull);
    expect(OrderResponse.fromJson(order.toJson()).id, order.id);
    expect(OrderResponse.fromJson(order.toJson()).isLocallyPaid, isFalse);
  });

  test('preserves locally registered payment state in the cache model', () {
    final order = OrderResponse.fromJson({
      'id': '018f47a2-8b45-7cc2-9a1e-123456789abc',
      'status': 'accepted',
      'version': 3,
      'createdAt': '2026-11-17T12:00:00.000Z',
      'lines': [],
      'subtotal': '3750',
      'freight': '1000',
      'commission': '100',
      'total': '4750',
      'providerNet': '3650',
      'acceptedAt': null,
      'cancelReason': null,
      'quoteValidUntil': '2026-11-20T12:00:00.000Z',
    }).copyWith(status: 'paid', isLocallyPaid: true);

    final restored = OrderResponse.fromJson(order.toJson());
    expect(restored.status, 'paid');
    expect(restored.isLocallyPaid, isTrue);
  });

  test('serializes optimistic-concurrency request fields', () {
    expect(const AcceptQuoteRequest(expectedVersion: 7).toJson(), {
      'expectedVersion': 7,
    });
    expect(
      const CancelOrderRequest(expectedVersion: 7, reason: '  Cambio  ')
          .toJson(),
      {'expectedVersion': 7, 'reason': 'Cambio'},
    );
    expect(const CancelOrderRequest(expectedVersion: 2).toJson(), {
      'expectedVersion': 2,
    });
  });
}
