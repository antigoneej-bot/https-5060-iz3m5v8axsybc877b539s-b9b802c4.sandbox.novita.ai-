import '../models/letter_context.dart';
import 'letter_composer_engine.dart';
import 'reply_generator.dart';

/// [ReplyGenerator]의 현재(Phase 2) 구현체 - 8모듈 태그 조합 방식.
///
/// 내부적으로 [LetterComposerEngine]에 그대로 위임합니다. 이 클래스가 얇은
/// 래퍼로 존재하는 이유는, 6개월 후 `AiReplyGenerator`가 추가되어도 호출부
/// (예: [buildReplyText])가 구체 구현을 몰라도 되도록 하기 위함입니다.
class TemplateReplyGenerator implements ReplyGenerator {
  final LetterComposerEngine _engine;

  TemplateReplyGenerator({LetterComposerEngine? engine})
    : _engine = engine ?? LetterComposerEngine();

  @override
  Future<String> generate(LetterContext ctx) => _engine.compose(ctx);
}
