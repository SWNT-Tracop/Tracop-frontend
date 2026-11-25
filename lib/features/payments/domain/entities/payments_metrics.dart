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
  });

  final DateTime generatedAt;
  final int paidOrdersTotalCop;
  final int proofsAwaitingReview;
  final DateTime? oldestProofUploadedAt;
  final int openDisputes;

  /// Liquidaciones emitidas que aún no se pagan.
  final AmountCount settlementsIssued;
  final AmountCount settlementsPaid;

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
    );
  }
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
