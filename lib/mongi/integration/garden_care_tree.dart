import 'package:flutter/material.dart';
import '../../theme.dart';
import 'mongi_garden_store.dart';

/// A decorative tree grown by existing care receipts, never spendable currency.
class GardenCareTree extends StatelessWidget {
  const GardenCareTree({super.key});
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<MongiGardenData>(
    valueListenable: MongiGardenStore.instance,
    builder: (context, data, _) {
      final today = MongiGardenData.dayKey(DateTime.now());
      final message = data.meditationDays.contains(today)
          ? '잠시 쉰 자리에서 새잎이 펴졌어요.'
          : data.recordDays.contains(today)
          ? '오늘의 편지 곁에 고양이가 자리를 잡았어요.'
          : data.stage > 1
          ? '달리고 돌아온 몽이의 빛이 잎에 남았어요.'
          : '편지·명상·달리기의 시간이 잎으로 남아요.';
      return Tooltip(
        message: message,
        child: Semantics(
          label: '돌봄 나무 ${data.careTreeTier}단계. $message',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 600),
                child: Text(
                  const ['🌱', '🌿', '🌳', '🌳✨', '🌳🌸'][data.careTreeTier],
                  key: ValueKey(data.careTreeTier),
                  style: const TextStyle(fontSize: 34),
                ),
              ),
              const Text(
                '돌봄 나무',
                style: TextStyle(fontSize: 10, color: Color(0xFF375B42)),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class GardenCareNote extends StatelessWidget {
  final MongiGardenData data;
  const GardenCareNote({super.key, required this.data});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    margin: const EdgeInsets.only(top: 10),
    decoration: BoxDecoration(
      color: AppColors.blobMint,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '정원에 남은 오늘의 마음',
          style: bodyFont(
            fontSize: 15,
            color: AppColors.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          data.careLeaves == 0
              ? '편지를 쓰거나 명상을 마치면 돌봄 나무가 자라기 시작해요.'
              : '함께한 시간이 돌봄 나무의 잎과 정원의 이야기로 남아 있어요. 쉬었다 와도 잎은 사라지지 않아요.',
        ),
        if (data.recordDays.isNotEmpty)
          const Text('💌 편지 곁에서 고양이가 조용히 기다리고 있어요.'),
        if (data.meditationDays.isNotEmpty)
          const Text('🌿 쉬어 간 자리에는 작은 그늘이 생겼어요.'),
        if (data.stage > 1) const Text('✨ 달리고 돌아온 몽이가 풀밭에서 숨을 고르고 있어요.'),
      ],
    ),
  );
}
