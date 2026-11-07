import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_app/models/care_journal_entry.dart';
import 'package:flutter_app/models/letter_entry.dart';
import 'package:flutter_app/models/self_care_entry.dart';
import 'package:flutter_app/services/care_journal_store.dart';
import 'package:flutter_app/services/hive_encryption.dart';
import 'package:flutter_app/services/self_care_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late CareJournalStore store;
  late SelfCareStore canonical;
  late DateTime now;
  late Box metadata, actions;
  late Map<String, String> sources;
  final letter = LetterEntry(
    id: 'letter-one',
    catId: 'angry',
    date: DateTime.utc(2026, 10, 1),
    letterText: '화가 나도 괜찮아. 오늘은 천천히 쉬자.',
  );

  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('care_journal_test_');
    Hive.init(directory.path);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (_) async => null,
        );
  });
  setUp(() async {
    now = DateTime.utc(2026, 10, 21, 10);
    metadata = await HiveEncryption.openBox('test_care_journal');
    actions = await HiveEncryption.openBox('test_self_care');
    await metadata.clear();
    await actions.clear();
    canonical = SelfCareStore.forTesting(
      openBox: () async => actions,
      clock: () => now,
    );
    sources = {
      letter.id: letter.letterText,
      'heart:${letter.id}': letter.letterText,
    };
    store = CareJournalStore.forTesting(
      openBox: () async => metadata,
      selfCare: canonical,
      sourceText: (id) => sources[id],
      clock: () => now,
    );
  });
  tearDown(() => store.dispose());
  tearDownAll(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test(
    'existing self-care is projected without duplicating its private data',
    () async {
      await canonical.save(
        SelfCareEntry(id: 'old', createdAt: now, action: CareAction.rest),
      );
      now = now.add(const Duration(hours: 1));
      await canonical.review('old', CareFeedback.helped, null);
      await store.reload();
      expect(store.entries.single.id, 'action:old');
      expect(store.entries.single.wasHelpful, isTrue);
      expect(metadata.isEmpty, isTrue);
      expect(actions.length, 1);
    },
  );

  test(
    'concurrent optional letter choices merge and persist in encrypted storage',
    () async {
      await Future.wait([
        store.setAfterWritingFeeling(letter, AfterWritingFeeling.complex),
        store.saveOwnQuote(letter, '오늘은 천천히 쉬자.'),
        store.saveClosingWords(letter.id, '오늘은 여기까지 해도 괜찮아.'),
      ]);
      await store.reload();
      final entry = store.entryForLetter(letter.id)!;
      expect(entry.afterWritingFeeling, AfterWritingFeeling.complex);
      expect(entry.ownQuote, '오늘은 천천히 쉬자.');
      expect(entry.selfChosenClosing, isNotNull);
      expect(metadata.length, 1);
      expect(await Hive.boxExists('test_care_journal'), isFalse);
      expect(await Hive.boxExists('test_care_journal__enc'), isTrue);
      final bytes = await File(
        '${directory.path}/test_care_journal__enc.hive',
      ).readAsBytes();
      expect(
        utf8.decode(bytes, allowMalformed: true),
        isNot(contains('오늘은 천천히 쉬자.')),
      );
    },
  );

  test(
    'plan retry is idempotent; completion does not infer helpfulness',
    () async {
      final planned = await store.planAction(
        kind: CareActionKind.walk,
        operationId: 'tap-1',
      );
      final retry = await store.planAction(
        kind: CareActionKind.walk,
        operationId: 'tap-1',
      );
      expect(retry.id, planned.id);
      expect(actions.length, 1);
      expect(store.helpfulActions, isEmpty);
      expect(store.entries.single.isPlanned, isTrue);
      now = now.add(const Duration(minutes: 10));
      await store.completeAction(planned.id);
      final completedAt = store.entries.single.completedAt;
      expect(completedAt, now);
      expect(store.entries.single.helpfulness, isNull);
      expect(store.helpfulActions, isEmpty);
      now = now.add(const Duration(minutes: 2));
      await store.completeAction(
        planned.id,
        helpfulness: CareHelpfulness.helped,
      );
      expect(store.entries.single.completedAt, completedAt);
      expect(store.helpfulActions.single.id, planned.id);
    },
  );

  test(
    'a newer unhelpful experience supersedes older helpful recommendation',
    () async {
      final first = await store.planAction(kind: CareActionKind.rest);
      await store.completeAction(first.id, helpfulness: CareHelpfulness.helped);
      now = now.add(const Duration(days: 1));
      final second = await store.planAction(kind: CareActionKind.rest);
      await store.completeAction(
        second.id,
        helpfulness: CareHelpfulness.harder,
      );
      expect(store.helpfulActions, isEmpty);
      expect(store.entries.where((e) => e.actionKind != null).length, 2);
      expect(store.entries.any((e) => e.wasHelpful), isTrue);
    },
  );

  test(
    'letter deletion removes linked care only, including distinct heart namespaces',
    () async {
      await store.saveOwnQuote(letter, '오늘은 천천히 쉬자.');
      await store.planAction(
        kind: CareActionKind.rest,
        sourceLetterId: letter.id,
      );
      await store.saveLetterFeeling(
        'heart:${letter.id}',
        AfterWritingFeeling.same,
      );
      await store.planAction(
        kind: CareActionKind.walk,
        sourceLetterId: 'heart:${letter.id}',
      );
      await store.planAction(kind: CareActionKind.custom, customLabel: '물 한 잔');
      await store.removeForLetter(letter.id);
      expect(store.entries.any((e) => e.sourceLetterId == letter.id), isFalse);
      expect(
        store.entries
            .where((e) => e.sourceLetterId == 'heart:${letter.id}')
            .length,
        2,
      );
      expect(store.entries.any((e) => e.actionLabel == '물 한 잔'), isTrue);
      await store.clear();
      expect(metadata.isEmpty, isTrue);
      expect(actions.isEmpty, isTrue);
      expect(store.entries, isEmpty);
    },
  );

  test(
    'only exact own words are accepted and malformed backups are rejected',
    () async {
      await expectLater(
        store.saveOwnQuote(letter, '넌 사실 행복해.'),
        throwsFormatException,
      );
      expect(metadata.isEmpty, isTrue);
      await store.setAfterWritingFeeling(letter, AfterWritingFeeling.unknown);
      final json = store.entries.single.toJson();
      expect(
        () => CareJournalEntry.fromJson({
          ...json,
          'afterWritingFeeling': 'happy',
        }),
        throwsFormatException,
      );
      expect(
        () => CareJournalEntry.fromJson({
          ...json,
          'createdAt': '2026-02-30T00:00:00.000Z',
        }),
        throwsFormatException,
      );
      expect(
        () => CareJournalEntry.fromJson({...json, 'helpfulness': 'helped'}),
        throwsFormatException,
      );
      // Failed updates do not poison the write queue.
      await store.saveOwnQuote(letter, '화가 나도 괜찮아.');
      expect(store.entries.single.ownQuote, '화가 나도 괜찮아.');
    },
  );

  test(
    'received encouragement is explicit, deduplicated and rolled back on account change',
    () async {
      await store.saveReceivedEncouragement(
        sourceId: 'owner:real-cheer',
        text: '함께 쉬어가요.',
        author: '친구',
      );
      await store.saveReceivedEncouragement(
        sourceId: 'owner:real-cheer',
        text: '함께 쉬어가요.',
        author: '친구',
      );
      expect(metadata.length, 1);
      var checks = 0;
      await expectLater(
        store.saveReceivedEncouragement(
          sourceId: 'other:cheer',
          text: '응원해요.',
          author: '이웃',
          stillCurrent: () => ++checks < 3,
        ),
        throwsStateError,
      );
      expect(metadata.length, 1);
      expect(store.entries.single.encouragementSourceId, 'owner:real-cheer');
    },
  );
  test(
    'stale closing writes cannot recreate records while source deletion is queued',
    () async {
      await store.saveOwnQuote(letter, '오늘은 천천히 쉬자.');
      final removal = store.removeLetterSource(letter.id, () async {
        await Future<void>.delayed(Duration.zero);
        sources.remove(letter.id);
      });
      final staleWrite = store.saveOwnQuote(letter, '오늘은 천천히 쉬자.');
      final rejected = expectLater(staleWrite, throwsStateError);
      await removal;
      await rejected;
      expect(
        store.entries.where((e) => e.sourceLetterId == letter.id),
        isEmpty,
      );
      await expectLater(
        store.planAction(kind: CareActionKind.rest, sourceLetterId: letter.id),
        throwsStateError,
      );
      await store.planAction(kind: CareActionKind.walk);
      expect(store.entries.single.actionKind, CareActionKind.walk);
    },
  );
}
