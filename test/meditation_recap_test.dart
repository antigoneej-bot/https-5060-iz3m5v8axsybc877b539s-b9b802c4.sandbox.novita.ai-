import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/services/meditation_library_store.dart';
import 'package:flutter_app/services/meditation_recap_service.dart';
import 'package:flutter_app/widgets/meditation_recap_card.dart';

Map<String, dynamic> answer(
  String session,
  String day,
  String feeling, {
  String guide = 'forestRest',
}) => {'session': session, 'guide': guide, 'feeling': feeling, 'at': day};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime(2026, 10, 16, 15);
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  test(
    'seven local calendar days count actual responses, not skipped days',
    () {
      final recap = MeditationRecap.fromCheckIns([
        answer('boundary', '2026-10-10T00:00:00', 'same'),
        answer('today', '2026-10-16T14:00:00', 'better'),
        answer('second-today', '2026-10-16T13:00:00', 'worse'),
        answer('old', '2026-10-09T23:59:59', 'better'),
        answer('future', '2026-10-16T15:00:01', 'better'),
      ], now: now);
      expect(recap.from, DateTime(2026, 10, 10));
      expect(recap.through, DateTime(2026, 10, 16));
      expect([recap.better, recap.same, recap.worse], [1, 1, 1]);
      expect(recap.total, 3);
      expect(recap.recordedDays, 2);
      expect(recap.suggestPause, false);
    },
  );

  test(
    'deduplicates restored sessions by latest timestamp, validates input',
    () {
      final recap = MeditationRecap.fromCheckIns([
        answer('copy', '2026-10-11T12:00:00', 'better'),
        answer('copy', '2026-10-16T12:00:00', 'worse'),
        answer('invalid-feeling', '2026-10-16T12:00:00', 'diagnosed'),
        answer('unknown', '2026-10-16T12:00:00', 'better', guide: 'missing'),
        answer('', '2026-10-16T12:00:00', 'better'),
        answer('bad-date', 'not-a-date', 'better'),
        answer('overflow-time', '2026-10-15T25:00:00', 'better'),
      ], now: now);
      expect(recap.total, 1);
      expect(recap.worse, 1);
      expect(recap.suggestPause, true);
      expect(recap.preferredGuide, isNull);
      expect(
        MeditationRecap.fromCheckIns([
          answer('invalid-calendar', '2026-02-30T12:00:00', 'better'),
        ], now: DateTime(2026, 3, 3)).total,
        0,
      );
    },
  );

  test('does not suggest a guide with a later uncomfortable response', () {
    final recap = MeditationRecap.fromCheckIns([
      answer('forest-comfort', '2026-10-16T13:00:00', 'better'),
      answer('forest-later', '2026-10-16T14:00:00', 'worse'),
      answer(
        'rain-comfort',
        '2026-10-15T13:00:00',
        'better',
        guide: 'rainThunderRest',
      ),
      answer(
        'rain-later',
        '2026-10-16T14:30:00',
        'same',
        guide: 'rainThunderRest',
      ),
    ], now: now);
    expect(recap.preferredGuide, 'rainThunderRest');
    expect(recap.suggestPause, false);
  });

  testWidgets(
    'empty recap gives a directly usable free guide without inventing improvement',
    (tester) async {
      final store = MeditationLibraryStore();
      String? opened;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MeditationRecapCard(
                store: store,
                now: now,
                onOpenGuide: (key) => opened = key,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('이번 주에는 명상 후 남긴 응답이 없어요'), findsOneWidget);
      expect(find.text('편안해짐 0회'), findsNothing);
      await tester.tap(find.text('2분 숲 명상 살펴보기'));
      expect(opened, 'forestRest');
      await tester.pumpWidget(const SizedBox.shrink());
      store.dispose();
    },
  );

  testWidgets('recap uses saved answers and opens the relevant guide', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'meditation.checkins': jsonEncode([
        answer('a', '2026-10-16T12:00:00', 'better', guide: 'rainThunderRest'),
        answer('b', '2026-10-15T12:00:00', 'same'),
      ]),
    });
    final store = MeditationLibraryStore();
    String? opened;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MeditationRecapCard(
              store: store,
              now: now,
              onOpenGuide: (key) => opened = key,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('2일 동안 남긴 2개의 응답'), findsOneWidget);
    expect(find.text('편안해짐 1회'), findsOneWidget);
    expect(find.text('비슷함 1회'), findsOneWidget);
    expect(find.text('불편함 0회'), findsOneWidget);
    await tester.tap(find.text('그 명상 다시 열기'));
    expect(opened, 'rainThunderRest');
    await tester.pumpWidget(const SizedBox.shrink());
    store.dispose();
  });

  testWidgets(
    'recent discomfort offers a pause, fits a narrow phone, never opens media',
    (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({
        'meditation.checkins': jsonEncode([
          answer('a', '2026-10-16T12:00:00', 'worse'),
          answer('b', '2026-10-15T12:00:00', 'better'),
        ]),
      });
      final store = MeditationLibraryStore();
      String? opened;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: MeditationRecapCard(
                store: store,
                now: now,
                onOpenGuide: (key) => opened = key,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('그 명상 다시 열기'), findsNothing);
      await tester.ensureVisible(find.text('주변 잠깐 살펴보기'));
      await tester.tap(find.text('주변 잠깐 살펴보기'));
      await tester.pumpAndSettle();
      expect(find.text('지금은 잠깐 쉬어도 괜찮아요'), findsOneWidget);
      expect(opened, isNull);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('내 속도로 쉴게요'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
      store.dispose();
    },
  );
}
