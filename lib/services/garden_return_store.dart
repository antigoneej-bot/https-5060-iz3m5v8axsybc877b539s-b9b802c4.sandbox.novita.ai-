import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../mongi/models/public_garden.dart';

/// Device-local, account-scoped read markers. These are not server claims,
/// currency, push notifications or an authoritative total inbox count.
class GardenReturnStore extends ChangeNotifier {
  static final instance = GardenReturnStore();
  GardenReturnStore();
  final Map<String, Map<String, bool>> _messages = {};
  Future<void> _tail = Future.value();
  static String _key(String owner, String suffix) =>
      'garden_return_v1.${base64Url.encode(utf8.encode(owner))}.$suffix';

  Future<T> _serial<T>(Future<T> Function() task) {
    final result = _tail.then((_) => task());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  bool hasUnseen(String? owner) =>
      owner != null && (_messages[owner]?.values.any((seen) => !seen) ?? false);

  Future<Map<String, bool>> _read(String owner, SharedPreferences prefs) async {
    if (_messages.containsKey(owner)) return Map.of(_messages[owner]!);
    try {
      final raw = jsonDecode(prefs.getString(_key(owner, 'seen')) ?? '{}');
      if (raw is Map &&
          raw.length <= 1000 &&
          raw.entries.every((e) => e.key is String && e.value is bool)) {
        return Map<String, bool>.from(raw);
      }
    } catch (_) {}
    return {};
  }

  Future<void> reload(String owner) => _serial(() async {
    final prefs = await SharedPreferences.getInstance();
    _messages[owner] = await _read(owner, prefs);
    notifyListeners();
  });

  Future<void> _save(
    String owner,
    Map<String, bool> messages,
    SharedPreferences prefs,
  ) async {
    while (messages.length > 1000) {
      messages.remove(messages.keys.first);
    }
    if (!await prefs.setString(_key(owner, 'seen'), jsonEncode(messages))) {
      throw StateError('받은 마음 확인 표시를 저장하지 못했어요.');
    }
    _messages[owner] = messages;
    notifyListeners();
  }

  Future<void> observe(
    String owner,
    List<ReceivedCheer> cheers, {
    Iterable<String> retiredIds = const [],
  }) => _serial(() async {
    final prefs = await SharedPreferences.getInstance();
    final messages = await _read(owner, prefs);
    // Old history does not become new: confirmed/claimed entries have already
    // been handled. Pure emoji cheers remain unread until explicitly viewed.
    for (final cheer in cheers.reversed) {
      if (cheer.id.isEmpty) continue;
      if (cheer.claimed || cheer.bloomConfirmed) {
        messages[cheer.id] = true;
      } else {
        messages.putIfAbsent(cheer.id, () => false);
      }
    }
    for (final id in retiredIds) {
      if (messages.containsKey(id)) messages[id] = true;
    }
    await _save(owner, messages, prefs);
  });

  Future<void> markSeen(String owner, Iterable<String> ids) =>
      _serial(() async {
        final prefs = await SharedPreferences.getInstance();
        final messages = await _read(owner, prefs);
        for (final id in ids) {
          if (id.isNotEmpty) messages[id] = true;
        }
        await _save(owner, messages, prefs);
      });

  /// Returns the previous visit for this opening, then persists today's actual
  /// local state. Never invent growth while the app was closed.
  Future<GardenReturnSummary> recordVisit(
    String owner, {
    required Map<String, int> seeds,
    required int recordDays,
    DateTime? now,
  }) => _serial(() async {
    final time = now ?? DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    DateTime? previous;
    Map<String, int> oldSeeds = {};
    var oldDays = recordDays;
    try {
      final raw = jsonDecode(prefs.getString(_key(owner, 'visit')) ?? '{}');
      if (raw is Map) {
        previous = DateTime.tryParse(raw['at']?.toString() ?? '');
        if (raw['seeds'] is Map) oldSeeds = Map<String, int>.from(raw['seeds']);
        if (raw['recordDays'] is int) oldDays = raw['recordDays'];
      }
    } catch (_) {
      previous = null;
    }
    final summary = GardenReturnSummary(
      previousVisit: previous,
      currentVisit: time,
      newPlants: previous == null
          ? 0
          : seeds.entries
                .where((e) => e.value > 0 && (oldSeeds[e.key] ?? 0) == 0)
                .length,
      grownPlants: previous == null
          ? 0
          : seeds.entries
                .where(
                  (e) =>
                      (oldSeeds[e.key] ?? 0) > 0 && e.value > oldSeeds[e.key]!,
                )
                .length,
      newRecordDays: previous == null
          ? 0
          : (recordDays - oldDays).clamp(0, recordDays),
    );
    if (!await prefs.setString(
      _key(owner, 'visit'),
      jsonEncode({
        'at': time.toIso8601String(),
        'seeds': seeds,
        'recordDays': recordDays,
      }),
    )) {
      throw StateError('정원 방문 표시를 저장하지 못했어요.');
    }
    return summary;
  });
}

class GardenReturnSummary {
  final DateTime? previousVisit;
  final DateTime currentVisit;
  final int newPlants, grownPlants, newRecordDays;
  const GardenReturnSummary({
    required this.previousVisit,
    required this.currentVisit,
    this.newPlants = 0,
    this.grownPlants = 0,
    this.newRecordDays = 0,
  });

  int get daysAway {
    final previous = previousVisit;
    if (previous == null) return 0;
    return DateTime.utc(currentVisit.year, currentVisit.month, currentVisit.day)
        .difference(DateTime.utc(previous.year, previous.month, previous.day))
        .inDays
        .clamp(0, 99999);
  }

  bool get hasChanges => newPlants + grownPlants + newRecordDays > 0;
  String get greeting => daysAway >= 3 ? '다시 만나 반가워요' : '정원에 남은 작은 소식';
  String get description {
    if (previousVisit == null) return '오늘부터 정원의 변화를 함께 기억할게요.';
    final parts = <String>[
      if (newPlants > 0) '새로 심은 식물 $newPlants종',
      if (grownPlants > 0) '한 뼘 자란 식물 $grownPlants종',
      if (newRecordDays > 0) '새로 마음을 남긴 날 $newRecordDays일',
    ];
    return parts.isEmpty
        ? '쉬어 간 날에도 정원에 남긴 시간은 그대로예요.'
        : '지난 방문 이후 ${parts.join(' · ')}이 남았어요.';
  }
}
