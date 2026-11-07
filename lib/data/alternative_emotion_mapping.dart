/// 유료(Basic 구독) 캐릭터 → 가장 가까운 무료 캐릭터(들) 매핑.
///
/// ⚠️ 현재는 모든 그림자 고양이가 무료로 전환되어(isPremium 캐릭터 없음)
/// 이 매핑이 실제로 트리거되지 않습니다. 추후 유료 캐릭터가 다시 추가될
/// 경우를 위해 함수/구조만 남겨두고, 매핑 내용은 비워둡니다.
library;

const Map<String, List<String>> alternativeEmotionMapping = {};

/// 유료 캐릭터 id로 대안 무료 캐릭터 id 목록을 반환합니다.
/// 매핑에 없는 id라면 빈 목록을 반환합니다.
List<String> alternativeFreeCatIdsFor(String premiumCatId) =>
    alternativeEmotionMapping[premiumCatId] ?? const [];
