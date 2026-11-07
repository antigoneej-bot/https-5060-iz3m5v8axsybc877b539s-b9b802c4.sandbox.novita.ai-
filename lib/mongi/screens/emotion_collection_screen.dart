import '../../theme.dart' show AppColors;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/emotion_l10n.dart';
import '../l10n/gen/app_localizations.dart';
import '../models/emotion.dart';
import '../providers/garden_provider.dart';
import '../services/emotion_evolution_service.dart';
import '../widgets/floating_bob.dart';

/// "감정 컬렉션 도감" - 15종 감정(부정 10 + 긍정 5)을 처음 만날 때마다
/// 하나씩 채워지는 도감. [GardenProvider.flowerCounts]에 이미 존재하는
/// "감정 타입별 누적 심어진 꽃 개수"를 그대로 재사용해서, 개수가 1 이상이면
/// "이미 만난 감정"으로 간주한다 (별도 저장 로직이 필요 없다 - MVP 원칙).
///
/// 레어도 시스템: 같은 감정을 5번/20번 마주하면 "진화"(몬스터가 더 성숙한
/// 이름으로 바뀜)하고, 50번(마스터) 이상부터는 세션마다 극히 낮은 확률로
/// "황금 프레임"을 얻을 수 있다 - SNS에 자랑할 만한 희귀 요소.
///
/// 목적: 수집욕구 자극 + 감정 교육적 가치. 아직 만나지 않은 감정은 실루엣으로
/// 가려두어 "어떤 감정일까?" 하는 호기심을 자극하고, 처음 만나면 카드가
/// 열리면서 몽이 시선의 짧은 스토리를 보여준다.
class EmotionCollectionScreen extends StatelessWidget {
  const EmotionCollectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final garden = context.watch<GardenProvider>();
    final metCount = Emotion.all
        .where((e) => (garden.flowerCounts[e.type.name] ?? 0) > 0)
        .length;
    final negative = Emotion.all.where((e) => !e.isPositive).toList();
    final positive = Emotion.all.where((e) => e.isPositive).toList();

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF3EAFB), AppColors.bg0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, l10n, metCount),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProgressCard(l10n, metCount, garden),
                      const SizedBox(height: 22),
                      _sectionTitle(l10n.collectionNegativeSectionTitle),
                      const SizedBox(height: 10),
                      _buildGrid(context, garden, negative),
                      const SizedBox(height: 22),
                      _sectionTitle(l10n.collectionPositiveSectionTitle),
                      const SizedBox(height: 10),
                      _buildGrid(context, garden, positive),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AppLocalizations l10n,
    int metCount,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.ink),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              l10n.collectionHeaderTitle,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              '$metCount / ${Emotion.all.length}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFF8B6BB5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(
    AppLocalizations l10n,
    int metCount,
    GardenProvider garden,
  ) {
    final total = Emotion.all.length;
    final ratio = total == 0 ? 0.0 : metCount / total;
    final isComplete = metCount >= total;
    final goldenCount = garden.goldenFrameEmotions.length;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isComplete
                ? l10n.collectionProgressCompleteText
                : l10n.collectionProgressPartialText(metCount),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.collectionProgressHint,
            style: const TextStyle(fontSize: 11.5, color: AppColors.inkSoft),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: const Color(0xFFEFE6F5),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF8B6BB5)),
            ),
          ),
          if (goldenCount > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE0A72E), Color(0xFFF5C244)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🏆', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    l10n.collectionGoldenFrameCount(goldenCount),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: AppColors.ink,
      ),
    );
  }

  Widget _buildGrid(
    BuildContext context,
    GardenProvider garden,
    List<Emotion> emotions,
  ) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: emotions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.82,
      ),
      itemBuilder: (context, index) {
        final emotion = emotions[index];
        final count = garden.flowerCounts[emotion.type.name] ?? 0;
        final met = count > 0;
        final hasGolden = garden.hasGoldenFrame(emotion);
        final card = _EmotionCollectionCard(
          emotion: emotion,
          met: met,
          count: count,
          hasGoldenFrame: hasGolden,
        );
        // 만난 감정만 살짝 둥둥 떠다니게 해서 "살아있는 도감" 느낌을 준다.
        if (!met) return card;
        return FloatingBob(
          phase: (index * 0.41) % 1.0,
          amplitude: hasGolden ? 6 : 4,
          duration: Duration(milliseconds: 2400 + (index % 4) * 260),
          child: card,
        );
      },
    );
  }
}

/// 도감 카드 하나. 아직 만나지 않았으면 물음표 실루엣으로 가려두고,
/// 만난 감정만 탭하면 상세 스토리 다이얼로그를 열 수 있다.
/// [hasGoldenFrame]이 true면 카드 전체에 금빛 테두리/광채가 둘러진다.
class _EmotionCollectionCard extends StatelessWidget {
  final Emotion emotion;
  final bool met;
  final int count;
  final bool hasGoldenFrame;

  const _EmotionCollectionCard({
    required this.emotion,
    required this.met,
    required this.count,
    this.hasGoldenFrame = false,
  });

  void _showDetail(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final stageIndex = EmotionEvolutionService.stageIndexForCount(count);
    final evolvedName = evolutionNameForCount(l10n, emotion.type, count);
    final remaining = EmotionEvolutionService.remainingToNextStage(count);
    final nextName = evolutionNextNameFor(l10n, emotion.type, count);
    final isMastered = EmotionEvolutionService.isMastered(count);
    // 6번: 히든 4단계("초월") - 마스터 이후에도 조용히 계속 채워지다가
    // 100번째에 도달하면 이 화면에서도 별도 등급으로 표시된다. 도달하기
    // 전까지는 카운트다운이나 존재 자체를 전혀 알려주지 않는다.
    final isTranscended = EmotionEvolutionService.isTranscended(count);
    final rankLabel = isTranscended
        ? l10n.collectionTranscendedRank
        : isMastered
        ? l10n.collectionMasteredRank
        : l10n.collectionStageRank(stageIndex + 1);

    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: hasGoldenFrame
                ? Border.all(color: const Color(0xFFE0A72E), width: 3)
                : isTranscended
                ? Border.all(color: const Color(0xFF6B4FA0), width: 3)
                : null,
            boxShadow: hasGoldenFrame
                ? [
                    BoxShadow(
                      color: const Color(0xFFE0A72E).withValues(alpha: 0.5),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ]
                : isTranscended
                ? [
                    BoxShadow(
                      color: const Color(0xFF6B4FA0).withValues(alpha: 0.45),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasGoldenFrame) ...[
                Text(
                  l10n.collectionGoldenFrameEarned,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFB8860B),
                  ),
                ),
                const SizedBox(height: 8),
              ] else if (isTranscended) ...[
                Text(
                  l10n.collectionTranscendedBadge,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF6B4FA0),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Stack(
                alignment: Alignment.center,
                children: [
                  if (hasGoldenFrame)
                    Container(
                      width: 84,
                      height: 84,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFFE0A72E), Color(0xFFF5C244)],
                        ),
                      ),
                    ),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: emotion.color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      emotion.emoji,
                      style: const TextStyle(fontSize: 34),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                evolvedName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: emotion.color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${emotionLabel(l10n, emotion.type)} · $rankLabel',
                style: const TextStyle(fontSize: 11, color: AppColors.inkSoft),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.collectionMetCountLabel(count),
                style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
              ),
              if (remaining != null && nextName != null) ...[
                const SizedBox(height: 6),
                Text(
                  l10n.collectionNextEvolutionHint(remaining, nextName),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF8B6BB5),
                  ),
                ),
              ] else if (isTranscended) ...[
                const SizedBox(height: 6),
                Text(
                  l10n.collectionTranscendedMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6B4FA0),
                  ),
                ),
              ] else if (isMastered && !hasGoldenFrame) ...[
                const SizedBox(height: 6),
                Text(
                  l10n.collectionMasteredMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFB8860B),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: emotion.color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  emotionStoryText(l10n, emotion.type),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.55,
                    color: AppColors.ink,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: emotion.color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(l10n.commonCloseButton),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final stageIndex = EmotionEvolutionService.stageIndexForCount(count);
    // 6번: 히든 4단계("초월"). 황금 프레임과는 별개의 등급이라, 황금
    // 프레임이 없을 때만 카드 테두리/광채에 반영해 시각적으로 구분한다.
    final isTranscended = met && stageIndex >= 3;
    final evolvedName = met
        ? evolutionNameForCount(l10n, emotion.type, count)
        : '???';
    return GestureDetector(
      onTap: met ? () => _showDetail(context) : null,
      child: Container(
        decoration: BoxDecoration(
          color: met
              ? Colors.white.withValues(alpha: 0.9)
              : Colors.white.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: hasGoldenFrame
                ? const Color(0xFFE0A72E)
                : isTranscended
                ? const Color(0xFF6B4FA0)
                : met
                ? emotion.color.withValues(alpha: 0.35)
                : Colors.grey.withValues(alpha: 0.2),
            width: hasGoldenFrame || isTranscended ? 2.5 : 1,
          ),
          boxShadow: hasGoldenFrame
              ? [
                  BoxShadow(
                    color: const Color(0xFFE0A72E).withValues(alpha: 0.45),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : isTranscended
              ? [
                  BoxShadow(
                    color: const Color(0xFF6B4FA0).withValues(alpha: 0.4),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: met
                        ? emotion.color.withValues(alpha: 0.15)
                        : Colors.grey.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    met ? emotion.emoji : '❔',
                    style: TextStyle(
                      fontSize: 20,
                      color: met ? null : Colors.grey.shade400,
                    ),
                  ),
                ),
                if (met && stageIndex >= 1)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: Text(
                      // 6번: 초월(3단계)은 별과는 다른 심볼로 구분해,
                      // 마스터(2단계 · ⭐⭐)와 한눈에 다른 등급임을 보여준다.
                      stageIndex >= 3
                          ? '🌌'
                          : stageIndex >= 2
                          ? '⭐⭐'
                          : '⭐',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                if (hasGoldenFrame)
                  const Positioned(
                    bottom: -4,
                    child: Text('🏆', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              evolvedName,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: met ? AppColors.ink : Colors.grey.shade400,
              ),
            ),
            if (met) ...[
              const SizedBox(height: 2),
              Text(
                'x$count',
                style: const TextStyle(fontSize: 10, color: AppColors.inkSoft),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
