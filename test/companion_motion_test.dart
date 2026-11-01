import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/models/companion_coat.dart';
import 'package:flutter_app/models/companion_motion.dart';
import 'package:flutter_app/models/companion_behavior.dart';
import 'package:flutter_app/widgets/companion_motion_art.dart';
import 'package:flutter_app/widgets/companion_coat_art.dart';
import 'package:flutter_app/widgets/companion_coat_preview.dart';
import 'package:flutter_app/widgets/companion_presence.dart';
import 'package:flutter_app/providers/cat_care_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('six walking drawings alternate real leg poses and reverse left', () {
    expect(
      [for (var i = 0; i < 8; i++) CompanionMotionPose.walk(i).frame].toSet(),
      {6, 7, 8, 9, 10, 11},
    );
    expect(CompanionMotionPose.walk(0, faceLeft: true).mirror, true);
    expect(CompanionMotionPose.walk(8).frame, 6);
  });
  test(
    'blink closes, smile changes mouth, tail cycles, reduced motion freezes',
    () {
      expect(CompanionMotionPose.idle(0, eyeClosure: .3).frame, 1);
      expect(CompanionMotionPose.idle(0, eyeClosure: 1).frame, 2);
      expect(CompanionMotionPose.idle(0, smile: true).frame, 3);
      final swings = [
        for (var i = 0; i < 60; i++) CompanionMotionPose.idle(i / 10).tailSwing,
      ];
      expect(swings.reduce((a, b) => a > b ? a : b), greaterThan(.99));
      expect(swings.reduce((a, b) => a < b ? a : b), lessThan(-.99));
      for (final paw in [const Offset(.5, .98), const Offset(.9, .98)]) {
        expect(CompanionMotionPainter.tailWarp(paw, .4, 1), paw);
      }
      expect(CompanionMotionPose.idle(2, animate: false, smile: true).frame, 0);
      expect(
        CompanionMotionPose.idle(2, animate: false, resting: true).frame,
        2,
      );
    },
  );
  testWidgets('every coat has twelve real assets with stable ground contact', (
    tester,
  ) async {
    for (final coat in CompanionCoat.values) {
      final atlas = (await tester.runAsync(
        () => CompanionSpriteAtlas.load(coat),
      ))!;
      expect(atlas.frames.length, 12);
      for (var i = 0; i < 12; i++) {
        final f = atlas.frames[i];
        expect(f.source.left, greaterThanOrEqualTo(0));
        expect(f.source.right, lessThanOrEqualTo(atlas.image.width));
        final rect = CompanionMotionPainter.destination(
          atlas,
          i,
          const Size(220, 220),
        );
        final scale = rect.height / f.source.height;
        expect(
          rect.top + (f.footY - f.source.top) * scale,
          closeTo(220 * CompanionMotionPainter.baseline, 1e-9),
        );
        expect(rect.left, greaterThanOrEqualTo(-.01));
        expect(rect.right, lessThanOrEqualTo(220.01));
      }
    }
  });
  testWidgets(
    'idle and care interaction actually render different sprite poses',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final care = CatCareProvider();
      await tester.runAsync(() async {
        await care.selectCoat(CompanionCoat.calico);
        await CompanionSpriteAtlas.load(CompanionCoat.calico);
      });
      Future<void> show({
        bool enabled = true,
        bool reduced = false,
        CompanionInteraction? interaction,
      }) => tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: care,
          child: MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(disableAnimations: reduced),
              child: Scaffold(
                body: SizedBox(
                  width: 220,
                  height: 220,
                  child: CompanionPresence(
                    enabled: enabled,
                    interaction: interaction,
                    interactionProgress: .5,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      CompanionMotionPose pose() => tester
          .widget<CompanionCoatArt>(find.byType(CompanionCoatArt))
          .motion!;
      await show();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1750));
      expect(pose().frame, 2);
      await show(interaction: CompanionInteraction.petting);
      await tester.pump();
      expect(pose().frame, 3);
      await show(reduced: true);
      await tester.pump();
      expect(pose().frame, 0);
      await tester.pump(const Duration(seconds: 8));
      expect(pose().frame, 0);
      await tester.pumpWidget(const SizedBox());
      care.dispose();
    },
  );
  testWidgets(
    'preview pauses when app backgrounds and resumes without changing cat',
    (tester) async {
      await tester.runAsync(
        () => CompanionSpriteAtlas.load(CompanionCoat.white),
      );
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 220,
              height: 220,
              child: CompanionCoatPreview(coat: CompanionCoat.white),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(
        tester
            .widget<CompanionCoatArt>(find.byType(CompanionCoatArt))
            .motion!
            .frame,
        0,
      );
      await tester.pump(const Duration(seconds: 4));
      expect(
        tester
            .widget<CompanionCoatArt>(find.byType(CompanionCoatArt))
            .motion!
            .frame,
        0,
      );
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('render six cats motion review using the actual app painter', (
    tester,
  ) async {
    const out = String.fromEnvironment('CAT_MOTION_CAPTURE');
    if (out.isEmpty) return;
    tester.view.physicalSize = const Size(900, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final font in ['GowunDodum', 'GamjaFlower']) {
      final loader = FontLoader(font)
        ..addFont(rootBundle.load('assets/fonts/$font-Regular.ttf'));
      await tester.runAsync(loader.load);
    }
    await tester.runAsync(() async {
      for (final c in CompanionCoat.values) {
        await CompanionSpriteAtlas.load(c);
      }
      await Directory(out).create(recursive: true);
    });
    final key = GlobalKey();
    final time = ValueNotifier<double>(0);
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(fontFamily: 'GowunDodum'),
          home: Scaffold(
            backgroundColor: const Color(0xFFFFF8EF),
            body: ValueListenableBuilder<double>(
              valueListenable: time,
              builder: (context, t, _) {
                final walking = t >= 6;
                final status = walking
                    ? '다리로 걷기'
                    : t < 1.8
                    ? '꼬리 살랑살랑'
                    : t < 2.4
                    ? '눈 깜빡이기'
                    : t < 3.8
                    ? '기분 좋게 웃기'
                    : '꼬리 살랑살랑';
                return Column(
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      '마음냥 정원 · 6종 고양이',
                      style: TextStyle(fontFamily: 'GamjaFlower', fontSize: 34),
                    ),
                    Text(status, style: const TextStyle(fontSize: 19)),
                    const SizedBox(height: 15),
                    Wrap(
                      spacing: 12,
                      runSpacing: 14,
                      children: [
                        for (final coat in CompanionCoat.values)
                          Container(
                            width: 278,
                            height: 290,
                            decoration: BoxDecoration(
                              color: Color(coat.color),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Column(
                              children: [
                                SizedBox(
                                  width: 240,
                                  height: 240,
                                  child: CompanionCoatArt(
                                    coat: coat,
                                    motion: walking
                                        ? CompanionMotionPose.walk(
                                            ((t - 6) * 8).floor(),
                                            faceLeft: t >= 9,
                                          )
                                        : CompanionMotionPose.idle(
                                            t,
                                            eyeClosure: t >= 1.8 && t < 2.4
                                                ? (1 - (t - 2.1).abs() / .3)
                                                      .clamp(0.0, 1.0)
                                                : 0,
                                            smile: t >= 2.4 && t < 3.8,
                                          ),
                                  ),
                                ),
                                Text(
                                  coat.label,
                                  style: const TextStyle(
                                    fontFamily: 'GamjaFlower',
                                    fontSize: 23,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
    for (var frame = 0; frame < 144; frame++) {
      time.value = frame / 12;
      await tester.pump();
      await tester.runAsync(() async {
        final image =
            await (key.currentContext!.findRenderObject()
                    as RenderRepaintBoundary)
                .toImage();
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '$out/${frame.toString().padLeft(4, '0')}.png',
        ).writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
    }
    await tester.pumpWidget(const SizedBox());
    time.dispose();
    expect(tester.takeException(), isNull);
  });
}
