import 'personal_reply_service.dart';
import 'hive_encryption.dart';
import 'reply_failure.dart';
import '../models/letter_entry.dart';
import '../models/shadow_cat.dart';
import '../models/cat_care_state.dart';

/// Existing cached letters are preserved; new replies use the offline v5 engine.
final Map<String, Future<String>> _replyInFlight = {};
Future<String> buildReplyText({
  required LetterEntry entry,
  required ShadowCat cat,
  required List<LetterEntry> history,
  required CatGrowthStage growthStage,
  required int visitStreak,
}) => _replyInFlight.putIfAbsent(
  entry.id,
  () =>
      _buildReplyText(
        entry: entry,
        cat: cat,
        history: history,
        growthStage: growthStage,
        visitStreak: visitStreak,
      ).whenComplete(() {
        // Do not return Map.remove's value: it is this very Future. Returning it
        // makes whenComplete wait for itself, so neither success nor error reaches UI.
        _replyInFlight.remove(entry.id);
      }),
);

Future<String> _buildReplyText({
  required LetterEntry entry,
  required ShadowCat cat,
  required List<LetterEntry> history,
  required CatGrowthStage growthStage,
  required int visitStreak,
}) async {
  final cache = await ReplyFailure.step(
    'CACHE',
    () => HiveEncryption.openBox('reply_cache_local_user'),
    timeout: const Duration(seconds: 8),
  );
  final cached = cache.get(entry.id);
  // Match PersonalReplyService's minimum validity check. A damaged legacy
  // cache must not hide a valid stored answer or block regeneration forever.
  if (cached is String && cached.trim().length >= 4) return cached;
  final reply = await PersonalReplyService.create(
    id: 'letter:${entry.id}',
    letterText: entry.letterText,
    style: entry.replyStyle,
    catName: cat.nameKr,
    legacyReplies: cache.values
        .whereType<String>()
        .toList()
        .reversed
        .take(20)
        .toList(),
  );
  // New replies are already durably cached by PersonalReplyService.
  return reply;
}
