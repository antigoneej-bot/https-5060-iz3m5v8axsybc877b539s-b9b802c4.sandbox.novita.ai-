import '../../theme.dart' show AppColors;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/breathing_technique_l10n.dart';
import '../l10n/gen/app_localizations.dart';
import '../models/breathing_technique.dart';
import '../providers/garden_provider.dart';
import '../widgets/breathing_interstitial.dart';

/// "몽이의 숨결 도감" - 가이드 호흡/명상 미니 라이브러리(벤치마킹 제안 #5,
/// Calm/Headspace 벤치마킹).
///
/// 지금까지 [BreathingInterstitial]은 게임이 끝난 뒤에만 자동으로(또는 홈
/// 배지에서 기본 호흡 하나만) 재생할 수 있었다. 이 화면은 상황에 맞는 여러
/// 호흡 기법(불안할 때/집중할 때/잠들기 전 등)을 직접 골라서, 게임과 전혀
/// 무관하게 언제든 시작할 수 있게 한다. 어떤 기법을 고르든 재생 엔진은
/// 동일한 [BreathingInterstitial]을 재사용한다.
class BreathingLibraryScreen extends StatefulWidget {
  const BreathingLibraryScreen({super.key});

  @override
  State<BreathingLibraryScreen> createState() => _BreathingLibraryScreenState();
}

class _BreathingLibraryScreenState extends State<BreathingLibraryScreen> {
  Future<void> _onTapTechnique(BreathingTechniqueDef def) async {
    final garden = context.read<GardenProvider>();
    final completed = await BreathingInterstitial.show(context, technique: def);
    if (!completed || !mounted) return;

    final reward = await garden.completeBreathingTechnique(def);
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          reward > 0
              ? l10n.breathingLibraryRewardSnackbar(reward)
              : l10n.breathingLibraryNoRewardSnackbar,
        ),
        duration: const Duration(seconds: 2),
      ),
    );
    setState(() {});
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
          l10n.breathingLibraryHeaderTitle,
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
            l10n.breathingLibrarySubtitle,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.inkSoft,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          ...BreathingTechnique.all.map((def) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _TechniqueCard(
                l10n: l10n,
                def: def,
                completedTodayReward: garden.hasBreathingRewardToday,
                onTap: () => _onTapTechnique(def),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _TechniqueCard extends StatelessWidget {
  final AppLocalizations l10n;
  final BreathingTechniqueDef def;

  /// 오늘 이미 (다른 기법이든 이 기법이든) 호흡 보상을 받았는지 여부 -
  /// true면 이 카드에도 "오늘 완료" 뱃지 대신 보상 힌트를 숨긴다.
  final bool completedTodayReward;
  final VoidCallback onTap;

  const _TechniqueCard({
    required this.l10n,
    required this.def,
    required this.completedTodayReward,
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
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
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
                          breathingTechniqueName(l10n, def),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      if (completedTodayReward)
                        _badge(
                          l10n.breathingLibraryCompletedTodayBadge,
                          const Color(0xFF7FB37A),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    breathingTechniqueDescription(l10n, def),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.inkSoft,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
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
                          l10n.breathingLibraryDurationLabel(def.totalSeconds),
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF8A7F76),
                          ),
                        ),
                      ),
                      if (!completedTodayReward)
                        Text(
                          l10n.breathingLibraryRewardHint(
                            def.rewardLightEssence,
                          ),
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFE0A23A),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Spacer(),
                      Text(
                        l10n.breathingLibraryStartButton,
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
