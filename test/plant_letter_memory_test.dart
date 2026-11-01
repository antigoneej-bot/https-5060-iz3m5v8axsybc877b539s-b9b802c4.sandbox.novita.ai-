import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/models/letter_entry.dart';
import 'package:flutter_app/models/special_letter_entry.dart';
import 'package:flutter_app/mongi/integration/mongi_garden_store.dart';
import 'package:flutter_app/mongi/integration/plant_memory_store.dart';
import 'package:flutter_app/services/backup_service.dart';
import 'package:flutter_app/services/hive_encryption.dart';
import 'package:flutter_app/services/private_letter_memory_source.dart';
import 'package:flutter_app/services/storage_service.dart';
import 'package:flutter_app/services/special_letter_service.dart';
import 'package:flutter_app/widgets/private_memory_links.dart';
import 'package:flutter_app/mongi/integration/plant_memory_editor.dart';
import 'package:flutter_app/mongi/models/seed.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final letter = LetterEntry(
    id: 'same-letter-id',
    catId: 'angry',
    date: DateTime(2026, 10, 20, 20),
    letterText: '오늘은 답답했지만 내 마음을 남겨본다. 천천히 걸어보자.',
  );
  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('plant-letter-memory-');
    Hive.init(directory.path);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (call) async => call.method == 'read'
              ? base64Encode(List<int>.filled(32, 8))
              : null,
        );
    await StorageService.setCurrentUser('local_user');
    await SpecialLetterService.setCurrentUser('local_user');
  });
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      MongiGardenStore.storageKey: jsonEncode(
        MongiGardenData(seeds: {'pine': 3}).toJson(),
      ),
    });
    for (final name in [
      'letter_entries_local_user',
      'special_letters_local_user',
      PlantMemoryStore.boxName,
      'garden_memory_books_local_user',
      'care_journal_local_user',
      'self_care_local_user',
    ]) {
      final box = await HiveEncryption.openBox(name);
      await box.clear();
    }
    await StorageService.letterBox.put(letter.id, letter.toMap());
    await PlantMemoryStore.instance.saveMemory(
      PlantMemory(
        plantId: 'pine',
        name: '처음의 나무',
        note: '원래의 추억',
        updatedAt: DateTime(2026, 10, 19),
        anniversaryOn: '2026-10-01',
      ),
    );
  });
  tearDownAll(() async {
    await StorageService.clearCurrentUser();
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test(
    'exact quote attaches once with source day and preserves growth',
    () async {
      final store = PlantMemoryStore.instance;
      for (var attempt = 0; attempt < 2; attempt++) {
        await store.attachLetterQuote(
          plantId: 'pine',
          sourceLetterId: letter.id,
          quote: '천천히 걸어보자.',
        );
      }
      await store.reload();
      final memory = store.value['pine']!;
      expect(memory.timeline.length, 2);
      final linked = memory.timeline.last;
      expect(linked.sourceLetterId, letter.id);
      expect(linked.sourceWrittenAt, letter.date);
      expect(linked.on, '2026-10-20');
      expect(memory.name, '처음의 나무');
      expect(memory.anniversaryOn, '2026-10-01');
      expect(MongiGardenStore.instance.value.seeds['pine'], 3);
      final snapshot = await BackupService.snapshot();
      BackupService.validate(snapshot);
    },
  );

  test(
    'unplanted target, rewritten quote and missing source cannot attach',
    () async {
      final store = PlantMemoryStore.instance;
      await expectLater(
        store.attachLetterQuote(
          plantId: 'cherry',
          sourceLetterId: letter.id,
          quote: '천천히 걸어보자.',
        ),
        throwsFormatException,
      );
      await expectLater(
        store.attachLetterQuote(
          plantId: 'pine',
          sourceLetterId: letter.id,
          quote: '이제 나는 완전히 괜찮아.',
        ),
        throwsFormatException,
      );
      await expectLater(
        store.attachLetterQuote(
          plantId: 'pine',
          sourceLetterId: 'deleted',
          quote: '천천히 걸어보자.',
        ),
        throwsFormatException,
      );
      expect(store.value['pine']!.timeline.length, 1);
    },
  );

  test(
    'deleting source scrubs linked plant quote and stale editor cannot resurrect it',
    () async {
      final store = PlantMemoryStore.instance;
      await store.attachLetterQuote(
        plantId: 'pine',
        sourceLetterId: letter.id,
        quote: '천천히 걸어보자.',
      );
      final staleEditor = store.value['pine']!;
      await StorageService.deleteLetter(letter.id);
      await store.reload();
      expect(store.value['pine']!.timeline.single.note, '원래의 추억');
      expect(store.value['pine']!.name, '처음의 나무');
      expect(await PrivateLetterMemorySource.find(letter.id), isNull);
      await expectLater(store.saveMemory(staleEditor), throwsFormatException);
      expect(store.value['pine']!.timeline.length, 1);
    },
  );

  test(
    'heart letters have independent source IDs and are available in monthly books',
    () async {
      final heart = SpecialLetterEntry(
        id: letter.id,
        type: SpecialLetterType.gratitude,
        letterText: '오늘 곁에 있어 줘서 고마워.',
        replyText: '',
        createdAt: DateTime(2026, 10, 20, 22),
      );
      final box = await HiveEncryption.openBox('special_letters_local_user');
      await box.put(heart.id, heart.toMap());
      await PlantMemoryStore.instance.attachLetterQuote(
        plantId: 'pine',
        sourceLetterId: 'heart:${heart.id}',
        quote: heart.letterText,
      );
      final sources = await PrivateLetterMemorySource.bookLetters();
      expect(
        sources.map((item) => item.id),
        containsAll([letter.id, 'heart:${heart.id}']),
      );
      await SpecialLetterService.deleteLetter(heart.id);
      expect(await PrivateLetterMemorySource.find('heart:${heart.id}'), isNull);
      expect(
        (await PrivateLetterMemorySource.find(letter.id))!.text,
        letter.letterText,
      );
      expect(
        PlantMemoryStore.instance.value['pine']!.timeline.single.note,
        '원래의 추억',
      );
    },
  );

  test(
    'remembered plant day does not move when a backup opens in another zone',
    () {
      final source = PlantMemoryEntry(
        id: 'remembered-day',
        on: '2026-10-01',
        note: '원문',
        sourceLetterId: letter.id,
        sourceWrittenAt: DateTime.utc(2026, 9, 30, 15, 30),
      );
      expect(PlantMemoryEntry.fromJson(source.toJson()).on, '2026-10-01');
    },
  );

  test('malformed linked date or incomplete source identity is rejected', () {
    final row = PlantMemoryEntry(
      id: 'a',
      on: '2026-10-20',
      note: '원문',
      sourceLetterId: letter.id,
      sourceWrittenAt: letter.date,
    ).toJson();
    expect(
      () => PlantMemoryEntry.fromJson({...row, 'on': '2026-02-30'}),
      throwsFormatException,
    );
    expect(
      () => PlantMemoryEntry.fromJson({...row}..remove('sourceWrittenAt')),
      throwsFormatException,
    );
  });
  testWidgets(
    '360px quote picker leads from own tree to the original saved letter',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Column(
                children: [
                  TextButton(
                    onPressed: () => attachLetterQuoteToPlant(
                      context,
                      sourceLetterId: letter.id,
                      quote: '천천히 걸어보자.',
                    ),
                    child: const Text('나무에 담기'),
                  ),
                  TextButton(
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) =>
                          PlantMemoryEditor(plant: SeedType.byId('pine')),
                    ),
                    child: const Text('추억 열기'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      Future<void> ioUntil(bool Function() ready) async {
        for (var n = 0; n < 80; n++) {
          await tester.pump(const Duration(milliseconds: 25));
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)),
          );
          if (ready()) return;
        }
        expect(ready(), isTrue);
      }

      await tester.tap(find.text('나무에 담기'));
      await ioUntil(() => find.text('처음의 나무').evaluate().isNotEmpty);
      await tester.pump(const Duration(milliseconds: 350));
      final save = find.widgetWithText(FilledButton, '이 나무에 간직하기');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await ioUntil(() => find.text('내 나무에 문장 간직하기').evaluate().isEmpty);
      await tester.pumpAndSettle();
      expect(
        PlantMemoryStore.instance.value['pine']!.timeline.last.note,
        '천천히 걸어보자.',
      );
      await tester.tap(find.text('추억 열기'));
      await tester.pumpAndSettle();
      final sourceLink = find.text('그날의 편지 보기');
      await tester.ensureVisible(sourceLink);
      await tester.tap(sourceLink);
      await ioUntil(() => find.text(letter.letterText).evaluate().isNotEmpty);
      expect(find.text('그날의 내 마음'), findsOneWidget);
      expect(find.text('이 달의 정원 기록집 보기'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      // Hive's internal write-lock futures were created by the widget tap.
      // Finish their callbacks while this fake-async zone is still pumping.
      var closed = false;
      final closing = () async {
        await StorageService.clearCurrentUser();
        await Hive.close();
        closed = true;
      }();
      await ioUntil(() => closed);
      await closing;
    },
  );
}
