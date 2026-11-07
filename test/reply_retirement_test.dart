import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/data/shadow_cats_data.dart';
import 'package:flutter_app/models/cat_care_state.dart';
import 'package:flutter_app/models/letter_entry.dart';
import 'package:flutter_app/models/reply_style.dart';
import 'package:flutter_app/models/special_letter_entry.dart';
import 'package:flutter_app/mongi/integration/mongi_garden_store.dart';
import 'package:flutter_app/providers/app_state_provider.dart';
import 'package:flutter_app/services/hive_encryption.dart';
import 'package:flutter_app/services/personal_reply_service.dart';
import 'package:flutter_app/services/reply_text_builder.dart';
import 'package:flutter_app/services/special_letter_service.dart';
import 'package:flutter_app/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  late Directory directory;
  late Box replies;
  const archived = '이전에 저장한 답장 원문은 그대로 남아 있어요.';

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('reply-retirement-');
    Hive.init(directory.path);
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (call) async => call.method == 'read'
              ? base64Encode(List<int>.filled(32, 7))
              : null,
        );
    await StorageService.setCurrentUser('local_user');
    await SpecialLetterService.setCurrentUser('local_user');
    replies = await HiveEncryption.openBox('personal_replies_local_user');
  });

  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Future<String> create(String id, {bool refresh = false}) =>
      PersonalReplyService.create(
        id: id,
        letterText: '오늘은 마음이 복잡했어요.',
        style: ReplyStyle.listen,
        catName: '고양이',
        refreshExisting: refresh,
      );

  test(
    'missing answers are never generated, including explicit old refresh',
    () async {
      await replies.put('quota:2026-10-20', 1);
      for (final refresh in [false, true]) {
        await expectLater(
          create('new', refresh: refresh),
          throwsA(isA<ReplyGenerationRetired>()),
        );
      }
      expect(await PersonalReplyService.savedReply('new'), isNull);
      expect(await PersonalReplyService.needsRefresh('new'), isFalse);
      expect(replies.toMap(), {'quota:2026-10-20': 1});
    },
  );

  test(
    'old refresh calls preserve exact archive, feedback and quota',
    () async {
      final original = jsonEncode({
        'reply': archived,
        'engineVersion': 0,
        'parts': [archived],
        'time': '2026-01-01T00:00:00.000',
      });
      await replies.put('old', original);
      await replies.put('quota:2026-10-20', 1);
      await PersonalReplyService.setFeedback('old', 'off_topic');
      expect(await create('old', refresh: true), archived);
      expect(await create('old'), archived);
      expect(replies.get('old'), original);
      expect(replies.get('quota:2026-10-20'), 1);
      expect(await PersonalReplyService.feedback('old'), 'off_topic');
      expect(await PersonalReplyService.needsRefresh('old'), isFalse);
    },
  );

  test(
    'legacy archive can be read without migration or source writes',
    () async {
      var writes = 0;
      final result = await PersonalReplyService.create(
        id: 'legacy',
        letterText: '오늘의 원문',
        style: ReplyStyle.listen,
        catName: '고양이',
        refreshExisting: true,
        legacyReply: archived,
        persistSourceReply: (_) async {
          writes++;
        },
      );
      expect(result, archived);
      expect(writes, 0);
      expect(replies.isEmpty, isTrue);
    },
  );

  test('cat letter and original text survive a retired old route', () async {
    final entry = LetterEntry(
      id: 'cat',
      catId: shadowCats.first.id,
      date: DateTime(2026, 10, 20),
      letterText: '아직 정리되지 않은 마음 그대로',
    );
    await StorageService.saveLetter(entry);
    await expectLater(
      buildReplyText(
        entry: entry,
        cat: shadowCats.first,
        history: [entry],
        growthStage: CatGrowthStage.baby,
        visitStreak: 1,
      ),
      throwsA(isA<ReplyGenerationRetired>()),
    );
    expect(StorageService.getAllLetters().single.toMap(), entry.toMap());
    expect(replies.isEmpty, isTrue);
    final app = AppStateProvider()..history = [entry];
    expect(app.letterWithUnseenReadyReply, isNull);
    expect(app.latestReadyReply, isNull);
    app.dispose();
  });

  test(
    'heart save is idempotent, retains garden reward and creates no reply',
    () async {
      final entry = await SpecialLetterService.sendLetter(
        type: SpecialLetterType.gratitude,
        letterText: '오늘 이야기를 들어줘서 고마워.',
        submissionId: 'heart-save',
      );
      final firstGarden = jsonEncode(MongiGardenStore.instance.value.toJson());
      final again = await SpecialLetterService.sendLetter(
        type: entry.type,
        letterText: entry.letterText,
        submissionId: entry.id,
      );
      expect(again.toMap(), entry.toMap());
      expect(SpecialLetterService.getAllEntries(), hasLength(1));
      expect(entry.replyText, isEmpty);
      expect(MongiGardenStore.instance.value.careDays, isNotEmpty);
      expect(jsonEncode(MongiGardenStore.instance.value.toJson()), firstGarden);
      expect(SpecialLetterService.unseenReadyReply, isNull);
      await expectLater(
        SpecialLetterService.ensureReply(entry),
        throwsA(isA<ReplyGenerationRetired>()),
      );
      expect(
        SpecialLetterService.getAllEntries().single.toMap(),
        entry.toMap(),
      );
      expect(replies.isEmpty, isTrue);
    },
  );

  test(
    'heart archive is readable without rewriting embedded legacy reply',
    () async {
      final entry = SpecialLetterEntry(
        id: 'heart-old',
        type: SpecialLetterType.love,
        letterText: '그날 남긴 내 마음',
        replyText: archived,
        createdAt: DateTime(2026, 1, 1),
      );
      final box = await HiveEncryption.openBox('special_letters_local_user');
      await box.put(entry.id, entry.toMap());
      expect(
        await SpecialLetterService.ensureReply(entry, refreshExisting: true),
        archived,
      );
      expect(box.get(entry.id), entry.toMap());
      expect(replies.isEmpty, isTrue);
    },
  );
}
