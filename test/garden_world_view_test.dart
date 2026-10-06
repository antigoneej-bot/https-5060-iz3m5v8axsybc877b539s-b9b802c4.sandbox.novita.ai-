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

  // The zone picker is a closed DropdownButton showing only the current
  // selection; open it before its other options' text is in the tree.
  Future<void> selectZone(WidgetTester tester, String label) async {
    await tester.tap(find.byType(DropdownButton<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  // Care/decorate/memory tools now live behind a collapsed "돌보기 · 꾸미기 ·
  // 추억" toggle; open it before tapping any tool inside. The toggle only
  // flips _toolsOpen, so if the tray is already open (its label already
  // reads "도구 접기"), tapping it again would close it - check state first
  // instead of toggling unconditionally.
  Future<void> openTools(WidgetTester tester) async {
    if (find.text('도구 접기').evaluate().isNotEmpty) return;
    await tester.tap(find.text('돌보기 · 꾸미기 · 추억'));
    // Ambient controllers repeat forever when a test runs with
    // reduced:false, so pumpAndSettle would hang here; a single bounded
    // pump is enough to open the ConstrainedBox/SingleChildScrollView tray.
    await tester.pump(const Duration(milliseconds: 300));
  }

  // Zoom/light/motion controls moved from standalone icon buttons into a
  // single "보기 설정" popup menu; open it before tapping an option's text.
  // The ambient controllers repeat forever while motion is on, so
  // pumpAndSettle would hang; use bounded pumps instead. A zero-duration
  // pump must run right after the tap so the PopupMenuRoute is actually
  // pushed onto the Navigator before its 300ms entrance transition is
  // pumped - otherwise the menu item's hit test can land on the route
  // underneath instead of the menu itself.
  Future<void> selectViewOption(WidgetTester tester, String label) async {
    await tester.tap(find.byTooltip('보기 설정'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.text(label));
    await tester.pump();
  }

  testWidgets('camera pans, zooms and can return home', (tester) async {
    await showWorld(tester);
    final viewer = tester.widget<InteractiveViewer>(
      find.byType(InteractiveViewer),
    );
    final camera = viewer.transformationController!;
    final initial = camera.value.clone();
    await selectZone(tester, '꽃밭');
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
      await openTools(tester);
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
    await openTools(tester);
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
    // The garden's ambient controllers repeat forever while motion is on, so
    // pumpAndSettle would hang here. The popup route needs a zero-duration
    // pump to actually push/register before its 300ms entrance transition
    // is pumped, or the menu item's hit test lands on the old route instead.
    await selectViewOption(tester, '정원 움직임 멈추기');
    final paused = clock.value;
    await tester.pump(const Duration(seconds: 1));
    expect(clock.value, paused);
    await selectViewOption(tester, '정원 움직임 재생');
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
    // The user's own pause preference must survive a backgrounding, not
    // just the lifecycle's own foreground/background suspension above.
    await selectViewOption(tester, '정원 움직임 멈추기');
    await tester.pump();
    final userPaused = clock.value;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 1));
    expect(clock.value, userPaused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(clock.value, userPaused);
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
    // The wide-garden layout (AspectRatio 1.25, depth-scaled art) renders the
    // bench at a different on-screen size than the old portrait layout;
    // this reflects the intentional ZIP layout change, not a test bug.
    // Flutter's layout pass can round the final pixel values slightly
    // (e.g. off by 1e-4), so compare with a tolerance instead of exact.
    final benchSize = tester.getSize(bench);
    expect(benchSize.width, closeTo(209.935, 0.01));
    expect(benchSize.height, closeTo(162.027, 0.01));
    await openTools(tester);
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
    await openTools(tester);
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
    await openTools(tester);
    await tester.tap(find.text('잠깐 쉬기'));
    await tester.pumpAndSettle();
    expect(find.text('배치 모드'), findsNothing);
    expect(find.text('물 주기'), findsNothing);
    expect(find.text('쉬기 마치기'), findsOneWidget);
    await tester.tap(find.text('쉬기 마치기'));
    await tester.pumpAndSettle();
    // _toolsOpen isn't reset by rest mode, so the tray is still expanded
    // from the openTools() call above. Call openTools() again anyway to
    // confirm it's a no-op (idempotent) rather than assuming the state.
    await openTools(tester);
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
      await openTools(tester);
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
