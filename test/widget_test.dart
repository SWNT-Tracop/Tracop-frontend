import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracop_mobile/app/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: TracopApp()));
    expect(find.text('TRACOP'), findsOneWidget);
  });
}
