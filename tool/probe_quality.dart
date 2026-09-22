import 'dart:convert';
import 'dart:io';
import 'dart:math';
import '../lib/services/personal_reply_engine.dart';
import '../lib/models/reply_style.dart';

void main() {
  final cases = jsonDecode(File('tool/reply_quality_cases.json').readAsStringSync()) as List;
  final engine = PersonalReplyEngine(random: Random(42));
  for (final row in cases) {
    final text = row['text'] as String;
    final reply = engine.compose(letterText: text, style: ReplyStyle.listen, catName: '몽이');
    print('${reply.parts.length}\t${reply.situation}\t$text');
  }
}
