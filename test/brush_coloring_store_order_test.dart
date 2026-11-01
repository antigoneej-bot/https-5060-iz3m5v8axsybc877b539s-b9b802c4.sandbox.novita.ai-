import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/models/coloring_stroke.dart';
import 'package:flutter_app/services/brush_coloring_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'save snapshots strokes before awaiting preferences and reentry waits for it',
    () async {
      final points = <Offset>[const Offset(20, 30)];
      final strokes = [ColoringStroke(0xffff0000, 16, false, points)];
      final write = BrushColoringStore('artist').save(strokes);
      // A gesture or departing screen can mutate its in-memory list immediately.
      points.add(const Offset(90, 90));
      strokes.clear();
      final reentry = BrushColoringStore('artist').load();
      await write;
      final restored = await reentry;
      expect(restored, hasLength(1));
      expect(restored.single.points, [const Offset(20, 30)]);
      expect(await BrushColoringStore('other').load(), isEmpty);
    },
  );

  test('concurrent screen instances retain requested save order', () async {
    final first = ColoringStroke(0xffff0000, 4, false, [const Offset(10, 10)]);
    final second = ColoringStroke(0xff00ff00, 16, false, [
      const Offset(20, 20),
    ]);
    final a = BrushColoringStore('artist');
    final b = BrushColoringStore('artist');
    final writes = [
      a.save([first]),
      b.save([first, second]),
    ];
    final reentry = BrushColoringStore('artist').load();
    await Future.wait(writes);
    expect((await reentry).map((s) => s.color), [first.color, second.color]);
  });
}
