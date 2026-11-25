import 'entities/settlement.dart';

/// Periodo rápido sobre la fecha de emisión (`issuedAt`).
enum SettlementPeriod {
  all(null),
  last7Days(7),
  last30Days(30);

  const SettlementPeriod(this.days);
  final int? days;
}

/// Filtro de estado que sí entiende el servidor (`?status=`).
enum SettlementStatusFilter {
  issued(SettlementStatus.issued, 'emitidas'),
  paid(SettlementStatus.paid, 'pagadas'),
  all(null, 'todas');

  const SettlementStatusFilter(this.status, this.query);

  /// `null` = sin filtro (todas).
  final SettlementStatus? status;

  /// Valor del parámetro `estado` en la ruta `/pagos/liquidaciones`.
  final String query;

  static SettlementStatusFilter fromQuery(String? value,
          {SettlementStatusFilter fallback = SettlementStatusFilter.issued}) =>
      SettlementStatusFilter.values.firstWhere(
        (filter) => filter.query == value,
        orElse: () => fallback,
      );
}

/// Filtros del lado del cliente: `GET /settlements` solo filtra por estado.
class SettlementFilters {
  const SettlementFilters({
    this.kind,
    this.period = SettlementPeriod.all,
    this.query = '',
  });

  final BeneficiaryKind? kind;
  final SettlementPeriod period;
  final String query;

  bool get isActive =>
      kind != null || period != SettlementPeriod.all || query.isNotEmpty;

  SettlementFilters copyWith({
    BeneficiaryKind? Function()? kind,
    SettlementPeriod? period,
    String? query,
  }) =>
      SettlementFilters(
        kind: kind == null ? this.kind : kind(),
        period: period ?? this.period,
        query: query ?? this.query,
      );

  bool matches(Settlement settlement, DateTime now) {
    if (kind != null && settlement.beneficiaryKind != kind) return false;
    final days = period.days;
    if (days != null &&
        settlement.issuedAt.isBefore(now.subtract(Duration(days: days)))) {
      return false;
    }
    final text = query.trim().toLowerCase();
    if (text.isEmpty) return true;
    return settlement.orderId.toLowerCase().contains(text) ||
        settlement.paymentId.toLowerCase().contains(text);
  }

  /// Conserva el orden del servidor (más recientes primero).
  List<Settlement> apply(Iterable<Settlement> settlements, DateTime now) =>
      settlements.where((item) => matches(item, now)).toList(growable: false);
}
