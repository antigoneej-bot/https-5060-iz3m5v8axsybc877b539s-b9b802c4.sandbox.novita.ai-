/// 유료(Basic 구독) 캐릭터 → 가장 가까운 무료 캐릭터(들) 매핑.
///
/// 무료 사용자가 유료 캐릭터를 선택하려고 하면, 곧바로 결제창으로 보내지
/// 않고 반드시 이 매핑에 있는 가장 가까운 무료 캐릭터를 대안으로 안내합니다.
/// (기획 요구사항: "유료 캐릭터를 못 고르게 막는 느낌"이 아니라 "지금도
/// 충분히 표현할 방법이 있다"는 안내를 항상 함께 제공)
///
/// 각 유료 캐릭터 id에 대해 1~2개의 무료 캐릭터 id를 후보로 두며, 화면에서는
/// 첫 번째 후보를 기본으로 보여주고 두 번째 후보가 있다면 "또는" 형태로
/// 함께 제시합니다.
library;

const Map<String, List<String>> alternativeEmotionMapping = {
  'guilty': ['selfCritical'], // 죄책감 → 자책
  'dread': ['anxious'], // 두려움 → 불안
  'hurtFeelings': ['sad', 'sulky'], // 서운함 → 슬픈 또는 삐친
  'inferior': ['jealous', 'selfCritical'], // 열등감 → 질투 또는 자책
  'cynical': ['indifferent'], // 냉소 → 무심한
  'envious': ['jealous'], // 시기 → 질투
  'openHearted': ['vulnerable', 'hesitant'], // 취약함 인정 → 다친 또는 망설임
  'creative': ['curious'], // 창의성 → 호기심
  'leaderly': ['proud'], // 리더십 → 당당한
  'convicted': ['proud', 'content'], // 확신 → 당당한 또는 만족
};

/// 유료 캐릭터 id로 대안 무료 캐릭터 id 목록을 반환합니다.
/// 매핑에 없는 id라면 빈 목록을 반환합니다.
List<String> alternativeFreeCatIdsFor(String premiumCatId) =>
    alternativeEmotionMapping[premiumCatId] ?? const [];
