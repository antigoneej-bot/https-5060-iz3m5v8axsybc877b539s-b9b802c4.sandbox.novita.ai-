// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'package:flame/flame.dart';
import 'package:flutter_app/mongi/screens/runner_game_screen.dart';
import 'package:flutter_app/mongi/screens/onboarding_screen.dart';
import 'package:flutter_app/mongi/screens/season_pass_screen.dart';
import 'package:flutter_app/mongi/screens/mood_trend_screen.dart';
import 'package:flutter_app/mongi/models/emotion.dart';
import 'package:flutter_app/mongi/services/sound_manager.dart';
import 'package:flutter_app/screens/cat_shop_screen.dart';
import 'package:flutter_app/screens/emotion_statistics_screen.dart';
import 'package:audioplayers_platform_interface/audioplayers_platform_interface.dart';
import '../test/support/fake_audioplayers_platform.dart';
import '../test/support/fake_global_audioplayers_platform.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_app/providers/app_state_provider.dart';
import 'package:flutter_app/providers/cat_care_provider.dart';
import 'package:flutter_app/screens/data_safety_screen.dart';
import 'package:flutter_app/screens/my_screen.dart';
// Render actual widgets at phone widths. No production records are touched.
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/theme.dart';
import 'package:flutter_app/mongi/providers/garden_provider.dart';
import 'package:flutter_app/mongi/l10n/gen/app_localizations.dart';
import 'package:flutter_app/mongi/screens/shop_screen.dart';
import 'package:flutter_app/mongi/screens/settings_screen.dart';
import 'package:flutter_app/mongi/screens/diary_screen.dart';
import 'package:flutter_app/mongi/screens/mind_report_screen.dart';
import 'package:flutter_app/mongi/screens/emotion_calendar_screen.dart';
import 'package:flutter_app/mongi/screens/emotion_collection_screen.dart';
import 'package:flutter_app/mongi/screens/growth_milestone_screen.dart';
import 'package:flutter_app/screens/about_app_screen.dart';
import 'package:flutter_app/screens/meditation_library_screen.dart';

void main() {
  testWidgets('phone design review', (tester) async {
    AudioplayersPlatformInterface.instance = FakeAudioplayersPlatform();
    GlobalAudioplayersPlatformInterface.instance =
        FakeGlobalAudioplayersPlatform();
    SharedPreferences.setMockInitialValues({});
    Flame.images.prefix = 'assets/mongi/images/';
    SoundManager.instance.setEnabled(false);
    await tester.runAsync(() async {
      for (final entry in {
        'GowunDodum': 'assets/fonts/GowunDodum-Regular.ttf',
        'GamjaFlower': 'assets/fonts/GamjaFlower-Regular.ttf',
        'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
        'Poppins': 'assets/fonts/Poppins-ExtraBold.ttf',
      }.entries) {
        await (FontLoader(
          entry.key,
        )..addFont(rootBundle.load(entry.value))).load();
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
    Hive.init(Directory.systemTemp.createTempSync('design-review-').path);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async => null,
    );
    final garden = GardenProvider();
    await tester.runAsync(() async {
      try {
        await garden.init();
      } on MissingPluginException {
        /* native store unavailable in widget runner */
      }
    });
    final app = AppStateProvider();
    final care = CatCareProvider();
    addTearDown(app.dispose);
    addTearDown(care.dispose);
    addTearDown(garden.dispose);
    final pages = <String, Widget>{
      'mongi-runner': RunnerGameScreen(
        emotions: [Emotion.all.first],
        targetName: null,
        practice: true,
      ),
      'mongi-onboarding': const OnboardingScreen(isReplay: true),
      'mongi-season': const SeasonPassScreen(),
      'mongi-trends': const MoodTrendScreen(),
      'garden-statistics': const EmotionStatisticsScreen(),
      'garden-shop': const Scaffold(
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: CatShopScreen(),
        ),
      ),
      'mongi-shop': const ShopScreen(),
      'mongi-settings': const SettingsScreen(),
      'mongi-diary': const DiaryScreen(),
      'mongi-report': const MindReportScreen(),
      'mongi-calendar': const EmotionCalendarScreen(),
      'mongi-collection': const EmotionCollectionScreen(),
      'mongi-growth': const GrowthMilestoneScreen(),
      'garden-backup': const DataSafetyScreen(),
      'garden-my': const Scaffold(
        body: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: MyScreen(),
        ),
      ),
      'garden-about': const AboutAppScreen(),
      'garden-meditation': const Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: MeditationLibraryScreen(),
          ),
        ),
      ),
    };
    final issues = <String>[];
    for (final size in ['phone', 'narrow', 'large']) {
      tester.view.physicalSize = Size(size == 'narrow' ? 320 : 390, 844);
      for (final page in pages.entries) {
        final key = GlobalKey();
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: garden),
              ChangeNotifierProvider.value(value: app),
              ChangeNotifierProvider.value(value: care),
            ],
            child: MaterialApp(
              theme: appTheme,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: const Locale('ko'),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(size == 'large' ? 1.3 : 1),
                ),
                child: child!,
              ),
              home: RepaintBoundary(key: key, child: page.value),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 200));
        });
        await tester.pump();
        final errors = <Object>[];
        Object? error;
        while ((error = tester.takeException()) != null) {
          errors.add(error!);
        }
        if (errors.isNotEmpty) {
          issues.add('${page.key} $size: $errors');
          debugPrint('DESIGN ISSUE ${page.key} $size: $errors');
        }
        await tester.runAsync(() async {
          final b =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final img = await b.toImage(pixelRatio: 1);
          final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
          await Directory('verification/design27').create(recursive: true);
          await File(
            'verification/design27/${page.key}-$size.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          img.dispose();
        });
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }
    }
    debugPrint('All 51 layouts rendered; checking errors.');
    expect(issues, isEmpty);
  });
}
