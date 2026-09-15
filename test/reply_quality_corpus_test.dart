import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/services/reply_situation.dart';
import 'package:flutter_app/services/personal_reply_engine.dart';
import 'package:flutter_app/models/reply_style.dart';

void main() {
  test(
    '50-case quality corpus routes without reversing ambiguous accounts',
    () {
      final cases =
          jsonDecode(File('tool/reply_quality_cases.json').readAsStringSync())
              as List;
      expect(cases.length, 50);
      for (final row in cases) {
        final text = row['text'] as String;
        expect(ReplySituation.detect(text)?.id, row['situation'], reason: text);
        for (final style in ReplyStyle.values) {
          final reply = PersonalReplyEngine(
            random: Random(42),
          ).compose(letterText: text, style: style, catName: '몽이');
          expect(reply.text, isNotEmpty);
          if (style == ReplyStyle.listen) expect(reply.parts.length, 3);
        }
      }
    },
  );
  test(
    'new situations retain repetition checks across 20 consecutive replies',
    () {
      final parts = <List<String>>[], texts = <String>[];
      for (var i = 0; i < 20; i++) {
        final reply = PersonalReplyEngine(random: Random(i)).compose(
          letterText: '나는 오늘 외로워.',
          style: ReplyStyle.listen,
          catName: '몽이',
          recentParts: parts.reversed.toList(),
          recentTexts: texts.reversed.toList(),
        );
        expect(texts.contains(reply.text), isFalse);
        parts.add(reply.parts);
        texts.add(reply.text);
      }
    },
  );
}
