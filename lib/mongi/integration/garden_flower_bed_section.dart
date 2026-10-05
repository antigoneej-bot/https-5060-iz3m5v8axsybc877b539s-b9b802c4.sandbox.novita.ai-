import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme.dart' show AppColors;
import '../l10n/emotion_l10n.dart';
import '../l10n/gen/app_localizations.dart';
import '../models/emotion.dart';
import '../providers/garden_provider.dart';

/// 정원 통합(마음냥 정원 + 몽이네 정원) 이전, "몽이네 정원"(구 GardenScreen)
/// 화면에만 있던 "감정별 꽃밭" 시각화를 그대로 이어받은 섹션.
///
/// [GardenProvider.flowerCounts]는 통합 전/후 완전히 동일한 저장소
/// ([GardenStorage])를 쓰고 있었으므로 숫자 데이터 자체는 처음부터 한 번도
/// 손실된 적이 없다 - 이 위젯은 그 숫자를 "나의 정원" 화면에서도 계속 눈으로
/// 확인할 수 있도록, 기존 카드 디자인을 그대로 옮겨온 것뿐이다.
class GardenFlowerBedSection extends StatelessWidget {
  const GardenFlowerBedSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final garden = context.watch<GardenProvider>();
    final plantedEmotions = Emotion.all
        .where((e) => (garden.flowerCounts[e.type.name] ?? 0) > 0)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('🌼', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              l10n.gardenSummaryFlowersPlanted(garden.totalFlowersPlanted),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14.5,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        plantedEmotions.isEmpty
            ? _buildEmptyState(l10n)
            : Column(
                children: plantedEmotions.map((emotion) {
                  final count = garden.flowerCounts[emotion.type.name] ?? 0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _GardenFlowerBedCard(
                      l10n: l10n,
                      emotion: emotion,
                      count: count,
                    ),
                  );
                }).toList(),
              ),
      ],
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          const Text('🌱', style: TextStyle(fontSize: 32)),
          const SizedBox(height: 10),
          Text(
            l10n.gardenEmptyTitle,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.gardenEmptyBody,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.inkSoft,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// 감정 타입 하나에 해당하는 "꽃밭" 카드. 심어진 개수만큼 아이콘이 늘어난다.
/// (구 GardenScreen._FlowerBedCard와 동일한 디자인을 그대로 유지한다.)
class _GardenFlowerBedCard extends StatelessWidget {
  final AppLocalizations l10n;
  final Emotion emotion;
  final int count;

  const _GardenFlowerBedCard({
    required this.l10n,
    required this.emotion,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    const maxShown = 10;
    final shown = count > maxShown ? maxShown : count;
    final overflow = count - shown;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: emotion.color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: emotion.color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Text(emotion.gardenIcon, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      l10n.gardenFlowerBedTitle(emotionLabel(l10n, emotion.type)),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: emotion.color,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'x$count',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 3,
                  children: [
                    ...List.generate(
                      shown,
                      (_) => Text(
                        emotion.gardenIcon,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    if (overflow > 0)
                      Text(
                        '+$overflow',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.inkSoft,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
