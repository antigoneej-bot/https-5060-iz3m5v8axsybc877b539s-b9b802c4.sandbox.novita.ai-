import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/meditation_media_data.dart';

class MeditationLibraryStore extends ChangeNotifier {
  static final instance = MeditationLibraryStore();
  final favorites = <String>{};
  final recent = <String>[];
  final checkIns = <Map<String, dynamic>>[];
  Future<void>? _ready;
  Future<void> _tail = Future.value();
  Future<void> load() => _ready ??= _load().catchError((Object error) {
    _ready = null;
    throw error;
  });
  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    favorites.addAll(
      (p.getStringList('meditation.favorites') ?? []).where(
        meditationMedia.containsKey,
      ),
    );
    recent.addAll(
      (p.getStringList('meditation.recent') ?? [])
          .where(meditationMedia.containsKey)
          .take(10),
    );
    try {
      final raw =
          jsonDecode(p.getString('meditation.checkins') ?? '[]') as List;
      checkIns.addAll(
        raw.whereType<Map>().map((v) => Map<String, dynamic>.from(v)).take(90),
      );
    } catch (_) {
      /* Ignore malformed optional history; never alter the diary. */
    }
    notifyListeners();
  }

  Future<void> _run(Future<void> Function(SharedPreferences) action) {
    final result = _tail.then((_) async {
      await load();
      await action(await SharedPreferences.getInstance());
      notifyListeners();
    });
    _tail = result.catchError((Object _) {});
    return result;
  }

  Future<void> toggleFavorite(String key) => _run((p) async {
    if (!meditationMedia.containsKey(key)) return;
    final next = {...favorites};
    if (!next.add(key)) next.remove(key);
    if (!await p.setStringList('meditation.favorites', next.toList()))
      throw StateError('favorite-save');
    favorites
      ..clear()
      ..addAll(next);
  });
  Future<void> played(String key) => _run((p) async {
    if (!meditationMedia.containsKey(key)) return;
    final next = [key, ...recent.where((v) => v != key)].take(10).toList();
    if (!await p.setStringList('meditation.recent', next))
      throw StateError('recent-save');
    recent
      ..clear()
      ..addAll(next);
  });
  Future<void> checkIn(String session, String key, String feeling) =>
      _run((p) async {
        if (!['better', 'same', 'worse'].contains(feeling) ||
            !meditationMedia.containsKey(key))
          return;
        if (checkIns.any((v) => v['session'] == session)) return;
        final next = <Map<String, dynamic>>[
          {
            'session': session,
            'guide': key,
            'feeling': feeling,
            'at': DateTime.now().toIso8601String(),
          },
          ...checkIns,
        ].take(90).toList();
        if (!await p.setString('meditation.checkins', jsonEncode(next)))
          throw StateError('checkin-save');
        checkIns
          ..clear()
          ..addAll(next);
      });
}
