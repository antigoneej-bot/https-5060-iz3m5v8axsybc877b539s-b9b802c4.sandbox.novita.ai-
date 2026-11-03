import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/data/shadow_cats_data.dart';
import 'package:flutter_app/models/letter_entry.dart';
import 'package:flutter_app/mongi/providers/garden_provider.dart';
import 'package:flutter_app/providers/app_state_provider.dart';
import 'package:flutter_app/screens/emotion_archive_screen.dart';
import 'package:flutter_app/theme.dart';

class _ArchiveGarden extends GardenProvider {
  @override
  Future<void> ensureInitialized() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const secure = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          secure,
          (_) async => throw PlatformException(code: 'no-user-keystore'),
        );
    for (final name in ['GowunDodum', 'GamjaFlower']) {
      await (FontLoader(
        name,
      )..addFont(rootBundle.load('assets/fonts/$name-Regular.ttf'))).load();
    }
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  tearDownAll(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secure, null),
  );
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final size in [
    const Size(320, 640),
    const Size(390, 844),
    const Size(844, 390),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'archive reads originals, filters periods and keeps controls $size text $scale',
        (t) async {
          t.view.physicalSize = size;
          t.view.devicePixelRatio = 1;
          addTearDown(t.view.reset);
          final now = DateTime.now(),
              day = DateTime(
                DateTime.now().year,
                DateTime.now().month,
                DateTime.now().day,
                12,
              );
          final app = AppStateProvider()
            ..history = [
              LetterEntry(
                id: 'saved',
                catId: 'angry',
                date: day,
                letterText: '원문-편지',
              ),
              LetterEntry(
                id: 'legacy',
                catId: 'unknown-legacy',
                date: day.subtract(const Duration(hours: 2)),
                letterText: '원문-옛감정',
              ),
              LetterEntry(
                id: 'older',
                catId: 'sad',
                date: DateTime(now.year, now.month - 1, 1),
                letterText: '원문-지난달',
              ),
            ];
          final garden = _ArchiveGarden()
            ..diaryEntries = [
              {
                'date': '${now.year}-${now.month}-${now.day}',
                'emotionType': 'calm',
                'note': '원문-정원',
              },
            ];
          addTearDown(app.dispose);
          addTearDown(garden.dispose);
          final lettersBefore = app.history
              .map((e) => (e.id, e.catId, e.date, e.letterText))
              .toList();
          final diaryBefore = jsonEncode(garden.diaryEntries),
              boundary = GlobalKey();
          await t.pumpWidget(
            MultiProvider(
              providers: [
                ChangeNotifierProvider<AppStateProvider>.value(value: app),
                ChangeNotifierProvider<GardenProvider>.value(value: garden),
              ],
              child: MaterialApp(
                theme: appTheme,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                home: RepaintBoundary(
                  key: boundary,
                  child: const EmotionArchiveScreen(),
                ),
              ),
            ),
          );
          await t.pumpAndSettle();
          expect(t.takeException(), isNull);
          Future<void> capture(String name) async {
            const dest = String.fromEnvironment('USABILITY_CAPTURE');
            if (dest.isEmpty || size != const Size(390, 844) || scale != 1)
              return;
            await t.runAsync(() async {
              for (final id in ['angry', 'serene', 'sad']) {
                await precacheImage(
                  AssetImage(
                    shadowCats.firstWhere((c) => c.id == id).imageAsset,
                  ),
                  boundary.currentContext!,
                );
              }
            });
            await t.pump();
            await t.runAsync(() async {
              final image =
                  await (boundary.currentContext!.findRenderObject()!
                          as RenderRepaintBoundary)
                      .toImage();
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              await File(
                '$dest/$name.png',
              ).writeAsBytes(bytes!.buffer.asUint8List());
              image.dispose();
            });
          }

          await capture('20-emotion-calendar');
          final today = find.byKey(ValueKey('emotion-calendar-day-${day.day}'));
          final calendarScroll = find
              .descendant(
                of: find.byType(ListView).first,
                matching: find.byType(Scrollable),
              )
              .first;
          // The calendar grid has its own non-scrolling viewport. Scroll the
          // enclosing list with a real gesture rather than revealing only the
          // already-visible part of that inner viewport.
          for (
            var i = 0;
            i < 10 && today.hitTestable().evaluate().isEmpty;
            i++
          ) {
            final target = t.getRect(today),
                viewport = t.getRect(calendarScroll);
            await t.drag(
              calendarScroll,
              Offset(0, target.center.dy > viewport.center.dy ? -100 : 100),
            );
            await t.pumpAndSettle();
          }
          expect(today.hitTestable(), findsOneWidget);
          await t.tap(today);
          await t.pumpAndSettle();
          final detailList = find.byKey(const Key('emotion-day-record-list'));
          final detailScroll = find
              .descendant(of: detailList, matching: find.byType(Scrollable))
              .first;
          await t.scrollUntilVisible(
            find.text('원문-편지'),
            180,
            scrollable: detailScroll,
          );
          expect(find.text('원문-편지'), findsOneWidget);
          await t.scrollUntilVisible(
            find.text('원문-정원'),
            180,
            scrollable: detailScroll,
          );
          expect(find.text('원문-정원'), findsOneWidget);
          await t.binding.handlePopRoute();
          await t.pumpAndSettle();
          await t.tap(find.text('고양이 카드 모아보기'));
          await t.pumpAndSettle();
          int count() => t
              .widget<GridView>(find.byType(GridView))
              .childrenDelegate
              .estimatedChildCount!;
          expect(count(), 3);
          await t.tap(find.text('전체 기간'));
          await t.pumpAndSettle();
          expect(count(), 4);
          await capture('21-emotion-cards');
          await t.tap(find.byType(DropdownButton<String>));
          await t.pumpAndSettle();
          await t.tap(find.text('분노 · 편지').last);
          await t.pumpAndSettle();
          expect(count(), 1);
          await t.tap(find.byTooltip('이전 달'));
          await t.pumpAndSettle();
          expect(find.text('아직 보관된 감정 카드가 없어요.'), findsOneWidget);
          await capture('22-emotion-empty');
          expect(
            app.history
                .map((e) => (e.id, e.catId, e.date, e.letterText))
                .toList(),
            lettersBefore,
          );
          expect(jsonEncode(garden.diaryEntries), diaryBefore);
          expect(t.takeException(), isNull);
          await t.pumpWidget(const SizedBox());
        },
      );
    }
  }
}
