import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/models/companion_coat.dart';
import 'package:flutter_app/models/companion_journey.dart';
import 'package:flutter_app/services/companion_journey_store.dart';
import 'package:flutter_app/widgets/companion_motion_art.dart';
import 'package:flutter/material.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('adoption retains adult and starts baby without resetting garden', () {
    final adult = const CompanionJourney(
      previousCareDays: 90,
    ).withCoat(CompanionCoat.ginger);
    final baby = adult.adopt(CompanionCoat.white);
    expect(baby.growthDays, 90);
    expect(baby.activeGrowthDays, 0);
    expect(baby.residents[CompanionCoat.ginger], 90);
    expect(baby.canAdopt, false);
    expect(baby.withCoat(CompanionCoat.ginger).stage, 3);
    expect(baby.withCoat(CompanionCoat.ginger).residents.length, 2);
    final restored = CompanionJourney.decode(baby.encode());
    expect(restored.residents, baby.residents);
    expect(restored.coat, CompanionCoat.white);
  });
  test('same-day switching and reopening cannot duplicate growth', () {
    final day = DateTime(2026, 10, 29);
    var j = const CompanionJourney(
      previousCareDays: 90,
    ).adopt(CompanionCoat.black);
    j = j.record(CompanionMoment.pet, day);
    j = j.withCoat(CompanionCoat.ginger).record(CompanionMoment.water, day);
    j = CompanionJourney.decode(
      j.encode(),
    ).withCoat(CompanionCoat.black).record(CompanionMoment.rest, day);
    expect(j.activeGrowthDays, 1);
    expect(j.growthDays, 91);
    expect(j.residents[CompanionCoat.ginger], 91);
  });
  test('legacy already-counted day survives first appearance selection', () {
    const j = CompanionJourney(
      previousCareDays: 89,
      careDays: ['2026-10-29'],
      today: '2026-10-29',
    );
    for (final c in CompanionCoat.values) {
      expect(
        j
            .withCoat(c)
            .record(CompanionMoment.pet, DateTime(2026, 10, 29))
            .activeGrowthDays,
        90,
      );
    }
  });
  test('legacy counted date stays counted across repeated care and reopen', () {
    const old = CompanionJourney(
      previousCareDays: 89,
      careDays: ['2026-10-29'],
      today: '2026-10-29',
    );
    var j = old.record(CompanionMoment.pet, DateTime(2026, 10, 29));
    j = CompanionJourney.decode(
      j.encode(),
    ).record(CompanionMoment.water, DateTime(2026, 10, 29));
    expect(j.activeGrowthDays, 90);
    expect(j.growthDays, 90);
  });
  test('adoption gate and six resident maximum are enforced in model', () {
    expect(
      () => const CompanionJourney().adopt(CompanionCoat.white),
      throwsStateError,
    );
    var j = const CompanionJourney(previousCareDays: 90);
    for (final c in CompanionCoat.values.skip(1)) {
      j = j.adopt(c);
      for (var i = 0; i < 90; i++) {
        j = j.record(
          CompanionMoment.rest,
          DateTime(2026, 1, 1).add(Duration(days: i)),
        );
      }
    }
    expect(j.residents.length, 6);
    expect(j.canAdopt, false);
    expect(() => j.adopt(CompanionCoat.white), throwsStateError);
  });
  test(
    'corrupt family data is rejected without overwriting local record',
    () async {
      final raw = jsonDecode(const CompanionJourney().encode()) as Map;
      raw['family'] = {'ginger': -1};
      final encoded = jsonEncode(raw);
      SharedPreferences.setMockInitialValues({
        'local_user_companion_journey_v1': encoded,
      });
      await expectLater(
        CompanionJourneyStore.setCoat('local_user', CompanionCoat.white),
        throwsFormatException,
      );
      expect(
        (await SharedPreferences.getInstance()).getString(
          'local_user_companion_journey_v1',
        ),
        encoded,
      );
    },
  );
  test('serialized simultaneous adoption cannot create two babies', () async {
    SharedPreferences.setMockInitialValues({
      'local_user_companion_journey_v1': const CompanionJourney(
        previousCareDays: 90,
      ).encode(),
    });
    final outcomes = await Future.wait(
      [CompanionCoat.white, CompanionCoat.black].map((c) async {
        try {
          await CompanionJourneyStore.adopt('local_user', c);
          return true;
        } catch (_) {
          return false;
        }
      }),
    );
    expect(outcomes.where((v) => v).length, 1);
    expect(
      (await CompanionJourneyStore.load('local_user')).residents.length,
      2,
    );
  });
  test('growth mesh keeps feet fixed and changes body proportions', () {
    expect(
      CompanionMotionPainter.growthWarp(const Offset(.5, 1), 3, false),
      const Offset(.5, 1),
    );
    expect(
      CompanionMotionPainter.growthWarp(const Offset(.2, .2), 0, false),
      const Offset(.2, .2),
    );
    expect(
      CompanionMotionPainter.growthWarp(const Offset(.2, .2), 3, false).dx,
      greaterThan(.2),
    );
    for (var i = 0; i <= 100; i++) {
      final p = CompanionMotionPainter.growthWarp(
        Offset(.5, i / 100),
        3,
        false,
      );
      expect(p.dy, inInclusiveRange(0, 1));
    }
  });
}
