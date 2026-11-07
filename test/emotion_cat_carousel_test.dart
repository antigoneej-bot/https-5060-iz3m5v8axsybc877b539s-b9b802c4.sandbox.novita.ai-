import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_app/data/shadow_cats_data.dart';
import 'package:flutter_app/widgets/emotion_cat_carousel.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  final cats = shadowCats.where((cat) => cat.selectable).take(3).toList();
  Widget harness({
    required ValueChanged<String> select,
    ValueChanged<String>? favorite,
    double textScale = 1,
    bool fullCatalog = false,
  }) => MaterialApp(
    debugShowCheckedModeBanner: false,
    home: MediaQuery(
      data: MediaQueryData(
        disableAnimations: true,
        textScaler: TextScaler.linear(textScale),
      ),
      child: Scaffold(
        body: SingleChildScrollView(
          child: EmotionCatCarousel(
            cats: fullCatalog
                ? shadowCats.where((cat) => cat.selectable).toList()
                : cats,
            favorites: const {},
            onSelect: (cat) => select(cat.id),
            onFavorite: favorite ?? (_) {},
          ),
        ),
      ),
    ),
  );

  testWidgets('swipe browses without committing; button selects focused cat', (
    tester,
  ) async {
    String? selected;
    await tester.pumpWidget(harness(select: (id) => selected = id));
    await tester.pumpAndSettle();
    expect(find.text('1 / 3'), findsOneWidget);
    await tester.drag(
      find.byKey(const ValueKey('emotion-carousel-pages')),
      const Offset(-650, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('2 / 3'), findsOneWidget);
    expect(selected, isNull);
    await tester.ensureVisible(find.byKey(const ValueKey('confirm-emotion')));
    await tester.tap(find.byKey(const ValueKey('confirm-emotion')));
    expect(selected, cats[1].id);
  });

  testWidgets('arrows stop at boundaries and favorites target focused cat', (
    tester,
  ) async {
    String? favorite;
    await tester.pumpWidget(
      harness(select: (_) {}, favorite: (id) => favorite = id),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<IconButton>(
            find.widgetWithIcon(IconButton, Icons.chevron_left_rounded),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.byTooltip('다음 감정'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('즐겨찾기 추가'));
    expect(favorite, cats[1].id);
    await tester.tap(find.byTooltip('다음 감정'));
    await tester.pumpAndSettle();
    expect(find.text('3 / 3'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(
            find.widgetWithIcon(IconButton, Icons.chevron_right_rounded),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('small screen with large text has no overflow', (tester) async {
    tester.view.reset();
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(harness(select: (_) {}, textScale: 2));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('confirm-emotion')));
    expect(tester.takeException(), isNull);
  });
  testWidgets('capture carousel preview', (tester) async {
    const destination = String.fromEnvironment('CAROUSEL_CAPTURE_DIR');
    if (destination.isEmpty) return;
    tester.view.physicalSize = const Size(390, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final family in ['GowunDodum', 'GamjaFlower']) {
      final loader = FontLoader(family)
        ..addFont(rootBundle.load('assets/fonts/$family-Regular.ttf'));
      await loader.load();
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: harness(select: (_) {}, fullCatalog: true),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final image =
          await (key.currentContext!.findRenderObject()
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory(destination).create(recursive: true);
      await File(
        '$destination/Mindnyang-Emotion-Carousel-v45.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  });
}
