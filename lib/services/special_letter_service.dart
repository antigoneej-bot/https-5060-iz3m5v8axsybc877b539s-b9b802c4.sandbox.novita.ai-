import '../mongi/integration/mongi_garden_store.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/special_letter_entry.dart';
import 'personal_reply_service.dart';
import '../models/reply_style.dart';
import 'hive_encryption.dart';
import 'notification_service.dart';

/// 감사·용서·미안함·사랑, 네 가지 마음편지의 저장을 담당하는 서비스.
///
/// 그림자 고양이 편지와 동일하게, 답장은 다음날 오전 6시가 지나야 열어볼
/// 수 있습니다. 편지 작성 시에는 원문만 저장하고, 답장을 받을 수 있는
/// 시각이 지난 뒤 사용자가 선택해 열 때 답장을 생성합니다. 저장된 답장은
/// 다시 생성하지 않습니다. 계정별 Hive Box를 사용해, 다른 로컬 서비스
/// (PromiseService 등)와 동일한 패턴을 따릅니다.
class SpecialLetterService {
  static String _uid = 'guest';
  static Box? _box;
  static ValueListenable<Box>? get listenable =>
      _box != null && _box!.isOpen ? _box!.listenable() : null;

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

  /// 원문을 저장합니다. 다음날 오전 6시 이후 사용자가 답장을 선택해
  /// 열 때 생성하므로, 편지를 쓰거나 목록을 보는 것만으로 횟수를 쓰지 않습니다.
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
          saved.replyStyle != replyStyle) {
        throw StateError('편지 ID가 겹쳤어요.');
      }
      await _b.flush();
      if (saved.letterText.trim().isNotEmpty) {
        await MongiGardenStore.instance.claimCompletedCare(
          now: saved.createdAt.toLocal(),
        );
      }
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
    if (entry.letterText.trim().isNotEmpty) {
      await MongiGardenStore.instance.claimCompletedCare(
        now: entry.createdAt.toLocal(),
      );
    }
    try {
      await NotificationService().scheduleHeartLetterReplyNotification(
        typeLabel: type.label,
        scheduledAt: entry.replyAvailableAt,
      );
    } catch (_) {}
    return entry;
  }

  static bool _sourceIsCurrent(
    Box box,
    String userId,
    SpecialLetterEntry source,
  ) {
    if (_uid != userId || !identical(_box, box) || !box.isOpen) return false;
    final raw = box.get(source.id);
    if (raw is! Map) return false;
    final current = SpecialLetterEntry.fromMap(Map<dynamic, dynamic>.from(raw));
    return current.letterText == source.letterText &&
        current.replyStyle == source.replyStyle &&
        current.type == source.type;
  }

  static SpecialLetterEntry _storedSource(Box box, String id) {
    final stored = box.get(id);
    if (stored == null) throw StateError('삭제된 편지예요.');
    return SpecialLetterEntry.fromMap(
      Map<dynamic, dynamic>.from(stored as Map),
    );
  }

  /// Read only: history cards can show saved answers without using today's
  /// free reply or generating answers for every item while merely scrolling.
  static Future<String?> savedReply(SpecialLetterEntry entry) async {
    final box = _b;
    final userId = _uid;
    final source = _storedSource(box, entry.id);
    return PersonalReplyService.savedReply(
      'heart:${entry.id}',
      legacyReplyReader: () => _storedSource(box, entry.id).replyText,
      sourceIsCurrent: () => _sourceIsCurrent(box, userId, source),
    );
  }

  static Future<String> ensureReply(
    SpecialLetterEntry entry, {
    bool refreshExisting = false,
  }) async {
    final box = _b;
    final userId = _uid;
    final source = _storedSource(box, entry.id);
    return PersonalReplyService.create(
      id: 'heart:${entry.id}',
      letterText: source.letterText,
      style: source.replyStyle,
      catName: '마음편지 고양이',
      refreshExisting: refreshExisting,
      legacyReplyReader: () => _storedSource(box, entry.id).replyText,
      legacyReplies: getAllEntries().take(20).map((e) => e.replyText).toList(),
      sourceIsCurrent: () => _sourceIsCurrent(box, userId, source),
      persistSourceReply: (reply) async {
        if (!_sourceIsCurrent(box, userId, source)) {
          throw StateError('삭제되거나 변경된 편지예요. 기록을 다시 열어 주세요.');
        }
        final current = _storedSource(box, entry.id);
        if (current.replyText != reply) {
          try {
            await box.put(entry.id, current.withReplyText(reply).toMap());
            await box.flush();
          } catch (_) {
            // The source's embedded cache is part of the same migration. A
            // failed write must not become the next reader's legacy fallback.
            try {
              await box.put(entry.id, current.toMap());
              await box.flush();
            } catch (_) {}
            rethrow;
          }
        }
      },
    );
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
    final box = _b;
    final userId = _uid;
    Object? previousSource;
    var captured = false;
    await PersonalReplyService.remove(
      'heart:$id',
      deleteSource: () async {
        if (_uid != userId || !identical(_box, box) || !box.isOpen) {
          throw StateError('사용자가 변경됐어요. 편지를 다시 열어 주세요.');
        }
        previousSource = box.get(id);
        captured = true;
        await box.delete(id);
        await box.flush();
      },
      restoreSource: () async {
        if (!captured ||
            _uid != userId ||
            !identical(_box, box) ||
            !box.isOpen) {
          return;
        }
        if (previousSource != null) await box.put(id, previousSource);
        await box.flush();
      },
    );
  }

  /// 답장을 열어봤음을 표시합니다(홈 화면 배너를 한 번만 보여주기 위함).
  static Future<void> markReplySeen(String id) async {
    final box = _b;
    final userId = _uid;
    await PersonalReplyService.withStorageLock(() async {
      if (_uid != userId || !identical(_box, box) || !box.isOpen) return;
      final raw = box.get(id);
      if (raw == null) return;
      final entry = SpecialLetterEntry.fromMap(
        Map<dynamic, dynamic>.from(raw as Map),
      );
      if (entry.replySeen) return;
      await box.put(id, entry.withReplySeen().toMap());
      await box.flush();
    });
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
