import '../models/letter_context.dart';

/// 그림자 고양이의 답장을 생성하는 방식을 추상화한 인터페이스(설계서 13.2).
///
/// 지금은 [TemplateReplyGenerator](8모듈 조합 방식)만 존재하지만, 6개월 후
/// AI를 도입하면 동일한 인터페이스를 구현하는 `AiReplyGenerator`로 교체할 수
/// 있습니다. [LetterContext]는 두 구현체가 공유하는 입력 규격입니다.
abstract class ReplyGenerator {
  Future<String> generate(LetterContext ctx);
}
