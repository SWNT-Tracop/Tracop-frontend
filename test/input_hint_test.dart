import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracop_mobile/app/theme.dart';
import 'package:tracop_mobile/features/auth/presentation/auth_screens.dart';
import 'package:tracop_mobile/features/home/presentation/home_screen.dart'
    show homeConnectivityProvider;

void main() {
  test('hints are lighter than typed text in both themes', () {
    final light = AppTheme.light.inputDecorationTheme.hintStyle?.color;
    expect(light, AppTheme.hintText);
    expect(light, isNot(AppTheme.ink));
    expect(AppTheme.dark.inputDecorationTheme.hintStyle?.color, isNotNull);
  });

  testWidgets('the phone example reads as an example', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        homeConnectivityProvider
            .overrideWith((ref) => Stream<bool>.value(true)),
      ],
      child: MaterialApp(theme: AppTheme.light, home: const LoginScreen()),
    ));
    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.decoration?.hintText, 'Ej.: 300 123 4567');
  });
}
