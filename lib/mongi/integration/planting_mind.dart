import '../../l10n/app_language.dart';
import '../models/seed.dart';
import 'plant_memory.dart';

/// A draft until planting or adding a private memory is confirmed. Never public,
/// and never part of the
/// garden snapshot or of the seed/reward balance.
class PlantingMind {
  final String id, emotionCatId, note;
  const PlantingMind({
    required this.id,
    required this.emotionCatId,
    this.note = '',
  });

  PlantMemoryEntry entry(DateTime now) {
    final result = PlantMemoryEntry(
      id: id,
      on: plantMemoryDay(now),
      note: note.trim(),
      emotionCatId: emotionCatId,
    );
    return PlantMemoryEntry.fromJson(result.toJson());
  }
}

String plantingMeaning(SeedType seed) => tr(switch (seed.id) {
  'pine' => '나를 지켜주는 마음을 심어요.',
  'cherry' => '간직하고 싶은 작은 기쁨을 심어요.',
  'maple' => '변해가는 나를 천천히 받아들여요.',
  'forgiveness' => '아직 풀리지 않은 마음을 잠시 놓아두어요.',
  'love' => '나와 소중한 사람을 아끼는 마음을 심어요.',
  _ => '내 마음이 잠깐 쉴 자리를 만들어요.',
});
