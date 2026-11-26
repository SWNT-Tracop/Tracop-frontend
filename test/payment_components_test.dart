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
import 'package:tracop_mobile/features/ordering/domain/entities/order.dart';
import 'package:tracop_mobile/features/ordering/presentation/providers/order_provider.dart';
import 'package:tracop_mobile/features/ordering/presentation/screens/order_screens.dart';
import 'package:tracop_mobile/features/payments/presentation/providers/payment_provider.dart';
import 'package:tracop_mobile/features/payments/presentation/screens/payment_review_inbox_screen.dart';
import 'package:tracop_mobile/features/payments/presentation/widgets/payment_dialogs.dart';
import 'package:tracop_mobile/features/payments/presentation/widgets/proof_viewer.dart';

import 'support/payment_fixtures.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

const _failure =
    DomainFailure(statusCode: 503, code: 'network_error', message: 'x');

void main() {
  setUpAll(() => initializeDateFormatting('es_CO'));

  testWidgets('reject dialog requires a reason', (tester) async {
    final reasons = <String>[];
    await tester.pumpWidget(_host(RejectPaymentDialog(onSubmit: (reason) async {
      reasons.add(reason);
      return const Err(_failure);
    })));

    await tester.tap(find.text(PaymentStrings.confirmReject).last);
    await tester.pump();
    expect(find.text(PaymentStrings.reasonRequired), findsOneWidget);
    expect(reasons, isEmpty);

    await tester.tap(find.text(PaymentStrings.rejectReasons.first));
    await tester.pump();
    await tester.tap(find.text(PaymentStrings.confirmReject).last);
    await tester.pumpAndSettle();
    expect(reasons, [PaymentStrings.rejectReasons.first]);
    expect(find.textContaining('Sin conexión'), findsOneWidget);
  });

  testWidgets('release is disabled when the order was never delivered',
      (tester) async {
    var calls = 0;
    await tester.pumpWidget(_host(DisputeResolutionDialog(
      payment: paymentFixture(status: 'disputed', disputeReason: 'Faltó'),
      onSubmit: (_, __) async {
        calls++;
        return const Err(_failure);
      },
    )));

    expect(find.text(PaymentStrings.releaseUnavailable), findsOneWidget);
    await tester.tap(find.text(PaymentStrings.releaseTitle));
    await tester.enterText(find.byType(TextField), 'Se revisó la entrega');
    await tester.tap(find.text(PaymentStrings.resolve).last);
    await tester.pump();
    expect(find.text(PaymentStrings.chooseOutcome), findsOneWidget);
    expect(calls, 0);

    await tester.tap(find.text(PaymentStrings.refundTitle));
    await tester.pump();
    await tester.tap(find.text(PaymentStrings.confirmRefund));
    await tester.pumpAndSettle();
    expect(calls, 1);
  });

  testWidgets('proof image error offers reloading a fresh URL', (tester) async {
    var reloads = 0;
    await tester.pumpWidget(_host(ProofViewer(
      url: 'https://storage.example/proof',
      onReload: () async => reloads++,
    )));
    // El cliente HTTP de pruebas responde 400: la imagen falla.
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pumpAndSettle();
    expect(find.text(PaymentStrings.expiredLinkTitle), findsOneWidget);
    await tester.tap(find.text(PaymentStrings.reload));
    await tester.pumpAndSettle();
    expect(reloads, 1);
  });

  group('order detail payment entry', () {
    Future<void> pumpOrder(WidgetTester tester, String status) async {
      await tester.binding.setSurfaceSize(const Size(420, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => AuthNotifier(_NoAuthRepository())),
          homeUserProvider.overrideWith((ref) async => _user('buyer')),
          homeConnectivityProvider
              .overrideWith((ref) => Stream<bool>.value(true)),
          orderDetailProvider.overrideWith((ref, id) async =>
              OrderResponse.fromJson(_order(status: status))),
        ],
        child: _host(const OrderDetailScreen(orderId: orderIdFixture)),
      ));
      await tester.pumpAndSettle();
    }

    for (final (status, label) in [
      ('accepted', PaymentStrings.pay),
      ('payment_pending', PaymentStrings.pay),
      ('paid', PaymentStrings.viewPayment),
      ('delivered', PaymentStrings.viewPayment),
      ('closed', PaymentStrings.viewPayment),
      ('quoted', null),
      ('cancelled', null),
    ]) {
      testWidgets('$status → ${label ?? 'sin botón'}', (tester) async {
        await pumpOrder(tester, status);
        if (label == null) {
          expect(find.text(PaymentStrings.pay), findsNothing);
          expect(find.text(PaymentStrings.viewPayment), findsNothing);
        } else {
          expect(find.text(label), findsOneWidget);
        }
        // Sin ENABLE_LOCAL_PAYMENT_DEMO el botón de la demo no aparece.
        expect(find.text(LogisticsStrings.recordLocalPayment), findsNothing);
      });
    }
  });

  testWidgets('review inbox refreshes while visible and stops on dispose',
      (tester) async {
    final repository = FakePaymentRepository()..queue = [paymentFixture()];
    await tester.binding.setSurfaceSize(const Size(420, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authProvider.overrideWith((ref) => AuthNotifier(_NoAuthRepository())),
        paymentRepositoryProvider.overrideWithValue(repository),
      ],
      child: _host(const PaymentReviewInboxScreen()),
    ));
    await tester.pumpAndSettle();
    expect(repository.reviewQueueCalls, 1);

    await tester.pump(const Duration(seconds: 61));
    await tester.pumpAndSettle();
    expect(repository.reviewQueueCalls, 2);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 3));
    expect(repository.reviewQueueCalls, 2);
  });
}

User _user(String role) => User(
    id: 'user',
    role: role,
    fullName: 'Prueba',
    phone: '+573000000000',
    status: 'active',
    locale: 'es-CO');

Map<String, dynamic> _order({required String status}) => {
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

class _NoAuthRepository implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
