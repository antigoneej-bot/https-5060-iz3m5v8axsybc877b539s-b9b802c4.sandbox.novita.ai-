import 'dart:convert';
import 'dart:io';
import '../lib/services/acceptance_reply_matcher.dart';

void main() {
  final cases = jsonDecode(File('tool/reply_quality_cases.json').readAsStringSync()) as List;
  for (final row in cases) {
    final text = row['text'] as String;
    final situation = row['situation'];
    final acceptId = AcceptanceReplyMatcher.detect(text);
    if (situation == null) {
      print('${acceptId ?? '-'}\t$text');
    }
  }
}
