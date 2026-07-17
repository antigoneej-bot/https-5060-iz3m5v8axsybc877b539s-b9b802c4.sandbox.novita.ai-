import 'dart:math';
import '../models/letter_context.dart';
import '../models/letter_tags.dart';
import 'tag_matcher.dart';

/// 고양이의 오늘 감정(⑦ 모듈, 설계서 10장)을 가중 랜덤으로 뽑습니다.
///
/// 완전 랜덤이 아니라 사용자 상태(연속방문, 명상 성공, 특별한 날, 성장단계)에
/// 살짝 반응하도록 기본 가중치에 보너스를 더한 뒤 뽑습니다.
class CatMoodPicker {
  static const Map<CatMoodTag, int> _baseWeights = {
    CatMoodTag.good: 20,
    CatMoodTag.sleepy: 15,
    CatMoodTag.worried: 15,
    CatMoodTag.cheer: 15,
    CatMoodTag.excited: 15,
    CatMoodTag.playful: 10,
    CatMoodTag.quiet: 10,
  };

  static CatMoodTag pick(
    LetterContext ctx,
    DateTime now, {
    Random? random,
  }) {
    final rng = random ?? Random();
    final weights = <CatMoodTag, int>{..._baseWeights};

    if (ctx.visitStreak >= 3) {
      weights[CatMoodTag.good] = (weights[CatMoodTag.good] ?? 0) + 10;
    }
    if (timeTagFor(now) == TimeTag.night) {
      weights[CatMoodTag.sleepy] = (weights[CatMoodTag.sleepy] ?? 0) + 10;
    }
    if (ctx.hasNegativeStreak) {
      weights[CatMoodTag.worried] = (weights[CatMoodTag.worried] ?? 0) + 10;
    }
    if (ctx.meditationSucceededYesterday) {
      weights[CatMoodTag.cheer] = (weights[CatMoodTag.cheer] ?? 0) + 10;
    }
    if (specialDayTagFor(now) != null) {
      // 신남 가중치를 대폭 상승(설계서 10장: 60%대로).
      weights[CatMoodTag.excited] = 45;
    }
    if (ctx.growthStage == GrowthTag.teen) {
      weights[CatMoodTag.playful] = (weights[CatMoodTag.playful] ?? 0) + 10;
    }
    if (ctx.growthStage == GrowthTag.adult) {
      weights[CatMoodTag.quiet] = (weights[CatMoodTag.quiet] ?? 0) + 10;
    }

    final total = weights.values.fold<int>(0, (a, b) => a + b);
    var roll = rng.nextInt(total);
    for (final entry in weights.entries) {
      if (roll < entry.value) return entry.key;
      roll -= entry.value;
    }
    return CatMoodTag.good; // 안전장치(도달하지 않아야 정상이지만 대비)
  }
}
