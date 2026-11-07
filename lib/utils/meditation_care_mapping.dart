import '../services/cat_care_service.dart';

/// 편지 쓰기 중 선택한 명상 가이드 키를, 마음 돌보기의 '호흡 명상'/'걷기 명상'
/// 임무와 연결합니다. 실제로 호흡법을 실천했다면 breathing 임무를, 움직이는
/// 명상(태극권/걷기/스트레칭 등)을 실천했다면 walking 임무를 자동으로
/// 완료 처리할 수 있게 하기 위한 매핑입니다.
///
/// 이 매핑에 없는 가이드(알아차림/표현하기/감사명상 등)는 breathing/walking
/// 어느 쪽도 자동완료하지 않습니다 - 대신 편지를 쓴 행위 자체는 항상
/// '마음기록'(journaling) 임무로 자동완료됩니다.
CareTask? careTaskForMeditationKey(String? guideKey) {
  if (guideKey == null) return null;
  const breathingKeys = {
    'breathing',
    'boxBreathing',
    '478Breathing',
    'humBreathing',
    'tensionRelease',
    'angerCooling',
  };
  const walkingKeys = {
    'taichi',
    'walkingMeditation',
    'stretching',
    'shoulderRelease',
    'handStretch',
  };
  if (breathingKeys.contains(guideKey)) return CareTask.breathing;
  if (walkingKeys.contains(guideKey)) return CareTask.walking;
  return null;
}
