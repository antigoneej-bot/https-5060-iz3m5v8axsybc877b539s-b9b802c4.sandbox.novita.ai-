import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
// The installed plugin's official memory platform simulates a failed disk write.
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:flutter_app/mongi/integration/mongi_garden_store.dart';
import 'package:flutter_app/mongi/integration/plant_memory_editor.dart';
import 'package:flutter_app/mongi/models/plant_care.dart';
import 'package:flutter_app/mongi/models/seed.dart';
import 'package:flutter_app/mongi/models/garden_layout.dart';
import 'package:flutter_app/mongi/widgets/garden_world_view.dart';
import 'package:flutter_app/theme.dart';

class _Disk extends InMemorySharedPreferencesStore {
  bool fail = false;
  _Disk(MongiGardenData data)
    : super.withData({
        'flutter.${MongiGardenStore.storageKey}': jsonEncode(data.toJson()),
      });
  @override
  Future<bool> setValue(String type, String key, Object value) async =>
      fail ? false : super.setValue(type, key, value);
}

void main() {
  testWidgets(
    '360px large-text care buttons persist each action and failed writes retry',
    (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final disk = _Disk(MongiGardenData(seedTokens: 1).plant('pine'));
      SharedPreferencesStorePlatform.instance = disk;
      addTearDown(() => SharedPreferences.setMockInitialValues({}));
      final store = MongiGardenStore.instance;
      await store.reload();
      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.5)),
            child: child!,
          ),
          home: Scaffold(body: PlantMemoryEditor(plant: SeedType.byId('pine'))),
        ),
      );
      disk.fail = true;
      await tester.ensureVisible(
        find.byKey(const ValueKey('plant-care-fertilizer')),
      );
      await tester.tap(find.byKey(const ValueKey('plant-care-fertilizer')));
      await tester.pumpAndSettle();
      expect(store.value.growthFor('pine'), 1);
      expect(find.text('돌봄을 저장하지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
      disk.fail = false;
      for (final care in PlantCare.values) {
        final button = find.byKey(ValueKey('plant-care-${care.name}'));
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pumpAndSettle();
        expect(tester.widget<FilledButton>(button).onPressed, isNull);
      }
      await store.reload();
      expect(store.value.growthFor('pine'), closeTo(2 + 2 / 3, .00001));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'growth animates upwards with fixed roots and respects motion off',
    (tester) async {
      tester.view.physicalSize = const Size(390, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var count = 1;
      var remainder = 0;
      var motion = true;
      late StateSetter update;
      final capture = GlobalKey();
      if (Platform.environment['GARDEN_GROWTH_CAPTURE'] == '1') {
        await tester.runAsync(() async {
          for (final font in {
            'GowunDodum': 'assets/fonts/GowunDodum-Regular.ttf',
            'GamjaFlower': 'assets/fonts/GamjaFlower-Regular.ttf',
            'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
          }.entries) {
            await (FontLoader(
              font.key,
            )..addFont(rootBundle.load(font.value))).load();
          }
        });
      }
      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          home: RepaintBoundary(
            key: capture,
            child: Scaffold(
              body: StatefulBuilder(
                builder: (_, set) {
                  update = set;
                  return GardenWorldView(
                    layout: GardenLayout(),
                    seeds: {'pine': count},
                    careRemainders: {'pine': remainder},
                    decorations: const [],
                    motionEnabled: motion,
                    companionAutomaticBehavior: false,
                    onMove: (_, __) async {},
                    onMemory: (_) {},
                    onPlant: () {},
                    onDecorate: () {},
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final item = find.byKey(const ValueKey('world-item-seed:pine'));
      final viewer = tester.widget<InteractiveViewer>(
        find.byType(InteractiveViewer),
      );
      final cameraScale = viewer.transformationController!.value
          .getMaxScaleOnAxis();
      Offset root() {
        final size = tester.getSize(item);
        return tester.getTopLeft(item) +
            Offset(size.width / 2, (size.height - 22) * .9) * cameraScale;
      }

      final plantedRoot = root();
      final firstWidth = tester.getSize(item).width;
      update(() => remainder = 1);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      final middleWidth = tester.getSize(item).width;
      expect(middleWidth, greaterThan(firstWidth));
      expect((root() - plantedRoot).distance, lessThan(.01));
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.getSize(item).width, greaterThan(middleWidth));
      update(() {
        count = 10;
        remainder = 0;
        motion = false;
      });
      await tester.pumpAndSettle();
      expect(tester.getSize(item).width, greaterThan(firstWidth * 2));
      expect((root() - plantedRoot).distance, lessThan(.01));
      expect(tester.takeException(), isNull);
      if (Platform.environment['GARDEN_GROWTH_CAPTURE'] == '1') {
        await tester.runAsync(() async {
          final context = tester.element(find.byType(GardenWorldView));
          await Future.wait([
            for (final asset in [
              'world_day',
              'world_night',
              'plants',
              'cat_idle_front',
              'cat_idle_front_blink',
            ])
              precacheImage(
                AssetImage('assets/living_garden/$asset.webp'),
                context,
              ),
          ]);
        });
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          final image =
              await (capture.currentContext!.findRenderObject()
                      as RenderRepaintBoundary)
                  .toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(
            '/tmp/mindnyang-grown-tree.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
