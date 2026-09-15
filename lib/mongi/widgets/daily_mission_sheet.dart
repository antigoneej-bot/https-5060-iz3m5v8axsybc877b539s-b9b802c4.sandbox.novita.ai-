import '../../theme.dart' show AppColors;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/daily_mission_l10n.dart';
import '../l10n/gen/app_localizations.dart';
import '../models/daily_mission.dart';
import '../providers/garden_provider.dart';

/// 일일 미션 시트 - "오늘 이미 하고 있는 것"에 자연스럽게 보상을 얹어주는
/// 3종 고정 미션 + 올클리어 보너스를 보여준다. 처벌형이 아니라, 하면 할수록
/// 조금씩 더 받는 "보상 차등형" 설계를 그대로 UI에 옮긴 화면.
///
/// 홈 화면 배너에서 열리며, 진행 바 + "받기" 버튼으로 구성된 미션 카드
/// 3개와, 3개를 모두 수령하면 열리는 올클리어 보너스 카드를 보여준다.
void showDailyMissionSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const DailyMissionSheet(),
  );
}

class DailyMissionSheet extends StatefulWidget {
  const DailyMissionSheet({super.key});

  @override
  State<DailyMissionSheet> createState() => _DailyMissionSheetState();
}

class _DailyMissionSheetState extends State<DailyMissionSheet> {
  Future<void> _claim(DailyMissionDef mission) async {
    final l10n = AppLocalizations.of(context);
    final garden = context.read<GardenProvider>();
    final ok = await garden.claimDailyMission(mission);
    if (!ok || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.dailyMissionClaimedSnackbar(
            mission.emoji,
            mission.rewardLightEssence,
          ),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _claimAllClear() async {
    final l10n = AppLocalizations.of(context);
    final garden = context.read<GardenProvider>();
    final ok = await garden.claimDailyMissionAllClearBonus();
    if (!ok || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.dailyMissionAllClearSnackbar),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final garden = context.watch<GardenProvider>();
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(14),
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
        decoration: BoxDecoration(
          color: AppColors.bg0,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📋', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 8),
            Text(
              l10n.dailyMissionSheetLabel,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.inkSoft,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.dailyMissionSheetTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 16),
            ...DailyMission.all.map(
              (mission) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _MissionCard(
                  mission: mission,
                  progress: garden.dailyMissionProgressFor(mission),
                  achieved: garden.isDailyMissionAchieved(mission),
                  claimed: garden.isDailyMissionClaimed(mission),
                  onClaim: () => _claim(mission),
                  l10n: l10n,
                ),
              ),
            ),
            const SizedBox(height: 4),
            _AllClearCard(
              claimedCount: DailyMission.all
                  .where((m) => garden.isDailyMissionClaimed(m))
                  .length,
              totalCount: DailyMission.all.length,
              canClaim: garden.canClaimDailyMissionAllClearBonus,
              alreadyClaimed: garden.dailyMissionAllClearClaimed,
              onClaim: _claimAllClear,
              l10n: l10n,
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                l10n.commonCloseButton,
                style: const TextStyle(color: AppColors.inkSoft),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  final DailyMissionDef mission;
  final int progress;
  final bool achieved;
  final bool claimed;
  final VoidCallback onClaim;
  final AppLocalizations l10n;

  const _MissionCard({
    required this.mission,
    required this.progress,
    required this.achieved,
    required this.claimed,
    required this.onClaim,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = mission.target == 0
        ? 1.0
        : (progress / mission.target).clamp(0.0, 1.0);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: claimed ? const Color(0xFFE8F5E0) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: claimed
              ? const Color(0xFF4C7A44).withValues(alpha: 0.25)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Text(mission.emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dailyMissionLabel(l10n, mission),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 7,
                    backgroundColor: AppColors.catSageBg,
                    color: claimed
                        ? const Color(0xFF4C7A44)
                        : const Color(0xFFFF8FAB),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.dailyMissionProgressWithReward(
                    progress,
                    mission.target,
                    mission.rewardLightEssence,
                  ),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _trailingButton(),
        ],
      ),
    );
  }

  Widget _trailingButton() {
    if (claimed) {
      return const Icon(Icons.check_circle, color: Color(0xFF4C7A44), size: 26);
    }
    if (achieved) {
      return ElevatedButton(
        onPressed: onClaim,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF8FAB),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          minimumSize: Size.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          l10n.dailyMissionClaimButton,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
        ),
      );
    }
    return const Icon(Icons.lock_clock, color: Color(0xFFBBB0A6), size: 22);
  }
}

class _AllClearCard extends StatelessWidget {
  final int claimedCount;
  final int totalCount;
  final bool canClaim;
  final bool alreadyClaimed;
  final VoidCallback onClaim;
  final AppLocalizations l10n;

  const _AllClearCard({
    required this.claimedCount,
    required this.totalCount,
    required this.canClaim,
    required this.alreadyClaimed,
    required this.onClaim,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: alreadyClaimed
              ? [const Color(0xFFE8F5E0), const Color(0xFFDCEFD2)]
              : [const Color(0xFFFFE0A3), const Color(0xFFFFC98F)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Text('🎁', style: TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.dailyMissionAllClearCardTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: Color(0xFF6B4A16),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  alreadyClaimed
                      ? l10n.dailyMissionAllClearAlreadyClaimed
                      : l10n.dailyMissionAllClearProgress(
                          claimedCount,
                          totalCount,
                          DailyMission.allClearBonusLightEssence,
                          DailyMission.allClearBonusStarShard,
                        ),
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8A5A1F),
                  ),
                ),
              ],
            ),
          ),
          if (alreadyClaimed)
            const Icon(Icons.check_circle, color: Color(0xFF4C7A44), size: 26)
          else
            ElevatedButton(
              onPressed: canClaim ? onClaim : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B4A16),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.black.withValues(alpha: 0.15),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                l10n.dailyMissionClaimButton,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
