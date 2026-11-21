// Limites y tiempos de la busqueda de lotes.
abstract final class CatalogConfig {
  static const pageSize = 20;
  static const searchDebounce = Duration(milliseconds: 350);
  static const availableSoonDays = 30;
  static const wideBreakpoint = 900.0;
  static const maxContentWidth = 1120.0;
  static const detailMaxWidth = 760.0;
  static const cardExtent = 252.0;
  static const staggerStep = Duration(milliseconds: 35);
  static const staggerDuration = Duration(milliseconds: 220);
  static const staggerLimit = 8;
}
