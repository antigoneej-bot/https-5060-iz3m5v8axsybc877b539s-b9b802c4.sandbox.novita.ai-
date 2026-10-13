import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/meditation_media_data.dart';
import '../models/meditation_check_in_record.dart';
import 'meditation_check_in_store.dart';

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
    final history = await MeditationCheckInStore.instance.load();
    favorites.clear();
    recent.clear();
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
    checkIns
      ..clear()
      ..addAll(history);
    notifyListeners();
  }

  Future<T> _run<T>(Future<T> Function(SharedPreferences) action) {
    final result = _tail.then((_) async {
      await load();
      final value = await action(await SharedPreferences.getInstance());
      notifyListeners();
      return value;
    });
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
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
  Future<void> removeCheckIn(String session) => _run((_) async {
    await MeditationCheckInStore.instance.remove(session);
    checkIns
      ..clear()
      ..addAll(await MeditationCheckInStore.instance.load());
  });

  Future<void> reload() async {
    await _tail;
    await (await SharedPreferences.getInstance()).reload();
    _ready = null;
    await load();
  }

  Future<MeditationCheckInRecord?> findCheckIn(String session) =>
      MeditationCheckInStore.instance.find(session);

  Future<MeditationCheckInRecord> checkIn(
    String session,
    String key,
    String feeling,
  ) => _run((p) async {
    if (!['better', 'same', 'worse'].contains(feeling) ||
        !meditationMedia.containsKey(key))
      throw ArgumentError('명상 후기 선택을 확인해 주세요.');
    final saved = await MeditationCheckInStore.instance.save(
      MeditationCheckInRecord(
        session: session,
        guide: key,
        feeling: feeling,
        at: DateTime.now(),
      ),
    );
    checkIns
      ..clear()
      ..addAll(await MeditationCheckInStore.instance.load());
    return saved;
  });
}
