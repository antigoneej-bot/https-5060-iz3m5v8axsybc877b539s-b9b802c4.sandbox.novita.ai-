import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/emotion_entry.dart';

/// 계정별 감정기록(하루 감정 + 강도 + 메모)을 저장하고,
/// 월간 리포트가 이미 확인되었는지 여부도 함께 관리합니다.
class EmotionService {
  static String _uid = 'guest';
  static Box? _box;

  static Future<void> setCurrentUser(String userId) async {
    if (_uid == userId && _box != null && _box!.isOpen) return;
    _uid = userId;
    if (_box != null && _box!.isOpen) {
      await _box!.close();
    }
    _box = await Hive.openBox('emotion_entries_$_uid');
  }

  static Future<void> clearCurrentUser() async {
    if (_box != null && _box!.isOpen) {
      await _box!.close();
    }
    _box = null;
    _uid = 'guest';
  }

  static Box get _b {
    if (_box == null || !_box!.isOpen) {
      throw Exception('EmotionService: 사용자가 설정되지 않았습니다 (setCurrentUser 먼저 호출)');
    }
    return _box!;
  }

  static Future<void> saveEntry(EmotionEntry entry) async {
    await _b.put(entry.id, entry.toMap());
  }

  static Future<void> deleteEntry(String id) async {
    await _b.delete(id);
  }

  static List<EmotionEntry> getAllEntries() {
    final entries = _b.values
        .map((e) => EmotionEntry.fromMap(Map<dynamic, dynamic>.from(e as Map)))
        .toList();
    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  static List<EmotionEntry> getEntriesForMonth(int year, int month) {
    return getAllEntries()
        .where((e) => e.date.year == year && e.date.month == month)
        .toList();
  }

  /// 오늘 이미 기록했는지 확인 (하루 여러 번 기록 가능하지만, 홈 화면 CTA 문구용)
  static bool hasRecordedToday() {
    final now = DateTime.now();
    return getAllEntries().any(
      (e) =>
          e.date.year == now.year &&
          e.date.month == now.month &&
          e.date.day == now.day,
    );
  }

  // ---- 월간 리포트 열람 여부 (계정별, SharedPreferences) ----
  static String get _lastSeenReportKey => '${_uid}_last_seen_monthly_report';

  /// "yyyy-MM" 형식의 리포트를 이미 확인했는지 여부
  static Future<bool> hasSeenReport(String yearMonthKey) async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getStringList(_lastSeenReportKey) ?? [];
    return seen.contains(yearMonthKey);
  }

  static Future<void> markReportSeen(String yearMonthKey) async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getStringList(_lastSeenReportKey) ?? [];
    if (!seen.contains(yearMonthKey)) {
      await prefs.setStringList(_lastSeenReportKey, [...seen, yearMonthKey]);
    }
  }
}
