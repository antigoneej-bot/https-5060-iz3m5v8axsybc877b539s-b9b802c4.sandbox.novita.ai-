import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/models/care_journal_entry.dart';
import 'package:flutter_app/services/care_journal_store.dart';
import 'package:flutter_app/services/self_care_store.dart';
import 'package:flutter_app/widgets/care_return_sheet.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late Box metadata, actions;
  late CareJournalStore store;
  late DateTime now;
  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('care_return_sheet_');
    Hive.init(directory.path);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (_) async => null,
        );
    metadata = await Hive.openBox('return_metadata');
    actions = await Hive.openBox('return_actions');
  });
  setUp(() async {
    await metadata.clear();
    await actions.clear();
    now = DateTime.utc(2026, 10, 21, 3);
    store = CareJournalStore.forTesting(
      openBox: () async => metadata,
      selfCare: SelfCareStore.forTesting(
        openBox: () async => actions,
        clock: () => now,
      ),
      clock: () => now,
      sourceText: (id) => id == 'letter' ? '오늘은 창가에서 쉬었다.' : null,
    );
  });
  tearDown(() => store.dispose());
  tearDownAll(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  Future<void> open(
    WidgetTester tester, {
    required bool words,
    ValueChanged<CareJournalEntry?>? result,
  }) async {
    tester.view.physicalSize = const Size(360, 800);
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
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                final entry = await showModalBottomSheet<CareJournalEntry>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (_) => CareReturnSheet(store: store, words: words),
                );
                result?.call(entry);
              },
              child: const Text('꺼내기'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('꺼내기'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'saved words filter retains their real origin on a narrow screen',
    (tester) async {
      await tester.runAsync(() async {
        await store.saveLetterQuote(
          sourceLetterId: 'letter',
          originalText: '오늘은 창가에서 쉬었다.',
          exactQuote: '오늘은 창가에서 쉬었다.',
        );
        await store.saveClosingWords('letter', '오늘은 여기까지.');
        await store.saveReceivedEncouragement(
          sourceId: 'received-1',
          text: '함께 천천히 가요.',
          author: '이웃 냥이',
        );
      });
      final before = store.entries.length;
      await open(tester, words: true);
      expect(find.text('간직한 말 다시 보기'), findsOneWidget);
      await tester.tap(find.widgetWithText(ChoiceChip, '내 문장'));
      await tester.pumpAndSettle();
      expect(find.text('오늘은 창가에서 쉬었다.'), findsOneWidget);
      expect(find.text('함께 천천히 가요.'), findsNothing);
      expect(find.text('그날 편지 보기'), findsOneWidget);
      expect(find.text('나무에 간직하기'), findsOneWidget);
      await tester.tap(find.widgetWithText(ChoiceChip, '받은 응원'));
      await tester.pumpAndSettle();
      expect(find.text('함께 천천히 가요.'), findsOneWidget);
      expect(find.text('이웃 냥이에게 받은 응원'), findsOneWidget);
      expect(find.text('오늘은 창가에서 쉬었다.'), findsNothing);
      expect(find.text('그날 편지 보기'), findsNothing);
      expect(store.entries.length, before);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'reusing helpful care returns a choice without inventing completion',
    (tester) async {
      late CareJournalEntry helpful;
      await tester.runAsync(() async {
        helpful = await store.planAction(
          kind: CareActionKind.custom,
          customLabel: '창가에서 따뜻한 차 마시기',
          contextLabel: '몸이 피곤할 때',
        );
        now = now.add(const Duration(minutes: 5));
        await store.completeAction(
          helpful.id,
          helpfulness: CareHelpfulness.helped,
        );
      });
      CareJournalEntry? selected;
      final before = store.entries.length;
      await open(tester, words: false, result: (entry) => selected = entry);
      expect(find.text('그때의 상황 · 몸이 피곤할 때'), findsOneWidget);
      await tester.tap(find.text('다시 해볼 계획 남기기'));
      await tester.pumpAndSettle();
      expect(selected?.id, helpful.id);
      expect(selected?.contextLabel, '몸이 피곤할 때');
      expect(store.entries.length, before);
      expect(store.entries.where((e) => e.isPlanned), isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
}
