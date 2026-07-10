/// 한국어 조사(은/는) 자동 선택 유틸리티.
/// 이름의 마지막 글자에 받침이 있으면 '은', 없으면 '는'을 반환합니다.
/// (한글이 아닌 경우 기본값으로 '는'을 사용합니다)
String topicParticle(String word) {
  if (word.isEmpty) return '는';
  final lastChar = word[word.length - 1];
  final code = lastChar.codeUnitAt(0);
  const hangulBase = 0xAC00; // '가'
  const hangulEnd = 0xD7A3; // '힣'
  if (code < hangulBase || code > hangulEnd) return '는';
  final offset = code - hangulBase;
  final hasBatchim = (offset % 28) != 0;
  return hasBatchim ? '은' : '는';
}

/// 한국어 조사(이/가) 자동 선택 유틸리티. (필요 시 확장용)
String subjectParticle(String word) {
  if (word.isEmpty) return '가';
  final lastChar = word[word.length - 1];
  final code = lastChar.codeUnitAt(0);
  const hangulBase = 0xAC00;
  const hangulEnd = 0xD7A3;
  if (code < hangulBase || code > hangulEnd) return '가';
  final offset = code - hangulBase;
  final hasBatchim = (offset % 28) != 0;
  return hasBatchim ? '이' : '가';
}
