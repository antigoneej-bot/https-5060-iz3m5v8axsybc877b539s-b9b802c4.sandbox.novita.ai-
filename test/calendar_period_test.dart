import 'package:flutter_test/flutter_test.dart';
import '../lib/services/emotion_summary_service.dart';

void main() {
  test('calendar weeks keep reflection keys stable from Monday through Sunday', () {
    final monday = DateTime(2026, 9, 7);
    expect(EmotionSummaryService.weekStart(DateTime(2026, 9, 13, 23, 59)), monday);
    expect(EmotionSummaryService.weekStart(DateTime(2026, 9, 14)), DateTime(2026, 9, 14));
    expect(EmotionSummaryService.weekEnd(monday), DateTime(2026, 9, 13));
  });
  test('week crosses a year boundary without changing its key', () {
    expect(EmotionSummaryService.weekStart(DateTime(2027, 1, 1)), DateTime(2026, 12, 28));
    expect(EmotionSummaryService.weekEnd(DateTime(2027, 1, 1)), DateTime(2027, 1, 3));
  });
}
