import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/theme.dart';
import 'package:flutter_app/mongi/widgets/living_garden_scene.dart';
import 'package:flutter_app/mongi/widgets/garden_plant_picker.dart';
import 'package:flutter_app/mongi/models/seed.dart';

void main() {
  final shot = GlobalKey();
  setUpAll(() async {
    for (final e in {
      'GowunDodum': 'assets/fonts/GowunDodum-Regular.ttf',
      'GamjaFlower': 'assets/fonts/GamjaFlower-Regular.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
    }.entries) {
      await (FontLoader(e.key)..addFont(rootBundle.load(e.value))).load();
    }
  });
  Future<void> show(
    WidgetTester t, {
    int tokens = 1,
    Map<String, int> seeds = const {},
    Future<void> Function(SeedType)? plant,
    ValueChanged<SeedType>? locate,
    ValueChanged<SeedType>? care,
    double textScale = 1,
    bool chooseLocation = false,
  }) async {
    await t.pumpWidget(
      MaterialApp(
        theme: appTheme,
        home: MediaQuery(
          data: MediaQueryData(
            size: const Size(390, 844),
            textScaler: TextScaler.linear(textScale),
          ),
          child: Scaffold(
            body: RepaintBoundary(
              key: shot,
              child: Material(
                color: appTheme.scaffoldBackgroundColor,
                child: GardenPlantPicker(
                  tokens: tokens,
                  seeds: seeds,
                  onPlant: plant ?? (_) async {},
                  onLocate: locate ?? (_) {},
                  onCare: care ?? (_) {},
                  chooseLocation: chooseLocation,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
  }

  testWidgets('all six illustrated plants can be browsed left and right', (
    t,
  ) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await show(t);
    for (var i = 0; i < SeedType.all.length; i++) {
      expect(find.text('${i + 1} / 6'), findsOneWidget);
      expect(find.text('${SeedType.all[i].label} 심기 · 씨앗 1개'), findsOneWidget);
      final out = Platform.environment['PLANT_PICKER_REVIEW_DIR'];
      if (out != null) {
        await t.runAsync(() async {
          await precacheImage(
            const AssetImage('assets/living_garden/plants.webp'),
            shot.currentContext!,
          );
        });
        await t.pumpAndSettle();
        await t.runAsync(() async {
          final image =
              await (shot.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary)
                  .toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File(
            '$out/plant-${SeedType.all[i].id}.png',
          ).writeAsBytesSync(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      if (i < 5) {
        await t.drag(
          find.byKey(const Key('plant-carousel')),
          const Offset(-250, 0),
        );
        await t.pumpAndSettle();
      }
    }
    await t.tap(find.byTooltip('이전 식물'));
    await t.pumpAndSettle();
    expect(find.text('5 / 6'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
  testWidgets('existing pine offers location and care without replanting', (
    t,
  ) async {
    String? located, cared;
    var plants = 0;
    await show(
      t,
      tokens: 0,
      seeds: const {'pine': 4},
      locate: (s) => located = s.id,
      care: (s) => cared = s.id,
      plant: (_) async {
        plants++;
      },
    );
    expect(find.byKey(const Key('plant-selected')), findsNothing);
    await t.tap(find.byKey(const Key('locate-plant')));
    await t.tap(find.text('돌보기'));
    expect(located, 'pine');
    expect(cared, 'pine');
    expect(plants, 0);
  });
  testWidgets(
    'cultivation separates unplanted previews from actual saved growth',
    (t) async {
      await show(t, seeds: const {'pine': 4}, chooseLocation: true);
      expect(find.text('벚꽃나무 심을 자리 고르기'), findsOneWidget);
      expect(find.text('다 자란 모습 미리보기'), findsWidgets);
      await t.tap(find.text('이미 심은 식물'));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('locate-plant')), findsOneWidget);
      final art = t.widgetList<GardenPlantArt>(find.byType(GardenPlantArt));
      expect(art.every((a) => a.seed.id == 'pine' && a.count == 4), isTrue);
      await show(
        t,
        seeds: {for (final s in SeedType.all) s.id: 1},
        chooseLocation: true,
      );
      await t.tap(find.text('심을 수 있는 씨앗'));
      await t.pumpAndSettle();
      expect(find.textContaining('모든 종류를 심었어요'), findsOneWidget);
    },
  );
  testWidgets(
    'no tokens cannot plant; pending write cannot be sent twice; failure retries',
    (t) async {
      await show(t, tokens: 0);
      expect(
        t
            .widget<FilledButton>(find.byKey(const Key('plant-selected')))
            .onPressed,
        isNull,
      );
      final pending = Completer<void>();
      var attempts = 0;
      await show(
        t,
        plant: (_) {
          attempts++;
          return pending.future;
        },
      );
      await t.tap(find.byKey(const Key('plant-selected')));
      await t.pump();
      await t.tap(find.byKey(const Key('plant-selected')));
      expect(attempts, 1);
      pending.completeError(StateError('write failed'));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('plant-error')), findsOneWidget);
      expect(
        t
            .widget<FilledButton>(find.byKey(const Key('plant-selected')))
            .onPressed,
        isNotNull,
      );
    },
  );
  testWidgets('large text and landscape selection stay scrollable', (t) async {
    t.view.physicalSize = const Size(844, 390);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await show(t, textScale: 2);
    await t.ensureVisible(find.byKey(const Key('plant-selected')));
    expect(t.takeException(), isNull);
  });
}
