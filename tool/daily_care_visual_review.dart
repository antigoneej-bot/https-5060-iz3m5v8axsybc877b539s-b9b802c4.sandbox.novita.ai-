import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/widgets/daily_care_card.dart';
import 'package:flutter_app/mongi/integration/mongi_garden_store.dart';
import 'package:flutter_app/theme.dart';

void main() {
  testWidgets('daily care layouts and actions', (tester) async {
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
    for (final scenario in ['normal', 'narrow', 'large-text', 'rewarded']) {
      final data = MongiGardenData(
        careDays: scenario == 'rewarded'
            ? {MongiGardenData.dayKey(DateTime.now())}
            : {},
      );
      SharedPreferences.setMockInitialValues({
        MongiGardenStore.storageKey: jsonEncode(data.toJson()),
      });
      final tapped = <String>[];
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
                child: DailyCareCard(
                  key: ValueKey(scenario),
                  onWrite: () => tapped.add('write'),
                  onRest: () => tapped.add('rest'),
                  onRun: () => tapped.add('run'),
                  onGarden: () => tapped.add('garden'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: scenario);
      if (scenario == 'rewarded')
        expect(find.text('오늘의 공통 돌봄 보상을 받았어요 🌱'), findsOneWidget);
      await tester.runAsync(() async {
        final img =
            await (key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage();
        final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
        await Directory('verification/daily-care').create(recursive: true);
        await File(
          'verification/daily-care/$scenario.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        img.dispose();
      });
      for (final label in ['편지 쓰기', '조용히 쉬기', '몽이와 달리기', '내 정원으로 가기']) {
        await tester.ensureVisible(find.text(label));
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
      }
      expect(tapped, ['write', 'rest', 'run', 'garden']);
      expect(tester.takeException(), isNull, reason: '$scenario actions');
    }
    await tester.pumpWidget(const SizedBox());
  });
}
