import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracop_mobile/features/recommendations/presentation/pricing_mappings_screen.dart';
import 'package:tracop_mobile/features/recommendations/presentation/recommendations_provider.dart';
import 'package:tracop_mobile/features/recommendations/presentation/recommendations_screen.dart';

void main() {
  testWidgets('buyer sees recommended lots and price alerts', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          recommendedLotsProvider.overrideWith((ref) async => {
                'items': [
                  {
                    'lotId': 'lot-1',
                    'productId': 'product-1',
                    'unit': 'kg',
                    'unitPrice': '3200',
                    'distanceKm': 8,
                    'score': 70,
                    'reasons': ['good_price', 'nearby'],
                  },
                ],
                'nextCursor': null,
              }),
          priceAlertsProvider.overrideWith((ref) async => [
                {
                  'id': 'alert-1',
                  'productId': 'product-1',
                  'maxPrice': '4000',
                  'radiusKm': 50,
                  'centerLat': 4.65,
                  'centerLng': -74.1,
                },
              ]),
        ],
        child: const MaterialApp(home: RecommendationsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lotes para ti'), findsOneWidget);
    expect(find.textContaining('Buen precio'), findsOneWidget);
    expect(find.text('Alertas de precio'), findsOneWidget);
    expect(find.textContaining('Radio: 50 km'), findsOneWidget);
  });

  testWidgets('staff sees configured pricing mappings', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pricingMappingsProvider.overrideWith((ref) async => [
                {
                  'id': 'mapping-1',
                  'productId': 'product-1',
                  'unit': 'kg',
                  'source': 'DANE-SIPSA',
                  'sourceProduct': 'Papa criolla limpia',
                  'presentation': 'bulto 50 kg',
                },
              ]),
        ],
        child: const MaterialApp(home: PricingMappingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Asociaciones de precios'), findsOneWidget);
    expect(find.text('Papa criolla limpia'), findsOneWidget);
    expect(find.textContaining('bulto 50 kg'), findsOneWidget);
  });
}
