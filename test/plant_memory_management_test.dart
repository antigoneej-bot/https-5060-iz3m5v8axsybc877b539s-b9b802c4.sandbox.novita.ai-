import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:flutter_app/models/letter_entry.dart';
import 'package:flutter_app/mongi/integration/mongi_garden_store.dart';
import 'package:flutter_app/mongi/integration/plant_memory_store.dart';
import 'package:flutter_app/mongi/models/garden_layout.dart';
import 'package:flutter_app/mongi/widgets/garden_keepsake_sheets.dart';
import 'package:flutter_app/services/garden_memory_book_store.dart';
import 'package:flutter_app/services/hive_encryption.dart';
import 'package:flutter_app/services/storage_service.dart';
import 'package:flutter_app/services/backup_service.dart';

class _Disk extends InMemorySharedPreferencesStore {
  bool fail = false;
  _Disk(MongiGardenData data)
    : super.withData({
        'flutter.${MongiGardenStore.storageKey}': jsonEncode(data.toJson()),
      });
  @override
  Future<bool> setValue(String type, String key, Object value) =>
      fail ? Future.value(false) : super.setValue(type, key, value);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final garden = MongiGardenStore.instance;
  final memories = PlantMemoryStore.instance;
  final books = GardenMemoryBookStore.instance;
  late Directory directory;
  late _Disk disk;
  final date = DateTime(2026, 10, 20);
  final original = PlantMemory(
    plantId: 'pine',
    name: '처음 심은 나무',
    note: '다시 시작한 날',
    updatedAt: date,
    anniversaryOn: '2026-10-01',
  );
  final letter = LetterEntry(
    id: 'letter-source',
    catId: 'angry',
    date: date,
    letterText: '원본 편지는 그대로 남아 있어요.',
  );

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('plant-management-');
    Hive.init(directory.path);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (call) async =>
              call.method == 'read' ? base64Encode(List.filled(32, 7)) : null,
        );
    SharedPreferences.setMockInitialValues({});
    disk = _Disk(
      MongiGardenData(
        seedTokens: 2,
        essence: 90,
        seeds: {'pine': 5, 'cherry': 3},
        plantedOn: {'pine': '2026-10-01', 'cherry': '2026-10-03'},
        wateredOn: {'pine': '2026-10-20'},
        fertilizedOn: {'pine': '2026-10-20'},
        sunlightOn: {'pine': '2026-10-20'},
        careRemainders: {'pine': 2},
        recordDays: {'2026-10-20'},
      ),
    );
    SharedPreferencesStorePlatform.instance = disk;
    await StorageService.setCurrentUser('local_user');
    await StorageService.saveLetter(letter);
    await garden.reload();
    await memories.saveMemory(original);
    await memories.save('cherry', '다른 나무', '그대로 둘 추억');
    final box = await HiveEncryption.openBox(GardenMemoryBookStore.boxName);
    final book = GardenMemoryBook(
      month: '2026-10',
      style: 'basic',
      createdAt: date,
      updatedAt: date,
      snapshot: GardenBookSnapshot(
        capturedAt: date,
        seeds: {'pine': 5},
        decorations: [],
        layout: GardenLayout(),
        memoryDays: 1,
        companionName: '나비',
      ),
      quotes: [
        GardenBookQuote(
          letterId: letter.id,
          text: letter.letterText,
          writtenAt: date,
        ),
      ],
      plants: [
        const GardenBookPlant(
          plantId: 'pine',
          name: '처음 심은 나무',
          anniversaryOn: '2026-10-01',
        ),
      ],
      care: [],
    );
    await box.put(book.id, book.toJson());
    await books.reload();
  });
  tearDown(() async {
    disk.fail = false;
    await StorageService.clearCurrentUser();
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test(
    'delete persists, scrubs copies, preserves letters and other plants, fresh replant',
    () async {
      final staleBook = books.value.single;
      await memories.deletePlant('pine');
      await garden.reload();
      await memories.reload();
      await books.reload();
      final data = garden.value;
      expect(data.seeds, {'cherry': 3});
      for (final map in [
        data.plantedOn,
        data.wateredOn,
        data.fertilizedOn,
        data.sunlightOn,
        data.careRemainders,
      ]) {
        expect(map.containsKey('pine'), false);
      }
      expect(data.seedTokens, 2);
      expect(data.essence, 90);
      expect(data.recordDays, {'2026-10-20'});
      expect(memories.value.keys, ['cherry']);
      expect(books.value.single.plants, isEmpty);
      expect(books.value.single.quotes.single.text, letter.letterText);
      expect(
        StorageService.getAllLetters().single.letterText,
        letter.letterText,
      );
      await expectLater(books.save(staleBook), throwsFormatException);
      BackupService.validate(await BackupService.snapshot());
      await garden.plant('pine', now: DateTime(2026, 10, 24));
      expect(garden.value.seeds['pine'], 1);
      expect(garden.value.plantedOn['pine'], '2026-10-24');
      expect(garden.value.seedTokens, 1);
      expect(memories.value.containsKey('pine'), false);
    },
  );

  test(
    'failed preference save restores memory and book, retry deletes exactly once',
    () async {
      disk.fail = true;
      await expectLater(memories.deletePlant('pine'), throwsStateError);
      await garden.reload();
      await memories.reload();
      await books.reload();
      expect(garden.value.seeds['pine'], 5);
      expect(memories.value['pine']!.name, original.name);
      expect(books.value.single.plants.single.name, original.name);
      disk.fail = false;
      await memories.deletePlant('pine');
      await memories.deletePlant('pine');
      expect(garden.value.seedTokens, 2);
      expect(memories.value.containsKey('pine'), false);
    },
  );

  test(
    'open stale editor cannot recreate a deleted or replanted memory',
    () async {
      await memories.deletePlant('pine');
      for (var attempt = 0; attempt < 2; attempt++) {
        await expectLater(
          memories.saveMemory(
            original,
            checkRevision: true,
            expectedUpdatedAt: original.updatedAt,
          ),
          throwsStateError,
        );
        await garden.plant('pine');
      }
      expect(memories.value.containsKey('pine'), false);
    },
  );

  Future<void> ioUntil(WidgetTester tester, bool Function() ready) async {
    for (var n = 0; n < 100; n++) {
      await tester.pump(const Duration(milliseconds: 25));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      if (ready()) return;
    }
    expect(ready(), true);
  }

  Future<void> open(WidgetTester tester, double width) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.3)),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showPlantMemoryManager(context),
              child: const Text('관리 열기'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('관리 열기'));
    await ioUntil(tester, () => find.text(original.name).evaluate().isNotEmpty);
    await tester.pumpAndSettle();
    await tester.tap(find.text(original.name));
    await tester.pumpAndSettle();
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    var closed = false;
    final operation = () async {
      await StorageService.clearCurrentUser();
      await Hive.close();
      closed = true;
    }();
    await ioUntil(tester, () => closed);
    await operation;
  }

  testWidgets(
    '360px: edit saves immediately and survives reopening, individual delete persists',
    (tester) async {
      await open(tester, 360);
      expect(find.byKey(const ValueKey('delete-plant')), findsOneWidget);
      await tester.tap(find.text('글 수정·삭제'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('수정'));
      await tester.tap(find.text('수정'));
      await tester.pumpAndSettle();
      final editor = find.byType(AlertDialog).last;
      await tester.enterText(
        find.descendant(of: editor, matching: find.byType(TextField)),
        '수정한 마음',
      );
      await tester.tap(
        find.descendant(
          of: editor,
          matching: find.widgetWithText(FilledButton, '저장'),
        ),
      );
      await ioUntil(tester, () => memories.value['pine']?.note == '수정한 마음');
      await tester.pumpAndSettle();
      await tester.runAsync(memories.reload);
      expect(memories.value['pine']!.name, original.name);
      expect(memories.value['pine']!.anniversaryOn, original.anniversaryOn);
      expect(memories.value['pine']!.note, '수정한 마음');
      await tester.ensureVisible(find.text('삭제'));
      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('지우기'));
      await ioUntil(tester, () => memories.value['pine']!.timeline.isEmpty);
      await tester.pumpAndSettle();
      expect(garden.value.seeds['pine'], 5);
      expect(tester.takeException(), isNull);
      await close(tester);
    },
  );

  testWidgets('editing a quoted memory keeps the original letter unchanged', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await memories.remove('pine');
      await memories.attachLetterQuote(
        plantId: 'pine',
        sourceLetterId: letter.id,
        quote: letter.letterText,
      );
      // Give the picker its familiar name without changing the linked quote.
      final linked = memories.value['pine']!;
      await memories.saveMemory(
        PlantMemory(
          plantId: 'pine',
          name: original.name,
          note: linked.note,
          updatedAt: linked.updatedAt,
          entries: linked.timeline,
        ),
      );
    });
    await open(tester, 360);
    await tester.tap(find.text('글 수정·삭제'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('수정'));
    await tester.tap(find.text('수정'));
    await tester.pumpAndSettle();
    expect(find.textContaining('원본 편지는 바뀌지 않아요.'), findsOneWidget);
    final dialog = find.byType(AlertDialog).last;
    await tester.enterText(
      find.descendant(of: dialog, matching: find.byType(TextField)),
      '지금 다시 돌아본 마음',
    );
    await tester.tap(
      find.descendant(
        of: dialog,
        matching: find.widgetWithText(FilledButton, '저장'),
      ),
    );
    await ioUntil(tester, () => memories.value['pine']?.note == '지금 다시 돌아본 마음');
    await tester.pumpAndSettle();
    expect(memories.value['pine']!.timeline.single.sourceLetterId, isNull);
    expect(StorageService.getAllLetters().single.letterText, letter.letterText);
    expect(tester.takeException(), isNull);
    await close(tester);
  });

  testWidgets(
    'failed stale save keeps the typed text and cannot overwrite newer memory',
    (tester) async {
      await open(tester, 390);
      await tester.tap(find.text('글 수정·삭제'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('수정'));
      await tester.tap(find.text('수정'));
      await tester.pumpAndSettle();
      final dialog = find.byType(AlertDialog).last;
      final field = find.descendant(
        of: dialog,
        matching: find.byType(TextField),
      );
      await tester.enterText(field, '입력한 내용을 잃지 않아요');
      await tester.runAsync(
        () => memories.save('pine', original.name, '다른 화면에서 저장한 추억'),
      );
      await tester.tap(
        find.descendant(
          of: dialog,
          matching: find.widgetWithText(FilledButton, '저장'),
        ),
      );
      await ioUntil(
        tester,
        () => find.textContaining('닫은 뒤 다시 열어 주세요.').evaluate().isNotEmpty,
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(field).controller!.text,
        '입력한 내용을 잃지 않아요',
      );
      expect(memories.value['pine']!.note, '다른 화면에서 저장한 추억');
      expect(tester.takeException(), isNull);
      await close(tester);
    },
  );

  testWidgets(
    '390px: cancel preserves tree; confirmed deletion updates manager immediately',
    (tester) async {
      await open(tester, 390);
      await tester.tap(find.byKey(const ValueKey('delete-plant')));
      await tester.pumpAndSettle();
      expect(find.textContaining('원본 편지와 다른 식물'), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog).last,
          matching: find.text('취소'),
        ),
      );
      await tester.pumpAndSettle();
      expect(garden.value.seeds['pine'], 5);
      await tester.tap(find.byKey(const ValueKey('delete-plant')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('confirm-delete-plant')));
      await ioUntil(tester, () => !garden.value.seeds.containsKey('pine'));
      await tester.pumpAndSettle();
      expect(find.text(original.name), findsNothing);
      expect(find.text('다른 나무'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await close(tester);
    },
  );
}
