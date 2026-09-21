/// Conservative rules for short, direct questions. This is not a language model.
/// Quoted speech, long letters and explicit requests to just listen stay on the
/// existing diary path. Unknown facts and another person's feelings are never
/// asserted as answers.
class ReplyIntent {
  final String id;
  final List<String> responses;
  const ReplyIntent(this.id, this.responses);

  static ReplyIntent? detect(String text) {
    final value = text.trim();
    if (value.isEmpty || value.length > 300) return null;
    if (RegExp(r'["“”「」『』]|라고|냐고|대사|소설|예를 들|가정해').hasMatch(value)) {
      return null;
    }
    if (RegExp(r'그냥\s*들어|조언.*(말|싫|필요\s*없)|해결책.*(말|싫|필요\s*없)|묻지\s*마|질문.*(말|싫)').hasMatch(value)) {
      return null;
    }
    // A question mark by itself in the middle of a diary is not enough.
    final question = RegExp(r'[?？]\s*$|(?:건가|걸까|일까|될까|한가|하나|됐나|되나|나요|인가요|할지|어쩌지)[.!\s]*$').hasMatch(value);
    if (!question) return null;

    if (RegExp(r'해결|고쳐|고친|고쳤|수정|정상.*작동').hasMatch(value) &&
        RegExp(r'건가|됐|되었|된\s*거|된\s*건|한\s*거|한\s*건|된\s*걸|했|맞|완료|끝').hasMatch(value) &&
        !RegExp(r'어떻게|방법|왜|언제').hasMatch(value)) {
      // A named problem needs an observation, not a request to name it again.
      final named = RegExp(r'앱|오류|답장|로그인|결제|버그|설치').hasMatch(value);
      return named ? const ReplyIntent('question_resolution_named', [
        '정말 해결됐는지 확인하고 싶은 거구나. 내가 앱의 상태를 직접 볼 수는 없어서, 해결됐다고 단정할 수는 없어. 전에 안 되던 동작을 다시 해봤을 때는 어땠어?',
        '고쳐졌다는 말보다 실제로 잘되는지 확인하고 싶겠네. 지금은 결과를 알 수 없으니, 같은 동작을 다시 했을 때 문제가 또 생기는지 알려줄래?',
        '해결 여부가 궁금한 거구나. 여기서는 실행 결과를 볼 수 없어서 확답하기 어려워. 전에는 안 됐던 부분이 지금은 어떻게 달라졌어?',
      ]) : const ReplyIntent('question_resolution', [
        '문제가 정말 해결된 건지 확인하고 싶은 거구나. 어떤 문제였는지 조금만 더 알려줄래?',
        '해결됐는지 아직 확인하고 싶은 거네. 어떤 일이었고, 지금은 어떻게 달라졌는지 들려줄래?',
        '정말 끝난 건지 묻는 말이구나. 이 편지만으로는 해결 여부를 알 수 없어서, 어떤 문제를 말하는 건지 알고 싶어.',
      ]);
    }
    if (RegExp(r'내가|나는|나만|내\s*잘못').hasMatch(value) &&
        RegExp(r'잘못|이상|못난|문제인|문제일|문제야').hasMatch(value)) {
      return const ReplyIntent('question_self_judgment', [
        '네가 잘못한 건지 묻고 있구나. 어떤 일이 있었는지 모르는 채 네 탓이라고 결론 내리고 싶지는 않아. 마음에 걸리는 장면 하나를 들려줄래?',
        '이 일 때문에 너 자신까지 판단하게 되는 걸까. 누가 잘못했는지 서둘러 정하기 전에, 어떤 일이 있었는지부터 듣고 싶어.',
        '그 질문에 바로 네가 잘못했다고도, 아무 잘못 없다고도 말할 수는 없어. 어떤 말이나 행동이 마음에 남아 있어?',
      ]);
    }
    if (RegExp(r'나를|날\s|내게|나한테').hasMatch(value) &&
        RegExp(r'싫어|좋아|미워|사랑').hasMatch(value)) {
      return const ReplyIntent('question_other_mind', [
        '상대가 너를 어떻게 생각하는지 궁금하구나. 그 사람의 마음을 내가 대신 알 수는 없어. 어떤 말이나 행동 때문에 그렇게 생각했어?',
        '상대의 마음이 궁금해진 이유가 있을 것 같아. 마음을 단정하기보다, 네가 실제로 듣거나 본 일을 먼저 들려줄래?',
        '그 사람이 어떤 마음인지 확답할 수는 없어. 다만 너에게 남은 말이나 행동은 함께 살펴볼 수 있어. 어떤 일이 있었어?',
      ]);
    }
    if (RegExp(r'어떻게\s*(해야|하면|하지|할)|어쩌지|어쩌면|방법.*(있|없)|뭘\s*해야').hasMatch(value)) {
      return const ReplyIntent('question_next_step', [
        '어떻게 하면 좋을지 함께 생각하고 싶은 거구나. 지금 가장 바꾸고 싶은 부분 하나를 알려줄래? 그 일에 맞는 작은 방법부터 찾아보자.',
        '방법을 찾고 있구나. 상황을 모른 채 쉬거나 참으라고 말하고 싶지는 않아. 지금 어디에서 막혔는지 하나만 들려줄래?',
        '다음에 뭘 해야 할지 고민되는 거네. 이미 해본 일과 아직 어려운 부분을 알려주면, 같은 방법을 되풀이하지 않고 생각해볼 수 있겠어.',
      ]);
    }
    // Only short ambiguous confirmation questions use this fallback. Emotional
    // rhetorical questions and factual questions retain the existing path.
    if (value.length <= 80 &&
        RegExp(r'^(이거|그거|이게|그게|그럼|그러면|결국|정말|진짜)').hasMatch(value) &&
        RegExp(r'맞|괜찮|된|되는|한\s*건|한\s*거').hasMatch(value)) {
      return const ReplyIntent('question_context', [
        '무엇을 확인하고 싶은지 조금 더 알고 싶어. 어떤 일을 두고 묻는 건지 한 가지만 들려줄래?',
        '확인하고 싶은 일이 있구나. 이 말만으로는 상황을 알기 어려워서, 어떤 일이 있었는지 조금 더 듣고 싶어.',
        '바로 그렇다고 답하기에는 내가 아는 내용이 적어. 무엇에 관한 질문인지 알려줄래?',
      ]);
    }
    return null;
  }
}
