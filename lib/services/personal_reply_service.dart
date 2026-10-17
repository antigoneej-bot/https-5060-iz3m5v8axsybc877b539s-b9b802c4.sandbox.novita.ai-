import 'dart:async';
import 'access_policy.dart';
import 'subscription_service.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/reply_style.dart';
import 'hive_encryption.dart';
import 'personal_reply_engine.dart';
import 'reply_failure.dart';

/// One queue across cats and heart letters; duplicate opens cannot race the
/// anti-repetition history. Saved replies change only on an explicit migration.
class PersonalReplyService {
  static const currentEngineVersion = 3;
  @visibleForTesting
  static DateTime Function() clock = DateTime.now;
  static Future<void> _tail = Future.value();
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
    var expired = false;
    final operation = _tail.catchError((Object _) {}).then((_) {
      if (expired) {
        throw TimeoutException('대기 시간이 지나 작업을 시작하지 않았어요. 다시 시도해 주세요.');
      }
      return action();
    });
    // Never use the caller's timeout future as the tail: Future.timeout does
    // not cancel an in-flight storage write or its eventual rollback.
    _tail = operation.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return operation.timeout(
      timeout,
      onTimeout: () {
        expired = true;
        throw TimeoutException('답장 저장 작업이 아직 끝나지 않았어요. 잠시 후 다시 확인해 주세요.');
      },
    );
  }

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
  }) => withStorageLock(
    () => _createBody(
      id,
      letterText,
      style,
      catName,
      legacyReplies,
      emotionId,
      refreshExisting,
      legacyReply,
      legacyReplyReader,
      sourceIsCurrent,
      persistSourceReply,
    ),
  );

  static void _checkSource(bool Function()? sourceIsCurrent) {
    if (sourceIsCurrent != null && !sourceIsCurrent()) {
      throw StateError('삭제되거나 변경된 편지예요. 기록을 다시 열어 주세요.');
    }
  }

  static Future<String> _createBody(
    String id,
    String letterText,
    ReplyStyle style,
    String catName,
    List<String> legacyReplies,
    String? emotionId,
    bool refreshExisting,
    String? legacyReply,
    String? Function()? legacyReplyReader,
    bool Function()? sourceIsCurrent,
    Future<void> Function(String reply)? persistSourceReply,
  ) {
    return () async {
      _checkSource(sourceIsCurrent);
      final box = await ReplyFailure.step(
        'HISTORY',
        _history,
        timeout: const Duration(seconds: 8),
      );
      _checkSource(sourceIsCurrent);
      final existing = box.get(id);
      final row = existing is String ? _historyRow(existing) : null;
      final saved =
          _validReply(row?['reply']) ??
          _validReply(
            legacyReplyReader != null ? legacyReplyReader() : legacyReply,
          );
      // Canonical history wins over stale outer caches. Opening a saved answer
      // never silently rewrites it; migration is explicit and once per version.
      if (saved != null && (!refreshExisting || _isCurrent(row))) {
        _checkSource(sourceIsCurrent);
        if (persistSourceReply != null) await persistSourceReply(saved);
        return saved;
      }
      final refreshingSaved = refreshExisting && saved != null;
      // 구독 확인이 네트워크/캐시 문제로 멈추면 답장 전체가 무한정 멈추는
      // 것을 막기 위해 타임아웃을 둡니다(8초 지나면 실패로 처리해 재시도
      // 버튼이 뜨도록 함).
      final premium = refreshingSaved
          ? false
          : await ReplyFailure.step(
              'ACCESS',
              SubscriptionService().isPremium,
              timeout: const Duration(seconds: 8),
            );
      final day = AccessPolicy.dayKey(clock());
      final quotaKey = 'quota:$day';
      final used = box.get(quotaKey, defaultValue: 0) as int;
      if (!refreshingSaved &&
          !AccessPolicy.newReplyAllowed(premium: premium, used: used)) {
        throw const SubscriptionRequired(
          '편지는 저장되어 있어요. 무료 답장은 하루 1회 제공돼요. 추가 답장은 마음냥 구독으로 만나보세요.',
        );
      }
      // 과거 답장 이력 중 일부가 손상된 JSON이거나 parts가 누락되어 있어도
      // (예: 이전 버전에서 저장된 데이터) 전체 조회가 실패해 새 답장 생성을
      // 막지 않도록, 개별 행 파싱 실패는 건너뜁니다. 원본 저장 데이터는
      // 건드리지 않습니다.
      final allRows = _orderedHistory(box);
      final rows = allRows.take(20).toList();
      final nextSequence =
          allRows.fold<int>(0, (highest, row) {
            final value = row['replySequence'];
            return value is int && value > highest ? value : highest;
          }) +
          1;
      final feedback = await ReplyFailure.step(
        'FEEDBACK',
        _feedback,
        timeout: const Duration(seconds: 8),
      );
      // R11: 과거 행의 id가 비어있거나 String이 아닌 경우 평가 저장소
      // 조회 키로 그대로 쓰면 예기치 않은 예외가 날 수 있어, 유효성을
      // 먼저 검증합니다(검증 실패 시 단순히 '평가 없음'으로 취급).
      Object? feedbackFor(Map<String, dynamic> row) {
        final key = row['id'];
        if (key is! String || key.isEmpty) return null;
        return feedback.get(key);
      }

      final disliked = [
        for (final row in rows)
          if (feedbackFor(row) == 'repeated') row['reply'] as String,
      ];
      final offTopicCounts = <String, int>{};
      final matchedCounts = <String, int>{};
      final avoidedSituations = <String>{};
      final preferredParts = <String>[];
      for (final row in rows) {
        // A rejection of the previous engine must not suppress the replacement.
        if (!_isCurrent(row)) continue;
        if (feedbackFor(row) == 'matched') {
          final topic = row['topic'] is String
              ? row['topic'] as String
              : 'general';
          matchedCounts[topic] = (matchedCounts[topic] ?? 0) + 1;
          if (topic == PersonalReplyEngine.topicFor(letterText) &&
              row['style'] == style.name) {
            preferredParts.addAll(
              (row['parts'] as List? ?? const []).whereType<String>().toList(),
            );
          }
        }
        if (feedbackFor(row) == 'off_topic' && row['situation'] is String) {
          avoidedSituations.add(row['situation'] as String);
        }
        if (feedbackFor(row) == 'off_topic' && row['topic'] is String) {
          final topic = row['topic'] as String;
          offTopicCounts[topic] = (offTopicCounts[topic] ?? 0) + 1;
        }
      }
      // 주의: 과거에는 compute()(별도 워커/isolate)로 답장 문장을
      // 조합했으나, Flutter Web(dart2js/CanvasKit) 환경에서 워커가 결과를
      // 정상적으로 계산해 반환값까지 만들어내는데도 그 완료 신호가 원래
      // async 체인으로 전달되지 않아 화면이 로딩 스피너에 무한정 머무는
      // 현상이 실제로 재현되었습니다(Future 자체가 절대 끝나지 않음).
      // 답장 문장 조합은 순수 문자열 처리로 몇 밀리초 밖에 걸리지 않으므로,
      // 별도 워커 없이 메인 스레드에서 직접 계산합니다.
      final generated = await ReplyFailure.step(
        'GENERATE',
        () async => _generateReply(<String, dynamic>{
          'letterText': letterText,
          'style': style.name,
          'catName': catName,
          'emotionId': emotionId,
          'recentParts': [
            for (final row in rows)
              (row['parts'] as List? ?? const []).whereType<String>().toList(),
          ],
          'recentTexts': [
            if (saved != null) saved,
            ...rows.map((r) => r['reply'] as String),
            ...legacyReplies,
          ].take(40).toList(),
          'dislikedTexts': disliked,
          'avoidedTopics': offTopicCounts.entries
              .where(
                (e) => e.value >= 2 && e.value > (matchedCounts[e.key] ?? 0),
              )
              .map((e) => e.key)
              .toList(),
          'avoidedSituations': avoidedSituations.toList(),
          'preferredParts': preferredParts,
          'repetitionWindow': disliked.isEmpty ? 3 : 6,
        }),
        timeout: const Duration(seconds: 15),
      );
      final previousFeedback = feedback.get(id);
      _checkSource(sourceIsCurrent);
      try {
        await ReplyFailure.step(
          'SAVE',
          () => box.putAll({
            if (!premium && !refreshingSaved) quotaKey: used + 1,
            id: jsonEncode({
              'version': 1,
              'engineVersion': currentEngineVersion,
              'replySequence': nextSequence,
              'createdAt': row?['createdAt'] is String
                  ? row!['createdAt']
                  : clock().toUtc().toIso8601String(),
              'updatedAt': clock().toUtc().toIso8601String(),
              'id': id,
              'reply': generated.text,
              // Keep the original in the same durable row during migration.
              if (refreshingSaved) 'previousReply': saved,
              'parts': generated.parts,
              'topic': generated.topic,
              'style': style.name,
              if (emotionId != null) 'emotionId': emotionId,
              'situation': generated.situation,
            }),
          }),
        );
        await ReplyFailure.step('FLUSH', box.flush);
        // Ratings describe the old text, not its replacement. Clear only
        // after the replacement is durably saved.
        if (refreshingSaved) {
          await ReplyFailure.step('FEEDBACK', () async {
            await feedback.delete(id);
            await feedback.flush();
          });
        }
        _checkSource(sourceIsCurrent);
        if (persistSourceReply != null) {
          await persistSourceReply(generated.text);
        }
      } catch (_) {
        if (refreshingSaved) {
          // Restore both stores if a replacement cannot be committed. If the
          // device cannot write at all, the new row also retains previousReply.
          try {
            if (existing == null) {
              await box.delete(id);
            } else {
              await box.put(id, existing);
            }
            await box.flush();
            if (previousFeedback == null) {
              await feedback.delete(id);
            } else {
              await feedback.put(id, previousFeedback);
            }
            await feedback.flush();
          } catch (_) {
            // Keep the original stage error; never expose stored text in logs.
          }
        }
        rethrow;
      }
      return generated.text;
    }();
  }

  static String? _validReply(Object? value) =>
      value is String && value.trim().length >= 4 ? value : null;

  static bool _isCurrent(Map<String, dynamic>? row) =>
      row != null &&
      _validReply(row['reply']) != null &&
      row['engineVersion'] is int &&
      (row['engineVersion'] as int) >= currentEngineVersion;

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

  /// Call after loading a visible reply; absent history can mean a legacy cache.
  static Future<bool> needsRefresh(String id) => withStorageLock(() async {
    final box = await ReplyFailure.step(
      'HISTORY',
      _history,
      timeout: const Duration(seconds: 8),
    );
    final value = box.get(id);
    return !_isCurrent(value is String ? _historyRow(value) : null);
  }, timeout: const Duration(seconds: 15));

  /// Hive values are key-sorted, not insertion-sorted. A sequence gives updates
  /// and both letter kinds one ordering, even if the device clock moves back.
  /// Legacy rows use their timestamp ID (then key) as a deterministic fallback.
  static List<Map<String, dynamic>> _orderedHistory(Box box) {
    final rows = <Map<String, dynamic>>[];
    for (final key in box.keys) {
      final value = box.get(key);
      final row = value is String ? _historyRow(value) : null;
      if (row == null || _validReply(row['reply']) == null) continue;
      rows.add({...row, '_storageKey': key.toString()});
    }
    int legacyTime(Map<String, dynamic> row) {
      final parsed =
          DateTime.tryParse(row['updatedAt']?.toString() ?? '') ??
          DateTime.tryParse(row['createdAt']?.toString() ?? '');
      if (parsed != null) return parsed.microsecondsSinceEpoch;
      final match = RegExp(
        r'^(?:letter:|heart:)?(\d{10,20})(?:_|$)',
      ).firstMatch(row['_storageKey'] as String);
      final value = int.tryParse(match?.group(1) ?? '') ?? 0;
      // Older IDs may use milliseconds rather than microseconds.
      return value > 0 && value < 100000000000000 ? value * 1000 : value;
    }

    rows.sort((a, b) {
      final sa = a['replySequence'] is int ? a['replySequence'] as int : 0;
      final sb = b['replySequence'] is int ? b['replySequence'] as int : 0;
      final sequenceOrder = sb.compareTo(sa);
      if (sequenceOrder != 0) return sequenceOrder;
      final timeOrder = legacyTime(b).compareTo(legacyTime(a));
      if (timeOrder != 0) return timeOrder;
      return (b['_storageKey'] as String).compareTo(a['_storageKey'] as String);
    });
    return rows;
  }

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
    Future<void> Function()? restoreSource,
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
    final previous = box.get(id);
    final previousFeedback = feedback.get(id);
    try {
      if (deleteSource != null) await deleteSource();
      await box.delete(id);
      await box.flush();
      await feedback.delete(id);
      await feedback.flush();
    } catch (_) {
      // A failed deletion must not strand an undeleted letter without its
      // answer, or remove its source while reporting a failure to the reader.
      try {
        if (previous == null) {
          await box.delete(id);
        } else {
          await box.put(id, previous);
        }
        await box.flush();
        if (previousFeedback == null) {
          await feedback.delete(id);
        } else {
          await feedback.put(id, previousFeedback);
        }
        await feedback.flush();
      } catch (_) {}
      try {
        if (restoreSource != null) await restoreSource();
      } catch (_) {}
      rethrow;
    }
  }, timeout: const Duration(seconds: 15));
}

PersonalReply _generateReply(Map<String, dynamic> input) =>
    PersonalReplyEngine().compose(
      letterText: input['letterText'] as String,
      style: parseReplyStyle(input['style']),
      catName: input['catName'] as String,
      emotionId: input['emotionId'] as String?,
      recentParts: List<List<String>>.from(input['recentParts'] as List),
      recentTexts: List<String>.from(input['recentTexts'] as List),
      dislikedTexts: List<String>.from(input['dislikedTexts'] as List),
      avoidedTopics: Set<String>.from(input['avoidedTopics'] as List),
      avoidedSituations: Set<String>.from(input['avoidedSituations'] as List),
      preferredParts: List<String>.from(input['preferredParts'] as List),
      repetitionWindow: input['repetitionWindow'] as int,
    );
