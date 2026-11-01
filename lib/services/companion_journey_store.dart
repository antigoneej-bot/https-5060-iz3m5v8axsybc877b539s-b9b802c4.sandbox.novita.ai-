import 'local_record_transaction.dart';
import '../models/companion_coat.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/companion_journey.dart';

/// Same local record owner as CatCareService. Login never changes ownership.
/// Reads and writes share a queue so two screens cannot lose a care action.
class CompanionJourneyStore {
  static const suffix = 'companion_journey_v1';
  static final _queue = LocalRecordQueue();
  static Future<T> _serial<T>(Future<T> Function() action) =>
      _queue.run(action);

  static Future<CompanionJourney> _read(
    SharedPreferences prefs,
    String owner,
  ) async {
    final raw = prefs.getString('${owner}_$suffix');
    if (raw != null) return CompanionJourney.decode(raw);
    // Preserve known care days, not attendance or invented past dates.
    final old = max(0, prefs.getInt('${owner}_care_total_full_care_days') ?? 0);
    final today = companionDay(DateTime.now());
    final countedToday =
        old > 0 && prefs.getBool('${owner}_care_bonus_given_$today') == true;
    final journey = countedToday
        ? CompanionJourney(
            previousCareDays: old - 1,
            careDays: [today],
            today: today,
            firstMoments: {CompanionMoment.care: today},
            todayMoments: {CompanionMoment.care},
          )
        : CompanionJourney(previousCareDays: old);
    if (old > 0) await _write(prefs, owner, journey);
    return journey;
  }

  static Future<void> _write(
    SharedPreferences prefs,
    String owner,
    CompanionJourney journey,
  ) async {
    if (!await prefs.setString('${owner}_$suffix', journey.encode())) {
      throw StateError('고양이와 함께한 기록을 저장하지 못했어요.');
    }
  }

  static Future<CompanionJourney> load(String owner) =>
      _serial(() async => _read(await SharedPreferences.getInstance(), owner));

  static Future<CompanionJourney> record(
    String owner,
    CompanionMoment action, {
    DateTime? now,
  }) => _serial(() async {
    final prefs = await SharedPreferences.getInstance();
    final current = await _read(prefs, owner);
    final next = current.record(action, now ?? DateTime.now());
    await _write(prefs, owner, next);
    return next;
  });

  static Future<CompanionJourney> setCoat(String owner, CompanionCoat value) =>
      _serial(() async {
        final prefs = await SharedPreferences.getInstance();
        final next = (await _read(prefs, owner)).withCoat(value);
        await _write(prefs, owner, next);
        return next;
      });

  static Future<CompanionJourney> adopt(String owner, CompanionCoat coat) =>
      _serial(() async {
        final prefs = await SharedPreferences.getInstance();
        final next = (await _read(prefs, owner)).adopt(coat);
        await _write(prefs, owner, next);
        return next;
      });

  static Future<CompanionJourney> setBaby(String owner, bool value) =>
      _serial(() async {
        final prefs = await SharedPreferences.getInstance();
        final next = (await _read(prefs, owner)).withBaby(value);
        await _write(prefs, owner, next);
        return next;
      });

  static Future<CompanionJourney> setAutomaticBehavior(
    String owner,
    bool value,
  ) => _serial(() async {
    final prefs = await SharedPreferences.getInstance();
    final next = (await _read(prefs, owner)).withAutomaticBehavior(value);
    await _write(prefs, owner, next);
    return next;
  });
}
