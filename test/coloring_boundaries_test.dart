import 'dart:typed_data';
import 'package:flutter_app/utils/welcome_policy.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/models/coloring_boundaries.dart';
import 'package:flutter_app/models/coloring_stroke.dart';
import 'package:flutter_app/screens/coloring_healing_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'test welcome replays once per session without changing production completion',
    () {
      expect(
        shouldShowWelcome(
          completed: true,
          testReplay: true,
          shownThisSession: false,
        ),
        true,
      );
      expect(
        shouldShowWelcome(
          completed: true,
          testReplay: true,
          shownThisSession: true,
        ),
        false,
      );
      expect(
        shouldShowWelcome(
          completed: true,
          testReplay: false,
          shownThisSession: false,
        ),
        false,
      );
      expect(
        shouldShowWelcome(
          completed: false,
          testReplay: false,
          shownThisSession: false,
        ),
        true,
      );
    },
  );
  test(
    'separate regions clip brush, fill and eraser and survive serialization',
    () async {
      const w = 20, h = 30;
      final rgba = Uint8List(w * h * 4)..fillRange(0, w * h * 4, 255);
      for (var y = 0; y < h; y++)
        for (var k = 0; k < 3; k++) rgba[(y * w + 10) * 4 + k] = 0;
      final labels = labelColoringRegions({
        'rgba': rgba,
        'width': w,
        'height': h,
      });
      final boundaries = ColoringBoundaries(labels, w, h);
      final left = boundaries.regionAt(const Offset(100, 400)),
          right = boundaries.regionAt(const Offset(900, 400));
      expect(left, isPositive);
      expect(right, isNot(left));
      expect(boundaries.regionAt(const Offset(512, 400)), 0);
      final stroke = ColoringStroke(0xffff0000, 40, false, [
        const Offset(100, 400),
        const Offset(900, 400),
      ], region: left);
      expect(ColoringStroke.fromJson(stroke.toJson()).region, left);
      Future<List<int>> pixel(
        List<ColoringStroke> strokes,
        int x,
        int y,
      ) async {
        final recorder = ui.PictureRecorder();
        BrushColoringPainter(
          null,
          strokes,
          boundaries: boundaries,
        ).paint(Canvas(recorder), const Size(1024, 1536));
        final picture = recorder.endRecording(),
            image = await picture.toImage(1024, 1536);
        final bytes = (await image.toByteData())!.buffer.asUint8List();
        final result = bytes.sublist(
          (y * 1024 + x) * 4,
          (y * 1024 + x) * 4 + 4,
        );
        image.dispose();
        picture.dispose();
        return result;
      }

      expect(await pixel([stroke], 900, 400), [255, 255, 255, 255]);
      expect(await pixel([stroke], 100, 400), [255, 0, 0, 255]);
      final fill = ColoringStroke(
        0xffff0000,
        16,
        false,
        [const Offset(100, 400)],
        region: left,
        fill: true,
      );
      expect(await pixel([fill], 100, 100), [255, 0, 0, 255]);
      expect(await pixel([fill], 900, 100), [255, 255, 255, 255]);
      final erase = ColoringStroke(0, 40, true, [
        const Offset(100, 400),
        const Offset(900, 400),
      ], region: right);
      expect(await pixel([fill, erase], 100, 400), [255, 0, 0, 255]);
    },
  );
}
