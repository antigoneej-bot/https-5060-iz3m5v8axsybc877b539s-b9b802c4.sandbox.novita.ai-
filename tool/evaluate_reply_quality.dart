import 'dart:convert';
import 'dart:io';
import 'dart:math';
import '../lib/services/personal_reply_engine.dart';
import '../lib/services/reply_situation.dart';
import '../lib/models/reply_style.dart';

void main() {
  final cases =
      jsonDecode(File('tool/reply_quality_cases.json').readAsStringSync())
          as List;
  final results = <Map<String, dynamic>>[];
  final output = StringBuffer(
    '# 답장 검토용 50개 사연 · 150개 답장\n\n작성한 가상 사연입니다. 객관적 공감 점수는 아직 없습니다. 검토자는 사연 이해 30 / 공감 25 / 자연스러움 15 / 다양성 15 / 요청 존중 15로 평가해 주세요. 사실 반전·없는 사건·부적절한 조언은 점수와 별도로 기록합니다.\n',
  );
  var recognized = 0;
  for (var i = 0; i < cases.length; i++) {
    final row = cases[i] as Map;
    final text = row['text'] as String;
    final actual = ReplySituation.detect(text)?.id;
    if (actual != row['situation'])
      throw StateError(
        'case ${i + 1}: expected ${row['situation']}, got $actual',
      );
    if (actual != null) recognized++;
    output.writeln('\n## 사연 ${i + 1}\n\n$text\n');
    for (final style in ReplyStyle.values) {
      final reply = PersonalReplyEngine(
        random: Random(i * 3 + style.index),
      ).compose(letterText: text, style: style, catName: '몽이');
      output.writeln('### ${style.label}\n\n${reply.text}\n');
      results.add({
        'case': i + 1,
        'style': style.name,
        'input': text,
        'situation': actual,
        'reply': reply.text,
      });
    }
  }
  Directory('verification/reply80').createSync(recursive: true);
  File(
    'verification/reply80/replies.json',
  ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(results));
  File('REPLY_150_REVIEW_KO.md').writeAsStringSync(output.toString());
  File('verification/reply80/checks.json').writeAsStringSync(
    jsonEncode({
      'cases': cases.length,
      'replies': results.length,
      'matchedSituation': recognized,
      'fallback': cases.length - recognized,
      'humanQualityScore': null,
      'note':
          'Pattern checks only, not a validated empathy or comprehension score.',
    }),
  );
  print(
    '50 scenario routing checks passed; 150 replies exported; $recognized recognized, ${cases.length - recognized} fallbacks.',
  );
}
