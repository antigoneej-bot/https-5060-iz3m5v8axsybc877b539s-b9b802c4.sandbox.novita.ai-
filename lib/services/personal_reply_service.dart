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
    final result = _tail.catchError((Object _) {}).then((_) async {
      final box = await _history();
      final existing = box.get(id);
      if (existing is String)
        return (jsonDecode(existing) as Map)['reply'] as String;
      final premium = await SubscriptionService().isPremium();
      final day = AccessPolicy.dayKey(clock());
      final quotaKey = 'quota:$day';
      final used = box.get(quotaKey, defaultValue: 0) as int;
      if (!AccessPolicy.newReplyAllowed(premium: premium, used: used)) {
        throw const SubscriptionRequired(
          '편지는 저장되어 있어요. 무료 답장은 하루 1회 제공돼요. 추가 답장은 마음냥 구독으로 만나보세요.',
        );
      }
      final rows = box.values
          .whereType<String>()
          .toList()
          .reversed
          .take(20)
          .map((value) => Map<String, dynamic>.from(jsonDecode(value) as Map))
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
            preferredParts.addAll(List<String>.from(row['parts'] as List));
        }
        if (feedback.get(row['id']) == 'off_topic' &&
            row['situation'] is String)
          avoidedSituations.add(row['situation'] as String);
        if (feedback.get(row['id']) == 'off_topic' && row['topic'] is String) {
          final topic = row['topic'] as String;
          offTopicCounts[topic] = (offTopicCounts[topic] ?? 0) + 1;
        }
      }
      final generated = await compute(_generateReply, <String, dynamic>{
        'letterText': letterText,
        'style': style.name,
        'catName': catName,
        'recentParts': [
          for (final row in rows) List<String>.from(row['parts'] as List),
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
    });
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  static Future<String?> feedback(String id) async =>
      (await _feedback()).get(id) as String?;
  static Future<void> setFeedback(String id, String? value) {
    if (value != null && !{'matched', 'off_topic', 'repeated'}.contains(value))
      throw ArgumentError('Invalid feedback');
    final result = _tail.then((_) async {
      final box = await _feedback();
      if (value == null) {
        await box.delete(id);
      } else {
        await box.put(id, value);
      }
      await box.flush();
    });
    _tail = result.catchError((Object _) {});
    return result;
  }

  static Future<void> remove(String id) {
    final result = _tail.catchError((Object _) {}).then((_) async {
      final box = await _history();
      await box.delete(id);
      await box.flush();
      final feedback = await _feedback();
      await feedback.delete(id);
      await feedback.flush();
    });
    _tail = result.catchError((Object _) {});
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
