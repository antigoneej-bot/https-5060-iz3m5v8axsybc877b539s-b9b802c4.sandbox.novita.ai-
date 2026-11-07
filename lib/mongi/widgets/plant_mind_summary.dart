import 'package:flutter/material.dart';
import '../../data/shadow_cats_data.dart';
import '../../l10n/app_language.dart';
import '../integration/plant_memory_store.dart';

/// Owner-only presentation; never included by the public garden renderer.
class PlantMindSummary extends StatelessWidget {
  final String plantId;
  const PlantMindSummary({super.key, required this.plantId});
  @override
  Widget build(
    BuildContext context,
  ) => ValueListenableBuilder<Map<String, PlantMemory>>(
    valueListenable: PlantMemoryStore.instance,
    builder: (_, memories, __) {
      final entries = memories[plantId]?.timeline ?? const <PlantMemoryEntry>[];
      if (entries.isEmpty) return const SizedBox.shrink();
      final entry = entries.last;
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 5,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 15),
                Text(tr('이 식물에 담아둔 마음')),
                if (entry.emotionCatId != null)
                  Text(shadowCatById(entry.emotionCatId!).displayKeyword),
              ],
            ),
            if (entry.note.isNotEmpty)
              Text(entry.note, maxLines: 2, overflow: TextOverflow.ellipsis),
            Text(tr('그날의 나에게, 오늘의 다정함을 조금.')),
          ],
        ),
      );
    },
  );
}
