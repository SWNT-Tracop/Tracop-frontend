import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tracop_mobile/core/i18n/formats.dart';
import 'package:tracop_mobile/core/i18n/strings.dart';
import 'package:tracop_mobile/features/payments/domain/entities/payment.dart';
import 'package:tracop_mobile/features/payments/domain/payment_attempt_ids.dart';
import 'package:tracop_mobile/features/payments/domain/payment_permissions.dart';
import 'package:tracop_mobile/features/payments/domain/proof_file_rules.dart';
import 'package:tracop_mobile/features/payments/domain/review_filters.dart';

import 'support/payment_fixtures.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es_CO'));

  group('Payment.fromJson', () {
    test('parses integer money strings without doubles and keeps nulls', () {
      final payment = Payment.fromJson(paymentJson(
        status: 'pending',
        proofUploadedAt: null,
        total: '9223372036854775807',
      ));
      expect(payment.status, PaymentStatus.pending);
      expect(payment.method, PaymentMethod.transfer);
      expect(payment.subtotal, 95000);
      expect(payment.freight, 5000);
      expect(payment.commission, 4750);
      expect(payment.providerNet, 90250);
      expect(payment.total, 9223372036854775807);
      expect(payment.proofUploadedAt, isNull);
      expect(payment.proofUrl, isNull);
      expect(payment.reviewedAt, isNull);
      expect(payment.rejectionReason, isNull);
      expect(payment.heldAt, isNull);
      expect(payment.disputeReason, isNull);
      expect(payment.createdAt, DateTime.utc(2026, 11, 24, 14));
      expect(payment.version, 3);
    });

    test('rejects malformed money', () {
      expect(() => parseMoney('12.5'), throwsFormatException);
      expect(() => parseMoney('-1'), throwsFormatException);
      expect(() => parseMoney('007'), throwsFormatException);
      expect(() => parseMoney(null), throwsFormatException);
      expect(parseMoney('0'), 0);
    });

    test('degrades unknown status and method without actions', () {
      final payment =
          Payment.fromJson(paymentJson(status: 'lost', method: 'pse'));
      expect(payment.status, PaymentStatus.unknown);
      expect(payment.statusCode, 'lost');
      expect(payment.method, PaymentMethod.unknown);
      expect(payment.methodCode, 'pse');
      expect(PaymentStrings.status(payment.statusCode),
          'Estado desconocido (lost)');
      for (final role in ['buyer', 'finance', 'operator', 'admin']) {
        expect(PaymentPermissions.actionsFor(payment.status, role), isEmpty);
      }
      expect(PaymentMethod.selectable, isNot(contains(PaymentMethod.unknown)));
      // Un valor conocido no se confunde con el desconocido.
      expect(PaymentStatus.fromWire(''), PaymentStatus.unknown);
      expect(PaymentStatus.fromWire('held'), PaymentStatus.held);
    });

    test('never exposes the signed proof URL in toString', () {
      final payment = Payment.fromJson(
          paymentJson(proofUrl: 'https://storage.example/proof?sig=secret'));
      expect(payment.proofUrl, isNotNull);
      expect(payment.toString(), isNot(contains('secret')));
    });

    test('parses the presigned upload policy', () {
      final policy = ProofUploadPolicy.fromJson({
        'uploadPolicy': {
          'url': 'https://storage.example/bucket',
          'fields': {'key': 'payment-incoming/x', 'Policy': 'abc'},
          'expiresAt': '2026-11-24T15:15:00.000Z',
        }
      });
      expect(policy.fields['key'], 'payment-incoming/x');
      expect(policy.expiresAt, DateTime.utc(2026, 11, 24, 15, 15));
      expect(policy.toString(), isNot(contains('storage.example')));
    });
  });

  test('every status has the Spanish label from the payments document', () {
    expect(
      {
        // `unknown` se cubre en 'degrades unknown status and method'.
        for (final status in PaymentStatus.values)
          if (status != PaymentStatus.unknown)
            status.wire: PaymentStrings.status(status.wire)
      },
      {
        'pending': 'Pendiente de pago',
        'proof_uploaded': 'Comprobante pendiente de revisión',
        'verified': 'Pago verificado',
        'held': 'Pago retenido hasta la entrega',
        'settled': 'Pago liquidado',
        'rejected': 'Pago rechazado',
        'disputed': 'Pago en disputa',
        'refunded': 'Pago reembolsado',
      },
    );
  });

  test('allowed actions follow backend transitions per role', () {
    Map<String, Set<PaymentAction>> matrix(String? role) => {
          for (final status in PaymentStatus.values)
            if (status != PaymentStatus.unknown)
              status.wire: PaymentPermissions.actionsFor(status, role)
        };

    expect(matrix('buyer'), {
      'pending': {PaymentAction.uploadProof},
      'proof_uploaded': <PaymentAction>{},
      'verified': {PaymentAction.openDispute},
      'held': {PaymentAction.openDispute},
      'settled': <PaymentAction>{},
      'rejected': {PaymentAction.startNewPayment},
      'disputed': <PaymentAction>{},
      'refunded': <PaymentAction>{},
    });
    for (final role in ['finance', 'operator', 'admin']) {
      expect(matrix(role), {
        'pending': <PaymentAction>{},
        'proof_uploaded': {PaymentAction.verify, PaymentAction.reject},
        'verified': <PaymentAction>{},
        'held': <PaymentAction>{},
        'settled': <PaymentAction>{},
        'rejected': <PaymentAction>{},
        'disputed': {PaymentAction.resolveDispute},
        'refunded': <PaymentAction>{},
      });
    }
    for (final role in ['producer', 'supplier', 'carrier', null]) {
      expect(matrix(role).values.every((actions) => actions.isEmpty), isTrue);
    }
    expect(PaymentPermissions.canRelease(paymentFixture(status: 'disputed')),
        isFalse);
    expect(
        PaymentPermissions.canRelease(paymentFixture(
            status: 'disputed', heldAt: '2026-11-25T10:00:00.000Z')),
        isTrue);
  });

  test('COP amounts use the \$90.000 format in payments', () {
    expect(AppFormats.cop(90000), '\$90.000');
    expect(AppFormats.cop(0), '\$0');
    expect(AppFormats.cop(1234567), '\$1.234.567');
    expect(AppFormats.copText('90000'), '\$90.000');
  });

  test('dispute, availability and demo rules', () {
    final verified = paymentFixture(status: 'verified');
    expect(PaymentPermissions.canOpenDispute(verified, 'paid'), isTrue);
    for (final status in ['pickup_scheduled', 'in_transit', 'delivered']) {
      expect(PaymentPermissions.canOpenDispute(verified, status), isTrue);
    }
    final held =
        paymentFixture(status: 'held', heldAt: '2026-11-25T10:00:00.000Z');
    expect(PaymentPermissions.canOpenDispute(held, 'closed'), isFalse);
    expect(PaymentPermissions.canOpenDispute(held, 'disputed'), isFalse);
    expect(
        PaymentPermissions.canOpenDispute(
            paymentFixture(status: 'verified', disputeReason: 'Ya abierta'),
            'paid'),
        isFalse);
    expect(
        PaymentPermissions.canOpenDispute(
            paymentFixture(status: 'pending'), 'paid'),
        isFalse);

    expect(
        PaymentPermissions.paymentsAvailable(
            releaseMode: true, hasPlaceholderData: true),
        isFalse);
    expect(
        PaymentPermissions.paymentsAvailable(
            releaseMode: true, hasPlaceholderData: false),
        isTrue);
    expect(
        PaymentPermissions.paymentsAvailable(
            releaseMode: false, hasPlaceholderData: true),
        isTrue);

    bool demo(
            {bool enabled = true,
            bool isBuyer = true,
            String status = 'accepted',
            bool isLocallyPaid = false}) =>
        PaymentPermissions.showLocalPaymentDemo(
            enabled: enabled,
            isBuyer: isBuyer,
            orderStatus: status,
            isLocallyPaid: isLocallyPaid);
    expect(demo(), isTrue);
    expect(demo(status: 'payment_pending'), isTrue);
    expect(demo(enabled: false), isFalse);
    expect(demo(isBuyer: false), isFalse);
    expect(demo(status: 'paid'), isFalse);
    expect(demo(isLocallyPaid: true), isFalse);
  });

  group('Bogotá formatting', () {
    test('is UTC-5 regardless of the device timezone', () {
      final instant = DateTime.utc(2026, 11, 25, 3, 30);
      expect(AppFormats.toBogota(instant), DateTime.utc(2026, 11, 24, 22, 30));
      expect(AppFormats.bogotaTime(instant), '22:30');
      final text = AppFormats.bogotaDateTime(instant);
      expect(text, startsWith('24 '));
      expect(text, endsWith('2026, 22:30'));
      // Un DateTime local del mismo instante da el mismo resultado.
      expect(AppFormats.bogotaDateTime(instant.toLocal()), text);
    });
  });

  test('payment attempt ids are reused per order attempt', () {
    var counter = 0;
    final ids = PaymentAttemptIds(generator: () => 'id-${++counter}');
    final first = ids.idFor('order-1');
    expect(ids.idFor('order-1'), first, reason: 'double tap / retry');
    expect(ids.idFor('order-2'), isNot(first));
    final afterRejection =
        ids.idFor('order-1', afterRejectedPaymentId: 'rejected-1');
    expect(afterRejection, isNot(first));
    expect(ids.idFor('order-1', afterRejectedPaymentId: 'rejected-1'),
        afterRejection);
    ids.reset('order-1');
    expect(ids.idFor('order-1'), isNot(first));
  });

  test('uuid v7 is the default generator', () {
    final id = PaymentAttemptIds().idFor('order');
    expect(id[14], '7');
  });

  group('proof file rules', () {
    const jpeg = [0xFF, 0xD8, 0xFF, 0xE0, 0, 0];
    const png = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0];
    const webp = [
      0x52, 0x49, 0x46, 0x46, 0, 0, 0, 0, //
      0x57, 0x45, 0x42, 0x50, 0,
    ];

    test('accepts JPEG, PNG and WebP by signature', () {
      expect(detectProofFormat(jpeg), ProofImageFormat.jpeg);
      expect(detectProofFormat(png), ProofImageFormat.png);
      expect(detectProofFormat(webp), ProofImageFormat.webp);
      expect(checkProofBytes(png, maxBytes: 100), isA<ProofAccepted>());
    });

    test('rejects empty, too large and other formats', () {
      expect((checkProofBytes(const [], maxBytes: 10) as ProofRejected).code,
          'proof_empty');
      expect((checkProofBytes(jpeg, maxBytes: 3) as ProofRejected).code,
          'proof_too_large');
      expect(
          (checkProofBytes('%PDF-1.7'.codeUnits, maxBytes: 100)
                  as ProofRejected)
              .code,
          'proof_format_invalid');
    });
  });

  group('review filters', () {
    final now = DateTime.utc(2026, 11, 25, 16);
    final oldProof = paymentFixture(
        id: '018f47a2-0000-7000-8000-000000000001',
        proofUploadedAt: '2026-11-24T10:00:00.000Z');
    final newProof = paymentFixture(
        id: '018f47a2-0000-7000-8000-000000000002',
        method: 'nequi',
        proofUploadedAt: '2026-11-25T15:00:00.000Z');
    final dispute = paymentFixture(
        id: '018f47a2-0000-7000-8000-000000000003',
        status: 'disputed',
        orderId: '018f47a2-ffff-7000-8000-00000000abcd',
        updatedAt: '2026-11-25T12:00:00.000Z');

    test('sorts oldest first and filters by status, method and id', () {
      final all = [newProof, dispute, oldProof];
      expect(const ReviewFilters().apply(all), [oldProof, dispute, newProof]);
      expect(const ReviewFilters(status: PaymentStatus.disputed).apply(all),
          [dispute]);
      expect(const ReviewFilters(method: PaymentMethod.nequi).apply(all),
          [newProof]);
      expect(const ReviewFilters(query: 'ABCD').apply(all), [dispute]);
      expect(const ReviewFilters(query: '0002').apply(all), [newProof]);
    });

    test('marks reviews older than the threshold as overdue', () {
      expect(isReviewOverdue(oldProof, now, hours: 24), isTrue);
      expect(isReviewOverdue(newProof, now, hours: 24), isFalse);
    });
  });

  test('milestones only use timestamps present in the payment', () {
    final pending = paymentFixture(status: 'pending', proofUploadedAt: null);
    expect(paymentMilestones(pending).map((item) => item.kind), [
      PaymentMilestoneKind.created,
      PaymentMilestoneKind.current,
    ]);
    final rejected = Payment.fromJson(paymentJson(
        status: 'rejected',
        reviewedAt: '2026-11-24T16:00:00.000Z',
        rejectionReason: 'Ilegible'));
    expect(paymentMilestones(rejected).map((item) => item.kind), [
      PaymentMilestoneKind.created,
      PaymentMilestoneKind.proofUploaded,
      PaymentMilestoneKind.rejected,
      PaymentMilestoneKind.current,
    ]);
    final disputed = Payment.fromJson(paymentJson(
        status: 'disputed',
        reviewedAt: '2026-11-24T16:00:00.000Z',
        heldAt: '2026-11-25T16:00:00.000Z',
        disputeReason: 'Incompleto'));
    final milestones = paymentMilestones(disputed);
    expect(milestones.map((item) => item.kind), [
      PaymentMilestoneKind.created,
      PaymentMilestoneKind.proofUploaded,
      PaymentMilestoneKind.verified,
      PaymentMilestoneKind.held,
      PaymentMilestoneKind.disputed,
      PaymentMilestoneKind.current,
    ]);
    expect(
        milestones
            .firstWhere((item) => item.kind == PaymentMilestoneKind.disputed)
            .at,
        isNull,
        reason: 'el API no registra la fecha de la disputa');
  });
}
