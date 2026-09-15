import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/mongi/integration/garden_moments_card.dart';
import 'package:flutter_app/mongi/integration/garden_moments.dart';
import 'package:flutter_app/mongi/integration/mongi_garden_data.dart';
import 'package:flutter_app/theme.dart';

void main() {
  testWidgets('garden story layouts, locks and reader navigation', (
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
    for (final scenario in ['normal', 'narrow', 'large-text', 'locked']) {
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
            child: GardenMomentsScreen(
              data: scenario == 'locked' ? MongiGardenData() : MongiGardenData(stage: 2, seeds: {'pine': 1}),
              catCount: scenario == 'locked' ? 0 : 1,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: scenario);
      expect(find.byIcon(Icons.lock_outline), findsNWidgets(scenario == 'locked' ? 3 : 0));
      await tester.runAsync(() async {
        final img =
            await (key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage();
        final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
        await Directory('verification/garden-moments').create(recursive: true);
        await File(
          'verification/garden-moments/$scenario.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        img.dispose();
      });
      await tester.tap(find.text(gardenMoments.first.title));
      await tester.pumpAndSettle();
      expect(find.byType(GardenMomentReader), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pageBack();
      await tester.pumpAndSettle();

    }
    await tester.pumpWidget(const SizedBox());
  });
}
