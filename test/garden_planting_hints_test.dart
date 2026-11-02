import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/mongi/models/garden_layout.dart';
import 'package:flutter_app/mongi/models/seed.dart';
import 'package:flutter_app/mongi/widgets/garden_planting_hints.dart';
import 'package:flutter_app/mongi/widgets/garden_world_view.dart';

void main() {
  test(
    'every hint passes durable placement rules for each seed and land stage',
    () {
      for (final spaces in [1, 2, 3]) {
        final layout = GardenLayout(
          spaces: spaces,
          positions: const {'seed:pine': Offset(.5, .7)},
        );
        final before = layout.toJson().toString();
        for (final seed in SeedType.all) {
          final id = 'seed:${seed.id}';
          final hints = layout.plantingHints(id, ['seed:pine']);
          expect(hints, isNotEmpty);
          for (final point in hints) {
            expect(layout.placementError(id, point, ['seed:pine']), isNull);
            expect(layout.isOpen(GardenLayout.spaceFor(point.dx)), isTrue);
            expect(GardenLayout.pondBounds.contains(point), isFalse);
          }
        }
        expect(layout.toJson().toString(), before);
      }
    },
  );

  test('occupied hints disappear without moving existing plants', () {
    final empty = GardenLayout(spaces: 3);
    final candidate = empty.plantingHints('seed:cherry', []).first;
    final occupied = GardenLayout(
      spaces: 3,
      positions: {'seed:pine': candidate},
    );
    expect(
      occupied.plantingHints('seed:cherry', ['seed:pine']),
      isNot(contains(candidate)),
    );
    expect(occupied.positions['seed:pine'], candidate);
    expect(
      empty.placementError('seed:pine', const Offset(.15, .4), []),
      contains('연못'),
    );
    expect(
      GardenLayout.fromJson(occupied.toJson()).positions,
      occupied.positions,
    );
  });

  testWidgets(
    'hints only during editable planting; invalid previews are hidden',
    (t) async {
      var writes = 0;
      Future<void> show({
        bool planting = true,
        bool readOnly = false,
        Offset point = const Offset(.5, .7),
      }) async {
        await t.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GardenWorldView(
                layout: GardenLayout(spaces: 3),
                seeds: const {},
                decorations: const [],
                fillViewport: true,
                cultivationMode: true,
                readOnly: readOnly,
                motionEnabled: false,
                companionAutomaticBehavior: false,
                placementSeed: planting ? SeedType.byId('pine') : null,
                placementPoint: planting ? point : null,
                onMove: (_, __) async {
                  writes++;
                },
                onMemory: (_) {
                  writes++;
                },
                onPlant: () {
                  writes++;
                },
                onDecorate: () {
                  writes++;
                },
              ),
            ),
          ),
        );
        await t.pumpAndSettle();
      }

      await show(planting: false);
      expect(find.byKey(const Key('planting-available-hints')), findsNothing);
      await show();
      expect(find.byKey(const Key('planting-available-hints')), findsOneWidget);
      expect(find.byKey(const Key('plant-location-preview')), findsOneWidget);
      final painter =
          t
                  .widget<CustomPaint>(
                    find.byKey(const Key('planting-available-hints')),
                  )
                  .painter!
              as GardenPlantingHints;
      expect(painter.validSelection, isTrue);
      final preview = t.widget<Positioned>(
        find.byKey(const Key('plant-location-preview')),
      );
      final width =
          SeedType.byId('pine').worldArtSize(1) * GardenLayout.depthAt(.7);
      expect(preview.left! + preview.width! / 2, closeTo(.5 * 2400, .001));
      expect(preview.top! + preview.height! * .9, closeTo(.7 * 800, .001));
      expect(preview.width, width);
      // Camera motion must not alter world-space selection or write to storage.
      await t.drag(
        find.byKey(const Key('garden-world-camera')),
        const Offset(-50, 0),
      );
      await t.pumpAndSettle();
      final afterPan = t.widget<Positioned>(
        find.byKey(const Key('plant-location-preview')),
      );
      expect(afterPan.left, preview.left);
      expect(afterPan.top, preview.top);
      await show(point: const Offset(.15, .4));
      expect(find.byKey(const Key('plant-location-preview')), findsNothing);
      await show(readOnly: true);
      expect(find.byKey(const Key('planting-available-hints')), findsNothing);
      expect(find.byKey(const Key('plant-location-preview')), findsNothing);
      expect(writes, 0);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    },
  );
}
