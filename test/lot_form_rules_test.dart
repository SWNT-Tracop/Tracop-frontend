import 'package:flutter_test/flutter_test.dart';
import 'package:tracop_mobile/features/catalog/domain/entities/lot.dart'
    hide Category, Product;
import 'package:tracop_mobile/features/catalog/domain/lot_form_rules.dart';

void main() {
  group('parseUnitPrice', () {
    test('accepts positive integer pesos', () {
      expect(parseUnitPrice('1'), 1);
      expect(parseUnitPrice('3200'), 3200);
      expect(parseUnitPrice(' 45000 '), 45000);
      expect(parseUnitPrice('$maxSafeUnitPrice'), maxSafeUnitPrice);
    });

    test('rejects empty, zero, negative, decimal and unsafe values', () {
      expect(parseUnitPrice(''), isNull);
      expect(parseUnitPrice('0'), isNull);
      expect(parseUnitPrice('-100'), isNull);
      expect(parseUnitPrice('3.5'), isNull);
      expect(parseUnitPrice('3 200'), isNull);
      expect(parseUnitPrice('${maxSafeUnitPrice + 1}'), isNull);
    });
  });

  group('parseCoordinate', () {
    test('accepts decimal points and commas', () {
      expect(parseCoordinate('5.5353'), 5.5353);
      expect(parseCoordinate('5,5353'), 5.5353);
      expect(parseCoordinate('-73.3678'), -73.3678);
    });

    test('rejects empty and non numeric values', () {
      expect(parseCoordinate(''), isNull);
      expect(parseCoordinate('abc'), isNull);
      expect(parseCoordinate('NaN'), isNull);
      expect(parseCoordinate('Infinity'), isNull);
    });
  });

  group('isWithinColombia', () {
    test('accepts coordinates inside the country and its bounds', () {
      expect(isWithinColombia(5.5353, -73.3678), isTrue);
      expect(isWithinColombia(colombiaMinLat, colombiaMinLng), isTrue);
      expect(isWithinColombia(colombiaMaxLat, colombiaMaxLng), isTrue);
    });

    test('rejects coordinates outside the country', () {
      expect(isWithinColombia(14, -73.3678), isFalse);
      expect(isWithinColombia(5.5353, -82), isFalse);
      expect(isWithinColombia(5.5353, -60), isFalse);
    });
  });

  group('validateAvailability', () {
    final now = DateTime(2026, 11, 10, 15, 30);

    test('accepts ranges inside the horizon', () {
      expect(
        validateAvailability(
          DateTime(2026, 11, 10),
          DateTime(2026, 11, 20),
          now: now,
        ),
        isNull,
      );
      expect(
        validateAvailability(
          DateTime(2026, 11, 10),
          DateTime(2026, 11, 10),
          now: now,
        ),
        isNull,
      );
    });

    test('accepts the last full day inside the horizon', () {
      final lastDay =
          dateOnly(now.add(const Duration(days: lotMaxHorizonDays - 1)));
      expect(
        validateAvailability(
          DateTime(2026, 11, 10),
          lastDay,
          now: now,
        ),
        isNull,
      );
    });

    test('rejects a final day whose end falls beyond the horizon', () {
      final boundary =
          dateOnly(now.add(const Duration(days: lotMaxHorizonDays)));
      expect(
        validateAvailability(
          DateTime(2026, 11, 10),
          boundary,
          now: now,
        ),
        contains('$lotMaxHorizonDays días'),
      );
    });

    test('rejects inverted and out of horizon ranges', () {
      expect(
        validateAvailability(
          DateTime(2026, 11, 20),
          DateTime(2026, 11, 10),
          now: now,
        ),
        contains('posterior'),
      );
      expect(
        validateAvailability(
          DateTime(2026, 11, 10),
          DateTime(2026, 11, 10)
              .add(const Duration(days: lotMaxHorizonDays + 1)),
          now: now,
        ),
        contains('$lotMaxHorizonDays días'),
      );
    });
  });

  group('UpdateLotRequest', () {
    test('serializes the full editable snapshot including nullable quality',
        () {
      final request = UpdateLotRequest(
        version: 3,
        productId: 'product-1',
        quantityMilli: '25500',
        unit: 'kg',
        unitPrice: 3200,
        qualityGrade: null,
        availableFrom: DateTime.utc(2026, 11, 10),
        availableUntil: DateTime.utc(2026, 11, 20),
        locationLat: 5.5353,
        locationLng: -73.3678,
      );

      expect(request.toJson(), {
        'version': 3,
        'productId': 'product-1',
        'quantityMilli': '25500',
        'unit': 'kg',
        'unitPrice': 3200,
        'qualityGrade': null,
        'availableFrom': '2026-11-10T00:00:00.000Z',
        'availableUntil': '2026-11-20T00:00:00.000Z',
        'locationLat': 5.5353,
        'locationLng': -73.3678,
      });
    });
  });

  group('Lot location', () {
    test('reads owner coordinates and keeps them when serializing', () {
      final lot = Lot.fromJson({
        'id': 'lot-1',
        'providerId': 'provider-1',
        'productId': 'product-1',
        'quantityMilli': '25000',
        'unit': 'kg',
        'unitPrice': '3200',
        'qualityGrade': 'Primera',
        'availableFrom': '2026-11-10T00:00:00.000Z',
        'availableUntil': '2026-11-20T00:00:00.000Z',
        'status': 'draft',
        'version': 1,
        'locationLat': 5.5353,
        'locationLng': -73.3678,
        'isMine': true,
      });

      expect(lot.locationLat, 5.5353);
      expect(lot.locationLng, -73.3678);
      expect(lot.toJson()['locationLat'], 5.5353);
      expect(lot.toJson()['locationLng'], -73.3678);
    });

    test('leaves coordinates null when the API hides them', () {
      final lot = Lot.fromJson({
        'id': 'lot-2',
        'productId': 'product-1',
        'quantityMilli': '25000',
        'unit': 'kg',
        'unitPrice': '3200',
        'qualityGrade': null,
        'availableFrom': '2026-11-10T00:00:00.000Z',
        'availableUntil': '2026-11-20T00:00:00.000Z',
        'status': 'published',
        'version': 2,
      });

      expect(lot.locationLat, isNull);
      expect(lot.locationLng, isNull);
    });
  });
}
