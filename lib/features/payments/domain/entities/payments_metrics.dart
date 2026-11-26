/// Métricas operativas de pagos (`GET /backoffice/metrics`). Solo se toman
/// los campos que usa el resumen de pagos; el resto se ignora.
class PaymentsMetrics {
  const PaymentsMetrics({
    required this.generatedAt,
    required this.paidOrdersTotalCop,
    required this.proofsAwaitingReview,
    required this.oldestProofUploadedAt,
    required this.openDisputes,
    required this.settlementsIssued,
    required this.settlementsPaid,
    this.ordersByStatus = const {},
  });

  /// Estados del pedido que suma `paidOrdersTotalCop` en el backend
  /// (`ordering/.../drizzle-repositories.ts`, `metrics()`): el total cobrado
  /// incluye los pedidos pagados y los que siguieron después del pago, no solo
  /// `paid`. El conteo usa los mismos estados para que monto y cantidad
  /// describan el mismo conjunto. Ojo: `closed` incluye también pedidos
  /// cerrados tras un reembolso, igual que el monto del servidor.
  static const paidOrderStatuses = {
    'paid',
    'pickup_scheduled',
    'in_transit',
    'delivered',
    'closed',
  };

  final DateTime generatedAt;
  final int paidOrdersTotalCop;
  final int proofsAwaitingReview;
  final DateTime? oldestProofUploadedAt;
  final int openDisputes;

  /// Liquidaciones emitidas que aún no se pagan.
  final AmountCount settlementsIssued;
  final AmountCount settlementsPaid;

  /// Pedidos por estado. Claves desconocidas se conservan pero no se usan;
  /// valores que no son enteros se descartan.
  final Map<String, int> ordersByStatus;

  /// Pedidos que forman `paidOrdersTotalCop` (ver `paidOrderStatuses`).
  int get paidOrdersCount => paidOrderStatuses.fold(
      0, (sum, status) => sum + (ordersByStatus[status] ?? 0));

  /// Antigüedad del comprobante más viejo, medida contra `generatedAt` (el
  /// reloj del servidor), no contra el reloj del equipo.
  Duration? get oldestProofAge {
    final oldest = oldestProofUploadedAt;
    if (oldest == null) return null;
    final age = generatedAt.difference(oldest);
    return age.isNegative ? Duration.zero : age;
  }

  bool oldestProofOverdue(int hours) =>
      (oldestProofAge ?? Duration.zero) > Duration(hours: hours);

  factory PaymentsMetrics.fromJson(Map<String, dynamic> json) {
    final payments = Map<String, dynamic>.from(json['payments'] as Map);
    return PaymentsMetrics(
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      paidOrdersTotalCop: parseSignedMoney(json['paidOrdersTotalCop']),
      proofsAwaitingReview: payments['proofsAwaitingReview'] as int,
      oldestProofUploadedAt: payments['oldestProofUploadedAt'] is String
          ? DateTime.parse(payments['oldestProofUploadedAt'] as String)
          : null,
      openDisputes: payments['openDisputes'] as int,
      settlementsIssued: AmountCount.fromJson(
          Map<String, dynamic>.from(payments['settlementsIssued'] as Map)),
      settlementsPaid: AmountCount.fromJson(
          Map<String, dynamic>.from(payments['settlementsPaid'] as Map)),
      ordersByStatus: _counts(json['ordersByStatus']),
    );
  }
}

Map<String, int> _counts(Object? value) {
  if (value is! Map) return const {};
  return {
    for (final entry in value.entries)
      if (entry.key is String &&
          entry.value is int &&
          (entry.value as int) >= 0)
        entry.key as String: entry.value as int,
  };
}

class AmountCount {
  const AmountCount({required this.count, required this.amountCop});
  final int count;
  final int amountCop;

  factory AmountCount.fromJson(Map<String, dynamic> json) => AmountCount(
        count: json['count'] as int,
        amountCop: parseSignedMoney(json['amountCop']),
      );
}

/// Montos del backoffice: enteros con signo en texto
/// (`^-?(0|[1-9]\d{0,18})$`).
int parseSignedMoney(Object? value) {
  if (value is int) return value;
  if (value is String && RegExp(r'^-?(0|[1-9]\d{0,18})$').hasMatch(value)) {
    return int.parse(value);
  }
  throw const FormatException('Monto inválido.');
}
