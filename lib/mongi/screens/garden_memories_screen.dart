import 'package:flutter/material.dart';
import '../integration/mongi_garden_store.dart';
import '../integration/plant_memory_store.dart';
import '../integration/plant_memory_editor.dart';
import '../models/garden_anniversary.dart';
import '../models/seed.dart';

class GardenMemoriesScreen extends StatefulWidget {
  const GardenMemoriesScreen({super.key});
  @override
  State<GardenMemoriesScreen> createState() => _GardenMemoriesScreenState();
}

class _GardenMemoriesScreenState extends State<GardenMemoriesScreen> {
  late Future<void> _ready;
  @override
  void initState() {
    super.initState();
    _ready = _load();
  }

  Future<void> _load() async {
    await MongiGardenStore.instance.reload();
    await PlantMemoryStore.instance.reload();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('정원에 남긴 기억')),
    body: SafeArea(
      child: FutureBuilder<void>(
        future: _ready,
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return Center(
              child: TextButton(
                onPressed: () => setState(() => _ready = _load()),
                child: const Text('기억을 불러오지 못했어요 · 다시 시도'),
              ),
            );
          if (snapshot.connectionState != ConnectionState.done)
            return const Center(child: CircularProgressIndicator());
          return AnimatedBuilder(
            animation: Listenable.merge([
              MongiGardenStore.instance,
              PlantMemoryStore.instance,
            ]),
            builder: (context, _) {
              final garden = MongiGardenStore.instance.value,
                  memories = PlantMemoryStore.instance.value;
              final plants = SeedType.all
                  .where((p) => (garden.seeds[p.id] ?? 0) > 0)
                  .toList();
              final dates =
                  garden.plantedOn.values
                      .map(GardenAnniversary.parse)
                      .whereType<DateTime>()
                      .toList()
                    ..sort();
              final now = DateTime.now();
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      const Text(
                        '함께한 시간이 여기에 남아 있어요',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('나만 보는 이름·마음·기념일이에요. 식물을 눌러 읽거나 고칠 수 있어요.'),
                      if (dates.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            GardenAnniversary.daysTogether(dates.first, now) > 0
                                ? '처음 심은 날 ${GardenAnniversary.key(dates.first)}\n정원과 함께한 지 ${GardenAnniversary.daysTogether(dates.first, now)}일'
                                : '처음 심은 날 ${GardenAnniversary.key(dates.first)}',
                          ),
                        ),
                      if (plants.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Text('첫 씨앗을 심으면 이곳에서 이름과 그날의 마음을 남길 수 있어요.'),
                        ),
                      for (final plant in plants)
                        Builder(
                          builder: (context) {
                            final memory = memories[plant.id];
                            final planted = GardenAnniversary.parse(
                              garden.plantedOn[plant.id],
                            );
                            final date = memory?.memoryDate ?? planted;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 14),
                              child: InkWell(
                                onTap: () => showDialog<void>(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (_) =>
                                      PlantMemoryEditor(plant: plant),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(18),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        memory?.name.isNotEmpty == true
                                            ? memory!.name
                                            : plant.label,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '${plant.label} · ${plant.growthLabel(garden.seeds[plant.id]!)}',
                                      ),
                                      const SizedBox(height: 8),
                                      if (date != null)
                                        Text(
                                          '${memory?.memoryDate == null ? '심은 날' : '기억할 날'} ${GardenAnniversary.key(date)} · ${GardenAnniversary.label(date, now)}',
                                        ),
                                      if (memory?.note.isNotEmpty == true)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 10,
                                          ),
                                          child: Text(memory!.note),
                                        ),
                                      if (memory == null ||
                                          (memory.name.isEmpty &&
                                              memory.note.isEmpty))
                                        const Text('이 나무에 이름과 마음을 남겨볼까요?'),
                                      const SizedBox(height: 8),
                                      const Text(
                                        '기억 열기',
                                        style: TextStyle(
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    ),
  );
}
