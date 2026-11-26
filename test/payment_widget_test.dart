import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tracop_mobile/core/i18n/strings.dart';
import 'package:tracop_mobile/core/result/result.dart';
import 'package:tracop_mobile/features/auth/domain/entities/user.dart';
import 'package:tracop_mobile/features/auth/domain/repository/auth_repository.dart';
import 'package:tracop_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:tracop_mobile/features/home/presentation/home_screen.dart';
import 'package:tracop_mobile/features/ordering/domain/entities/order.dart';
import 'package:tracop_mobile/features/ordering/presentation/providers/order_provider.dart';
import 'package:tracop_mobile/features/payments/domain/entities/payment.dart';
import 'package:tracop_mobile/shared/widgets/option_selectors.dart';
import 'package:tracop_mobile/features/payments/presentation/providers/payment_backoffice_provider.dart';
import 'package:tracop_mobile/features/payments/presentation/providers/payment_provider.dart';
import 'package:tracop_mobile/features/payments/presentation/screens/buyer_payment_screen.dart';
import 'package:tracop_mobile/features/payments/presentation/screens/payment_review_inbox_screen.dart';
import 'package:tracop_mobile/features/payments/presentation/screens/staff_payment_detail_screen.dart';

import 'support/payment_fixtures.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es_CO'));

  Future<void> pump(WidgetTester tester, Widget child,
      {required FakePaymentRepository repository,
      String role = 'buyer',
      String orderStatus = 'accepted',
      Size size = const Size(420, 1400)}) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authProvider.overrideWith((ref) => AuthNotifier(_NoAuthRepository())),
        paymentRepositoryProvider.overrideWithValue(repository),
        paymentBackofficeRepositoryProvider
            .overrideWithValue(FakePaymentBackofficeRepository()),
        homeUserProvider.overrideWith((ref) async => User(
            id: 'user',
            role: role,
            fullName: 'Prueba',
            phone: '+573000000000',
            status: 'active',
            locale: 'es-CO')),
        orderDetailProvider.overrideWith((ref, id) async =>
            OrderResponse.fromJson(_order(status: orderStatus))),
        myOrdersProvider
            .overrideWith((ref, cursor) async => const OrderPage(items: [])),
      ],
      child: MaterialApp(home: Scaffold(body: child)),
    ));
    await tester.pumpAndSettle();
  }

  group('BuyerPaymentScreen', () {
    testWidgets(
        'without payment shows summary and method selector; '
        'retries reuse the same payment id', (tester) async {
      final repository = FakePaymentRepository();
      await pump(tester, const BuyerPaymentScreen(orderId: orderIdFixture),
          repository: repository);

      expect(find.text(PaymentStrings.orderSummary), findsOneWidget);
      expect(find.text(r'$11.000'), findsOneWidget);
      expect(find.text(PaymentStrings.chooseMethod), findsWidgets);
      expect(find.text(PaymentStrings.uploadProof), findsNothing);

      await tester.tap(find.text('Nequi'));
      await tester.pumpAndSettle();
      final continueButton = find.text(PaymentStrings.continueWith('Nequi'));
      await tester.tap(continueButton);
      await tester.pumpAndSettle();
      expect(find.textContaining('Sin conexión'), findsOneWidget);
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      expect(repository.initiateCalls, hasLength(2));
      expect(repository.initiateCalls.first['id'],
          repository.initiateCalls.last['id']);
      expect(repository.initiateCalls.first['method'], PaymentMethod.nequi);
      expect((repository.initiateCalls.first['id'] as String)[14], '7');
    });

    testWidgets('pending payment shows instructions and proof upload',
        (tester) async {
      final repository = FakePaymentRepository()
        ..forOrder = paymentFixture(status: 'pending', proofUploadedAt: null);
      await pump(tester, const BuyerPaymentScreen(orderId: orderIdFixture),
          repository: repository);

      expect(find.text(PaymentStrings.status('pending')), findsWidgets);
      expect(find.text(PaymentStrings.instructionsTitle), findsOneWidget);
      expect(find.text(PaymentStrings.placeholderWarning), findsOneWidget);
      expect(find.text(PaymentStrings.chooseFromGallery), findsOneWidget);
      expect(find.text(PaymentStrings.openDispute), findsNothing);
      expect(find.text(PaymentStrings.milestonesTitle), findsOneWidget);
    });

    testWidgets('rejected payment shows the reason and allows a new payment',
        (tester) async {
      final repository = FakePaymentRepository()
        ..forOrder = paymentFixture(
            status: 'rejected', rejectionReason: 'El comprobante es ilegible.');
      await pump(tester, const BuyerPaymentScreen(orderId: orderIdFixture),
          repository: repository);

      expect(find.text('El comprobante es ilegible.'), findsOneWidget);
      await tester.ensureVisible(find.text(PaymentStrings.startNewPayment));
      await tester.tap(find.text(PaymentStrings.startNewPayment));
      await tester.pumpAndSettle();
      final selector = find.byType(OptionCircleSelector<PaymentMethod?>);
      expect(selector, findsOneWidget);
      await tester.tap(
          find.descendant(of: selector, matching: find.text('Transferencia')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(PaymentStrings.continueWith('Transferencia')));
      await tester.pumpAndSettle();
      expect(repository.initiateCalls.single['id'], isNot(paymentId));
    });

    testWidgets('verified payment offers a dispute', (tester) async {
      final repository = FakePaymentRepository()
        ..forOrder = paymentFixture(status: 'verified');
      await pump(tester, const BuyerPaymentScreen(orderId: orderIdFixture),
          repository: repository, orderStatus: 'paid');
      expect(find.text(PaymentStrings.chooseFromGallery), findsNothing);

      // Paso 1: motivo obligatorio.
      await tester.ensureVisible(find.text(PaymentStrings.openDispute));
      await tester.tap(find.text(PaymentStrings.openDispute));
      await tester.pumpAndSettle();
      final dialog = find.byType(AlertDialog);
      final next = find.descendant(
          of: dialog, matching: find.text(PaymentStrings.openDispute));
      await tester.tap(next);
      await tester.pumpAndSettle();
      expect(find.text(PaymentStrings.reasonRequired), findsOneWidget);
      expect(find.text(PaymentStrings.disputeWarning), findsOneWidget);

      // Paso 2: confirmación.
      await tester.enterText(
          find.descendant(of: dialog, matching: find.byType(TextField)),
          'Llegó incompleto');
      await tester.tap(next);
      await tester.pumpAndSettle();
      expect(find.text(PaymentStrings.confirmDisputeTitle), findsOneWidget);
      await tester.tap(find.text(PaymentStrings.confirmDispute));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text(PaymentStrings.disputeOpened), findsOneWidget);
    });

    testWidgets('held payment on a closed order offers no dispute',
        (tester) async {
      final repository = FakePaymentRepository()
        ..forOrder =
            paymentFixture(status: 'held', heldAt: '2026-11-25T10:00:00.000Z');
      await pump(tester, const BuyerPaymentScreen(orderId: orderIdFixture),
          repository: repository, orderStatus: 'closed');
      expect(find.text(PaymentStrings.openDispute), findsNothing);
    });

    testWidgets('pending payment on a cancelled order blocks paying',
        (tester) async {
      final repository = FakePaymentRepository()
        ..forOrder = paymentFixture(status: 'pending', proofUploadedAt: null);
      await pump(tester, const BuyerPaymentScreen(orderId: orderIdFixture),
          repository: repository, orderStatus: 'cancelled');
      expect(find.text(PaymentStrings.orderNotPayableTitle), findsOneWidget);
      expect(find.text(PaymentStrings.instructionsTitle), findsNothing);
      expect(find.text(PaymentStrings.chooseFromGallery), findsNothing);
      expect(find.text(PaymentStrings.chooseMethod), findsNothing);
    });

    testWidgets('upload flow: invalid file, preview, busy button, retry',
        (tester) async {
      var picked = XFile.fromData(Uint8List.fromList(utf8.encode('%PDF-1.7')),
          name: 'doc.pdf');
      final completer = Completer<Result<Payment, DomainFailure>>();
      final repository = FakePaymentRepository()
        ..forOrder = paymentFixture(status: 'pending', proofUploadedAt: null)
        ..onUpload = () => completer.future;
      await pump(
          tester,
          BuyerPaymentScreen(
              orderId: orderIdFixture, picker: (_) async => picked),
          repository: repository);

      await tester.ensureVisible(find.text(PaymentStrings.chooseFromGallery));
      await tester.tap(find.text(PaymentStrings.chooseFromGallery));
      await tester.pumpAndSettle();
      expect(find.textContaining('JPEG, PNG o WebP.'), findsOneWidget);
      expect(find.text(PaymentStrings.uploadProof), findsNothing);

      picked = XFile.fromData(_png, name: 'comprobante.png');
      await tester.tap(find.text(PaymentStrings.chooseFromGallery));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel(PaymentStrings.proofImageLabel),
          findsOneWidget);
      await tester.ensureVisible(find.text(PaymentStrings.uploadProof));
      await tester.tap(find.text(PaymentStrings.uploadProof));
      await tester.pump();
      expect(_button(tester, PaymentStrings.uploadingProof).enabled, isFalse);
      await tester.tap(find.text(PaymentStrings.uploadingProof),
          warnIfMissed: false);
      expect(repository.uploadCalls, 1);

      completer.complete(const Err(DomainFailure(
          statusCode: 502, code: 'storage_upload_failed', message: 'x')));
      await tester.pumpAndSettle();
      expect(find.textContaining('No pudimos subir la imagen'), findsOneWidget);

      repository.onUpload = null;
      await tester.ensureVisible(find.text(PaymentStrings.retryUpload));
      await tester.tap(find.text(PaymentStrings.retryUpload));
      await tester.pumpAndSettle();
      expect(repository.uploadCalls, 2);
      expect(find.text(PaymentStrings.proofUploaded), findsOneWidget);
    });
  });

  group('Staff review', () {
    final proof = paymentFixture(
        id: '018f47a2-0000-7000-8000-000000000001',
        proofUploadedAt: '2020-01-01T10:00:00.000Z');
    final nequiProof = paymentFixture(
        id: '018f47a2-0000-7000-8000-000000000002',
        method: 'nequi',
        proofUploadedAt: '2020-01-02T10:00:00.000Z');
    final dispute = paymentFixture(
        id: '018f47a2-0000-7000-8000-000000000003',
        status: 'disputed',
        disputeReason: 'Llegó incompleto',
        updatedAt: '2020-01-03T10:00:00.000Z');

    testWidgets('inbox filters by status, method and search', (tester) async {
      final repository = FakePaymentRepository()
        ..queue = [dispute, nequiProof, proof];
      await pump(tester, const PaymentReviewInboxScreen(),
          repository: repository, role: 'finance');

      expect(find.text(PaymentStrings.resultsCount(3, 3)), findsOneWidget);
      expect(find.textContaining('Más de'), findsNWidgets(3));

      await tester.tap(find.text(PaymentStrings.filterDisputes));
      await tester.pumpAndSettle();
      expect(find.text(PaymentStrings.resultsCount(1, 3)), findsOneWidget);
      expect(find.textContaining('Llegó'), findsNothing,
          reason: 'la bandeja no muestra el detalle de la disputa');

      await tester.tap(find.text(PaymentStrings.filterAll).first);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Nequi'));
      await tester.pumpAndSettle();
      expect(find.text(PaymentStrings.resultsCount(1, 3)), findsOneWidget);

      await tester.tap(find.text(PaymentStrings.filterAll).last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pumpAndSettle();
      expect(find.text(PaymentStrings.reviewNoMatchesTitle), findsOneWidget);
      await tester.tap(find.text(PaymentStrings.clearFilters).last);
      await tester.pumpAndSettle();
      expect(find.text(PaymentStrings.resultsCount(3, 3)), findsOneWidget);
    });

    testWidgets('verify dialog disables the button while the request is busy',
        (tester) async {
      final completer = Completer<Result<Payment, DomainFailure>>();
      final repository = FakePaymentRepository()
        ..queue = [proof]
        ..onVerify = () => completer.future;
      await pump(tester, StaffPaymentDetailScreen(paymentId: proof.id),
          repository: repository, role: 'finance');

      expect(find.text(PaymentStrings.resolve), findsNothing);
      await tester.ensureVisible(find.text(PaymentStrings.verify));
      await tester.tap(find.text(PaymentStrings.verify));
      await tester.pumpAndSettle();
      expect(find.text(PaymentStrings.verifyConsequences), findsOneWidget);

      await tester.tap(find.byKey(const Key('confirm-verify')));
      await tester.pump();
      final button =
          tester.widget<FilledButton>(find.byKey(const Key('confirm-verify')));
      expect(button.onPressed, isNull);
      await tester.tap(find.byKey(const Key('confirm-verify')),
          warnIfMissed: false);
      await tester.pump();
      expect(repository.verifyCalls, 1);

      completer.complete(Ok(paymentFixture(id: proof.id, status: 'verified')));
      await tester.pumpAndSettle();
      expect(find.text(PaymentStrings.verifyConsequences), findsNothing);
      expect(find.text(PaymentStrings.verified), findsOneWidget);
    });

    testWidgets('version conflict asks to load the latest version',
        (tester) async {
      final repository = FakePaymentRepository()
        ..queue = [proof]
        ..onVerify = () async => const Err(DomainFailure(
            statusCode: 409, code: 'version_conflict', message: 'x'));
      await pump(tester, StaffPaymentDetailScreen(paymentId: proof.id),
          repository: repository, role: 'admin');

      await tester.ensureVisible(find.text(PaymentStrings.verify));
      await tester.tap(find.text(PaymentStrings.verify));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-verify')));
      await tester.pumpAndSettle();
      expect(find.text(PaymentStrings.conflictTitle), findsOneWidget);
      await tester.tap(find.text(PaymentStrings.loadLatest));
      await tester.pumpAndSettle();
      expect(find.text(PaymentStrings.conflictTitle), findsNothing);
    });
  });
}

Map<String, dynamic> _order({String status = 'accepted'}) => {
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

ButtonStyleButton _button(WidgetTester tester, String label) =>
    tester.widget<ButtonStyleButton>(find.ancestor(
        of: find.text(label),
        matching: find.byWidgetPredicate((w) => w is ButtonStyleButton)));

class _NoAuthRepository implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
