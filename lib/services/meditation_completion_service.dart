import 'meditation_course_store.dart';
import 'meditation_completion_journal.dart';
import '../models/meditation_completion_record.dart';
import 'package:flutter/foundation.dart';
import '../mongi/integration/mongi_garden_store.dart';

enum MeditationSaveState { idle, saving, waiting, unsaved }

/// Journal first, then idempotent course and once-per-day care writes.
class MeditationCompletionService {
  static final instance = MeditationCompletionService();
  final _notYetStored = <String, MeditationCompletionRecord>{};
  Future<void> _tail = Future.value();
  final completed = ValueNotifier<({String session, String key})?>(null);
  final saveState = ValueNotifier(MeditationSaveState.idle);
  int _sequence = 0;

  Future<void> begin(String guideKey) async {
    await retry();
    await MeditationCourseStore.instance.begin(guideKey);
    if (completed.value?.key == guideKey) completed.value = null;
  }

  Future<void> complete({String? guideKey}) {
    final now = DateTime.now();
    final id = '${now.microsecondsSinceEpoch}-${_sequence++}';
    final record =
        (guideKey == null
            ? null
            : MeditationCourseStore.instance.captureCompletion(
                guideKey,
                id: id,
                now: now,
                reward: true,
              )) ??
        MeditationCompletionRecord(
          id: id,
          completedAt: now,
          guide: guideKey,
          reward: true,
        );
    _notYetStored[id] = record;
    saveState.value = MeditationSaveState.saving;
    if (guideKey != null) completed.value = (session: id, key: guideKey);
    return retry();
  }

  Future<void> reload() async {
    await _tail;
    completed.value = null;
    await retry();
  }

  Future<void> prepareForBackup() async {
    await retry();
    if (saveState.value != MeditationSaveState.idle) {
      throw StateError('명상 완료 기록의 저장을 먼저 마쳐 주세요. 명상 화면에서 다시 시도할 수 있어요.');
    }
  }

  /// A backup must observe either side of a completion, never new course
  /// progress with an older garden reward snapshot. Lock order: completion,
  /// then the existing garden transaction lane.
  Future<T> consistentRead<T>(Future<T> Function() read) async {
    await prepareForBackup();
    final result = _tail.then((_) async {
      if (saveState.value != MeditationSaveState.idle) {
        throw StateError('명상 완료를 저장 중이에요. 저장 뒤 백업을 다시 시도해 주세요.');
      }
      return read();
    });
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  /// Errors remain visible and retryable. If even the journal cannot be written,
  /// the UI explicitly asks the user to retry before closing the app.
  Future<void> retry() {
    final result = _tail.then((_) async {
      try {
        for (final record in _notYetStored.values.toList()) {
          await MeditationCompletionJournal.instance.save(record);
          MeditationCourseStore.instance.acknowledge(record);
          _notYetStored.remove(record.id);
        }
        final pending = await MeditationCompletionJournal.instance.load();
        if (pending.isNotEmpty) saveState.value = MeditationSaveState.saving;
        for (final record in pending) {
          await MeditationCourseStore.instance.applyCompletion(record);
          if (record.reward) {
            await MongiGardenStore.instance.claimCompletedCare(
              now: record.day,
              meditation: true,
            );
          }
          await MeditationCompletionJournal.instance.remove(record.id);
        }
        saveState.value = _notYetStored.isEmpty
            ? MeditationSaveState.idle
            : MeditationSaveState.unsaved;
      } catch (_) {
        saveState.value = _notYetStored.isEmpty
            ? MeditationSaveState.waiting
            : MeditationSaveState.unsaved;
      }
    });
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }
}
