/// 고양이 기억 시스템의 키워드 동의어 사전 (설계서 6.1 / 12.4 참고).
///
/// 편지 텍스트에서 아래 12개 카테고리 중 하나라도 감지되면
/// [MemoryEntry]가 생성됩니다. AI 없이 동작하는 단순 사전 매칭 방식입니다.
const Map<String, List<String>> memoryKeywordSynonyms = {
  '면접': ['면접', '인터뷰', '취업 면접', '최종 면접'],
  '시험': ['시험', '시험공부', '모의고사', '자격증 시험'],
  '감기': ['감기', '몸살', '콜록', '열이 나', '코감기'],
  '여행': ['여행', '휴가', '출장', '여행지', '여행 계획'],
  '생일': ['생일', '생일파티', '생일 축하'],
  '퇴사': ['퇴사', '그만두다', '사직서', '퇴직'],
  '입사': ['입사', '첫 출근', '취업', '새 직장'],
  '이사': ['이사', '이삿짐', '새 집', '집 구하기'],
  '반려동물': ['강아지', '고양이', '반려동물', '동물병원'],
  '가족': ['엄마', '아빠', '부모님', '형', '언니', '동생', '가족'],
  '친구': ['친구', '절친', '동창', '오랜 친구'],
  '연애': ['연애', '남자친구', '여자친구', '소개팅', '이별'],
};

/// [text] 안에서 감지되는 첫 번째 카테고리 키워드를 반환합니다(없으면 null).
/// 여러 카테고리가 동시에 감지되면, 사전 선언 순서상 먼저 나오는 카테고리를
/// 우선합니다(모호성 회피를 위한 단순 규칙).
String? detectMemoryKeyword(String text) {
  if (text.trim().isEmpty) return null;
  for (final category in memoryKeywordSynonyms.keys) {
    final synonyms = memoryKeywordSynonyms[category]!;
    for (final synonym in synonyms) {
      if (text.contains(synonym)) {
        return category;
      }
    }
  }
  return null;
}
