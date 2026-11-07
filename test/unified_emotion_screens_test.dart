import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter_app/l10n/app_language.dart';
import 'package:flutter_app/screens/all_features_screen.dart';
import 'package:flutter_app/screens/cat_bond_screen.dart';
import 'package:flutter_app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/models/letter_entry.dart';
import 'package:flutter_app/mongi/l10n/gen/app_localizations.dart';
import 'package:flutter_app/mongi/providers/garden_provider.dart';
import 'package:flutter_app/mongi/screens/mind_report_screen.dart';
import 'package:flutter_app/providers/app_state_provider.dart';
import 'package:flutter_app/screens/emotion_statistics_screen.dart';
import 'package:flutter_app/services/subscription_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Garden extends GardenProvider {
  bool fail = false;
  bool ready = false;
  List<Map<String, dynamic>> loadedEntries = [];
  @override
  bool get isInitialized => ready;
  @override
  bool get hasGratitudeEntryToday => false;
  @override
  Future<void> ensureInitialized() async {
    if (fail) throw StateError('local read failed');
    diaryEntries = loadedEntries;
    ready = true;
    notifyListeners();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const secureChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  setUpAll(() async {
    for (final font in {
      'GowunDodum': 'assets/fonts/GowunDodum-Regular.ttf',
      'GamjaFlower': 'assets/fonts/GamjaFlower-Regular.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
    }.entries) {
      await (FontLoader(font.key)..addFont(rootBundle.load(font.value))).load();
    }
    if (Platform.isWindows && Platform.environment['WINDIR'] != null) {
      final emoji = File(
        Platform.environment['WINDIR']! + '/Fonts/seguiemj.ttf',
      );
      if (await emoji.exists()) {
        await (FontLoader(
          'Segoe UI Emoji',
        )..addFont(emoji.readAsBytes().then(ByteData.sublistView))).load();
      }
    }
    // The screen flow does not edit reflection drafts. Model an unavailable
    // keystore explicitly so these navigation tests never start filesystem I/O.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureChannel, (_) async {
          throw PlatformException(
            code: 'keystore-unavailable-in-navigation-test',
          );
        });
  });
  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureChannel, null);
  });
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppLanguage.instance.select('ko');
    GoogleFonts.config.allowRuntimeFetching = false;
    SubscriptionService.debugIsPremiumOverride = false;
  });
  tearDown(() => SubscriptionService.debugIsPremiumOverride = null);

  Future<void> open(
    WidgetTester tester,
    Widget screen,
    _Garden garden, {
    double width = 390,
    double height = 844,
    double scale = 1,
    String language = 'ko',
  }) async {
    final now = DateTime.now();
    final app = AppStateProvider()
      ..history = [
        LetterEntry(
          id: 'first',
          catId: 'sad',
          date: now,
          letterText: '내 편지 내용',
        ),
        LetterEntry(
          id: 'second',
          catId: 'anxious',
          date: now,
          letterText: '또 다른 기록',
        ),
      ];
    addTearDown(app.dispose);
    addTearDown(garden.dispose);
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await AppLanguage.instance.select(language);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppStateProvider>.value(value: app),
          ChangeNotifierProvider<GardenProvider>.value(value: garden),
        ],
        child: MaterialApp(
          theme: appTheme,
          locale: Locale(language),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
              disableAnimations: true,
            ),
            child: RepaintBoundary(
              key: const Key('streamline-capture'),
              child: child!,
            ),
          ),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: screen,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
  }

  Future<void> capture(WidgetTester tester, String name) async {
    final dir = Platform.environment['UI_APPROVED_REVIEW_DIR'];
    if (dir == null) return;
    await tester.runAsync(() async {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const Key('streamline-capture')),
      );
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory(dir).create(recursive: true);
      await File('$dir/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  for (final language in ['ko', 'en']) {
    for (final size in [
      const Size(320, 640),
      const Size(390, 844),
      const Size(844, 390),
    ]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets(
          'free monthly view keeps detailed journal access $language $size $scale',
          (tester) async {
            final garden = _Garden();
            await open(
              tester,
              const EmotionStatisticsScreen(initialMonthly: true),
              garden,
              width: size.width,
              height: size.height,
              scale: scale,
              language: language,
            );
            await tester.pumpAndSettle();
            final entry = find.byKey(const Key('open-garden-report-details'));
            await tester.ensureVisible(entry);
            expect(entry.hitTestable(), findsOneWidget);
            await tester.tap(entry);
            await tester.pumpAndSettle();
            expect(
              tester
                  .widget<MindReportScreen>(find.byType(MindReportScreen))
                  .detailsFirst,
              isTrue,
            );
            expect(
              tester
                  .widget<ExpansionTile>(
                    find.byKey(const Key('report-garden-details')),
                  )
                  .initiallyExpanded,
              isTrue,
            );
            expect(find.text(tr('이번 달 함께 모은 마음')), findsNothing);
            await capture(
              tester,
              'report-$language-' + size.width.toInt().toString() + '-$scale',
            );
            final overview = find.byKey(const Key('report-period-overview'));
            await tester.ensureVisible(overview);
            await tester.tap(find.text(tr('주간·월간 요약 다시 보기')));
            await tester.pumpAndSettle();
            expect(
              find.text(language == 'en' ? '1 day · 2 entries' : '1일 · 2개의 기록'),
              findsNWidgets(2),
            );
            expect(
              find.text(tr('편지 {0}개 · 정원 일기 {1}개', [2, 0])),
              findsNWidgets(2),
            );
            if (language == 'en') {
              expect(
                find.byWidgetPredicate(
                  (w) => w is Text && RegExp(r'[가-힣]').hasMatch(w.data ?? ''),
                ),
                findsNothing,
              );
            }
            await capture(
              tester,
              'report-summary-$language-' +
                  size.width.toInt().toString() +
                  '-$scale',
            );
            await tester.tap(find.byIcon(Icons.arrow_back));
            await tester.pumpAndSettle();
            expect(find.byType(MindReportScreen), findsNothing);
            expect(
              find.byKey(const Key('open-garden-report-details')),
              findsOneWidget,
            );
            expect(
              tester
                  .widget<EmotionStatisticsScreen>(
                    find.byType(EmotionStatisticsScreen),
                  )
                  .initialMonthly,
              isTrue,
            );
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pump();
          },
        );
      }
    }
  }

  testWidgets(
    'old report search opens statistics, cat codes remain separate from invitations',
    (tester) async {
      await open(tester, const AllFeaturesScreen(), _Garden());
      await tester.pumpAndSettle();
      expect(find.text('마음 리포트'), findsNothing);
      expect(find.text('36개 기능'), findsOneWidget);
      Future<void> search(String value) async {
        await tester.ensureVisible(find.byType(TextField));
        await tester.enterText(find.byType(TextField), value);
        await tester.pumpAndSettle();
      }

      await search('마음 리포트');
      expect(find.text('1개 기능'), findsOneWidget);
      await tester.ensureVisible(find.text('감정 통계'));
      await tester.tap(find.text('감정 통계'));
      await tester.pumpAndSettle();
      expect(find.byType(EmotionStatisticsScreen), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await search('묘연');
      expect(find.text('1개 기능'), findsOneWidget);
      await tester.ensureVisible(find.text('고양이 코드 비교'));
      await tester.tap(find.text('고양이 코드 비교'));
      // This screen keeps blinking. Wait for the route's completion condition,
      // rather than waiting for unrelated repeating animations to stop.
      ModalRoute<dynamic>? codeRoute;
      for (var frame = 0; frame < 60; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        final screen = find.byType(CatBondScreen, skipOffstage: false);
        if (screen.evaluate().isEmpty) continue;
        codeRoute = ModalRoute.of(tester.element(screen));
        if (codeRoute!.animation!.isCompleted) break;
      }
      expect(codeRoute?.animation?.status, AnimationStatus.completed);
      expect(find.byType(CatBondScreen), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();
      await search('예약');
      expect(find.text('1개 기능'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'report and statistics share letters plus diary, with inspectable source and intensity',
    (tester) async {
      final now = DateTime.now();
      final garden = _Garden()
        ..loadedEntries = [
          {
            'date': '${now.year}-${now.month}-${now.day}',
            'emotionType': 'sadness',
            'note': '정원에 남긴 글',
            'intensity': 4,
          },
        ];
      await open(tester, const MindReportScreen(), garden);
      expect(find.text('1일 · 3개의 기록'), findsNWidgets(2));
      expect(find.text('편지 2개 · 정원 일기 1개'), findsNWidgets(2));
      await tester.tap(find.text('이번 주 함께 모은 마음'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.byType(EmotionStatisticsScreen), findsOneWidget);
      await tester.tap(find.text('통계 자세히'));
      await tester.pumpAndSettle();
      expect(find.text('3번'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('함께 모은 기록'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('편지 2개 · 정원 일기 1개'), findsOneWidget);
      expect(find.text('직접 남긴 감정 강도 평균 4.0/5'), findsOneWidget);
      final date = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == '${now.month}/${now.day}, 3개 기록',
      );
      // The day lives inside a non-scrolling GridView. Scroll its outer
      // list with a real gesture before tapping, rather than its inner viewport.
      await tester.drag(find.byType(ListView).first, const Offset(0, -400));
      await tester.pump();
      expect(date.hitTestable(), findsOneWidget);
      await tester.tap(date);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.textContaining('슬픔 · 정원 일기 · 시간 미기록'), findsOneWidget);
      expect(find.textContaining('정원에 남긴 글\n직접 남긴 강도 4/5'), findsOneWidget);
      expect(find.text('내 편지 내용'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets(
    'failed diary load preserves letters and offers working retry at 360 px',
    (tester) async {
      final garden = _Garden()..fail = true;
      await open(tester, const EmotionStatisticsScreen(), garden, width: 360);
      await tester.tap(find.text('통계 자세히'));
      await tester.pumpAndSettle();
      expect(find.text('2번'), findsOneWidget);
      final retry = find.text('정원 일기를 불러오지 못했어요. 다시 시도');
      await tester.scrollUntilVisible(
        retry,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(retry, findsOneWidget);
      garden.fail = false;
      await tester.tap(retry);
      await tester.pump();
      expect(retry, findsNothing);
      expect(find.text('편지 2개 · 정원 일기 0개'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
}
