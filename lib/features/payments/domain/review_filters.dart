import 'entities/payment.dart';

/// Filtros del lado del cliente para la cola de revisión: el API
/// (`GET /payments/review`) no acepta filtros, solo `limit`.
class ReviewFilters {
  const ReviewFilters({this.status, this.method, this.query = ''});

  final PaymentStatus? status;
  final PaymentMethod? method;
  final String query;

  /// Filtro inicial desde la ruta (`?filtro=comprobantes|disputas`).
  factory ReviewFilters.fromQuery(String? value) => ReviewFilters(
        status: switch (value) {
          'comprobantes' => PaymentStatus.proofUploaded,
          'disputas' => PaymentStatus.disputed,
          _ => null,
        },
      );

  bool get isActive => status != null || method != null || query.isNotEmpty;

  ReviewFilters copyWith({
    PaymentStatus? Function()? status,
    PaymentMethod? Function()? method,
    String? query,
  }) =>
      ReviewFilters(
        status: status == null ? this.status : status(),
        method: method == null ? this.method : method(),
        query: query ?? this.query,
      );

  bool matches(Payment payment) {
    if (status != null && payment.status != status) return false;
    if (method != null && payment.method != method) return false;
    final text = query.trim().toLowerCase();
    if (text.isEmpty) return true;
    return payment.id.toLowerCase().contains(text) ||
        payment.orderId.toLowerCase().contains(text);
  }

  /// Aplica los filtros y ordena del más antiguo al más reciente.
  List<Payment> apply(Iterable<Payment> payments) =>
      payments.where(matches).toList()
        ..sort((a, b) => a.waitingSince.compareTo(b.waitingSince));
}

bool isReviewOverdue(Payment payment, DateTime now, {required int hours}) =>
    now.difference(payment.waitingSince) > Duration(hours: hours);
