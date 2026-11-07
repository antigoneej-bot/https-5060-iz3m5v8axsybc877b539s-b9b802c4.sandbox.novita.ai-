import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/l10n/app_language.dart';
import 'package:flutter_app/services/cloud_service.dart';
import 'package:flutter_app/mongi/l10n/gen/app_localizations.dart';
import 'package:flutter_app/screens/all_features_screen.dart';
import 'package:flutter_app/screens/app_tutorial_screen.dart';
import 'package:flutter_app/screens/onboarding_flow_screen.dart';
import 'package:flutter_app/data/shadow_cats_data.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/providers/app_state_provider.dart';
import 'package:flutter_app/screens/data_safety_screen.dart';
import 'package:flutter_app/screens/mind_review_screen.dart';
import 'package:flutter_app/widgets/restore_complete_dialog.dart';
import 'package:flutter_app/widgets/mood_picker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final font in {
      'GowunDodum': 'assets/fonts/GowunDodum-Regular.ttf',
      'GamjaFlower': 'assets/fonts/GamjaFlower-Regular.ttf',
      'Poppins': 'assets/fonts/Poppins-ExtraBold.ttf',
      'NanumPenScript': 'assets/fonts/NanumPenScript-Regular.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
    }.entries) {
      await (FontLoader(font.key)..addFont(rootBundle.load(font.value))).load();
    }
  });
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppLanguage.instance.select('en');
  });
  Future<void> mount(WidgetTester t, Widget page, double scale) async {
    t.view.physicalSize = Size(scale == 1 ? 390 : 320, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: ThemeData(fontFamily: 'GowunDodum'),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: true,
            textScaler: TextScaler.linear(scale),
          ),
          child: child!,
        ),
        home: RepaintBoundary(key: const Key('capture86'), child: page),
      ),
    );
    await t.pump(const Duration(milliseconds: 300));
  }

  Future<void> capture(WidgetTester t, String name) async {
    final dir = Platform.environment['REVIEW86'];
    if (dir == null) return;
    await t.runAsync(() async {
      final boundary = t.renderObject<RenderRepaintBoundary>(
        find.byKey(const Key('capture86')),
      );
      final im = await boundary.toImage(pixelRatio: 2);
      final data = await im.toByteData(format: ui.ImageByteFormat.png);
      await Directory(dir).create(recursive: true);
      await File('$dir/$name.png').writeAsBytes(data!.buffer.asUint8List());
      im.dispose();
    });
  }

  for (final scale in [1.0, 2.0]) {
    for (final page in ['directory', 'backup', 'review']) {
      testWidgets('English $page fits text scale $scale', (t) async {
        await mount(
          t,
          page == 'directory'
              ? const AllFeaturesScreen()
              : page == 'backup'
              ? const DataSafetyScreen()
              : MindReviewScreen(onOpenRecords: () {}),
          scale,
        );
        expect(t.takeException(), isNull);
        for (final text in t.widgetList<Text>(find.byType(Text))) {
          expect(
            RegExp('[가-힣]').hasMatch(text.data ?? ''),
            isFalse,
            reason: text.data,
          );
        }
        await capture(t, '$page-en-${scale.toInt()}');
        if (page == 'directory') {
          await t.scrollUntilVisible(
            find.byType(TextField),
            200,
            scrollable: find.byType(Scrollable).first,
          );
          await t.enterText(find.byType(TextField), 'BACKUP');
          await t.pump(const Duration(milliseconds: 300));
          await t.scrollUntilVisible(
            find.text('Features: 1'),
            200,
            scrollable: find.byType(Scrollable).first,
          );
          expect(find.text('Features: 1'), findsOneWidget);
          expect(t.takeException(), isNull);
        }
        await t.pumpWidget(const SizedBox());
      });
    }
  }
  testWidgets('English onboarding keeps draft text unchanged', (t) async {
    await mount(
      t,
      ChangeNotifierProvider(
        create: (_) => AppStateProvider(),
        child: OnboardingFlowScreen(cat: shadowCats.first),
      ),
      1,
    );
    await t.enterText(find.byType(TextField), '내 기록 stays mine {0}');
    await t.pump();
    final field = t.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, '내 기록 stays mine {0}');
    expect(find.text('Skip writing for now'), findsOneWidget);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });
  testWidgets('English guide explains five pages and unavailable meditation', (
    t,
  ) async {
    await mount(
      t,
      const Scaffold(body: SingleChildScrollView(child: AppTutorialScreen())),
      1,
    );
    expect(
      find.text('Home · My garden · Neighbors · Unwind · Journal'),
      findsOneWidget,
    );
    await t.scrollUntilVisible(
      find.text('Rest & recharge'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await t.tap(find.text('Rest & recharge'));
    await t.pump(const Duration(milliseconds: 400));
    await t.pump(const Duration(milliseconds: 400));
    expect(
      find.textContaining('not available to purchase or play yet'),
      findsOneWidget,
    );
    expect(t.takeException(), isNull);
  });
  testWidgets('English restore preserves retry and non-dismissible state', (
    t,
  ) async {
    var calls = 0;
    await mount(
      t,
      Scaffold(
        body: RestoreCompleteDialog(
          title: 'Restore complete',
          added: 3,
          reload: () async {
            calls++;
            throw StateError('offline');
          },
        ),
      ),
      1,
    );
    expect(find.textContaining('Added 3 items.'), findsOneWidget);
    expect(t.widget<PopScope>(find.byType(PopScope)).canPop, isFalse);
    await t.tap(find.text('Open restored garden'));
    await t.pumpAndSettle();
    expect(find.text('Try opening again'), findsOneWidget);
    expect(find.textContaining('Your entries were restored'), findsOneWidget);
    await t.tap(find.text('Try opening again'));
    await t.pumpAndSettle();
    expect(calls, 2);
  });
  test('cloud errors translate presentation without changing codes', () async {
    for (final code in [
      'garden-owner-mismatch',
      'account-changed',
      'subscription-required',
      'invalid-invite-code',
      'unknown-error',
    ]) {
      final error = CloudException(code);
      expect(error.code, code);
      expect(RegExp('[가-힣]').hasMatch(error.toString()), isFalse);
      await AppLanguage.instance.select('ko');
      expect(RegExp('[가-힣]').hasMatch(error.toString()), isTrue);
      await AppLanguage.instance.select('en');
    }
  });
  test('mood labels change without changing saved emoji identifiers', () async {
    expect(moodLabelFor('🌧️'), 'Low');
    await AppLanguage.instance.select('ko');
    expect(moodLabelFor('🌧️'), '우울함');
    expect(kMoodOptions.map((e) => e.emoji), contains('🌧️'));
  });
}
