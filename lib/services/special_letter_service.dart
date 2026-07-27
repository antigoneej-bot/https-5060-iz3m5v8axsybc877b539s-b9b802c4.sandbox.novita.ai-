import 'package:hive_flutter/hive_flutter.dart';
import '../models/special_letter_entry.dart';
import 'special_letter_reply_service.dart';

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
    _box = await Hive.openBox('special_letters_$_uid');
  }

  static Box get _b {
    if (_box == null || !_box!.isOpen) {
      throw Exception('SpecialLetterService: 사용자가 설정되지 않았습니다 (setCurrentUser 먼저 호출)');
    }
    return _box!;
  }

  /// 편지를 씁니다. 답장은 내부적으로 미리 만들어 함께 저장하지만,
  /// 다음날 오전 6시가 지나기 전에는 화면에 보여주지 않습니다.
  static Future<SpecialLetterEntry> sendLetter({
    required SpecialLetterType type,
    required String letterText,
  }) async {
    final reply = SpecialLetterReplyService.buildReply(
      type: type,
      letterText: letterText,
    );
    final entry = SpecialLetterEntry(
      id: '${DateTime.now().millisecondsSinceEpoch}_${type.storageKey}',
      type: type,
      letterText: letterText,
      replyText: reply,
      createdAt: DateTime.now(),
    );
    await _b.put(entry.id, entry.toMap());
    return entry;
  }

  /// 특정 종류의 마음편지를 최신순으로 모두 가져옵니다.
  static List<SpecialLetterEntry> getEntriesOfType(SpecialLetterType type) {
    final all = _b.values
        .map((e) => SpecialLetterEntry.fromMap(Map<dynamic, dynamic>.from(e as Map)))
        .where((e) => e.type == type)
        .toList();
    all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return all;
  }

  /// 모든 마음편지를 최신순으로 가져옵니다.
  static List<SpecialLetterEntry> getAllEntries() {
    final all = _b.values
        .map((e) => SpecialLetterEntry.fromMap(Map<dynamic, dynamic>.from(e as Map)))
        .toList();
    all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return all;
  }

  static Future<void> deleteLetter(String id) async {
    await _b.delete(id);
  }

  /// 답장을 열어봤음을 표시합니다(홈 화면 배너를 한 번만 보여주기 위함).
  static Future<void> markReplySeen(String id) async {
    final raw = _b.get(id);
    if (raw == null) return;
    final entry = SpecialLetterEntry.fromMap(Map<dynamic, dynamic>.from(raw as Map));
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
