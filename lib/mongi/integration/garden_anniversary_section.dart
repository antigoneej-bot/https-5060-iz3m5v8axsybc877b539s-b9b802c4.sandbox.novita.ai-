import 'package:flutter/material.dart';
import '../../models/shadow_cat.dart';
import '../models/seed.dart';
import 'garden_postcard_screen.dart';
import 'mongi_garden_data.dart';
import 'plant_memory_store.dart';

/// Private anniversary cards. No note, name or anniversary is added to a public
/// garden snapshot; an owner must choose a postcard and then use the OS share.
class GardenAnniversarySection extends StatelessWidget {
  final MongiGardenData data;
  final List<ShadowCat> cats;
  final DateTime? now;
  const GardenAnniversarySection({
    super.key,
    required this.data,
    required this.cats,
    this.now,
  });

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<Map<String, PlantMemory>>(
        valueListenable: PlantMemoryStore.instance,
        builder: (context, memories, _) {
          final dated = memories.values.where(
            (memory) =>
                memory.anniversaryOn != null &&
                (data.seeds[memory.plantId] ?? 0) > 0,
          );
          if (dated.isEmpty) return const SizedBox.shrink();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '함께 기억하는 날',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              for (final memory in dated)
                _card(context, memory, now ?? DateTime.now()),
              const SizedBox(height: 12),
            ],
          );
        },
      );

  Widget _card(BuildContext context, PlantMemory memory, DateTime today) {
    final days = memory.daysTogether(today)!;
    final reached = memory.milestonesReached(today);
    final next = days < 30
        ? 30
        : days < 100
        ? 100
        : null;
    final name = memory.name.isEmpty
        ? SeedType.byId(memory.plantId).label
        : memory.name;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(name, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              days > 0
                  ? '함께한 지 $days일 · ${memory.anniversaryOn}'
                  : '기념 시작일까지 ${1 - days}일 · ${memory.anniversaryOn}',
            ),
            if (next != null && days > 0)
              Text('$next일 기념까지 ${next - days}일 남았어요.'),
            if (days <= 0) const Text('시작일을 기다리며 오늘의 추억을 남겨도 좋아요.'),
            if (reached.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('지나온 날을 엽서로 남겨 볼까요?'),
              Wrap(
                spacing: 8,
                children: [
                  for (final milestone in reached)
                    OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GardenPostcardScreen(
                            data: data,
                            cats: cats,
                            initialCaption: memory.milestoneCaption(milestone),
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.mail_outline),
                      label: Text('$milestone일 기념 엽서'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
