import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/mongi/integration/mongi_garden_store.dart';
import 'package:flutter_app/services/draft_service.dart';
import 'package:flutter_app/services/unified_emotion_summary_service.dart';
import 'package:flutter_app/widgets/emotion_comic_book.dart';
import 'package:flutter_app/theme.dart';

UnifiedEmotionRecord record(int id, int day, {String emotion = 'calm'}) =>
    UnifiedEmotionRecord(
      id: '$id',
      source: EmotionRecordSource.gardenDiary,
      date: DateTime(2026, 10, day),
      hasTime: false,
      emotionId: emotion,
      label: emotion == 'calm' ? '평온' : '기쁨',
      emoji: emotion == 'calm' ? '😌' : '😊',
      color: Colors.green,
      background: const Color(0xFFE1EFE4),
      note: '오늘은 잠깐 나를 위한 시간을 가졌어요.',
    );
Future<void> flush(WidgetTester tester) async {
  bool done = false;
  Object? error;
  DraftTextController.flushAll().then(
    (_) => done = true,
    onError: (Object e) {
      error = e;
      done = true;
    },
  );
  for (var i = 0; i < 100 && !done; i++) {
    await tester.pump();
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    });
  }
  expect(error, isNull);
  expect(done, isTrue);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;
  setUpAll(() async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({
      MongiGardenStore.storageKey: jsonEncode(MongiGardenData(seedTokens: 1)
          .plant('pine', now: DateTime(2026, 10, 5)).toJson()),
    });
    dir = await Directory.systemTemp.createTemp('comic53');
    Hive.init(dir.path);
    await DraftService.box();
    await MongiGardenStore.instance.reload();
  });
  tearDownAll(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });
  test('pagination preserves every record and chronology', () {
    final records = List.generate(30, (i) => record(i, 1 + i % 29));
    final pages = comicPages(records.reversed.toList());
    expect(
      pages.expand((p) => p).map((r) => r.id).toSet(),
      records.map((r) => r.id).toSet(),
    );
    expect(pages.every((p) => p.length <= 4), isTrue);
    final all = pages.expand((p) => p).toList();
    for (var i = 1; i < all.length; i++) {
      expect(all[i].date.isBefore(all[i - 1].date), isFalse);
    }
    expect(comicPages([]), isEmpty);
  });
  testWidgets(
    'navigation, originals, encrypted title, small screens and empty state',
    (tester) async {
      for (final size in [const Size(390, 844), const Size(320, 640)]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        const dest = String.fromEnvironment('COMIC_CAPTURE_DIR');
        if (dest.isNotEmpty) {
          for (final name in ['GowunDodum', 'GamjaFlower']) {
            final f = FontLoader(name)
              ..addFont(rootBundle.load('assets/fonts/$name-Regular.ttf'));
            await tester.runAsync(f.load);
          }
          final f = FontLoader('MaterialIcons')
            ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
          await tester.runAsync(f.load);
        }
        final records = [
          record(1, 5),
          record(2, 6),
          record(3, 7, emotion: 'joy'),
          record(4, 9),
          record(5, 14, emotion: 'joy'),
        ];
        final key = GlobalKey();
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: appTheme,
            home: Scaffold(
              body: SingleChildScrollView(
                child: RepaintBoundary(
                  key: key,
                  child: Container(
                    color: const Color(0xFFFFF4E9),
                    padding: const EdgeInsets.all(12),
                    child: EmotionComicBook(
                      key: ValueKey('book-${size.width}'),
                      summary: UnifiedEmotionPeriod(records),
                      start: DateTime(2026, 10),
                      end: DateTime(2026, 10, 29),
                      monthly: true,
                      detailed: true,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 150));
        });
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.textContaining('정원 이야기를 불러오지 못했어요.'), findsNothing);
        Future<void> capture(String name) async {
          if (dest.isNotEmpty && size.width == 390) {
            await tester.runAsync(() async {
              for (final element in find.byType(Image).evaluate().toList()) {
                await precacheImage((element.widget as Image).image, element);
              }
            });
            await tester.pump();
            await tester.runAsync(() async {
              final img =
                  await (key.currentContext!.findRenderObject()
                          as RenderRepaintBoundary)
                      .toImage(pixelRatio: 2);
              final bytes = await img.toByteData(
                format: ui.ImageByteFormat.png,
              );
              await File(
                '$dest/$name',
              ).writeAsBytes(bytes!.buffer.asUint8List());
              img.dispose();
            });
          }
        }

        await capture('Mindnyang-Comic-v53.png');
        await tester.tap(find.text('10/5 · 평온'));
        await tester.pumpAndSettle();
        expect(find.text('오늘은 잠깐 나를 위한 시간을 가졌어요.'), findsWidgets);
        await tester.tap(find.text('닫기'));
        await tester.pumpAndSettle();
        for (var page = 0; page < 2; page++) {
          await tester.ensureVisible(find.byTooltip('다음 장'));
          await tester.tap(find.byTooltip('다음 장'));
          await tester.pumpAndSettle();
        }
        expect(find.text('내 정원이 자란 날'), findsOneWidget);
        await capture('79-comic-saved-planting.png');
        await tester.ensureVisible(find.text('마지막 장 · 마음 모아 보기'));
        await tester.tap(find.text('마지막 장 · 마음 모아 보기'));
        await tester.pumpAndSettle();
        expect(find.text('5일 동안, 5개의 마음을 남겼어요'), findsOneWidget);
        expect(find.text('3번 만났어요'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.byType(TextField));
        await tester.enterText(find.byType(TextField), '작은 용기를 모은 달');
        await flush(tester);
        await tester.pumpAndSettle();
        await capture('Mindnyang-Comic-Summary-v53.png');
        await tester.pumpWidget(const SizedBox());
        await flush(tester);
        final box = await tester.runAsync(DraftService.box);
        expect(
          box!.get('comic_title_month_${DateTime(2026, 10).toIso8601String()}'),
          '작은 용기를 모은 달',
        );
      }
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.8)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: EmotionComicBook(
                  summary: const UnifiedEmotionPeriod([]),
                  start: DateTime(2026, 10, 26),
                  end: DateTime(2026, 10, 29),
                  monthly: false,
                  detailed: false,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('첫 이야기를 기다려요'), findsOneWidget);
      expect(find.text('0일 동안, 0개의 마음을 남겼어요'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await flush(tester);
      bool closed = false;
      Hive.close().then((_) => closed = true);
      for (var i = 0; i < 100 && !closed; i++) {
        await tester.pump();
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        });
      }
      expect(closed, isTrue);
    },
  );
}
