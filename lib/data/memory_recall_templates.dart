import 'dart:math';

/// 고양이 기억 회상 템플릿 (설계서 6.3 / 12.4 참고).
///
/// 회상 시점(3/7/14/30일 후)별로 2개씩의 템플릿을 두고, {키워드}를
/// 실제 카테고리명으로 치환해 자연스럽게 삽입합니다.
/// recallStageIndex: 0=3일, 1=7일, 2=14일, 3=30일
const List<List<String>> memoryRecallTemplatesByStage = [
  // +3일 (결과 대기형/진행형)
  [
    '그때 {키워드} 이야기 했었지. 잘 되었으면 좋겠어.',
    '{키워드} 일은 어떻게 됐어? 궁금했어.',
  ],
  // +7일 (회복형/일반형)
  [
    '{키워드}는 좀 괜찮아졌어?',
    '지난주에 말했던 {키워드}, 잘 지나갔어?',
  ],
  // +14일 (여운형/정서 확인형)
  [
    '요즘도 {키워드} 생각 자주 나?',
    '{키워드} 이후로 마음은 좀 어때?',
  ],
  // +30일 (장기 회상형/장기 신뢰형)
  [
    '한 달 전 {키워드} 얘기, 기억하고 있었어.',
    '그때 {키워드} 이야기, 시간이 지나도 잊지 않았어.',
  ],
];

/// [stageIndex](0~3)와 [keyword]에 맞는 회상 문장을 무작위로 하나 골라
/// 치환해서 반환합니다. stageIndex가 범위를 벗어나면 가장 마지막 단계로
/// 안전하게 대체합니다.
String pickMemoryRecallSentence(
  int stageIndex,
  String keyword, {
  Random? random,
}) {
  final rng = random ?? Random();
  final safeIndex = stageIndex.clamp(
    0,
    memoryRecallTemplatesByStage.length - 1,
  );
  final templates = memoryRecallTemplatesByStage[safeIndex];
  final template = templates[rng.nextInt(templates.length)];
  return template.replaceAll('{키워드}', keyword);
}
