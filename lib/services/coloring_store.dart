import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ColoringStore {
  final String owner;
  ColoringStore(this.owner);
  String key(int design) => 'coloring_v1_${owner}_$design';
  Future<Map<String, dynamic>> load(int design) async {
    final raw = (await SharedPreferences.getInstance()).getString(key(design));
    if (raw == null)
      return {'colors': List<int?>.filled(12, null), 'complete': false};
    final data = Map<String, dynamic>.from(jsonDecode(raw));
    final c = data['colors'];
    if (c is! List ||
        c.length != 12 ||
        c.any((v) => v != null && (v is! int || v < 0 || v > 0xffffffff)))
      throw const FormatException('색칠 기록을 읽지 못했어요.');
    return data;
  }

  Future<Map<String, dynamic>?> gallery(int design) async {
    final raw = (await SharedPreferences.getInstance()).getString(
      '${key(design)}_finished',
    );
    return raw == null ? null : Map<String, dynamic>.from(jsonDecode(raw));
  }

  Future<void> save(
    int design,
    List<int?> colors, {
    bool complete = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (complete &&
        !await prefs.setString(
          '${key(design)}_finished',
          jsonEncode({'colors': colors, 'complete': true}),
        ))
      throw StateError('작품을 보관하지 못했어요.');
    if (!await prefs.setString(
      key(design),
      jsonEncode({'colors': colors, 'complete': complete}),
    ))
      throw StateError('저장하지 못했어요.');
  }
}
