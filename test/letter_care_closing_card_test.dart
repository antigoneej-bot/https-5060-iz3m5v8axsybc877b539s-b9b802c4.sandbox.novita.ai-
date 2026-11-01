import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_app/models/letter_entry.dart';
import 'package:flutter_app/services/care_journal_store.dart';
import 'package:flutter_app/widgets/letter_care_closing_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('care_closing_layout_');
    Hive.init(directory.path);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (_) async => null,
        );
  });
  tearDownAll(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  testWidgets(
    'small screen supports large text and closing with no extra answers',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.runAsync(() => CareJournalStore.instance.clear());
      final letter = LetterEntry(
        id: 'skip-letter',
        catId: 'angry',
        date: DateTime.now(),
        letterText: '오늘의 마음 그대로.',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: SingleChildScrollView(
                child: LetterCareClosingCard(letter: letter),
              ),
            ),
          ),
        ),
      );
      // Let real Hive I/O progress between fake-async widget frames; do not
      // enqueue another reload behind the widget's unfinished fake-async read.
      for (var frame = 0; frame < 20; frame++) {
        await tester.pump(const Duration(milliseconds: 20));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        if (find.byType(ChoiceChip).evaluate().isNotEmpty) break;
      }
      expect(find.byType(ChoiceChip), findsNWidgets(4));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        tester
            .widgetList<ChoiceChip>(find.byType(ChoiceChip))
            .every((chip) => !chip.selected),
        isTrue,
      );
      final close = find.widgetWithText(FilledButton, '오늘은 여기까지');
      await tester.ensureVisible(close);
      await tester.tap(close);
      await tester.pumpAndSettle();
      expect(find.text('오늘의 편지를 간직했어요.'), findsOneWidget);
      expect(CareJournalStore.instance.entryForLetter(letter.id), isNull);
      expect(tester.takeException(), isNull);
    },
  );
}
