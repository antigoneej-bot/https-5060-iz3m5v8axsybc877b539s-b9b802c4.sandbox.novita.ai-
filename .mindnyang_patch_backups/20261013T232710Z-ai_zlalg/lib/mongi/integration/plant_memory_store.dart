import 'package:flutter/foundation.dart';
import '../../services/hive_encryption.dart';
import 'plant_memory.dart';
export 'plant_memory.dart';

/// Written memories use the same encrypted storage as the private journal.
class PlantMemoryStore extends ValueNotifier<Map<String, PlantMemory>> {
  static final instance = PlantMemoryStore._();
  static const boxName = 'garden_memories_local_user';
  PlantMemoryStore._() : super(const {});
  Future<void> _tail = Future.value();
  Future<void> _serial(Future<void> Function() action) {
    final result = _tail.then((_) => action());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  Future<void> _refresh() async {
    final box = await HiveEncryption.openBox(boxName);
    final memories = <String, PlantMemory>{};
    for (final key in box.keys) {
      final memory = PlantMemory.fromJson(
        Map<dynamic, dynamic>.from(box.get(key) as Map),
      );
      if (key != memory.plantId) {
        throw const FormatException('식물 기록이 일치하지 않아요.');
      }
      memories[memory.plantId] = memory;
    }
    value = Map.unmodifiable(memories);
  }

  Future<void> reload() => _serial(_refresh);
  Future<void> save(String plantId, String name, String note) =>
      _serial(() async {
        final data = PlantMemory(
          plantId: plantId,
          name: name.trim(),
          note: note.trim(),
          updatedAt: DateTime.now(),
        ).toJson();
        PlantMemory.fromJson(data);
        final box = await HiveEncryption.openBox(boxName);
        await box.put(plantId, data);
        await box.flush();
        await _refresh();
      });
  Future<void> remove(String plantId) => _serial(() async {
    final box = await HiveEncryption.openBox(boxName);
    await box.delete(plantId);
    await box.flush();
    await _refresh();
  });
}
