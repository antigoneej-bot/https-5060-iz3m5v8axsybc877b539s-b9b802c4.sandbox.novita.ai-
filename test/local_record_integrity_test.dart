import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
// Deliberately exercise real encrypted Hive writes, not mocked success paths.
// ignore: implementation_imports
import 'package:hive/src/box/box_base_impl.dart';
// ignore: implementation_imports
import 'package:hive/src/backend/vm/storage_backend_vm.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/models/care_journal_entry.dart';
import 'package:flutter_app/models/letter_entry.dart';
import 'package:flutter_app/models/special_letter_entry.dart';
import 'package:flutter_app/mongi/integration/plant_memory_store.dart';
import 'package:flutter_app/mongi/models/garden_layout.dart';
import 'package:flutter_app/services/backup_service.dart';
import 'package:flutter_app/services/access_policy.dart';
import 'package:flutter_app/services/care_journal_store.dart';
import 'package:flutter_app/services/garden_memory_book_store.dart';
import 'package:flutter_app/services/hive_encryption.dart';
import 'package:flutter_app/services/local_record_transaction.dart';
import 'package:flutter_app/services/self_care_store.dart';
import 'package:flutter_app/services/special_letter_service.dart';
import 'package:flutter_app/services/storage_service.dart';
import 'package:flutter_app/services/subscription_service.dart';

class _PausedFlush implements RandomAccessFile {
  final RandomAccessFile inner;
  final entered = Completer<void>();
  final release = Completer<void>();
  bool _first = true;
  _PausedFlush(this.inner);

  @override
  Future<RandomAccessFile> flush() async {
    if (_first) {
      _first = false;
      entered.complete();
      await release.future;
    }
    return inner.flush();
  }

  @override
  Future<RandomAccessFile> writeFrom(List<int> b, [int s = 0, int? e]) =>
      inner.writeFrom(b, s, e);
  @override
  Future<RandomAccessFile> setPosition(int p) => inner.setPosition(p);
  @override
  Future<void> close() => inner.close();
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  const secure = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  const ownWords = '오늘도 내 마음을 남겨둔다.';
  late DateTime now;
  late LetterEntry letter;
  final care = CareJournalStore.instance;
  final books = GardenMemoryBookStore.instance;
  final plants = PlantMemoryStore.instance;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('record-transaction-');
    Hive.init(directory.path);
    SharedPreferences.setMockInitialValues({});
    SubscriptionService.debugIsPremiumOverride = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          secure,
          (call) async => call.method == 'read'
              ? base64Encode(List<int>.filled(32, 7))
              : null,
        );
    await StorageService.setCurrentUser('local_user');
    await SpecialLetterService.setCurrentUser('local_user');
    now = DateTime.now().subtract(const Duration(minutes: 1));
    letter = LetterEntry(
      id: 'source-letter',
      catId: 'lonely',
      date: now,
      letterText: '오늘은 조금 힘들었다. $ownWords',
    );
    await care.reload();
    await books.reload();
    await plants.reload();
  });
  tearDown(() async {
    SubscriptionService.debugIsPremiumOverride = null;
    await Hive.close();
    await directory.delete(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secure, null);
  });

  Future<Box> open(String name) => HiveEncryption.openBox('${name}_local_user');
  Future<_PausedFlush> pause(Box box) async {
    // ignore: invalid_use_of_protected_member
    final backend = (box as BoxBaseImpl).backend as StorageBackendVm;
    final wrapper = _PausedFlush(backend.writeRaf);
    backend.writeRaf = wrapper;
    return wrapper;
  }

  Future<CareJournalEntry> seedCare(String sourceId) async {
    await care.saveLetterQuote(
      sourceLetterId: sourceId,
      originalText: letter.letterText,
      exactQuote: ownWords,
    );
    final action = await care.planAction(
      kind: CareActionKind.rest,
      sourceLetterId: sourceId,
      operationId: 'one',
    );
    await care.completeAction(action.id, helpfulness: CareHelpfulness.helped);
    return care.helpfulActions.single;
  }

  Future<void> seedBook(CareJournalEntry action, {bool heart = false}) async {
    final date = DateTime.now();
    await books.save(
      GardenMemoryBook(
        month: gardenBookMonth(date),
        createdAt: date,
        updatedAt: date,
        snapshot: GardenBookSnapshot(
          capturedAt: date,
          seeds: {'pine': 1},
          decorations: [],
          layout: GardenLayout(),
          memoryDays: 1,
          companionName: '나비',
        ),
        quotes: heart
            ? []
            : [
                GardenBookQuote(
                  letterId: letter.id,
                  text: ownWords,
                  writtenAt: letter.date,
                ),
              ],
        care: [
          GardenBookCare(
            entryId: action.id,
            actionLabel: action.actionLabel!,
            completedAt: action.completedAt!.toLocal(),
            sourceLetterId: action.sourceLetterId,
          ),
        ],
        plants: const [GardenBookPlant(plantId: 'pine', name: '첫 나무')],
      ),
    );
  }

  Future<void> seedPlant({String? sourceId}) => plants.saveMemory(
    PlantMemory(
      plantId: 'pine',
      name: '첫 나무',
      note: ownWords,
      updatedAt: now,
      entries: [
        PlantMemoryEntry(
          id: 'memory-1',
          on: plantMemoryDay(now),
          note: ownWords,
          sourceLetterId: sourceId,
          sourceWrittenAt: sourceId == null ? null : now,
        ),
      ],
    ),
  );

  test(
    'late archive failure restores source, care, actions, tree and book; queued save survives',
    () async {
      await StorageService.saveLetter(letter);
      final action = await seedCare(letter.id);
      await seedPlant(sourceId: letter.id);
      await seedBook(action);
      final replies = await open('personal_replies');
      await replies.put(
        'letter:${letter.id}',
        jsonEncode({'reply': '이전에 남겨진 답장입니다.'}),
      );
      final cache = await open('reply_cache');
      await cache.put(letter.id, '기존 답장');
      final names = [
        'letter_entries',
        'personal_replies',
        'reply_cache',
        'care_journal',
        'self_care',
        'garden_memories',
        'garden_memory_books',
      ];
      final before = <String, Map>{};
      for (final name in names) {
        before[name] =
            jsonDecode(jsonEncode((await open(name)).toMap())) as Map;
      }
      final delayed = await pause(replies);
      final deletion = StorageService.deleteLetter(letter.id);
      final failed = expectLater(deletion, throwsA(isA<FileSystemException>()));
      await delayed.entered.future;
      // Failure is late: source and copies really were removed before archive flush.
      expect(StorageService.letterBox.containsKey(letter.id), isFalse);
      expect((await open('care_journal')).get('letter:${letter.id}'), isNull);
      var saved = false;
      final later = StorageService.saveLetter(
        LetterEntry(
          id: 'later',
          catId: 'lonely',
          date: now,
          letterText: '다른 편지',
        ),
      ).then((_) => saved = true);
      await Future<void>.delayed(Duration.zero);
      expect(saved, isFalse);
      delayed.release.completeError(
        FileSystemException('late archive flush failure'),
      );
      await failed;
      await later;
      for (final name in names) {
        final actual = Map.from((await open(name)).toMap());
        if (name == 'letter_entries') actual.remove('later');
        expect(actual, before[name], reason: name);
      }
      expect(StorageService.letterBox.containsKey('later'), isTrue);
      expect(care.entryForLetter(letter.id)?.ownQuote, ownWords);
      expect(care.helpfulActions.single.id, action.id);
      expect(books.value.single.quotes.single.text, ownWords);
      expect(plants.value['pine']!.timeline.single.sourceLetterId, letter.id);
    },
  );

  test(
    'heart deletion has the same rollback boundary as care and tree copies',
    () async {
      final hearts = await open('special_letters');
      final entry = SpecialLetterEntry(
        id: letter.id,
        type: SpecialLetterType.love,
        letterText: letter.letterText,
        replyText: '',
        createdAt: now,
      );
      await hearts.put(entry.id, entry.toMap());
      final action = await seedCare('heart:${letter.id}');
      await seedPlant(sourceId: 'heart:${letter.id}');
      await seedBook(action, heart: true);
      final replies = await open('personal_replies');
      await replies.put(
        'heart:${entry.id}',
        jsonEncode({'reply': '과거의 답장이에요.'}),
      );
      final delayed = await pause(replies);
      final failed = expectLater(
        SpecialLetterService.deleteLetter(entry.id),
        throwsA(isA<FileSystemException>()),
      );
      await delayed.entered.future;
      expect(hearts.containsKey(entry.id), isFalse);
      delayed.release.completeError(
        FileSystemException('heart archive flush failure'),
      );
      await failed;
      expect(hearts.containsKey(entry.id), isTrue);
      expect(care.entryForLetter('heart:${letter.id}')?.ownQuote, ownWords);
      expect(
        books.value.single.care.single.sourceLetterId,
        'heart:${letter.id}',
      );
      expect(
        plants.value['pine']!.timeline.single.sourceLetterId,
        'heart:${letter.id}',
      );
    },
  );

  test(
    'standalone plant and care failures restore copied book entries',
    () async {
      await StorageService.saveLetter(letter);
      final action = await seedCare(letter.id);
      await seedPlant();
      await seedBook(action);
      final plantBox = await open('garden_memories');
      final plantFailure = await pause(plantBox);
      final rejectedPlant = expectLater(
        plants.remove('pine'),
        throwsA(isA<FileSystemException>()),
      );
      await plantFailure.entered.future;
      expect(books.value.single.plants, isEmpty);
      plantFailure.release.completeError(
        FileSystemException('plant flush failure'),
      );
      await rejectedPlant;
      expect(plants.value['pine']!.name, '첫 나무');
      expect(books.value.single.plants.single.name, '첫 나무');
      final actionBox = await open('self_care');
      final actionFailure = await pause(actionBox);
      final rejectedAction = expectLater(
        SelfCareStore.instance.remove(action.id.substring(7)),
        throwsA(isA<FileSystemException>()),
      );
      await actionFailure.entered.future;
      expect(books.value.single.care, isEmpty);
      actionFailure.release.completeError(
        FileSystemException('action flush failure'),
      );
      await rejectedAction;
      expect(
        (await SelfCareStore.instance.load()).single.id,
        action.id.substring(7),
      );
      expect(books.value.single.care.single.entryId, action.id);
    },
  );

  test(
    'backup and concurrent deletion cannot split private copies from source',
    () async {
      await StorageService.saveLetter(letter);
      await seedCare(letter.id);
      final journal = await open('care_journal');
      final delayed = await pause(journal);
      final exporting = BackupService.snapshot();
      await delayed.entered.future;
      var deleted = false;
      final deleting = StorageService.deleteLetter(
        letter.id,
      ).then((_) => deleted = true);
      await Future<void>.delayed(Duration.zero);
      expect(deleted, isFalse);
      expect(StorageService.letterBox.containsKey(letter.id), isTrue);
      delayed.release.complete();
      final snapshot = await exporting;
      await deleting;
      BackupService.validate(snapshot);
      final rows = snapshot['boxes'] as Map;
      expect(rows['care_journal'], hasLength(1));
      expect(rows['self_care'], hasLength(1));
      expect(rows['letter_entries'], hasLength(1));
      final later = (await BackupService.snapshot())['boxes'] as Map;
      expect(later['care_journal'], isEmpty);
      expect(later['self_care'], isEmpty);
      expect(later['letter_entries'], isEmpty);
    },
  );

  test(
    'first-book allowance survives deletion and encrypted backup restore',
    () async {
      await StorageService.saveLetter(letter);
      final action = await seedCare(letter.id);
      await seedPlant();
      await seedBook(action);
      await books.remove(books.value.single.id);
      expect(books.value, isEmpty);
      final exported = await BackupService.snapshot();
      BackupService.validate(exported);
      final rows = (exported['boxes'] as Map)['garden_memory_books'] as List;
      expect(rows, hasLength(1));
      expect(rows.single['key'], '__creation_policy');
      final invalid = Map<String, dynamic>.from(
        jsonDecode(jsonEncode(exported)) as Map,
      );
      (((invalid['boxes'] as Map)['garden_memory_books'] as List)
                  .single['value']
              as Map)['firstBookCreated'] =
          false;
      expect(() => BackupService.validate(invalid), throwsFormatException);
      // Emulate restoring onto fresh local storage for this box, with no cached
      // in-memory allowance. Existing records in other boxes remain additive.
      await (await open('garden_memory_books')).clear();
      await BackupService.restore(exported);
      await books.reload();
      SubscriptionService.debugIsPremiumOverride = false;
      final date = DateTime.now();
      await expectLater(
        books.save(
          GardenMemoryBook(
            month: gardenBookMonth(DateTime(date.year, date.month - 1)),
            createdAt: date,
            updatedAt: date,
            snapshot: GardenBookSnapshot(
              capturedAt: date,
              seeds: {},
              decorations: [],
              layout: GardenLayout(),
              memoryDays: 0,
              companionName: '나비',
            ),
          ),
        ),
        throwsA(isA<SubscriptionRequired>()),
      );
    },
  );

  test(
    'book policy is preserved without being counted as a personal record',
    () async {
      final box = await open('garden_memory_books');
      await box.put(
        GardenMemoryBookStore.policyKey,
        GardenMemoryBookStore.creationPolicy,
      );
      final snapshot = await BackupService.snapshot();
      BackupService.validate(snapshot);
      expect(BackupService.count(snapshot), 0);
      expect(await BackupService.hasLocalRecords(), isFalse);
      expect((snapshot['boxes'] as Map)['garden_memory_books'], hasLength(1));
      await box.clear();
      expect(await BackupService.restore(snapshot), 0);
      expect(
        box.get(GardenMemoryBookStore.policyKey),
        GardenMemoryBookStore.creationPolicy,
      );
      expect(await BackupService.hasLocalRecords(), isFalse);
    },
  );

  test(
    'an idle queue does not retain an expired caller microtask zone',
    () async {
      final scheduled = <void Function()>[];
      final order = <int>[];
      var finished = false;
      final storeQueue = LocalRecordQueue();
      runZoned(
        () {
          LocalRecordTransaction.atomic(
            () => storeQueue.run(() async {
              order.add(1);
            }),
          );
          LocalRecordTransaction.atomic(
            () => storeQueue.run(() async {
              order.add(2);
            }),
          ).then((_) => finished = true);
        },
        zoneSpecification: ZoneSpecification(
          scheduleMicrotask: (self, parent, zone, callback) {
            scheduled.add(() => zone.run(callback));
          },
        ),
      );
      while (scheduled.isNotEmpty) {
        scheduled.removeAt(0)();
      }
      expect(finished, isTrue);
      expect(order, [1, 2]);
      // That caller's event loop has now ended. The next caller must be able to
      // use both queues without pumping the old zone again.
      await LocalRecordTransaction.atomic(
        () => storeQueue.run(() async {
          order.add(3);
        }),
      ).timeout(const Duration(seconds: 1));
      expect(order, [1, 2, 3]);
      expect(scheduled, isEmpty);
    },
  );

  test(
    'failed recovery is explicit and does not claim the original error alone',
    () async {
      final box = await open('care_journal');
      await box.put('before', 'value');
      await expectLater(
        LocalRecordTransaction.atomic(() async {
          LocalRecordTransaction.capture(box);
          await box.close();
          throw const FileSystemException('disk unavailable');
        }),
        throwsA(isA<LocalRecordRollbackFailure>()),
      );
    },
  );
}
