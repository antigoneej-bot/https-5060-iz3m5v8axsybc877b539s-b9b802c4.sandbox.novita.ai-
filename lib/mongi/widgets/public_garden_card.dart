import 'garden_world_view.dart';
import 'package:flutter/material.dart';

import '../../theme.dart' show AppColors;
import '../l10n/gen/app_localizations.dart';
import '../models/garden_decoration.dart';
import '../models/public_garden.dart';
import '../models/seed.dart';
import '../models/tree_growth.dart';

/// "둘러보기"에서 다른 사람의 공개정원 하나를 보여주는 읽기전용 카드.
///
/// [GardenSceneView]처럼 배경 이미지 위에 씨앗/장식/나무를 겹쳐 그리는
/// 완전한 씬이 아니라, 훨씬 가벼운 "미리보기" 형태로 심은 씨앗과 나무
/// 단계를 요약해 보여준다 - 방문자 화면이 무거워지지 않게 하기 위함이다.
///
/// 이 카드에는 터치로 움직이거나 바꿀 수 있는 요소가 전혀 없다(읽기전용) -
/// "방문자가 다른 사람의 정원 배치를 바꾸거나 반출할 수 없다"는 원칙을
/// 위젯 구조 자체로 보장한다. 유일한 상호작용은 하단의 응원 보내기
/// 버튼([onCheer])뿐이다.
class PublicGardenCard extends StatelessWidget {
  final PublicGarden garden;
  final bool alreadyCheeredToday;
  final VoidCallback? onCheer;

  const PublicGardenCard({
    super.key,
    required this.garden,
    required this.alreadyCheeredToday,
    this.onCheer,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final plantedSeeds = garden.seedCounts.entries
        .where((e) => e.value > 0)
        .map((e) => SeedType.byId(e.key))
        .toList();
    final decorations = garden.equippedDecorationIds
        .map(GardenDecoration.byId)
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E0),
                  shape: BoxShape.circle,
                ),
                child: const Text('🌿', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  garden.nickname?.trim().isNotEmpty == true
                      ? garden.nickname!
                      : l10n.publicGardenAnonymousNickname,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                    color: AppColors.ink,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (garden.layout != null)
            OutlinedButton.icon(
              icon: const Icon(Icons.landscape_outlined),
              label: const Text('이 정원 산책하기'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(
                      title: Text('${garden.nickname ?? "이웃"}의 정원'),
                    ),
                    body: GardenWorldView(
                      readOnly: true,
                      publicMemoryStage: garden.memoryTreeStage,
                      publicCheerBed: garden.hasCheerFlowers,
                      reactions: garden.reactions,
                      flowerKinds: garden.flowerKinds,
                      layout: garden.layout!,
                      seeds: garden.seedCounts,
                      decorations: garden.equippedDecorationIds,
                      onMove: (_, _) async {},
                      onMemory: (_) {},
                      onPlant: () {},
                      onDecorate: () {},
                    ),
                  ),
                ),
              ),
            ),
          if (garden.treeStageIndex >= 0)
            Row(
              children: [
                Image.asset(
                  TreeGrowth.stageAssets[garden.treeStageIndex],
                  height: 40,
                ),
                const SizedBox(width: 8),
                Text(
                  TreeGrowth.stageLabels[garden.treeStageIndex],
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
            ),
          if (plantedSeeds.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: plantedSeeds.map((seed) {
                final count = garden.seedCounts[seed.id] ?? 0;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: seed.color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${seed.emojiForCount(count)} ${seed.label}',
                    style: const TextStyle(fontSize: 11.5),
                  ),
                );
              }).toList(),
            ),
          ],
          if (decorations.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              children: decorations
                  .map(
                    (d) => Text(d.emoji, style: const TextStyle(fontSize: 18)),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: alreadyCheeredToday ? null : onCheer,
              icon: const Text('💌', style: TextStyle(fontSize: 14)),
              label: Text(
                alreadyCheeredToday
                    ? l10n.publicGardenCheerAlreadySentToday
                    : l10n.publicGardenCheerButton,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB1466E),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFE6DDD6),
                disabledForegroundColor: const Color(0xFF9C8F84),
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
