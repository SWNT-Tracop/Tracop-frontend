import '../../../core/i18n/formats.dart';
import 'entities/settlement.dart';

/// Periodo rápido sobre la fecha de emisión (`issuedAt`).
enum SettlementPeriod {
  all(null),
  last7Days(7),
  last30Days(30);

  const SettlementPeriod(this.days);
  final int? days;
}

/// Rango de días calendario (hora de Bogotá, ambos extremos incluidos)
/// sobre la fecha de emisión. Solo se usan año, mes y día de `start`/`end`.
class SettlementDateRange {
  SettlementDateRange({required DateTime start, required DateTime end})
      : start = DateTime.utc(start.year, start.month, start.day),
        end = DateTime.utc(end.year, end.month, end.day);

  final DateTime start;
  final DateTime end;

  /// El día de Bogotá en que se emitió está dentro del rango.
  bool contains(DateTime instant) {
    final local = AppFormats.toBogota(instant);
    final day = DateTime.utc(local.year, local.month, local.day);
    return !day.isBefore(start) && !day.isAfter(end);
  }

  @override
  bool operator ==(Object other) =>
      other is SettlementDateRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);
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
    this.range,
  });

  final BeneficiaryKind? kind;
  final SettlementPeriod period;
  final String query;

  /// Rango elegido con el calendario; reemplaza al periodo rápido.
  final SettlementDateRange? range;

  bool get isActive =>
      kind != null ||
      period != SettlementPeriod.all ||
      range != null ||
      query.isNotEmpty;

  SettlementFilters copyWith({
    BeneficiaryKind? Function()? kind,
    SettlementPeriod? period,
    String? query,
    SettlementDateRange? Function()? range,
  }) =>
      SettlementFilters(
        kind: kind == null ? this.kind : kind(),
        period: period ?? this.period,
        query: query ?? this.query,
        range: range == null ? this.range : range(),
      );

  /// Elegir un periodo rápido quita el rango, y viceversa.
  SettlementFilters withPeriod(SettlementPeriod value) =>
      copyWith(period: value, range: () => null);
  SettlementFilters withRange(SettlementDateRange? value) => copyWith(
      period: value == null ? period : SettlementPeriod.all,
      range: () => value);

  bool matches(Settlement settlement, DateTime now) {
    if (kind != null && settlement.beneficiaryKind != kind) return false;
    final range = this.range;
    if (range != null && !range.contains(settlement.issuedAt)) return false;
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
