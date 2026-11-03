import 'package:flutter/foundation.dart';
import 'package:characters/characters.dart';
import '../../services/hive_encryption.dart';
import '../../services/garden_memory_book_store.dart';
import '../../services/local_record_transaction.dart';
import '../../services/private_letter_memory_source.dart';
import 'mongi_garden_store.dart';
import 'plant_memory.dart';
export 'plant_memory.dart';

/// Written memories use the same encrypted storage as the private journal.
class PlantMemoryStore extends ValueNotifier<Map<String, PlantMemory>> {
  static final instance = PlantMemoryStore._();
  static const boxName = 'garden_memories_local_user';
  PlantMemoryStore._() : super(const {});
  final _queue = LocalRecordQueue();
  Future<void> _serial(Future<void> Function() action) =>
      LocalRecordTransaction.atomic(() => _queued(action));

  Future<void> _queued(Future<void> Function() action) => _queue.run(action);

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

  Future<void> reload() => _serial(() async { await _pruneDiaryLinks(); await _refresh(); });

  Future<void> _pruneDiaryLinks() async {
    await _refresh();
    final ids = <String>{for (final memory in value.values) for (final entry in memory.timeline)
      if (entry.sourceLetterId?.startsWith('garden-diary:') == true) entry.sourceLetterId!};
    for (final id in ids) {
      final source = await PrivateLetterMemorySource.find(id);
      final linked = value.values.expand((m) => m.timeline).where((e) => e.sourceLetterId == id);
      if (source == null || linked.any((e) => !source.text.contains(e.note) || !source.writtenAt.isAtSameMomentAs(e.sourceWrittenAt!))) {
        await GardenMemoryBookStore.instance.removeForLetter(id);
        await _scrubLetter(id);
      }
    }
  }

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

  Future<void> saveMemory(
    PlantMemory memory, {
    bool checkRevision = false,
    DateTime? expectedUpdatedAt,
  }) => _serial(() async {
    if (checkRevision) {
      await _refresh();
      await MongiGardenStore.instance.reload();
      if ((MongiGardenStore.instance.value.seeds[memory.plantId] ?? 0) <= 0 ||
          value[memory.plantId]?.updatedAt != expectedUpdatedAt) {
        throw StateError('나무나 추억이 변경되었어요. 닫은 뒤 다시 열어 주세요.');
      }
    }
    await _write(memory);
  });

  Future<void> deletePlant(String plantId) => MongiGardenStore.instance
      .removePlant(plantId, removeMemories: () => remove(plantId));

  Future<void> _write(PlantMemory memory) async {
    final data = memory.toJson();
    PlantMemory.fromJson(data);
    for (final entry in memory.timeline) {
      if (entry.sourceLetterId == null) continue;
      final source = await PrivateLetterMemorySource.find(
        entry.sourceLetterId!,
      );
      if (source == null ||
          !source.writtenAt.isAtSameMomentAs(entry.sourceWrittenAt!) ||
          !source.text.contains(entry.note)) {
        throw const FormatException('편지가 변경되었어요. 나무에 남길 문장을 다시 골라 주세요.');
      }
    }
    final box = await HiveEncryption.openBox(boxName);
    LocalRecordTransaction.capture(box, afterRollback: _refresh);
    await box.put(memory.plantId, data);
    await box.flush();
    await _refresh();
  }

  Future<void> remove(String plantId) =>
      GardenMemoryBookStore.instance.removePlantSource(
        plantId,
        () => _serial(() async {
          final box = await HiveEncryption.openBox(boxName);
          LocalRecordTransaction.capture(box, afterRollback: _refresh);
          await box.delete(plantId);
          await box.flush();
          await _refresh();
        }),
      );

  /// Links only a real saved sentence, and only to a plant the owner has grown.
  /// Identical retries are a no-op; a network-style double tap cannot append
  /// copies of the same private quote. No text is sent to neighbor gardens.
  Future<void> attachLetterQuote({
    required String plantId,
    required String sourceLetterId,
    required String quote,
  }) => _serial(() async {
    await _refresh();
    await MongiGardenStore.instance.reload();
    if ((MongiGardenStore.instance.value.seeds[plantId] ?? 0) <= 0) {
      throw const FormatException('내 정원에 심은 식물을 골라 주세요.');
    }
    final source = await PrivateLetterMemorySource.find(sourceLetterId);
    if (source == null ||
        quote.trim().isEmpty ||
        quote.characters.length > 300 ||
        !source.text.contains(quote)) {
      throw const FormatException('편지 원문에서 300자 이내의 문장을 골라 주세요.');
    }
    final previous = value[plantId];
    final entries = [...?previous?.timeline];
    if (entries.any(
      (entry) => entry.sourceLetterId == sourceLetterId && entry.note == quote,
    )) {
      return;
    }
    final now = DateTime.now();
    entries.add(
      PlantMemoryEntry(
        id: 'letter-${now.microsecondsSinceEpoch}',
        on: plantMemoryDay(source.writtenAt.toLocal()),
        note: quote,
        sourceLetterId: sourceLetterId,
        sourceWrittenAt: source.writtenAt,
      ),
    );
    await _write(
      PlantMemory(
        plantId: plantId,
        name: previous?.name ?? '',
        note: entries.last.note,
        updatedAt: now,
        anniversaryOn: previous?.anniversaryOn,
        entries: entries,
      ),
    );
  });

  Future<void> _scrubLetter(String sourceLetterId) async {
    await _refresh();
    final box = await HiveEncryption.openBox(boxName);
    LocalRecordTransaction.capture(box, afterRollback: _refresh);
    for (final memory in value.values) {
      final entries = memory.timeline
          .where((entry) => entry.sourceLetterId != sourceLetterId)
          .toList();
      if (entries.length == memory.timeline.length) continue;
      final next = PlantMemory(
        plantId: memory.plantId,
        name: memory.name,
        anniversaryOn: memory.anniversaryOn,
        updatedAt: DateTime.now(),
        note: entries.isEmpty ? '' : entries.last.note,
        entries: entries,
      );
      await box.put(memory.plantId, next.toJson());
    }
    await box.flush();
    await _refresh();
  }

  Future<void> removeForLetter(String sourceLetterId) =>
      _serial(() => _scrubLetter(sourceLetterId));

  Future<void> removeLetterSource(
    String sourceLetterId,
    Future<void> Function() deleteSource,
  ) => _serial(() async {
    await _scrubLetter(sourceLetterId);
    await deleteSource();
  });
}
