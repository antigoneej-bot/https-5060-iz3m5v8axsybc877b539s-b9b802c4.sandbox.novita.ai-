import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/mongi/models/garden_layout.dart';
import 'package:flutter_app/mongi/widgets/garden_ambient.dart';
import 'package:flutter_app/mongi/widgets/garden_world_view.dart';
import 'package:flutter_app/mongi/widgets/storybook_garden.dart';

void main() {
  testWidgets(
    'original day and night restore the existing assets and nature painter',
    (t) async {
      var writes = 0;
      Future<void> show({required bool original, required bool night}) async {
        await t.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GardenWorldView(
                originalScenery: original,
                nightOverride: night,
                readOnly: true,
                cultivationMode: true,
                fillViewport: true,
                motionEnabled: false,
                companionAutomaticBehavior: false,
                layout: GardenLayout(spaces: 3),
                seeds: const {},
                decorations: const [],
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

      await show(original: true, night: false);
      Image backdrop() =>
          t.widget<Image>(find.byKey(const Key('original-garden-backdrop')));
      expect(
        (backdrop().image as AssetImage).assetName,
        'assets/living_garden/cultivation_day.png',
      );
      expect(
        t
            .widgetList<CustomPaint>(find.byType(CustomPaint))
            .map((w) => w.painter)
            .whereType<GardenAtmosphere>()
            .single
            .night,
        isFalse,
      );
      expect(find.byKey(const Key('storybook-foreground')), findsNothing);
      await show(original: true, night: true);
      expect(
        (backdrop().image as AssetImage).assetName,
        'assets/living_garden/cultivation_night.png',
      );
      expect(
        t
            .widgetList<CustomPaint>(find.byType(CustomPaint))
            .map((w) => w.painter)
            .whereType<GardenAtmosphere>()
            .single
            .night,
        isTrue,
      );
      await show(original: false, night: true);
      expect(find.byType(StorybookBackdrop), findsOneWidget);
      expect(find.byType(StorybookForeground), findsOneWidget);
      expect(find.byKey(const Key('original-garden-backdrop')), findsNothing);
      expect(writes, 0);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    },
  );
}
