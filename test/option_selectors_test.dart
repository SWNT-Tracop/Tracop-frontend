import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracop_mobile/shared/widgets/option_selectors.dart';

void main() {
  testWidgets('searchable selector returns the original option value',
      (tester) async {
    String? selected;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SearchableSheetSelector<String>(
          label: 'Producto',
          value: selected,
          options: const [
            SelectorOption(value: 'tomato-id', label: 'Tomate chonto'),
            SelectorOption(value: 'potato-id', label: 'Papa criolla'),
          ],
          onChanged: (value) => selected = value,
        ),
      ),
    ));

    await tester.tap(find.text('Producto'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'papa');
    await tester.pumpAndSettle();
    expect(find.text('Tomate chonto'), findsNothing);
    await tester.tap(find.text('Papa criolla'));
    await tester.pumpAndSettle();

    expect(selected, 'potato-id');
  });

  testWidgets(
      'circle selector exposes selected option and supports reduced motion',
      (tester) async {
    String selected = 'producer';
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Scaffold(
          body: OptionCircleSelector<String>(
            value: selected,
            options: const [
              SelectorOption(value: 'producer', label: 'Productor'),
              SelectorOption(value: 'buyer', label: 'Comprador'),
            ],
            onChanged: (value) => selected = value,
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Comprador'));
    await tester.pumpAndSettle();
    expect(selected, 'buyer');
  });
}
