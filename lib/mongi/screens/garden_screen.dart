import '../../theme.dart' show AppColors;
import '../../screens/my_garden_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/emotion_l10n.dart';
import '../l10n/gen/app_localizations.dart';
import '../l10n/tree_growth_l10n.dart';
import '../models/emotion.dart';
import '../models/tree_growth.dart';
import '../providers/garden_provider.dart';
import '../widgets/garden_growth_share_sheet.dart';
import '../widgets/garden_scene_view.dart';
import 'diary_screen.dart';
import 'emotion_calendar_screen.dart';
import 'emotion_collection_screen.dart';
import 'growth_milestone_screen.dart';
import 'mind_report_screen.dart';
import 'settings_screen.dart';

/// "내 마음정원" - 지금까지 치유한 감정마다 심어진 꽃들을 한눈에 다시 볼 수 있는 화면.
/// 숫자(회복도 %)로만 존재하던 진행도를 실제로 "눈에 보이는 정원"으로 시각화한다.
class GardenScreen extends StatelessWidget {
  const GardenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final garden = context.watch<GardenProvider>();
    final plantedEmotions = Emotion.all
        .where((e) => (garden.flowerCounts[e.type.name] ?? 0) > 0)
        .toList();

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE8F5E0), AppColors.bg0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, garden),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    children: [
                      _buildSummaryCard(context, garden),
                      const SizedBox(height: 20),
                      const GardenSceneView(),
                      const SizedBox(height: 6),
                      Text(
                        AppLocalizations.of(context).gardenTapHint,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.inkSoft,
                        ),
                      ),
                      const SizedBox(height: 20),
                      plantedEmotions.isEmpty
                          ? _buildEmptyState(context)
                          : _buildFlowerGrid(context, garden, plantedEmotions),
                      MyGardenScreen(showMongiPanel: false, onGoMeetCat: () => Navigator.of(context, rootNavigator: true).pop()),
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

  Widget _buildHeader(BuildContext context, GardenProvider garden) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 4),
      child: Column(children: [Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.ink),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              l10n.gardenHeaderTitle,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
          ),
        ],),
        Wrap(alignment: WrapAlignment.end, children: [
          _headerIcon(
            tooltip: l10n.homeMindReportButton,
            icon: const Text('💗', style: TextStyle(fontSize: 17)),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MindReportScreen()),
              );
            },
          ),
          _headerIcon(
            tooltip: l10n.gardenTooltipCollection,
            icon: const Text('📖', style: TextStyle(fontSize: 17)),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const EmotionCollectionScreen(),
                ),
              );
            },
          ),
          if (garden.isTreeFullyGrown)
            _headerIcon(
              tooltip: l10n.gardenTooltipMilestone,
              icon: const Text('🎬', style: TextStyle(fontSize: 16)),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const GrowthMilestoneScreen(),
                  ),
                );
              },
            ),
          _headerIcon(
            tooltip: l10n.gardenTooltipShare,
            icon: const Icon(
              Icons.ios_share,
              color: AppColors.ink,
              size: 18,
            ),
            onPressed: () {
              final garden = context.read<GardenProvider>();
              GardenGrowthShareSheet.show(
                context,
                stageIndex: garden.treeStageIndex,
                score: garden.score,
                streakDays: garden.streakDays,
                totalFlowersPlanted: garden.totalFlowersPlanted,
              );
            },
          ),
          _headerIcon(
            tooltip: l10n.gardenTooltipCalendar,
            icon: const Text('🗓️', style: TextStyle(fontSize: 17)),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const EmotionCalendarScreen(),
                ),
              );
            },
          ),
          _headerIcon(
            tooltip: l10n.gardenTooltipDiary,
            icon: const Text('📔', style: TextStyle(fontSize: 17)),
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const DiaryScreen()));
            },
          ),
          _headerIcon(
            tooltip: l10n.navSettings,
            icon: const Icon(
              Icons.settings_outlined,
              color: AppColors.ink,
              size: 18,
            ),
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
        ],),
      ]),
    );
  }

  /// 상단바 아이콘 버튼용 컴팩트 헬퍼. 아이콘이 5개나 늘어난 좁은 화면에서도
  /// 여백을 최소화해 한 줄에 자연스럽게 들어가도록 [IconButton]보다
  /// 패딩/최소 탭 영역을 살짝 줄여서 쓴다.
  Widget _headerIcon({
    required String tooltip,
    required Widget icon,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      tooltip: tooltip,
      icon: icon,
      onPressed: onPressed,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildSummaryCard(BuildContext context, GardenProvider garden) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            l10n.gardenSummaryFlowersPlanted(garden.totalFlowersPlanted),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _statItem(
                '🌱',
                l10n.gardenStatRecoveryLabel,
                l10n.gardenStatPercentValue((garden.progress * 100).round()),
              ),
              _statItem(
                '🐾',
                l10n.gardenStatMongiLabel,
                l10n.gardenStatStageValue(garden.stage),
              ),
              _statItem(
                '🔥',
                l10n.gardenStatStreakLabel,
                l10n.gardenStatStreakValue(garden.streakDays),
              ),
              _statItem(
                '✨',
                l10n.gardenStatScoreLabel,
                l10n.gardenStatScoreValue(garden.score),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildTreeGrowthHint(context, garden),
        ],
      ),
    );
  }

  /// 몽이의 성장나무 진행 상황을 알려주는 작은 안내 문구.
  /// "다음 성장까지 OO점 남았어요" 형태로 다음 단계까지의 거리를 보여준다.
  /// 정원을 이틀 이상 찾지 않아 나무가 살짝 시들었을 때는, 절대 다그치는
  /// 느낌이 들지 않도록 부드럽게 다시 찾아오길 권하는 문구로 바뀐다.
  Widget _buildTreeGrowthHint(BuildContext context, GardenProvider garden) {
    final l10n = AppLocalizations.of(context);
    final stageIndex = garden.treeStageIndex;
    final label = treeStageLabel(l10n, stageIndex);
    final remaining = garden.pointsToNextTreeStage;
    final isMaxStage = stageIndex >= TreeGrowth.maxStageIndex;
    final isWilted = garden.isTreeWilted;
    final String message;
    if (isWilted) {
      message = l10n.gardenTreeWiltedHint;
    } else if (isMaxStage) {
      message = l10n.gardenTreeMaxStageHint(label);
    } else {
      message = l10n.gardenTreeGrowthHint(label, remaining);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: (isWilted ? const Color(0xFFC9A87A) : const Color(0xFF7FB37A))
            .withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            stageIndex < 0 ? '🕳️' : (isWilted ? '🍂' : '🌳'),
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF3D5A3D),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String emoji, String label, String value) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            color: AppColors.ink,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.inkSoft),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Text('🌱', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(
            l10n.gardenEmptyTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.gardenEmptyBody,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.inkSoft,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlowerGrid(
    BuildContext context,
    GardenProvider garden,
    List<Emotion> emotions,
  ) {
    return Column(
      children: emotions.map((emotion) {
        final count = garden.flowerCounts[emotion.type.name] ?? 0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _FlowerBedCard(emotion: emotion, count: count),
        );
      }).toList(),
    );
  }
}

/// 감정 타입 하나에 해당하는 "꽃밭" 카드. 심어진 개수만큼 아이콘이 늘어난다.
class _FlowerBedCard extends StatelessWidget {
  final Emotion emotion;
  final int count;

  const _FlowerBedCard({required this.emotion, required this.count});

  @override
  Widget build(BuildContext context) {
    const maxShown = 10;
    final shown = count > maxShown ? maxShown : count;
    final overflow = count - shown;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: emotion.color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: emotion.color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Text(
              emotion.gardenIcon,
              style: const TextStyle(fontSize: 22),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      AppLocalizations.of(context).gardenFlowerBedTitle(
                        emotionLabel(
                          AppLocalizations.of(context),
                          emotion.type,
                        ),
                      ),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: emotion.color,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'x$count',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
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
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                    if (overflow > 0)
                      Text(
                        '+$overflow',
                        style: const TextStyle(
                          fontSize: 12,
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
