import '../mongi/integration/mongi_garden_store.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/special_letter_entry.dart';
import 'personal_reply_service.dart';
import '../models/reply_style.dart';
import 'hive_encryption.dart';
import 'notification_service.dart';

/// 감사·용서·미안함·사랑, 네 가지 마음편지의 저장을 담당하는 서비스.
///
/// 그림자 고양이 편지와 동일하게, 답장은 다음날 오전 6시가 지나야 열어볼
/// 수 있습니다(내부적으로는 편지를 쓰는 시점에 답장을 미리 만들어 함께
/// 저장하지만, [SpecialLetterEntry.isReplyReady]가 true가 되기 전까지는
/// 화면에 보여주지 않습니다). 계정별 Hive Box를 사용해, 다른 로컬 서비스
/// (PromiseService 등)와 동일한 패턴을 따릅니다.
class SpecialLetterService {
  static String _uid = 'guest';
  static Box? _box;

  static Future<void> setCurrentUser(String userId) async {
    if (_uid == userId && _box != null && _box!.isOpen) return;
    _uid = userId;
    if (_box != null && _box!.isOpen) {
      await _box!.close();
    }
    _box = await HiveEncryption.openBox('special_letters_$_uid');
  }

  static Box get _b {
    if (_box == null || !_box!.isOpen) {
      throw Exception(
        'SpecialLetterService: 사용자가 설정되지 않았습니다 (setCurrentUser 먼저 호출)',
      );
    }
    return _box!;
  }

  /// 편지를 씁니다. 답장은 내부적으로 미리 만들어 함께 저장하지만,
  /// 다음날 오전 6시가 지나기 전에는 화면에 보여주지 않습니다.
  static Future<SpecialLetterEntry> sendLetter({
    required SpecialLetterType type,
    required String letterText,
    ReplyStyle replyStyle = ReplyStyle.listen,
    String? submissionId,
  }) async {
    final now = DateTime.now();
    final id =
        submissionId ?? '${now.microsecondsSinceEpoch}_${type.storageKey}';
    final existing = _b.get(id);
    if (existing != null) {
      final saved = SpecialLetterEntry.fromMap(
        Map<dynamic, dynamic>.from(existing as Map),
      );
      if (saved.letterText != letterText ||
          saved.type != type ||
          saved.replyStyle != replyStyle)
        throw StateError('편지 ID가 겹쳤어요.');
      await _b.flush();
      if (saved.letterText.trim().isNotEmpty)
        await MongiGardenStore.instance.claimCompletedCare(
          now: saved.createdAt.toLocal(),
        );
      return saved;
    }
    final entry = SpecialLetterEntry(
      id: id,
      type: type,
      letterText: letterText,
      replyText: '',
      createdAt: now,
      replyStyle: replyStyle,
    );
    await _b.put(entry.id, entry.toMap());
    await _b.flush();
    if (entry.letterText.trim().isNotEmpty)
      await MongiGardenStore.instance.claimCompletedCare(
        now: entry.createdAt.toLocal(),
      );
    try {
      await NotificationService().scheduleHeartLetterReplyNotification(
        typeLabel: type.label,
        scheduledAt: entry.replyAvailableAt,
      );
    } catch (_) {}
    return entry;
  }

  static Future<String> ensureReply(SpecialLetterEntry entry) async {
    if (entry.replyText.isNotEmpty) return entry.replyText;
    final reply = await PersonalReplyService.create(
      id: 'heart:${entry.id}',
      letterText: entry.letterText,
      style: entry.replyStyle,
      catName: '마음편지 고양이',
      legacyReplies: getAllEntries().take(20).map((e) => e.replyText).toList(),
    );
    final raw = _b.get(entry.id);
    if (raw == null) throw StateError('삭제된 편지예요.');
    final current = SpecialLetterEntry.fromMap(
      Map<dynamic, dynamic>.from(raw as Map),
    );
    if (current.replyText.isNotEmpty) return current.replyText;
    await _b.put(entry.id, current.withReplyText(reply).toMap());
    await _b.flush();
    return reply;
  }

  /// 특정 종류의 마음편지를 최신순으로 모두 가져옵니다.
  static List<SpecialLetterEntry> getEntriesOfType(SpecialLetterType type) {
    final all = _b.values
        .map(
          (e) =>
              SpecialLetterEntry.fromMap(Map<dynamic, dynamic>.from(e as Map)),
        )
        .where((e) => e.type == type)
        .toList();
    all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return all;
  }

  /// 모든 마음편지를 최신순으로 가져옵니다.
  static List<SpecialLetterEntry> getAllEntries() {
    final all = _b.values
        .map(
          (e) =>
              SpecialLetterEntry.fromMap(Map<dynamic, dynamic>.from(e as Map)),
        )
        .toList();
    all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return all;
  }

  static Future<void> deleteLetter(String id) async {
    await PersonalReplyService.remove('heart:$id');
    await _b.delete(id);
    await _b.flush();
  }

  /// 답장을 열어봤음을 표시합니다(홈 화면 배너를 한 번만 보여주기 위함).
  static Future<void> markReplySeen(String id) async {
    final raw = _b.get(id);
    if (raw == null) return;
    final entry = SpecialLetterEntry.fromMap(
      Map<dynamic, dynamic>.from(raw as Map),
    );
    await _b.put(id, entry.withReplySeen().toMap());
  }

  /// 답장이 준비됐지만 아직 열어보지 않은 마음편지 중 가장 최근 것을
  /// 반환합니다(없으면 null). 홈 화면의 "답장이 도착했어요" 배너에
  /// 사용됩니다.
  static SpecialLetterEntry? get unseenReadyReply {
    if (_box == null || !_box!.isOpen) return null;
    for (final e in getAllEntries()) {
      if (e.isReplyReady && !e.replySeen) return e;
    }
    return null;
  }
}
