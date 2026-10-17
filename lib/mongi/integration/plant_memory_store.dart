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

  /// Compatibility entry point for older callers. A new scene appends to the
  /// timeline instead of silently replacing the earlier memory.
  Future<void> save(String plantId, String name, String note) =>
      _serial(() async {
        await _refresh();
        final previous = value[plantId];
        final entries = [...?previous?.timeline];
        final trimmed = note.trim();
        final now = DateTime.now();
        if (trimmed.isNotEmpty &&
            (entries.isEmpty || entries.last.note != trimmed)) {
          entries.add(
            PlantMemoryEntry(
              id: 'memory-${now.microsecondsSinceEpoch}',
              on: plantMemoryDay(now),
              note: trimmed,
            ),
          );
        }
        await _write(
          PlantMemory(
            plantId: plantId,
            name: name.trim(),
            note: entries.isEmpty ? '' : entries.last.note,
            updatedAt: now,
            anniversaryOn: previous?.anniversaryOn,
            entries: entries,
          ),
        );
      });

  Future<void> saveMemory(PlantMemory memory) => _serial(() => _write(memory));

  Future<void> _write(PlantMemory memory) async {
    final data = memory.toJson();
    PlantMemory.fromJson(data);
    final box = await HiveEncryption.openBox(boxName);
    await box.put(memory.plantId, data);
    await box.flush();
    await _refresh();
  }

  Future<void> remove(String plantId) => _serial(() async {
    final box = await HiveEncryption.openBox(boxName);
    await box.delete(plantId);
    await box.flush();
    await _refresh();
  });
}
