import 'package:hive_flutter/hive_flutter.dart';
import 'dart:math';
import '../models/memory_entry.dart';
import '../data/memory_keyword_dictionary.dart';
import '../data/memory_recall_templates.dart';
import 'hive_encryption.dart';

/// 고양이 기억 시스템(설계서 6장)의 데이터를 계정별로 관리하는 서비스.
///
/// [BuriedEmotionService]와 동일한 패턴(계정별 Hive Box)을 따릅니다.
/// 편지 텍스트에서 키워드가 감지되면 [MemoryEntry]를 생성해 저장하고,
/// 3/7/14/30일 후 회상 예정일이 도달했는지 매 편지 생성 시 확인합니다.
class CatMemoryService {
  static String _uid = 'guest';
  static Box? _box;

  static Future<void> setCurrentUser(String userId) async {
    if (_uid == userId && _box != null && _box!.isOpen) return;
    _uid = userId;
    if (_box != null && _box!.isOpen) {
      await _box!.close();
    }
    _box = await HiveEncryption.openBox('cat_memories_$_uid');
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
        'CatMemoryService: 사용자가 설정되지 않았습니다 (setCurrentUser 먼저 호출)',
      );
    }
    return _box!;
  }

  static List<MemoryEntry> getAllEntries() {
    final entries = _safeBox.values
        .map((e) => MemoryEntry.fromMap(Map<dynamic, dynamic>.from(e as Map)))
        .toList();
    entries.sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
    return entries;
  }

  static List<MemoryEntry> entriesForCat(String catId) =>
      getAllEntries().where((e) => e.catId == catId).toList();

  /// 편지 텍스트를 검사해 키워드가 감지되면 [MemoryEntry]를 생성해
  /// 저장합니다. 감지되지 않으면 아무 일도 하지 않고 null을 반환합니다.
  static Future<MemoryEntry?> captureIfKeywordFound({
    required String catId,
    required String letterText,
    DateTime? now,
  }) async {
    final keyword = detectMemoryKeyword(letterText);
    if (keyword == null) return null;

    final ref = now ?? DateTime.now();
    final snippet = letterText.trim().length > 40
        ? '${letterText.trim().substring(0, 40)}...'
        : letterText.trim();
    final entry = MemoryEntry(
      id: 'memory_${ref.microsecondsSinceEpoch}',
      catId: catId,
      keyword: keyword,
      originalSnippet: snippet,
      capturedAt: ref,
      recallDueDates: MemoryEntry.computeDueDates(ref),
    );
    await _safeBox.put(entry.id, entry.toMap());
    return entry;
  }

  /// 오늘(now) 회상해도 되는 기억이 있는지 찾습니다. 여러 개가 겹치면
  /// 가장 오래된(capturedAt 기준) 기억 하나만 반환합니다(설계서 6.2 -
  /// "한 편지에는 최대 1개의 기억만 등장").
  static ({MemoryEntry entry, DateTime dueDate})? findDueMemory(
    String catId, {
    DateTime? now,
  }) {
    final ref = now ?? DateTime.now();
    final candidates = <({MemoryEntry entry, DateTime dueDate})>[];
    for (final entry in entriesForCat(catId)) {
      final due = entry.dueDateFor(ref);
      if (due != null) candidates.add((entry: entry, dueDate: due));
    }
    if (candidates.isEmpty) return null;
    candidates.sort(
      (a, b) => a.entry.capturedAt.compareTo(b.entry.capturedAt),
    );
    return candidates.first;
  }

  /// [findDueMemory]로 찾은 기억을 실제 문장으로 렌더링하고, "이미 회상함"
  /// 상태로 기록합니다.
  static Future<String> renderAndMarkRecalled(
    ({MemoryEntry entry, DateTime dueDate}) found, {
    Random? random,
  }) async {
    final stageIndex = found.entry.recallStageIndex(found.dueDate);
    final sentence = pickMemoryRecallSentence(
      stageIndex,
      found.entry.keyword,
      random: random,
    );
    final updated = found.entry.withRecalled(found.dueDate);
    await _safeBox.put(updated.id, updated.toMap());
    return sentence;
  }
}
