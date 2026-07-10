import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cat_care_provider.dart';
import '../theme.dart';
import '../data/shadow_cats_data.dart';
import '../models/shadow_cat.dart';
import '../models/cat_care_state.dart';
import '../utils/korean_particle.dart';
import '../widgets/animated_cat_art.dart';

/// 마음 돌보기 (다마고치식) - 매일 몸(밥/물/목욕/청소)과 마음(호흡명상/걷기명상/
/// 마음기록/감사쓰기)을 함께 돌보며 나의 그림자 고양이를 키우고 마음 온도를
/// 유지하는 화면. 하루라도 돌보지 않으면 온도가 1도씩 내려갑니다.
/// 처음엔 아기 고양이로 시작해서, 정성껏 돌본 날이 쌓일수록 청년을 거쳐
/// 내가 고른 그림자 고양이의 모습으로 다 자라납니다.
class PetCareScreen extends StatefulWidget {
  const PetCareScreen({super.key});

  @override
  State<PetCareScreen> createState() => _PetCareScreenState();
}

class _PetCareScreenState extends State<PetCareScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CatCareProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final care = context.watch<CatCareProvider>();

    if (care.isLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: 80),
        child: Center(child: CircularProgressIndicator(color: AppColors.gold)),
      );
    }

    ShadowCat companion;
    try {
      companion = shadowCatById(care.state.companionCatId);
    } catch (_) {
      companion = shadowCats.first;
    }
    final name = care.displayName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '마음 돌보기',
          textAlign: TextAlign.center,
          style: serifFont(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '몸과 마음을 함께 돌보며 $name${topicParticle(name)} 마음 온도를 지켜주세요',
          textAlign: TextAlign.center,
          style: bodyFont(fontSize: 12.5, color: AppColors.inkSoft),
        ),
        const SizedBox(height: 22),
        _CompanionCard(cat: companion, state: care.state, name: name),
        const SizedBox(height: 24),
        Text(
          '몸을 돌보기',
          style: serifFont(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$name${subjectParticle(name)} 건강하게 지낼 수 있도록 챙겨주세요',
          style: bodyFont(fontSize: 11.5, color: AppColors.inkSoft),
        ),
        const SizedBox(height: 12),
        _CareTaskTile(
          emoji: '🍚',
          label: '밥 주기',
          done: care.state.fedToday,
          onTap: care.state.fedToday
              ? null
              : () => context.read<CatCareProvider>().feed(),
        ),
        const SizedBox(height: 10),
        _CareTaskTile(
          emoji: '💧',
          label: '물 주기',
          done: care.state.wateredToday,
          onTap: care.state.wateredToday
              ? null
              : () => context.read<CatCareProvider>().water(),
        ),
        const SizedBox(height: 10),
        _CareTaskTile(
          emoji: '🛁',
          label: '목욕 시키기',
          done: care.state.bathedToday,
          onTap: care.state.bathedToday
              ? null
              : () => context.read<CatCareProvider>().bath(),
        ),
        const SizedBox(height: 10),
        _CareTaskTile(
          emoji: '🧹',
          label: '집 청소하기',
          done: care.state.cleanedToday,
          onTap: care.state.cleanedToday
              ? null
              : () => context.read<CatCareProvider>().clean(),
        ),
        const SizedBox(height: 24),
        Text(
          '마음을 돌보기',
          style: serifFont(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '당신의 마음을 돌보는 것이 곧 $name${topicParticle(name)} 돌보는 일이에요',
          style: bodyFont(fontSize: 11.5, color: AppColors.inkSoft),
        ),
        const SizedBox(height: 12),
        _CareTaskTile(
          emoji: '🌬',
          label: '5분 호흡 명상',
          done: care.state.breathingDoneToday,
          onTap: care.state.breathingDoneToday
              ? null
              : () => context.read<CatCareProvider>().breathing(),
        ),
        const SizedBox(height: 10),
        _CareTaskTile(
          emoji: '🚶',
          label: '걷기 명상',
          done: care.state.walkingDoneToday,
          onTap: care.state.walkingDoneToday
              ? null
              : () => context.read<CatCareProvider>().walking(),
        ),
        const SizedBox(height: 10),
        _CareTaskTile(
          emoji: '📖',
          label: '오늘의 마음 기록',
          done: care.state.journalingDoneToday,
          onTap: care.state.journalingDoneToday
              ? null
              : () => context.read<CatCareProvider>().journaling(),
        ),
        const SizedBox(height: 10),
        _CareTaskTile(
          emoji: '❤️',
          label: '감사 3가지 쓰기',
          done: care.state.gratitudeDoneToday,
          onTap: care.state.gratitudeDoneToday
              ? null
              : () => context.read<CatCareProvider>().gratitude(),
        ),
        const SizedBox(height: 18),
        if (care.state.allDoneToday)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.bg2,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              children: [
                const Text('🎉', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '오늘 돌봄을 모두 마쳤어요! 마음 온도가 올라갔어요.',
                    style: bodyFont(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.bg1,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.inkSoft,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '오늘의 돌봄 ${care.state.completedCountToday}/8 · 하루라도 돌보지 않으면 마음 온도가 내려가요.',
                    style: bodyFont(fontSize: 11.5, color: AppColors.inkSoft),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _CompanionCard extends StatelessWidget {
  final ShadowCat cat;
  final CatCareState state;
  final String name;
  const _CompanionCard({
    required this.cat,
    required this.state,
    required this.name,
  });

  Color get _tempColor {
    switch (state.moodState) {
      case CatMoodState.warm:
        return AppColors.gold;
      case CatMoodState.calm:
        return AppColors.goldSoft;
      case CatMoodState.tired:
        return const Color(0xFF7C93B8);
      case CatMoodState.recovering:
        return AppColors.catSage;
    }
  }

  /// 성장 단계에 따라 보여줄 이미지 - 아기/청년 단계에서는 공용 성장 아트를,
  /// 다 자란 단계에서는 사용자가 실제로 키우고 있는 그림자 고양이 모습을 보여줍니다.
  String get _stageImageAsset {
    switch (state.growthStage) {
      case CatGrowthStage.baby:
        return 'assets/growth/baby_cat.png';
      case CatGrowthStage.young:
        return 'assets/growth/young_cat.png';
      case CatGrowthStage.adult:
        return cat.imageAsset;
    }
  }

  @override
  Widget build(BuildContext context) {
    final stage = state.growthStage;
    final daysLeft = state.daysUntilNextStage;
    final displayName = stage == CatGrowthStage.adult ? cat.nameKr : name;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bg1,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            clipBehavior: Clip.none,
            children: [
              AnimatedCatArt(imageAsset: _stageImageAsset, size: 140),
              Positioned(
                right: -4,
                bottom: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Text(
                    state.moodEmoji,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.bg2,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              stage == CatGrowthStage.adult
                  ? '🌟 ${state.growthStageLabel}'
                  : state.growthStageLabel,
              style: bodyFont(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.goldSoft,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            displayName,
            style: serifFont(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$displayName${topicParticle(displayName)} 오늘 ${state.moodLabel}',
            style: bodyFont(fontSize: 12.5, color: AppColors.inkSoft),
          ),
          if (daysLeft != null) ...[
            const SizedBox(height: 4),
            Text(
              '$displayName${topicParticle(displayName)} $daysLeft일 더 정성껏 돌보면 다음 단계로 자라나요',
              style: bodyFont(fontSize: 11, color: AppColors.goldSoft),
            ),
          ],
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.bg0,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Text(state.moodEmoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '마음 온도',
                        style: bodyFont(fontSize: 11, color: AppColors.moon),
                      ),
                      Text(
                        state.moodLabel,
                        style: serifFont(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: _tempColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${state.temperature}°',
                  style: serifFont(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _tempColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: (state.temperature / 100).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: AppColors.bg0,
              valueColor: AlwaysStoppedAnimation(_tempColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _CareTaskTile extends StatelessWidget {
  final String emoji;
  final String label;
  final bool done;
  final VoidCallback? onTap;
  const _CareTaskTile({
    required this.emoji,
    required this.label,
    required this.done,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: done ? AppColors.bg2 : AppColors.bg1,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: bodyFont(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
              ),
              if (done)
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.gold,
                  size: 24,
                )
              else
                const Icon(
                  Icons.radio_button_unchecked_rounded,
                  color: AppColors.inkSoft,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
