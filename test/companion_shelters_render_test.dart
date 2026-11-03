import 'dart:io';
import 'package:audioplayers_platform_interface/audioplayers_platform_interface.dart';
import 'support/fake_audioplayers_platform.dart';
import 'support/fake_global_audioplayers_platform.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_app/theme.dart';
import 'package:flutter_app/models/cat_visit.dart';
import 'package:flutter_app/models/companion_coat.dart';
import 'package:flutter_app/widgets/companion_loaf_art.dart';
import 'package:flutter_app/mongi/models/garden_layout.dart';
import 'package:flutter_app/mongi/widgets/garden_world_view.dart';

void main() {
  setUpAll(() async {
    AudioplayersPlatformInterface.instance = FakeAudioplayersPlatform();
    GlobalAudioplayersPlatformInterface.instance =
        FakeGlobalAudioplayersPlatform();
    GoogleFonts.config.allowRuntimeFetching = false;
    for (final name in ['GowunDodum', 'GamjaFlower']) {
      await (FontLoader(
        name,
      )..addFont(rootBundle.load('assets/fonts/$name-Regular.ttf'))).load();
    }
  });
  for (final coat in CompanionCoat.values) {
    testWidgets(
      '${coat.name} preserves coat and wakes from all three shelters with reduced motion',
      (t) async {
        t.view.physicalSize = const Size(844, 390);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        final shot = GlobalKey();
        var request = 0;
        var growth = 6;
        Future<void> show(String? target) async {
          await t.pumpWidget(
            MaterialApp(
              theme: appTheme,
              home: RepaintBoundary(
                key: shot,
                child: Scaffold(
                  body: GardenWorldView(
                    originalScenery: true,
                    layout: GardenLayout(spaces: 3),
                    seeds: {'pine': growth},
                    nightOverride: false,
                    decorations: const ['cat_cushion', 'cat_basket'],
                    cultivationMode: true,
                    fillViewport: true,
                    motionEnabled: false,
                    companionName: '테스트 고양이',
                    companionAutomaticBehavior: false,
                    visitingHost: VisitingCat(
                      coat: coat,
                      stage: 4,
                      name: '테스트 고양이',
                    ),
                    requestedRestItem: target,
                    restRequest: request,
                    onMove: (_, __) async {},
                    onMemory: (_) {},
                    onPlant: () {},
                    onDecorate: () {},
                  ),
                ),
              ),
            ),
          );
          await t.pumpAndSettle();
        }

        await show(null);
        for (final entry in {
          'decor:cat_cushion': '방석',
          'decor:cat_basket': '바구니',
          'seed:pine': '나무 그늘',
        }.entries) {
          request++;
          await show(entry.key);
          final cat = find.byKey(const Key('garden-companion'));
          expect(
            t.widget<Semantics>(cat).properties.label,
            contains('${entry.value}에서 일어나기'),
          );
          expect(
            t
                .widget<GardenWorldView>(find.byType(GardenWorldView))
                .visitingHost!
                .coat,
            coat,
          );
          const out = String.fromEnvironment('USABILITY_CAPTURE');
          if (out.isNotEmpty) {
            ScaffoldMessenger.of(t.element(find.byType(GardenWorldView))).removeCurrentSnackBar();
            await t.pump();
            await t.runAsync(() async {
              final deadline = DateTime.now().add(const Duration(seconds: 30));
              while (find.byWidgetPredicate((w) => w is CustomPaint &&
                  w.painter is CompanionLoafPainter).evaluate().isEmpty) {
                if (DateTime.now().isAfter(deadline)) fail('Resting cat art did not decode');
                await Future<void>.delayed(const Duration(milliseconds: 5));
                await t.pump();
              }
              await precacheImage(
                const AssetImage('assets/living_garden/cultivation_day.png'),
                shot.currentContext!,
              );
              await precacheImage(
                AssetImage(
                  'assets/living_garden/companion_motion_${coat.name}.webp',
                ),
                shot.currentContext!,
              );
            });
            await t.pump();
            await t.runAsync(() async {
              final image =
                  await (shot.currentContext!.findRenderObject()
                          as RenderRepaintBoundary)
                      .toImage();
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              await File(
                '$out/79-shelter-${coat.name}-${entry.key.replaceAll(':', '-')}.png',
              ).writeAsBytes(bytes!.buffer.asUint8List());
              image.dispose();
            });
          }
          if (entry.key == 'seed:pine') {
            growth = 1;
            await show(entry.key);
          } else {
            await t.tap(cat);
            await t.pumpAndSettle();
          }
          expect(
            t.widget<Semantics>(cat).properties.label,
            isNot(contains('일어나기')),
          );
        }
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
      },
    );
  }
}
