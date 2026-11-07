import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers_platform_interface/audioplayers_platform_interface.dart';
import 'package:flutter_app/models/companion_journey.dart';
import 'package:flutter_app/models/companion_reminder.dart';
import 'package:flutter_app/providers/cat_care_provider.dart';
import 'package:flutter_app/services/notification_service.dart';
import 'package:flutter_app/services/cat_care_service.dart';
import 'package:flutter_app/services/companion_journey_store.dart';
import 'package:flutter_app/services/sound_service.dart';
import 'package:flutter_app/widgets/companion_care_panel.dart';
import 'package:flutter_app/widgets/companion_reminder_settings.dart';
import 'support/fake_audioplayers_platform.dart';
import 'support/fake_global_audioplayers_platform.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  const timezoneChannel = MethodChannel('garden/device_timezone');
  late NotificationService service;
  bool permission = true;
  setUpAll(() {
    AudioplayersPlatformInterface.instance = FakeAudioplayersPlatform();
    GlobalAudioplayersPlatformInterface.instance =
        FakeGlobalAudioplayersPlatform();
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CatCareService.setCurrentUser('local_user');
    SoundService().sfxEnabled = false;
    permission = true;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      timezoneChannel,
      (_) async => {'id': 'Asia/Seoul', 'offsetSeconds': 32400},
    );
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      if (call.method == 'initialize') return true;
      if (call.method == 'requestNotificationsPermission') return permission;
      if (call.method == 'getNotificationAppLaunchDetails') {
        return {'notificationLaunchedApp': false};
      }
      return null;
    });
    service = NotificationService.forTesting(now: DateTime.now);
  });
  tearDown(() {
    service.dispose();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      timezoneChannel,
      null,
    );
  });

  Future<void> ready(WidgetTester tester, Finder button) async {
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (tester.widget<OutlinedButton>(button).onPressed != null) return;
    }
    fail('Care action did not finish saving');
  }

  Future<void> capture(WidgetTester tester, GlobalKey key, String name) async {
    const destination = String.fromEnvironment('COMPANION_CAPTURE_DIR');
    if (destination.isEmpty) return;
    await tester.runAsync(() async {
      final image =
          await (key.currentContext!.findRenderObject()
                  as RenderRepaintBoundary)
              .toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory(destination).create(recursive: true);
      await File(
        '$destination/$name.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  for (final width in [360.0, 390.0]) {
    testWidgets(
      'notification invitation feeds and plays with same cat at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final font = FontLoader('GowunDodum')
          ..addFont(rootBundle.load('assets/fonts/GowunDodum-Regular.ttf'));
        final icons = FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
        await tester.runAsync(() async {
          await font.load();
          await icons.load();
        });
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'local_user_companion_journey_v1',
          const CompanionJourney(automaticBehavior: false).encode(),
        );
        final care = CatCareProvider(notifications: service)
          ..companionName = '햇살';
        final boundary = GlobalKey();
        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: care,
            child: RepaintBoundary(
              key: boundary,
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: ThemeData(
                  fontFamily: 'GowunDodum',
                  scaffoldBackgroundColor: const Color(0xFFFAF7EF),
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: const Color(0xFF50785C),
                  ),
                ),
                home: Scaffold(
                  appBar: AppBar(title: const Text('고양이 돌보기')),
                  body: const SingleChildScrollView(
                    padding: EdgeInsets.all(20),
                    child: CompanionCarePanel(invitation: CompanionMoment.feed),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          for (final asset in [
            'cat_idle_front.webp',
            'cat_idle_front_blink.webp',
          ]) {
            await precacheImage(
              AssetImage('assets/living_garden/$asset'),
              tester.element(find.byType(CompanionCarePanel)),
            );
          }
        });
        await tester.pump();
        expect(
          care.journey.growthDays,
          0,
        ); // Opening an invitation never performs care.
        expect(
          find.text(CompanionInvitation.message(CompanionMoment.feed)),
          findsOneWidget,
        );
        final feed = find.byKey(const ValueKey('companion-feed'));
        await tester.ensureVisible(feed);
        await tester.pump();
        await tester.tap(feed);
        await ready(tester, feed);
        expect(care.state.fedToday, true);
        expect(
          care.journey.didToday(CompanionMoment.feed, DateTime.now()),
          true,
        );
        await tester.pump(const Duration(milliseconds: 650));
        await capture(tester, boundary, 'feeding-${width.toInt()}');
        final play = find.byKey(const ValueKey('companion-play'));
        await tester.ensureVisible(play);
        await tester.pump();
        await tester.tap(play);
        await ready(tester, play);
        expect(
          care.journey.didToday(CompanionMoment.play, DateTime.now()),
          true,
        );
        expect(care.journey.growthDays, 1);
        await tester.pump(const Duration(milliseconds: 650));
        await capture(tester, boundary, 'playing-${width.toInt()}');
        final reopened = await CompanionJourneyStore.load('local_user');
        expect(
          reopened.firstMoments.keys,
          containsAll([CompanionMoment.feed, CompanionMoment.play]),
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        care.dispose();
      },
    );
  }

  testWidgets(
    'settings opt in, edit numeric time, persist and disable at large text',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(
                size: Size(360, 800),
                textScaler: TextScaler.linear(2),
              ),
              child: SingleChildScrollView(
                child: CompanionReminderSettingsTile(service: service),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final toggle = find.byKey(const Key('companion-reminder-toggle'));
      expect(tester.widget<SwitchListTile>(toggle).value, false);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect((await service.getCompanionReminderSettings()).enabled, true);
      final time = find.byKey(const Key('companion-reminder-time'));
      await tester.ensureVisible(time);
      await tester.tap(time);
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNWidgets(2));
      await tester.enterText(find.byType(TextField).first, '20');
      await tester.enterText(find.byType(TextField).last, '15');
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      final saved = await service.getCompanionReminderSettings();
      expect([saved.hour, saved.minute], [20, 15]);
      expect(find.text('알림 시간  20:15'), findsOneWidget);
      await tester.ensureVisible(toggle);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect((await service.getCompanionReminderSettings()).enabled, false);
      expect(find.byKey(const Key('companion-reminder-time')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'permission refusal leaves switch off with understandable error',
    (tester) async {
      permission = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: CompanionReminderSettingsTile(service: service)),
        ),
      );
      await tester.pumpAndSettle();
      final toggle = find.byKey(const Key('companion-reminder-toggle'));
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(tester.widget<SwitchListTile>(toggle).value, false);
      expect(find.textContaining('기기 알림 권한을 확인'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
