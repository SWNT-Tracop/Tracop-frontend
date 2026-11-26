import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracop_mobile/core/result/result.dart';
import 'package:tracop_mobile/features/payments/data/remote/payment_backoffice_remote.dart';
import 'package:tracop_mobile/features/payments/data/repository/payment_backoffice_repository_impl.dart';
import 'package:tracop_mobile/features/payments/domain/entities/audit_entry.dart';
import 'package:tracop_mobile/features/payments/domain/entities/settlement.dart';

import 'support/payment_fixtures.dart';

class _FakeRemote implements PaymentBackofficeRemoteDataSource {
  final queries = <Map<String, dynamic>>[];
  final markPaidCalls = <(String, Map<String, dynamic>)>[];
  Object? error;
  Map<String, dynamic> settlementResponse = settlementJson(
      status: 'paid',
      paidAt: '2026-11-25T10:00:00.000Z',
      reference: 'TRX-9',
      version: 2);

  @override
  Future<Map<String, dynamic>> listSettlements(
      Map<String, dynamic> query) async {
    queries.add(query);
    if (error != null) throw error!;
    return {
      'items': [settlementJson()]
    };
  }

  @override
  Future<Map<String, dynamic>> markSettlementPaid(
      String settlementId, Map<String, dynamic> body) async {
    markPaidCalls.add((settlementId, body));
    if (error != null) throw error!;
    return settlementResponse;
  }

  @override
  Future<Map<String, dynamic>> ledgerForOrder(String orderId) async => {
        'items': [
          ledgerEntryJson(debit: '100000'),
          ledgerEntryJson(account: 'payable_buyer_funds', credit: '100000'),
        ]
      };

  @override
  Future<Map<String, dynamic>> metrics() async => metricsJson();

  final auditQueries = <Map<String, dynamic>>[];

  @override
  Future<Map<String, dynamic>> audit(Map<String, dynamic> query) async {
    auditQueries.add(query);
    if (error != null) throw error!;
    return {
      'items': [auditEntryJson()],
      'nextCursor': 'abc',
    };
  }
}

DioException _apiError(int status, String code) => DioException(
      requestOptions: RequestOptions(path: '/settlements'),
      response: Response(
        requestOptions: RequestOptions(path: '/settlements'),
        statusCode: status,
        data: {'statusCode': status, 'code': code, 'message': 'x'},
      ),
      error: DomainFailure(statusCode: status, code: code, message: 'x'),
    );

void main() {
  group('audit', () {
    test('sends only keys accepted by the strict schema', () async {
      final remote = _FakeRemote();
      final repository = PaymentBackofficeRepositoryImpl(remote: remote);
      final result =
          await repository.audit(entity: 'payment', entityId: paymentId);
      expect(remote.auditQueries.single,
          {'entity': 'payment', 'entityId': paymentId, 'limit': 50});
      final page = (result as Ok<AuditPage, DomainFailure>).value;
      expect(page.items.single.action, 'payment.verify');
      expect(page.nextCursor, 'abc');

      await repository.audit(
          entity: 'settlement',
          entityId: settlementId,
          action: 'settlement.mark_paid',
          cursor: 'abc',
          limit: 500);
      expect(remote.auditQueries.last, {
        'entity': 'settlement',
        'entityId': settlementId,
        'action': 'settlement.mark_paid',
        'cursor': 'abc',
        'limit': 100,
      });
    });

    test('maps a 403 to a DomainFailure', () async {
      final remote = _FakeRemote()..error = _apiError(403, 'forbidden');
      final result = await PaymentBackofficeRepositoryImpl(remote: remote)
          .audit(entity: 'payment', entityId: paymentId);
      expect((result as Err<AuditPage, DomainFailure>).error.code, 'forbidden');
    });
  });

  late _FakeRemote remote;
  late PaymentBackofficeRepositoryImpl repository;

  setUp(() {
    remote = _FakeRemote();
    repository = PaymentBackofficeRepositoryImpl(remote: remote);
  });

  test('mark paid sends exactly expectedVersion and trimmed reference',
      () async {
    final result =
        await repository.markSettlementPaid(settlementId, 3, '  TRX-9  ');
    expect(remote.markPaidCalls.single.$1, settlementId);
    expect(remote.markPaidCalls.single.$2,
        {'expectedVersion': 3, 'reference': 'TRX-9'});
    final settlement = (result as Ok<Settlement, DomainFailure>).value;
    expect(settlement.isPaid, isTrue);
    expect(settlement.reference, 'TRX-9');
  });

  test('empty or blank reference is sent as null', () async {
    await repository.markSettlementPaid(settlementId, 1, '   ');
    await repository.markSettlementPaid(settlementId, 1, null);
    for (final call in remote.markPaidCalls) {
      expect(call.$2, {'expectedVersion': 1, 'reference': null});
      expect(call.$2.containsKey('reference'), isTrue);
    }
  });

  test('version conflict surfaces as a domain failure', () async {
    remote.error = _apiError(409, 'version_conflict');
    final result = await repository.markSettlementPaid(settlementId, 1, 'x');
    expect((result as Err).error.code, 'version_conflict');
  });

  test('list sends status only when filtered and clamps the limit', () async {
    await repository.settlements();
    await repository.settlements(status: SettlementStatus.paid, limit: 500);
    expect(remote.queries, [
      {'limit': 100},
      {'status': 'paid', 'limit': 100},
    ]);
  });

  test('malformed payload maps to invalid_response', () async {
    remote.settlementResponse = settlementJson(amount: '1.5');
    final result = await repository.markSettlementPaid(settlementId, 1, 'x');
    expect((result as Err).error.code, 'invalid_response');
  });

  test('ledger and metrics parse', () async {
    final ledger = await repository.ledgerForOrder(orderIdFixture);
    expect((ledger as Ok).value, hasLength(2));
    final metrics = await repository.metrics();
    expect((metrics as Ok).value.paidOrdersTotalCop, 1200000);
  });
}
