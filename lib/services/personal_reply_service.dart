import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/reply_style.dart';
import 'hive_encryption.dart';
import 'personal_reply_engine.dart';

/// One queue across cats and heart letters; duplicate opens cannot race the
/// anti-repetition history. Once saved, a reply is never regenerated.
class PersonalReplyService {
  static Future<void> _tail=Future.value();
  static Future<Box> _history()=>HiveEncryption.openBox('personal_replies_local_user');
  static Future<Box> _feedback()=>HiveEncryption.openBox('reply_feedback_local_user');
  static Future<String> create({required String id,required String letterText,
    required ReplyStyle style,required String catName,List<String> legacyReplies=const [],
  }) {
    final result=_tail.catchError((Object _) {}).then((_) async {
      final box=await _history();
      final existing=box.get(id);
      if(existing is String) return (jsonDecode(existing) as Map)['reply'] as String;
      final rows=box.values.whereType<String>().toList().reversed.take(20)
        .map((value)=>Map<String,dynamic>.from(jsonDecode(value) as Map)).toList();
      final feedback=await _feedback();
      final disliked=[for(final row in rows)
        if(feedback.get(row['id'])=='repeated') row['reply'] as String];
      final offTopicCounts = <String, int>{};
      for (final row in rows) {
        if (feedback.get(row['id']) == 'off_topic' && row['topic'] is String) {
          final topic = row['topic'] as String;
          offTopicCounts[topic] = (offTopicCounts[topic] ?? 0) + 1;
        }
      }
      final generated=await compute(_generateReply, <String,dynamic>{
        'letterText':letterText,'style':style.name,'catName':catName,
        'recentParts':[for(final row in rows) List<String>.from(row['parts'] as List)],
        'recentTexts':[...rows.map((r)=>r['reply'] as String),...legacyReplies].take(20).toList(),
        'dislikedTexts':disliked,
        'avoidedTopics':offTopicCounts.entries.where((e) => e.value >= 2).map((e) => e.key).toList(),
      });
      await box.put(id,jsonEncode({'version':1,'id':id,'reply':generated.text,
        'parts':generated.parts,'topic':generated.topic,'style':style.name}));
      await box.flush();
      return generated.text;
    });
    _tail=result.then<void>((_) {},onError:(Object _,StackTrace __) {});
    return result;
  }
  static Future<String?> feedback(String id) async => (await _feedback()).get(id) as String?;
  static Future<void> setFeedback(String id,String? value) async {
    if(value!=null && !{'matched','off_topic','repeated'}.contains(value)) throw ArgumentError('Invalid feedback');
    final box=await _feedback();
    if(value==null) {await box.delete(id);} else {await box.put(id,value);}
    await box.flush();
  }
  static Future<void> remove(String id) {
    final result=_tail.catchError((Object _) {}).then((_) async {
      final box=await _history(); await box.delete(id); await box.flush();
      final feedback=await _feedback(); await feedback.delete(id); await feedback.flush();
    });
    _tail=result.catchError((Object _) {});
    return result;
  }
}

PersonalReply _generateReply(Map<String,dynamic> input) => PersonalReplyEngine().compose(
  letterText:input['letterText'] as String, style:parseReplyStyle(input['style']),
  catName:input['catName'] as String,
  recentParts:List<List<String>>.from(input['recentParts'] as List),
  recentTexts:List<String>.from(input['recentTexts'] as List),
  dislikedTexts:List<String>.from(input['dislikedTexts'] as List),
  avoidedTopics:Set<String>.from(input['avoidedTopics'] as List),
);
