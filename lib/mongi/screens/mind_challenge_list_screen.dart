import '../../theme.dart' show AppColors;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/gen/app_localizations.dart';
import '../l10n/mind_challenge_l10n.dart';
import '../models/mind_challenge.dart';
import '../providers/garden_provider.dart';
import 'mind_challenge_detail_screen.dart';

/// "마음 챌린지" 테마 목록 화면 - Finch "Goal Journeys" 벤치마킹.
///
/// 시즌 패스("몽이의 마음여정")와는 이름/개념이 겹치지 않도록 "챌린지"라는
/// 용어를 쓴다. 테마 하나를 골라 시작하면, 매일 홈 화면의 "오늘의 감정
/// 체크인"을 하는 것만으로 하루씩 자연스럽게 진행된다(새로운 강제 행동을
/// 요구하지 않는다).
class MindChallengeListScreen extends StatelessWidget {
  const MindChallengeListScreen({super.key});

  Future<void> _onTapChallenge(
    BuildContext context,
    MindChallengeDef def,
  ) async {
    final l10n = AppLocalizations.of(context);
    final garden = context.read<GardenProvider>();
    final activeId = garden.mindChallengeActiveId;

    if (activeId == def.id) {
      // 이미 이 챌린지가 진행 중이면 바로 상세 화면으로.
      if (!context.mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const MindChallengeDetailScreen()),
      );
      return;
    }

    final hasOtherActive = activeId != null;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.mindChallengeStartConfirmTitle),
        content: Text(
          hasOtherActive
              ? l10n.mindChallengeStartConfirmReplaceBody
              : l10n.mindChallengeStartConfirmBody(def.durationDays),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCloseButton),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF7FB37A),
            ),
            child: Text(l10n.mindChallengeStartConfirmButton),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await garden.startMindChallenge(def.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.mindChallengeStartedSnackbar(mindChallengeTitle(l10n, def)),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MindChallengeDetailScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final garden = context.watch<GardenProvider>();

    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        backgroundColor: AppColors.bg0,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l10n.mindChallengeListAppBarTitle,
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
          Text(
            l10n.mindChallengeListHeadline,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.mindChallengeListSubtitle,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.inkSoft,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          ...MindChallenge.all.map((def) {
            final isActive = garden.mindChallengeActiveId == def.id;
            final isCompleted = garden.mindChallengeCompletedIds.contains(
              def.id,
            );
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ChallengeCard(
                l10n: l10n,
                def: def,
                isActive: isActive,
                isCompleted: isCompleted,
                onTap: () => _onTapChallenge(context, def),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final AppLocalizations l10n;
  final MindChallengeDef def;
  final bool isActive;
  final bool isCompleted;
  final VoidCallback onTap;

  const _ChallengeCard({
    required this.l10n,
    required this.def,
    required this.isActive,
    required this.isCompleted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? const Color(0xFF7FB37A)
                : Colors.black.withValues(alpha: 0.06),
            width: isActive ? 1.8 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(def.emoji, style: const TextStyle(fontSize: 30)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          mindChallengeTitle(l10n, def),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      if (isActive)
                        _badge(
                          l10n.mindChallengeCardInProgressBadge,
                          const Color(0xFF7FB37A),
                        )
                      else if (isCompleted)
                        _badge(
                          l10n.mindChallengeCardCompletedBadge,
                          const Color(0xFFA36BE0),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    mindChallengeDescription(l10n, def),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.inkSoft,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.catSageBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          l10n.mindChallengeCardDurationLabel(def.durationDays),
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF8A7F76),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        isActive
                            ? l10n.mindChallengeCardContinueButton
                            : l10n.mindChallengeCardStartButton,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF7FB37A),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: Color(0xFF7FB37A),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 10,
        ),
      ),
    );
  }
}
