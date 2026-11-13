import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracop_mobile/shared/widgets/lot_interaction_widgets.dart';

void main() {
  testWidgets(
      'status filters show all four options and selected filter toggles to all',
      (tester) async {
    String? active = 'published';
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 360,
          child: StatusFilterGrid(
            selected: active,
            counts: const {null: 8, 'draft': 2, 'published': 3, 'cancelled': 0},
            onSelected: (value) => active = value,
          ),
        ),
      ),
    ));

    expect(find.text('Todos'), findsOneWidget);
    expect(find.text('Borradores'), findsOneWidget);
    expect(find.text('Publicados'), findsOneWidget);
    expect(find.text('Cancelados'), findsOneWidget);
    expect(tester.getSize(find.byType(StatusFilterGrid)).height, lessThan(220));

    await tester.tap(find.text('Publicados'));
    await tester.pumpAndSettle();
    expect(active, isNull);
  });

  testWidgets('lot thumbnail has an icon fallback when there is no photo',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: LotThumbnail(url: null, heroTag: 'lot-thumb-test'),
      ),
    ));
    expect(find.byIcon(Icons.spa_outlined), findsOneWidget);
  });
}
