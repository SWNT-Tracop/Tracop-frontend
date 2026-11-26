import 'package:flutter_test/flutter_test.dart';
import 'package:tracop_mobile/core/config/colombia_locations.dart';
import 'package:tracop_mobile/core/utils/text_search.dart';

void main() {
  test(
      'carries every DANE DIVIPOLA department and municipality inside Colombia',
      () {
    final municipalities = [
      for (final department in ColombiaLocations.departments)
        ...department.municipalities
    ];
    expect(ColombiaLocations.departments, hasLength(33));
    expect(municipalities, hasLength(1122));
    expect(municipalities.map((m) => m.code).toSet(), hasLength(1122));
    for (final municipality in municipalities) {
      expect(
          ColombiaBounds.contains(municipality.lat, municipality.lng), isTrue,
          reason: municipality.name);
    }
    expect(ColombiaLocations.municipality('Boyacá', 'Ventaquemada')?.code,
        '15861');
    expect(
        ColombiaLocations.municipality(
                'Norte de Santander', 'San José de Cúcuta')
            ?.code,
        '54001');
  });

  test('finds names without accents or capitals', () {
    expect(foldForSearch('  BOGOTÁ, D.C. '), 'bogota, d.c.');
    expect(ColombiaLocations.municipality('boyaca', 'TUNJA')?.name, 'Tunja');
  });

  test('maps profiles saved with the old short list to the official names', () {
    expect(ColombiaLocations.resolve('Cundinamarca', 'Bogotá'),
        ('Bogotá, D.C.', 'Bogotá, D.C.'));
    expect(ColombiaLocations.resolve('Boyaca', 'Villa de Leyva'),
        ('Boyacá', 'Villa de Leyva'));
    expect(ColombiaLocations.resolve('Boyacá', 'Pueblo que no existe'),
        ('Boyacá', null));
    expect(ColombiaLocations.resolve(null, null), (null, null));
  });
}
