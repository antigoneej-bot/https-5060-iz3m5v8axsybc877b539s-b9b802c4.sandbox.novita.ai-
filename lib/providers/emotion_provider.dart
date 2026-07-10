import 'package:flutter/material.dart';
import '../models/emotion_entry.dart';
import '../models/monthly_report.dart';
import '../services/emotion_service.dart';
import '../services/monthly_report_service.dart';
import '../services/sound_service.dart';

/// 감정기록 + 월간 리포트 상태를 관리하는 Provider
class EmotionProvider extends ChangeNotifier {
  List<EmotionEntry> entries = [];
  bool isLoading = true;

  /// 지난달 리포트가 아직 확인되지 않았다면 true (홈 화면 알림 배너용)
  bool hasNewReport = false;
  String? newReportKey;

  Future<void> load() async {
    isLoading = true;
    notifyListeners();
    entries = EmotionService.getAllEntries();
    await _checkNewReport();
    isLoading = false;
    notifyListeners();
  }

  Future<void> _checkNewReport() async {
    final now = DateTime.now();
    // 지난달 리포트를 대상으로 확인 (한 달이 마무리된 시점 기준)
    final lastMonthDate = DateTime(now.year, now.month - 1, 1);
    final lastMonthEntries = entries
        .where(
          (e) =>
              e.date.year == lastMonthDate.year &&
              e.date.month == lastMonthDate.month,
        )
        .toList();
    if (lastMonthEntries.isEmpty) {
      hasNewReport = false;
      newReportKey = null;
      return;
    }
    final key =
        '${lastMonthDate.year}-${lastMonthDate.month.toString().padLeft(2, '0')}';
    final seen = await EmotionService.hasSeenReport(key);
    hasNewReport = !seen;
    newReportKey = key;
  }

  Future<void> markReportSeen(String key) async {
    await EmotionService.markReportSeen(key);
    if (newReportKey == key) {
      hasNewReport = false;
    }
    notifyListeners();
  }

  bool get hasRecordedToday {
    final now = DateTime.now();
    return entries.any(
      (e) =>
          e.date.year == now.year &&
          e.date.month == now.month &&
          e.date.day == now.day,
    );
  }

  Future<void> addEntry({
    required EmotionType emotion,
    required int intensity,
    String memo = '',
  }) async {
    final entry = EmotionEntry(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      date: DateTime.now(),
      emotion: emotion,
      intensity: intensity,
      memo: memo,
    );
    await EmotionService.saveEntry(entry);
    entries = EmotionService.getAllEntries();
    await SoundService().playChime();
    notifyListeners();
  }

  Future<void> deleteEntry(String id) async {
    await EmotionService.deleteEntry(id);
    entries = EmotionService.getAllEntries();
    notifyListeners();
  }

  MonthlyEmotionReport reportFor(int year, int month) {
    final monthEntries = entries
        .where((e) => e.date.year == year && e.date.month == month)
        .toList();
    return MonthlyReportService.buildReport(
      year: year,
      month: month,
      monthEntries: monthEntries,
    );
  }

  /// 감정기록이 존재하는 (년,월) 목록 - 최신순
  List<(int, int)> get availableMonths {
    final set = <(int, int)>{};
    for (final e in entries) {
      set.add((e.date.year, e.date.month));
    }
    final list = set.toList()
      ..sort((a, b) {
        final ai = a.$1 * 12 + a.$2;
        final bi = b.$1 * 12 + b.$2;
        return bi.compareTo(ai);
      });
    return list;
  }

  void reset() {
    entries = [];
    hasNewReport = false;
    newReportKey = null;
    isLoading = true;
    notifyListeners();
  }
}
