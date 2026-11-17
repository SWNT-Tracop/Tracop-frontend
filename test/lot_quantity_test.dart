import 'package:flutter_test/flutter_test.dart';
import 'package:tracop_mobile/features/catalog/domain/lot_quantity.dart';

void main() {
  group('parseQuantityMilli', () {
    test('accepts whole and decimal quantities', () {
      expect(parseQuantityMilli('25'), 25000);
      expect(parseQuantityMilli('25.5'), 25500);
      expect(parseQuantityMilli('0,125'), 125);
      expect(parseQuantityMilli(' 7 '), 7000);
    });

    test('rejects empty, zero, negative and malformed values', () {
      expect(parseQuantityMilli(''), isNull);
      expect(parseQuantityMilli('0'), isNull);
      expect(parseQuantityMilli('-1'), isNull);
      expect(parseQuantityMilli('1.2345'), isNull);
      expect(parseQuantityMilli('1,2,3'), isNull);
      expect(parseQuantityMilli('abc'), isNull);
    });

    test('enforces the server quantity limit', () {
      expect(parseQuantityMilli('999999999.999'), maxQuantityMilli);
      expect(parseQuantityMilli('1000000000'), isNull);
    });
  });

  group('formatQuantityMilli', () {
    test('drops unnecessary decimal zeros', () {
      expect(formatQuantityMilli('25000'), '25');
      expect(formatQuantityMilli('25500'), '25.5');
      expect(formatQuantityMilli('125'), '0.125');
      expect(formatQuantityMilli('1000'), '1');
    });
  });
}
