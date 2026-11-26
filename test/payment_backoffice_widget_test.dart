import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tracop_mobile/core/i18n/strings.dart';
import 'package:tracop_mobile/core/result/result.dart';
import 'package:tracop_mobile/features/auth/domain/entities/user.dart';
import 'package:tracop_mobile/features/auth/domain/repository/auth_repository.dart';
import 'package:tracop_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:tracop_mobile/features/home/presentation/home_screen.dart';
import 'package:tracop_mobile/features/payments/domain/entities/ledger.dart';
import 'package:tracop_mobile/features/payments/domain/entities/payments_metrics.dart';
import 'package:tracop_mobile/features/payments/domain/entities/settlement.dart';
import 'package:tracop_mobile/features/payments/domain/settlement_filters.dart';
import 'package:tracop_mobile/features/payments/presentation/providers/payment_backoffice_provider.dart';
import 'package:tracop_mobile/features/payments/presentation/providers/payment_provider.dart';
import 'package:tracop_mobile/features/payments/presentation/screens/payments_dashboard_screen.dart';
import 'package:tracop_mobile/features/payments/presentation/screens/settlements_screen.dart';
import 'package:tracop_mobile/features/payments/presentation/screens/staff_payment_detail_screen.dart';
import 'package:tracop_mobile/features/payments/presentation/widgets/ledger_section.dart';
import 'package:tracop_mobile/features/payments/presentation/widgets/mark_settlement_paid_dialog.dart';

import 'support/payment_fixtures.dart';

const _conflict =
    DomainFailure(statusCode: 409, code: 'version_conflict', message: 'x');

void main() {
  setUpAll(() => initializeDateFormatting('es_CO'));

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    FakePaymentBackofficeRepository? backoffice,
    FakePaymentRepository? payments,
    Size size = const Size(420, 1600),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authProvider.overrideWith((ref) => AuthNotifier(_NoAuthRepository())),
        paymentBackofficeRepositoryProvider
            .overrideWithValue(backoffice ?? FakePaymentBackofficeRepository()),
        paymentRepositoryProvider
            .overrideWithValue(payments ?? FakePaymentRepository()),
        homeUserProvider.overrideWith((ref) async => const User(
            id: 'user',
            role: 'finance',
            fullName: 'Prueba',
            phone: '+573000000000',
            status: 'active',
            locale: 'es-CO')),
      ],
      child: MaterialApp(home: Scaffold(body: child)),
    ));
    await tester.pumpAndSettle();
  }

  group('MarkSettlementPaidDialog', () {
    Future<List<Object?>> open(
        WidgetTester tester,
        Future<Result<Settlement, DomainFailure>> Function(String)
            onSubmit) async {
      final results = <Object?>[];
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () async => results.add(await showDialog<Object>(
                context: context,
                barrierDismissible: false,
                builder: (_) => MarkSettlementPaidDialog(
                    settlement: settlementFixture(), onSubmit: onSubmit),
              )),
              child: const Text('abrir'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      return results;
    }

    testWidgets('warns it is irreversible and requires a reference',
        (tester) async {
      var calls = 0;
      await open(tester, (_) async {
        calls++;
        return Ok(settlementFixture());
      });
      expect(find.text(SettlementStrings.irreversibleWarning), findsOneWidget);
      expect(find.text(r'$90.000'), findsOneWidget);

      await tester.tap(find.text(SettlementStrings.continueLabel));
      await tester.pump();
      expect(find.text(SettlementStrings.referenceRequired), findsOneWidget);
      expect(calls, 0);

      await tester.enterText(find.byType(TextField), 'a' * 101);
      await tester.tap(find.text(SettlementStrings.continueLabel));
      await tester.pump();
      // maxLength corta a 100; la validación acepta 100.
      expect(find.text(SettlementStrings.confirmTitle), findsOneWidget);
      expect(calls, 0);
      expect(validateSettlementReference('a' * 101),
          SettlementStrings.referenceTooLong);
      expect(validateSettlementReference('  '),
          SettlementStrings.referenceRequired);
    });

    testWidgets('confirm step disables buttons while busy and pops the result',
        (tester) async {
      final completer = Completer<Result<Settlement, DomainFailure>>();
      final references = <String>[];
      final results = await open(tester, (reference) {
        references.add(reference);
        return completer.future;
      });
      await tester.enterText(find.byType(TextField), '  TRX-77 ');
      await tester.tap(find.text(SettlementStrings.continueLabel));
      await tester.pump();
      expect(find.text(SettlementStrings.confirmTitle), findsOneWidget);
      expect(find.text('"TRX-77"'), findsOneWidget);
      expect(find.text(SettlementStrings.irreversibleWarning), findsOneWidget);

      await tester.tap(find.byKey(const Key('confirm-mark-paid')));
      await tester.pump();
      final confirm = tester
          .widget<FilledButton>(find.byKey(const Key('confirm-mark-paid')));
      final back = tester.widget<TextButton>(
          find.widgetWithText(TextButton, CommonStrings.back));
      expect(confirm.onPressed, isNull);
      expect(back.onPressed, isNull);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // Un segundo toque no envía otra vez.
      await tester.tap(find.byKey(const Key('confirm-mark-paid')),
          warnIfMissed: false);
      expect(references, ['TRX-77']);

      final paid = settlementFixture(
          status: 'paid',
          paidAt: '2026-11-25T10:00:00.000Z',
          reference: 'TRX-77');
      completer.complete(Ok(paid));
      await tester.pumpAndSettle();
      expect(find.byType(MarkSettlementPaidDialog), findsNothing);
      expect(results.single, same(paid));
    });

    testWidgets('system back does not close the dialog while busy',
        (tester) async {
      final completer = Completer<Result<Settlement, DomainFailure>>();
      await open(tester, (_) => completer.future);
      await tester.enterText(find.byType(TextField), 'TRX');
      await tester.tap(find.text(SettlementStrings.continueLabel));
      await tester.pump();
      await tester.tap(find.byKey(const Key('confirm-mark-paid')));
      await tester.pump();

      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.byType(MarkSettlementPaidDialog), findsOneWidget);

      completer.complete(const Err(_conflict));
      await tester.pumpAndSettle();
      expect(find.byType(MarkSettlementPaidDialog), findsNothing);
    });

    testWidgets('version conflict closes the dialog with the failure',
        (tester) async {
      final results = await open(tester, (_) async => const Err(_conflict));
      await tester.enterText(find.byType(TextField), 'TRX');
      await tester.tap(find.text(SettlementStrings.continueLabel));
      await tester.pump();
      await tester.tap(find.byKey(const Key('confirm-mark-paid')));
      await tester.pumpAndSettle();
      expect(find.byType(MarkSettlementPaidDialog), findsNothing);
      expect((results.single! as DomainFailure).code, 'version_conflict');
    });

    testWidgets('already paid stays open with a settlement-specific message',
        (tester) async {
      await open(
          tester,
          (_) async => const Err(DomainFailure(
              statusCode: 409, code: 'invalid_transition', message: 'x')));
      await tester.enterText(find.byType(TextField), 'TRX');
      await tester.tap(find.text(SettlementStrings.continueLabel));
      await tester.pump();
      await tester.tap(find.byKey(const Key('confirm-mark-paid')));
      await tester.pumpAndSettle();
      expect(find.byType(MarkSettlementPaidDialog), findsOneWidget);
      expect(
          find.textContaining('La liquidación ya fue pagada'), findsOneWidget);
    });
  });

  group('SettlementsScreen', () {
    testWidgets('lists issued settlements with \$ amounts and filters',
        (tester) async {
      final backoffice = FakePaymentBackofficeRepository()
        ..settlementItems = [
          settlementFixture(issuedAt: '2026-11-24T12:00:00.000Z'),
          settlementFixture(
              id: '018f47a2-8b45-7cc2-9a1e-1234567890a2',
              beneficiaryKind: 'carrier',
              amount: '15000',
              issuedAt: '2026-11-24T12:00:00.000Z'),
          settlementFixture(
              id: '018f47a2-8b45-7cc2-9a1e-1234567890a3',
              status: 'paid',
              amount: '40000',
              paidAt: '2026-11-24T13:00:00.000Z',
              reference: 'TRX-1'),
        ];
      await pump(
        tester,
        SettlementsScreen(clock: () => DateTime.utc(2026, 11, 25)),
        backoffice: backoffice,
        size: const Size(1300, 1400),
      );
      expect(backoffice.settlementCalls, [SettlementStatus.issued]);
      expect(find.text(r'$90.000'), findsOneWidget);
      expect(find.text(r'$15.000'), findsOneWidget);
      expect(find.text(r'$40.000'), findsNothing);
      expect(find.text(SettlementStrings.markPaid), findsNWidgets(2));

      await tester.tap(find.widgetWithText(ChoiceChip, 'Transportista'));
      await tester.pumpAndSettle();
      expect(find.text(r'$90.000'), findsNothing);
      expect(find.text(r'$15.000'), findsOneWidget);

      await tester
          .tap(find.widgetWithText(ChoiceChip, SettlementStrings.filterPaid));
      await tester.pumpAndSettle();
      expect(backoffice.settlementCalls.last, SettlementStatus.paid);
      expect(find.text(SettlementStrings.noMatchesTitle), findsOneWidget);
      await tester.tap(find.text(PaymentStrings.clearFilters));
      await tester.pumpAndSettle();
      expect(find.text(r'$40.000'), findsOneWidget);
      expect(find.text('TRX-1'), findsOneWidget);
      expect(find.text(SettlementStrings.markPaid), findsNothing);
    });

    testWidgets('initial query filters by payment id', (tester) async {
      final backoffice = FakePaymentBackofficeRepository()
        ..settlementItems = [
          settlementFixture(),
          settlementFixture(
              id: '018f47a2-8b45-7cc2-9a1e-1234567890a2',
              paymentId: '018f47a2-8b45-7cc2-9a1e-cccccccccccc',
              amount: '15000'),
        ];
      await pump(tester, const SettlementsScreen(initialQuery: paymentId),
          backoffice: backoffice);
      expect(find.text(r'$90.000'), findsOneWidget);
      expect(find.text(r'$15.000'), findsNothing);
      expect(find.text(SettlementStrings.resultsCount(1, 2)), findsOneWidget);
    });

    testWidgets('conflict shows the conflict dialog and reloads the list',
        (tester) async {
      final backoffice = FakePaymentBackofficeRepository()
        ..settlementItems = [settlementFixture()]
        ..onMarkPaid = (_) async => const Err(_conflict);
      await pump(tester, const SettlementsScreen(), backoffice: backoffice);
      final metricsBefore = backoffice.metricsCalls;
      final listCalls = backoffice.settlementCalls.length;

      await tester.tap(find.byKey(const Key('mark-paid-$settlementId')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'TRX');
      await tester.tap(find.text(SettlementStrings.continueLabel));
      await tester.pump();
      await tester.tap(find.byKey(const Key('confirm-mark-paid')));
      await tester.pumpAndSettle();

      expect(find.text(SettlementStrings.conflictTitle), findsOneWidget);
      await tester.tap(find.text(PaymentStrings.loadLatest));
      await tester.pumpAndSettle();
      expect(backoffice.markPaidCalls, 1);
      expect(backoffice.settlementCalls.length, greaterThan(listCalls));
      // Las métricas alimentan el aviso de liquidaciones ocultas.
      expect(backoffice.metricsCalls, greaterThan(metricsBefore));
    });

    testWidgets('success shows a confirmation and reloads', (tester) async {
      final backoffice = FakePaymentBackofficeRepository()
        ..settlementItems = [settlementFixture()];
      backoffice.onMarkPaid = (reference) async {
        final paid = settlementFixture(
            status: 'paid',
            paidAt: '2026-11-25T10:00:00.000Z',
            reference: reference);
        backoffice.settlementItems = [paid];
        return Ok(paid);
      };
      await pump(tester, const SettlementsScreen(), backoffice: backoffice);
      await tester.tap(find.byKey(const Key('mark-paid-$settlementId')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'TRX-5');
      await tester.tap(find.text(SettlementStrings.continueLabel));
      await tester.pump();
      await tester.tap(find.byKey(const Key('confirm-mark-paid')));
      await tester.pumpAndSettle();
      expect(find.text(SettlementStrings.markedPaid), findsOneWidget);
      // La lista de emitidas se recargó y ya no la incluye.
      expect(find.text(SettlementStrings.emptyTitle), findsOneWidget);
    });

    testWidgets('warns about older issued settlements the API did not return',
        (tester) async {
      final backoffice = FakePaymentBackofficeRepository()
        ..settlementItems = [settlementFixture()]
        ..metricsValue = PaymentsMetrics.fromJson(metricsJson(issuedCount: 5));
      await pump(tester, const SettlementsScreen(), backoffice: backoffice);
      expect(find.byKey(const Key('hidden-issued-alert')), findsOneWidget);
      expect(find.text(SettlementStrings.hiddenIssued(4)), findsOneWidget);

      // En "Pagadas" no aplica.
      await tester
          .tap(find.widgetWithText(ChoiceChip, SettlementStrings.filterPaid));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('hidden-issued-alert')), findsNothing);
    });

    testWidgets('no warning when every issued settlement is loaded',
        (tester) async {
      final backoffice = FakePaymentBackofficeRepository()
        ..settlementItems = [settlementFixture()]
        ..metricsValue = PaymentsMetrics.fromJson(metricsJson(issuedCount: 1));
      await pump(tester, const SettlementsScreen(), backoffice: backoffice);
      expect(find.byKey(const Key('hidden-issued-alert')), findsNothing);
    });

    testWidgets('unknown status and kind render raw labels without action',
        (tester) async {
      final backoffice = FakePaymentBackofficeRepository()
        ..metricsValue = PaymentsMetrics.fromJson(metricsJson(issuedCount: 0))
        ..settlementItems = [
          settlementFixture(status: 'cancelled', beneficiaryKind: 'supplier'),
        ];
      // El falso filtra por estado conocido; "Todas" no envía estado.
      await pump(tester,
          const SettlementsScreen(initialStatus: SettlementStatusFilter.all),
          backoffice: backoffice, size: const Size(1300, 1200));
      expect(find.text('cancelled'), findsOneWidget);
      expect(find.text('supplier'), findsOneWidget);
      expect(find.text(SettlementStrings.markPaid), findsNothing);
      expect(find.text(SettlementStrings.noReference), findsOneWidget);
    });

    testWidgets('empty state', (tester) async {
      await pump(tester, const SettlementsScreen());
      expect(find.text(SettlementStrings.emptyTitle), findsOneWidget);
      expect(find.text(SettlementStrings.emptyIssuedBody), findsOneWidget);
    });
  });

  group('PaymentsDashboardScreen', () {
    testWidgets('renders amounts, overdue alert and the paid bar',
        (tester) async {
      await pump(tester, const PaymentsDashboardScreen(),
          size: const Size(1200, 1400));
      expect(find.text(r'$250.000'), findsWidgets);
      expect(find.text(r'$750.000'), findsWidgets);
      expect(find.text(r'$1.200.000'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.byKey(const Key('overdue-alert')), findsOneWidget);
      expect(find.textContaining('hace 2 d'), findsWidgets);
      expect(find.textContaining('Actualizado:'), findsOneWidget);
      expect(find.textContaining('10:00'), findsOneWidget);
      expect(find.text(PaymentsDashboardStrings.barTitle), findsOneWidget);
      expect(find.textContaining('75 %', findRichText: true), findsOneWidget);
      expect(find.textContaining('25 %', findRichText: true), findsOneWidget);
      expect(find.textContaining(r'Pagado $750.000', findRichText: true),
          findsOneWidget);
      expect(
          find.text(PaymentsDashboardStrings.pendingCount(2)), findsOneWidget);
    });

    testWidgets('no alert when the oldest proof is recent', (tester) async {
      final backoffice = FakePaymentBackofficeRepository()
        ..metricsValue = PaymentsMetrics.fromJson(metricsJson(
            oldestProofUploadedAt: '2026-11-25T13:00:00.000Z',
            issuedAmount: '0',
            issuedCount: 0,
            paidAmount: '0',
            paidCount: 0));
      await pump(tester, const PaymentsDashboardScreen(),
          backoffice: backoffice);
      expect(find.byKey(const Key('overdue-alert')), findsNothing);
      expect(find.text(PaymentsDashboardStrings.oldest('hace 2 h')),
          findsOneWidget);
      expect(find.text(PaymentsDashboardStrings.barEmpty), findsOneWidget);
    });

    testWidgets('a tiny pending amount stays visible in the bar',
        (tester) async {
      final backoffice = FakePaymentBackofficeRepository()
        ..metricsValue = PaymentsMetrics.fromJson(metricsJson(
            paidAmount: '100000000', issuedAmount: '1000', issuedCount: 1));
      await pump(tester, const PaymentsDashboardScreen(),
          backoffice: backoffice);
      final paid = tester.getSize(find.byKey(const Key('bar-paid'))).width;
      final issued = tester.getSize(find.byKey(const Key('bar-issued'))).width;
      expect(issued / (paid + issued), closeTo(0.04, 0.005));
      expect(
          find.text(PaymentsDashboardStrings.pendingCount(1)), findsOneWidget);
    });

    testWidgets('manual refresh reloads metrics', (tester) async {
      final backoffice = FakePaymentBackofficeRepository();
      await pump(tester, const PaymentsDashboardScreen(),
          backoffice: backoffice);
      expect(backoffice.metricsCalls, 1);
      await tester.tap(find.text(PaymentStrings.refresh));
      await tester.pumpAndSettle();
      expect(backoffice.metricsCalls, 2);
    });
  });

  group('ledger', () {
    testWidgets('balanced ledger shows Spanish kinds, \$ amounts and Cuadrado',
        (tester) async {
      await pump(
          tester,
          SingleChildScrollView(
            child: LedgerView(
                summary: LedgerSummary.fromEntries(balancedLedger())),
          ));
      expect(find.text('Pago verificado'), findsOneWidget);
      expect(find.text('Entrega confirmada'), findsOneWidget);
      expect(find.text(LedgerStrings.accountName('cash_held')), findsOneWidget);
      expect(find.text(r'$100.000'), findsNWidgets(3));
      expect(find.text(r'$200.000'), findsNWidgets(2));
      // Dos transacciones + total.
      expect(find.text(LedgerStrings.balanced), findsNWidgets(3));
    });

    testWidgets('unbalanced ledger warns', (tester) async {
      final summary = LedgerSummary.fromEntries([
        ...balancedLedger(),
        LedgerEntry.fromJson(ledgerEntryJson(
            transactionId: '018f47a2-8b45-7cc2-9a1e-1234567890c5',
            kind: 'settlement_paid_producer',
            account: 'payable_producer',
            debit: '90000',
            createdAt: '2026-11-22T15:00:00.000Z')),
      ]);
      await pump(
          tester, SingleChildScrollView(child: LedgerView(summary: summary)));
      expect(find.text(LedgerStrings.unbalanced(r'$90.000')), findsNWidgets(2));
      expect(find.text(LedgerStrings.unbalancedHelp), findsOneWidget);
    });

    testWidgets('total balanced with an unbalanced transaction is flagged',
        (tester) async {
      final summary = LedgerSummary.fromEntries([
        LedgerEntry.fromJson(ledgerEntryJson(debit: '10')),
        LedgerEntry.fromJson(ledgerEntryJson(
            transactionId: transactionB, kind: 'fx_gain', credit: '10')),
      ]);
      await pump(
          tester, SingleChildScrollView(child: LedgerView(summary: summary)));
      expect(find.text(LedgerStrings.someUnbalanced), findsOneWidget);
      expect(find.text(LedgerStrings.unbalanced(r'$0')), findsNothing);
      expect(find.text('fx_gain'), findsOneWidget);
    });

    testWidgets('ledger fits 360 px with text scale 1.3', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final summary = LedgerSummary.fromEntries([
        ...balancedLedger(),
        LedgerEntry.fromJson(ledgerEntryJson(
            transactionId: '018f47a2-8b45-7cc2-9a1e-1234567890c5',
            kind: 'settlement_paid_carrier',
            account: 'payable_carrier',
            debit: '1234567890',
            createdAt: '2026-11-22T15:00:00.000Z')),
      ]);
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.3)),
            child: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: LedgerView(summary: summary),
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text(r'$1.234.567.890'), findsWidgets);
    });

    testWidgets('held payment without settlements explains the claim window',
        (tester) async {
      final payments = FakePaymentRepository()
        ..queue = [
          paymentFixture(status: 'held', heldAt: '2026-11-21T15:00:00.000Z')
        ];
      await pump(tester, const StaffPaymentDetailScreen(paymentId: paymentId),
          payments: payments, size: const Size(420, 4000));
      expect(find.text(SettlementStrings.heldNotIssuedYet), findsOneWidget);
      expect(find.text(SettlementStrings.settledOutOfRange), findsNothing);
    });

    testWidgets('settled payment without loaded settlements links the list',
        (tester) async {
      final payments = FakePaymentRepository()
        ..queue = [
          paymentFixture(status: 'settled', heldAt: '2026-11-21T15:00:00.000Z')
        ];
      final backoffice = FakePaymentBackofficeRepository()
        ..settlementItems = [
          settlementFixture(paymentId: '018f47a2-8b45-7cc2-9a1e-eeeeeeeeeeee'),
        ];
      await pump(tester, const StaffPaymentDetailScreen(paymentId: paymentId),
          payments: payments,
          backoffice: backoffice,
          size: const Size(420, 4000));
      expect(find.text(SettlementStrings.settledOutOfRange), findsOneWidget);
      expect(find.text(SettlementStrings.viewInSettlements), findsOneWidget);
    });

    testWidgets('staff detail shows settlements and ledger for held payment',
        (tester) async {
      final payments = FakePaymentRepository()
        ..queue = [
          paymentFixture(status: 'held', heldAt: '2026-11-21T15:00:00.000Z')
        ];
      final backoffice = FakePaymentBackofficeRepository()
        ..ledger = balancedLedger()
        ..settlementItems = [
          settlementFixture(),
          settlementFixture(
              id: '018f47a2-8b45-7cc2-9a1e-1234567890a2',
              paymentId: '018f47a2-8b45-7cc2-9a1e-dddddddddddd',
              amount: '15000'),
        ];
      await pump(tester, const StaffPaymentDetailScreen(paymentId: paymentId),
          payments: payments,
          backoffice: backoffice,
          size: const Size(420, 4000));
      expect(find.text(SettlementStrings.paymentSectionTitle), findsOneWidget);
      expect(find.text(SettlementStrings.viewInSettlements), findsOneWidget);
      expect(find.text(r'$90.000'), findsWidgets);
      expect(find.text(r'$15.000'), findsNothing);
      expect(backoffice.settlementCalls, [null]);
      expect(find.text(LedgerStrings.title), findsOneWidget);
      expect(find.text(LedgerStrings.balanced), findsNWidgets(3));
    });

    testWidgets('proof_uploaded detail skips settlements but shows ledger',
        (tester) async {
      final payments = FakePaymentRepository()..queue = [paymentFixture()];
      final backoffice = FakePaymentBackofficeRepository();
      await pump(tester, const StaffPaymentDetailScreen(paymentId: paymentId),
          payments: payments,
          backoffice: backoffice,
          size: const Size(420, 4000));
      expect(find.text(SettlementStrings.paymentSectionTitle), findsNothing);
      expect(backoffice.settlementCalls, isEmpty);
      expect(find.text(LedgerStrings.empty), findsOneWidget);
    });
  });
}

class _NoAuthRepository implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
