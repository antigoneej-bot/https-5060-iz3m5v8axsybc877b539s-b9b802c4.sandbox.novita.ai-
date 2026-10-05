import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/mongi/models/garden_gifts.dart';
import 'package:flutter_app/mongi/widgets/garden_cat_response.dart';
import 'package:flutter_app/mongi/widgets/garden_ambient.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/mongi/models/garden_layout.dart';
import 'package:flutter_app/mongi/widgets/garden_world_view.dart';

void main() {
  Future<void> showWorld(
    WidgetTester tester, {
    double width = 390,
    double height = 844,
    double scale = 1,
    bool reduced = true,
    bool motionEnabled = true,
    bool readOnly = false,
    List<GardenReaction> reactions = const [],
    int publicMemoryStage = 0,
    bool publicCheerBed = false,
    int memoryDays = 0,
    int cheerFlowers = 0,
    VoidCallback? memoryTree,
    VoidCallback? flowers,
    Future<void> Function(String, Offset)? move,
  }) async {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var layout = GardenLayout(spaces: 3);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('나의 넓은 정원')),
          body: MediaQuery(
            data: MediaQueryData(
              size: Size(width, height),
              disableAnimations: reduced,
              textScaler: TextScaler.linear(scale),
            ),
            child: StatefulBuilder(
              builder: (context, update) => GardenWorldView(
                layout: layout,
                motionEnabled: motionEnabled,
                readOnly: readOnly,
                reactions: reactions,
                publicMemoryStage: publicMemoryStage,
                publicCheerBed: publicCheerBed,
                memoryDays: memoryDays,
                cheerFlowers: cheerFlowers,
                onMemoryTree: memoryTree,
                onCheerFlowers: flowers,
                seeds: const {'love': 3, 'peace': 8, 'pine': 2},
                decorations: const ['bench'],
                onMemory: (_) {},
                onPlant: () {},
                onDecorate: () {},
                onMove: (id, p) async {
                  if (move != null) await move(id, p);
                  update(
                    () => layout = layout.move(id, p, [
                      'seed:love',
                      'seed:peace',
                      'seed:pine',
                      'decor:bench',
                    ]),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    if (reduced || !motionEnabled) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('camera pans, zooms and can return home', (tester) async {
    await showWorld(tester);
    final viewer = tester.widget<InteractiveViewer>(
      find.byType(InteractiveViewer),
    );
    final camera = viewer.transformationController!;
    final initial = camera.value.clone();
    await tester.tap(find.text('꽃밭'));
    await tester.pumpAndSettle();
    expect(camera.value.storage[12], isNot(initial.storage[12]));
    await tester.tap(find.byTooltip('정원 확대'));
    await tester.pumpAndSettle();
    expect(
      camera.value.getMaxScaleOnAxis(),
      greaterThan(initial.getMaxScaleOnAxis()),
    );
    await tester.drag(find.byType(InteractiveViewer), const Offset(-70, 0));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'select, save a ground position and undo with transformed coordinates',
    (tester) async {
      final moves = <Offset>[];
      await showWorld(tester, move: (_, p) async => moves.add(p));
      await tester.tap(find.text('배치 모드'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, '사랑'));
      await tester.pumpAndSettle();
      final camera = tester
          .widget<InteractiveViewer>(find.byType(InteractiveViewer))
          .transformationController!;
      final origin = tester.getTopLeft(find.byType(InteractiveViewer));
      final point = MatrixUtils.transformPoint(
        camera.value,
        const Offset(.59 * 2400, .78 * 800),
      );
      await tester.tapAt(origin + point);
      await tester.pumpAndSettle();
      expect(moves.length, 1);
      expect(moves.first.dx, closeTo(.59, .001));
      expect(moves.first.dy, closeTo(.78, .001));
      await tester.tap(find.text('되돌리기'));
      await tester.pumpAndSettle();
      expect(moves.last, GardenLayout.defaultPosition('seed:love'));
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('narrow screen and large text do not overflow', (tester) async {
    await showWorld(tester, width: 320, scale: 1.8);
    await tester.tap(find.text('배치 모드'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets('ambient motion pauses, resumes and respects app lifecycle', (
    tester,
  ) async {
    await showWorld(tester, reduced: false);
    final painter = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((w) => w.painter)
        .whereType<GardenAtmosphere>()
        .single;
    final clock = painter.animation!;
    final initial = clock.value;
    await tester.pump(const Duration(seconds: 1));
    expect(clock.value, isNot(initial));
    await tester.tap(find.byTooltip('정원 움직임 멈추기'));
    await tester.pump();
    final paused = clock.value;
    await tester.pump(const Duration(seconds: 1));
    expect(clock.value, paused);
    await tester.tap(find.byTooltip('정원 움직임 재생'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(clock.value, isNot(paused));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    final background = clock.value;
    await tester.pump(const Duration(seconds: 1));
    expect(clock.value, background);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(clock.value, isNot(background));
    await tester.pumpWidget(const SizedBox());
    expect(tester.binding.transientCallbackCount, 0);
  });
  testWidgets('global motion preference leaves no running ticker', (
    tester,
  ) async {
    await showWorld(tester, reduced: false, motionEnabled: false);
    expect(tester.binding.transientCallbackCount, 0);
  });
  testWidgets('watering targets plants and enlarged bench keeps its hit area', (
    tester,
  ) async {
    await showWorld(tester, reduced: false);
    final bench = find.byKey(const ValueKey('world-item-decor:bench'));
    expect(tester.getSize(bench), const Size(172, 184));
    await tester.tap(find.text('물 주기'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('world-item-seed:love')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    final drops = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((w) => w.painter)
        .whereType<GardenWaterDrops>()
        .single;
    expect(drops.progress.value, greaterThan(0));
    expect(drops.progress.value, lessThan(1));
    expect(find.text('사랑에 물을 주었어요. 잎사귀가 촉촉해졌어요.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    expect(drops.progress.value, 1);
    await tester.tap(find.text('배치 모드'));
    await tester.pump();
    expect(find.text('물주기 완료'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('watering works without animation under reduced motion', (
    tester,
  ) async {
    await showWorld(tester);
    await tester.tap(find.text('물 주기'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('world-item-seed:love')));
    await tester.pumpAndSettle();
    final drops = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((w) => w.painter)
        .whereType<GardenWaterDrops>()
        .single;
    expect(drops.progress.value, 0);
    expect(tester.binding.transientCallbackCount, 0);
  });
  testWidgets('rest mode hides controls and always has an exit', (
    tester,
  ) async {
    await showWorld(tester);
    await tester.tap(find.text('잠깐 쉬기'));
    await tester.pumpAndSettle();
    expect(find.text('배치 모드'), findsNothing);
    expect(find.text('물 주기'), findsNothing);
    expect(find.text('쉬기 마치기'), findsOneWidget);
    await tester.tap(find.text('쉬기 마치기'));
    await tester.pumpAndSettle();
    expect(find.text('배치 모드'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'keepsake controls open private content but public gardens omit it',
    (tester) async {
      var memories = 0, flowers = 0;
      await showWorld(
        tester,
        memoryDays: 8,
        cheerFlowers: 3,
        memoryTree: () => memories++,
        flowers: () => flowers++,
      );
      await tester.tap(find.text('기억의 나무'));
      await tester.tap(find.text('응원 꽃'));
      expect([memories, flowers], [1, 1]);
      expect(find.byKey(const Key('garden-memory-tree')), findsOneWidget);
      await showWorld(
        tester,
        readOnly: true,
        memoryDays: 8,
        cheerFlowers: 3,
        memoryTree: () {},
        flowers: () {},
      );
      expect(find.byKey(const Key('garden-memory-tree')), findsNothing);
      expect(find.byKey(const Key('garden-cheer-flowers')), findsNothing);
      expect(find.text('물 주기'), findsNothing);
      expect(find.text('기억의 나무'), findsNothing);
    },
  );
  testWidgets('public keepsakes show appearance with no private callbacks', (
    tester,
  ) async {
    await showWorld(
      tester,
      readOnly: true,
      publicMemoryStage: 3,
      publicCheerBed: true,
      memoryDays: 99,
      cheerFlowers: 99,
      memoryTree: () => fail('private memory opened'),
      flowers: () => fail('private flowers opened'),
    );
    for (final key in ['garden-memory-tree', 'garden-cheer-flowers']) {
      final gesture = tester.widget<GestureDetector>(find.byKey(Key(key)));
      expect(gesture.onTap, isNull);
    }
    expect(find.bySemanticsLabel('기억의 나무, 기록한 날 99일'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('expired reactions disappear while garden stays open', (
    tester,
  ) async {
    await showWorld(
      tester,
      reactions: [
        GardenReaction('heart', DateTime.now().add(const Duration(seconds: 1))),
      ],
    );
    expect(find.text('💗'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    // Flutter fake timers advance independently from wall time; supply a past deadline on rebuild.
    await showWorld(
      tester,
      reactions: [
        GardenReaction(
          'heart',
          DateTime.now().subtract(const Duration(seconds: 1)),
        ),
      ],
    );
    expect(find.text('💗'), findsNothing);
  });
  testWidgets(
    'tap a live response plays one Mongi reaction and returns to normal',
    (tester) async {
      await showWorld(
        tester,
        reactions: [
          GardenReaction('star', DateTime.now().add(const Duration(hours: 1))),
        ],
      );
      expect(find.byType(GardenCatResponse), findsNothing);
      // showWorld settles the automatic, bounded greeting. A tap can replay it.
      final button = find.widgetWithText(TextButton, '⭐');
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pump();
      expect(find.byType(GardenCatResponse), findsOneWidget);
      expect(
        tester
            .widget<GardenCatResponse>(find.byType(GardenCatResponse))
            .animated,
        isFalse,
      );
      await tester.pumpAndSettle();
      expect(find.byType(GardenCatResponse), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  if (const bool.fromEnvironment('GARDEN_GOLDENS')) {
    testWidgets('capture playable garden', (tester) async {
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
      final font = FontLoader('Roboto')
        ..addFont(rootBundle.load('assets/fonts/GowunDodum-Regular.ttf'));
      await font.load();
      await showWorld(tester);
      if (find.byTooltip('햇살 정원 보기').evaluate().isNotEmpty) {
        await tester.tap(find.byTooltip('햇살 정원 보기'));
        await tester.pumpAndSettle();
      }
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('../docs/expanded-garden.png'),
      );
      await showWorld(
        tester,
        width: 1120,
        height: 620,
        memoryDays: 8,
        cheerFlowers: 3,
        memoryTree: () {},
        flowers: () {},
      );
      if (find.byTooltip('햇살 정원 보기').evaluate().isNotEmpty) {
        await tester.tap(find.byTooltip('햇살 정원 보기'));
        await tester.pumpAndSettle();
      }
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('../docs/expanded-garden-overview.png'),
      );
      await tester.tap(find.text('잠깐 쉬기'));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('../docs/garden-rest.png'),
      );
    });
  }
}
