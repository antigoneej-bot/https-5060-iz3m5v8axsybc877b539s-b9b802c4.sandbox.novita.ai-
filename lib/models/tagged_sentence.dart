import 'letter_tags.dart';

/// 문장 마스터 데이터 한 줄 (설계서 11.1 참고).
/// 사용자별로 바뀌지 않는 정적 데이터라, 이 클래스의 인스턴스들은
/// `letter_sentence_pools.dart`에 const 리스트로 내장됩니다.
class TaggedSentence {
  final String id;
  final String moduleKey; // LetterModuleKey 값 중 하나
  final String text;
  final SentenceTags tags;

  const TaggedSentence({
    required this.id,
    required this.moduleKey,
    required this.text,
    this.tags = const SentenceTags(),
  });
}
