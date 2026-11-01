import 'local_record_transaction.dart';
import 'meditation_checkin_store.dart';
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
  final _queue = LocalRecordQueue();
  Future<void> load() => _ready ??= _load().catchError((Object error) {
    _ready = null;
    throw error;
  });

  /// Refresh preferences and encrypted check-ins after a backup restore.
  Future<void> reload() async {
    await _queue.settled;
    await (await SharedPreferences.getInstance()).reload();
    _ready = null;
    favorites.clear();
    recent.clear();
    checkIns.clear();
    await load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    favorites.clear();
    recent.clear();
    checkIns.clear();
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
    final savedCheckIns = await MeditationCheckInStore.read();
    try {
      final raw = jsonDecode(savedCheckIns ?? '[]') as List;
      checkIns.addAll(
        raw.whereType<Map>().map((v) => Map<String, dynamic>.from(v)).take(90),
      );
    } catch (_) {
      /* Ignore malformed optional history; never alter the diary. */
    }
    notifyListeners();
  }

  Future<void> _run(Future<void> Function(SharedPreferences) action) {
    return _queue.run(() async {
      await load();
      await action(await SharedPreferences.getInstance());
      notifyListeners();
    });
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
        final saved = await MeditationCheckInStore.update((raw) {
          final current = raw == null
              ? <Map<String, dynamic>>[]
              : MeditationCheckInStore.rows(raw);
          if (current.any((row) => row['session'] == session)) return raw;
          return jsonEncode(
            [
              {
                'session': session,
                'guide': key,
                'feeling': feeling,
                'at': DateTime.now().toIso8601String(),
              },
              ...current,
            ].take(90).toList(),
          );
        });
        final next = MeditationCheckInStore.rows(saved!);
        checkIns
          ..clear()
          ..addAll(next);
      });
}
