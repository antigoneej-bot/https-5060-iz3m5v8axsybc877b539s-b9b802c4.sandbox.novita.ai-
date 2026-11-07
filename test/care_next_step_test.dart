import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/models/care_journal_entry.dart';
import 'package:flutter_app/models/care_next_step.dart';
import 'package:flutter_app/widgets/care_next_step_card.dart';

void main() {
  final now = DateTime(2026, 10, 24, 12);
  CareJournalEntry entry(
    String id, {
    CareHelpfulness? feeling = CareHelpfulness.helped,
    int daysAgo = 1,
    String label = '가볍게 걷기',
    String? context,
    bool completed = true,
  }) {
    final date = now.subtract(Duration(days: daysAgo));
    return CareJournalEntry(
      id: id,
      createdAt: date,
      updatedAt: date,
      actionKind: CareActionKind.walk,
      actionLabel: label,
      contextLabel: context,
      completedAt: completed ? date : null,
      helpfulness: feeling,
    );
  }

  test('plans and unreviewed actions never count as helpful reports', () {
    final summary = CareNextStep.fromEntries([
      entry('plan', completed: false, feeling: null),
      entry('done', feeling: null),
    ], now: now);
    expect(summary.suggested, isNull);
    expect(summary.reviewed, 0);
    expect(summary.awaitingFeedback?.id, 'done');
  });
  test('counts only explicit reports for the same action and context', () {
    final summary = CareNextStep.fromEntries([
      entry('a'),
      entry('b', daysAgo: 2, feeling: CareHelpfulness.same),
      entry('c', daysAgo: 3),
      entry('d', daysAgo: 4, context: '다른 상황'),
      entry('e', daysAgo: 40),
      entry('f', daysAgo: -1),
    ], now: now);
    expect(summary.suggested?.id, 'a');
    expect(summary.reviewed, 3);
    expect(summary.helped, 2);
  });
  for (final feeling in [
    CareHelpfulness.harder,
    CareHelpfulness.same,
    CareHelpfulness.unknown,
  ]) {
    test('latest $feeling prevents repeating an older helpful experience', () {
      final summary = CareNextStep.fromEntries([
        entry('old', daysAgo: 2),
        entry('new', feeling: feeling),
      ], now: now);
      expect(summary.suggested, isNull);
    });
  }
  test(
    'conflicting same-time feedback is conservative and order independent',
    () {
      final a = entry('a'), b = entry('b', feeling: CareHelpfulness.harder);
      expect(CareNextStep.fromEntries([a, b], now: now).suggested, isNull);
      expect(CareNextStep.fromEntries([b, a], now: now).suggested, isNull);
    },
  );
  test('different custom labels and situations are not silently merged', () {
    final summary = CareNextStep.fromEntries([
      entry('a', context: '퇴근 후'),
      entry('b', feeling: CareHelpfulness.harder, context: '출근 전'),
      entry('c', feeling: CareHelpfulness.harder, label: '다른 돌봄'),
    ], now: now);
    expect(summary.suggested?.id, 'a');
    expect(summary.reviewed, 1);
  });
  testWidgets(
    'large text fits and navigation never records an action automatically',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var repeat = 0, feedback = 0, choose = 0, garden = 0;
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              child: CareNextStepCard(
                summary: CareNextStep.fromEntries([
                  entry('a'),
                  entry('b', feeling: null),
                ], now: now),
                onRepeat: () => repeat++,
                onFeedback: () => feedback++,
                onChoose: () => choose++,
                onGarden: () => garden++,
              ),
            ),
          ),
        ),
      );
      expect([repeat, feedback, choose, garden], [0, 0, 0, 0]);
      await tester.ensureVisible(find.text('정원에서 쉬기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('정원에서 쉬기'));
      await tester.pump();
      expect([repeat, feedback, choose, garden], [0, 0, 0, 1]);
      expect(tester.takeException(), isNull);
    },
  );
}
