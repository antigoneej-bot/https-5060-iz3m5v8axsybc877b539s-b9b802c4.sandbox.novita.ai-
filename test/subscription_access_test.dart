import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/services/access_policy.dart';
import 'package:flutter_app/services/backup_service.dart';
import 'package:flutter_app/services/hive_encryption.dart';
import 'package:flutter_app/services/personal_reply_service.dart';
import 'package:flutter_app/services/subscription_service.dart';
import 'package:flutter_app/models/reply_style.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('subscription-access-');
    Hive.init(dir.path);
    SharedPreferences.setMockInitialValues({'is_premium_subscriber': true});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (call) async => call.method == 'read'
              ? base64Encode(List<int>.filled(32, 7))
              : null,
        );
    PersonalReplyService.clock = () => DateTime(2026, 9, 16);
  });
  tearDown(() async {
    PersonalReplyService.clock = DateTime.now;
    await Hive.close();
    await dir.delete(recursive: true);
  });
  Future<String> reply(String id) => PersonalReplyService.create(
    id: id,
    letterText: '오늘 조금 외로웠어.',
    style: ReplyStyle.listen,
    catName: '몽이',
  );

  test('local premium preference alone cannot unlock subscription', () async {
    expect(await SubscriptionService().isPremium(), isFalse);
  });
  test('concurrent cat and heart replies share one free quota', () async {
    final results = await Future.wait([
      reply('letter:one').then<Object>((v) => v, onError: (Object e) => e),
      reply('heart:two').then<Object>((v) => v, onError: (Object e) => e),
    ]);
    expect(results.whereType<String>(), hasLength(1));
    expect(results.whereType<SubscriptionRequired>(), hasLength(1));
    final box = await HiveEncryption.openBox('personal_replies_local_user');
    expect(box.get('quota:2026-09-16'), 1);
  });
  test(
    'saved replies remain readable; deletion does not reset quota; next day resets',
    () async {
      final first = await reply('letter:one');
      expect(await reply('letter:one'), first);
      await PersonalReplyService.remove('letter:one');
      await expectLater(
        reply('letter:two'),
        throwsA(isA<SubscriptionRequired>()),
      );
      PersonalReplyService.clock = () => DateTime(2026, 9, 17);
      expect(await reply('letter:two'), isNotEmpty);
    },
  );
  test('legacy saved reply remains readable with exhausted quota', () async {
    final box = await HiveEncryption.openBox('personal_replies_local_user');
    await box.put('letter:old', jsonEncode({'reply': '이미 받은 온전한 답장'}));
    await box.put('quota:2026-09-16', 1);
    expect(await reply('letter:old'), '이미 받은 온전한 답장');
  });
  test('backup accepts quota rows without changing existing reply schema', () {
    Map<String, dynamic> backup(Object value) => {
      'schema': 1,
      'createdAt': '2026-09-16T00:00:00Z',
      'settings': {},
      'boxes': {
        'personal_replies': [
          {'key': 'quota:2026-09-16', 'value': value},
        ],
      },
    };
    expect(() => BackupService.validate(backup(1)), returnsNormally);
    expect(() => BackupService.validate(backup(-1)), throwsFormatException);
    expect(
      () => BackupService.validate(backup('unlimited')),
      throwsFormatException,
    );
  });
}
