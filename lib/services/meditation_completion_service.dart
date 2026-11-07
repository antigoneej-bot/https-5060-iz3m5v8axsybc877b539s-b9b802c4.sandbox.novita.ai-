import 'local_record_transaction.dart';
import 'companion_journey_store.dart';
import 'cat_care_service.dart';
import '../models/companion_journey.dart';
import 'meditation_course_store.dart';
import 'meditation_completion_journal.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../mongi/integration/mongi_garden_store.dart';

/// One durable event contains both course progression and the daily garden reward.
class MeditationCompletionService {
  static final instance = MeditationCompletionService();
  MeditationCompletionService({
    MeditationCourseStore? courses,
    Future<void> Function(DateTime)? claimReward,
  }) : _courses = courses ?? MeditationCourseStore.instance,
       _claimReward = claimReward ?? _claim;
  final MeditationCourseStore _courses;
  final Future<void> Function(DateTime) _claimReward;
  static Future<void> _claim(DateTime day) async {
    await MongiGardenStore.instance.claimCompletedCare(
      now: day,
      meditation: true,
    );
    // The completion journal retries this idempotent daily update on failure.
    await CompanionJourneyStore.record(
      CatCareService.localOwner,
      CompanionMoment.meditation,
      now: day,
    );
  }

  final _unsaved = <Map<String, dynamic>>[];
  final _queue = LocalRecordQueue();
  final completed = ValueNotifier<({String session, String key})?>(null);
  final saveProblem = ValueNotifier<String?>(null);

  Future<void> begin(String guideKey) async {
    await retry();
    if (completed.value?.key == guideKey) completed.value = null;
    try {
      await _courses.begin(guideKey);
    } catch (_) {
      saveProblem.value = '코스 기록을 불러오지 못했어요. 명상은 이용할 수 있어요.';
    }
  }

  Future<void> complete({String? guideKey}) {
    final now = DateTime.now();
    final id = const Uuid().v4();
    final event = <String, dynamic>{
      'id': id,
      'day': MeditationCourseStore.day(now),
      'reward': true,
      if (guideKey != null) ...?_courses.preparedCompletion(guideKey, now),
    };
    _unsaved.add(event);
    if (guideKey != null) completed.value = (session: id, key: guideKey);
    return retry();
  }

  Future<void> retry() {
    return _queue.run(() async {
      try {
        for (final event in _unsaved.toList()) {
          await MeditationCompletionJournal.enqueue(event);
          _unsaved.remove(event);
        }
        await MeditationCompletionJournal.drain((event) async {
          await _courses.applyCompletion(event);
          if (event['reward'] == true)
            await _claimReward(DateTime.parse(event['day'] as String));
        });
        saveProblem.value = null;
      } catch (_) {
        saveProblem.value = _unsaved.isEmpty
            ? '완료 기록 반영을 기다리고 있어요. 다시 시도하거나 앱을 다시 열면 이어서 확인해요.'
            : '완료 기록을 저장하지 못했어요. 앱을 닫기 전에 저장을 다시 시도해 주세요.';
      }
    });
  }
}
