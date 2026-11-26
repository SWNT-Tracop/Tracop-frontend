import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tracop_mobile/app/router.dart' show router;
import 'package:tracop_mobile/core/i18n/strings.dart';
import 'package:tracop_mobile/features/auth/domain/entities/user.dart';
import 'package:tracop_mobile/features/auth/domain/repository/auth_repository.dart';
import 'package:tracop_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:tracop_mobile/features/home/presentation/home_screen.dart';
import 'package:tracop_mobile/features/payments/presentation/providers/payment_backoffice_provider.dart';
import 'package:tracop_mobile/features/payments/presentation/providers/payment_provider.dart';
import 'package:tracop_mobile/features/payments/presentation/screens/buyer_payment_screen.dart';
import 'package:tracop_mobile/features/payments/presentation/screens/payment_review_inbox_screen.dart';
import 'package:tracop_mobile/features/payments/presentation/screens/payments_dashboard_screen.dart';
import 'package:tracop_mobile/features/payments/presentation/screens/settlements_screen.dart';

import 'support/payment_fixtures.dart';

const _blocked = 'Esta sección no está disponible para tu cuenta.';

void main() {
  setUpAll(() => initializeDateFormatting('es_CO'));

  Future<void> pumpAt(WidgetTester tester, String location, String role) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    router.go(location);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authProvider.overrideWith((ref) => _SignedIn(role)),
        homeUserProvider.overrideWith((ref) async => User(
            id: 'user',
            role: role,
            fullName: 'Prueba',
            phone: '+573000000000',
            status: 'active',
            locale: 'es-CO')),
        homeConnectivityProvider
            .overrideWith((ref) => Stream<bool>.value(true)),
        homeLotsProvider.overrideWith((ref) async => const []),
        paymentRepositoryProvider.overrideWithValue(FakePaymentRepository()),
        paymentBackofficeRepositoryProvider
            .overrideWithValue(FakePaymentBackofficeRepository()),
      ],
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();
  }

  for (final role in ['finance', 'operator', 'admin']) {
    testWidgets('$role lands on the payments summary from /', (tester) async {
      await pumpAt(tester, '/', role);
      expect(router.routerDelegate.currentConfiguration.uri.path,
          '/pagos/resumen');
      expect(find.byType(PaymentsDashboardScreen), findsOneWidget);
      expect(find.text(NavStrings.home), findsNothing);
      // Destinos del personal en orden: resumen, revisión, liquidaciones.
      final labels = [
        NavStrings.paymentsSummary,
        NavStrings.paymentsReview,
        NavStrings.settlements,
        NavStrings.profile,
      ];
      for (final label in labels) {
        expect(find.text(label), findsWidgets);
      }
      final xs = [
        for (final label in labels.skip(1))
          tester.getCenter(find.text(label).last).dx
      ];
      expect(xs, orderedEquals([...xs]..sort()));
    });

    testWidgets('$role cannot open the buyer payment screen', (tester) async {
      await pumpAt(tester, '/pedidos/$orderIdFixture/pago', role);
      expect(find.byType(BuyerPaymentScreen), findsNothing);
      expect(find.text(_blocked), findsOneWidget);
    });
  }

  testWidgets('summary shortcut opens the inbox pre-filtered to proofs',
      (tester) async {
    await pumpAt(tester, '/pagos/resumen', 'finance');
    await tester.tap(find.text(PaymentsDashboardStrings.reviewProofs).first);
    await tester.pumpAndSettle();
    expect(
        router.routerDelegate.currentConfiguration.uri.path, '/pagos/revision');
    expect(find.byType(PaymentReviewInboxScreen), findsOneWidget);
    final chip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, PaymentStrings.filterProofs));
    expect(chip.selected, isTrue);
  });

  for (final (query, label) in [
    ('', NavStrings.paymentsReview),
    ('?desde=liquidaciones', NavStrings.settlements),
  ]) {
    testWidgets('payment detail$query highlights $label', (tester) async {
      await pumpAt(tester, '/pagos/$paymentId$query', 'finance');
      final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      final destination =
          bar.destinations[bar.selectedIndex] as NavigationDestination;
      expect(destination.label, label);
    });
  }

  testWidgets('staff can open the settlements destination', (tester) async {
    await pumpAt(tester, '/pagos/liquidaciones?estado=pagadas', 'operator');
    expect(find.byType(SettlementsScreen), findsOneWidget);
    final chip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, SettlementStrings.filterPaid));
    expect(chip.selected, isTrue);
  });

  for (final location in [
    '/pagos/resumen',
    '/pagos/revision',
    '/pagos/liquidaciones',
    '/pagos/$paymentId',
  ]) {
    testWidgets('buyer is blocked from $location', (tester) async {
      await pumpAt(tester, location, 'buyer');
      expect(find.byType(PaymentReviewInboxScreen), findsNothing);
      expect(find.text(_blocked), findsOneWidget);
    });
  }
}

class _SignedIn extends AuthNotifier {
  _SignedIn(String role) : super(_NoAuthRepository()) {
    state = AsyncValue.data(AuthSession(
      accessToken: 'test-access-token',
      refreshToken: 'test-refresh-token',
      accessTokenExpiresIn: 900,
      refreshTokenExpiresAt: DateTime.utc(2030),
      user: User(
          id: 'user',
          role: role,
          fullName: 'Prueba',
          phone: '+573000000000',
          status: 'active',
          locale: 'es-CO'),
    ));
  }
}

class _NoAuthRepository implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
