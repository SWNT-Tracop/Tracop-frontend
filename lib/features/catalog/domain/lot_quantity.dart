const int maxQuantityMilli = 999999999999;

/// Convierte una cantidad escrita por la persona usuaria a milésimas.
///
/// Acepta enteros o hasta tres decimales, con punto o coma decimal.
/// Devuelve `null` cuando el valor no es válido.
int? parseQuantityMilli(String raw) {
  final normalized = raw.trim().replaceAll(',', '.');
  if (normalized.isEmpty) return null;

  final match = RegExp(r'^(\d{1,9})(?:\.(\d{1,3}))?$').firstMatch(normalized);
  if (match == null) return null;

  final whole = int.parse(match.group(1)!);
  final fraction = (match.group(2) ?? '').padRight(3, '0');
  final milli = whole * 1000 + int.parse(fraction.isEmpty ? '0' : fraction);
  if (milli <= 0 || milli > maxQuantityMilli) return null;
  return milli;
}

/// Presenta una cantidad en milésimas sin ceros decimales innecesarios.
String formatQuantityMilli(String quantityMilli) {
  final value = int.tryParse(quantityMilli) ?? 0;
  final whole = value ~/ 1000;
  final fraction = (value % 1000)
      .toString()
      .padLeft(3, '0')
      .replaceFirst(RegExp(r'0+$'), '');
  return fraction.isEmpty ? '$whole' : '$whole.$fraction';
}
