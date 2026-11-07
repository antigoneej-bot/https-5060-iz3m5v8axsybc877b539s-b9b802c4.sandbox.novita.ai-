import 'dart:typed_data';
import 'dart:ui';

/// Deterministic connected regions from the original line art. A one-pixel
/// barrier expansion closes antialias gaps without modifying the illustration.
Int32List labelColoringRegions(Map<String, dynamic> input) {
  final bytes = input['rgba'] as Uint8List;
  final w = input['width'] as int, h = input['height'] as int;
  final barrier = Uint8List(w * h),
      labels = Int32List(w * h),
      queue = Int32List(w * h);
  for (var y = 0; y < h; y++)
    for (var x = 0; x < w; x++) {
      final i = (y * w + x) * 4;
      if (bytes[i] < 195 &&
          bytes[i + 1] < 195 &&
          bytes[i + 2] < 195 &&
          bytes[i + 3] > 128) {
        for (var dy = -1; dy <= 1; dy++)
          for (var dx = -1; dx <= 1; dx++) {
            final a = x + dx, b = y + dy;
            if (a >= 0 && a < w && b >= 0 && b < h) barrier[b * w + a] = 1;
          }
      }
    }
  var id = 0;
  for (var i = 0; i < w * h; i++) {
    if (barrier[i] != 0 || labels[i] != 0) continue;
    id++;
    var head = 0, tail = 0;
    queue[tail++] = i;
    labels[i] = id;
    while (head < tail) {
      final p = queue[head++], x = p % w;
      void visit(int n) {
        if (barrier[n] == 0 && labels[n] == 0) {
          labels[n] = id;
          queue[tail++] = n;
        }
      }

      if (x > 0) visit(p - 1);
      if (x < w - 1) visit(p + 1);
      if (p >= w) visit(p - w);
      if (p < w * (h - 1)) visit(p + w);
    }
  }
  return labels;
}

class ColoringBoundaries {
  final Int32List labels;
  final int width, height;
  final _paths = <int, Path>{};
  ColoringBoundaries(this.labels, this.width, this.height);
  int regionAt(Offset p) {
    final x = (p.dx / 1024 * width).floor(), y = (p.dy / 1536 * height).floor();
    if (x < 0 || y < 0 || x >= width || y >= height) return 0;
    return labels[y * width + x];
  }

  Path path(int id) => _paths.putIfAbsent(id, () {
    final path = Path();
    if (id <= 0) return path;
    for (var y = 0; y < height; y++) {
      var x = 0;
      while (x < width) {
        if (labels[y * width + x] != id) {
          x++;
          continue;
        }
        final start = x;
        while (x < width && labels[y * width + x] == id) {
          x++;
        }
        path.addRect(
          Rect.fromLTRB(
            start * 1024 / width,
            y * 1536 / height,
            x * 1024 / width,
            (y + 1) * 1536 / height,
          ),
        );
      }
    }
    return path;
  });
}
