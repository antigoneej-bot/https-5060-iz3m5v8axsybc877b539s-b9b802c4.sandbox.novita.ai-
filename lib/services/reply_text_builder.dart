import 'personal_reply_service.dart';
import 'hive_encryption.dart';
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
}) => _replyInFlight.putIfAbsent(entry.id, () => _buildReplyText(
  entry: entry, cat: cat, history: history, growthStage: growthStage, visitStreak: visitStreak,
).whenComplete(() => _replyInFlight.remove(entry.id)));

Future<String> _buildReplyText({
  required LetterEntry entry,
  required ShadowCat cat,
  required List<LetterEntry> history,
  required CatGrowthStage growthStage,
  required int visitStreak,
}) async {
  // ignore: avoid_print
  print('DEBUG_REPLY: start _buildReplyText entry=${entry.id}');
  final cache = await HiveEncryption.openBox('reply_cache_local_user');
  // ignore: avoid_print
  print('DEBUG_REPLY: opened cache box');
  final cached = cache.get(entry.id);
  if (cached is String) {
    // ignore: avoid_print
    print('DEBUG_REPLY: cache hit');
    return cached;
  }
  // ignore: avoid_print
  print('DEBUG_REPLY: cache miss, calling PersonalReplyService.create');
  final reply = await PersonalReplyService.create(
    id: 'letter:${entry.id}', letterText: entry.letterText,
    style: entry.replyStyle, catName: cat.nameKr,
    legacyReplies: cache.values.whereType<String>().toList().reversed.take(20).toList(),
  );
  // ignore: avoid_print
  print('DEBUG_REPLY: create() resolved');
  // New replies are already durably cached by PersonalReplyService.
  return reply;
}
