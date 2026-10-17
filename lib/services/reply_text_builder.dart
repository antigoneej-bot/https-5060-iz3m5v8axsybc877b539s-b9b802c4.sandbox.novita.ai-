import 'personal_reply_service.dart';
import 'hive_encryption.dart';
import 'reply_failure.dart';
import 'storage_service.dart';
import '../models/letter_entry.dart';
import '../models/shadow_cat.dart';
import '../models/cat_care_state.dart';

/// Existing answers are preserved until the reader explicitly refreshes them.
final Map<String, Future<String>> _replyInFlight = {};
Future<String> buildReplyText({
  required LetterEntry entry,
  required ShadowCat cat,
  required List<LetterEntry> history,
  required CatGrowthStage growthStage,
  required int visitStreak,
  bool refreshExisting = false,
}) {
  final key = '${entry.id}:${refreshExisting ? 'refresh' : 'read'}';
  return _replyInFlight.putIfAbsent(
    key,
    () =>
        _buildReplyText(
          entry: entry,
          cat: cat,
          history: history,
          growthStage: growthStage,
          visitStreak: visitStreak,
          refreshExisting: refreshExisting,
        ).whenComplete(() {
          // Do not return Map.remove's value: it is this very Future. Returning it
          // makes whenComplete wait for itself, so neither success nor error reaches UI.
          _replyInFlight.remove(key);
        }),
  );
}

Future<String> _buildReplyText({
  required LetterEntry entry,
  required ShadowCat cat,
  required List<LetterEntry> history,
  required CatGrowthStage growthStage,
  required int visitStreak,
  required bool refreshExisting,
}) async {
  final sourceBox = StorageService.letterBox;
  bool sourceIsCurrent() {
    try {
      if (!sourceBox.isOpen ||
          !identical(StorageService.letterBox, sourceBox)) {
        return false;
      }
      final raw = sourceBox.get(entry.id);
      if (raw is! Map) return false;
      final current = LetterEntry.fromMap(Map<dynamic, dynamic>.from(raw));
      return current.letterText == entry.letterText &&
          current.catId == entry.catId &&
          current.replyStyle == entry.replyStyle;
    } catch (_) {
      return false;
    }
  }

  if (!sourceIsCurrent()) throw StateError('삭제되거나 변경된 편지예요.');
  final cache = await ReplyFailure.step(
    'CACHE',
    () => HiveEncryption.openBox('reply_cache_local_user'),
    timeout: const Duration(seconds: 8),
  );
  final cached = cache.get(entry.id);
  // The service checks its canonical history first, so an older outer cache
  // cannot bring back the old answer after an explicit refresh.
  final reply = await PersonalReplyService.create(
    id: 'letter:${entry.id}',
    letterText: entry.letterText,
    style: entry.replyStyle,
    catName: cat.nameKr,
    emotionId: cat.id,
    refreshExisting: refreshExisting,
    sourceIsCurrent: sourceIsCurrent,
    legacyReply: cached is String ? cached : null,
    legacyReplies: (() {
      // Legacy caches have no saved-at metadata. Their timestamp IDs provide
      // the best available chronological order; unknown IDs tie-break by key.
      int timestamp(String id) {
        final value = int.tryParse(id.split('_').first) ?? 0;
        return value > 0 && value < 100000000000000 ? value * 1000 : value;
      }

      final keys = cache.keys.whereType<String>().toList()
        ..sort((a, b) {
          final byTime = timestamp(b).compareTo(timestamp(a));
          return byTime != 0 ? byTime : b.compareTo(a);
        });
      return keys
          .map(cache.get)
          .whereType<String>()
          .where((text) => text.trim().length >= 4)
          .take(20)
          .toList();
    })(),
  );
  // New replies are already durably cached by PersonalReplyService.
  return reply;
}
