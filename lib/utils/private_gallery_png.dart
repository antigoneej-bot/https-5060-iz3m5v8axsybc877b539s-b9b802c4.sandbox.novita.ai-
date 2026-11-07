import 'dart:ui' as ui;
import 'dart:typed_data';
import '../services/garden_personal_gallery_store.dart';

/// Resizes an owned image for bounded private storage. Caller disposes source.
Future<Uint8List> privateGalleryPng(ui.Image source) async {
  var scale =
      640 / (source.width > source.height ? source.width : source.height);
  if (scale > 1) scale = 1;
  for (var attempt = 0; attempt < 6; attempt++) {
    final w = (source.width * scale).round().clamp(1, 1600).toInt();
    final h = (source.height * scale).round().clamp(1, 1600).toInt();
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawImageRect(
      source,
      ui.Rect.fromLTWH(0, 0, source.width.toDouble(), source.height.toDouble()),
      ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
      ui.Paint()..filterQuality = ui.FilterQuality.medium,
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(w, h);
    picture.dispose();
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data != null &&
          data.lengthInBytes <= GardenPersonalGalleryStore.maxImageBytes) {
        return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      }
    } finally {
      image.dispose();
    }
    scale *= .75;
  }
  throw StateError('그림을 저장할 크기로 줄이지 못했어요.');
}
