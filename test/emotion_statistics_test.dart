import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/models/letter_entry.dart';
import 'package:flutter_app/services/weekly_shadow_map_service.dart';
import 'package:flutter_app/services/emotion_summary_service.dart';
import 'package:flutter_app/data/shadow_cats_data.dart';
import 'package:flutter_app/data/cat_browse_groups.dart';

LetterEntry record(String id, DateTime date, [String cat = 'sad']) =>
    LetterEntry(id: id, catId: cat, date: date, letterText: '기록');

void main() {
  test('March comparison does not include March in February results', () {
    final history = [record('feb', DateTime(2026, 2, 28)), record('mar', DateTime(2026, 3, 1))];
    final (current, previous) = WeeklyShadowMapService.compareThisMonthVsLastMonth(history, now: DateTime(2026, 3, 31));
    expect(current['sad'], 1);
    expect(previous['sad'], 1);
  });
  test('leap February and year boundary remain in previous month', () {
    final history = [record('leap', DateTime(2024, 2, 29)), record('mar', DateTime(2024, 3, 1))];
    final (_, previous) = WeeklyShadowMapService.compareThisMonthVsLastMonth(history, now: DateTime(2024, 3, 31));
    expect(previous['sad'], 1);
    final (_, december) = WeeklyShadowMapService.compareThisMonthVsLastMonth(
      [record('dec', DateTime(2025, 12, 31)), record('jan', DateTime(2026, 1, 1))], now: DateTime(2026, 1, 31));
    expect(december['sad'], 1);
  });
  test('previous quarter does not cross into current quarter', () {
    final (_, previous) = WeeklyShadowMapService.compareThisQuarterVsLastQuarter(
      [record('march', DateTime(2026, 3, 31)), record('april', DateTime(2026, 4, 1))], now: DateTime(2026, 6, 30));
    expect(previous['sad'], 1);
  });
  test('calendar month excludes previous month; counts days separately', () {
    final selected = EmotionSummaryService.entries([
      record('old', DateTime(2026, 8, 31)),
      record('a', DateTime(2026, 9, 1, 8)),
      record('b', DateTime(2026, 9, 1, 20), 'joyful'),
      record('c', DateTime(2026, 9, 2)),
    ], DateTime(2026, 9, 1), DateTime(2026, 9, 2));
    expect(selected.length, 3);
    expect(EmotionSummaryService.recordedDays(selected), 2);
    expect(EmotionSummaryService.ranked(selected).first.value, 2);
  });
  test('top-three ratios retain denominator of all records', () {
    final ratios = WeeklyShadowMapService.topEmotionsRatio({'sad': 4, 'joyful': 3, 'angry': 2, 'weary': 1});
    expect(ratios.first.$3, .4);
    expect(ratios.fold<double>(0, (sum, entry) => sum + entry.$3), closeTo(.9, .0001));
  });
  test('every catalog cat is reachable in exactly one browse group', () {
    final grouped = catBrowseGroups.values.expand((ids) => ids).toList();
    expect(grouped.toSet().length, grouped.length);
    expect(grouped.toSet(), shadowCats.map((cat) => cat.id).toSet());
  });
}
