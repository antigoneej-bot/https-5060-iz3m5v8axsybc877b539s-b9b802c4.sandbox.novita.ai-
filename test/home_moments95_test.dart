import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/l10n/app_language.dart';
import 'package:flutter_app/models/home_moments_snapshot.dart';
import 'package:flutter_app/models/letter_entry.dart';
import 'package:flutter_app/mongi/integration/mongi_garden_data.dart';
import 'package:flutter_app/widgets/home_moments.dart';
import 'package:flutter_app/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final today = DateTime(2026, 11, 6, 12);
  LetterEntry entry(String id, DateTime date) => LetterEntry(
    id: id,
    catId: 'joy',
    date: date,
    letterText: 'Private original stays unchanged',
  );
  final garden = MongiGardenData(
    seeds: {'pine': 7, 'cherry': 1, 'maple': 0},
    wateredOn: {
      'pine': '2026-11-06',
      'cherry': '2026-11-05',
      'maple': '2026-11-06',
      'unknown': '2026-11-06',
    },
  );

  setUpAll(() async {
    for (final font in ['GowunDodum', 'GamjaFlower']) {
      await (FontLoader(
        font,
      )..addFont(rootBundle.load('assets/fonts/$font-Regular.ttf'))).load();
    }
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppLanguage.instance.select('ko');
  });

  test('only saved local-day records and actual watered plants appear', () {
    final same = entry('today', today);
    final summary = HomeMomentsSnapshot(
      letters: [
        entry('yesterday', DateTime(2026, 11, 5, 23, 59)),
        same,
        same,
        entry('midnight', DateTime(2026, 11, 6)),
        entry('future', DateTime(2026, 11, 6, 13)),
      ],
      garden: garden,
      now: today,
    );
    expect(summary.recordsToday, 2);
    expect(summary.wateredPlants.map((p) => p.seed.id), ['pine']);
    expect(summary.wateredPlants.single.growth, 7);
    expect(same.letterText, 'Private original stays unchanged');
    expect(garden.seeds, {'pine': 7, 'cherry': 1, 'maple': 0});
    expect(garden.seedTokens, 0);
  });

  test('a new day resets the summary without deleting history or growth', () {
    final summary = HomeMomentsSnapshot(
      letters: [entry('saved', today)],
      garden: garden,
      now: DateTime(2026, 11, 7),
    );
    expect(summary.recordsToday, 0);
    expect(summary.wateredPlants, isEmpty);
    expect(summary.hasRecords, isTrue);
    expect(garden.seeds['pine'], 7);
    expect(
      HomeMomentsSnapshot(letters: [], garden: null, now: today).hasToday,
      isFalse,
    );
  });

  Future<void> mount(
    WidgetTester t,
    ValueNotifier<MongiGardenData> data, {
    List<LetterEntry> letters = const [],
    Future<void> Function()? reload,
    DateTime Function()? now,
    ValueChanged<String>? action,
    double scale = 1,
    Key? boundary,
  }) => t.pumpWidget(
    MaterialApp(
      theme: appTheme,
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: RepaintBoundary(
          key: boundary,
          child: Scaffold(
            body: SafeArea(
              child: SingleChildScrollView(
                child: HomeMoments(
                  letters: letters,
                  garden: data,
                  reloadGarden: reload ?? () async {},
                  now: now ?? () => today,
                  onRecords: () => action?.call('records'),
                  onReview: () => action?.call('review'),
                  onMemoryBook: () => action?.call('book'),
                  onPlant: (id) => action?.call('plant:$id'),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  testWidgets(
    'empty garden and history do not invent activity or a task list',
    (t) async {
      final data = ValueNotifier(MongiGardenData());
      await mount(t, data);
      await t.pumpAndSettle();
      expect(find.byKey(const Key('home-saved-moments')), findsNothing);
      expect(find.textContaining('답장'), findsNothing);
      await t.pumpWidget(const SizedBox());
      data.dispose();
    },
  );

  testWidgets(
    'loading and failed reads never advertise stale plant activity; retry is coalesced',
    (t) async {
      final data = ValueNotifier(garden);
      var request = Completer<void>();
      var calls = 0;
      await mount(
        t,
        data,
        reload: () {
          calls++;
          return request.future;
        },
      );
      expect(find.byKey(const ValueKey('home-watered-pine')), findsNothing);
      request.completeError(StateError('offline local read'));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('home-moments-retry')), findsOneWidget);
      expect(find.byKey(const ValueKey('home-watered-pine')), findsNothing);
      request = Completer<void>();
      await t.tap(find.byKey(const Key('home-moments-retry')));
      await t.tap(find.byKey(const Key('home-moments-retry')));
      expect(calls, 2);
      request.complete();
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('home-watered-pine')), findsOneWidget);
      expect(find.byKey(const Key('home-moments-retry')), findsNothing);
      await t.pumpWidget(const SizedBox());
      data.dispose();
    },
  );

  testWidgets('store notifications and midnight refresh reflect actual saves', (
    t,
  ) async {
    final data = ValueNotifier(MongiGardenData());
    var now = DateTime(2026, 11, 6, 23, 59);
    await mount(t, data, letters: [entry('saved', today)], now: () => now);
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('home-watered-pine')), findsNothing);
    data.value = garden;
    await t.pump();
    expect(find.byKey(const ValueKey('home-watered-pine')), findsOneWidget);
    now = DateTime(2026, 11, 7);
    await t.pump(const Duration(minutes: 1));
    expect(find.byKey(const ValueKey('home-watered-pine')), findsNothing);
    expect(find.byKey(const Key('home-saved-records')), findsNothing);
    expect(find.byKey(const Key('home-reflection')), findsOneWidget);
    expect(data.value.seeds['pine'], 7);
    await t.pumpWidget(const SizedBox());
    data.dispose();
  });

  for (final lang in ['ko', 'en']) {
    for (final size in [
      const Size(320, 640),
      const Size(390, 844),
      const Size(844, 390),
    ]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('saved moments routes are reachable $lang $size $scale', (
          t,
        ) async {
          await AppLanguage.instance.select(lang);
          t.view.physicalSize = size;
          t.view.devicePixelRatio = 1;
          addTearDown(t.view.resetPhysicalSize);
          addTearDown(t.view.resetDevicePixelRatio);
          final data = ValueNotifier(garden), shot = GlobalKey();
          final actions = <String>[];
          await mount(
            t,
            data,
            letters: [entry('one', today), entry('two', today)],
            action: actions.add,
            scale: scale,
            boundary: shot,
          );
          await t.pumpAndSettle();
          expect(find.textContaining('Private original'), findsNothing);
          expect(find.textContaining('답장'), findsNothing);
          expect(find.textContaining('색칠'), findsNothing);
          for (final key in [
            'home-saved-records',
            'home-watered-pine',
            'home-reflection',
            'home-memory-book',
          ]) {
            final control = find.byKey(ValueKey(key));
            await t.ensureVisible(control);
            await t.tap(control);
            await t.pump();
          }
          expect(actions, ['records', 'plant:pine', 'review', 'book']);
          expect(t.takeException(), isNull);
          final dir = Platform.environment['UI_FLOW95_REVIEW_DIR'];
          if (dir != null) {
            await t.ensureVisible(find.byKey(const Key('home-saved-records')));
            await t.pumpAndSettle();
            await t.runAsync(() async {
              final image =
                  await (shot.currentContext!.findRenderObject()!
                          as RenderRepaintBoundary)
                      .toImage();
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              await Directory(dir).create(recursive: true);
              await File(
                '$dir/moments-$lang-${size.width.toInt()}-$scale.png',
              ).writeAsBytes(bytes!.buffer.asUint8List());
              image.dispose();
            });
          }
          await t.pumpWidget(const SizedBox());
          data.dispose();
        });
      }
    }
  }
}
