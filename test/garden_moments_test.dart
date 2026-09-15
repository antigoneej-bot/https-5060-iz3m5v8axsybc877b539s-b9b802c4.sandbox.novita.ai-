import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/mongi/integration/garden_moments.dart';
import 'package:flutter_app/mongi/integration/mongi_garden_data.dart';

void main() {
  test('garden moments follow saved achievements independently', () {
    final empty = MongiGardenData();
    expect(gardenMoments.map((m) => m.isAvailable(empty, 0)), [
      true,
      false,
      false,
      false,
      false,
      false,
    ]);
    expect(gardenMoments[1].isAvailable(empty, 1), isTrue);
    expect(gardenMoments[2].isAvailable(empty.copy(stage: 2), 0), isTrue);
    expect(gardenMoments[3].isAvailable(empty.copy(seedTokens: 5), 0), isFalse);
    expect(
      gardenMoments[3].isAvailable(empty.copy(seeds: {'pine': 1}), 0),
      isTrue,
    );
    final restored = MongiGardenData.fromJson(
      empty
          .copy(
            stage: 2,
            seeds: {'pine': 1},
            recordDays: {'2026-09-15'},
            meditationDays: {'2026-09-15'},
          )
          .toJson(),
    );
    expect(gardenMoments.every((m) => m.isAvailable(restored, 1)), isTrue);
    expect(
      restored.storyProgress,
      isEmpty,
    ); // no paid chapter or reward mutation
  });
}
