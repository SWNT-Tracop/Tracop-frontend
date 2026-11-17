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
}
