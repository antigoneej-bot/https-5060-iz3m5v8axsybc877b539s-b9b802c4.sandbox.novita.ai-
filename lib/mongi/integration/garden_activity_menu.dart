import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme.dart' show AppColors;
import '../providers/garden_provider.dart';
import '../widgets/garden_growth_share_sheet.dart';
import '../screens/diary_screen.dart';
import '../screens/emotion_calendar_screen.dart';
import '../screens/emotion_collection_screen.dart';
import '../screens/growth_milestone_screen.dart';
import '../screens/mind_report_screen.dart';

/// 정원 통합(마음냥 정원 + 몽이네 정원) 이후, 기존 "몽이네 정원" 화면
/// 상단에 흩어져 있던 6가지 기록·활동 바로가기(마음 리포트/감정 도감/
/// 성장 마일스톤/정원 공유/감정 캘린더/감정 다이어리)를 한 곳에 모아
/// 보여주는 공용 메뉴. 각 기능 자체의 화면/로직은 전혀 바꾸지 않고
/// 그대로 재사용한다 - 이 위젯은 순수하게 "어디서 무엇을 볼 수 있는지"
/// 보여주는 진입점 모음이다.
///
/// 구 "몽이네 정원"(GardenScreen)이 삭제되면서, 이 메뉴가 유일한
/// 진입점이 되므로 "나의 정원"(통합 화면) 상단 어디서든 눌러서 열 수
/// 있도록 버튼 하나로 제공한다.
class GardenActivityMenuButton extends StatelessWidget {
  const GardenActivityMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.78),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _showMenu(context),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🗂️', style: TextStyle(fontSize: 16)),
              SizedBox(width: 8),
              Text(
                '기록·활동',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                  color: AppColors.ink,
                ),
              ),
              SizedBox(width: 4),
              Icon(Icons.expand_more_rounded, size: 18, color: AppColors.ink),
            ],
          ),
        ),
      ),
    );
  }

  void _showMenu(BuildContext context) {
    final garden = context.read<GardenProvider>();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: .85,
        child: SingleChildScrollView(
          child: _GardenActivitySheet(garden: garden),
        ),
      ),
    );
  }
}

class _GardenActivitySheet extends StatelessWidget {
  final GardenProvider garden;
  const _GardenActivitySheet({required this.garden});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          color: AppColors.bg1,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 4),
              child: Row(
                children: [
                  Text('🗂️', style: TextStyle(fontSize: 18)),
                  SizedBox(width: 8),
                  Text(
                    '기록·활동',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            _tile(
              context,
              emoji: '💗',
              title: '마음 리포트',
              subtitle: '주간 리포트·마음 흐름·요일별 패턴을 한눈에',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MindReportScreen()),
              ),
            ),
            _tile(
              context,
              emoji: '📖',
              title: '감정 도감',
              subtitle: '지금까지 마주한 감정들을 모아보는 도감',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const EmotionCollectionScreen(),
                ),
              ),
            ),
            if (garden.isTreeFullyGrown)
              _tile(
                context,
                emoji: '🎬',
                title: '성장 마일스톤',
                subtitle: '몽이와 함께 자라온 순간을 돌아보는 다큐멘터리',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const GrowthMilestoneScreen(),
                  ),
                ),
              ),
            _tile(
              context,
              emoji: '📤',
              title: '정원 공유',
              subtitle: '지금까지 가꾼 정원을 카드로 만들어 공유하기',
              onTap: () => GardenGrowthShareSheet.show(
                context,
                stageIndex: garden.treeStageIndex,
                score: garden.score,
                streakDays: garden.streakDays,
                totalFlowersPlanted: garden.totalFlowersPlanted,
              ),
            ),
            _tile(
              context,
              emoji: '🗓️',
              title: '감정 캘린더',
              subtitle: '한 달간 마주한 감정을 히트맵으로 보기',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const EmotionCalendarScreen(),
                ),
              ),
            ),
            _tile(
              context,
              emoji: '📔',
              title: '감정 다이어리',
              subtitle: '스테이지를 마칠 때마다 남긴 한 줄 기록',
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const DiaryScreen())),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required String emoji,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Text(emoji, style: const TextStyle(fontSize: 20)),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14.5,
          color: AppColors.ink,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 11.5, color: AppColors.inkSoft),
      ),
      onTap: () {
        if (Navigator.of(context).canPop() && ModalRoute.of(context) != null) {
          Navigator.of(context).pop();
        }
        onTap();
      },
    );
  }
}
