import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/mongi/integration/mature_tree_memories.dart';
import 'package:flutter_app/mongi/integration/plant_memory.dart';

void main() {
  testWidgets(
    'mature summary shows real memories and month navigation at narrow width',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      DateTime? selected;
      var wrote = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MatureTreeMemories(
                entries: const [
                  PlantMemoryEntry(id: 'a', on: '2026-09-30', note: '첫 추억'),
                  PlantMemoryEntry(id: 'b', on: '2026-10-24', note: '오늘의 추억'),
                ],
                anniversaryOn: '2026-09-25',
                now: DateTime(2026, 10, 24),
                onWrite: () => wrote = true,
                onHistory: () {},
                onMonth: (month) => selected = month,
              ),
            ),
          ),
        ),
      );
      expect(find.textContaining('함께한 30일'), findsOneWidget);
      expect(find.textContaining('추억 2개'), findsOneWidget);
      await tester.tap(find.text('2026-09 · 1개'));
      expect(selected, DateTime(2026, 9));
      await tester.tap(find.text('오늘의 추억 더하기'));
      expect(wrote, true);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'empty future anniversary invents neither memories nor elapsed days',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatureTreeMemories(
              entries: const [],
              anniversaryOn: '2027-01-01',
              now: DateTime(2026, 10, 24),
              onWrite: () {},
              onHistory: null,
              onMonth: null,
            ),
          ),
        ),
      );
      expect(find.textContaining('추억 0개'), findsOneWidget);
      expect(find.textContaining('함께한'), findsNothing);
      expect(find.textContaining('2027-01-01'), findsOneWidget);
    },
  );
  testWidgets('future memories do not open a calendar beyond its valid range', (
    tester,
  ) async {
    var opened = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MatureTreeMemories(
            entries: const [
              PlantMemoryEntry(
                id: 'future',
                on: '2027-01-01',
                note: '미리 남긴 기억',
              ),
            ],
            anniversaryOn: null,
            now: DateTime(2026, 10, 24),
            onWrite: null,
            onHistory: null,
            onMonth: (_) => opened = true,
          ),
        ),
      ),
    );
    final chip = tester.widget<ActionChip>(find.byType(ActionChip));
    expect(chip.onPressed, isNull);
    expect(opened, false);
  });
}
