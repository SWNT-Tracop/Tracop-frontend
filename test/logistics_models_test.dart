import 'package:flutter_test/flutter_test.dart';
import 'package:tracop_mobile/features/logistics/domain/logistics_models.dart';

void main() {
  test('parses the minimized candidate contract without personal data', () {
    final candidate = OrderCandidate.fromJson({
      'orderId': 'order-uuid',
      'status': 'paid',
      'version': 2,
      'deliveryZone': 'Bogotá',
      'deliveryWindow': null,
      'pickupZones': ['Tunja'],
      'lines': [
        {'lotId': 'lot-uuid', 'quantityMilli': '12500', 'unit': 'kg'},
      ],
    });

    expect(candidate.orderId, 'order-uuid');
    expect(candidate.deliveryZone, 'Bogotá');
    expect(candidate.lines.single.quantityMilli, '12500');
    expect(candidate.toJson().containsKey('deliveryAddress'), isFalse);
    expect(candidate.toJson().containsKey('buyerId'), isFalse);
  });

  test('parses carrier trips and route stops for the driver workflow', () {
    final trip = CarrierTrip.fromJson({
      'id': 'trip-uuid',
      'status': 'in_progress',
      'version': 3,
      'plannedAt': '2026-11-20T12:00:00.000Z',
    });
    final stop = TripStop.fromJson({
      'id': 'stop-uuid',
      'orderId': 'order-uuid',
      'kind': 'pickup',
      'sequence': 1,
      'zone': 'Tunja',
      'completedAt': null,
    });

    expect(trip.status, 'in_progress');
    expect(trip.version, 3);
    expect(stop.kind, 'pickup');
    expect(stop.completedAt, isNull);
  });
}
