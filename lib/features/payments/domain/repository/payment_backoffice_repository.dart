import '../../../../core/result/result.dart';
import '../entities/ledger.dart';
import '../entities/payments_metrics.dart';
import '../entities/settlement.dart';

/// Operaciones del personal sobre liquidaciones, libro y métricas. Separado
/// de `PaymentRepository` para no mezclar el flujo del comprador con el
/// backoffice.
abstract interface class PaymentBackofficeRepository {
  /// `GET /settlements`; `status == null` trae todas (máximo 100, más
  /// recientes primero).
  Future<Result<List<Settlement>, DomainFailure>> settlements(
      {SettlementStatus? status, int limit = 100});

  /// `POST /settlements/{id}/paid`. Una referencia vacía se envía como
  /// `null`.
  Future<Result<Settlement, DomainFailure>> markSettlementPaid(
      String settlementId, int expectedVersion, String? reference);

  Future<Result<List<LedgerEntry>, DomainFailure>> ledgerForOrder(
      String orderId);

  Future<Result<PaymentsMetrics, DomainFailure>> metrics();
}
