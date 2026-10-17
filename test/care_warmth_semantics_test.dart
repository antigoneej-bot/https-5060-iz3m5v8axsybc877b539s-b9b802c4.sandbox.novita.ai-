import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/models/cat_care_state.dart';
import 'package:flutter_app/models/letter_entry.dart';
import 'package:flutter_app/services/cat_care_service.dart';
import 'package:flutter_app/services/emotion_summary_service.dart';
import 'package:flutter_app/services/temperature_insight_service.dart';
import 'package:flutter_app/data/cat_flavor_text.dart';

CatCareState stateAt(int value) => CatCareState(
  temperature: value,
  fedToday: false,
  wateredToday: false,
  bathedToday: false,
  cleanedToday: false,
  companionCatId: 'sad',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'earning a point resets warmth but never says the user deteriorated',
    () async {
      SharedPreferences.setMockInitialValues({
        'warmth_test_care_temperature': 99,
        'warmth_test_care_points': 2,
      });
      CatCareService.setCurrentUser('warmth_test');
      final (warmth, points) = await CatCareService.adjustBonusTemperature(
        1,
        isPremium: true,
      );
      expect((warmth, points), (0, 3));
      final insight = TemperatureInsightService.analyze([
        MapEntry(DateTime(2026, 10, 15), 99),
        MapEntry(DateTime(2026, 10, 16), warmth),
      ])!;
      expect(insight.stateDescription, contains('감정이나 심리 상태를 측정한 점수가 아니에요'));
      expect(insight.stateDescription, contains('포인트를 받고 0부터 다시 쌓아요'));
      expect(insight.stateDescription, contains('마음이 나빠졌다는 뜻은 아니에요'));
      expect(stateAt(warmth).moodLabel, '온기를 쌓는 중이에요');
      expect(TemperatureInsightService.tierFor(warmth).label, '0~33');
      final history = await CatCareService.getTempHistory();
      expect(history.last.value, 0);
      expect(await CatCareService.getPoints(), 3);
    },
  );

  test(
    'all activity ranges and daily cat lines avoid tired/recovery judgments',
    () {
      for (var value = 0; value <= 100; value++) {
        final state = stateAt(value);
        final insight = TemperatureInsightService.analyze([
          MapEntry(DateTime(2026, 10, 16), value),
        ])!;
        expect(state.moodLabel, contains('온기'));
        expect(insight.bandLabel, startsWith('평균 온기'));
        expect(
          TemperatureInsightService.tierFor(value).label,
          matches(RegExp(r'^\d+~\d+$')),
        );
        for (var day = 1; day <= 31; day++) {
          final line = catFlavorText(
            state.moodState,
            now: DateTime(2026, 10, day),
          );
          expect(line, isNot(contains('회복하는 시간')));
          expect(line, isNot(contains('지쳤')));
          expect(line, isNot(contains('몸이 조금 무겁')));
        }
      }
    },
  );

  test('self-reported emotion counts remain separate from activity values', () {
    final letters = [
      LetterEntry(
        id: 'sad',
        catId: 'sad',
        date: DateTime(2026, 10, 15),
        letterText: '오늘은 슬퍼요.',
      ),
      LetterEntry(
        id: 'joy',
        catId: 'joyful',
        date: DateTime(2026, 10, 16),
        letterText: '오늘은 기뻐요.',
      ),
    ];
    final expected = EmotionSummaryService.frequency(letters);
    for (final values in [
      [99, 0],
      [0, 100],
    ]) {
      TemperatureInsightService.analyze([
        MapEntry(DateTime(2026, 10, 15), values[0]),
        MapEntry(DateTime(2026, 10, 16), values[1]),
      ]);
      expect(EmotionSummaryService.frequency(letters), expected);
      expect(expected, {'sad': 1, 'joyful': 1});
    }
  });
}
