import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_app/theme.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/mongi/models/garden_layout.dart';
import 'package:flutter_app/mongi/widgets/garden_world_view.dart';

Rect screenRect(WidgetTester tester, Finder finder) {
  final box = tester.renderObject<RenderBox>(finder);
  return MatrixUtils.transformRect(
    box.getTransformTo(null),
    Offset.zero & box.size,
  );
}

void main() {
  final boundary = GlobalKey();
  Widget world(bool fill, {bool immersive = false}) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: appTheme,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true),
      child: child!,
    ),
    home: Scaffold(
      appBar: immersive
          ? null
          : AppBar(title: const Text('고양이 정원'), toolbarHeight: 48),
      body: RepaintBoundary(
        key: boundary,
        child: ColoredBox(
          color: AppColors.bg0,
          child: GardenWorldView(
            fillViewport: fill,
            immersive: immersive,
            motionEnabled: false,
            layout: GardenLayout(spaces: 3),
            seeds: const {'love': 3, 'peace': 8},
            decorations: const ['bench'],
            onMove: (_, __) async {},
            onMemory: (_) {},
            onPlant: () {},
            onDecorate: () {},
            onOrchard: () {},
          ),
        ),
      ),
    ),
  );
  for (final size in [
    const Size(320, 640),
    const Size(390, 844),
    const Size(844, 390),
  ]) {
    testWidgets(
      'fills available phone canvas and keeps cat feet visible at $size',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(world(true));
        await tester.pumpAndSettle();
        final view = screenRect(
          tester,
          find.byKey(const Key('garden-world-camera')),
        );
        final cat = screenRect(
          tester,
          find.byKey(const Key('garden-companion')),
        );
        expect(view.width, closeTo(size.width, 1));
        expect(view.height, greaterThan(size.height * .65));
        expect(cat.top, greaterThanOrEqualTo(view.top));
        expect(cat.bottom, lessThanOrEqualTo(view.bottom));
        expect(tester.takeException(), isNull);
        await tester.tap(find.byKey(const Key('garden-show-all')));
        await tester.pumpAndSettle();
        final viewer = tester.widget<InteractiveViewer>(
          find.byType(InteractiveViewer),
        );
        final ground = screenRect(
          tester,
          find.byKey(const Key('garden-world-ground')),
        );
        final overview = screenRect(
          tester,
          find.byKey(const Key('garden-world-camera')),
        );
        expect(ground.width, closeTo(overview.width, 1));
        expect(ground.height, closeTo(overview.height, 1));
        expect(viewer.minScale, greaterThan(0));
        await tester.tap(find.byKey(const Key('garden-show-cat')));
        await tester.pumpAndSettle();
        expect(
          screenRect(
            tester,
            find.byKey(const Key('garden-world-camera')),
          ).height,
          closeTo(view.height, 1),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('portrait cat is larger than former fixed-aspect view', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(world(false));
    await tester.pumpAndSettle();
    final oldSize = screenRect(
      tester,
      find.byKey(const Key('garden-companion')),
    ).width;
    await tester.pumpWidget(world(true));
    await tester.pumpAndSettle();
    // RenderBox size is world-space; compare transformed screen rectangles.
    final view = screenRect(
      tester,
      find.byKey(const Key('garden-world-camera')),
    );
    expect(view.height, greaterThan(600));
    expect(
      screenRect(tester, find.byKey(const Key('garden-companion'))).width,
      greaterThan(oldSize * 1.7),
    );
    await tester.tap(find.byKey(const Key('garden-toggle-tools')));
    await tester.pumpAndSettle();
    expect(find.byTooltip('정원 확대'), findsOneWidget);
    await tester.tap(find.text('돌보기 · 꾸미기 · 추억'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('배치 모드'));
    await tester.tap(find.text('배치 모드'));
    await tester.pumpAndSettle();
    expect(find.text('배치 완료'), findsOneWidget);

    await tester.tap(find.byKey(const Key('garden-toggle-tools')));
    await tester.pumpAndSettle();
    expect(find.byTooltip('정원 확대'), findsNothing);
    await tester.tap(find.byKey(const Key('garden-toggle-tools')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('돌보기 · 꾸미기 · 추억'));
    await tester.pumpAndSettle();
    expect(find.text('배치 모드'), findsOneWidget);
    expect(find.text('배치 완료'), findsNothing);

    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'immersive entry ends hidden editing and fills the entire landscape',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(world(true));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('garden-toggle-tools')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('돌보기 · 꾸미기 · 추억'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('배치 모드'));
      await tester.tap(find.text('배치 모드'));
      await tester.pumpAndSettle();
      expect(find.text('배치 완료'), findsOneWidget);
      tester.view.physicalSize = const Size(844, 390);
      await tester.pumpWidget(world(true, immersive: true));
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.byKey(const Key('garden-canvas'))),
        const Rect.fromLTWH(0, 0, 844, 390),
      );
      tester.view.physicalSize = const Size(390, 844);
      await tester.pumpWidget(world(true));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('garden-toggle-tools')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('돌보기 · 꾸미기 · 추억'));
      await tester.pumpAndSettle();
      expect(find.text('배치 완료'), findsNothing);
      expect(find.text('배치 모드'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('landscape garden retains tools and full canvas', (tester) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(world(true, immersive: true));
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.byKey(const Key('garden-canvas'))),
      const Rect.fromLTWH(0, 0, 844, 390),
    );
    expect(find.byTooltip('보기 설정'), findsOneWidget);
    final compactButton = tester.getSize(find.byKey(const ValueKey('storybook-plant')));
    expect(compactButton.height, inInclusiveRange(48, 58));
    expect(compactButton.width, lessThanOrEqualTo(90));
    await tester.tap(find.byKey(const ValueKey('storybook-decorate')));
    await tester.pumpAndSettle();
    expect(find.text('물 주기'), findsOneWidget);
    expect(find.text('씨앗 심기'), findsNWidgets(2));
    expect(find.text('장식'), findsOneWidget);
    await tester.ensureVisible(find.text('물 주기'));
    await tester.tap(find.text('물 주기'));
    await tester.pumpAndSettle();
    expect(find.text('물주기 마치기'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const ValueKey('storybook-decorate')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('storybook-backdrop')), findsOneWidget);
    expect(find.byKey(const Key('storybook-foreground')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('storybook-water')));
    await tester.pumpAndSettle();
    const dest = String.fromEnvironment('GARDEN57_CAPTURE');
    if (dest.isNotEmpty) {
      final providers = tester.widgetList<Image>(find.byType(Image)).map((w) => w.image).toList();
      await tester.runAsync(() async {
        for (final provider in providers) { await precacheImage(provider, boundary.currentContext!); }
      });
      await tester.pumpAndSettle();
      for (final family in ['GowunDodum', 'GamjaFlower']) {
        final font = FontLoader(family)
          ..addFont(rootBundle.load('assets/fonts/$family-Regular.ttf'));
        await tester.runAsync(font.load);
      }
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await tester.runAsync(icons.load);
      await tester.pump();
      await tester.runAsync(() async {
        final image =
            await (boundary.currentContext!.findRenderObject()
                    as RenderRepaintBoundary)
                .toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(dest).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
  });
  testWidgets('capture full phone garden', (tester) async {
    const dest = String.fromEnvironment('GARDEN_FULL_CAPTURE_DIR');
    if (dest.isEmpty) return;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final family in ['GowunDodum', 'GamjaFlower']) {
      await (FontLoader(
        family,
      )..addFont(rootBundle.load('assets/fonts/$family-Regular.ttf'))).load();
    }
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await tester.pumpWidget(world(true));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      for (final image in tester.widgetList<Image>(find.byType(Image))) {
        await precacheImage(image.image, boundary.currentContext!);
      }
    });
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final image =
          await (boundary.currentContext!.findRenderObject()
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(
        '$dest/Mindnyang-Garden-Fullscreen-v46.png',
      ).writeAsBytes(data!.buffer.asUint8List());
      image.dispose();
    });
  });
}
