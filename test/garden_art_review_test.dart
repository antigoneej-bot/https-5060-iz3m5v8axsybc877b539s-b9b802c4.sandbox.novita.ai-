import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/mongi/models/seed.dart';
import 'package:flutter_app/mongi/widgets/living_garden_scene.dart';

void main() {
  testWidgets('plant species and all growth stages render without exceptions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 650);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RepaintBoundary(
            key: key,
            child: ColoredBox(
              color: const Color(0xFFF9F3E8),
              child: Column(
                children: [
                  for (final count in [1, 3, 6, 10])
                    Expanded(
                      child: Row(
                        children: [
                          for (final seed in SeedType.all)
                            Expanded(
                              child: Column(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      width: 110,
                                      child: GardenPlantArt(
                                        seed: seed,
                                        count: count,
                                      ),
                                    ),
                                  ),
                                  Text('${seed.id} / $count'),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    if (Platform.environment['GARDEN_ART_CAPTURE'] == '1') {
      await tester.runAsync(() async {
        final image =
            await (key.currentContext!.findRenderObject()
                    as RenderRepaintBoundary)
                .toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '/tmp/garden-plants-review.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
  });
}
