import 'dart:convert';
import 'local_record_transaction.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/coloring_stroke.dart';

class BrushColoringStore {
  static final _queues = <String, LocalRecordQueue>{};
  LocalRecordQueue get _queue => _queues.putIfAbsent(key, LocalRecordQueue.new);
  final String owner;
  BrushColoringStore(this.owner);
  String get key => 'coloring_brush_v1_${owner}_love';
  Future<List<ColoringStroke>> load({bool finished = false}) =>
      _queue.run(() async {
        final raw = (await SharedPreferences.getInstance()).getString(
          '$key${finished ? '_finished' : ''}',
        );
        if (raw == null) return [];
        final data = jsonDecode(raw);
        if (data is! List || data.length > 5000)
          throw const FormatException('Invalid painting');
        return data
            .map((d) => ColoringStroke.fromJson(Map<String, dynamic>.from(d)))
            .toList();
      });

  Future<void> save(List<ColoringStroke> strokes, {bool finished = false}) {
    final snapshot = jsonEncode(strokes.map((s) => s.toJson()).toList());
    return _queue.run(() async {
      final prefs = await SharedPreferences.getInstance();
      if (!await prefs.setString(
        '$key${finished ? '_finished' : ''}',
        snapshot,
      )) {
        throw StateError('작품을 저장하지 못했어요.');
      }
    });
  }
}
