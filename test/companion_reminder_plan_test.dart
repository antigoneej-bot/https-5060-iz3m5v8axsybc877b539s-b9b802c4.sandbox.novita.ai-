import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/models/companion_journey.dart';
import 'package:flutter_app/models/companion_reminder.dart';
import 'package:flutter_app/models/companion_behavior.dart';
import 'package:flutter_app/services/backup_service.dart';
import 'package:flutter_app/services/notification_service.dart';

void main() {
  final morning = DateTime(2026, 10, 25, 9);
  const on = CompanionReminderSettings(enabled: true);
  List<CompanionReminderSlot> plan({
    DateTime? now,
    CompanionJourney journey = const CompanionJourney(),
    String? consumed,
  }) => planCompanionReminders(
    now: now ?? morning,
    settings: on,
    journey: journey,
    consumedDay: consumed,
  );

  test(
    'consent defaults off, survives round-trip, and rejects night/corrupt times',
    () {
      expect(CompanionReminderSettings.decode(null).enabled, false);
      expect(
        planCompanionReminders(
          now: morning,
          settings: const CompanionReminderSettings(),
          journey: const CompanionJourney(),
        ),
        isEmpty,
      );
      expect(CompanionReminderSettings.decode(on.encode()).enabled, true);
      for (final hour in [-1, 7, 22, 24]) {
        expect(
          () => CompanionReminderSettings.decode(
            jsonEncode({
              'version': 1,
              'enabled': true,
              'hour': hour,
              'minute': 0,
            }),
          ),
          throwsFormatException,
        );
      }
    },
  );

  test(
    'one local-clock invitation per date, four varied actions, bounded week',
    () {
      final slots = plan();
      expect(slots.length, 7);
      expect(slots.map((s) => s.invitation.day).toSet().length, 7);
      expect(slots.map((s) => s.id).toSet().length, 7);
      expect(
        slots.map((s) => s.invitation.action).toSet(),
        CompanionInvitation.actions.toSet(),
      );
      for (final slot in slots) {
        expect(slot.when.hour, 19);
        expect(slot.when.minute, 0);
        expect(slot.when.isAfter(morning), true);
        expect(slot.when.isBefore(DateTime(2026, 11, 2)), true);
      }
    },
  );

  test(
    'past time and midnight use calendar days, no immediate catch-up ping',
    () {
      final slots = plan(now: DateTime(2026, 12, 31, 23, 59));
      expect(slots.first.when, DateTime(2027, 1, 1, 19));
      expect(slots.last.when, DateTime(2027, 1, 7, 19));
      expect(plan(now: DateTime(2026, 10, 25, 18, 59, 30)).first.when.day, 26);
    },
  );

  for (final action in [
    ...CompanionInvitation.actions,
    CompanionMoment.brush,
    CompanionMoment.care,
  ]) {
    test('$action already cared today: suppress today, preserve tomorrow', () {
      final journey = const CompanionJourney().record(action, morning);
      expect(plan(journey: journey).first.invitation.day, '2026-10-26');
      expect(
        plan(
          journey: journey,
          now: DateTime(2026, 10, 26, 9),
        ).first.invitation.day,
        '2026-10-26',
      );
    });
  }

  test(
    'delivered-day budget survives time edits and does not punish absence',
    () {
      final slots = plan(consumed: '2026-10-25');
      expect(slots.every((s) => s.invitation.day != '2026-10-25'), true);
      final journey = const CompanionJourney().record(
        CompanionMoment.pet,
        morning,
      );
      expect(
        plan(journey: journey, now: DateTime(2027, 1, 1)).isNotEmpty,
        true,
      );
      expect(journey.growthDays, 1);
    },
  );

  test('payloads contain action and date only; invalid links are rejected', () {
    for (final action in CompanionInvitation.actions) {
      final request = CompanionInvitation(action, '2026-10-25');
      expect(CompanionInvitation.parse(request.payload)?.action, action);
    }
    for (final bad in [
      null,
      'companionCare:v1:delete:2026-10-25',
      'companionCare:v1:feed:2026-02-30',
      'companionCare:v2:feed:2026-10-25',
      'companionCare:v1:feed:2026-10-25:private',
      'gardenPush:social',
    ]) {
      expect(CompanionInvitation.parse(bad), isNull);
    }
  });

  test(
    'new memories preserve old records; notification consent stays device-local',
    () {
      final old = const CompanionJourney().record(CompanionMoment.pet, morning);
      final next = CompanionJourney.decode(old.encode())
          .record(CompanionMoment.feed, morning)
          .record(CompanionMoment.play, morning);
      final restored = CompanionJourney.decode(next.encode());
      expect(restored.growthDays, 1);
      expect(restored.firstMoments.length, 3);
      expect(restored.firstMoments[CompanionMoment.pet], '2026-10-25');
      expect(
        BackupService.prefType(CompanionNotifications.settingsKey),
        isNull,
      );
      expect(BackupService.prefType(CompanionNotifications.ledgerKey), isNull);
      expect(
        BackupService.prefType(CompanionNotifications.consumedKey),
        isNull,
      );
    },
  );

  test(
    'reactions return to neutral smoothly and never move the body baseline',
    () {
      for (final action in CompanionInteraction.values) {
        var previous = CompanionBehaviorFrame.reacting(action, 0);
        for (var i = 0; i <= 1000; i++) {
          final frame = CompanionBehaviorFrame.reacting(action, i / 1000);
          expect(frame.headTilt.abs(), lessThanOrEqualTo(.05));
          expect((frame.headTilt - previous.headTilt).abs(), lessThan(.002));
          expect(frame.eyeClosure, inInclusiveRange(0, 1));
          expect(frame.breath, 1);
          previous = frame;
        }
        expect(previous.headTilt.abs(), lessThan(1e-10));
        expect(previous.eyeClosure.abs(), lessThan(1e-10));
      }
    },
  );
}
