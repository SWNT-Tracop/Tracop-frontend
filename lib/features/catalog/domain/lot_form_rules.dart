/// Reglas de validación que replica el formulario de lotes antes de llamar al API.
library;

/// Horizonte máximo de disponibilidad configurado por defecto en el servidor.
const int lotMaxHorizonDays = 90;

/// Límite seguro para precios enteros (JavaScript safe integer).
const int maxSafeUnitPrice = 9007199254740991;

const double colombiaMinLat = -4.3;
const double colombiaMaxLat = 13.7;
const double colombiaMinLng = -81.8;
const double colombiaMaxLng = -66.9;

/// Convierte un precio escrito con dígitos a entero positivo en COP.
int? parseUnitPrice(String raw) {
  final normalized = raw.trim();
  if (normalized.isEmpty || !RegExp(r'^\d+$').hasMatch(normalized)) {
    return null;
  }
  final value = int.tryParse(normalized);
  if (value == null || value <= 0 || value > maxSafeUnitPrice) return null;
  return value;
}

/// Acepta punto o coma decimal y devuelve `null` si el valor no es numérico.
double? parseCoordinate(String raw) {
  final normalized = raw.trim().replaceAll(',', '.');
  if (normalized.isEmpty) return null;
  final value = double.tryParse(normalized);
  if (value == null || !value.isFinite) return null;
  return value;
}

bool isWithinColombia(double lat, double lng) =>
    lat.isFinite &&
    lng.isFinite &&
    lat >= colombiaMinLat &&
    lat <= colombiaMaxLat &&
    lng >= colombiaMinLng &&
    lng <= colombiaMaxLng;

DateTime dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

DateTime endOfDay(DateTime value) =>
    DateTime(value.year, value.month, value.day, 23, 59, 59, 999);

/// Valida el rango de disponibilidad con el mismo criterio del dominio.
String? validateAvailability(
  DateTime from,
  DateTime until, {
  DateTime? now,
  int horizonDays = lotMaxHorizonDays,
}) {
  final start = dateOnly(from);
  final end = dateOnly(until);
  if (end.isBefore(start)) {
    return 'La fecha final debe ser igual o posterior a la inicial.';
  }
  final horizon = (now ?? DateTime.now()).add(Duration(days: horizonDays));
  if (endOfDay(until).isAfter(horizon)) {
    return 'La disponibilidad no puede superar $horizonDays días desde hoy.';
  }
  return null;
}
