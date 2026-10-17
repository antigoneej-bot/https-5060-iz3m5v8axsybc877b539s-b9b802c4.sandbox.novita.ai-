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
  setUpAll(() {
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
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
    SubscriptionService.debugIsPremiumOverride = false;
  });
  tearDown(() => SubscriptionService.debugIsPremiumOverride = null);

  Future<void> open(
    WidgetTester tester,
    Widget screen,
    _Garden garden, {
    double width = 390,
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
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppStateProvider>.value(value: app),
          ChangeNotifierProvider<GardenProvider>.value(value: garden),
        ],
        child: MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: screen,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
  }

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
