import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/mongi/models/garden_layout.dart';
import 'package:flutter_app/mongi/widgets/garden_world_view.dart';
import 'package:flutter_app/theme.dart';

void main() {
  testWidgets('mature garden renders at phone widths with real app artwork', (
    tester,
  ) async {
    await tester.runAsync(() async {
      for (final entry in {
        'GowunDodum': 'assets/fonts/GowunDodum-Regular.ttf',
        'GamjaFlower': 'assets/fonts/GamjaFlower-Regular.ttf',
        'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
      }.entries) {
        await (FontLoader(
          entry.key,
        )..addFont(rootBundle.load(entry.value))).load();
      }
    });
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final width in [360.0, 390.0]) {
      tester.view.physicalSize = Size(width, 780);
      final capture = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          home: RepaintBoundary(
            key: capture,
            child: Scaffold(
              appBar: AppBar(title: const Text('나의 정원')),
              body: Padding(
                padding: const EdgeInsets.all(12),
                child: GardenWorldView(
                  layout: GardenLayout(spaces: 3),
                  seeds: const {
                    'pine': 10,
                    'cherry': 10,
                    'maple': 10,
                    'love': 4,
                    'peace': 5,
                  },
                  decorations: const ['bench'],
                  motionEnabled: false,
                  onMove: (_, __) async {},
                  onMemory: (_) {},
                  onPlant: () {},
                  onDecorate: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.runAsync(() async {
        final context = capture.currentContext!;
        for (final asset in [
          'assets/living_garden/day.webp',
          'assets/living_garden/night.webp',
          'assets/living_garden/bench.webp',
        ]) {
          // Images used by the widget are also awaited below via normal frames.
          if ((await AssetManifest.loadFromAssetBundle(
            rootBundle,
          )).listAssets().contains(asset)) {
            if (!context.mounted) return;
            await precacheImage(AssetImage(asset), context);
          }
        }
      });
      for (var frame = 0; frame < 8; frame++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 40)),
        );
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final boundary =
            capture.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await boundary.toImage();
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        await Directory('verification/refinement').create(recursive: true);
        await File(
          'verification/refinement/garden-${width.toInt()}.png',
        ).writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
