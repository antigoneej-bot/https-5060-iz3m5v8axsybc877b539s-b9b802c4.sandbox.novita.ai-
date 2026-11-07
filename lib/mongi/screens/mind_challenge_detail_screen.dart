import '../../theme.dart' show AppColors;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/gen/app_localizations.dart';
import '../l10n/mind_challenge_l10n.dart';
import '../models/mind_challenge.dart';
import '../providers/garden_provider.dart';

/// 진행 중인 "마음 챌린지" 상세/진행 화면.
///
/// 오늘 며칠차인지, 오늘 체크인을 했는지, 지금까지 몇 일을 채웠는지를
/// 보여주고, 모든 날짜를 채우면 완주 보상을 수령할 수 있는 버튼이 나타난다.
/// 실제 "오늘 할 일"은 이 화면이 아니라 홈 화면의 감정 체크인에서 이뤄지므로,
/// 이 화면은 진행 상황을 보여주고 격려하는 역할에 집중한다.
class MindChallengeDetailScreen extends StatefulWidget {
  const MindChallengeDetailScreen({super.key});

  @override
  State<MindChallengeDetailScreen> createState() =>
      _MindChallengeDetailScreenState();
}

class _MindChallengeDetailScreenState extends State<MindChallengeDetailScreen> {
  Future<void> _claimCompletion() async {
    final l10n = AppLocalizations.of(context);
    final garden = context.read<GardenProvider>();
    final ok = await garden.claimMindChallengeCompletion();
    if (!ok || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.mindChallengeDetailCompletedSnackbar),
        duration: const Duration(seconds: 2),
      ),
    );
    Navigator.of(context).pop();
  }

  Future<void> _abandon() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.mindChallengeDetailAbandonConfirmTitle),
        content: Text(l10n.mindChallengeDetailAbandonConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCloseButton),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE0A93A),
            ),
            child: Text(l10n.mindChallengeDetailAbandonConfirmButton),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<GardenProvider>().abandonMindChallenge();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final garden = context.watch<GardenProvider>();
    final def = garden.activeMindChallenge;

    if (def == null) {
      // 방어적 처리: 다른 경로로 챌린지가 끝난 상태에서 이 화면이 남아있는
      // 경우, 조용히 뒤로 보낸다.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    final daysDone = garden.mindChallengeDaysDone;
    final todayIndex = (daysDone + 1).clamp(1, def.durationDays);
    final checkedToday = garden.hasCheckedInMindChallengeToday;
    final canComplete = garden.canCompleteMindChallenge;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F9F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F9F0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l10n.mindChallengeDetailAppBarTitle,
          style: const TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          _buildHeaderCard(l10n, def, daysDone),
          const SizedBox(height: 16),
          _buildTodayCard(l10n, def, todayIndex, checkedToday, canComplete),
          const SizedBox(height: 16),
          _buildRewardInfoCard(l10n, def),
          const SizedBox(height: 24),
          TextButton(
            onPressed: _abandon,
            child: Text(
              l10n.mindChallengeDetailAbandonButton,
              style: const TextStyle(color: AppColors.inkSoft),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(
    AppLocalizations l10n,
    MindChallengeDef def,
    int daysDone,
  ) {
    final ratio = def.durationDays == 0
        ? 1.0
        : (daysDone / def.durationDays).clamp(0.0, 1.0);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFDCEFD2), Color(0xFFC3E4B4)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(def.emoji, style: const TextStyle(fontSize: 34)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  mindChallengeTitle(l10n, def),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: Color(0xFF3A5A34),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.55),
              color: const Color(0xFF4C7A44),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.mindChallengeDetailProgressLabel(daysDone, def.durationDays),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4C7A44),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayCard(
    AppLocalizations l10n,
    MindChallengeDef def,
    int todayIndex,
    bool checkedToday,
    bool canComplete,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (canComplete) ...[
            Text(
              l10n.mindChallengeDetailCompleteReadyTitle,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _claimCompletion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4C7A44),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  l10n.mindChallengeDetailCompleteButton,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ] else ...[
            Text(
              l10n.mindChallengeDetailDayLabel(todayIndex, def.durationDays),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
                color: Color(0xFF7FB37A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              mindChallengeDailyPrompt(l10n, def, todayIndex),
              style: const TextStyle(
                fontSize: 14.5,
                color: AppColors.ink,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(
                  checkedToday ? Icons.check_circle : Icons.circle_outlined,
                  size: 18,
                  color: checkedToday
                      ? const Color(0xFF4C7A44)
                      : const Color(0xFFBBB0A6),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    checkedToday
                        ? l10n.mindChallengeDetailCheckedInToday
                        : l10n.mindChallengeDetailNotCheckedInYet,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: checkedToday
                          ? const Color(0xFF4C7A44)
                          : AppColors.inkSoft,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRewardInfoCard(AppLocalizations l10n, MindChallengeDef def) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3D6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.mindChallengeDetailDayRewardLabel(
              def.rewardLightEssencePerDay,
            ),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF8A5A1F),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.mindChallengeDetailCompletionRewardLabel(
              def.completionBonusLightEssence,
              def.completionBonusStarShard,
            ),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF8A5A1F),
            ),
          ),
        ],
      ),
    );
  }
}
