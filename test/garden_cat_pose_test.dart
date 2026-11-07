import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/mongi/widgets/garden_cat_pose.dart';
import 'package:flutter_app/mongi/models/garden_life.dart';

void main() {
  testWidgets('all walk frames preserve aspect ratio and share idle ground',
      (tester) async {
    for (final frame in [-1, 0, 1, 2, 3, 4, 5, 6, 7]) {
      final walking = frame >= 0;
      await tester.pumpWidget(MaterialApp(home: Center(child: SizedBox(
        key: const Key('ground-box'), width: 160, height: 160,
        child: GardenCatPose(walking: walking, frame: walking ? frame : 0,
          child: const ColoredBox(key: Key('source-art'), color: Colors.orange)),
      ))));
      final art = tester.getRect(find.byKey(const Key('source-art')));
      final box = tester.getRect(find.byKey(const Key('ground-box')));
      final foot = art.top + art.height * GardenCatPose.footFraction(
        walking: walking, frame: walking ? frame : 0);
      expect(foot, closeTo(box.bottom, .001));
      expect(art.width / art.height, closeTo(1, .001));
    }
  });

  test('bench state belongs to bench rest, not ordinary rest', () {
    expect(GardenCatMoment.at(0, animated: false,
      bench: const Offset(1300, 600)).onBench, isFalse);
    var sawBench = false;
    for (var t = 0.0; t < 180; t += .1) {
      final m = GardenCatMoment.at(t, bench: const Offset(1300, 600));
      if (m.onBench) {
        sawBench = true;
        expect(m.walking, isFalse);
        expect(m.resting, isTrue);
        expect(m.feet, const Offset(1300, 542));
      }
    }
    expect(sawBench, isTrue);
  });
}
