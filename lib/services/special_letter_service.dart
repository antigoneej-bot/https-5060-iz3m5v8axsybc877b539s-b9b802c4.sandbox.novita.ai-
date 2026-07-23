import 'package:hive_flutter/hive_flutter.dart';
import '../models/special_letter_entry.dart';
import 'special_letter_reply_service.dart';

/// 감사·용서·미안함·사랑, 네 가지 마음편지의 저장을 담당하는 서비스.
///
/// 그림자 고양이 편지(다음날 답장)와 다르게, 이 마음편지는 쓰는 즉시
/// 답장까지 함께 저장됩니다. 계정별 Hive Box를 사용해, 다른 로컬 서비스
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

  /// 편지를 쓰는 즉시 답장을 함께 생성해 저장합니다.
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
}
