import 'local_record_transaction.dart';
import 'package:uuid/uuid.dart';
import 'meditation_completion_journal.dart';
import 'dart:convert';
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
  final _queue = LocalRecordQueue();
  ({String course, int index, String key})? _armed;
  final _unsaved = <Map<String, dynamic>>[];
  int step(MeditationCourse c) => progress[c.id] ?? 0;
  static String day(DateTime now) =>
      '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  bool doneToday(MeditationCourse c, {DateTime? now}) =>
      lastDays[c.id] == day(now ?? DateTime.now());
  Future<void> load() => _ready ??= _load().catchError((Object e) {
    _ready = null;
    throw e;
  });

  /// Forces a fresh read from SharedPreferences, discarding any in-memory
  /// cache. Used after a backup restore writes `meditation.courses` directly,
  /// so this store's cached [progress]/[lastDays]/[active] cannot go stale.
  Future<void> reload() async {
    await _queue.settled;
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
    return _queue.run(() async {
      await load();
      await action();
    });
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
    )) {
      await p.reload();
      throw StateError('course-save');
    }
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

  /// Capture the armed step before the player records its durable completion.
  Map<String, dynamic>? preparedCompletion(String key, DateTime now) {
    final session = _armed;
    if (session == null || session.key != key) return null;
    return {'course': session.course, 'index': session.index, 'day': day(now)};
  }

  Future<void> complete(String key, {DateTime? now}) async {
    final event = preparedCompletion(key, now ?? DateTime.now());
    if (event == null) return;
    _armed = null;
    _unsaved.add({'id': const Uuid().v4(), ...event, 'reward': false});
    await retry();
  }

  Future<void> applyCompletion(Map<String, dynamic> event) => _run(() async {
    final course = event['course'];
    if (course == null) return;
    final index = event['index'] as int;
    final date = event['day'] as String;
    if (!meditationCourses.any(
      (c) => c.id == course && index >= 0 && index < c.guides.length,
    )) {
      throw const FormatException('invalid-course-completion');
    }
    if ((progress[course] ?? 0) == index && lastDays[course] != date) {
      await _save(
        active,
        {...progress, course as String: index + 1},
        {...lastDays, course: date},
      );
    }
    if (_armed?.course == course && _armed?.index == index) _armed = null;
  });

  Future<void> retry() async {
    for (final event in _unsaved.toList()) {
      await MeditationCompletionJournal.enqueue(event);
      _unsaved.remove(event);
    }
    await MeditationCompletionJournal.drain(applyCompletion, courseOnly: true);
  }
}
