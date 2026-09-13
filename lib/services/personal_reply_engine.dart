import 'dart:math';
import '../data/replies/personal_reply_content.dart';
import '../models/reply_style.dart';

class PersonalReply {
  final String text;
  final List<String> parts;
  final String topic;
  const PersonalReply(this.text, this.parts, this.topic);
}

/// Offline lexical routing, NOT semantic understanding. Never follows diary
/// instructions, invents memories, diagnoses, or claims to know another's intent.
class PersonalReplyEngine {
  final Random random;
  PersonalReplyEngine({Random? random}) : random = random ?? Random();
  static const _topics = <String,List<String>>{
    'work':['회사','직장','상사','동료','업무','야근','면접'],
    'friend':['친구','우정'],
    'family':['가족','엄마','아빠','어머니','아버지','남편','아내','부모'],
    'health':['병원','진료','검사 결과','검사결과','통증','몸이 아','건강'],
    'loss':['장례','세상을 떠','떠나보','돌아가셨'],
    'achievement':['합격','불합격','수상','완성','해냈','성취','승진'],
  };
  static String topicFor(String text) {
    final matched = _topics.entries.where((e) => e.value.any(text.contains)).map((e)=>e.key).toList();
    // Mixed subjects should not be reduced to a guessed main story.
    return matched.length == 1 ? matched.single : 'general';
  }
  static String? excerpt(String text) {
    final clean = text.trim();
    if (clean.isEmpty) return null;
    if (clean.runes.length <= 180) return clean;
    // Only complete, bounded sentences. Do not cut off a following negation.
    final sentences = RegExp(r'[^.!?\n]+[.!?\n]').allMatches(clean)
      .map((m)=>m.group(0)!.trim()).where((s)=>s.runes.length >= 8 && s.runes.length <= 180).toList();
    return sentences.isEmpty ? null : sentences.last;
  }
  static double similarity(String a, String b) {
    Set<String> grams(String value) {
      final runes = value.replaceAll(RegExp(r'[\s\p{P}]',unicode:true),'').runes.toList();
      return {for(var i=0;i+2<runes.length;i++) String.fromCharCodes(runes.sublist(i,i+3))};
    }
    final x=grams(a), y=grams(b);
    if(x.isEmpty || y.isEmpty) return a==b ? 1 : 0;
    return x.intersection(y).length / x.union(y).length;
  }
  PersonalReply compose({required String letterText, required ReplyStyle style,
    required String catName, List<List<String>> recentParts=const [],
    List<String> recentTexts=const [], List<String> dislikedTexts=const [],
    Set<String> avoidedTopics=const {},
  }) {
    final detectedTopic=topicFor(letterText);
    final topic=avoidedTopics.contains(detectedTopic) ? 'general' : detectedTopic;
    final quote=excerpt(letterText);
    final anchor=quote != null
      ? '네 편지에서 이 말을 읽었어.\n「$quote」'
      : letterText.trim().isEmpty
        ? '오늘은 글 대신 마음의 표시를 남겨주었네. 쓰지 않은 사연까지 추측하지 않을게.'
        : '긴 편지를 남겨주었네. 문장을 잘라 뜻을 바꾸거나, 내가 전부 이해했다고 말하지 않을게.';
    // Select the least repetitive candidate. Relevance and requested mode remain
    // hard constraints even after all finite phrase pools have been used.
    PersonalReply? best;
    var bestScore=double.infinity;
    final cooldown = recentParts.take(3).expand((parts) => parts).toSet();
    final voice = catName.runes.fold<int>(0, (sum, rune) => sum + rune) % 2;
    for(var attempt=0;attempt<48;attempt++) {
      String pick(List<String> values) {
        final fresh = values.where((line) => !cooldown.contains(line)).toList();
        final pool = fresh.isEmpty ? values : fresh;
        return pool[random.nextInt(pool.length)];
      }
      final opening=pick(replyOpenings);
      final listening=pick(topicListeningLines[topic]!);
      final ending=pick([...replyClosings, ...(voice == 0 ? quietCatClosings : warmCatClosings)]);
      final effectiveStyle=letterText.trim().isEmpty ? ReplyStyle.listen : style;
      final extra=switch(effectiveStyle) {
        ReplyStyle.listen=>'',
        ReplyStyle.reflect=>pick(reflectionQuestions[topic]!),
        ReplyStyle.suggest=>pick(smallSuggestions[topic]!),
      };
      final parts=[opening,listening,if(extra.isNotEmpty) extra,ending];
      final body=parts.join('\n\n');
      var score=0.0;
      for(var i=0;i<recentParts.length && i<20;i++) {
        final weight=1.0/(1+i*.12);
        for(final part in parts) {
          for(final previous in recentParts[i]) {
            final sim=similarity(part,previous);
            if(sim>.35) score+=sim*weight*4;
          }
        }
      }
      for(final previous in recentTexts.take(20)) {
        for(final part in parts) { if(previous.contains(part)) score+=2; }
        score+=similarity(body,previous)*2;
      }
      for(final previous in dislikedTexts.take(20)) {
        for(final part in parts) { if(previous.contains(part)) score+=8; }
      }
      if(score<bestScore) {
        bestScore=score;
        final text=[opening,anchor,listening,if(extra.isNotEmpty) extra,ending,'— $catName'].join('\n\n');
        best=PersonalReply(text,parts,topic);
      }
    }
    return best!;
  }
}
