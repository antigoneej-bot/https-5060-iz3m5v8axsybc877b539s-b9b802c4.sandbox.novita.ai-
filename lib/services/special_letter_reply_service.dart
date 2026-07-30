import 'dart:math';
import '../models/special_letter_entry.dart';
import '../data/heart_letter_reply_pools.dart';

/// 감사·용서·미안함·사랑, 네 가지 마음편지에 대한 답장을 즉석에서
/// 만들어주는 서비스.
///
/// 그림자 고양이에게 보내는 기존 편지(다음날 답장)와 달리, 이 마음편지는
/// 쓰는 즉시 짧고 따뜰한 답장을 받습니다. 답장은 인사→통찰→실천제안→마무리,
/// 4개 모듈을 각각 넉넉한 문장 풀에서 진짜 랜덤으로 골라 조합하기 때문에
/// (이전 버전처럼 "편지 글자 수" 기반 결정적 시드가 아니라, 매번 새로운
/// 무작위 값을 사용) 같은 종류의 편지를 여러 번 써도 매번 다른 답장을
/// 받게 됩니다. 또한 편지 내용이 "나 자신"을 향한 것으로 보이면, 그에
/// 맞는 전용 인사 문장으로 자연스럽게 갈라집니다.
class SpecialLetterReplyService {
  SpecialLetterReplyService._();

  static final RegExp _selfDirectedPattern = RegExp(
    r'나\s*자신|스스로|내\s*자신|나에게|내게|자기\s*자신',
  );

  /// 편지 내용이 "나 자신"을 향한 것으로 보이는지 판단합니다.
  static bool _isSelfDirected(String letterText) =>
      _selfDirectedPattern.hasMatch(letterText);

  /// [type]에 대한 답장을 조합합니다.
  ///
  /// [recentReplies]는 같은 종류의 편지에 대해 최근에 이미 보냈던 답장
  /// 전체 텍스트 목록입니다(있다면). 각 모듈에서 고른 문장이 최근
  /// 답장들에 이미 포함되어 있었다면 되도록 피해서, 연속으로 겹치는
  /// 문장이 나오는 걸 최소화합니다(9.3 Fallback과 동일한 철학으로,
  /// 회피 후 후보가 하나도 남지 않으면 전체 풀로 안전하게 되돌립니다).
  static String buildReply({
    required SpecialLetterType type,
    required String letterText,
    List<String> recentReplies = const [],
    Random? random,
  }) {
    final pool = heartLetterReplyPools[type];
    if (pool == null) return '오늘 이 마음을 전해줘서 고마워요.';

    final rng = random ?? Random();
    final selfDirected = _isSelfDirected(letterText);

    final openingPool = (selfDirected && pool.selfOpening.isNotEmpty)
        ? pool.selfOpening
        : pool.opening;

    final opening = _pickAvoiding(openingPool, recentReplies, rng);
    final insight = _pickAvoiding(pool.insight, recentReplies, rng);
    final practice = _pickAvoiding(pool.practice, recentReplies, rng);
    final closing = _pickAvoiding(pool.closing, recentReplies, rng);

    return [opening, insight, practice, closing]
        .where((s) => s.isNotEmpty)
        .join(' ');
  }

  static String _pickAvoiding(
    List<String> candidates,
    List<String> recentReplies,
    Random rng,
  ) {
    if (candidates.isEmpty) return '';
    var filtered = candidates
        .where((s) => !recentReplies.any((r) => r.contains(s)))
        .toList();
    if (filtered.isEmpty) filtered = candidates;
    return filtered[rng.nextInt(filtered.length)];
  }
}
