import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/theme.dart';
import 'package:flutter_app/services/cat_care_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/models/coloring_stroke.dart';
import 'package:flutter_app/services/brush_coloring_store.dart';
import 'package:flutter_app/services/garden_bell.dart';
import 'package:flutter_app/screens/coloring_healing_screen.dart';

Future<void> waitForPainting(WidgetTester tester) async {
  final deadline = DateTime.now().add(const Duration(seconds: 45));
  while (find
      .byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == '색칠 준비 완료',
      )
      .evaluate()
      .isEmpty) {
    if (DateTime.now().isAfter(deadline)) {
      fail(
        'Coloring did not complete image decoding, segmentation and persisted stroke loading',
      );
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    '48 distinct colors, three widths and account-isolated persisted strokes',
    () async {
      expect(coloringPalette.toSet().length, 48);
      final a = BrushColoringStore('a'), b = BrushColoringStore('b');
      final stroke = ColoringStroke(0xffff0000, 4, false, [
        const Offset(25, 35),
      ]);
      await a.save([stroke]);
      expect((await a.load()).single.width, 4);
      expect(await b.load(), isEmpty);
      await a.save([stroke], finished: true);
      await a.save([]);
      expect((await a.load(finished: true)).length, 1);
      expect(await a.load(), isEmpty);
      expect(
        () => ColoringStroke.fromJson({
          'color': 1,
          'width': 4,
          'erase': false,
          'points': [
            [double.nan, 1],
          ],
        }),
        throwsFormatException,
      );
    },
  );
  test('eraser clears paint and preserves white paper', () async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    BrushColoringPainter(null, [
      ColoringStroke(0xffff0000, 40, false, [
        const Offset(100, 100),
        const Offset(200, 100),
      ]),
      ColoringStroke(0, 16, true, [const Offset(150, 100)]),
    ]).paint(canvas, const Size(1024, 1536));
    final picture = recorder.endRecording();
    final image = await picture.toImage(1024, 1536);
    final data = (await image.toByteData())!.buffer.asUint8List();
    expect(data.sublist((100 * 1024 + 150) * 4, (100 * 1024 + 150) * 4 + 4), [
      255,
      255,
      255,
      255,
    ]);
    expect(data.sublist((100 * 1024 + 110) * 4, (100 * 1024 + 110) * 4 + 4), [
      255,
      0,
      0,
      255,
    ]);
    image.dispose();
    picture.dispose();
  });
  test(
    'notice baseline, duplicates, concurrent reads and sound choice',
    () async {
      expect(await GardenBell.newNotices('a', ['old']), false);
      expect(await GardenBell.newNotices('a', ['old']), false);
      final results = await Future.wait([
        GardenBell.newNotices('a', ['old', 'new']),
        GardenBell.newNotices('a', ['old', 'new']),
      ]);
      expect(results.where((v) => v).length, 1);
      expect(await GardenBell.newNotices('b', ['new']), false);
      expect(await GardenBell.enabled(), true);
      await GardenBell.setEnabled(false);
      expect(await GardenBell.enabled(), false);
      final now = DateTime(2030);
      expect(GardenBell.takeSound(now), true);
      expect(GardenBell.takeSound(now.add(const Duration(seconds: 1))), false);
      expect(GardenBell.takeSound(now.add(const Duration(seconds: 4))), true);
    },
  );
  for (final size in [const Size(320, 640), const Size(390, 844)]) {
    testWidgets('brush drawing and undo redo persist at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      CatCareService.setCurrentUser('brush-artist');
      const dest = String.fromEnvironment('BRUSH_CAPTURE');
      if (dest.isNotEmpty) {
        for (final name in ['GowunDodum', 'GamjaFlower']) {
          final font = FontLoader(name)
            ..addFont(rootBundle.load('assets/fonts/$name-Regular.ttf'));
          await tester.runAsync(font.load);
        }
        final font = FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
        await tester.runAsync(font.load);
      }
      final capture = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          home: RepaintBoundary(
            key: capture,
            child: const ColoringHealingScreen(),
          ),
        ),
      );
      await waitForPainting(tester);
      expect(tester.takeException(), isNull);
      final canvas = find.byKey(const Key('brush-canvas'));
      final rect = tester.getRect(canvas);
      await tester.dragFrom(
        Offset(rect.left + rect.width * .50, rect.top + rect.height * .58),
        const Offset(20, 15),
      );
      await tester.pumpAndSettle();
      final store = BrushColoringStore('brush-artist');
      expect((await store.load()).length, 1);
      expect((await store.load()).first.width, 16);
      await tester.scrollUntilVisible(
        find.text('아주 얇은 붓'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('아주 얇은 붓'));
      await tester.pump();
      expect(
        tester
            .widget<ChoiceChip>(
              find.ancestor(
                of: find.text('아주 얇은 붓'),
                matching: find.byType(ChoiceChip),
              ),
            )
            .selected,
        true,
      );
      await tester.scrollUntilVisible(
        find.text('되돌리기'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('되돌리기'));
      await tester.pumpAndSettle();
      expect(await store.load(), isEmpty);
      await tester.tap(find.text('다시하기'));
      await tester.pumpAndSettle();
      expect((await store.load()).length, 1);
      await tester.ensureVisible(find.text('작품 완성 · 보관하기'));
      await tester.tap(find.text('작품 완성 · 보관하기'));
      await tester.pumpAndSettle();
      expect((await store.load(finished: true)).length, 1);
      expect(tester.takeException(), isNull);
      if (dest.isNotEmpty && size.width == 390) {
        ScaffoldMessenger.of(
          tester.element(find.byType(ColoringHealingScreen)),
        ).hideCurrentSnackBar();
        await tester.drag(
          find.byKey(const Key('paint-tools')),
          const Offset(0, 1800),
        );
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          final image =
              await (capture.currentContext!.findRenderObject()
                      as RenderRepaintBoundary)
                  .toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(
            dest.replaceFirst('.png', '-finished.png'),
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.tap(find.byTooltip('전체화면'));
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.byKey(const Key('coloring-viewport'))),
        Offset.zero & size,
      );
      tester.view.physicalSize = const Size(844, 390);
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.byKey(const Key('coloring-viewport'))),
        const Rect.fromLTWH(0, 0, 844, 390),
      );
      await tester.tap(find.byTooltip('색칠 도구 접기'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('paint-tools')), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('전체화면 닫기'));
      await tester.pumpAndSettle();
      expect(find.text('감정고양이 색칠'), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      final persisted = <String, Object>{
        for (final key in prefs.getKeys()) key: prefs.get(key)!,
      };
      await tester.pumpWidget(const SizedBox());
      SharedPreferences.setMockInitialValues(persisted);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: appTheme,
          home: RepaintBoundary(
            key: capture,
            child: const ColoringHealingScreen(),
          ),
        ),
      );
      await waitForPainting(tester);
      final restored =
          tester
                  .widget<CustomPaint>(find.byKey(const Key('brush-canvas')))
                  .painter
              as BrushColoringPainter;
      expect(restored.strokes.length, 1);
      expect(
        (await BrushColoringStore('brush-artist').load()).single.toJson(),
        (await store.load(finished: true)).single.toJson(),
      );
      if (dest.isNotEmpty && size.width == 390) {
        await tester.runAsync(() async {
          final image =
              await (capture.currentContext!.findRenderObject()
                      as RenderRepaintBoundary)
                  .toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(dest).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.pumpWidget(const SizedBox());
      CatCareService.setCurrentUser('');
    });
  }
}
