import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_app/data/shadow_cats_data.dart';
import 'package:flutter_app/models/cat_care_state.dart';
import 'package:flutter_app/models/letter_entry.dart';
import 'package:flutter_app/services/hive_encryption.dart';
import 'package:flutter_app/services/reply_text_builder.dart';
import 'package:flutter_app/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  final started = <Future<String>>[];
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('reply-completion-');
    Hive.init(directory.path);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (call) async => call.method == 'read'
              ? base64Encode(List<int>.generate(32, (i) => i))
              : null,
        );
    await StorageService.setCurrentUser('local_user');
    for (final id in ['cached', 'saved', 'damaged']) {
      await StorageService.saveLetter(
        LetterEntry(
          id: id,
          catId: shadowCats.first.id,
          date: DateTime(2026, 1, 1),
          letterText: '오늘의 테스트 편지',
        ),
      );
    }
  });
  tearDown(() async {
    // An assertion failure must not close Hive underneath an outstanding reply.
    // Await real I/O completion; a two-second wall-clock cutoff races disk I/O
    // when the full suite and Android build share this Windows machine.
    await Future.wait(
      started.map(
        (future) =>
            future.then<void>((_) {}, onError: (Object _, StackTrace __) {}),
      ),
    );
    started.clear();
    await Hive.close();
    await directory.delete(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
  Future<String> open(String id) {
    final future = buildReplyText(
      entry: LetterEntry(
        id: id,
        catId: shadowCats.first.id,
        date: DateTime(2026, 1, 1),
        letterText: '오늘의 테스트 편지',
      ),
      cat: shadowCats.first,
      history: const [],
      growthStage: CatGrowthStage.baby,
      visitStreak: 1,
    );
    started.add(future);
    return future;
  }

  test(
    'cached reply completes, simultaneous opens share it, reopening works',
    () async {
      final cache = await HiveEncryption.openBox('reply_cache_local_user');
      await cache.put('cached', '이미 저장한 고양이 답장입니다.');
      final first = open('cached');
      final second = open('cached');
      expect(identical(first, second), isTrue);
      expect(await first, '이미 저장한 고양이 답장입니다.');
      expect(await second, '이미 저장한 고양이 답장입니다.');
      expect(await open('cached'), '이미 저장한 고양이 답장입니다.');
    },
  );
  test(
    'personal history reply reaches caller without regenerating stored text',
    () async {
      final history = await HiveEncryption.openBox(
        'personal_replies_local_user',
      );
      const reply = '이전에 생성하고 저장한 답장 그대로입니다.';
      await history.put('letter:saved', jsonEncode({'reply': reply}));
      expect(await open('saved'), reply);
      expect(jsonDecode(history.get('letter:saved') as String)['reply'], reply);
    },
  );
  test(
    'damaged legacy cache cannot hide a valid saved personal reply',
    () async {
      final cache = await HiveEncryption.openBox('reply_cache_local_user');
      final history = await HiveEncryption.openBox(
        'personal_replies_local_user',
      );
      const reply = '이미 저장되어 있던 온전한 답장입니다.';
      for (final damaged in ['', '   ', '…']) {
        await cache.put('damaged', damaged);
        await history.put('letter:damaged', jsonEncode({'reply': reply}));
        expect(await open('damaged'), reply);
        expect(await open('damaged'), reply);
      }
    },
  );
}
