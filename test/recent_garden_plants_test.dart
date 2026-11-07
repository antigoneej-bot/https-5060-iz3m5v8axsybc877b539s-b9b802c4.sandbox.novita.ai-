import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/utils/recent_garden_plants.dart';

void main() {
  test('same-day plants remain candidates without an invented timestamp', () {
    expect(
      recentGardenPlants(
        seeds: {'a': 1, 'b': 2, 'c': 4},
        plantedOn: {'a': '2026-10-31', 'b': '2026-11-01', 'c': '2026-11-01'},
      ),
      unorderedEquals(['b', 'c']),
    );
  });
  test('only an actual planting in this session can break the tie', () {
    expect(
      recentGardenPlants(
        seeds: {'a': 1, 'b': 2},
        plantedOn: {'a': '2026-11-01', 'b': '2026-11-01'},
        sessionLast: 'b',
      ),
      ['b'],
    );
  });
  test('undated legacy and removed plants are not assigned a planting day', () {
    expect(
      recentGardenPlants(
        seeds: {'legacy': 3, 'deleted': 0},
        plantedOn: {'deleted': '2026-11-01'},
        sessionLast: 'deleted',
      ),
      isEmpty,
    );
  });
}
