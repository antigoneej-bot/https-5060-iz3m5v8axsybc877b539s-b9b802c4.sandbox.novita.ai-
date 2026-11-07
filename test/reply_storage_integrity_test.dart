import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
// Fault injection uses Hive's documented testing fields, never app data files.
// ignore: implementation_imports
import 'package:hive/src/box/box_base_impl.dart';
// ignore: implementation_imports
import 'package:hive/src/backend/vm/storage_backend_vm.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/data/shadow_cats_data.dart';
import 'package:flutter_app/models/cat_care_state.dart';
import 'package:flutter_app/models/letter_entry.dart';
import 'package:flutter_app/models/reply_style.dart';
import 'package:flutter_app/models/special_letter_entry.dart';
import 'package:flutter_app/services/hive_encryption.dart';
import 'package:flutter_app/services/personal_reply_service.dart';
import 'package:flutter_app/services/reply_text_builder.dart';
import 'package:flutter_app/services/special_letter_service.dart';
import 'package:flutter_app/services/storage_service.dart';
import 'package:flutter_app/services/subscription_service.dart';

class _OneDelayedWrite implements RandomAccessFile {
  final RandomAccessFile inner;
  final entered = Completer<void>();
  final gate = Completer<void>();
  bool _first = true;
  _OneDelayedWrite(this.inner);

  @override
  Future<RandomAccessFile> writeFrom(
    List<int> buffer, [
    int start = 0,
    int? end,
  ]) async {
    if (_first) {
      _first = false;
      entered.complete();
      await gate.future;
    }
    return inner.writeFrom(buffer, start, end);
  }

  @override
  Future<RandomAccessFile> setPosition(int p) => inner.setPosition(p);
  @override
  Future<RandomAccessFile> flush() => inner.flush();
  @override
  Future<void> close() => inner.close();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  const oldReply = '기존에 저장되어 있던 소중한 답장입니다.';
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('reply-integrity-');
    Hive.init(directory.path);
    SharedPreferences.setMockInitialValues({});
    SubscriptionService.debugIsPremiumOverride = true;
    PersonalReplyService.clock = () => DateTime(2026, 10, 16);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (call) async => call.method == 'read'
              ? base64Encode(List<int>.filled(32, 7))
              : null,
        );
    await StorageService.setCurrentUser('local_user');
    await SpecialLetterService.setCurrentUser('local_user');
  });
  tearDown(() async {
    SubscriptionService.debugIsPremiumOverride = null;
    PersonalReplyService.clock = DateTime.now;
    await Hive.close();
    await directory.delete(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Future<String> create(String id, {bool refresh = false}) =>
      PersonalReplyService.create(
        id: id,
        letterText: '나는 오늘 외로워.',
        style: ReplyStyle.listen,
        catName: '외로운 고양이',
        emotionId: 'lonely',
        refreshExisting: refresh,
      );

  Future<String> openCat(LetterEntry entry) => buildReplyText(
    entry: entry,
    cat: shadowCatById(entry.catId),
    history: [entry],
    growthStage: CatGrowthStage.baby,
    visitStreak: 1,
  );

  test(
    'all existing heart and cat archives remain readable without reordering or rewriting',
    () async {
      final box = await HiveEncryption.openBox('personal_replies_local_user');
      for (var i = 0; i < 20; i++) {
        final id = 'letter:1000000000000000_$i';
        await box.put(id, jsonEncode({'id': id, 'reply': '과거 고양이 답장 $i'}));
      }
      const heartId = 'heart:2000000000000000_love';
      await box.put(
        heartId,
        jsonEncode({'reply': oldReply, 'engineVersion': 0}),
      );
      await PersonalReplyService.setFeedback(heartId, 'off_topic');
      final snapshot = Map.from(box.toMap());
      expect(await create(heartId, refresh: true), oldReply);
      await expectLater(
        create('heart:new'),
        throwsA(isA<ReplyGenerationRetired>()),
      );
      expect(box.toMap(), snapshot);
      expect(await PersonalReplyService.feedback(heartId), 'off_topic');
    },
  );

  test(
    'archive refresh never enters a disk write even when that write would stall',
    () async {
      final box = await HiveEncryption.openBox('personal_replies_local_user');
      const id = 'letter:stall';
      await box.put(id, jsonEncode({'reply': oldReply, 'engineVersion': 0}));
      // ignore: invalid_use_of_protected_member
      final backend = (box as BoxBaseImpl).backend as StorageBackendVm;
      final original = backend.writeRaf;
      final delayed = _OneDelayedWrite(original);
      backend.writeRaf = delayed;
      try {
        expect(await create(id, refresh: true), oldReply);
        expect(await PersonalReplyService.savedReply(id), oldReply);
        expect(await PersonalReplyService.needsRefresh(id), isFalse);
        expect(delayed.entered.isCompleted, isFalse);
      } finally {
        backend.writeRaf = original;
      }
    },
  );

  test(
    'expired queued job does not start after blocked write completes',
    () async {
      final gate = Completer<void>();
      final first = PersonalReplyService.withStorageLock(() => gate.future);
      var started = false;
      final queued = PersonalReplyService.withStorageLock(() async {
        started = true;
      }, timeout: const Duration(milliseconds: 20));
      await expectLater(queued, throwsA(isA<TimeoutException>()));
      gate.complete();
      await first;
      await PersonalReplyService.savedReply('nothing');
      expect(started, isFalse);
    },
  );

  test('deleted cat cannot be recreated from stale dialog snapshot', () async {
    final entry = LetterEntry(
      id: 'delete-cat',
      catId: 'lonely',
      date: DateTime(2026, 10, 1),
      letterText: '나는 오늘 외로워.',
    );
    await StorageService.saveLetter(entry);
    final replies = await HiveEncryption.openBox('personal_replies_local_user');
    await replies.put('letter:${entry.id}', jsonEncode({'reply': oldReply}));
    expect(await openCat(entry), oldReply);
    await StorageService.deleteLetter(entry.id);
    await expectLater(openCat(entry), throwsStateError);
    expect(await PersonalReplyService.savedReply('letter:${entry.id}'), isNull);
    expect(StorageService.letterBox.containsKey(entry.id), isFalse);
  });

  test(
    'delete and waiting cat archive read share source existence guard',
    () async {
      final entry = LetterEntry(
        id: 'queued-delete',
        catId: 'lonely',
        date: DateTime(2026, 10, 1),
        letterText: '나는 오늘 외로워.',
      );
      await StorageService.saveLetter(entry);
      final gate = Completer<void>();
      final blocker = PersonalReplyService.withStorageLock(() => gate.future);
      final deletion = PersonalReplyService.remove(
        'letter:${entry.id}',
        deleteSource: () async {
          await StorageService.letterBox.delete(entry.id);
          await StorageService.letterBox.flush();
        },
      );
      final opening = openCat(entry);
      final rejected = expectLater(opening, throwsStateError);
      gate.complete();
      await blocker;
      await deletion;
      await rejected;
      expect(
        await PersonalReplyService.savedReply('letter:${entry.id}'),
        isNull,
      );
    },
  );

  test(
    'read-only heart lookup never generates, spends quota, or writes a reply',
    () async {
      SubscriptionService.debugIsPremiumOverride = false;
      final letters = await HiveEncryption.openBox(
        'special_letters_local_user',
      );
      final replies = await HiveEncryption.openBox(
        'personal_replies_local_user',
      );
      final entry = SpecialLetterEntry(
        id: 'read-only',
        type: SpecialLetterType.love,
        letterText: '나는 오늘 외로워.',
        replyText: '',
        createdAt: DateTime(2026, 10, 1),
      );
      await letters.put(entry.id, entry.toMap());
      expect(await SpecialLetterService.savedReply(entry), isNull);
      expect(replies.isEmpty, isTrue);
      await letters.put(entry.id, entry.withReplyText(oldReply).toMap());
      expect(await SpecialLetterService.savedReply(entry), oldReply);
      await replies.put(
        'heart:${entry.id}',
        jsonEncode({'reply': '새로 저장된 정상 답장입니다.'}),
      );
      expect(await SpecialLetterService.savedReply(entry), '새로 저장된 정상 답장입니다.');
      expect(replies.get('quota:2026-10-16', defaultValue: 0), 0);
      await SpecialLetterService.deleteLetter(entry.id);
      await expectLater(
        SpecialLetterService.savedReply(entry),
        throwsStateError,
      );
      await expectLater(
        SpecialLetterService.ensureReply(entry),
        throwsStateError,
      );
    },
  );

  test(
    'v2 answer remains unchanged and readable without automatic upgrade',
    () async {
      final box = await HiveEncryption.openBox('personal_replies_local_user');
      const id = 'letter:v2';
      await box.put(id, jsonEncode({'reply': oldReply, 'engineVersion': 2}));
      await box.put('quota:2026-10-16', 1);
      expect(await PersonalReplyService.savedReply(id), oldReply);
      expect(await PersonalReplyService.needsRefresh(id), isFalse);
      final answer = await create(id, refresh: true);
      expect(answer, oldReply);
      expect(await PersonalReplyService.needsRefresh(id), isFalse);
      expect(await create(id, refresh: true), answer);
      expect(box.get('quota:2026-10-16'), 1);
    },
  );
  test(
    'failed cat deletion restores original letter, answer and legacy cache',
    () async {
      final entry = LetterEntry(
        id: 'delete-fails',
        catId: 'lonely',
        date: DateTime(2026, 10, 1),
        letterText: '나는 오늘 외로워.',
      );
      await StorageService.saveLetter(entry);
      final replies = await HiveEncryption.openBox(
        'personal_replies_local_user',
      );
      await replies.put('letter:${entry.id}', jsonEncode({'reply': oldReply}));
      final answer = await openCat(entry);
      final cache = await HiveEncryption.openBox('reply_cache_local_user');
      await cache.put(entry.id, oldReply);
      // ignore: invalid_use_of_protected_member
      final backend = (replies as BoxBaseImpl).backend as StorageBackendVm;
      final delayed = _OneDelayedWrite(backend.writeRaf);
      backend.writeRaf = delayed;
      final deletion = StorageService.deleteLetter(entry.id);
      final rejected = expectLater(
        deletion,
        throwsA(isA<FileSystemException>()),
      );
      await delayed.entered.future;
      delayed.gate.completeError(
        FileSystemException('simulated delete failure'),
      );
      await rejected;
      expect(
        StorageService.getAllLetters().single.letterText,
        entry.letterText,
      );
      expect(
        await PersonalReplyService.savedReply('letter:${entry.id}'),
        answer,
      );
      expect(cache.get(entry.id), oldReply);
    },
  );

  test('heart archive lookup never rewrites embedded legacy text', () async {
    final letters = await HiveEncryption.openBox('special_letters_local_user');
    final entry = SpecialLetterEntry(
      id: 'heart-cache-read',
      type: SpecialLetterType.love,
      letterText: '나는 오늘 외로워.',
      replyText: oldReply,
      createdAt: DateTime(2026, 10, 1),
    );
    await letters.put(entry.id, entry.toMap());
    // ignore: invalid_use_of_protected_member
    final backend = (letters as BoxBaseImpl).backend as StorageBackendVm;
    final original = backend.writeRaf;
    final delayed = _OneDelayedWrite(original);
    backend.writeRaf = delayed;
    try {
      expect(
        await SpecialLetterService.ensureReply(entry, refreshExisting: true),
        oldReply,
      );
      expect(await SpecialLetterService.savedReply(entry), oldReply);
      expect(
        SpecialLetterService.getAllEntries().single.toMap(),
        entry.toMap(),
      );
      expect(delayed.entered.isCompleted, isFalse);
    } finally {
      backend.writeRaf = original;
    }
  });
}
