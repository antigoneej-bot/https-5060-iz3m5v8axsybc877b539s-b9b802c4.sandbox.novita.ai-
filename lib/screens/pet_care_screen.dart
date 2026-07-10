import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cat_care_provider.dart';
import '../theme.dart';
import '../data/shadow_cats_data.dart';
import '../models/shadow_cat.dart';
import '../models/cat_care_state.dart';
import '../utils/korean_particle.dart';
import '../widgets/animated_cat_art.dart';
import '../widgets/garden_path_card.dart';

/// 마음 돌보기 (다마고치식) - 매일 몸(밥/물/목욕/청소)과 마음(호흡명상/걷기명상/
/// 마음기록/감사쓰기)을 함께 돌보며 나의 그림자 고양이를 키우고 마음 온도를
/// 유지하는 화면. 하루라도 돌보지 않으면 온도가 1도씩 내려갑니다.
/// 처음엔 아기 고양이로 시작해서, 정성껏 돌본 날이 쌓일수록 청년을 거쳐
/// 내가 고른 그림자 고양이의 모습으로 다 자라납니다.
/// '힐링 정원' 컨셉에 맞춰 딱딱한 흰 사각 박스를 모두 걷어내고, 반투명
/// 파스텔 블롭(GlassBlob)과 알약형 돌봄 카드로 다시 꾸몄습니다.
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
        child: Center(
          child: CircularProgressIndicator(color: AppColors.blobMintAccent),
        ),
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
          style: titleFont(fontSize: 24, color: AppColors.ink),
        ),
        const SizedBox(height: 6),
        Text(
          '몸과 마음을 함께 돌보며 $name${topicParticle(name)} 마음 온도를 지켜주세요',
          textAlign: TextAlign.center,
          style: bodyFont(fontSize: 12.5, color: AppColors.inkSoft),
        ),
        const SizedBox(height: 22),
        _CompanionCard(cat: companion, state: care.state, name: name),
        const SizedBox(height: 30),
        _CareSectionSignpost(
          emoji: '🐾',
          title: '몸을 돌보기',
          subtitle: '$name${subjectParticle(name)} 건강하게 지낼 수 있도록 챙겨주세요',
        ),
        const SizedBox(height: 12),
        _CareTaskTile(
          emoji: '🍚',
          label: '밥 주기',
          done: care.state.fedToday,
          seed: 1,
          onTap: care.state.fedToday
              ? null
              : () => context.read<CatCareProvider>().feed(),
        ),
        const SizedBox(height: 10),
        _CareTaskTile(
          emoji: '💧',
          label: '물 주기',
          done: care.state.wateredToday,
          seed: 2,
          onTap: care.state.wateredToday
              ? null
              : () => context.read<CatCareProvider>().water(),
        ),
        const SizedBox(height: 10),
        _CareTaskTile(
          emoji: '🛁',
          label: '목욕 시키기',
          done: care.state.bathedToday,
          seed: 3,
          onTap: care.state.bathedToday
              ? null
              : () => context.read<CatCareProvider>().bath(),
        ),
        const SizedBox(height: 10),
        _CareTaskTile(
          emoji: '🧹',
          label: '집 청소하기',
          done: care.state.cleanedToday,
          seed: 4,
          onTap: care.state.cleanedToday
              ? null
              : () => context.read<CatCareProvider>().clean(),
        ),
        const SizedBox(height: 28),
        _CareSectionSignpost(
          emoji: '🦋',
          title: '마음을 돌보기',
          subtitle: '당신의 마음을 돌보는 것이 곧 $name${topicParticle(name)} 돌보는 일이에요',
        ),
        const SizedBox(height: 12),
        _CareTaskTile(
          emoji: '🌬',
          label: '5분 호흡 명상',
          done: care.state.breathingDoneToday,
          seed: 5,
          onTap: care.state.breathingDoneToday
              ? null
              : () => context.read<CatCareProvider>().breathing(),
        ),
        const SizedBox(height: 10),
        _CareTaskTile(
          emoji: '🚶',
          label: '걷기 명상',
          done: care.state.walkingDoneToday,
          seed: 6,
          onTap: care.state.walkingDoneToday
              ? null
              : () => context.read<CatCareProvider>().walking(),
        ),
        const SizedBox(height: 10),
        _CareTaskTile(
          emoji: '📖',
          label: '오늘의 마음 기록',
          done: care.state.journalingDoneToday,
          seed: 7,
          onTap: care.state.journalingDoneToday
              ? null
              : () => context.read<CatCareProvider>().journaling(),
        ),
        const SizedBox(height: 10),
        _CareTaskTile(
          emoji: '❤️',
          label: '감사 3가지 쓰기',
          done: care.state.gratitudeDoneToday,
          seed: 8,
          onTap: care.state.gratitudeDoneToday
              ? null
              : () => context.read<CatCareProvider>().gratitude(),
        ),
        const SizedBox(height: 22),
        if (care.state.allDoneToday)
          GlassBlob(
            accent: AppColors.blobButterAccent,
            background: AppColors.blobButter,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                const Text('🎉', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '오늘 돌봄을 모두 마쳤어요! 마음 온도가 올라갔어요.',
                    style: pathLabelFont(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          GlassBlob(
            accent: AppColors.blobLavenderAccent,
            background: AppColors.blobLavender,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.blobLavenderAccent,
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

/// 섹션 사이, 오솔길 팻말처럼 손글씨 폰트로 안내하는 작은 표지판.
class _CareSectionSignpost extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  const _CareSectionSignpost({
    required this.emoji,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: pathLabelFont(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: bodyFont(fontSize: 11.5, color: AppColors.inkSoft),
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
        return AppColors.blobPeachAccent;
      case CatMoodState.calm:
        return AppColors.blobButterAccent;
      case CatMoodState.tired:
        return const Color(0xFF7C93B8);
      case CatMoodState.recovering:
        return AppColors.blobMintAccent;
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
    return GlassBlob(
      accent: AppColors.blobPeachAccent,
      background: AppColors.blobPeach,
      padding: const EdgeInsets.all(20),
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
                    color: Colors.white.withValues(alpha: 0.75),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.blobPeachAccent.withValues(alpha: 0.3),
                    ),
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: AppColors.blobPeachAccent.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              stage == CatGrowthStage.adult
                  ? '🌟 ${state.growthStageLabel}'
                  : state.growthStageLabel,
              style: bodyFont(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.blobPeachAccent,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            displayName,
            style: titleFont(fontSize: 19, color: AppColors.ink),
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
              style: bodyFont(
                fontSize: 11,
                color: AppColors.blobPeachAccent,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(18),
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
                        style: pathLabelFont(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _tempColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${state.temperature}°',
                  style: numberFont(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _tempColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: (state.temperature / 100).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.5),
              valueColor: AlwaysStoppedAnimation(_tempColor),
            ),
          ),
        ],
      ),
    );
  }
}

/// 돌봄 항목 하나 - 딱딱한 흰 사각 박스 대신, 살짝 비대칭인 유기적 알약형
/// 카드로 표현합니다. 마우스를 올리면 나뭇잎처럼 살짝 흔들리고, 완료된
/// 항목은 부드러운 민트 톤으로 물들어 은은하게 표시됩니다.
class _CareTaskTile extends StatefulWidget {
  final String emoji;
  final String label;
  final bool done;
  final VoidCallback? onTap;
  final int seed;
  const _CareTaskTile({
    required this.emoji,
    required this.label,
    required this.done,
    required this.onTap,
    required this.seed,
  });

  @override
  State<_CareTaskTile> createState() => _CareTaskTileState();
}

class _CareTaskTileState extends State<_CareTaskTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hoverController;
  bool _hovering = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  void _setHover(bool v) {
    if (widget.onTap == null || _hovering == v) return;
    setState(() => _hovering = v);
    if (v) {
      _hoverController.forward();
    } else {
      _hoverController.reverse();
    }
  }

  BorderRadius _blobRadius() {
    final rng = Random(widget.seed * 23 + 11);
    double r(double base) => base + rng.nextDouble() * 10;
    return BorderRadius.only(
      topLeft: Radius.circular(r(22)),
      topRight: Radius.circular(r(18)),
      bottomLeft: Radius.circular(r(18)),
      bottomRight: Radius.circular(r(26)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.done
        ? AppColors.blobMintAccent
        : AppColors.blobLavenderAccent;
    final background = widget.done ? AppColors.blobMint : AppColors.blobLavender;
    final radius = _blobRadius();
    return AnimatedBuilder(
      animation: _hoverController,
      builder: (context, child) {
        final t = _hoverController.value;
        final wiggle = sin(t * pi * 3) * 0.03 * t;
        final scale = 1.0 + t * 0.02;
        return Transform.rotate(
          angle: wiggle,
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: MouseRegion(
        onEnter: (_) => _setHover(true),
        onExit: (_) => _setHover(false),
        cursor: widget.onTap == null
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        child: GestureDetector(
          onTapDown: (_) => _setHover(true),
          onTapCancel: () => _setHover(false),
          onTapUp: (_) => _setHover(false),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  background.withValues(alpha: widget.done ? 0.82 : 0.62),
                  background.withValues(alpha: widget.done ? 0.55 : 0.38),
                ],
              ),
              border: Border.all(
                color: accent.withValues(alpha: _hovering ? 0.5 : 0.24),
                width: 1.1,
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: _hovering ? 0.2 : 0.1),
                  blurRadius: _hovering ? 18 : 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Text(widget.emoji, style: const TextStyle(fontSize: 21)),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    widget.label,
                    style: pathLabelFont(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                Icon(
                  widget.done
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: accent,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
