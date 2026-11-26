import 'entities/payment.dart';

/// Estados del pedido en los que el comprador puede iniciar un pago o subir
/// el comprobante (backend: `startPayment` y `holdStockForPaymentReview`).
const payableOrderStatuses = {'accepted', 'payment_pending'};

/// Estados del pedido que admiten pasar a `disputed` (`order.ts`).
const disputableOrderStatuses = {
  'paid',
  'pickup_scheduled',
  'in_transit',
  'delivered',
};

/// Acciones que la interfaz puede ofrecer sobre un pago.
enum PaymentAction {
  uploadProof,
  startNewPayment,
  openDispute,
  verify,
  reject,
  resolveDispute,
}

/// Qué acciones mostrar según estado y rol. Refleja las transiciones del
/// dominio del backend (`payment.ts`); el servidor sigue siendo la autoridad,
/// esto solo evita ofrecer botones que fallarían.
abstract final class PaymentPermissions {
  static const staffRoles = {'finance', 'operator', 'admin'};

  static bool isStaff(String? role) => staffRoles.contains(role);

  /// "Ver auditoría": solo administración (el API responde 403 al resto).
  static bool canViewAudit(String? role) => role == 'admin';

  static Set<PaymentAction> actionsFor(PaymentStatus status, String? role) {
    if (role == 'buyer') {
      return switch (status) {
        PaymentStatus.pending => {PaymentAction.uploadProof},
        PaymentStatus.rejected => {PaymentAction.startNewPayment},
        // El servidor responde 409 settlement_issued si ya hay liquidaciones.
        PaymentStatus.verified || PaymentStatus.held => {
            PaymentAction.openDispute
          },
        _ => const {},
      };
    }
    if (isStaff(role)) {
      return switch (status) {
        PaymentStatus.proofUploaded => {
            PaymentAction.verify,
            PaymentAction.reject,
          },
        PaymentStatus.disputed => {PaymentAction.resolveDispute},
        _ => const {},
      };
    }
    return const {};
  }

  /// "Liberar" una disputa solo es válido si el pedido ya fue entregado
  /// (`heldAt`); si no, el backend responde `dispute_not_releasable`.
  static bool canRelease(Payment payment) => payment.heldAt != null;

  /// El comprador puede disputar si el pago está verificado o retenido, aún
  /// no tiene disputa y el pedido está en un estado que admite `disputed`.
  static bool canOpenDispute(Payment payment, String orderStatus) =>
      actionsFor(payment.status, 'buyer').contains(PaymentAction.openDispute) &&
      payment.disputeReason == null &&
      disputableOrderStatuses.contains(orderStatus);

  /// Mostrar método, instrucciones y carga: el pedido debe ser pagable y,
  /// en una compilación release, los datos de cuenta deben ser reales.
  static bool paymentsAvailable(
          {required bool releaseMode, required bool hasPlaceholderData}) =>
      !(releaseMode && hasPlaceholderData);

  /// Botón de la demo local de logística (ver docs/payments-decisions.md).
  static bool showLocalPaymentDemo({
    required bool enabled,
    required bool isBuyer,
    required String orderStatus,
    required bool isLocallyPaid,
  }) =>
      enabled &&
      isBuyer &&
      !isLocallyPaid &&
      payableOrderStatuses.contains(orderStatus);
}
