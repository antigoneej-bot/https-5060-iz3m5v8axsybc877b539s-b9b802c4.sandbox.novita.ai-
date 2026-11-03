import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/mongi/models/garden_layout.dart';
import 'package:flutter_app/mongi/widgets/garden_basic_item_art.dart';
import 'package:flutter_app/mongi/widgets/garden_world_view.dart';
import 'package:flutter_app/theme.dart';
import 'package:audioplayers_platform_interface/audioplayers_platform_interface.dart';
import 'support/fake_audioplayers_platform.dart';
import 'support/fake_global_audioplayers_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    AudioplayersPlatformInterface.instance = FakeAudioplayersPlatform();
    GlobalAudioplayersPlatformInterface.instance =
        FakeGlobalAudioplayersPlatform();
  });
  for (final night in [false, true]) {
    testWidgets(
      'eleven additions render in the actual saved garden at night=$night without writes',
      (t) async {
        t.view.physicalSize = const Size(1080, 480);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        var writes = 0;
        final boundary = GlobalKey();
        final layout = GardenLayout(spaces: 3);
        await t.pumpWidget(
          MaterialApp(
            theme: appTheme,
            home: Scaffold(
              body: RepaintBoundary(
                key: boundary,
                child: GardenWorldView(
                  layout: layout,
                  seeds: const {'pine': 7},
                  decorations: GardenBasicItemArt.ids.toList(),
                  readOnly: true,
                  motionEnabled: false,
                  companionAutomaticBehavior: false,
                  fillViewport: true,
                  overviewRequested: true,
                  nightOverride: night,
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
          ),
        );
        await t.pumpAndSettle();
        for (final id in GardenBasicItemArt.ids) {
          expect(find.byKey(ValueKey('world-item-decor:$id')), findsOneWidget);
        }
        expect(find.byType(GardenBasicItemArt), findsNWidgets(11));
        expect(writes, 0);
        expect(t.takeException(), isNull);
        const dest = String.fromEnvironment('USABILITY_CAPTURE');
        if (dest.isNotEmpty) {
          await t.runAsync(() async {
            for (final image in [
              'assets/living_garden/cultivation_day.png',
              'assets/living_garden/cultivation_night.png',
              'assets/living_garden/plants.webp',
            ]) {
              await precacheImage(AssetImage(image), boundary.currentContext!);
            }
          });
          await t.pump();
          await t.runAsync(() async {
            final image =
                await (boundary.currentContext!.findRenderObject()!
                        as RenderRepaintBoundary)
                    .toImage();
            final data = await image.toByteData(format: ui.ImageByteFormat.png);
            await File(
              '$dest/26-new-garden-items-${night ? 'night' : 'day'}.png',
            ).writeAsBytes(data!.buffer.asUint8List());
            image.dispose();
          });
        }
        await t.pumpWidget(const SizedBox());
      },
    );
  }
}
