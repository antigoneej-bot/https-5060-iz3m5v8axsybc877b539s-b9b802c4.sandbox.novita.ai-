import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider.dart';
import '../../utils/garden_record_progress.dart';
import '../integration/mongi_garden_store.dart';
import '../models/seed.dart';
import '../screens/garden_world_screen.dart';
import 'living_garden_scene.dart';

/// Shown only after a confirmed save; rewards may still be retrying separately.
class GardenRecordCard extends StatelessWidget {
  const GardenRecordCard({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppStateProvider>();
    return ValueListenableBuilder<MongiGardenData>(
      valueListenable: MongiGardenStore.instance,
      builder: (context, data, _) {
        final count = gardenRecordDays(
          data.recordDays,
          app.history.map((entry) => entry.date),
          now: DateTime.now(),
        ).length;
        final pending = app.gardenRewardPending || app.gardenRewardRetrying;
        return Card(
          color: const Color(0xFFF0F5EA),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('내 마음이 정원에 남는 시간', style: TextStyle(fontSize: 16)),
                SizedBox(
                  width: 86,
                  height: 86,
                  child: GardenPlantArt(
                    seed: SeedType.byId('cherry'),
                    count: count,
                  ),
                ),
                Text(
                  pending
                      ? '편지는 저장됐어요. 정원의 성장 기록을 연결하고 있어요.'
                      : gardenRecordMessage(count),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  '하루에 한 번 성장해요. 편지는 기억의 나무에서 나만 다시 볼 수 있어요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12),
                ),
                if (app.gardenRewardPending)
                  TextButton(
                    onPressed: app.gardenRewardRetrying
                        ? null
                        : app.retryGardenRewards,
                    child: const Text('성장 기록 다시 연결하기'),
                  ),
                TextButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          const GardenWorldScreen(showRecordNote: true),
                    ),
                  ),
                  icon: const Icon(Icons.park_outlined),
                  label: const Text('내 정원에서 보기'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
