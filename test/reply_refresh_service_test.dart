import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/data/replies/acceptance_reply_content.dart';
import 'package:flutter_app/data/shadow_cats_data.dart';
import 'package:flutter_app/models/cat_care_state.dart';
import 'package:flutter_app/models/letter_entry.dart';
import 'package:flutter_app/models/reply_style.dart';
import 'package:flutter_app/models/special_letter_entry.dart';
import 'package:flutter_app/services/access_policy.dart';
import 'package:flutter_app/services/hive_encryption.dart';
import 'package:flutter_app/services/personal_reply_service.dart';
import 'package:flutter_app/services/reply_text_builder.dart';
import 'package:flutter_app/services/special_letter_service.dart';
import 'package:flutter_app/services/storage_service.dart';
import 'package:flutter_app/utils/feature_flags.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  const oldReply = '예전에 저장한 답장입니다. 아직 그대로 읽을 수 있어요.';
  const quota = 'quota:2026-10-16';
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('reply-refresh-');
    Hive.init(directory.path);
    FeatureFlags.debugUnlockAllPremium = false;
    SharedPreferences.setMockInitialValues({});
    PersonalReplyService.clock = () => DateTime(2026, 10, 16);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (call) async => call.method == 'read'
              ? base64Encode(List<int>.filled(32, 7))
              : null,
        );
    await SpecialLetterService.setCurrentUser('local_user');
    await StorageService.setCurrentUser('local_user');
  });
  tearDown(() async {
    PersonalReplyService.clock = DateTime.now;
    await Hive.close();
    await directory.delete(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Future<String> reply(String id, {bool refresh = false, String? legacy}) =>
      PersonalReplyService.create(
        id: id,
        letterText: '나는 오늘 외로워.',
        style: ReplyStyle.listen,
        catName: '외로운 고양이',
        emotionId: 'lonely',
        refreshExisting: refresh,
        legacyReply: legacy,
      );

  test(
    'old answer remains unchanged until explicit once-per-version refresh',
    () async {
      final box = await HiveEncryption.openBox('personal_replies_local_user');
      await box.put('letter:old', jsonEncode({'reply': oldReply}));
      await box.put(quota, 1);
      await PersonalReplyService.setFeedback('letter:old', 'off_topic');
      expect(await reply('letter:old'), oldReply);
      expect(await PersonalReplyService.needsRefresh('letter:old'), isTrue);
      final results = await Future.wait([
        reply('letter:old', refresh: true),
        reply('letter:old', refresh: true),
      ]);
      expect(results.first, isNot(oldReply));
      expect(results.last, results.first);
      expect(await reply('letter:old'), results.first);
      expect(await reply('letter:old', refresh: true), results.first);
      expect(await PersonalReplyService.needsRefresh('letter:old'), isFalse);
      expect(await PersonalReplyService.feedback('letter:old'), isNull);
      expect(box.get(quota), 1);
      expect(
        jsonDecode(box.get('letter:old') as String)['engineVersion'],
        PersonalReplyService.currentEngineVersion,
      );
    },
  );

  test(
    'refresh flag without a saved answer cannot bypass the free quota',
    () async {
      final box = await HiveEncryption.openBox('personal_replies_local_user');
      await box.put(quota, 1);
      await expectLater(
        reply('letter:new', refresh: true),
        throwsA(isA<SubscriptionRequired>()),
      );
      await expectLater(
        reply('letter:damaged', refresh: true, legacy: '…'),
        throwsA(isA<SubscriptionRequired>()),
      );
      expect(box.containsKey('letter:new'), isFalse);
      expect(box.get(quota), 1);
    },
  );

  test('refreshing a saved answer leaves today free reply available', () async {
    final box = await HiveEncryption.openBox('personal_replies_local_user');
    await box.put('letter:old', jsonEncode({'reply': oldReply}));
    await reply('letter:old', refresh: true);
    expect(box.get(quota, defaultValue: 0), 0);
    await reply('letter:new');
    expect(box.get(quota), 1);
    await expectLater(
      reply('letter:another'),
      throwsA(isA<SubscriptionRequired>()),
    );
  });

  test(
    'canonical refreshed cat answer wins over preserved outer legacy cache',
    () async {
      final cache = await HiveEncryption.openBox('reply_cache_local_user');
      final box = await HiveEncryption.openBox('personal_replies_local_user');
      final cat = shadowCats.firstWhere((c) => c.id == 'lonely');
      final entry = LetterEntry(
        id: 'legacy',
        catId: cat.id,
        date: DateTime(2026, 10, 1),
        letterText: '나는 오늘 외로워.',
      );
      await StorageService.saveLetter(entry);
      Future<String> open({bool refresh = false}) => buildReplyText(
        entry: entry,
        cat: cat,
        history: [entry],
        growthStage: CatGrowthStage.baby,
        visitStreak: 1,
        refreshExisting: refresh,
      );
      await cache.put(entry.id, oldReply);
      await box.put(quota, 1);
      expect(await open(), oldReply);
      final refreshed = await open(refresh: true);
      expect(refreshed, isNot(oldReply));
      expect(cache.get(entry.id), oldReply);
      expect(await open(), refreshed);
      expect(box.get(quota), 1);
      expect(entry.letterText, '나는 오늘 외로워.');
    },
  );

  test(
    'heart refresh persists and stale entry cannot restore old text',
    () async {
      final entry = SpecialLetterEntry(
        id: 'heart-old',
        type: SpecialLetterType.gratitude,
        letterText: '친구가 도와줘서 고마워.',
        replyText: oldReply,
        createdAt: DateTime(2026, 10, 1),
      );
      final letters = await HiveEncryption.openBox(
        'special_letters_local_user',
      );
      final box = await HiveEncryption.openBox('personal_replies_local_user');
      await letters.put(entry.id, entry.toMap());
      await box.put(quota, 1);
      expect(await SpecialLetterService.ensureReply(entry), oldReply);
      final refreshed = await SpecialLetterService.ensureReply(
        entry,
        refreshExisting: true,
      );
      expect(refreshed, isNot(oldReply));
      expect(await SpecialLetterService.ensureReply(entry), refreshed);
      final saved = SpecialLetterService.getAllEntries().single;
      expect(saved.letterText, entry.letterText);
      expect(saved.createdAt, entry.createdAt);
      expect(saved.replyText, refreshed);
      expect(box.get(quota), 1);
    },
  );

  test(
    'deleted heart letter cannot be recreated by stale widget refresh',
    () async {
      final entry = SpecialLetterEntry(
        id: 'deleted',
        type: SpecialLetterType.gratitude,
        letterText: '고마워.',
        replyText: oldReply,
        createdAt: DateTime(2026, 10, 1),
      );
      await expectLater(
        SpecialLetterService.ensureReply(entry, refreshExisting: true),
        throwsStateError,
      );
      final box = await HiveEncryption.openBox('personal_replies_local_user');
      expect(box.containsKey('heart:deleted'), isFalse);
      expect(box.get(quota, defaultValue: 0), 0);
    },
  );

  test(
    'off-topic ratings from previous engine cannot block authored new replies',
    () async {
      final box = await HiveEncryption.openBox('personal_replies_local_user');
      for (var i = 0; i < 2; i++) {
        final id = 'letter:old-$i';
        await box.put(
          id,
          jsonEncode({
            'version': 1,
            'id': id,
            'reply': oldReply,
            'topic': 'general',
            'style': 'listen',
            'situation': 'lonely',
          }),
        );
        await PersonalReplyService.setFeedback(id, 'off_topic');
      }
      final result = await reply('letter:new');
      final texts = acceptanceReplyContent['04']!.replies.map((r) => r.text);
      expect(texts.any((text) => result.contains(text)), isTrue);
    },
  );
}
