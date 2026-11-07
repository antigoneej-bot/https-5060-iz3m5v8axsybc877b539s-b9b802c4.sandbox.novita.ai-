import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/mongi/models/garden_layout.dart';
import 'package:flutter_app/mongi/models/seed.dart';
import 'package:flutter_app/mongi/widgets/garden_world_view.dart';

void main() {
  for (final size in [const Size(640, 320), const Size(844, 390)]) {
    for (final selectedPlant in [false, true]) {
      testWidgets(
        'cover, map and exact camera restoration $size selected=$selectedPlant',
        (t) async {
          t.view.physicalSize = size;
          t.view.devicePixelRatio = 1;
          addTearDown(t.view.resetPhysicalSize);
          addTearDown(t.view.resetDevicePixelRatio);
          Future<void> show(bool map) async {
            await t.pumpWidget(
              MaterialApp(
                home: Scaffold(
                  body: GardenWorldView(
                    cultivationMode: true,
                    fillViewport: true,
                    cameraGestures: true,
                    overviewRequested: map,
                    motionEnabled: false,
                    companionAutomaticBehavior: false,
                    layout: GardenLayout(
                      spaces: 3,
                      positions: const {'seed:pine': Offset(.8, .7)},
                    ),
                    seeds: const {'pine': 4},
                    focusPlantId: selectedPlant ? 'pine' : null,
                    plantFocusRequest: selectedPlant ? 1 : 0,
                    decorations: const [],
                    onMove: (_, __) async {},
                    onMemory: (_) {},
                    onPlant: () {},
                    onDecorate: () {},
                  ),
                ),
              ),
            );
            await t.pumpAndSettle();
          }

          await show(false);
          final finder = find.byKey(const Key('garden-world-camera'));
          final controller = t
              .widget<InteractiveViewer>(finder)
              .transformationController!;
          expect(t.getSize(finder), size);
          final cover = math.max(size.width / 2400, size.height / 800);
          expect(2400 * cover, greaterThanOrEqualTo(size.width));
          expect(800 * cover, greaterThanOrEqualTo(size.height));
          await t.drag(finder, const Offset(100, 0));
          await t.pumpAndSettle();
          final p1 = await t.startGesture(
            size.center(Offset.zero) - const Offset(40, 0),
            pointer: 1,
          );
          final p2 = await t.startGesture(
            size.center(Offset.zero) + const Offset(40, 0),
            pointer: 2,
          );
          await p1.moveBy(const Offset(-100, 0));
          await p2.moveBy(const Offset(100, 0));
          await p1.up();
          await p2.up();
          await t.pumpAndSettle();
          expect(controller.value.getMaxScaleOnAxis(), greaterThan(cover));
          final saved = controller.value.clone();
          await show(true);
          final fit = controller.value.getMaxScaleOnAxis();
          expect(2400 * fit, lessThanOrEqualTo(size.width + .001));
          expect(800 * fit, lessThanOrEqualTo(size.height + .001));
          await show(false);
          expect(controller.value, saved);
          final savedCenter = controller.toScene(size.center(Offset.zero));
          final savedZoom = saved.getMaxScaleOnAxis() / cover;
          await show(true);
          const rotated = Size(390, 844);
          t.view.physicalSize = rotated;
          await t.pumpAndSettle();
          await show(false);
          final restoredCenter = controller.toScene(
            rotated.center(Offset.zero),
          );
          expect(restoredCenter.dx, closeTo(savedCenter.dx, .001));
          expect(restoredCenter.dy, closeTo(savedCenter.dy, .001));
          final rotatedCover = rotated.height / 800;
          expect(
            controller.value.getMaxScaleOnAxis() / rotatedCover,
            closeTo(savedZoom, .001),
          );
          t.view.physicalSize = size;
          await t.pumpAndSettle();
          expect(
            controller.toScene(size.center(Offset.zero)).dx,
            closeTo(savedCenter.dx, .001),
          );
          expect(
            controller.value.getMaxScaleOnAxis() / cover,
            closeTo(savedZoom, .001),
          );
          expect(t.takeException(), isNull);
          await t.pumpWidget(const SizedBox());
        },
      );
    }
  }

  testWidgets(
    'placement ignores pan and multitouch but accepts a deliberate tap',
    (t) async {
      var selected = 0;
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GardenWorldView(
              cultivationMode: true,
              fillViewport: true,
              cameraGestures: true,
              motionEnabled: false,
              companionAutomaticBehavior: false,
              placementSeed: SeedType.byId('pine'),
              onPlacementPoint: (_) => selected++,
              layout: GardenLayout(
                spaces: 3,
                positions: const {'seed:pine': Offset(.8, .7)},
              ),
              seeds: const {'pine': 4},
              focusPlantId: 'pine',
              plantFocusRequest: 1,
              decorations: const [],
              onMove: (_, __) async {},
              onMemory: (_) {},
              onPlant: () {},
              onDecorate: () {},
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      final finder = find.byKey(const Key('garden-world-camera'));
      await t.drag(finder, const Offset(90, 0));
      await t.pumpAndSettle();
      expect(selected, 0);
      final center = t.getCenter(finder);
      final a = await t.startGesture(center - const Offset(40, 0), pointer: 1);
      final b = await t.startGesture(center + const Offset(40, 0), pointer: 2);
      await a.moveBy(const Offset(-20, 0));
      await b.moveBy(const Offset(20, 0));
      await a.up();
      await b.up();
      await t.pumpAndSettle();
      expect(selected, 0);
      await t.tapAt(center);
      await t.pump();
      expect(selected, 1);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    },
  );
}
