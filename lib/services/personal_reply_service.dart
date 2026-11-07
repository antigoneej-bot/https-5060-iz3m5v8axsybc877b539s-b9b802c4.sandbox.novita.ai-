import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/reply_style.dart';
import 'hive_encryption.dart';
import 'local_record_transaction.dart';
import 'reply_failure.dart';

/// One queue across cats and heart letters protects archived replies during
/// reads and source deletion. New automatic replies are retired.
class PersonalReplyService {
  static const currentEngineVersion = 3;
  @visibleForTesting
  static DateTime Function() clock = DateTime.now;
  static Future<Box> _history() =>
      HiveEncryption.openBox('personal_replies_local_user');
  static Future<Box> _feedback() =>
      HiveEncryption.openBox('reply_feedback_local_user');

  /// The caller may stop waiting, but the real operation keeps its place in the
  /// queue until writes and any rollback finish. Hive exposes optimistic values
  /// before disk completion, so reads must use this same queue too.
  static Future<T> withStorageLock<T>(
    Future<T> Function() action, {
    Duration timeout = const Duration(seconds: 45),
  }) {
    final nested = LocalRecordTransaction.isActive;
    var expired = false;
    final operation = LocalRecordTransaction.atomic(() {
      if (expired) {
        throw TimeoutException('대기 시간이 지나 작업을 시작하지 않았어요. 다시 시도해 주세요.');
      }
      return action();
    });
    if (nested) return operation;
    // Never use the caller's timeout future as the tail: Future.timeout does
    // not cancel an in-flight storage write or its eventual rollback.
    return operation.timeout(
      timeout,
      onTimeout: () {
        expired = true;
        throw TimeoutException('답장 저장 작업이 아직 끝나지 않았어요. 잠시 후 다시 확인해 주세요.');
      },
    );
  }

  /// Kept for compatibility with old routes. New automated answers have been
  /// retired; even an explicit refresh may only read an already saved answer.
  static const generationEnabled = false;

  static Future<String> create({
    required String id,
    required String letterText,
    required ReplyStyle style,
    required String catName,
    String? emotionId,
    bool refreshExisting = false,
    String? legacyReply,
    String? Function()? legacyReplyReader,
    List<String> legacyReplies = const [],
    bool Function()? sourceIsCurrent,
    Future<void> Function(String reply)? persistSourceReply,
  }) async {
    final saved = await savedReply(
      id,
      legacyReply: legacyReply,
      legacyReplyReader: legacyReplyReader,
      sourceIsCurrent: sourceIsCurrent,
    );
    if (saved == null) throw const ReplyGenerationRetired();
    return saved;
  }

  static void _checkSource(bool Function()? sourceIsCurrent) {
    if (sourceIsCurrent != null && !sourceIsCurrent()) {
      throw StateError('삭제되거나 변경된 편지예요. 기록을 다시 열어 주세요.');
    }
  }

  static String? _validReply(Object? value) =>
      value is String && value.trim().length >= 4 ? value : null;

  /// Read only: no generation, daily quota, version migration or writes.
  static Future<String?> savedReply(
    String id, {
    String? legacyReply,
    String? Function()? legacyReplyReader,
    bool Function()? sourceIsCurrent,
  }) => withStorageLock(() async {
    _checkSource(sourceIsCurrent);
    final box = await ReplyFailure.step(
      'HISTORY',
      _history,
      timeout: const Duration(seconds: 8),
    );
    _checkSource(sourceIsCurrent);
    final value = box.get(id);
    final row = value is String ? _historyRow(value) : null;
    return _validReply(row?['reply']) ??
        _validReply(
          legacyReplyReader != null ? legacyReplyReader() : legacyReply,
        );
  }, timeout: const Duration(seconds: 15));

  /// Archived answers are immutable. No migration or paid regeneration.
  static Future<bool> needsRefresh(String id) async => false;

  /// 저장된 답장 이력 한 줄(JSON 문자열)을 파싱합니다. 손상됐거나 형식이
  /// 맞지 않으면 null을 반환해 호출부에서 건너뛸 수 있게 합니다(원본
  /// 데이터는 삭제하지 않고 그대로 둠).
  static Map<String, dynamic>? _historyRow(String value) {
    try {
      final row = Map<String, dynamic>.from(jsonDecode(value) as Map);
      if (row['reply'] is! String) return null;
      row['parts'] = (row['parts'] is List)
          ? (row['parts'] as List).whereType<String>().toList()
          : <String>[];
      return row;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> feedback(String id) => withStorageLock(
    () async => (await _feedback()).get(id) as String?,
    timeout: const Duration(seconds: 15),
  );

  static Future<void> setFeedback(String id, String? value) {
    if (value != null &&
        !{'matched', 'off_topic', 'repeated'}.contains(value)) {
      throw ArgumentError('Invalid feedback');
    }
    return withStorageLock(() async {
      final box = await ReplyFailure.step(
        'FEEDBACK',
        _feedback,
        timeout: const Duration(seconds: 8),
      );
      LocalRecordTransaction.capture(box);
      if (value == null) {
        await box.delete(id);
      } else {
        await box.put(id, value);
      }
      await box.flush();
    }, timeout: const Duration(seconds: 15));
  }

  /// Source deletion shares the generation queue, so a pending stale widget
  /// cannot recreate a reply after its backing letter has been removed.
  static Future<void> remove(
    String id, {
    Future<void> Function()? deleteSource,
  }) => withStorageLock(() async {
    final box = await ReplyFailure.step(
      'HISTORY',
      _history,
      timeout: const Duration(seconds: 8),
    );
    final feedback = await ReplyFailure.step(
      'FEEDBACK',
      _feedback,
      timeout: const Duration(seconds: 8),
    );
    LocalRecordTransaction.capture(box);
    LocalRecordTransaction.capture(feedback);
    // Source stores join this same transaction and capture their boxes before
    // removal. A later archive flush failure restores the original and every
    // derived private copy, not just the old reply cache.
    if (deleteSource != null) await deleteSource();
    await box.delete(id);
    await box.flush();
    await feedback.delete(id);
    await feedback.flush();
  }, timeout: const Duration(seconds: 15));
}

/// Old routes can distinguish an absent archive from a storage/network error.
class ReplyGenerationRetired implements Exception {
  const ReplyGenerationRetired();
  @override
  String toString() => '새 자동 답장은 만들지 않아요. 남긴 편지는 기록에서 볼 수 있어요.';
}
