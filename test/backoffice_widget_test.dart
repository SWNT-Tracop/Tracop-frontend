import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracop_mobile/features/backoffice/presentation/backoffice_provider.dart';
import 'package:tracop_mobile/features/backoffice/presentation/backoffice_screen.dart';

import 'support/backoffice_fixtures.dart';

void main() {
  Future<void> pumpSection(
    WidgetTester tester,
    BackofficeSection section, {
    List<dynamic>? categories,
    List<dynamic>? products,
    List<dynamic>? audit,
    Map<String, dynamic>? logistics,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          backofficeMetricsProvider
              .overrideWith((ref) async => backofficeMetricsFixture),
          backofficeCategoriesProvider.overrideWith(
              (ref) async => categories ?? backofficeCategoriesFixture),
          backofficeProductsProvider.overrideWith(
              (ref) async => products ?? backofficeProductsFixture),
          backofficeAuditProvider
              .overrideWith((ref) async => audit ?? backofficeAuditFixture),
          backofficeLogisticsProvider.overrideWith(
              (ref) async => logistics ?? backofficeLogisticsFixture),
        ],
        child: MaterialApp(
          home: BackofficeScreen(section: section),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('dashboard displays operational metrics', (tester) async {
    await pumpSection(tester, BackofficeSection.dashboard);

    expect(find.text('Resumen operativo'), findsOneWidget);
    expect(find.text('Comprobantes por revisar'), findsOneWidget);
    expect(find.text('Notificaciones fallidas'), findsOneWidget);
    expect(find.text('Outbox pendientes'), findsOneWidget);
  });

  testWidgets('catalog displays products and categories', (tester) async {
    await pumpSection(tester, BackofficeSection.catalog);

    expect(find.text('Catálogo curado'), findsOneWidget);
    expect(find.text('Tomate chonto'), findsOneWidget);
    await tester.tap(find.text('Categorías'));
    await tester.pumpAndSettle();
    expect(find.text('Hortalizas'), findsOneWidget);
  });

  testWidgets('audit displays before and after values', (tester) async {
    await pumpSection(tester, BackofficeSection.audit);

    expect(find.textContaining('parameter.update'), findsOneWidget);
    await tester.tap(find.textContaining('parameter.update'));
    await tester.pumpAndSettle();
    expect(find.textContaining('order.freight_cop'), findsOneWidget);
    expect(find.textContaining('15000'), findsOneWidget);
    expect(find.textContaining('18000'), findsOneWidget);
  });

  testWidgets('logistics displays trips, incidents and conflicts',
      (tester) async {
    await pumpSection(tester, BackofficeSection.logistics);

    expect(find.text('Viajes activos (1)'), findsOneWidget);
    expect(find.text('Incidencias (1)'), findsOneWidget);
    expect(find.textContaining('order-1'), findsOneWidget);
    await tester.tap(find.text('Viajes activos (1)'));
    await tester.pumpAndSettle();
    expect(find.text('trip-1'), findsOneWidget);
  });

  testWidgets('new product explains when there are no categories',
      (tester) async {
    await pumpSection(tester, BackofficeSection.catalog, categories: const []);

    await tester.tap(find.text('Nuevo producto'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Primero crea una categoría'), findsOneWidget);
  });
}
