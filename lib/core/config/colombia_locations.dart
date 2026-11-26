// Departamentos y municipios de Colombia (DANE DIVIPOLA) usados en el perfil de proveedor.
import '../utils/text_search.dart';

part 'colombia_locations_data.dart';

class ColombiaMunicipality {
  const ColombiaMunicipality(this.code, this.name, this.lat, this.lng);

  /// DIVIPOLA code (5 digits).
  final String code;
  final String name;

  /// Coordinates of the urban centre, as published by DANE.
  final double lat, lng;
}

class ColombiaDepartment {
  const ColombiaDepartment(this.code, this.name, this.municipalities);
  final String code;
  final String name;
  final List<ColombiaMunicipality> municipalities;
}

abstract final class ColombiaLocations {
  static const List<ColombiaDepartment> departments = _divipola;

  static ColombiaDepartment? department(String? name) {
    if (name == null) return null;
    final key = foldForSearch(name);
    for (final department in departments) {
      if (foldForSearch(department.name) == key) return department;
    }
    return null;
  }

  static ColombiaMunicipality? municipality(String? department, String? name) {
    if (name == null) return null;
    final key = foldForSearch(name);
    for (final municipality
        in ColombiaLocations.department(department)?.municipalities ??
            const <ColombiaMunicipality>[]) {
      if (foldForSearch(municipality.name) == key) return municipality;
    }
    return null;
  }

  /// Maps a saved (department, municipality) pair to the official names. Profiles saved with
  /// the old short list may say "Cundinamarca / Bogotá" or lack accents; when the pair cannot
  /// be matched, the municipality is cleared so the person picks it again.
  static (String?, String?) resolve(String? department, String? municipality) {
    final exact = ColombiaLocations.municipality(department, municipality);
    if (exact != null) {
      return (ColombiaLocations.department(department)!.name, exact.name);
    }
    if (municipality == null) {
      return (ColombiaLocations.department(department)?.name, null);
    }
    final key = foldForSearch(municipality);
    final matches = <(ColombiaDepartment, ColombiaMunicipality)>[
      for (final candidate in departments)
        for (final item in candidate.municipalities)
          if (foldForSearch(item.name) == key ||
              foldForSearch(item.name).startsWith('$key,'))
            (candidate, item),
    ];
    if (matches.length == 1) {
      return (matches.single.$1.name, matches.single.$2.name);
    }
    return (ColombiaLocations.department(department)?.name, null);
  }
}

abstract final class ColombiaBounds {
  static const minLat = -4.3;
  static const maxLat = 13.7;
  static const minLng = -81.8;
  static const maxLng = -66.9;
  static const coordinateDecimals = 4;

  /// Where the map opens before a municipality is chosen (Bogotá).
  static const defaultLat = 4.6493;
  static const defaultLng = -74.107;

  static bool contains(double lat, double lng) =>
      lat >= minLat && lat <= maxLat && lng >= minLng && lng <= maxLng;
}
