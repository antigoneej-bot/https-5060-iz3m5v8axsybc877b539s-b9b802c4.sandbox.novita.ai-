import 'dart:convert';
import '../models/meditation_completion_record.dart';
import 'meditation_completion_journal.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MeditationCourse {
  final String id, title, description;
  final List<String> guides;
  const MeditationCourse(this.id, this.title, this.description, this.guides);
}

const meditationCourses = [
  MeditationCourse('first7', '처음 시작하는 7일', '하루 한 편, 쉬어 가도 다음 순서부터 이어요.', [
    'forestRest',
    'busyMindRest',
    'singingBowlRest',
    'forestRest',
    'busyMindRest',
    'singingBowlRest',
    'sleepMeditation',
  ]),
  MeditationCourse('bedtime3', '잠들기 전 쉬기', '세 번의 밤을 위한 쉬는 시간이에요.', [
    'sleepMeditation',
    'rainThunderRest',
    'sleepMeditation',
  ]),
];

class MeditationCourseStore extends ChangeNotifier {
  static final instance = MeditationCourseStore();
  String? active;
  final progress = <String, int>{};
  final lastDays = <String, String>{};
  Future<void>? _ready;
  Future<void> _tail = Future.value();
  ({String course, int index, String key})? _armed;
  int step(MeditationCourse c) => progress[c.id] ?? 0;
  static String day(DateTime now) =>
      '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  bool doneToday(MeditationCourse c, {DateTime? now}) =>
      lastDays[c.id] == day(now ?? DateTime.now());
  Future<void> load() => _ready ??= _load().catchError((Object e) {
    _ready = null;
    throw e;
  });
  Future<void> reload() async {
    await _tail;
    await (await SharedPreferences.getInstance()).reload();
    _ready = null;
    _armed = null;
    active = null;
    progress.clear();
    lastDays.clear();
    await load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('meditation.courses');
    if (raw != null) {
      final data = jsonDecode(raw) as Map;
      for (final c in meditationCourses) {
        final count = (data['progress'] as Map?)?[c.id];
        if (count is int && count >= 0 && count <= c.guides.length)
          progress[c.id] = count;
        final date = (data['days'] as Map?)?[c.id];
        if (date is String && DateTime.tryParse(date) != null)
          lastDays[c.id] = date;
      }
      if (meditationCourses.any((c) => c.id == data['active']))
        active = data['active'] as String;
    }
    notifyListeners();
  }

  Future<void> _run(Future<void> Function() action) {
    final next = _tail.then((_) async {
      await load();
      await action();
    });
    _tail = next.catchError((Object _) {});
    return next;
  }

  Future<void> _save(
    String? selected,
    Map<String, int> steps,
    Map<String, String> days,
  ) async {
    final p = await SharedPreferences.getInstance();
    if (!await p.setString(
      'meditation.courses',
      jsonEncode({'active': selected, 'progress': steps, 'days': days}),
    ))
      throw StateError('course-save');
    active = selected;
    progress
      ..clear()
      ..addAll(steps);
    lastDays
      ..clear()
      ..addAll(days);
    notifyListeners();
  }

  Future<void> activate(String id) => _run(() async {
    if (!meditationCourses.any((c) => c.id == id))
      throw ArgumentError('course');
    await _save(id, Map.of(progress), Map.of(lastDays));
    _armed = null;
  });
  Future<void> begin(String key) => _run(() async {
    _armed = null;
    for (final c in meditationCourses) {
      final index = step(c);
      if (c.id == active && index < c.guides.length && c.guides[index] == key)
        _armed = (course: c.id, index: index, key: key);
    }
  });
  MeditationCompletionRecord? captureCompletion(
    String key, {
    String? id,
    DateTime? now,
    bool reward = false,
  }) {
    final session = _armed;
    if (session == null || session.key != key) return null;
    final at = now ?? DateTime.now();
    return MeditationCompletionRecord(
      id: id ?? 'course:${session.course}:${session.index}:${day(at)}',
      completedAt: at,
      guide: key,
      course: session.course,
      index: session.index,
      reward: reward,
    );
  }

  void acknowledge(MeditationCompletionRecord record) {
    if (_armed?.course == record.course &&
        _armed?.index == record.index &&
        _armed?.key == record.guide)
      _armed = null;
  }

  Future<void> complete(String key, {DateTime? now}) async {
    final record = captureCompletion(key, now: now);
    if (record == null) return;
    await MeditationCompletionJournal.instance.save(record);
    acknowledge(record);
    await retry();
  }

  /// Replaying a recorded step cannot advance it twice, even after a crash
  /// between the progress commit and removal of the completion journal.
  Future<void> applyCompletion(MeditationCompletionRecord record) => _run(
    () async {
      if (record.course == null) return;
      final matches = meditationCourses.where((c) => c.id == record.course);
      if (matches.isEmpty) throw const FormatException('명상 과정을 확인할 수 없어요.');
      final c = matches.single;
      final index = record.index!;
      if (index >= c.guides.length || c.guides[index] != record.guide)
        throw const FormatException('명상 과정 순서가 일치하지 않아요.');
      final current = step(c);
      if (current > index || lastDays[c.id] == day(record.completedAt)) return;
      if (current < index) throw StateError('이전 명상 과정의 저장을 먼저 마쳐야 해요.');
      await _save(
        active,
        {...progress, c.id: index + 1},
        {...lastDays, c.id: day(record.completedAt)},
      );
    },
  );

  Future<void> retry() async {
    await load();
    for (final record in await MeditationCompletionJournal.instance.load()) {
      if (record.course == null) continue;
      await applyCompletion(record);
      // Combined care rewards are acknowledged only by the completion service.
      if (!record.reward)
        await MeditationCompletionJournal.instance.remove(record.id);
    }
  }
}
