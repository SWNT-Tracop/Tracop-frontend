import 'package:flutter_test/flutter_test.dart';
import 'package:tracop_mobile/core/i18n/strings.dart';
import 'package:tracop_mobile/core/result/result.dart';
import 'package:tracop_mobile/features/payments/domain/entities/ledger.dart';
import 'package:tracop_mobile/features/payments/domain/entities/payment.dart';
import 'package:tracop_mobile/features/payments/domain/entities/payments_metrics.dart';
import 'package:tracop_mobile/features/payments/domain/entities/settlement.dart';
import 'package:tracop_mobile/features/payments/domain/review_filters.dart';
import 'package:tracop_mobile/features/payments/domain/settlement_filters.dart';
import 'package:tracop_mobile/features/payments/presentation/payment_error_text.dart';
import 'package:tracop_mobile/features/payments/presentation/screens/payments_dashboard_screen.dart';

import 'support/payment_fixtures.dart';

void main() {
  group('Settlement.fromJson', () {
    test('parses int-string amounts and nullable paid fields', () {
      final issued = Settlement.fromJson(settlementJson());
      expect(issued.amount, 90000);
      expect(issued.status, SettlementStatus.issued);
      expect(issued.beneficiaryKind, BeneficiaryKind.producer);
      expect(issued.paidAt, isNull);
      expect(issued.reference, isNull);
      expect(issued.isPaid, isFalse);

      final paid = Settlement.fromJson(settlementJson(
        status: 'paid',
        beneficiaryKind: 'carrier',
        amount: '9223372036854775807',
        paidAt: '2026-11-22T10:00:00.000Z',
        reference: 'TRX-1',
        version: 2,
      ));
      expect(paid.amount, 9223372036854775807);
      expect(paid.beneficiaryKind, BeneficiaryKind.carrier);
      expect(paid.paidAt, DateTime.utc(2026, 11, 22, 10));
      expect(paid.reference, 'TRX-1');
      expect(paid.version, 2);
    });

    test('rejects decimals and negatives', () {
      for (final json in [
        settlementJson(amount: '90000.5'),
        settlementJson(amount: '-1'),
        settlementJson(amount: '007'),
      ]) {
        expect(() => Settlement.fromJson(json), throwsFormatException);
      }
    });

    test('degrades unknown enums keeping the raw value', () {
      final settlement = Settlement.fromJson(
          settlementJson(status: 'cancelled', beneficiaryKind: 'supplier'));
      expect(settlement.status, SettlementStatus.unknown);
      expect(settlement.statusCode, 'cancelled');
      expect(settlement.beneficiaryKind, BeneficiaryKind.unknown);
      expect(settlement.beneficiaryKindCode, 'supplier');
      expect(settlement.canMarkPaid, isFalse);
      expect(settlement.isPaid, isFalse);
      expect(
          SettlementStrings.kind(settlement.beneficiaryKindCode), 'supplier');
      expect(
          BeneficiaryKind.selectable, isNot(contains(BeneficiaryKind.unknown)));
      expect(Settlement.fromJson(settlementJson()).canMarkPaid, isTrue);
    });
  });

  group('ledger', () {
    test('parses entries and degrades unknown kinds', () {
      final entry = LedgerEntry.fromJson(
          ledgerEntryJson(kind: 'refund', debit: '5000', credit: '0'));
      expect(entry.kind, LedgerKind.refund);
      expect(entry.debit, 5000);
      expect(entry.credit, 0);
      final unknown = LedgerEntry.fromJson(ledgerEntryJson(kind: 'fx_gain'));
      expect(unknown.kind, LedgerKind.unknown);
      expect(unknown.kindCode, 'fx_gain');
      expect(LedgerSummary.fromEntries([unknown]).transactions.single.kindCode,
          'fx_gain');
      expect(LedgerStrings.kind('fx_gain'), 'fx_gain');
      expect(() => LedgerEntry.fromJson(ledgerEntryJson(debit: '1.5')),
          throwsFormatException);
    });

    test('groups by transaction in chronological order and balances', () {
      // Orden del API invertido: la agrupación ordena por fecha.
      final summary =
          LedgerSummary.fromEntries(balancedLedger().reversed.toList());
      expect(
          summary.transactions.map((t) => t.id), [transactionA, transactionB]);
      expect(summary.transactions.first.kind, LedgerKind.paymentVerified);
      expect(summary.transactions.last.entries, hasLength(3));
      expect(summary.transactions.every((t) => t.isBalanced), isTrue);
      expect(summary.totalDebit, 200000);
      expect(summary.totalCredit, 200000);
      expect(summary.isBalanced, isTrue);
      expect(summary.difference, 0);
    });

    test('flags an unbalanced transaction and the total difference', () {
      final entries = [
        ...balancedLedger(),
        LedgerEntry.fromJson(ledgerEntryJson(
            transactionId: '018f47a2-8b45-7cc2-9a1e-1234567890c5',
            kind: 'settlement_paid_producer',
            account: 'payable_producer',
            debit: '90000',
            createdAt: '2026-11-22T15:00:00.000Z')),
      ];
      final summary = LedgerSummary.fromEntries(entries);
      expect(summary.transactions.last.isBalanced, isFalse);
      expect(summary.isBalanced, isFalse);
      expect(summary.difference, 90000);
    });

    test('total can match while a transaction is unbalanced', () {
      final summary = LedgerSummary.fromEntries([
        LedgerEntry.fromJson(ledgerEntryJson(debit: '10')),
        LedgerEntry.fromJson(ledgerEntryJson(
            transactionId: transactionB, kind: 'refund', credit: '10')),
      ]);
      expect(summary.totalDebit, summary.totalCredit);
      expect(summary.isBalanced, isFalse);
    });

    test('empty ledger', () {
      final summary = LedgerSummary.fromEntries(const []);
      expect(summary.isEmpty, isTrue);
      expect(summary.isBalanced, isTrue);
    });
  });

  group('PaymentsMetrics.fromJson', () {
    test('parses amounts and computes oldest age from generatedAt', () {
      final metrics = PaymentsMetrics.fromJson(metricsJson());
      expect(metrics.paidOrdersTotalCop, 1200000);
      expect(metrics.proofsAwaitingReview, 3);
      expect(metrics.openDisputes, 1);
      expect(metrics.settlementsIssued.count, 2);
      expect(metrics.settlementsIssued.amountCop, 250000);
      expect(metrics.settlementsPaid.amountCop, 750000);
      expect(metrics.oldestProofAge, const Duration(days: 2));
      expect(metrics.oldestProofOverdue(24), isTrue);
      expect(metrics.oldestProofOverdue(72), isFalse);
    });

    test('null oldest proof and signed amounts', () {
      final metrics = PaymentsMetrics.fromJson(
          metricsJson(oldestProofUploadedAt: null, paidOrders: '-5'));
      expect(metrics.oldestProofAge, isNull);
      expect(metrics.oldestProofOverdue(24), isFalse);
      expect(metrics.paidOrdersTotalCop, -5);
      expect(() => PaymentsMetrics.fromJson(metricsJson(paidAmount: '1.0')),
          throwsFormatException);
    });
  });

  group('SettlementFilters', () {
    final now = DateTime.utc(2026, 11, 25, 12);
    final items = [
      settlementFixture(issuedAt: '2026-11-24T12:00:00.000Z'),
      settlementFixture(
          id: '018f47a2-8b45-7cc2-9a1e-1234567890a2',
          beneficiaryKind: 'carrier',
          paymentId: '018f47a2-8b45-7cc2-9a1e-aaaaaaaaaaaa',
          orderId: '018f47a2-8b45-7cc2-9a1e-bbbbbbbbbbbb',
          issuedAt: '2026-11-10T12:00:00.000Z'),
      settlementFixture(
          id: '018f47a2-8b45-7cc2-9a1e-1234567890a3',
          issuedAt: '2026-09-01T12:00:00.000Z'),
    ];

    test('kind, period and search', () {
      expect(const SettlementFilters().apply(items, now), hasLength(3));
      expect(
          const SettlementFilters(kind: BeneficiaryKind.carrier)
              .apply(items, now)
              .single
              .beneficiaryKind,
          BeneficiaryKind.carrier);
      expect(
          const SettlementFilters(period: SettlementPeriod.last7Days)
              .apply(items, now),
          hasLength(1));
      expect(
          const SettlementFilters(period: SettlementPeriod.last30Days)
              .apply(items, now),
          hasLength(2));
      expect(const SettlementFilters(query: 'BBBBBBBB').apply(items, now),
          hasLength(1));
      expect(const SettlementFilters(query: 'aaaaaaaa').apply(items, now),
          hasLength(1));
      expect(const SettlementFilters(query: paymentId).apply(items, now),
          hasLength(2));
    });

    test('copyWith clears kind and keeps server order', () {
      const filters = SettlementFilters(kind: BeneficiaryKind.producer);
      expect(filters.isActive, isTrue);
      expect(filters.copyWith(kind: () => null).isActive, isFalse);
      expect(const SettlementFilters().apply(items, now).map((s) => s.id),
          items.map((s) => s.id));
    });

    test('status filter from the route query', () {
      expect(SettlementStatusFilter.fromQuery('pagadas'),
          SettlementStatusFilter.paid);
      expect(SettlementStatusFilter.fromQuery('todas').status, isNull);
      expect(SettlementStatusFilter.fromQuery(null),
          SettlementStatusFilter.issued);
      expect(
          SettlementStatusFilter.fromQuery('x',
              fallback: SettlementStatusFilter.all),
          SettlementStatusFilter.all);
    });
  });

  test('balance bar keeps a visible pending segment', () {
    expect(SettlementBalanceBar.segments(0, 0), (0, 0));
    expect(SettlementBalanceBar.segments(750, 250), (750, 250));
    expect(SettlementBalanceBar.segments(1000000, 1), (
      1000 - SettlementBalanceBar.minSegment,
      SettlementBalanceBar.minSegment
    ));
    expect(SettlementBalanceBar.segments(1, 1000000), (
      SettlementBalanceBar.minSegment,
      1000 - SettlementBalanceBar.minSegment
    ));
    expect(SettlementBalanceBar.segments(0, 5), (0, 1000));
    expect(SettlementBalanceBar.segments(5, 0), (1000, 0));
  });

  test('provider labels for the producer beneficiary', () {
    expect(SettlementStrings.kind('producer'), 'Proveedor');
    expect(LedgerStrings.kind('settlement_paid_producer'),
        'Liquidación al proveedor');
    expect(LedgerStrings.accountName('payable_producer'),
        'Por pagar al proveedor');
  });

  test('review filters from the route query', () {
    expect(ReviewFilters.fromQuery('comprobantes').status,
        PaymentStatus.proofUploaded);
    expect(ReviewFilters.fromQuery('disputas').status, PaymentStatus.disputed);
    expect(ReviewFilters.fromQuery(null).isActive, isFalse);
  });

  test('settlement error texts', () {
    DomainFailure failure(int status, String code) =>
        DomainFailure(statusCode: status, code: code, message: 'x');
    expect(settlementErrorText(failure(409, 'invalid_transition')),
        startsWith('La liquidación ya fue pagada'));
    expect(settlementErrorText(failure(400, 'invalid_reference')),
        'La referencia supera 100 caracteres.');
    expect(settlementErrorText(failure(404, 'not_found')),
        'Liquidación no encontrada.');
    expect(settlementErrorText(failure(404, 'http_error')),
        'Liquidación no encontrada.');
    expect(settlementErrorText(failure(503, 'offline')),
        paymentErrorText(failure(503, 'offline')));
  });
}
