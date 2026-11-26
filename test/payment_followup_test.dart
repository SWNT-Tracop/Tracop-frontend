import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tracop_mobile/core/i18n/formats.dart';
import 'package:tracop_mobile/core/i18n/strings.dart';
import 'package:tracop_mobile/core/result/result.dart';
import 'package:tracop_mobile/features/auth/domain/entities/user.dart';
import 'package:tracop_mobile/features/auth/domain/repository/auth_repository.dart';
import 'package:tracop_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:tracop_mobile/features/home/presentation/home_screen.dart';
import 'package:tracop_mobile/features/ordering/domain/entities/order.dart';
import 'package:tracop_mobile/features/ordering/presentation/providers/order_provider.dart';
import 'package:tracop_mobile/features/payments/domain/entities/audit_entry.dart';
import 'package:tracop_mobile/features/payments/domain/entities/payment.dart';
import 'package:tracop_mobile/features/payments/domain/entities/payments_metrics.dart';
import 'package:tracop_mobile/features/payments/domain/payment_permissions.dart';
import 'package:tracop_mobile/features/payments/domain/proof_upload_cancellation.dart';
import 'package:tracop_mobile/features/payments/domain/settlement_filters.dart';
import 'package:tracop_mobile/features/payments/presentation/providers/payment_backoffice_provider.dart';
import 'package:tracop_mobile/features/payments/presentation/providers/payment_provider.dart';
import 'package:tracop_mobile/features/payments/presentation/screens/buyer_payment_screen.dart';
import 'package:tracop_mobile/features/payments/presentation/screens/payment_review_inbox_screen.dart';
import 'package:tracop_mobile/features/payments/presentation/screens/payments_dashboard_screen.dart';
import 'package:tracop_mobile/features/payments/presentation/screens/staff_payment_detail_screen.dart';
import 'package:tracop_mobile/features/payments/presentation/widgets/payment_badges.dart';
import 'package:tracop_mobile/features/payments/presentation/widgets/settlement_filters_bar.dart';

import 'support/payment_fixtures.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es_CO'));

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    FakePaymentRepository? payments,
    FakePaymentBackofficeRepository? backoffice,
    String role = 'finance',
    String orderStatus = 'delivered',
    Size size = const Size(420, 2400),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authProvider.overrideWith((ref) => AuthNotifier(_NoAuthRepository())),
        paymentRepositoryProvider
            .overrideWithValue(payments ?? FakePaymentRepository()),
        paymentBackofficeRepositoryProvider
            .overrideWithValue(backoffice ?? FakePaymentBackofficeRepository()),
        homeUserProvider.overrideWith((ref) async => User(
            id: 'user',
            role: role,
            fullName: 'Prueba',
            phone: '+573000000000',
            status: 'active',
            locale: 'es-CO')),
        orderDetailProvider.overrideWith(
            (ref, id) async => OrderResponse.fromJson(_order(orderStatus))),
        myOrdersProvider
            .overrideWith((ref, cursor) async => const OrderPage(items: [])),
      ],
      child: MaterialApp(home: Scaffold(body: child)),
    ));
    await tester.pumpAndSettle();
  }

  group('dispute resolved (released)', () {
    final released = paymentFixture(
        status: 'held',
        heldAt: '2026-11-25T10:00:00.000Z',
        disputeReason: 'Llegó incompleto');

    test('is derived only from held + disputeReason', () {
      expect(released.disputeResolved, isTrue);
      expect(
          paymentFixture(status: 'held', heldAt: '2026-11-25T10:00:00.000Z')
              .disputeResolved,
          isFalse);
      expect(
          paymentFixture(status: 'refunded', disputeReason: 'x')
              .disputeResolved,
          isFalse);
      // Los permisos siguen usando el estado crudo del API.
      expect(PaymentPermissions.actionsFor(released.status, 'buyer'),
          {PaymentAction.openDispute});
      expect(PaymentPermissions.canOpenDispute(released, 'delivered'), isFalse);
    });

    test('closes the dispute in the milestones; refunds do not', () {
      expect(paymentMilestones(released).map((item) => item.kind).toList(), [
        PaymentMilestoneKind.created,
        PaymentMilestoneKind.proofUploaded,
        PaymentMilestoneKind.held,
        PaymentMilestoneKind.disputed,
        PaymentMilestoneKind.disputeResolved,
        PaymentMilestoneKind.current,
      ]);
      final refunded =
          paymentFixture(status: 'refunded', disputeReason: 'Incompleto');
      expect(paymentMilestones(refunded).map((item) => item.kind),
          isNot(contains(PaymentMilestoneKind.disputeResolved)));
    });

    testWidgets('badge shows "Disputa resuelta"; refunded keeps its label',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Column(children: [
          PaymentStatusBadge.of(released),
          PaymentStatusBadge.of(
              paymentFixture(status: 'refunded', disputeReason: 'x')),
        ]),
      ));
      expect(find.text(PaymentStrings.disputeResolvedLabel), findsOneWidget);
      expect(find.text('Pago reembolsado'), findsOneWidget);
    });

    testWidgets('buyer status card and timeline', (tester) async {
      await pump(tester, const BuyerPaymentScreen(orderId: orderIdFixture),
          payments: FakePaymentRepository()..forOrder = released,
          role: 'buyer');
      expect(find.text(PaymentStrings.disputeResolvedLabel), findsWidgets);
      expect(
          find.text(PaymentStrings.statusDisputeResolvedBody), findsOneWidget);
      expect(find.text(PaymentStrings.milestoneDisputeResolved), findsWidgets);
      expect(find.text(PaymentStrings.statusHeldBody), findsNothing);
    });
  });

  group('admin audit', () {
    final verified = paymentFixture(status: 'verified');

    FakePaymentBackofficeRepository backofficeWithAudit() =>
        FakePaymentBackofficeRepository()
          ..auditPages = {
            null: AuditPage(
              items: [AuditEntry.fromJson(auditEntryJson())],
              nextCursor: 'page-2',
            ),
            'page-2': AuditPage(items: [
              AuditEntry.fromJson(auditEntryJson(
                id: '018f47a2-8b45-7cc2-9a1e-1234567890e2',
                actorId: null,
                actorRole: 'system',
                action: 'payment.something_new',
                before: 'no es un objeto',
                after: null,
                at: '2026-11-23T16:00:00.000Z',
              )),
            ]),
          };

    test('parses entries and degrades unknown shapes', () {
      final entry = AuditEntry.fromJson({
        ...auditEntryJson(before: 'x', after: {'status': 7}),
        'extra': true,
      });
      expect(entry.beforeStatus, isNull);
      expect(entry.afterStatus, isNull);
      final page = AuditPage.fromJson({'items': [], 'nextCursor': ''});
      expect(page.nextCursor, isNull);
    });

    testWidgets('admin sees entries and loads more with the cursor',
        (tester) async {
      final backoffice = backofficeWithAudit();
      await pump(tester, const StaffPaymentDetailScreen(paymentId: paymentId),
          payments: FakePaymentRepository()..queue = [verified],
          backoffice: backoffice,
          role: 'admin');

      expect(find.text(PaymentStrings.auditTitle), findsOneWidget);
      expect(find.text('Pago verificado'), findsWidgets);
      expect(find.text('Por Finanzas TRACOP · 9A1E47A2'), findsOneWidget);
      expect(find.text('Comprobante pendiente de revisión → Pago verificado'),
          findsOneWidget);
      expect(
          find.text(AppFormats.bogotaDateTime(
              DateTime.parse('2026-11-24T16:00:00.000Z'))),
          findsWidgets);
      expect(backoffice.auditCalls.single, containsPair('entityId', paymentId));
      expect(backoffice.auditCalls.single, containsPair('entity', 'payment'));

      await tester.ensureVisible(find.byKey(const Key('audit-load-more')));
      await tester.tap(find.byKey(const Key('audit-load-more')));
      await tester.pumpAndSettle();
      expect(backoffice.auditCalls.last, containsPair('cursor', 'page-2'));
      expect(find.text('payment.something_new'), findsOneWidget,
          reason: 'acción desconocida: se muestra el código');
      expect(find.text('Por Sistema'), findsOneWidget);
      expect(find.byKey(const Key('audit-load-more')), findsNothing);
    });

    for (final role in ['finance', 'operator']) {
      testWidgets('$role does not see the audit section', (tester) async {
        final backoffice = backofficeWithAudit();
        await pump(tester, const StaffPaymentDetailScreen(paymentId: paymentId),
            payments: FakePaymentRepository()..queue = [verified],
            backoffice: backoffice,
            role: role);
        expect(find.byKey(const Key('payment-audit-section')), findsNothing);
        expect(find.text(PaymentStrings.auditTitle), findsNothing);
        expect(backoffice.auditCalls, isEmpty);
      });
    }
  });

  group('who marked the settlement as paid', () {
    final settled = paymentFixture(status: 'settled');
    final paid = settlementFixture(
        status: 'paid',
        paidAt: '2026-11-25T10:00:00.000Z',
        reference: 'TRX-1',
        version: 2);

    testWidgets('admin loads it lazily from the audit', (tester) async {
      final backoffice = FakePaymentBackofficeRepository()
        ..settlementItems = [paid]
        ..auditPages = {
          null: AuditPage(items: [
            AuditEntry.fromJson(auditEntryJson(
                action: 'settlement.mark_paid',
                entity: 'settlement',
                entityId: settlementId,
                before: {'status': 'issued'},
                after: {'status': 'paid', 'reference': 'TRX-1'},
                at: '2026-11-25T10:00:00.000Z')),
          ]),
        };
      await pump(tester, const StaffPaymentDetailScreen(paymentId: paymentId),
          payments: FakePaymentRepository()..queue = [settled],
          backoffice: backoffice,
          role: 'admin');

      bool settlementQuery(Map<String, Object?> call) =>
          call['entity'] == 'settlement';
      expect(backoffice.auditCalls.where(settlementQuery), isEmpty,
          reason: 'no se consulta hasta que el admin lo pide');

      final button = find.byKey(const Key('paid-by-$settlementId'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(backoffice.auditCalls.where(settlementQuery).single, {
        'entity': 'settlement',
        'entityId': settlementId,
        'action': 'settlement.mark_paid',
        'cursor': null,
        'limit': 1,
      });
      expect(
          find.text(SettlementStrings.paidBy(
              'Finanzas TRACOP',
              '9A1E47A2',
              AppFormats.bogotaDateTime(
                  DateTime.parse('2026-11-25T10:00:00.000Z')))),
          findsOneWidget);
    });

    testWidgets('finance sees the "no disponible" note', (tester) async {
      final backoffice = FakePaymentBackofficeRepository()
        ..settlementItems = [paid];
      await pump(tester, const StaffPaymentDetailScreen(paymentId: paymentId),
          payments: FakePaymentRepository()..queue = [settled],
          backoffice: backoffice);
      expect(find.text(SettlementStrings.paidByUnavailable), findsOneWidget);
      expect(find.byKey(const Key('paid-by-$settlementId')), findsNothing);
      expect(backoffice.auditCalls, isEmpty);
    });
  });

  group('review inbox', () {
    Payment proofAt(int i) => paymentFixture(
        id: '018f47a2-0000-7000-8000-${i.toString().padLeft(12, '0')}',
        proofUploadedAt: '2026-11-24T15:00:00.000Z');

    testWidgets('shows the absolute Bogota time of the waiting mark',
        (tester) async {
      final proof = proofAt(1);
      final dispute = paymentFixture(
          id: '018f47a2-0000-7000-8000-000000000099',
          status: 'disputed',
          disputeReason: 'x',
          updatedAt: '2026-11-24T20:30:00.000Z');
      for (final size in [const Size(420, 1600), const Size(1800, 1200)]) {
        await pump(tester, const PaymentReviewInboxScreen(),
            payments: FakePaymentRepository()..queue = [proof, dispute],
            backoffice: FakePaymentBackofficeRepository()
              ..metricsValue = PaymentsMetrics.fromJson(metricsJson(proofs: 1)),
            size: size);
        expect(
            find.text(PaymentStrings.waitingSinceAt(
                AppFormats.bogotaDateTime(proof.proofUploadedAt!))),
            findsOneWidget);
        expect(
            find.text(PaymentStrings.waitingSinceAt(
                AppFormats.bogotaDateTime(dispute.updatedAt))),
            findsOneWidget);
        expect(find.byKey(const Key('review-hidden-alert')), findsNothing);
      }
    });

    testWidgets('does not warn below the server limit even if metrics differ',
        (tester) async {
      await pump(tester, const PaymentReviewInboxScreen(),
          payments: FakePaymentRepository()..queue = [proofAt(1), proofAt(2)],
          backoffice: FakePaymentBackofficeRepository()
            ..metricsValue =
                PaymentsMetrics.fromJson(metricsJson(proofs: 5, disputes: 2)));
      expect(find.byKey(const Key('review-hidden-alert')), findsNothing);
    });

    testWidgets('warns with the exact count when the limit cuts the queue',
        (tester) async {
      await pump(tester, const PaymentReviewInboxScreen(),
          payments: FakePaymentRepository()
            ..queue = [for (var i = 0; i < 100; i++) proofAt(i)],
          backoffice: FakePaymentBackofficeRepository()
            ..metricsValue = PaymentsMetrics.fromJson(
                metricsJson(proofs: 120, disputes: 10)));
      expect(find.byKey(const Key('review-hidden-alert')), findsOneWidget);
      expect(find.text(PaymentStrings.reviewHidden(30)), findsOneWidget);
      expect(find.text(PaymentStrings.reviewHiddenHelp), findsOneWidget);
    });

    testWidgets('warns when the server limit is reached', (tester) async {
      await pump(tester, const PaymentReviewInboxScreen(),
          payments: FakePaymentRepository()
            ..queue = [for (var i = 0; i < 100; i++) proofAt(i)],
          backoffice: FakePaymentBackofficeRepository()
            ..metricsValue = PaymentsMetrics.fromJson(
                metricsJson(proofs: 100, disputes: 0)));
      expect(find.text(PaymentStrings.reviewHiddenUnknown), findsOneWidget);
    });
  });

  group('paid orders count', () {
    test('counts the same statuses as paidOrdersTotalCop', () {
      final json = metricsJson()
        ..['ordersByStatus'] = {
          'paid': 2,
          'pickup_scheduled': 1,
          'in_transit': 1,
          'delivered': 1,
          'closed': 3,
          'quoted': 5,
          'new_state': 4,
          'broken': 'x',
        };
      final metrics = PaymentsMetrics.fromJson(json);
      expect(metrics.paidOrdersCount, 8);
      expect(metrics.ordersByStatus.containsKey('broken'), isFalse);
      final missing = metricsJson()..remove('ordersByStatus');
      expect(PaymentsMetrics.fromJson(missing).paidOrdersCount, 0);
    });

    testWidgets('dashboard card shows the count next to the amount',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PaymentsDashboard(
                metrics: PaymentsMetrics.fromJson(metricsJson())),
          ),
        ),
      ));
      final card = find.byKey(const Key('metric-paid-orders'));
      expect(
          find.descendant(
              of: card,
              matching:
                  find.text('${PaymentsDashboardStrings.paidOrdersCount(4)} · '
                      '${PaymentsDashboardStrings.paidOrdersHint}')),
          findsOneWidget);
      expect(find.descendant(of: card, matching: find.text(r'$1.200.000')),
          findsOneWidget);
    });
  });

  group('cancel proof upload', () {
    testWidgets('cancel is not an error and a later retry works',
        (tester) async {
      final completer = Completer<Result<Payment, DomainFailure>>();
      final repository = FakePaymentRepository()
        ..forOrder = paymentFixture(status: 'pending', proofUploadedAt: null)
        ..onUpload = () => completer.future;
      await pump(
          tester,
          BuyerPaymentScreen(
              orderId: orderIdFixture,
              picker: (_) async => XFile.fromData(_png, name: 'c.png')),
          payments: repository,
          role: 'buyer',
          orderStatus: 'accepted');

      await tester.ensureVisible(find.text(PaymentStrings.chooseFromGallery));
      await tester.tap(find.text(PaymentStrings.chooseFromGallery));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('cancel-proof-upload')), findsNothing);
      await tester.ensureVisible(find.text(PaymentStrings.uploadProof));
      await tester.tap(find.text(PaymentStrings.uploadProof));
      await tester.pump();

      final cancel = find.byKey(const Key('cancel-proof-upload'));
      expect(cancel, findsOneWidget);
      await tester.tap(cancel);
      await tester.pump();
      expect(repository.lastCancellation?.isCancelled, isTrue);

      completer.complete(const Err(DomainFailure(
          statusCode: 499, code: proofUploadCancelledCode, message: 'x')));
      await tester.pumpAndSettle();
      expect(find.text(PaymentStrings.uploadCancelled), findsOneWidget);
      expect(find.text(PaymentStrings.retryUpload), findsNothing,
          reason: 'cancelar no se muestra como error');
      expect(find.byKey(const Key('cancel-proof-upload')), findsNothing);

      repository.onUpload = null;
      await tester.ensureVisible(find.text(PaymentStrings.uploadProof));
      await tester.tap(find.text(PaymentStrings.uploadProof));
      await tester.pumpAndSettle();
      expect(repository.uploadCalls, 2);
      expect(find.text(PaymentStrings.proofUploaded), findsOneWidget);
    });
  });

  group('settlement date range', () {
    final now = DateTime.utc(2026, 11, 25, 15);
    final range = SettlementDateRange(
        start: DateTime(2026, 11, 20), end: DateTime(2026, 11, 20));

    test('uses Bogota calendar days, both ends inclusive', () {
      final filters = const SettlementFilters().withRange(range);
      bool shows(String issuedAt) =>
          filters.matches(settlementFixture(issuedAt: issuedAt), now);
      expect(shows('2026-11-20T05:00:00.000Z'), isTrue); // 20 nov 00:00
      expect(shows('2026-11-21T04:59:00.000Z'), isTrue); // 20 nov 23:59
      expect(shows('2026-11-21T05:00:00.000Z'), isFalse); // 21 nov 00:00
      expect(shows('2026-11-20T04:59:00.000Z'), isFalse); // 19 nov 23:59
      expect(filters.isActive, isTrue);
    });

    test('presets and the range replace each other', () {
      final withPreset = const SettlementFilters()
          .withPeriod(SettlementPeriod.last7Days)
          .withRange(range);
      expect(withPreset.period, SettlementPeriod.all);
      expect(withPreset.range, range);
      final back = withPreset.withPeriod(SettlementPeriod.last30Days);
      expect(back.range, isNull);
      expect(back.period, SettlementPeriod.last30Days);
      final cleared = withPreset.withRange(null);
      expect(cleared.range, isNull);
      expect(cleared.isActive, isFalse);
    });

    testWidgets('bar opens the picker and clears the range', (tester) async {
      SettlementFilters? changed;
      Future<void> bar(SettlementFilters filters) =>
          tester.pumpWidget(MaterialApp(
            home: Scaffold(
              body: SettlementFiltersBar(
                status: SettlementStatusFilter.all,
                filters: filters,
                onStatusChanged: (_) {},
                onChanged: (value) => changed = value,
              ),
            ),
          ));

      await bar(const SettlementFilters());
      await tester.tap(find.byKey(const Key('settlement-range-pick')));
      await tester.pumpAndSettle();
      expect(find.byType(DateRangePickerDialog), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      await bar(const SettlementFilters().withRange(range));
      expect(find.text('20 nov 2026'), findsOneWidget);
      await tester.tap(find.byTooltip(SettlementStrings.clearRange));
      await tester.pump();
      expect(changed?.range, isNull);
    });
  });
}

Map<String, dynamic> _order(String status) => {
      'id': orderIdFixture,
      'status': status,
      'version': 2,
      'createdAt': '2026-11-20T12:00:00.000Z',
      'lines': [
        {
          'lotId': '018f47a2-8b45-7cc2-9a1e-123456789abe',
          'quantityMilli': '2000',
          'unit': 'kg',
          'unitPrice': '5000',
        },
      ],
      'subtotal': '10000',
      'freight': '1000',
      'commission': '200',
      'total': '11000',
      'providerNet': '9800',
      'acceptedAt': '2026-11-20T11:00:00.000Z',
      'cancelReason': null,
      'quoteValidUntil': '2026-11-21T12:00:00.000Z',
    };

final _png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==');

class _NoAuthRepository implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
