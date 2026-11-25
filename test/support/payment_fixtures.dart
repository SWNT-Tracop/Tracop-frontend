import 'package:tracop_mobile/core/result/result.dart';
import 'package:tracop_mobile/features/payments/domain/entities/payment.dart';
import 'package:tracop_mobile/features/payments/domain/entities/ledger.dart';
import 'package:tracop_mobile/features/payments/domain/entities/payments_metrics.dart';
import 'package:tracop_mobile/features/payments/domain/entities/settlement.dart';
import 'package:tracop_mobile/features/payments/domain/repository/payment_backoffice_repository.dart';
import 'package:tracop_mobile/features/payments/domain/repository/payment_repository.dart';

const paymentId = '018f47a2-8b45-7cc2-9a1e-123456789abc';
const orderIdFixture = '018f47a2-8b45-7cc2-9a1e-123456789abd';

Map<String, dynamic> paymentJson({
  String id = paymentId,
  String orderId = orderIdFixture,
  String status = 'proof_uploaded',
  String method = 'transfer',
  int version = 3,
  String total = '100000',
  String? proofUploadedAt = '2026-11-24T15:00:00.000Z',
  String? proofUrl,
  String? reviewedAt,
  String? rejectionReason,
  String? heldAt,
  String? disputeReason,
  String updatedAt = '2026-11-24T15:00:00.000Z',
}) =>
    {
      'id': id,
      'orderId': orderId,
      'method': method,
      'status': status,
      'version': version,
      'subtotal': '95000',
      'freight': '5000',
      'commission': '4750',
      'total': total,
      'providerNet': '90250',
      'proofUploadedAt': proofUploadedAt,
      'proofUrl': proofUrl,
      'reviewedAt': reviewedAt,
      'rejectionReason': rejectionReason,
      'heldAt': heldAt,
      'disputeReason': disputeReason,
      'createdAt': '2026-11-24T14:00:00.000Z',
      'updatedAt': updatedAt,
    };

Payment paymentFixture({
  String id = paymentId,
  String status = 'proof_uploaded',
  String method = 'transfer',
  String? proofUploadedAt = '2026-11-24T15:00:00.000Z',
  String? rejectionReason,
  String? heldAt,
  String? disputeReason,
  String updatedAt = '2026-11-24T15:00:00.000Z',
  String orderId = orderIdFixture,
}) =>
    Payment.fromJson(paymentJson(
      id: id,
      orderId: orderId,
      status: status,
      method: method,
      proofUploadedAt: proofUploadedAt,
      rejectionReason: rejectionReason,
      heldAt: heldAt,
      disputeReason: disputeReason,
      updatedAt: updatedAt,
    ));

/// Repositorio falso configurable para pruebas de widgets.
class FakePaymentRepository implements PaymentRepository {
  Payment? forOrder;
  List<Payment> queue = const [];
  Future<Result<Payment, DomainFailure>> Function()? onVerify;
  final initiateCalls = <Map<String, Object>>[];
  int verifyCalls = 0;
  int reviewQueueCalls = 0;
  int uploadCalls = 0;
  Future<Result<Payment, DomainFailure>> Function()? onUpload;

  @override
  Future<Result<Payment?, DomainFailure>> getForOrder(String orderId) async =>
      Ok(forOrder);

  @override
  Future<Result<Payment, DomainFailure>> getById(String paymentId) async =>
      Ok(queue.firstWhere((item) => item.id == paymentId,
          orElse: () => forOrder!));

  @override
  Future<Result<Payment, DomainFailure>> initiate({
    required String orderId,
    required String paymentId,
    required PaymentMethod method,
  }) async {
    initiateCalls.add({'orderId': orderId, 'id': paymentId, 'method': method});
    return const Err(DomainFailure(
        statusCode: 503, code: 'network_error', message: 'sin red'));
  }

  @override
  Future<Result<Payment, DomainFailure>> uploadProof(
      String paymentId, ProofFile file) {
    uploadCalls++;
    return onUpload?.call() ?? Future.value(Ok(forOrder!));
  }

  @override
  Future<Result<Payment, DomainFailure>> dispute(
          String paymentId, int expectedVersion, String reason) async =>
      Ok(forOrder!);

  @override
  Future<Result<List<Payment>, DomainFailure>> reviewQueue(
      {int limit = 100}) async {
    reviewQueueCalls++;
    return Ok(queue);
  }

  @override
  Future<Result<Payment, DomainFailure>> verify(
      String paymentId, int expectedVersion) {
    verifyCalls++;
    return onVerify!();
  }

  @override
  Future<Result<Payment, DomainFailure>> reject(
          String paymentId, int expectedVersion, String reason) async =>
      Ok(queue.first);

  @override
  Future<Result<Payment, DomainFailure>> resolveDispute(String paymentId,
          int expectedVersion, DisputeOutcome outcome, String note) async =>
      Ok(queue.first);
}

// ---------------------------------------------------------------------------
// Fase B: liquidaciones, libro y métricas.

const settlementId = '018f47a2-8b45-7cc2-9a1e-1234567890a1';
const beneficiaryIdFixture = '018f47a2-8b45-7cc2-9a1e-1234567890b2';
const transactionA = '018f47a2-8b45-7cc2-9a1e-1234567890c3';
const transactionB = '018f47a2-8b45-7cc2-9a1e-1234567890c4';

Map<String, dynamic> settlementJson({
  String id = settlementId,
  String paymentId = paymentId,
  String orderId = orderIdFixture,
  String beneficiaryKind = 'producer',
  String amount = '90000',
  String status = 'issued',
  String issuedAt = '2026-11-20T15:00:00.000Z',
  String? paidAt,
  String? reference,
  int version = 1,
}) =>
    {
      'id': id,
      'paymentId': paymentId,
      'orderId': orderId,
      'beneficiaryId': beneficiaryIdFixture,
      'beneficiaryKind': beneficiaryKind,
      'amount': amount,
      'status': status,
      'issuedAt': issuedAt,
      'paidAt': paidAt,
      'reference': reference,
      'version': version,
    };

Settlement settlementFixture({
  String id = settlementId,
  String paymentId = paymentId,
  String orderId = orderIdFixture,
  String beneficiaryKind = 'producer',
  String amount = '90000',
  String status = 'issued',
  String issuedAt = '2026-11-20T15:00:00.000Z',
  String? paidAt,
  String? reference,
  int version = 1,
}) =>
    Settlement.fromJson(settlementJson(
      id: id,
      paymentId: paymentId,
      orderId: orderId,
      beneficiaryKind: beneficiaryKind,
      amount: amount,
      status: status,
      issuedAt: issuedAt,
      paidAt: paidAt,
      reference: reference,
      version: version,
    ));

Map<String, dynamic> ledgerEntryJson({
  String transactionId = transactionA,
  String kind = 'payment_verified',
  String account = 'cash_held',
  String debit = '0',
  String credit = '0',
  String createdAt = '2026-11-20T15:00:00.000Z',
}) =>
    {
      'transactionId': transactionId,
      'kind': kind,
      'account': account,
      'debit': debit,
      'credit': credit,
      'createdAt': createdAt,
    };

/// Libro cuadrado: pago verificado y entrega confirmada.
List<LedgerEntry> balancedLedger() => [
      ledgerEntryJson(account: 'cash_held', debit: '100000'),
      ledgerEntryJson(account: 'payable_buyer_funds', credit: '100000'),
      ledgerEntryJson(
          transactionId: transactionB,
          kind: 'delivery_confirmed',
          account: 'payable_buyer_funds',
          debit: '100000',
          createdAt: '2026-11-21T15:00:00.000Z'),
      ledgerEntryJson(
          transactionId: transactionB,
          kind: 'delivery_confirmed',
          account: 'payable_producer',
          credit: '90000',
          createdAt: '2026-11-21T15:00:00.000Z'),
      ledgerEntryJson(
          transactionId: transactionB,
          kind: 'delivery_confirmed',
          account: 'revenue_commission',
          credit: '10000',
          createdAt: '2026-11-21T15:00:00.000Z'),
    ].map(LedgerEntry.fromJson).toList();

Map<String, dynamic> metricsJson({
  String generatedAt = '2026-11-25T15:00:00.000Z',
  String? oldestProofUploadedAt = '2026-11-23T15:00:00.000Z',
  int proofs = 3,
  int disputes = 1,
  String issuedAmount = '250000',
  int issuedCount = 2,
  String paidAmount = '750000',
  int paidCount = 5,
  String paidOrders = '1200000',
}) =>
    {
      'generatedAt': generatedAt,
      'ordersByStatus': {'paid': 4},
      'paidOrdersTotalCop': paidOrders,
      'lotsByStatus': {'published': 2},
      'payments': {
        'proofsAwaitingReview': proofs,
        'oldestProofUploadedAt': oldestProofUploadedAt,
        'openDisputes': disputes,
        'settlementsIssued': {'count': issuedCount, 'amountCop': issuedAmount},
        'settlementsPaid': {'count': paidCount, 'amountCop': paidAmount},
      },
      'notificationDeliveries': {'sent': 1},
      'outbox': {'pending': 0, 'deadLettered': 0},
    };

/// Repositorio falso del backoffice de pagos.
class FakePaymentBackofficeRepository implements PaymentBackofficeRepository {
  List<Settlement> settlementItems = const [];
  List<LedgerEntry> ledger = const [];
  PaymentsMetrics? metricsValue;
  final settlementCalls = <SettlementStatus?>[];
  int metricsCalls = 0;
  int markPaidCalls = 0;
  Future<Result<Settlement, DomainFailure>> Function(String? reference)?
      onMarkPaid;

  @override
  Future<Result<List<Settlement>, DomainFailure>> settlements(
      {SettlementStatus? status, int limit = 100}) async {
    settlementCalls.add(status);
    return Ok(settlementItems
        .where((item) => status == null || item.status == status)
        .toList());
  }

  @override
  Future<Result<Settlement, DomainFailure>> markSettlementPaid(
      String settlementId, int expectedVersion, String? reference) {
    markPaidCalls++;
    return onMarkPaid?.call(reference) ??
        Future.value(Ok(settlementItems.first));
  }

  @override
  Future<Result<List<LedgerEntry>, DomainFailure>> ledgerForOrder(
          String orderId) async =>
      Ok(ledger);

  @override
  Future<Result<PaymentsMetrics, DomainFailure>> metrics() async {
    metricsCalls++;
    return Ok(metricsValue ?? PaymentsMetrics.fromJson(metricsJson()));
  }
}
