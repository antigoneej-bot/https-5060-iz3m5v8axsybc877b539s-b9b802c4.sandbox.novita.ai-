import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/data/shadow_cats_data.dart';
import 'package:flutter_app/widgets/emotion_cat_thumbnail.dart';

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    for (final name in ['GowunDodum', 'GamjaFlower']) {
      await (FontLoader(
        name,
      )..addFont(rootBundle.load('assets/fonts/$name-Regular.ttf'))).load();
    }
  });
  testWidgets(
    'all 37 saved emotion assets have non-distorting calendar framing',
    (t) async {
      t.view.physicalSize = const Size(1050, 1000);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final shot = GlobalKey();
      await t.pumpWidget(
        MaterialApp(
          theme: appTheme,
          home: RepaintBoundary(
            key: shot,
            child: Scaffold(
              backgroundColor: const Color(0xFFFFFAF0),
              body: GridView.count(
                crossAxisCount: 7,
                childAspectRatio: .9,
                children: [
                  for (final cat in shadowCats)
                    Column(
                      children: [
                        Expanded(
                          child: EmotionCatThumbnail(
                            asset: cat.imageAsset,
                            label: cat.nameKr,
                          ),
                        ),
                        Text(cat.nameKr, style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      );
      await t.runAsync(() async {
        for (final cat in shadowCats) {
          await precacheImage(AssetImage(cat.imageAsset), shot.currentContext!);
        }
      });
      await t.pumpAndSettle();
      expect(shadowCats.length, 37);
      expect(EmotionCatThumbnail.subjects.length, 37);
      for (final cat in shadowCats) {
        final rect =
            EmotionCatThumbnail.subjects[cat.imageAsset.split('/').last];
        expect(rect, isNotNull, reason: cat.id);
        expect(rect!.left, greaterThanOrEqualTo(0));
        expect(rect.top, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(1));
        expect(rect.bottom, lessThanOrEqualTo(1));
        expect(rect.width, greaterThan(0));
        expect(rect.height, greaterThan(0));
      }
      final out = const String.fromEnvironment('USABILITY_CAPTURE');
      if (out.isNotEmpty) {
        await t.runAsync(() async {
          final image =
              await (shot.currentContext!.findRenderObject()
                      as RenderRepaintBoundary)
                  .toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(
            '$out/78-emotion-cats-37-framing.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    },
  );
}
