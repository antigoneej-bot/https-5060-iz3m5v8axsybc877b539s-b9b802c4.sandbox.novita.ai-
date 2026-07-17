import 'dart:math';
import '../models/cat_care_state.dart';

/// 다마고치식 감성 플레이버 텍스트 - 반려 고양이의 마음 온도 상태(4단계)에
/// 맞춰, 짧고 사랑스러운 한마디를 랜덤으로 보여줍니다. 개발 비용은 낮지만
/// 매일 화면을 열 때마다 조금씩 다른 말을 건네는 것만으로도 살아있는
/// 느낌을 더해줍니다.
///
/// 같은 날 안에서는 같은 문장이 유지되도록(하루 한 번 바뀌는 느낌),
/// [catFlavorText]는 날짜를 시드로 사용합니다.
const Map<CatMoodState, List<String>> _flavorLines = {
  CatMoodState.warm: [
    '오늘도 함께 있어줘서 참 좋아요 🌸',
    '기분이 몽글몽글해요. 당신 덕분이에요.',
    '따뜻한 담요 속에 있는 기분이에요.',
    '오늘은 유난히 다정한 하루네요.',
    '당신 곁이 세상에서 가장 편안해요.',
  ],
  CatMoodState.calm: [
    '오늘은 잔잔한 호수 같은 기분이에요.',
    '별일 없이 평온한 하루, 이대로도 좋아요.',
    '조용히 곁에 있는 것만으로 충분해요.',
    '살랑살랑 기분 좋은 바람이 부는 것 같아요.',
    '느긋하게, 오늘 하루를 함께 보내볼까요?',
  ],
  CatMoodState.tired: [
    '조금 지쳤지만 당신이 있어서 괜찮아요.',
    '오늘은 몸이 조금 무겁네요… 쉬어가도 될까요?',
    '기운이 살짝 없지만 곧 괜찮아질 거예요.',
    '작은 관심이 지금 저에게 큰 힘이 돼요.',
    '오늘 하루도 애썼어요, 우리 둘 다요.',
  ],
  CatMoodState.recovering: [
    '천천히 다시 기운을 모으고 있어요.',
    '지금은 회복하는 시간이에요. 조급해하지 않아도 돼요.',
    '작은 돌봄이 저에게는 큰 씨앗이 돼요.',
    '조금씩 다시 따뜻해지고 있어요. 고마워요.',
    '오늘 하루, 저와 함께 다시 시작해볼까요?',
  ],
};

/// 오늘(날짜 기준) 랜덤으로 고른, 현재 마음 상태에 맞는 플레이버 문장을
/// 반환합니다. 같은 날에는 같은 문장이 유지되어(자정에만 바뀜) 화면을
/// 다시 열 때마다 문장이 어지럽게 바뀌지 않습니다.
String catFlavorText(CatMoodState mood, {DateTime? now}) {
  final lines = _flavorLines[mood] ?? const ['오늘도 함께해줘서 고마워요.'];
  final ref = now ?? DateTime.now();
  final dayKey = ref.year * 1000 + ref.dayOfYearApprox;
  final rng = Random(dayKey + mood.index * 97);
  return lines[rng.nextInt(lines.length)];
}

extension _DayOfYear on DateTime {
  int get dayOfYearApprox {
    final startOfYear = DateTime(year, 1, 1);
    return difference(startOfYear).inDays;
  }
}
