import '../tool/reply_contract.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/services/reply_situation.dart';
import 'package:flutter_app/services/personal_reply_engine.dart';
import 'package:flutter_app/models/reply_style.dart';
import 'package:flutter_app/data/replies/acceptance_reply_content.dart';

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
          expect(followsReplyContract(reply, style), isTrue, reason: text);
        }
      }
    },
  );
  test(
    'authored finite emotion pool stays relevant and uses fresh replies when available',
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
        final pool = acceptanceReplyContent['04']!.receive
            .map((r) => r.text)
            .toSet();
        final recent = parts.reversed.take(3).expand((p) => p).toSet();
        final fresh = pool.difference(recent);
        expect(reply.situation, 'accept:04');
        expect(reply.parts, hasLength(1));
        expect(pool, contains(reply.parts.single));
        if (fresh.isNotEmpty) expect(fresh, contains(reply.parts.single));
        parts.add(reply.parts);
        texts.add(reply.text);
      }
    },
  );
}
