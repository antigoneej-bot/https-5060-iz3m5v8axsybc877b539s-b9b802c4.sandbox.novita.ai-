import 'package:flutter/material.dart';
import '../../l10n/app_language.dart';
import '../models/plant_care.dart';
import '../models/seed.dart';
import 'mongi_garden_data.dart';

/// Shared care controls inside a plant's private memory dialog.
class PlantCarePanel extends StatelessWidget {
  final SeedType plant;
  final MongiGardenData data;
  final bool busy;
  final ValueChanged<PlantCare> onCare;
  final String? feedback;
  const PlantCarePanel({
    super.key,
    required this.plant,
    required this.data,
    required this.busy,
    required this.onCare,
    this.feedback,
  });

  @override
  Widget build(BuildContext context) {
    final id = plant.id;
    final progress = data.growthProgress(id);
    final now = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          [
            if (data.plantedOn[id] != null)
              tr('심은 날 · {0}', [data.plantedOn[id]]),
            tr('{0} · 성장 {1}%', [
              plant.growthLabel(data.seeds[id] ?? 0),
              (progress * 100).floor(),
            ]),
          ].join('\n'),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          semanticsLabel: tr('{0} 성장', [plant.label]),
          semanticsValue: '${(progress * 100).floor()}%',
          minHeight: 6,
          borderRadius: BorderRadius.circular(8),
        ),
        const SizedBox(height: 8),
        Text(
          tr('물만 주어도 자라요. 거름과 햇볕은 성장을 조금 더 도와줘요. 각각 하루 한 번, 쉬는 날에도 시들지 않아요.'),
        ),
        const SizedBox(height: 8),
        for (final care in PlantCare.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: FilledButton.tonalIcon(
              key: ValueKey('plant-care-${care.name}'),
              onPressed:
                  busy ||
                      (data.seeds[id] ?? 0) <= 0 ||
                      data.caredToday(id, care, now)
                  ? null
                  : () => onCare(care),
              icon: Icon(switch (care) {
                PlantCare.water => Icons.water_drop_outlined,
                PlantCare.fertilizer => Icons.grass_outlined,
                PlantCare.sunlight => Icons.wb_sunny_outlined,
              }),
              label: Text(
                data.caredToday(id, care, now)
                    ? tr('{0} · 오늘 완료', [care.label])
                    : care.label,
              ),
            ),
          ),
        if (feedback != null)
          Semantics(liveRegion: true, child: Text(feedback!)),
      ],
    );
  }
}
