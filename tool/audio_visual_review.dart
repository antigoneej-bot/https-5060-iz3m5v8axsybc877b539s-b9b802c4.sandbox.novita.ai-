import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/widgets/meditation_audio_player.dart';
import '../test/meditation_audio_test.dart' as audio_checks;
import 'package:flutter_app/theme.dart';

void main() {
  audio_checks.main();
  testWidgets('audio controls at narrow and enlarged text sizes', (
    tester,
  ) async {
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
      await (FontLoader('NotoColorEmoji')..addFont(
            File(
              '/tmp/NotoColorEmoji.ttf',
            ).readAsBytes().then(ByteData.sublistView),
          ))
          .load();
    });
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final scenario in ['normal', 'narrow', 'large-text']) {
      final key = GlobalKey();
      tester.view.physicalSize = Size(scenario == 'narrow' ? 320 : 390, 844);
      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scenario == 'large-text' ? 1.5 : 1),
            ),
            child: child!,
          ),
          home: RepaintBoundary(
            key: key,
            child: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: MeditationAudioPlayer(
                  key: ValueKey(scenario),
                  guideKey: 'sleepMeditation',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: scenario);
      await tester.runAsync(() async {
        final img =
            await (key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage();
        final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
        await Directory('verification/audio-controls').create(recursive: true);
        await File(
          'verification/audio-controls/$scenario.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        img.dispose();
      });
    }
    await tester.pumpWidget(const SizedBox());
  });
}
