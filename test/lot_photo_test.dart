import 'package:flutter_test/flutter_test.dart';
import 'package:tracop_mobile/features/catalog/domain/entities/lot.dart';

void main() {
  test('lot reads photo metadata but does not persist signed image URLs', () {
    final lot = Lot.fromJson({
      'id': 'lot-1',
      'productId': 'product-1',
      'quantityMilli': '12000',
      'unit': 'kg',
      'unitPrice': '3000',
      'availableFrom': '2026-11-10T00:00:00.000Z',
      'availableUntil': '2026-11-17T23:59:59.000Z',
      'status': 'draft',
      'version': 1,
      'photos': [
        {
          'id': 'photo-1',
          'position': 1,
          'url': 'https://storage.example/photo?signature=temporary',
        },
      ],
    });

    expect(lot.photos, hasLength(1));
    expect(lot.photos.single.position, 1);
    expect(lot.photos.single.url, contains('signature=temporary'));
    expect(lot.toJson().containsKey('photos'), isFalse);
  });
}
