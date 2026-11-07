import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/mongi/integration/mature_tree_memories.dart';
import 'package:flutter_app/mongi/integration/plant_memory.dart';

import 'package:flutter_app/theme.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final size in [(360.0, 1.0), (390.0, 1.0), (360.0, 2.0)]) {
    testWidgets(
      'mature memories readable at ${size.$1}px and ${size.$2} text scale',
      (tester) async {
        tester.view.physicalSize = Size(size.$1, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final key = GlobalKey();
        final chosen = <String>[];
        if (Platform.environment['MINDNYANG_REVIEW_DIR'] != null) {
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
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(size.$2)),
              child: child!,
            ),
            home: RepaintBoundary(
              key: key,
              child: Scaffold(
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: MatureTreeMemories(
                    entries: const [PlantMemoryEntry(id:'one', on:'2026-10-24', note:'오늘은 한 걸음 천천히 쉬어 갔어요.'), PlantMemoryEntry(id:'two', on:'2026-09-24', note:'내 마음을 처음으로 남긴 날이에요.')],
                    anniversaryOn:'2026-09-25', now:DateTime(2026,10,24),
                    onWrite:()=>chosen.add('write'),onHistory:()=>chosen.add('history'), onMonth:(_)=>chosen.add('month'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(chosen, isEmpty);
        expect(tester.takeException(), isNull);
        final directory = Platform.environment['MINDNYANG_REVIEW_DIR'];
        if (directory != null) {
          await tester.runAsync(() async {
            final render =
                key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final image = await render.toImage();
            final data = await image.toByteData(format: ui.ImageByteFormat.png);
            await Directory(directory).create(recursive: true);
            await File(
              '$directory/mature-${size.$1.toInt()}-${size.$2}.png',
            ).writeAsBytes(data!.buffer.asUint8List());
            image.dispose();
          });
        }
        await tester.ensureVisible(find.text('오늘의 추억 더하기'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('오늘의 추억 더하기')); await tester.pump();
        expect(chosen, ['write']);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
