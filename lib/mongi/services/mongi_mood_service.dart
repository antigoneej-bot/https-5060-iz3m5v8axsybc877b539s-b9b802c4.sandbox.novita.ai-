import 'dart:math';

import '../models/emotion.dart';

/// "몽이의 하루" - 다마고치 요소. 최근 3일간의 [GardenProvider.diaryEntries]만
/// 보고 몽이의 오늘 표정/행동을 계산하는 순수 함수 모음. 새 그림을 그리지
/// 않고, 이미 있는 표정 이미지(idle/happy/jump/cry)를 재활용한다.
///
/// 서버/AI 없이 로컬 데이터 + 룰 기반으로 동작하며, 어떤 함수도 위젯/상태를
/// 건드리지 않는다(테스트 용이, 부작용 없음) - [EmotionInsightService]와 동일한
/// 설계 원칙을 따른다.
///
/// 다국어 지원을 위해 실제로 화면에 보여줄 문구는 여기서 만들지 않고,
/// [MongiMoodKind]라는 "종류"만 계산해서 돌려준다. 실제 문구(한국어/영어)는
/// 화면 쪽에서 [AppLocalizations]를 사용해 그 종류에 맞는 번역 문자열을
/// 골라 붙인다.
class MongiMoodService {
  const MongiMoodService._();

  static DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static DateTime? _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parts = raw.split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  /// 최근 3일(오늘 포함) 동안의 감정 일기만 보고 몽이의 표정/행동 종류를
  /// 계산한다. 데이터가 없으면 [MongiMoodKind.waiting]을 반환한다.
  static MongiMoodResult computeMood({
    required List<Map<String, dynamic>> diaryEntries,
  }) {
    final cutoff = _today.subtract(const Duration(days: 2));
    var positive = 0;
    var negative = 0;
    for (final entry in diaryEntries) {
      final date = _parseDate(entry['date'] as String?);
      if (date == null || date.isBefore(cutoff)) continue;
      final typeName = entry['emotionType'] as String?;
      if (typeName == null) continue;
      if (Emotion.byTypeName(typeName).isPositive) {
        positive++;
      } else {
        negative++;
      }
    }
    final total = positive + negative;

    if (total == 0) {
      return const MongiMoodResult(
        imageAsset: 'assets/mongi/images/cat_idle.png',
        mood: MongiMoodKind.waiting,
      );
    }

    final positiveRatio = positive / total;
    if (positiveRatio >= 0.7) {
      return const MongiMoodResult(
        imageAsset: 'assets/mongi/images/cat_jump.png',
        mood: MongiMoodKind.joyful,
      );
    }
    if (positiveRatio <= 0.3) {
      return const MongiMoodResult(
        imageAsset: 'assets/mongi/images/cat_cry.png',
        mood: MongiMoodKind.heavy,
      );
    }
    return const MongiMoodResult(
      imageAsset: 'assets/mongi/images/cat_idle.png',
      mood: MongiMoodKind.calm,
    );
  }

  /// 하루에 한 번, 랜덤하게 뽑히는 사소하고 귀여운 이스터에그 대사의 개수.
  /// 실제 문구는 `homeEasterEgg0` ~ `homeEasterEgg{easterEggCount - 1}` 키로
  /// ARB 파일에 번역되어 있다.
  static const int easterEggCount = 12;

  /// 오늘 뽑힐 이스터에그 대사의 인덱스(0 ~ [easterEggCount] - 1)를 랜덤으로
  /// 고른다. 실제 문구로 바꾸는 건 화면 쪽에서 AppLocalizations로 처리한다.
  static int randomEasterEggIndex() {
    final rand = Random();
    return rand.nextInt(easterEggCount);
  }
}

/// 몽이의 오늘 기분 종류. 실제 문구는 화면에서 [AppLocalizations]를 통해
/// 언어별로 골라 붙인다.
enum MongiMoodKind { waiting, joyful, heavy, calm }

/// [MongiMoodService.computeMood]의 계산 결과.
class MongiMoodResult {
  /// 오늘 보여줄 몽이 표정 이미지 경로(기존 에셋 재사용).
  final String imageAsset;

  /// 오늘 몽이의 기분 종류 - 실제 설명 문구는 화면에서 언어에 맞게 붙인다.
  final MongiMoodKind mood;

  const MongiMoodResult({required this.imageAsset, required this.mood});
}
