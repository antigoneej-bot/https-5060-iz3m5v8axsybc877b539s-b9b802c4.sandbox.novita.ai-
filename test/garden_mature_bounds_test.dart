import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/mongi/models/garden_layout.dart';
import 'package:flutter_app/mongi/widgets/garden_world_view.dart';

void main() {
  test('new placement reserves mature width and ground access', () {
    final layout = GardenLayout(spaces: 3);
    expect(
      layout.placementError('seed:pine', const Offset(.035, .91), [
        'seed:pine',
      ]),
      isNotNull,
    );
    expect(
      layout.placementError('seed:pine', const Offset(.965, .91), [
        'seed:pine',
      ]),
      isNotNull,
    );
    expect(
      layout.placementError('seed:cherry', const Offset(.40, .55), [
        'seed:pine',
        'seed:cherry',
      ]),
      isNotNull,
    );
    expect(
      layout.placementError('seed:cherry', const Offset(.5, .7), [
        'seed:pine',
        'seed:cherry',
      ]),
      isNull,
    );
  });
  for (final viewport in [360.0, 390.0]) {
    testWidgets(
      'legacy edge roots stay fixed and mature bounds fit at $viewport',
      (tester) async {
        tester.view.physicalSize = Size(viewport, 780);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final layout = GardenLayout.fromJson({
          'version': 1,
          'spaces': 3,
          'positions': {
            'seed:pine': [.035, .91],
            'seed:cherry': [.965, .91],
          },
        });
        final before = layout.toJson();
        Future<void> show(int growth) async {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: GardenWorldView(
                  layout: layout,
                  seeds: {'pine': growth, 'cherry': growth},
                  decorations: const [],
                  motionEnabled: false,
                  companionAutomaticBehavior: false,
                  onMove: (_, __) async {},
                  onMemory: (_) {},
                  onPlant: () {},
                  onDecorate: () {},
                ),
              ),
            ),
          );
          await tester.pump();
        }

        await show(1);
        final roots = <String, double>{};
        for (final id in ['pine', 'cherry']) {
          final b = tester.widget<AnimatedPositioned>(
            find.byKey(ValueKey('world-position-seed:$id')),
          );
          roots[id] = b.left! + b.width! / 2;
        }
        await show(10);
        for (final id in ['pine', 'cherry']) {
          final b = tester.widget<AnimatedPositioned>(
            find.byKey(ValueKey('world-position-seed:$id')),
          );
          expect(b.left, greaterThanOrEqualTo(16));
          expect(b.left! + b.width!, lessThanOrEqualTo(2384.001));
          expect(b.top, greaterThanOrEqualTo(0));
          expect(b.top! + b.height!, lessThanOrEqualTo(800));
          expect(b.left! + b.width! / 2, closeTo(roots[id]!, .001));
        }
        expect(layout.toJson(), before); // saved positions remain unchanged
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
