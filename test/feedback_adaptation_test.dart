import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_app/services/hive_encryption.dart';
import 'package:flutter_app/services/personal_reply_service.dart';
import 'package:flutter_app/models/reply_style.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'historical feedback is preserved without generating or rewriting any reply',
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
      PersonalReplyService.clock = () => DateTime(2026, 9, 16);
      addTearDown(() => PersonalReplyService.clock = DateTime.now);
      final box = await HiveEncryption.openBox('personal_replies_local_user');
      const first = '그때 저장한 답장 원문이에요.';
      final original = jsonEncode({'reply': first, 'engineVersion': 0});
      await box.put('first', original);
      await PersonalReplyService.setFeedback('first', 'off_topic');
      PersonalReplyService.clock = () => DateTime(2026, 9, 17);
      await expectLater(
        PersonalReplyService.create(
          id: 'second',
          letterText: '나는 오늘 외로워.',
          style: ReplyStyle.listen,
          catName: '몽이',
        ),
        throwsA(isA<ReplyGenerationRetired>()),
      );
      expect(box.containsKey('second'), isFalse);
      expect(box.get('first'), original);
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
