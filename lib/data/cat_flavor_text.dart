import 'dart:math';
import '../models/cat_care_state.dart';

/// 다마고치식 감성 플레이버 텍스트 - 활동으로 쌓은 돌봄 온기 구간에
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
    '오늘도 함께 정원을 바라볼까요?',
    '잎사귀가 살랑이는 소리를 같이 들어요.',
    '천천히 둘러봐도 좋아요. 곁에 있을게요.',
    '함께 보낸 작은 순간을 기억하고 있어요.',
    '오늘 하루도 애썼어요, 우리 둘 다요.',
  ],
  CatMoodState.recovering: [
    '오늘은 어떤 꽃을 바라보고 싶나요?',
    '잠깐 머물러도 좋아요. 정원은 여기 있어요.',
    '작은 돌봄이 저에게는 큰 씨앗이 돼요.',
    '우리 정원에 새로 모을 온기가 기다리고 있어요.',
    '오늘 하루, 저와 함께 다시 시작해볼까요?',
  ],
};

/// 오늘(날짜 기준) 랜덤으로 고른, 온기 구간에 맞는 플레이버 문장을
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
