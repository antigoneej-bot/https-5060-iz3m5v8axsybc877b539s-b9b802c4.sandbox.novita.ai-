import '../tool/reply_contract.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/data/replies/reply_tone_content.dart';
import 'package:flutter_app/models/reply_style.dart';
import 'package:flutter_app/services/personal_reply_engine.dart';
import 'package:flutter_app/services/reply_tone.dart';

void main() {
  test('explicit emotion, negation, quoted speaker and mixed emotion corpus', () {
    final cases = jsonDecode(File('tool/reply_tone_cases.json').readAsStringSync()) as List;
    for (final row in cases) {
      expect(ReplyTone.detect(row['text'] as String), row['tone'], reason: row['text'] as String);
    }
  });
  test('gratitude screenshot gets gratitude and completion, never hardship filler', () {
    const text = '오늘도 무사히 일을 마쳤습니다. 함께한 모든 이들에게 감사합니다.';
    for (var seed = 0; seed < 20; seed++) {
      for (final style in ReplyStyle.values) {
        for (final cat in ['지적인 고양이', '마음편지 고양이']) {
          final reply = PersonalReplyEngine(random: Random(seed)).compose(
            letterText: text, style: style, catName: cat);
          expect(reply.situation, 'accept:18');
          expect(reply.text, contains('무사히'));
          expect(reply.text, contains('함께한'));
          expect(reply.text, isNot(contains(text)));
          expect(reply.text, isNot(contains('멋진 마무리')));
          expect(reply.text, isNot(contains('네 편지에서')));
          expect(RegExp('고마|고맙|감사').hasMatch(reply.text), isTrue);
          expect(reply.text, endsWith('— $cat'));
          expect(followsReplyContract(reply, style), isTrue);
          if (style == ReplyStyle.listen) {
            expect(reply.parts.any(replyToneContent['gratitude_complete']!['suggestions']!.contains), isFalse);
          }
        }
      }
    }
  });
  test('explicit listening request overrides selected suggestion mode', () {
    final reply = PersonalReplyEngine(random: Random(1)).compose(
      letterText: '너무 속상해. 조언하지 말고 그냥 들어줘.',
      style: ReplyStyle.suggest, catName: '몽이');
    expect(reply.situation, 'accept:23');
    expect(followsReplyContract(reply, ReplyStyle.listen), isTrue);
    expect(containsNoExtraModule(reply), isTrue);
    expect(reply.text, isNot(contains('?')));
  });
  test('negative feedback can disable a mismatched tone', () {
    final reply = PersonalReplyEngine(random: Random(1)).compose(
      letterText: '고마워.', style: ReplyStyle.listen, catName: '몽이',
      avoidedSituations: {'tone:gratitude'});
    expect(reply.situation, 'tone:neutral');
  });
  test('all authored pools are non-empty and provide variation', () {
    for (final tone in replyToneContent.values) {
      for (final name in ['openings', 'listening', 'closings', 'reflections', 'suggestions']) {
        expect(tone[name]!.length, greaterThanOrEqualTo(4));
        expect(tone[name]!.toSet().length, tone[name]!.length);
      }
    }
  });
}
