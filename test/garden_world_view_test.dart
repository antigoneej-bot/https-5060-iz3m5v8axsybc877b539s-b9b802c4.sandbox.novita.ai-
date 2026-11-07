import 'package:audioplayers_platform_interface/audioplayers_platform_interface.dart';
import 'support/fake_audioplayers_platform.dart';
import 'support/fake_global_audioplayers_platform.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/mongi/widgets/garden_cat_pose.dart';
import 'package:flutter_app/mongi/widgets/garden_grounded_art.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/mongi/models/garden_gifts.dart';
import 'package:flutter_app/mongi/widgets/garden_cat_response.dart';
import 'package:flutter_app/mongi/widgets/garden_ambient.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/mongi/models/garden_layout.dart';
import 'package:flutter_app/mongi/widgets/garden_world_view.dart';
import 'package:flutter_app/mongi/widgets/living_garden_scene.dart';

void main() {
  testWidgets(
    'inspection preserves plant bounds and root, persists beyond flash, and tracks real watering',
    (t) async {
      t.view.physicalSize = const Size(390, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final layout = GardenLayout(
        positions: const {'seed:pine': Offset(.36, .55)},
      );
      Future<void> show({
        String? focus,
        bool watered = false,
        bool readOnly = false,
      }) async {
        await t.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GardenWorldView(
                layout: layout,
                seeds: const {'pine': 1},
                decorations: const [],
                motionEnabled: false,
                fillViewport: true,
                cultivationMode: true,
                focusPlantId: focus,
                plantFocusRequest: focus == null ? 0 : 1,
                wateredOn: watered
                    ? {
                        'pine': DateTime.now().toIso8601String().substring(
                          0,
                          10,
                        ),
                      }
                    : const {},
                readOnly: readOnly,
                onInspectPlant: (_) {},
                onMove: (_, __) async {},
                onMemory: (_) {},
                onPlant: () {},
                onDecorate: () {},
              ),
            ),
          ),
        );
        await t.pumpAndSettle();
      }

      await show();
      final art = find.byType(GardenPlantArt);
      final size = t.getSize(art);
      final position = t.widget<AnimatedPositioned>(
        find.byKey(const ValueKey('world-position-seed:pine')),
      );
      await show(focus: 'pine');
      final groundStack = t.widget<SizedBox>(find.byKey(const Key('garden-world-ground'))).child! as Stack;
      final haloIndex = groundStack.children.indexWhere((w) => w.key == const Key('located-plant-highlight'));
      final itemsIndex = groundStack.children.indexWhere((w) => w.key == const Key('garden-item-layer'));
      expect(haloIndex, greaterThanOrEqualTo(0));
      expect(haloIndex, lessThan(itemsIndex), reason: 'Halo must never paint over plant artwork or its name');
      expect(
        t.getSize(art),
        size,
        reason: 'Selection must not add layout padding',
      );
      final selected = t.widget<AnimatedPositioned>(
        find.byKey(const ValueKey('world-position-seed:pine')),
      );
      expect(selected.top, position.top);
      expect(selected.left, position.left);
      expect(find.byKey(const ValueKey('needs-water-pine')), findsOneWidget);
      await t.pump(const Duration(seconds: 4));
      expect(find.byKey(const Key('located-plant-highlight')), findsOneWidget);
      await show(focus: 'pine', watered: true);
      expect(find.byKey(const ValueKey('needs-water-pine')), findsNothing);
      t.view.physicalSize = const Size(844, 390);
      await t.pumpAndSettle();
      final camera = t.widget<InteractiveViewer>(
        find.byKey(const Key('garden-world-camera')),
      );
      final ground = MatrixUtils.transformPoint(
        camera.transformationController!.value,
        const Offset(.36 * 2400, .55 * 800),
      );
      expect(
        ground.dx,
        inInclusiveRange(
          0,
          t.getSize(find.byKey(const Key('garden-world-camera'))).width,
        ),
      );
      expect(
        ground.dy,
        inInclusiveRange(
          0,
          t.getSize(find.byKey(const Key('garden-world-camera'))).height,
        ),
      );
      await show(focus: 'pine', readOnly: true);
      expect(find.byKey(const Key('plant-focus-backdrop')), findsNothing);
      expect(find.byKey(const Key('located-plant-highlight')), findsNothing);
      expect(find.byKey(const ValueKey('plant-soil-seed:pine')), findsNothing);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    },
  );
  setUpAll(() {
    AudioplayersPlatformInterface.instance = FakeAudioplayersPlatform();
    GlobalAudioplayersPlatformInterface.instance =
        FakeGlobalAudioplayersPlatform();
  });
  testWidgets(
    'locating a saved pine brings its original coordinate into view',
    (t) async {
      t.view.physicalSize = const Size(390, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final layout = GardenLayout(
        positions: const {'seed:pine': Offset(.36, .55)},
      );
      Future<void> show(int request, {bool readOnly = false}) async {
        await t.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GardenWorldView(
                fillViewport: true,
                motionEnabled: false,
                readOnly: readOnly,
                layout: layout,
                seeds: const {'pine': 1},
                decorations: const [],
                focusPlantId: 'pine',
                plantFocusRequest: request,
                onMove: (_, __) async {},
                onMemory: (_) {},
                onPlant: () {},
                onDecorate: () {},
              ),
            ),
          ),
        );
        await t.pumpAndSettle();
      }

      await show(0);
      final camera = find.byKey(const Key('garden-world-camera'));
      final before = t
          .widget<InteractiveViewer>(camera)
          .transformationController!
          .value
          .clone();
      await show(1);
      final after = t
          .widget<InteractiveViewer>(camera)
          .transformationController!
          .value
          .clone();
      expect(after.storage[12], greaterThan(before.storage[12]));
      final point = MatrixUtils.transformPoint(
        after,
        const Offset(.36 * 2400, .55 * 800),
      );
      expect(point.dx, inInclusiveRange(0, t.getSize(camera).width));
      expect(layout.positions['seed:pine'], const Offset(.36, .55));
      expect(
        find.byKey(const ValueKey('plant-soil-seed:pine')),
        findsOneWidget,
      );
      await show(2, readOnly: true);
      expect(find.byKey(const ValueKey('plant-soil-seed:pine')), findsNothing);
      expect(find.byKey(const Key('plant-focus-backdrop')), findsNothing);
      expect(
        t.widget<InteractiveViewer>(camera).transformationController!.value,
        after,
      );
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'garden goals show growth and never offer public garden expansion',
    (t) async {
      Future<void> show(bool readOnly) async {
        await t.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GardenWorldView(
                immersive: true,
                motionEnabled: false,
                readOnly: readOnly,
                layout: GardenLayout(spaces: 2),
                seeds: const {'love': 3},
                decorations: const [],
                onMove: (_, __) async {},
                onMemory: (_) {},
                onPlant: () {},
                onDecorate: () {},
              ),
            ),
          ),
        );
        await t.pumpAndSettle();
      }

      await show(false);
      final goals = find.byKey(const Key('garden-growth-goals'));
      await t.ensureVisible(goals);
      await t.tap(goals);
      await t.pumpAndSettle();
      expect(find.text('다음 땅까지 성장 5회'), findsOneWidget);
      expect(find.text('작은 정원'), findsOneWidget);
      expect(find.text('꽃밭'), findsOneWidget);
      expect(find.text('나무 뜰'), findsOneWidget);
      await t.tap(find.text('꽃밭'));
      await t.pumpAndSettle();
      expect(find.text('다음 땅까지 성장 5회'), findsNothing);
      await show(true);
      expect(find.byKey(const Key('garden-growth-goals')), findsNothing);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    },
  );
  testWidgets('private cat care opens on tap; public cats cannot mutate care', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var calls = 0;
    Future<void> show(bool readOnly, double scale) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GardenWorldView(
              readOnly: readOnly,
              motionEnabled: false,
              companionScale: scale,
              onCompanionCare: () => calls++,
              layout: GardenLayout(spaces: 3),
              seeds: const {},
              decorations: const [],
              onMove: (_, __) async {},
              onMemory: (_) {},
              onPlant: () {},
              onDecorate: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await show(false, .82);
    final cat = find.byKey(const Key('garden-companion'));
    final small = tester.getRect(cat);
    await tester.tap(cat);
    expect(calls, 1);
    await show(false, 1);
    final grown = tester.getRect(cat);
    expect(grown.width, greaterThan(small.width));
    expect(grown.bottom, closeTo(small.bottom, .01));
    await show(true, 1);
    await tester.tap(cat);
    await tester.pump();
    expect(calls, 1);
    expect(tester.takeException(), isNull);
  });

  Future<void> showWorld(
    WidgetTester tester, {
    double width = 390,
    double height = 844,
    double scale = 1,
    bool reduced = true,
    bool motionEnabled = true,
    bool readOnly = false,
    VoidCallback? companionCare,
    double companionScale = 1,
    List<GardenReaction> reactions = const [],
    int publicMemoryStage = 0,
    bool publicCheerBed = false,
    int memoryDays = 0,
    int cheerFlowers = 0,
    VoidCallback? memoryTree,
    VoidCallback? flowers,
    Future<void> Function(String, Offset)? move,
    Future<bool> Function(String)? water,
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
                onCompanionCare: companionCare,
                companionScale: companionScale,
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
                onWater: water ?? (_) async => true,
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

  testWidgets(
    'resting the cat freezes the route and resumes at the same place',
    (tester) async {
      await showWorld(tester, reduced: false);
      await tester.tap(find.byTooltip('고양이 산책하기'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      // Measure the bottom-anchored foot point, not the top-left: resting
      // keeps a slight idle breathing scale that bulges upward from the
      // feet, so the top edge jitters by design while the feet stay put.
      final before = tester.getBottomLeft(find.byType(GardenCatPose));
      await tester.tap(find.byTooltip('고양이 앉아서 쉬기'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 8));
      expect(
        (tester.getBottomLeft(find.byType(GardenCatPose)) - before).distance,
        lessThan(.01),
      );
      expect(
        tester
            .widget<GardenBenchMoonlight>(find.byType(GardenBenchMoonlight))
            .seated,
        isFalse,
      );
      await tester.tap(find.byTooltip('고양이 산책하기'));
      await tester.pump();
      expect(
        (tester.getBottomLeft(find.byType(GardenCatPose)) - before).distance,
        lessThan(.01),
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

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
    // Default ground row y=.665: width=220*(.88+(.665-.52)*.55).
    final benchSize = tester.getSize(bench);
    expect(benchSize.width, closeTo(211.145, 0.01));
    expect(benchSize.height, closeTo(162.834, 0.01));
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
    expect(find.text('사랑에 물을 주었어요. 오늘의 돌봄을 기억할게요.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    expect(drops.progress.value, 1);
    await tester.tap(find.text('배치 모드'));
    await tester.pump();
    expect(find.text('물주기 마치기'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('failed watering does not show a saved growth or water effect', (
    tester,
  ) async {
    await showWorld(
      tester,
      water: (_) async => throw StateError('disk failure'),
    );
    await openTools(tester);
    await tester.tap(find.text('물 주기'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('world-item-seed:love')));
    await tester.pumpAndSettle();
    expect(find.text('물주기를 저장하지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
    expect(
      tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((w) => w.painter)
          .whereType<GardenWaterDrops>(),
      isEmpty,
    );
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
      expect(find.byKey(const Key('garden-memory-tree')), findsNothing);
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
    expect(find.byKey(const Key('garden-memory-tree')), findsNothing);
    for (final key in ['garden-cheer-flowers']) {
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
        // Screen/asset setup can take longer than one wall-clock second on CI.
        // The expired state is supplied explicitly on the rebuild below.
        GardenReaction('heart', DateTime.now().add(const Duration(hours: 1))),
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
