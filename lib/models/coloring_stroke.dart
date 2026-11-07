import 'package:flutter/material.dart';

const coloringBrushWidths = [4.0, 16.0, 40.0];
const coloringPalette = <Color>[
  Color(0xFFFFC6DA),
  Color(0xFFFFADC6),
  Color(0xFFE984A2),
  Color(0xFFC85B80),
  Color(0xFFFFDFCC),
  Color(0xFFFFC49B),
  Color(0xFFF6A66E),
  Color(0xFFE58057),
  Color(0xFFFFF3BE),
  Color(0xFFFFE18B),
  Color(0xFFF5C451),
  Color(0xFFD8A12E),
  Color(0xFFE4F2CF),
  Color(0xFFC0DFA5),
  Color(0xFF91BC7D),
  Color(0xFF5E8B62),
  Color(0xFFD8F5E7),
  Color(0xFFAFE2CF),
  Color(0xFF7BC4B3),
  Color(0xFF4A9C8E),
  Color(0xFFDAEFFA),
  Color(0xFFAED8F1),
  Color(0xFF7AB4D9),
  Color(0xFF507FAF),
  Color(0xFFE9E0F8),
  Color(0xFFCEBBED),
  Color(0xFFAB8DCE),
  Color(0xFF8063AA),
  Color(0xFFFFF8EA),
  Color(0xFFF3DFBF),
  Color(0xFFDFC29A),
  Color(0xFFC29A6B),
  Color(0xFFEBD5C9),
  Color(0xFFCDAA93),
  Color(0xFFA77B61),
  Color(0xFF765442),
  Color(0xFFFFFFFF),
  Color(0xFFE4E3E1),
  Color(0xFFB5B3B3),
  Color(0xFF85838A),
  Color(0xFF5A5862),
  Color(0xFF35343B),
  Color(0xFF242327),
  Color(0xFFE7B8B5),
  Color(0xFFDBE5B6),
  Color(0xFFB7D9E3),
  Color(0xFFE3C4DB),
  Color(0xFFF0D9A3),
];

class ColoringStroke {
  final int color;
  final int? region;
  final bool fill;
  final double width;
  final bool erase;
  final List<Offset> points;
  ColoringStroke(
    this.color,
    this.width,
    this.erase,
    this.points, {
    this.region,
    this.fill = false,
  });
  Map<String, dynamic> toJson() => {
    'color': color,
    if (region != null) 'region': region,
    if (fill) 'fill': true,
    'width': width,
    'erase': erase,
    'points': points.map((p) => [p.dx, p.dy]).toList(),
  };
  factory ColoringStroke.fromJson(Map<String, dynamic> d) {
    if (d['region'] != null && (d['region'] is! int || d['region'] <= 0) ||
        d['fill'] != null && d['fill'] is! bool)
      throw const FormatException('Invalid region');
    final c = d['color'], w = d['width'], p = d['points'];
    if (c is! int ||
        c < 0 ||
        c > 0xffffffff ||
        w is! num ||
        !coloringBrushWidths.contains(w.toDouble()) ||
        d['erase'] is! bool ||
        p is! List ||
        p.length > 20000) {
      throw const FormatException('Invalid coloring stroke');
    }
    final points = p.map<Offset>((v) {
      if (v is! List ||
          v.length != 2 ||
          v.any((n) => n is! num || !n.isFinite) ||
          v[0] < 0 ||
          v[0] > 1024 ||
          v[1] < 0 ||
          v[1] > 1536) {
        throw const FormatException('Invalid coloring point');
      }
      return Offset((v[0] as num).toDouble(), (v[1] as num).toDouble());
    }).toList();
    return ColoringStroke(
      c,
      w.toDouble(),
      d['erase'],
      points,
      region: d['region'] as int?,
      fill: d['fill'] == true,
    );
  }
}
