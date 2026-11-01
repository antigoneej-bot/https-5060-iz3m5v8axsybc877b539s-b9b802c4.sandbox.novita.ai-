import 'package:flutter_app/models/cat_accessory.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/models/companion_journey.dart';
import 'package:flutter_app/models/companion_reminder.dart';
import 'package:flutter_app/services/notification_service.dart';
import 'package:flutter_app/services/cat_care_service.dart';
import 'package:flutter_app/services/companion_journey_store.dart';
import 'package:flutter_app/services/sound_service.dart';
import 'package:flutter_app/services/storage_service.dart';
import 'package:flutter_app/providers/cat_care_provider.dart';
import 'package:audioplayers_platform_interface/audioplayers_platform_interface.dart';
import 'support/fake_audioplayers_platform.dart';
import 'support/fake_global_audioplayers_platform.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    AudioplayersPlatformInterface.instance = FakeAudioplayersPlatform();
    GlobalAudioplayersPlatformInterface.instance =
        FakeGlobalAudioplayersPlatform();
  });
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  late NotificationService service;
  late DateTime now;
  late List<MethodCall> calls;
  late Map<int, Map<dynamic, dynamic>> pending;
  bool permission = true, failCancel = false;
  int failNextSchedules = 0;
  Completer<bool>? permissionGate;
  String? launchPayload;

  List<CompanionInvitation> requests() => pending.values
      .map((p) => CompanionInvitation.parse(p['payload'] as String?)!)
      .toList();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    CatCareService.setCurrentUser('local_user');
    SoundService().sfxEnabled = false;
    now = DateTime.now().add(const Duration(days: 2));
    now = DateTime(now.year, now.month, now.day, 9);
    calls = [];
    pending = {};
    permission = true;
    failCancel = false;
    failNextSchedules = 0;
    permissionGate = null;
    launchPayload = null;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      calls.add(call);
      switch (call.method) {
        case 'initialize':
          return true;
        case 'getNotificationAppLaunchDetails':
          return {
            'notificationLaunchedApp': launchPayload != null,
            if (launchPayload != null)
              'notificationResponse': {
                'id': 2200,
                'payload': launchPayload,
                'notificationResponseType': 0,
              },
          };
        case 'requestNotificationsPermission':
          return permissionGate?.future ?? Future.value(permission);
        case 'zonedSchedule':
          if (failNextSchedules > 0) {
            failNextSchedules--;
            throw PlatformException(code: 'schedule-failed');
          }
          if (CompanionNotifications.ids.contains(call.arguments['id'])) {
            pending[call.arguments['id']] = Map.of(call.arguments as Map);
          }
          return null;
        case 'cancel':
          if (failCancel) throw PlatformException(code: 'cancel-failed');
          pending.remove(call.arguments['id']);
          return null;
      }
      return null;
    });
    service = NotificationService.forTesting(now: () => now);
    await service.init();
    binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    calls.clear();
  });

  tearDown(() async {
    service.dispose();
    await pumpEventQueue();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  test(
    'inventory food cancels today invitation without consuming twice',
    () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('local_user_care_consumable_inventory', [
        'churu_tuna|1',
      ]);
      expect(await service.changeCompanionReminders(enabled: true), true);
      final care = CatCareProvider(notifications: service, now: () => now);
      final food = catAccessories.firstWhere((item) => item.id == 'churu_tuna');
      expect(await care.useConsumable(food), true);
      expect(care.journey.didToday(CompanionMoment.feed, now), true);
      expect(requests().any((r) => r.day == companionDay(now)), false);
      expect(await care.useConsumable(food), false);
      expect(care.journey.growthDays, 1);
      care.dispose();
    },
  );

  test('startup and foreground do not opt in or request permission', () async {
    await service.restoreIfEnabled();
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await pumpEventQueue();
    expect((await service.getCompanionReminderSettings()).enabled, false);
    expect(pending, isEmpty);
    expect(
      calls.where((c) => c.method == 'requestNotificationsPermission'),
      isEmpty,
    );
  });

  test(
    'explicit opt-in schedules personalized, non-repeating invitations',
    () async {
      await StorageService.setCompanionName('햇살');
      expect(await service.changeCompanionReminders(enabled: true), true);
      expect(pending.length, 7);
      expect(requests().map((r) => r.day).toSet().length, 7);
      for (final slot in pending.values) {
        expect(slot['title'], '햇살의 작은 부탁 🐾');
        expect(slot['matchDateTimeComponents'], isNull);
        expect(slot['payload'], startsWith('companionCare:v1:'));
      }
      expect((await service.getCompanionReminderSettings()).enabled, true);
      expect(calls.where((c) => c.method == 'cancelAll'), isEmpty);
    },
  );

  test(
    'denied permission and native failure cannot show a successful opt-in',
    () async {
      permission = false;
      expect(await service.changeCompanionReminders(enabled: true), false);
      expect(pending, isEmpty);
      expect((await service.getCompanionReminderSettings()).enabled, false);
      permission = true;
      failNextSchedules = 1;
      expect(await service.changeCompanionReminders(enabled: true), false);
      expect(pending, isEmpty);
      expect((await service.getCompanionReminderSettings()).enabled, false);
    },
  );

  test(
    'provider care cancels today and preserves growth/name on reopen',
    () async {
      await service.changeCompanionReminders(enabled: true);
      expect(requests().any((r) => r.day == companionDay(now)), true);
      final care = CatCareProvider(notifications: service, now: () => now)
        ..companionName = '햇살';
      await care.loadJourney();
      await care.playWithCat();
      expect(requests().any((r) => r.day == companionDay(now)), false);
      expect(care.journey.didToday(CompanionMoment.play, now), true);
      await care.playWithCat();
      expect(care.journey.growthDays, 1);
      expect((await CompanionJourneyStore.load('local_user')).growthDays, 1);
      await care.renameCompanion('별이');
      expect(pending.values.every((p) => p['title'] == '별이의 작은 부탁 🐾'), true);
      expect(care.displayName, '별이');
      care.dispose();
    },
  );

  test(
    'changing time after a due invitation or toggling cannot send twice today',
    () async {
      await service.changeCompanionReminders(enabled: true, hour: 10);
      now = DateTime(now.year, now.month, now.day, 11);
      await service.changeCompanionReminders(hour: 20);
      expect(requests().any((r) => r.day == companionDay(now)), false);
      await service.changeCompanionReminders(enabled: false);
      expect(pending, isEmpty);
      service.dispose();
      service = NotificationService.forTesting(now: () => now);
      await service.changeCompanionReminders(enabled: true);
      expect(requests().any((r) => r.day == companionDay(now)), false);
      expect(
        (await SharedPreferences.getInstance()).getString(
          CompanionNotifications.consumedKey,
        ),
        companionDay(now),
      );
    },
  );

  test(
    'disable queued behind permission wins over enable and foreground refresh',
    () async {
      permissionGate = Completer<bool>();
      final enable = service.changeCompanionReminders(enabled: true);
      final disable = service.changeCompanionReminders(enabled: false);
      final refresh = service.refreshCompanionReminders();
      await pumpEventQueue();
      permissionGate!.complete(true);
      expect(await enable, true);
      expect(await disable, true);
      await refresh;
      expect((await service.getCompanionReminderSettings()).enabled, false);
      expect(pending, isEmpty);
    },
  );

  test(
    'failed time edit restores old time; failed disable keeps old preference',
    () async {
      await service.changeCompanionReminders(enabled: true, hour: 19);
      failNextSchedules = 1;
      expect(await service.changeCompanionReminders(hour: 20), false);
      expect((await service.getCompanionReminderSettings()).hour, 19);
      expect(pending.length, 7);
      failCancel = true;
      expect(await service.changeCompanionReminders(enabled: false), false);
      expect((await service.getCompanionReminderSettings()).enabled, true);
      failCancel = false;
      expect(await service.changeCompanionReminders(enabled: false), true);
      expect(pending, isEmpty);
    },
  );

  test(
    'past delivery ledger is conservative and corrupt care is never overwritten',
    () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(CompanionNotifications.ledgerKey, 'bad');
      await service.changeCompanionReminders(enabled: true);
      expect(requests().any((r) => r.day == companionDay(now)), false);
      await service.changeCompanionReminders(enabled: false);
      await prefs.setString('local_user_companion_journey_v1', 'broken');
      expect(await service.changeCompanionReminders(enabled: true), false);
      expect(prefs.getString('local_user_companion_journey_v1'), 'broken');
      expect(pending, isEmpty);
    },
  );

  test(
    'resume refreshes bounded week without prompting; paused visits do not',
    () async {
      await service.changeCompanionReminders(enabled: true);
      calls.clear();
      now = now.add(const Duration(days: 12));
      await service.refreshForForegroundVisit();
      expect(calls.where((c) => c.method == 'zonedSchedule'), isEmpty);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await pumpEventQueue();
      expect(pending.length, 7);
      expect(requests().first.day, companionDay(now));
      expect(
        calls.where((c) => c.method == 'requestNotificationsPermission'),
        isEmpty,
      );
    },
  );

  test(
    'cold and warm notification taps retain a consumable care deep link',
    () async {
      final payload = CompanionInvitation(
        CompanionMoment.play,
        companionDay(now),
      ).payload;
      launchPayload = payload;
      service.dispose();
      service = NotificationService.forTesting(now: () => now);
      await service.init();
      expect(service.consumePendingDeepLink(), payload);
      expect(service.consumePendingDeepLink(), isNull);
      var taps = 0;
      service.deepLinkChanges.addListener(() => taps++);
      final done = Completer<void>();
      binding.defaultBinaryMessenger.handlePlatformMessage(
        channel.name,
        const StandardMethodCodec().encodeMethodCall(
          MethodCall('didReceiveNotificationResponse', {
            'id': 2200,
            'payload': payload,
            'notificationResponseType': 0,
          }),
        ),
        (_) => done.complete(),
      );
      await done.future;
      expect(taps, 1);
      expect(service.consumePendingDeepLink(), payload);
    },
  );

  test(
    'late-day saved care is not lost and quiet-hour edits are rejected',
    () async {
      await service.changeCompanionReminders(enabled: true);
      final before = (await service.getCompanionReminderSettings()).encode();
      expect(await service.changeCompanionReminders(hour: 23), false);
      expect((await service.getCompanionReminderSettings()).encode(), before);
      final prefs = await SharedPreferences.getInstance();
      final ledger =
          jsonDecode(prefs.getString(CompanionNotifications.ledgerKey)!)
              as List;
      expect(ledger.length, 7);
    },
  );
}
