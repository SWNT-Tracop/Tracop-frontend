import '../../../../core/result/result.dart';
import '../entities/payment.dart';

abstract interface class PaymentRepository {
  /// Pago más reciente del pedido, o `null` si todavía no tiene.
  Future<Result<Payment?, DomainFailure>> getForOrder(String orderId);
  Future<Result<Payment, DomainFailure>> getById(String paymentId);

  /// Crea (o devuelve, si ya existe uno abierto) el pago del pedido.
  Future<Result<Payment, DomainFailure>> initiate({
    required String orderId,
    required String paymentId,
    required PaymentMethod method,
  });

  /// Pide la autorización, sube la imagen al almacenamiento y la confirma.
  Future<Result<Payment, DomainFailure>> uploadProof(
      String paymentId, ProofFile file);

  Future<Result<Payment, DomainFailure>> dispute(
      String paymentId, int expectedVersion, String reason);

  // Personal (finance, operator, admin).
  Future<Result<List<Payment>, DomainFailure>> reviewQueue({int limit = 100});
  Future<Result<Payment, DomainFailure>> verify(
      String paymentId, int expectedVersion);
  Future<Result<Payment, DomainFailure>> reject(
      String paymentId, int expectedVersion, String reason);
  Future<Result<Payment, DomainFailure>> resolveDispute(
    String paymentId,
    int expectedVersion,
    DisputeOutcome outcome,
    String note,
  );
}
