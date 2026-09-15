import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_app/services/hive_encryption.dart';
import 'package:flutter_app/services/personal_reply_service.dart';
import 'package:flutter_app/services/reply_situation.dart';
import 'package:flutter_app/models/reply_style.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'saved feedback affects the next reply without rewriting old replies',
    () async {
      final dir = await Directory.systemTemp.createTemp('reply-feedback-');
      Hive.init(dir.path);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
            (call) async => call.method == 'read'
                ? base64Encode(List<int>.filled(32, 7))
                : null,
          );
      final first = await PersonalReplyService.create(
        id: 'first',
        letterText: '나는 오늘 외로워.',
        style: ReplyStyle.listen,
        catName: '몽이',
      );
      await PersonalReplyService.setFeedback('first', 'off_topic');
      await PersonalReplyService.create(
        id: 'second',
        letterText: '나는 오늘 외로워.',
        style: ReplyStyle.listen,
        catName: '몽이',
      );
      final box = await HiveEncryption.openBox('personal_replies_local_user');
      final second = jsonDecode(box.get('second') as String) as Map;
      expect(
        (second['parts'] as List).any(
          ReplySituation.detect('나는 오늘 외로워.')!.listening.contains,
        ),
        false,
      );
      await PersonalReplyService.setFeedback('first', 'matched');
      expect(
        await PersonalReplyService.create(
          id: 'first',
          letterText: '나는 오늘 외로워.',
          style: ReplyStyle.listen,
          catName: '몽이',
        ),
        first,
      );
      expect(await PersonalReplyService.feedback('first'), 'matched');
      await Hive.close();
      await dir.delete(recursive: true);
    },
  );
}
