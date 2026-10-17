import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/models/letter_entry.dart';
import 'package:flutter_app/services/unified_emotion_summary_service.dart';

LetterEntry letter(String id, String emotion, DateTime date) =>
    LetterEntry(id: id, catId: emotion, date: date, letterText: '편지 $id');

void main() {
  final day = DateTime(2026, 10, 16);

  test('letters and diaries retain original catalogue, source and notes', () {
    final records = UnifiedEmotionSummaryService.read(
      letters: [letter('a', 'angry', day)],
      gardenDiary: [
        {'date': '2026-10-16', 'emotionType': 'anger', 'note': '정원 일기'},
      ],
    );
    final summary = UnifiedEmotionSummaryService.period(records, day, day);
    expect(summary.records, hasLength(2));
    expect(summary.letterCount, 1);
    expect(summary.gardenCount, 1);
    expect(summary.recordedDays, 1);
    expect(summary.ranked.map((e) => e.emotion.displayLabel).toSet(), {
      '분노 · 편지',
      '화 · 정원 일기',
    });
    expect(records.map((e) => e.note), containsAll(['편지 a', '정원 일기']));
  });

  test('deduplicates persisted IDs but retains distinct legacy sessions', () {
    final records = UnifiedEmotionSummaryService.read(
      letters: [letter('a', 'sad', day), letter('a', 'sad', day)],
      gardenDiary: [
        {'id': 'a', 'date': '2026-10-16', 'emotionType': 'sadness'},
        {'id': 'a', 'date': '2026-10-16', 'emotionType': 'sadness'},
        {'date': '2026-10-16', 'emotionType': 'sadness'},
        {'date': '2026-10-16', 'emotionType': 'sadness'},
      ],
    );
    // A letter ID and a garden ID are not the same event.
    expect(records, hasLength(4));
    expect(records.map((e) => e.id).toSet(), hasLength(4));
  });

  test('never invents intensity from missing values or activity rewards', () {
    final records = UnifiedEmotionSummaryService.read(
      letters: [letter('a', 'sad', day)],
      gardenDiary: [
        {'date': '2026-10-16', 'emotionType': 'sadness', 'intensity': 2},
        {'date': '2026-10-16', 'emotionType': 'joy', 'intensity': 4.0},
        {
          'date': '2026-10-16',
          'emotionType': 'calm',
          'eatenCount': 200,
          'temperature': 100,
        },
        for (final invalid in [0, 6, 2.5, '5', double.nan, double.infinity])
          {'date': '2026-10-16', 'emotionType': 'worry', 'intensity': invalid},
      ],
    );
    final summary = UnifiedEmotionSummaryService.period(records, day, day);
    expect(summary.intensities, containsAll([2, 4]));
    expect(summary.intensities, hasLength(2));
    expect(summary.averageIntensity, 3);
    expect(
      records
          .singleWhere((e) => e.source == EmotionRecordSource.letter)
          .intensity,
      isNull,
    );
  });

  test('unknown historical feelings do not fall back to sad or hate', () {
    final records = UnifiedEmotionSummaryService.read(
      letters: [letter('a', 'removed_cat', day)],
      gardenDiary: [
        {'date': '2026-10-16', 'emotionType': 'removed_emotion'},
      ],
    );
    expect(
      records.map((e) => e.label),
      containsAll(['이전 감정 (removed_cat)', '이전 감정 (removed_emotion)']),
    );
  });

  test('excludes invalid dates, retains legacy dates and ISO times', () {
    final records = UnifiedEmotionSummaryService.read(
      letters: [],
      gardenDiary: [
        for (final date in [
          '2026-2-31',
          '2026-0-16',
          '2026-13-16',
          'bad',
          4,
          null,
        ])
          {'date': date, 'emotionType': 'calm'},
        {'date': '2026-2-3', 'emotionType': 'calm'},
        {'date': '2026-10-16T10:30:00', 'emotionType': 'calm'},
      ],
    );
    expect(records, hasLength(2));
    expect(records.first.hasTime, isFalse);
    expect(records.last.hasTime, isTrue);
    expect(records.last.date.hour, 10);
  });

  test('periods include both boundary days, not future or earlier records', () {
    final records = UnifiedEmotionSummaryService.read(
      letters: [
        letter('outside', 'sad', DateTime(2026, 10, 11, 23, 59)),
        letter('first', 'sad', DateTime(2026, 10, 12)),
        letter('last', 'sad', DateTime(2026, 10, 16, 23, 59)),
        letter('future', 'sad', DateTime(2026, 10, 17)),
      ],
      gardenDiary: [
        {'date': '2026-10-16', 'emotionType': 'calm'},
      ],
    );
    final summary = UnifiedEmotionSummaryService.period(
      records,
      DateTime(2026, 10, 12),
      day,
    );
    expect(summary.records, hasLength(3));
    expect(summary.recordedDays, 2);
    expect(summary.letterCount, 2);
    expect(summary.ranked.first.count, 2);
    expect(summary.averageIntensity, isNull);
  });

  test('reading never writes or mutates the original diary and letters', () {
    final letters = [letter('a', 'sad', day)];
    final diary = <Map<String, dynamic>>[
      {'date': '2026-10-16', 'emotionType': 'sadness', 'intensity': 3},
    ];
    final records = UnifiedEmotionSummaryService.read(
      letters: letters,
      gardenDiary: diary,
    );
    expect(letters.single.catId, 'sad');
    expect(diary.single, {
      'date': '2026-10-16',
      'emotionType': 'sadness',
      'intensity': 3,
    });
    expect(() => records.clear(), throwsUnsupportedError);
  });
}
