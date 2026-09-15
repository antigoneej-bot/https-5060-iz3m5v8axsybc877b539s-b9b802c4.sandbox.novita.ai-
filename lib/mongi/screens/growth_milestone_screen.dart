import '../../theme.dart' show AppColors;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/emotion_l10n.dart';
import '../l10n/gen/app_localizations.dart';
import '../models/emotion.dart';
import '../models/tree_growth.dart';
import '../providers/garden_provider.dart';
import '../services/emotion_insight_service.dart';
import '../widgets/garden_growth_share_sheet.dart';

/// "성장 마일스톤 회고" - 몽이의 성장나무가 마침내 마지막 단계(열매)를 맺었을 때
/// 보여주는 엔딩 경험. 그동안 [GardenProvider.diaryEntries]에 쌓인 한 줄 기록들을
/// 시간순(오래된 것부터)으로 늘어놓아 "감정 성장 다큐멘터리"처럼 회고할 수 있게 한다.
///
/// 별도의 새 저장 로직 없이 이미 존재하는 다이어리 데이터를 재구성해서 보여주는
/// 화면이라 구현 난이도는 낮지만("하"), 감동/브랜드 애착이라는 임팩트는 크다.
class GrowthMilestoneScreen extends StatelessWidget {
  const GrowthMilestoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final garden = context.watch<GardenProvider>();
    // 다이어리는 최신순으로 저장되어 있으니, 다큐멘터리는 "처음부터" 보여주기 위해
    // 시간 순서를 오래된 것 -> 최신 순으로 뒤집는다.
    final timeline = garden.diaryEntries.reversed.toList();

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF3D6), AppColors.bg0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, l10n),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  children: [
                    _buildIntroCard(l10n),
                    const SizedBox(height: 20),
                    _buildStatsCard(garden, l10n),
                    const SizedBox(height: 16),
                    _buildInsightCard(garden, l10n),
                    const SizedBox(height: 24),
                    if (timeline.isEmpty)
                      _buildEmptyTimeline(l10n)
                    else ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 12),
                        child: Text(
                          l10n.milestoneTimelineTitle,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      ...List.generate(timeline.length, (index) {
                        final isFirst = index == 0;
                        final isLast = index == timeline.length - 1;
                        return _TimelineEntryTile(
                          entry: timeline[index],
                          order: index + 1,
                          isFirst: isFirst,
                          isLast: isLast,
                        );
                      }),
                    ],
                    const SizedBox(height: 24),
                    _buildClosingCard(context, garden, l10n),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.ink),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 4),
          Text(
            l10n.milestoneHeaderTitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroCard(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.blobMint, AppColors.blobButter],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: AppColors.line,
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Image.asset(TreeGrowth.stageAssets.last, height: 92),
          const SizedBox(height: 12),
          Text(
            l10n.milestoneIntroTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.titlePastelGreen,
              fontSize: 19,
              fontWeight: FontWeight.w800,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.milestoneIntroBody,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.titlePastelGreen,
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(GardenProvider garden, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statItem(
            '🌷',
            l10n.gardenShareCardFlowersStat(garden.totalFlowersPlanted),
            l10n.gardenShareCardFlowersLabel,
          ),
          _statItem(
            '🔥',
            l10n.gardenShareCardStreakStat(garden.streakDays),
            l10n.milestoneStreakLabel,
          ),
          _statItem(
            '✨',
            l10n.gardenShareCardScoreStat(garden.score),
            l10n.milestoneScoreLabel,
          ),
          _statItem(
            '📔',
            l10n.milestoneDiaryCountStat(garden.diaryEntries.length),
            l10n.milestoneDiaryCountLabel,
          ),
        ],
      ),
    );
  }

  /// 감정 데이터 되돌려주기(4단계) - 이 나무를 키우는 동안의 감정 기록을
  /// 요약해서 보여주는 카드. 새 저장 로직 없이 기존 diaryEntries만으로
  /// 계산한다([EmotionInsightService]).
  Widget _buildInsightCard(GardenProvider garden, AppLocalizations l10n) {
    final entries = garden.diaryEntries;
    final topEmotions = EmotionInsightService.topEmotions(
      diaryEntries: entries,
    );
    final improved = EmotionInsightService.mostImprovedEmotion(
      diaryEntries: entries,
    );
    final uncollected = EmotionInsightService.uncollectedEmotionCount(
      diaryEntries: entries,
    );

    // 보여줄 내용이 아무것도 없으면(데이터가 너무 적은 경우) 카드 자체를 생략.
    if (topEmotions.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
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
            l10n.milestoneInsightTitle,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: topEmotions.map((e) {
              final emotion = e.key;
              final count = e.value;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: emotion.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: emotion.color.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      emotion.gardenIcon,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n.milestoneEmotionCountLabel(
                        emotionLabel(l10n, emotion.type),
                        count,
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: emotion.color,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          if (improved != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6EC),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🌱', style: TextStyle(fontSize: 15)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.milestoneImprovedText(improved.label),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF4F7A47),
                        height: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (uncollected > 0) ...[
            const SizedBox(height: 10),
            Text(
              l10n.milestoneUncollectedText(uncollected),
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.inkSoft,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statItem(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            color: AppColors.ink,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10.5, color: AppColors.inkSoft),
        ),
      ],
    );
  }

  Widget _buildEmptyTimeline(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        l10n.milestoneEmptyTimelineText,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.inkSoft,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildClosingCard(
    BuildContext context,
    GardenProvider garden,
    AppLocalizations l10n,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE0A72E).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          const Text('🐱', style: TextStyle(fontSize: 30)),
          const SizedBox(height: 10),
          Text(
            l10n.milestoneClosingQuote,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.ink,
              fontStyle: FontStyle.italic,
              height: 1.6,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => GardenGrowthShareSheet.show(
                context,
                stageIndex: garden.treeStageIndex,
                score: garden.score,
                streakDays: garden.streakDays,
                totalFlowersPlanted: garden.totalFlowersPlanted,
              ),
              icon: const Icon(Icons.ios_share, size: 18),
              label: Text(
                l10n.milestoneShareButtonLabel,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE0A72E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 다큐멘터리 타임라인의 한 항목. 왼쪽에 세로선+점으로 시간 흐름을 표현하고,
/// 오른쪽에 그날 마주한 감정과 한 줄 기록을 카드로 보여준다.
class _TimelineEntryTile extends StatelessWidget {
  final Map<String, dynamic> entry;
  final int order;
  final bool isFirst;
  final bool isLast;

  const _TimelineEntryTile({
    required this.entry,
    required this.order,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final emotion = Emotion.byTypeName(entry['emotionType'] as String? ?? '');
    final date = entry['date'] as String? ?? '';
    final targetName = entry['targetName'] as String?;
    final eatenCount = (entry['eatenCount'] as num?)?.toInt() ?? 0;
    final note = entry['note'] as String?;
    final nameLabel = (targetName != null && targetName.isNotEmpty)
        ? l10n.shareNameLabelWithTarget(
            targetName,
            emotionLabel(l10n, emotion.type),
          )
        : emotionLabel(l10n, emotion.type);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 왼쪽: 세로 타임라인 선 + 점
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 2,
                  height: 6,
                  color: isFirst
                      ? Colors.transparent
                      : const Color(0xFFE0A72E).withValues(alpha: 0.35),
                ),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: emotion.color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast
                        ? Colors.transparent
                        : const Color(0xFFE0A72E).withValues(alpha: 0.35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // 오른쪽: 카드
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: emotion.color.withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          emotion.gardenIcon,
                          style: const TextStyle(fontSize: 15),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            nameLabel,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: emotion.color,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '#$order',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFBDB3A8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.milestoneTimelineDateCount(date, eatenCount),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.inkSoft,
                      ),
                    ),
                    if (note != null && note.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        l10n.milestoneTimelineNoteQuote(note),
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.inkSoft,
                          height: 1.4,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
