import 'package:intl/intl.dart';

// Formatos de moneda y fecha usados en catalogo y lotes.
abstract final class AppFormats {
  static const locale = 'es_CO';

  static String money(int value) =>
      NumberFormat.currency(locale: locale, symbol: r'$ ', decimalDigits: 0)
          .format(value);
  static String moneyText(String value) => money(int.tryParse(value) ?? 0);
  static String dayMonth(DateTime date) =>
      DateFormat('d MMM', locale).format(date.toLocal());
  static String dayMonthYear(DateTime date) =>
      DateFormat('d MMM y', locale).format(date.toLocal());
  static String dayMonthTime(DateTime date) =>
      DateFormat('d MMM, HH:mm', locale).format(date.toLocal());

  /// Pesos colombianos como `$90.000` (símbolo adelante, sin espacio). Solo
  /// lo usa el módulo de pagos; `money` se mantiene para el resto de la app.
  static String cop(int value) =>
      '\$${NumberFormat.decimalPattern(locale).format(value)}';
  static String copText(String value) => cop(int.tryParse(value) ?? 0);

  // Colombia usa UTC-5 todo el año (sin horario de verano). Los pagos se
  // muestran siempre en hora de Bogotá, sin depender de la zona del equipo.
  static const bogotaOffset = Duration(hours: -5);

  /// Hora de pared de Bogotá para un instante; el resultado es un `DateTime`
  /// UTC cuyos campos son los de Bogotá, para formatear sin conversión local.
  static DateTime toBogota(DateTime instant) =>
      instant.toUtc().add(bogotaOffset);
  static String bogotaDateTime(DateTime instant) =>
      DateFormat('d MMM y, HH:mm', locale).format(toBogota(instant));
  static String bogotaDate(DateTime instant) =>
      DateFormat('d MMM y', locale).format(toBogota(instant));
  static String bogotaTime(DateTime instant) =>
      DateFormat('HH:mm', locale).format(toBogota(instant));
}
