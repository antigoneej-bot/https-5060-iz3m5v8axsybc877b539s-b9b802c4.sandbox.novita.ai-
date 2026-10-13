import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/mongi/providers/garden_provider.dart';
import 'package:flutter_app/mongi/models/emotion.dart';
import 'package:flutter_app/mongi/screens/choice_screen.dart';
import 'package:flutter_app/mongi/l10n/gen/app_localizations.dart';

class RecordingGarden extends GardenProvider {
  final resultIds = <String?>[];
  final advanceIds = <String?>[];
  int diaryWrites = 0;
  bool failResult = false, failAdvance = false;
  Completer<void>? pending;
  @override
  Future<bool> recordSession(
    Map<EmotionType, int> eatenByType, {
    required bool choseLove,
    String? seedType,
    bool earlyStop = false,
    int? target,
    int? playedStage,
    String? sessionId,
  }) async {
    resultIds.add(sessionId);
    if (failResult) {
      failResult = false;
      throw StateError('disk');
    }
    await pending?.future;
    lastEarnedScore = 55;
    lastEarnedLightEssence = 24;
    return false;
  }

  @override
  Future<void> advanceToNextStage({String? sessionId}) async {
    advanceIds.add(sessionId);
    if (failAdvance) {
      failAdvance = false;
      throw StateError('disk');
    }
    stage = 2;
  }

  @override
  Future<void> addDiaryEntry({
    required EmotionType emotionType,
    String? targetName,
    required int eatenCount,
    String? note,
    int? intensity,
    List<String>? triggers,
    String? sessionId,
  }) async {
    diaryWrites++;
  }
}

Widget app(RecordingGarden garden) =>
    ChangeNotifierProvider<GardenProvider>.value(
      value: garden,
      child: MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              child: const Text('open result'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChoiceScreen(
                    sessionId: 'test-run',
                    emotions: [Emotion.all.first],
                    targetName: null,
                    eatenByType: {Emotion.all.first.type: 20},
                    target: 20,
                    playedStage: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

void main() {
  testWidgets('entry auto saves; back leaves no fabricated mood diary', (
    tester,
  ) async {
    final garden = RecordingGarden();
    await tester.pumpWidget(app(garden));
    await tester.tap(find.text('open result'));
    await tester.pumpAndSettle();
    expect(garden.resultIds, ['test-run:result']);
    expect(find.text('플레이 보상을 저장했어요'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('open result'), findsOneWidget);
    expect(garden.diaryWrites, 0);
    expect(garden.resultIds.length, 1);
    await tester.pumpWidget(const SizedBox());
    garden.dispose();
  });

  testWidgets(
    'failed automatic save retries same ID before any optional action',
    (tester) async {
      final garden = RecordingGarden()..failResult = true;
      await tester.pumpWidget(app(garden));
      await tester.tap(find.text('open result'));
      await tester.pumpAndSettle();
      expect(find.text('다시 저장하기'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('runner-result-garden')),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.text('다시 저장하기'));
      await tester.pumpAndSettle();
      expect(garden.resultIds, ['test-run:result', 'test-run:result']);
      expect(find.text('다시 저장하기'), findsNothing);
      expect(garden.diaryWrites, 0);
      await tester.pumpWidget(const SizedBox());
      garden.dispose();
    },
  );

  testWidgets('back while a save is pending cannot discard the result', (
    tester,
  ) async {
    final garden = RecordingGarden()..pending = Completer<void>();
    await tester.pumpWidget(app(garden));
    await tester.tap(find.text('open result'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byType(ChoiceScreen), findsOneWidget);
    expect(garden.resultIds.length, 1);
    garden.pending!.complete();
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('open result'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    garden.dispose();
  });

  testWidgets('optional stage failure retries only the stage, never rewards', (
    tester,
  ) async {
    final garden = RecordingGarden()..failAdvance = true;
    await tester.pumpWidget(app(garden));
    await tester.tap(find.text('open result'));
    await tester.pumpAndSettle();
    final advance = find.byKey(const ValueKey('runner-result-advance'));
    await tester.ensureVisible(advance);
    await tester.tap(advance);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('다시 저장하기'));
    await tester.tap(find.text('다시 저장하기'));
    await tester.pumpAndSettle();
    expect(garden.advanceIds, ['test-run:advance', 'test-run:advance']);
    expect(garden.resultIds.length, 1);
    expect(garden.stage, 2);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    garden.dispose();
  });
}
