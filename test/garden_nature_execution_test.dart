import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/widgets/companion_cat_mesh.dart';
import 'package:audioplayers_platform_interface/audioplayers_platform_interface.dart';
import 'package:flutter_app/mongi/widgets/garden_ambient.dart';
import 'package:flutter_app/mongi/widgets/garden_world_view.dart';
import 'package:flutter_app/mongi/models/garden_layout.dart';
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
      'original nature ${night ? 'night' : 'day'} animates and pauses without writes',
      (t) async {
        t.view.physicalSize = const Size(390, 700);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        final key = GlobalKey();
        var writes = 0;
        const output = String.fromEnvironment('GARDEN_NATURE_CAPTURE');
        final name = night ? 'night' : 'day';
        await t.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RepaintBoundary(
                key: key,
                child: GardenWorldView(
                  originalScenery: true,
                  nightOverride: night,
                  readOnly: true,
                  cultivationMode: true,
                  fillViewport: true,
                  motionEnabled: true,
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
          ),
        );
        await t.runAsync(
          () => precacheImage(
            AssetImage('assets/living_garden/cultivation_$name.png'),
            key.currentContext!,
          ),
        );
        await t.pump();
        if (output.isNotEmpty) {
          await t.runAsync(() async {
            final deadline = DateTime.now().add(const Duration(seconds: 30));
            // This fixture is read-only without a host identity, so it uses
            // the original mesh cat rather than a visitor's selected coat.
            while (find.byWidgetPredicate((w) => w is CustomPaint &&
                w.painter is CompanionCatMeshPainter &&
                (w.painter as CompanionCatMeshPainter).closed != null)
                .evaluate().isEmpty) {
              if (DateTime.now().isAfter(deadline)) fail('Companion art did not decode');
              await Future<void>.delayed(const Duration(milliseconds: 5));
              await t.pump();
            }
          });
        }
        final atmosphere = t
            .widgetList<CustomPaint>(find.byType(CustomPaint))
            .map((w) => w.painter)
            .whereType<GardenAtmosphere>()
            .single;
        final clock = atmosphere.animation! as AnimationController;
        expect(clock.isAnimating, true);
        expect(atmosphere.night, night);
        expect(atmosphere.openLawn, isTrue);
        final start = clock.value;
        for (var i = 0; i < (output.isEmpty ? 2 : 75); i++) {
          await t.pump(const Duration(microseconds: 66667));
          if (output.isNotEmpty) {
            await t.runAsync(() async {
              final image =
                  await (key.currentContext!.findRenderObject()
                          as RenderRepaintBoundary)
                      .toImage();
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              final target = File(
                '$output/nature-$name-frames/frame-${i.toString().padLeft(5, '0')}.png',
              );
              await target.parent.create(recursive: true);
              await target.writeAsBytes(bytes!.buffer.asUint8List());
              if (i == 0)
                await File(
                  '$output/nature-$name.png',
                ).writeAsBytes(bytes.buffer.asUint8List());
              image.dispose();
            });
          }
        }
        expect(clock.value, isNot(start));
        t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await t.pump();
        expect(clock.isAnimating, false);
        final paused = clock.value;
        await t.pump(const Duration(seconds: 2));
        expect(clock.value, paused);
        t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await t.pump();
        expect(clock.isAnimating, true);
        expect(writes, 0);
        if (output.isNotEmpty)
          await t.runAsync(
            () => File('$output/nature-$name-execution.json').writeAsString(
              jsonEncode({
                'night': night,
                'frames': 75,
                'fps': 15,
                'writes': writes,
                'backgroundPauseVerified': true,
                'environment':
                    'Production Flutter widget rendering, synthetic data and virtual time; not Android/emulator recording',
              }),
            ),
          );
        await t.pumpWidget(const SizedBox());
        expect(t.takeException(), isNull);
      },
    );
  }
}
