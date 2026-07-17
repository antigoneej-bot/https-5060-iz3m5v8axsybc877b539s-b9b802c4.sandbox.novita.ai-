import 'package:hive_flutter/hive_flutter.dart';
import '../models/usage_history_entry.dart';

/// 반복 방지 시스템(설계서 9장)의 사용 기록을 계정별로 관리하는 서비스.
///
/// [BuriedEmotionService]와 동일한 패턴(계정별 Hive Box)을 따릅니다.
/// 매 편지 생성 후, 사용된 모듈별 문장 ID를 기록해 최근 30일 내 재사용을
/// 막고 연속 시작/마무리 반복을 방지하는 데 사용합니다.
class UsageHistoryService {
  static String _uid = 'guest';
  static Box? _box;

  /// 이 기간(일) 이내 사용된 문장은 재사용을 금지합니다.
  static const int repetitionWindowDays = 30;

  static Future<void> setCurrentUser(String userId) async {
    if (_uid == userId && _box != null && _box!.isOpen) return;
    _uid = userId;
    if (_box != null && _box!.isOpen) {
      await _box!.close();
    }
    _box = await Hive.openBox('usage_history_$_uid');
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
        'UsageHistoryService: 사용자가 설정되지 않았습니다 (setCurrentUser 먼저 호출)',
      );
    }
    return _box!;
  }

  /// 지금까지 기록된 사용 이력 전체(최신순).
  static List<UsageHistoryEntry> getAllEntries() {
    final entries = _safeBox.values
        .map(
          (e) =>
              UsageHistoryEntry.fromMap(Map<dynamic, dynamic>.from(e as Map)),
        )
        .toList();
    entries.sort((a, b) => b.usedAt.compareTo(a.usedAt));
    return entries;
  }

  /// 특정 고양이(catId)의 사용 이력만.
  static List<UsageHistoryEntry> entriesForCat(String catId) =>
      getAllEntries().where((e) => e.catId == catId).toList();

  /// 특정 고양이·모듈의 최근 30일 내 사용된 문장 ID 집합
  /// (RepetitionFilter의 "최근 30일 재사용 금지" 판단용).
  static Set<String> recentlyUsedSentenceIds(
    String catId,
    String moduleKey, {
    DateTime? now,
  }) {
    final ref = now ?? DateTime.now();
    final cutoff = ref.subtract(const Duration(days: repetitionWindowDays));
    return entriesForCat(catId)
        .where((e) => e.moduleKey == moduleKey && e.usedAt.isAfter(cutoff))
        .map((e) => e.sentenceId)
        .toSet();
  }

  /// 특정 고양이·모듈에서 가장 최근에 사용한 문장 ID (연속 반복 금지 판단용).
  /// 기록이 없으면 null.
  static String? lastUsedSentenceId(String catId, String moduleKey) {
    final entries = entriesForCat(
      catId,
    ).where((e) => e.moduleKey == moduleKey).toList();
    if (entries.isEmpty) return null;
    entries.sort((a, b) => b.usedAt.compareTo(a.usedAt));
    return entries.first.sentenceId;
  }

  /// 이번 편지에서 모듈별로 실제 선택된 문장 ID를 한 번에 기록합니다.
  /// [selections]의 키는 [LetterModuleKey] 값, 값은 선택된 문장 ID입니다.
  static Future<void> record(
    String catId,
    Map<String, String> selections, {
    DateTime? now,
  }) async {
    final ref = now ?? DateTime.now();
    for (final entry in selections.entries) {
      final record = UsageHistoryEntry(
        catId: catId,
        moduleKey: entry.key,
        sentenceId: entry.value,
        usedAt: ref,
      );
      final id = '${catId}_${entry.key}_${ref.microsecondsSinceEpoch}';
      await _safeBox.put(id, record.toMap());
    }
  }

  /// 오래된 기록을 실제로 지워 Box 크기를 관리합니다(선택적 유지보수용 -
  /// 설계서 9.1에 따르면 삭제하지 않고 무시만 해도 되지만, 장기적으로 Box가
  /// 계속 커지는 것을 막기 위해 호출 시점 기준 60일보다 오래된 기록은
  /// 정리합니다).
  static Future<void> pruneOldEntries({DateTime? now}) async {
    final ref = now ?? DateTime.now();
    final cutoff = ref.subtract(const Duration(days: 60));
    final box = _safeBox;
    final keysToRemove = <dynamic>[];
    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw == null) continue;
      final entry = UsageHistoryEntry.fromMap(
        Map<dynamic, dynamic>.from(raw as Map),
      );
      if (entry.usedAt.isBefore(cutoff)) keysToRemove.add(key);
    }
    if (keysToRemove.isNotEmpty) {
      await box.deleteAll(keysToRemove);
    }
  }
}
