import '../models/letter_entry.dart';
import '../models/shadow_cat.dart';
import '../models/cat_care_state.dart';
import '../utils/feature_flags.dart';
import '../data/cat_reply_data.dart';
import 'letter_context_builder.dart';
import 'template_reply_generator.dart';

/// 화면에서 실제로 호출하는 단일 진입점.
///
/// [FeatureFlags.useNewLetterEngine]에 따라 신규 8모듈 조합 시스템과 기존
/// `generateCatReply()`(레거시) 중 하나로 즉시 전환/롤백할 수 있습니다
/// (설계서 13.5절 "확정 — 기존 generateCatReply()와의 관계" 참고).
Future<String> buildReplyText({
  required LetterEntry entry,
  required ShadowCat cat,
  required List<LetterEntry> history,
  required CatGrowthStage growthStage,
  required int visitStreak,
}) async {
  if (!FeatureFlags.useNewLetterEngine) {
    return generateCatReply(entry, cat);
  }

  final ctx = LetterContextBuilder.build(
    catId: cat.id,
    history: history,
    growthStage: growthStage,
    visitStreak: visitStreak,
    now: DateTime.now(),
  );
  final generator = TemplateReplyGenerator();
  return generator.generate(ctx);
}
