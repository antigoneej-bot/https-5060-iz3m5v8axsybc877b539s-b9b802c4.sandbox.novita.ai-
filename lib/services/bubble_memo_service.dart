import 'dart:math';
import '../models/bubble_memo_entry.dart';
import 'storage_service.dart';

/// '오늘의 그림자 방울 터뜨리기' 중 감정 고양이에게 남기는 짧은 한마디와,
/// 그 한마디를 나중에 같은 감정의 방울을 다시 마주쳤을 때 고양이가
/// "기억"하고 회상해주는 로직을 담당합니다.
///
/// 핵심 원칙:
/// - 회상은 낮은 확률(기본 25%, 20~30% 권장 범위 안)로만 일어나 예측
///   가능해지지 않도록 합니다.
/// - 같은 한마디는 [memoCooldownDays]일 안에는 다시 회상되지 않아
///   반복으로 특별함이 떨어지지 않게 합니다.
/// - 오늘 남긴 한마디는(=아직 '과거'가 아니므로) 오늘 안에는 회상 대상이
///   되지 않습니다.
/// - 어떤 한마디를 회상하든, 캐릭터가 그 내용을 부풀리거나 다시 아프게
///   찌르지 않도록 회상 문장 자체는 [buildRecallLine]에서 항상 같은
///   따뜻하고 수용적인 틀을 사용합니다(내용은 그대로 인용하되 반응은
///   고정).
class BubbleMemoService {
  /// 한 번의 완료(오늘의 방울 다 놓아주기) 시점마다 회상이 일어날 확률.
  static const double recallProbability = 0.25;

  /// 같은 한마디가 다시 회상되기까지 최소 며칠을 쉬어야 하는지.
  static const int memoCooldownDays = 5;

  /// 한마디 입력의 권장 최대 길이. UI에서 TextField maxLength로도 사용됩니다.
  static const int maxMessageLength = 50;

  static Future<void> saveMemo({
    required String catId,
    required String message,
  }) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty || catId.isEmpty) return;
    final clipped = trimmed.length > maxMessageLength
        ? trimmed.substring(0, maxMessageLength)
        : trimmed;
    final entry = BubbleMemoEntry(
      id: '${DateTime.now().millisecondsSinceEpoch}_$catId',
      catId: catId,
      date: DateTime.now(),
      message: clipped,
    );
    await StorageService.saveBubbleMemo(entry);
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// 오늘 방울밭에 등장한 감정(catId)들을 훑어, 그 중 하나의 감정 고양이가
  /// 과거에 남겼던 한마디를 낮은 확률로 회상하게 합니다. 회상할 만한
  /// 대상이 없거나(과거 기록이 없거나 모두 쿨다운 중) 확률에 걸리지
  /// 않았다면 null을 반환합니다.
  static BubbleMemoEntry? maybeRecallOnCompletion(
    List<String> todaysCatIds, {
    Random? random,
  }) {
    final uniqueCatIds = todaysCatIds.where((id) => id.isNotEmpty).toSet();
    if (uniqueCatIds.isEmpty) return null;

    final now = DateTime.now();
    final candidates = <BubbleMemoEntry>[];
    for (final catId in uniqueCatIds) {
      for (final memo in StorageService.getBubbleMemosForCat(catId)) {
        if (_isSameDay(memo.date, now)) continue;
        final lastRecalled = memo.lastRecalledAt;
        if (lastRecalled != null &&
            now.difference(lastRecalled).inDays < memoCooldownDays) {
          continue;
        }
        candidates.add(memo);
      }
    }
    if (candidates.isEmpty) return null;

    final rand = random ?? Random();
    if (rand.nextDouble() > recallProbability) return null;

    // 한 번도 회상되지 않았거나 가장 오래전에 회상된 한마디를 우선합니다
    // (특정 한마디만 반복해서 회상되는 걸 막기 위함).
    candidates.sort((a, b) {
      final aKey = a.lastRecalledAt ?? DateTime(2000);
      final bKey = b.lastRecalledAt ?? DateTime(2000);
      return aKey.compareTo(bKey);
    });
    return candidates.first;
  }

  static Future<void> markRecalled(String id) async {
    await StorageService.markBubbleMemoRecalled(id);
  }

  /// 회상 문장을 만듭니다. 남긴 말의 내용(긍정/부정)과 무관하게 항상 같은
  /// 따뜻하고 궁금해하는 어조의 틀을 사용해, 부정적인 한마디를 회상할
  /// 때에도 그 감정을 다시 부추기지 않도록 합니다.
  static String buildRecallLine(String message) {
    return "너 지난번에 나한테 '$message'라고 했었지. 지금은 마음이 좀 어때?";
  }
}
