import 'dart:async';
import 'reply_situation.dart';
import 'access_policy.dart';
import 'subscription_service.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/reply_style.dart';
import 'hive_encryption.dart';
import 'personal_reply_engine.dart';

/// One queue across cats and heart letters; duplicate opens cannot race the
/// anti-repetition history. Once saved, a reply is never regenerated.
class PersonalReplyService {
  @visibleForTesting
  static DateTime Function() clock = DateTime.now;
  static Future<void> _tail = Future.value();
  static Future<Box> _history() =>
      HiveEncryption.openBox('personal_replies_local_user');
  static Future<Box> _feedback() =>
      HiveEncryption.openBox('reply_feedback_local_user');
  static Future<String> create({
    required String id,
    required String letterText,
    required ReplyStyle style,
    required String catName,
    List<String> legacyReplies = const [],
  }) {
    // _tail 은 여러 편지의 답장 생성 요청이 서로 겹치지 않도록 순서를
    // 매기는 전역 큐입니다. 만약 아래 본문이 내부적으로 어딘가에서
    // (예: 보안 저장소 read, Hive box open 등) 영원히 끝나지 않는
    // await 를 만나면, 이 Future 자체가 완결되지 않아 _tail 이 영구히
    // 멈추고 그 뒤로는 어떤 편지를 열어도 답장이 계속 뜨지 않는 문제가
    // 실제로 발생했습니다(답장 화면은 자체 30초 타임아웃으로 에러만
    // 보여줄 뿐, 이 큐에 걸린 원본 작업은 취소되지 않았기 때문). 이를
    // 막기 위해 본문 전체를 25초 타임아웃으로 감싸, 어떤 지점에서
    // 멈추더라도 큐가 다음 요청으로 넘어갈 수 있게 합니다.
    final result = _tail
        .catchError((Object _) {})
        .then((_) => _createBody(id, letterText, style, catName, legacyReplies))
        .timeout(
          const Duration(seconds: 25),
          onTimeout: () => throw TimeoutException(
            '답장 생성이 지연되고 있어요. 잠시 후 다시 시도해 주세요.',
          ),
        );
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  static Future<String> _createBody(
    String id,
    String letterText,
    ReplyStyle style,
    String catName,
    List<String> legacyReplies,
  ) {
    return () async {
      final box = await _history();
      final existing = box.get(id);
      if (existing is String) {
        // 과거(더 이전) 버전에서 답장 생성 도중 예외가 발생해, 완결된
        // 문장이 아니라 특수문자 한두 글자만 저장된 손상 데이터가 드물게
        // 남아있을 수 있습니다. 그런 값을 그대로 돌려주면 사용자는 몇 번을
        // 다시 열어봐도 계속 깨진 답장만 보게 되므로, 사람이 쓴 문장으로
        // 보기 어려운 극단적으로 짧은 값(공백 제외 4자 미만)은 손상된
        // 것으로 간주하고 새로 생성해 덮어씁니다. 정상적인 짧은 레거시
        // 답장(예: 10자 안팎)은 그대로 보존됩니다.
        try {
          final reply = (jsonDecode(existing) as Map)['reply'];
          if (reply is String && reply.trim().length >= 4) return reply;
        } catch (_) {
          // 파싱 실패 시에도 아래로 내려가 재생성합니다.
        }
      }
      // 구독 확인이 네트워크/캐시 문제로 멈추면 답장 전체가 무한정 멈추는
      // 것을 막기 위해 타임아웃을 둡니다(8초 지나면 실패로 처리해 재시도
      // 버튼이 뜨도록 함).
      final premium = await SubscriptionService().isPremium().timeout(
        const Duration(seconds: 8),
      );
      final day = AccessPolicy.dayKey(clock());
      final quotaKey = 'quota:$day';
      final used = box.get(quotaKey, defaultValue: 0) as int;
      if (!AccessPolicy.newReplyAllowed(premium: premium, used: used)) {
        throw const SubscriptionRequired(
          '편지는 저장되어 있어요. 무료 답장은 하루 1회 제공돼요. 추가 답장은 마음냥 구독으로 만나보세요.',
        );
      }
      // 과거 답장 이력 중 일부가 손상된 JSON이거나 parts가 누락되어 있어도
      // (예: 이전 버전에서 저장된 데이터) 전체 조회가 실패해 새 답장 생성을
      // 막지 않도록, 개별 행 파싱 실패는 건너뜁니다. 원본 저장 데이터는
      // 건드리지 않습니다.
      final rows = box.values
          .whereType<String>()
          .toList()
          .reversed
          .take(20)
          .map(_historyRow)
          .whereType<Map<String, dynamic>>()
          .toList();
      final feedback = await _feedback();
      final disliked = [
        for (final row in rows)
          if (feedback.get(row['id']) == 'repeated') row['reply'] as String,
      ];
      final offTopicCounts = <String, int>{};
      final matchedCounts = <String, int>{};
      final avoidedSituations = <String>{};
      final preferredParts = <String>[];
      for (final row in rows) {
        if (feedback.get(row['id']) == 'matched') {
          final topic = row['topic'] as String? ?? 'general';
          matchedCounts[topic] = (matchedCounts[topic] ?? 0) + 1;
          if (topic == PersonalReplyEngine.topicFor(letterText) &&
              row['style'] == style.name)
            preferredParts.addAll(
              (row['parts'] as List? ?? const []).whereType<String>().toList(),
            );
        }
        if (feedback.get(row['id']) == 'off_topic' &&
            row['situation'] is String)
          avoidedSituations.add(row['situation'] as String);
        if (feedback.get(row['id']) == 'off_topic' && row['topic'] is String) {
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
      final generated = _generateReply(<String, dynamic>{
        'letterText': letterText,
        'style': style.name,
        'catName': catName,
        'recentParts': [
          for (final row in rows)
            (row['parts'] as List? ?? const []).whereType<String>().toList(),
        ],
        'recentTexts': [
          ...rows.map((r) => r['reply'] as String),
          ...legacyReplies,
        ].take(20).toList(),
        'dislikedTexts': disliked,
        'avoidedTopics': offTopicCounts.entries
            .where((e) => e.value >= 2 && e.value > (matchedCounts[e.key] ?? 0))
            .map((e) => e.key)
            .toList(),
        'avoidedSituations': avoidedSituations.toList(),
        'preferredParts': preferredParts,
        'repetitionWindow': disliked.isEmpty ? 3 : 6,
      });
      await box.putAll({
        if (!premium) quotaKey: used + 1,
        id: jsonEncode({
          'version': 1,
          'id': id,
          'reply': generated.text,
          'parts': generated.parts,
          'topic': generated.topic,
          'style': style.name,
          'situation': ReplySituation.detect(letterText)?.id,
        }),
      });
      await box.flush();
      return generated.text;
    }();
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

  static Future<String?> feedback(String id) async =>
      (await _feedback()).get(id) as String?;
  static Future<void> setFeedback(String id, String? value) {
    if (value != null && !{'matched', 'off_topic', 'repeated'}.contains(value))
      throw ArgumentError('Invalid feedback');
    // create() 와 같은 이유로, 이 작업도 큐(_tail)를 영구히 막을 수 없도록
    // 전체를 타임아웃으로 감쌉니다.
    final result = _tail
        .catchError((Object _) {})
        .then((_) async {
          final box = await _feedback();
          if (value == null) {
            await box.delete(id);
          } else {
            await box.put(id, value);
          }
          await box.flush();
        })
        .timeout(const Duration(seconds: 15));
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  static Future<void> remove(String id) {
    // create() 와 같은 이유로, 이 작업도 큐(_tail)를 영구히 막을 수 없도록
    // 전체를 타임아웃으로 감쌉니다.
    final result = _tail
        .catchError((Object _) {})
        .then((_) async {
          final box = await _history();
          await box.delete(id);
          await box.flush();
          final feedback = await _feedback();
          await feedback.delete(id);
          await feedback.flush();
        })
        .timeout(const Duration(seconds: 15));
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }
}

PersonalReply _generateReply(Map<String, dynamic> input) =>
    PersonalReplyEngine().compose(
      letterText: input['letterText'] as String,
      style: parseReplyStyle(input['style']),
      catName: input['catName'] as String,
      recentParts: List<List<String>>.from(input['recentParts'] as List),
      recentTexts: List<String>.from(input['recentTexts'] as List),
      dislikedTexts: List<String>.from(input['dislikedTexts'] as List),
      avoidedTopics: Set<String>.from(input['avoidedTopics'] as List),
      avoidedSituations: Set<String>.from(input['avoidedSituations'] as List),
      preferredParts: List<String>.from(input['preferredParts'] as List),
      repetitionWindow: input['repetitionWindow'] as int,
    );
