import 'package:hive_flutter/hive_flutter.dart';
import '../models/buried_emotion_entry.dart';

/// '그림자 방울 묻어두기' 데이터를 계정별로 관리하는 서비스.
///
/// [StorageService]/[PromiseService]와 같은 패턴(계정별 Hive Box)을 따르되,
/// 방울 터뜨리기 세션과 달리 하루 안에 사라지지 않고 며칠(기본 7일) 동안
/// 유지되어야 하므로 별도의 Box(`buried_emotions_$_uid`)를 씁니다.
///
/// 톤앤매너: 이 저장소는 "해결해야 할 문제 목록"이 아닙니다. 묻어둔 감정은
/// 그저 며칠 뒤 조용히 새싹으로 떠오르고, 사용자가 원하지 않으면 아무 기록도
/// 남기지 않고 흘려보낼 수 있습니다 - 실패/미완료 개념 자체가 없습니다.
class BuriedEmotionService {
  static String _uid = 'guest';
  static Box? _box;

  /// 묻은 지 며칠 뒤 새싹으로 떠오를지. 지금은 고정값으로 두고, 추후
  /// "랜덤 3~10일"로 튜닝하고 싶다면 [pickResurfaceDelay]만 바꾸면 됩니다.
  static const int fixedResurfaceDays = 7;

  /// 하루에 묻을 수 있는 최대 개수(누적 방지).
  static const int maxBuriesPerDay = 1;

  static Future<void> setCurrentUser(String userId) async {
    if (_uid == userId && _box != null && _box!.isOpen) return;
    _uid = userId;
    if (_box != null && _box!.isOpen) {
      await _box!.close();
    }
    _box = await Hive.openBox('buried_emotions_$_uid');
  }

  static Future<void> clearCurrentUser() async {
    if (_box != null && _box!.isOpen) {
      await _box!.close();
    }
    _box = null;
    _uid = 'guest';
  }

  static Box get _safeBox {
    if (_box == null || !_box!.isOpen) {
      throw Exception(
        'BuriedEmotionService: 사용자가 설정되지 않았습니다 (setCurrentUser 먼저 호출)',
      );
    }
    return _box!;
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// 새싹이 떠오를 시각을 정합니다. 지금은 고정 7일 뒤로 단순화되어 있습니다.
  static DateTime _pickResurfaceAt(DateTime buriedAt) {
    return buriedAt.add(const Duration(days: fixedResurfaceDays));
  }

  /// 지금까지 묻어둔 기록 전체를 최신순으로 반환합니다.
  static List<BuriedEmotionEntry> getAllEntries() {
    final entries = _safeBox.values
        .map(
          (e) =>
              BuriedEmotionEntry.fromMap(Map<dynamic, dynamic>.from(e as Map)),
        )
        .toList();
    entries.sort((a, b) => b.buriedAt.compareTo(a.buriedAt));
    return entries;
  }

  /// 오늘 이미 하나를 묻었는지 여부(하루 최대 1개 제한 판단용).
  static bool hasBuriedToday({DateTime? now}) {
    final ref = now ?? DateTime.now();
    return getAllEntries().any((e) => _isSameDay(e.buriedAt, ref));
  }

  /// 아직 새싹으로 떠오르지 않았고, 떠오를 시점도 아직 되지 않은(=땅 속에서
  /// 조용히 기다리는 중인) 기록들.
  static List<BuriedEmotionEntry> getWaitingEntries({DateTime? now}) {
    final ref = now ?? DateTime.now();
    return getAllEntries()
        .where((e) => !e.resurfaced && ref.isBefore(e.resurfaceAt))
        .toList();
  }

  /// 지금 새싹으로 떠올라 사용자가 만날 수 있는 기록들(아직 재부상 처리를
  /// 하지 않은 것들). 보통 한 번에 최대 1개만 존재하지만, 혹시 여러 개가
  /// 겹쳐도 안전하게 리스트로 반환합니다.
  static List<BuriedEmotionEntry> getPendingSprouts({DateTime? now}) {
    final ref = now ?? DateTime.now();
    return getAllEntries()
        .where((e) => e.isReadyToResurface(now: ref))
        .toList();
  }

  /// 오늘 특별히 무거웠던 감정 하나를 땅에 묻습니다. 하루 최대 1개 제한을
  /// 넘으면 아무 일도 하지 않고 false를 반환합니다.
  static Future<bool> buryEmotion({
    required String catId,
    required String letterSnippet,
    DateTime? now,
  }) async {
    final ref = now ?? DateTime.now();
    if (hasBuriedToday(now: ref)) return false;

    final id = 'buried_${ref.millisecondsSinceEpoch}';
    final entry = BuriedEmotionEntry(
      id: id,
      catId: catId,
      letterSnippet: letterSnippet,
      buriedAt: ref,
      resurfaceAt: _pickResurfaceAt(ref),
    );
    await _safeBox.put(entry.id, entry.toMap());
    return true;
  }

  /// 새싹을 만난 뒤 짧은 재기록을 남겼을 때 호출합니다.
  static Future<void> saveReRecording(String id, String text) async {
    final raw = _safeBox.get(id);
    if (raw == null) return;
    final entry = BuriedEmotionEntry.fromMap(
      Map<dynamic, dynamic>.from(raw as Map),
    );
    final updated = entry.copyWith(
      resurfaced: true,
      recorded: true,
      currentReflectionText: text,
    );
    await _safeBox.put(id, updated.toMap());
  }

  /// 재기록을 남기지 않고 새싹을 조용히 흘려보낼 때 호출합니다. 이는
  /// 실패가 아니라 그저 "지금은 괜찮다"는 선택입니다.
  static Future<void> skipReRecording(String id) async {
    final raw = _safeBox.get(id);
    if (raw == null) return;
    final entry = BuriedEmotionEntry.fromMap(
      Map<dynamic, dynamic>.from(raw as Map),
    );
    final updated = entry.copyWith(resurfaced: true, recorded: false);
    await _safeBox.put(id, updated.toMap());
  }
}
