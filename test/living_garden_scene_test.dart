import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/mongi/widgets/garden_ambient.dart';
import 'package:flutter_app/mongi/widgets/living_garden_scene.dart';

void main() {
  Future<void> showScene(
    WidgetTester tester, {
    double width = 390,
    double scale = 1,
    bool reduced = true,
    String companionName = '고양이',
    VoidCallback? write,
    VoidCallback? garden,
    VoidCallback? neighbors,
  }) async {
    tester.view.physicalSize = Size(width, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: MediaQueryData(
              size: Size(width, 1100),
              disableAnimations: reduced,
              textScaler: TextScaler.linear(scale),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: RepaintBoundary(
                  key: const Key('garden-preview'),
                  child: LivingGardenScene(
                    companionName: companionName,
                    seeds: const {'love': 3, 'peace': 10},
                    onWrite: write,
                    onGarden: garden,
                    onNeighbors: neighbors,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'three entrances dispatch their own action and real seeds render',
    (tester) async {
      var writes = 0, gardens = 0, neighbors = 0;
      await showScene(
        tester,
        write: () => writes++,
        garden: () => gardens++,
        neighbors: () => neighbors++,
      );
      for (final title in ['마음 남기기', '정원 가꾸기', '이웃 정원']) {
        await tester.tap(find.text(title));
        await tester.pump();
      }
      expect([writes, gardens, neighbors], [1, 1, 1]);
      expect(find.text('2가지 마음이 정원에서 자라고 있어요'), findsOneWidget);
      expect(find.byTooltip('사랑 · 성장 2단계'), findsOneWidget);
      expect(find.byTooltip('평안 · 성장 4단계'), findsOneWidget);
      expect(find.byTooltip('고양이를 쓰다듬어 보세요'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('small display and large text fit, reduced motion stays idle', (
    tester,
  ) async {
    await showScene(
      tester,
      width: 320,
      scale: 1.8,
      companionName: '밤',
      write: () {},
      garden: () {},
      neighbors: () {},
    );
    expect(tester.takeException(), isNull);
    expect(tester.binding.transientCallbackCount, 0);
    await tester.tap(find.byKey(const Key('living-cat')));
    await tester.pump();
    // The companion uses the user's chosen name, including its Korean particle.
    expect(find.text('밤이 손에 살며시 기대어요.'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('day and night are user-controlled without changing seed data', (
    tester,
  ) async {
    await showScene(tester);
    await tester.tap(find.byIcon(Icons.wb_twilight));
    await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Image &&
            w.image is AssetImage &&
            (w.image as AssetImage).assetName ==
                'assets/living_garden/day.webp',
      ),
      findsOneWidget,
    );
    await tester.tap(find.byIcon(Icons.wb_twilight));
    await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Image &&
            w.image is AssetImage &&
            (w.image as AssetImage).assetName ==
                'assets/living_garden/night.webp',
      ),
      findsOneWidget,
    );
    expect(find.text('2가지 마음이 정원에서 자라고 있어요'), findsOneWidget);
  });

  testWidgets(
    'wind starts only on request; pause keeps idle blinking and disposes cleanly',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: LivingGardenScene())),
      );
      double windPhase() => tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((widget) => widget.painter)
          .whereType<GardenAtmosphere>()
          .single
          .phase;
      Finder motionButton(String label) => find.byWidgetPredicate(
        (widget) => widget is IconButton && widget.tooltip == label,
      );
      final blink = tester
          .widget<GardenCatArt>(find.byType(GardenCatArt))
          .animation;
      expect(motionButton('바람과 물레방아 움직임 켜기'), findsOneWidget);
      expect(windPhase(), 0);
      final initialBlink = blink.value;
      await tester.pump(const Duration(seconds: 1));
      expect(windPhase(), 0);
      expect(blink.value, isNot(initialBlink));

      await tester.tap(motionButton('바람과 물레방아 움직임 켜기'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(windPhase(), greaterThan(0));
      expect(motionButton('바람과 물레방아 움직임 쉬기'), findsOneWidget);
      await tester.tap(motionButton('바람과 물레방아 움직임 쉬기'));
      await tester.pump();
      final pausedWind = windPhase(), pausedBlink = blink.value;
      await tester.pump(const Duration(seconds: 1));
      expect(windPhase(), pausedWind);
      expect(blink.value, isNot(pausedBlink));

      // Backgrounding suspends the remaining idle blink as well.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      final backgroundBlink = blink.value;
      await tester.pump(const Duration(seconds: 1));
      expect(blink.value, backgroundBlink);
      expect(tester.binding.transientCallbackCount, 0);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(windPhase(), pausedWind);
      expect(blink.value, isNot(backgroundBlink));
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(minutes: 2));
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.takeException(), isNull);
    },
  );

  if (const bool.fromEnvironment('GARDEN_GOLDENS')) {
    testWidgets('render garden day and night previews', (tester) async {
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
      for (final name in ['GowunDodum', 'GamjaFlower']) {
        final loader = FontLoader(name)
          ..addFont(rootBundle.load('assets/fonts/$name-Regular.ttf'));
        await loader.load();
      }
      await showScene(tester, write: () {}, garden: () {}, neighbors: () {});
      await tester.tap(find.byIcon(Icons.wb_twilight));
      await tester.pumpAndSettle();
      await expectLater(
        find.byKey(const Key('garden-preview')),
        matchesGoldenFile('../docs/living-garden-day.png'),
      );
      await tester.tap(find.byIcon(Icons.wb_twilight));
      await tester.pumpAndSettle();
      await expectLater(
        find.byKey(const Key('garden-preview')),
        matchesGoldenFile('../docs/living-garden-night.png'),
      );
    });
  }
}
