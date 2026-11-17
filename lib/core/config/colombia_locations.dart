// Departamentos, municipios y limites usados en el perfil de proveedor.
const colombiaDepartments = <String, List<String>>{
  'Boyacá': [
    'Tunja',
    'Duitama',
    'Sogamoso',
    'Chiquinquirá',
    'Villa de Leyva',
    'Paipa',
    'Tibasosa'
  ],
  'Cundinamarca': [
    'Bogotá',
    'Fusagasugá',
    'Zipaquirá',
    'Facatativá',
    'Chía',
    'Ubaté',
    'La Mesa',
    'Girardot'
  ],
  'Antioquia': ['Medellín', 'Rionegro', 'La Ceja', 'Marinilla', 'Apartadó'],
  'Santander': ['Bucaramanga', 'Floridablanca', 'Piedecuesta', 'San Gil'],
  'Valle del Cauca': ['Cali', 'Palmira', 'Tuluá', 'Buga'],
  'Nariño': ['Pasto', 'Ipiales', 'Tumaco'],
};

abstract final class ColombiaBounds {
  static const minLat = -4.3;
  static const maxLat = 13.7;
  static const minLng = -81.8;
  static const maxLng = -66.9;
  static const referenceLat = 5.5353;
  static const referenceLng = -73.3678;
  static const coordinateDecimals = 4;

  static bool contains(double lat, double lng) =>
      lat >= minLat && lat <= maxLat && lng >= minLng && lng <= maxLng;
}
