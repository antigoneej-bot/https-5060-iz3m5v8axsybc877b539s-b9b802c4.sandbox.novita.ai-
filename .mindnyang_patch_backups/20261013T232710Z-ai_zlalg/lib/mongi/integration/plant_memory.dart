import 'package:characters/characters.dart';
import '../models/seed.dart';

class PlantMemory {
  final String plantId;
  final String name;
  final String note;
  final DateTime updatedAt;
  const PlantMemory({
    required this.plantId,
    required this.name,
    required this.note,
    required this.updatedAt,
  });
  Map<String, dynamic> toJson() => {
    'plantId': plantId,
    'name': name,
    'note': note,
    'updatedAt': updatedAt.toIso8601String(),
  };
  factory PlantMemory.fromJson(Map<dynamic, dynamic> data) {
    final id = data['plantId'], name = data['name'], note = data['note'];
    final date = data['updatedAt'] is String
        ? DateTime.tryParse(data['updatedAt'])
        : null;
    if (id is! String ||
        !SeedType.all.any((s) => s.id == id) ||
        name is! String ||
        name.characters.length > 40 ||
        note is! String ||
        note.characters.length > 300 ||
        date == null) {
      throw const FormatException('식물의 추억 기록이 올바르지 않아요.');
    }
    return PlantMemory(plantId: id, name: name, note: note, updatedAt: date);
  }
}
