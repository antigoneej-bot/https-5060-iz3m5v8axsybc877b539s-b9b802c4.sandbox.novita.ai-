import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cat_care_provider.dart';
import '../theme.dart';
import '../data/shadow_cats_data.dart';
import '../models/shadow_cat.dart';
import '../models/cat_care_state.dart';
import '../data/cat_flavor_text.dart';
import '../models/cat_accessory.dart';
import '../utils/korean_particle.dart';
import '../models/cat_achievement.dart';
import '../widgets/achievement_unlocked_overlay.dart';
import '../widgets/animated_adult_cat.dart';
import '../widgets/animated_cat_art.dart';
import '../widgets/animated_teen_cat.dart';
import '../widgets/feature_scaffold.dart';
import '../widgets/garden_path_card.dart';
import '../widgets/level_up_overlay.dart';
import '../widgets/mochi_cat.dart';
import '../widgets/weather_reactive_cat.dart';
import '../providers/app_state_provider.dart';
import '../services/sound_service.dart';
import 'cat_achievements_screen.dart';
import 'cat_graduation_screens.dart';
import 'cat_shop_screen.dart';

/// 🐛 모찌 결석 감정 디버그 패널을 노출할지 여부.
/// ⚠️ 실제 스토어 출시 전에는 반드시 false로 바꿔주세요(또는 이 패널과
/// [_MochiEmotionDebugPanel] 위젯을 통째로 제거해주세요). release 빌드에서도
/// (테스트 목적상) 항상 true로 노출되도록 [kDebugMode]를 쓰지 않았습니다.
const bool kShowMochiDebugPanel = true;

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

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        _buildBody(care, companion, name),
        if (care.justReachedStage != null)
          LevelUpOverlay(
            stage: care.justReachedStage!,
            companionName: name,
            imageAsset: _CompanionCard.imageAssetFor(
              care.justReachedStage!,
              companion,
            ),
            onDismiss: () => context.read<CatCareProvider>().clearLevelUp(),
          ),
        if (care.justReachedStage == null && care.newlyUnlockedQueue.isNotEmpty)
          AchievementUnlockedOverlay(
            key: ValueKey(care.newlyUnlockedQueue.first.id),
            achievement: care.newlyUnlockedQueue.first,
            onDismiss: () =>
                context.read<CatCareProvider>().dequeueNewAchievement(),
          ),
      ],
    );
  }

  void _openShop(BuildContext context) {
    pushFullScreen(context, '정원 플러스 상점', const CatShopScreen());
  }

  void _openAchievements(BuildContext context) {
    pushFullScreen(context, '뱃지 컬렉션', const CatAchievementsScreen());
  }

  void _openGraduationAlbum(BuildContext context) {
    pushFullScreen(context, '졸업 앨범', const GraduationAlbumScreen());
  }

  Future<void> _startGraduation(BuildContext context, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '$name${topicParticle(name)} 졸업시킬까요?',
          style: pathLabelFont(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        content: Text(
          '다 자란 $name는 졸업 앨범에 기록되고,\n새 아기고양이와 처음부터 다시 키우게 돼요.\n(포인트는 그대로 유지돼요)',
          style: bodyFont(
            fontSize: 12.5,
            color: AppColors.inkSoft,
            height: 1.6,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('다음에'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('졸업시키기'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      pushFullScreen(context, '새 아기고양이', const NewBabyPickerScreen());
    }
  }

  Widget _buildBody(CatCareProvider care, ShadowCat companion, String name) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MochiGreetingHero(name: name),
        const SizedBox(height: 18),
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
        _CompanionCard(
          cat: companion,
          state: care.state,
          name: name,
          debugGrowthDays: care.debugGrowthDaysOverride,
          equippedAccessories: care.equippedBySlot.values
              .map(catAccessoryById)
              .whereType<CatAccessory>()
              .toList(),
          onGraduate: care.effectiveGrowthStage == CatGrowthStage.adult
              ? () => _startGraduation(context, name)
              : null,
        ),
        const SizedBox(height: 14),
        _PointsBadge(
          points: care.points,
          isPremium: care.isPremium,
          onOpenShop: () => _openShop(context),
        ),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: () => _openGraduationAlbum(context),
          child: GlassBlob(
            accent: AppColors.gold,
            background: const Color(0xFFFCEFD2),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                const Text('🎓', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '졸업 앨범',
                        style: pathLabelFont(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        // ⚠️ 유료(Basic 구독) 10마리는 육성 대상에서 제외되어
                        // 있어 shadowCats.length(52)를 분모로 쓰면 영원히
                        // 채울 수 없는 목표가 됩니다. 무료 42마리 기준으로 표시합니다.
                        '${care.graduatedCats.length} / ${freeShadowCats.length}마리를 졸업시켰어요',
                        style: bodyFont(
                          fontSize: 10.5,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.goldSoft,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: () => _openAchievements(context),
          child: GlassBlob(
            accent: AppColors.blobButterAccent,
            background: AppColors.blobButter,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                const Text('🎖️', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '뱃지 컬렉션',
                        style: pathLabelFont(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        '${care.unlockedAchievementIds.length} / ${catAchievements.length}개 달성했어요',
                        style: bodyFont(
                          fontSize: 10.5,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.blobButterAccent,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (care.ownedAccessoryIds.any(
          (id) => catAccessoryById(id)?.type == CatItemType.furniture,
        )) ...[
          const SizedBox(height: 14),
          _FurnitureRoomBlob(
            furniture: care.ownedAccessoryIds
                .map(catAccessoryById)
                .whereType<CatAccessory>()
                .where((a) => a.type == CatItemType.furniture)
                .toList(),
          ),
        ],
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
          subtitle: care.state.breathingDoneToday
              ? null
              : '편지쓰기에서 호흡 명상을 실천하면 자동으로 체크돼요',
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
          subtitle: care.state.walkingDoneToday
              ? null
              : '편지쓰기에서 움직임 명상을 실천하면 자동으로 체크돼요',
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
          subtitle: care.state.journalingDoneToday
              ? null
              : '오늘의 편지를 쓰면 자동으로 체크돼요',
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
        if (kShowMochiDebugPanel) const SizedBox(height: 14),
        if (kShowMochiDebugPanel) const _MochiEmotionDebugPanel(),
        if (kShowMochiDebugPanel) const SizedBox(height: 14),
        if (kShowMochiDebugPanel) const _GrowthStageDebugPanel(),
      ],
    );
  }
}

/// 🐛 디버그 전용 - 실제로 30일씩 출석해야 볼 수 있는 고양이 성장 단계
/// (아기→소년→청년→성체)를 기다리지 않고 바로 미리보기 위한 패널.
/// [kShowMochiDebugPanel]을 false로 바꾸면(또는 이 위젯을 지우면) 사라집니다.
class _GrowthStageDebugPanel extends StatelessWidget {
  const _GrowthStageDebugPanel();

  static const List<(String, int?)> _options = [
    ('실제 값', null),
    ('0일 (아기)', 0),
    ('35일 (소년)', 35),
    ('65일 (청년)', 65),
    ('95일 (성체)', 95),
  ];

  @override
  Widget build(BuildContext context) {
    final care = context.watch<CatCareProvider>();
    final override = care.debugGrowthDaysOverride;
    final effective = care.effectiveGrowthDays;
    final stage = CatCareState.stageForGrowthDays(effective);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.bug_report_outlined,
                size: 16,
                color: Colors.deepPurple,
              ),
              const SizedBox(width: 6),
              Text(
                '디버그: 고양이 성장 단계 미리보기',
                style: pathLabelFont(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.deepPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '실제 성장일수: ${care.state.growthDays}일'
            '${override != null ? " · 미리보기 중: $override일" : ""}'
            ' → 현재 단계: ${stage.name}',
            style: bodyFont(fontSize: 11, color: AppColors.inkSoft),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _options.map((opt) {
              final label = opt.$1;
              final value = opt.$2;
              final selected = value == null
                  ? override == null
                  : override == value;
              return ChoiceChip(
                label: Text(label, style: const TextStyle(fontSize: 11.5)),
                selected: selected,
                onSelected: (_) {
                  context.read<CatCareProvider>().setDebugGrowthDays(value);
                },
                selectedColor: Colors.deepPurple.withValues(alpha: 0.18),
                backgroundColor: Colors.white,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// 🐛 디버그 전용 - 모찌의 결석 감정을 미리보기 위한 패널.
/// [kShowMochiDebugPanel]을 false로 바꾸면(또는 이 위젯을 지우면) 사라집니다.
class _MochiEmotionDebugPanel extends StatelessWidget {
  const _MochiEmotionDebugPanel();

  static const List<(String, int?)> _options = [
    ('실제 값', null),
    ('오늘 방문 (해맑음)', 0),
    ('1일째 (해맑음)', 1),
    ('2일째 (기다림)', 2),
    ('4일째 (그리움)', 4),
    ('8일째 (걱정)', 8),
  ];

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final override = appState.debugDaysAwayOverride;
    final effective = appState.effectiveDaysAway;
    final emotion = CatEmotion.forDaysAway(effective);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.bug_report_outlined,
                size: 16,
                color: Colors.deepPurple,
              ),
              const SizedBox(width: 6),
              Text(
                '디버그: 모찌 결석 감정 미리보기',
                style: pathLabelFont(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.deepPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '실제 결석일수: ${appState.daysAwayOnOpen}일'
            '${override != null ? " · 미리보기 중: $override일" : ""}'
            ' → 현재 감정: ${emotion.label}',
            style: bodyFont(fontSize: 11, color: AppColors.inkSoft),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _options.map((opt) {
              final label = opt.$1;
              final value = opt.$2;
              final selected = value == null
                  ? override == null
                  : override == value;
              return ChoiceChip(
                label: Text(label, style: const TextStyle(fontSize: 11.5)),
                selected: selected,
                onSelected: (_) {
                  context.read<AppStateProvider>().setDebugDaysAway(value);
                },
                selectedColor: Colors.deepPurple.withValues(alpha: 0.18),
                backgroundColor: Colors.white,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// 마음 돌보기 탭 최상단에 자리한 인사 히어로 영역.
/// 큰 캐릭터 이미지는 바로 아래 _CompanionCard에서 한 번만 보여주므로
/// 여기서는 중복 없이 인사 문구만 표시합니다. 구독자가 이름을 지어주면
/// 그 이름으로 인사 문구가 대체됩니다.
class _MochiGreetingHero extends StatelessWidget {
  final String name;
  const _MochiGreetingHero({required this.name});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '오늘 마음은 어떠세요?',
          textAlign: TextAlign.center,
          style: titleFont(fontSize: 18, color: AppColors.ink),
        ),
        const SizedBox(height: 4),
        Text(
          '$name${topicParticle(name)} 함께 있어드릴게요 🌸',
          textAlign: TextAlign.center,
          style: bodyFont(fontSize: 12.5, color: AppColors.inkSoft),
        ),
      ],
    );
  }
}

/// 마음 온도가 100도에 도달할 때마다 적립되는 포인트를 보여주는 배지.
/// 유료구독자(정원 플러스)에게만 노출됩니다.
class _PointsBadge extends StatelessWidget {
  final int points;
  final bool isPremium;
  final VoidCallback? onOpenShop;
  const _PointsBadge({
    required this.points,
    required this.isPremium,
    this.onOpenShop,
  });

  @override
  Widget build(BuildContext context) {
    return GlassBlob(
      accent: AppColors.gold,
      background: const Color(0xFFFCEFD2),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: const Text('🏅', style: TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '정원 플러스 포인트',
                  style: bodyFont(fontSize: 11, color: AppColors.inkSoft),
                ),
                Text(
                  isPremium
                      ? '마음 온도가 100도에 닿을 때마다, 또 오늘의 방울 터뜨리기로도 포인트가 쌓여요'
                      : '오늘의 그림자 방울 터뜨리기로 포인트를 모을 수 있어요 · 정원 플러스 구독 시 온도로도 쌓여요',
                  style: bodyFont(fontSize: 10.5, color: AppColors.inkSoft),
                ),
              ],
            ),
          ),
          Text(
            '$points점',
            style: numberFont(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.gold,
            ),
          ),
          if (onOpenShop != null) ...[
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onOpenShop,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '상점',
                  style: pathLabelFont(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
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
  final List<CatAccessory> equippedAccessories;
  final VoidCallback? onGraduate;
  /// 🐛 디버그 전용 - 미리보기용 성장일수 오버라이드. null이면 실제
  /// [state.growthDays]를 사용합니다.
  final int? debugGrowthDays;
  const _CompanionCard({
    required this.cat,
    required this.state,
    required this.name,
    this.equippedAccessories = const [],
    this.onGraduate,
    this.debugGrowthDays,
  });

  /// 디버그 오버라이드가 있으면 그 값을, 없으면 실제 성장일수를 사용합니다.
  int get _effectiveGrowthDays => debugGrowthDays ?? state.growthDays;

  /// 화면 표시에 사용할 성장 단계(디버그 오버라이드 반영).
  CatGrowthStage get _effectiveStage =>
      CatCareState.stageForGrowthDays(_effectiveGrowthDays);

  /// 다음 단계까지 남은 출석일수(디버그 오버라이드 반영, 성체면 null).
  int? get _effectiveDaysLeft {
    switch (_effectiveStage) {
      case CatGrowthStage.baby:
        return kDaysPerGrowthStage - _effectiveGrowthDays;
      case CatGrowthStage.teen:
        return kDaysPerGrowthStage * 2 - _effectiveGrowthDays;
      case CatGrowthStage.young:
        return kDaysPerGrowthStage * 3 - _effectiveGrowthDays;
      case CatGrowthStage.adult:
        return null;
    }
  }

  /// 화면 표시용 성장 단계 라벨(디버그 오버라이드 반영).
  String get _effectiveStageLabel {
    switch (_effectiveStage) {
      case CatGrowthStage.baby:
        return '0단계 · 아기 고양이';
      case CatGrowthStage.teen:
        return '1단계 · 소년 고양이';
      case CatGrowthStage.young:
        return '2단계 · 청년 고양이';
      case CatGrowthStage.adult:
        return '3단계 · 다 자란 고양이';
    }
  }

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

  /// 특정 성장 단계에 해당하는 이미지 경로를 반환합니다 (레벨업 오버레이용).
  static String imageAssetFor(CatGrowthStage stage, ShadowCat cat) {
    switch (stage) {
      case CatGrowthStage.baby:
        return 'assets/growth/baby_cat.png';
      case CatGrowthStage.teen:
        return 'assets/growth/teen_cat.png';
      case CatGrowthStage.young:
        return 'assets/growth/young_cat.png';
      case CatGrowthStage.adult:
        return cat.imageAsset;
    }
  }

  /// 성장 단계에 따라 보여줄 이미지 - 아기/소년/청년 단계에서는 공용 성장 아트를,
  /// 다 자란 단계에서는 사용자가 실제로 키우고 있는 그림자 고양이 모습을 보여줍니다.
  String get _stageImageAsset {
    switch (_effectiveStage) {
      case CatGrowthStage.baby:
        return 'assets/growth/baby_cat.png';
      case CatGrowthStage.teen:
        return 'assets/growth/teen_cat.png';
      case CatGrowthStage.young:
        return 'assets/growth/young_cat.png';
      case CatGrowthStage.adult:
        return cat.imageAsset;
    }
  }

  @override
  Widget build(BuildContext context) {
    final stage = _effectiveStage;
    final daysLeft = _effectiveDaysLeft;
    final displayName = stage == CatGrowthStage.adult ? cat.nameKr : name;
    return GlassBlob(
      accent: AppColors.blobPeachAccent,
      background: AppColors.blobPeach,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _PattableCatStage(
            stage: stage,
            imageAsset: _stageImageAsset,
            moodEmoji: state.moodEmoji,
            equippedAccessories: equippedAccessories,
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
                  ? '🌟 $_effectiveStageLabel'
                  : _effectiveStageLabel,
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
              style: bodyFont(fontSize: 11, color: AppColors.blobPeachAccent),
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
          const SizedBox(height: 12),
          Text(
            '"${catFlavorText(state.moodState)}"',
            textAlign: TextAlign.center,
            style: bodyFont(
              fontSize: 11.5,
              color: AppColors.inkSoft,
              height: 1.5,
            ).copyWith(fontStyle: FontStyle.italic),
          ),
          if (onGraduate != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onGraduate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  '🎓  졸업시키고 새 아기고양이 만나기',
                  style: pathLabelFont(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 고양이 그림을 탭하면 하트가 퍼지고 말풍선으로 대사가 뜨는 인터랙션 영역.
/// 착용 중인 아이템에 따라 대사가 달라집니다 (예: 헤드셋 착용 시 "음악 듣는 중이에요~🎧").
class _PattableCatStage extends StatefulWidget {
  final CatGrowthStage stage;
  final String imageAsset;
  final String moodEmoji;
  final List<CatAccessory> equippedAccessories;
  const _PattableCatStage({
    required this.stage,
    required this.imageAsset,
    required this.moodEmoji,
    required this.equippedAccessories,
  });

  @override
  State<_PattableCatStage> createState() => _PattableCatStageState();
}

class _PattableCatStageState extends State<_PattableCatStage>
    with TickerProviderStateMixin {
  final List<_HeartBurstData> _hearts = [];
  String? _bubbleText;
  Timer? _bubbleTimer;
  Timer? _comboResetTimer;
  int _tapSeed = 0;

  /// 연속으로 탭한 횟수(3초 이상 쉬면 초기화). 3번째 연속 탭부터
  /// 냐옹 소리 대신(또는 함께) 골골송이 나와요.
  int _comboCount = 0;

  @override
  void dispose() {
    _bubbleTimer?.cancel();
    _comboResetTimer?.cancel();
    for (final h in _hearts) {
      h.controller.dispose();
    }
    super.dispose();
  }

  Future<void> _onTap() async {
    final rng = Random(_tapSeed++);
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    final heart = _HeartBurstData(
      controller: controller,
      dx: (rng.nextDouble() - 0.5) * 70,
      emoji: rng.nextBool() ? '💗' : (rng.nextBool() ? '💕' : '✨'),
    );
    setState(() => _hearts.add(heart));
    controller.forward().whenComplete(() {
      if (!mounted) return;
      setState(() => _hearts.remove(heart));
      controller.dispose();
    });

    // 연속 탭 횟수 갱신 - 3초 안에 다시 탭하지 않으면 콤보가 끊겨요.
    _comboResetTimer?.cancel();
    _comboCount++;
    _comboResetTimer = Timer(const Duration(seconds: 3), () {
      _comboCount = 0;
    });

    final provider = context.read<CatCareProvider>();
    final line = await provider.patCat();
    if (!mounted) return;

    // 냐옹(1번째) 이후 2번 더(3번째 연속 탭부터) 골골송이 나와요.
    String finalLine = line;
    if (_comboCount >= 3) {
      await SoundService().playPurr();
      finalLine = '골골골골... 너무 행복해요 😽💤';
      _comboCount = 0;
      _comboResetTimer?.cancel();
    }

    _bubbleTimer?.cancel();
    setState(() => _bubbleText = finalLine);
    _bubbleTimer = Timer(const Duration(milliseconds: 2000), () {
      if (!mounted) return;
      setState(() => _bubbleText = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _onTap,
      child: Stack(
        alignment: Alignment.bottomRight,
        clipBehavior: Clip.none,
        children: [
          widget.stage == CatGrowthStage.baby
              ? GardenWeatherCatMood(
                  activity: context
                      .watch<AppStateProvider>()
                      .gardenWeather
                      .catActivity,
                  child: MochiCat(
                    size: 140,
                    emotion: CatEmotion.forDaysAway(
                      context.watch<AppStateProvider>().effectiveDaysAway,
                    ),
                  ),
                )
              : widget.stage == CatGrowthStage.teen
              ? const AnimatedTeenCat(size: 140)
              : widget.stage == CatGrowthStage.adult
              ? const AnimatedAdultCat(size: 140)
              : AnimatedCatArt(imageAsset: widget.imageAsset, size: 140),
          Positioned(
            right: -4,
            bottom: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.75),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.blobPeachAccent.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                widget.moodEmoji,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          ...widget.equippedAccessories.map(
            (accessory) => _WornBadge(accessory: accessory),
          ),
          ..._hearts.map(
            (heart) => AnimatedBuilder(
              animation: heart.controller,
              builder: (context, _) {
                final t = heart.controller.value;
                return Positioned(
                  left: 70 + heart.dx,
                  top: 60 - (t * 70),
                  child: Opacity(
                    opacity: (1 - t).clamp(0.0, 1.0),
                    child: Text(
                      heart.emoji,
                      style: TextStyle(fontSize: 18 + (t * 6)),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_bubbleText != null)
            Positioned(
              top: -18,
              left: -10,
              right: -10,
              child: AnimatedOpacity(
                opacity: _bubbleText != null ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.blobPeachAccent.withValues(alpha: 0.35),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    _bubbleText!,
                    textAlign: TextAlign.center,
                    style: bodyFont(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeartBurstData {
  final AnimationController controller;
  final double dx;
  final String emoji;
  _HeartBurstData({
    required this.controller,
    required this.dx,
    required this.emoji,
  });
}

/// 착용 중인 아이템 하나를 부위에 맞는 위치에 작은 배지로 보여줍니다.
/// 부위가 다르면 여러 개가 겹치지 않고 각자 자리에 표시돼요.
class _WornBadge extends StatelessWidget {
  final CatAccessory accessory;
  const _WornBadge({required this.accessory});

  Offset get _offset {
    switch (accessory.slot) {
      case CatWearSlot.head:
        return const Offset(-2, -10);
      case CatWearSlot.neck:
        return const Offset(38, 6);
      case CatWearSlot.body:
        return const Offset(-40, 30);
      case CatWearSlot.feet:
        return const Offset(30, 96);
      case CatWearSlot.decor:
      case null:
        return const Offset(2, -6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = _offset;
    return Positioned(
      left: 70 + o.dx,
      top: 70 + o.dy,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.blobPeachAccent.withValues(alpha: 0.35),
          ),
        ),
        child: Text(accessory.emoji, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}

/// 구매한 가구(캣타워/캣베드/스크래처 등)를 보여주는 "우리 집" 영역.
/// 착용하는 아이템과 달리, 가구는 보유하는 순간 바로 방에 놓인 것으로
/// 표시됩니다.
class _FurnitureRoomBlob extends StatelessWidget {
  final List<CatAccessory> furniture;
  const _FurnitureRoomBlob({required this.furniture});

  @override
  Widget build(BuildContext context) {
    return GlassBlob(
      accent: AppColors.blobMintAccent,
      background: AppColors.blobMint,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          const Text('🏠', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '우리 집',
                  style: pathLabelFont(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: furniture
                      .map(
                        (f) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${f.emoji} ${f.label}',
                            style: bodyFont(
                              fontSize: 10.5,
                              color: AppColors.inkSoft,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
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
  final String? subtitle;
  final bool done;
  final VoidCallback? onTap;
  final int seed;
  const _CareTaskTile({
    required this.emoji,
    required this.label,
    this.subtitle,
    required this.done,
    required this.onTap,
    required this.seed,
  });

  @override
  State<_CareTaskTile> createState() => _CareTaskTileState();
}

class _CareTaskTileState extends State<_CareTaskTile>
    with TickerProviderStateMixin {
  late final AnimationController _hoverController;
  late final AnimationController _floatController;
  bool _hovering = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    // 마우스 호버가 없는 모바일에서도 살아있는 느낌을 주기 위해, 카드마다
    // 조금씩 다른 리듬으로 저절로 살짝 떠다니는 애니메이션을 항상 재생합니다.
    final rng = Random(widget.seed * 53 + 17);
    _floatController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 3800 + rng.nextInt(2200)),
    )..repeat(reverse: true, min: rng.nextDouble() * 0.6, max: 1);
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _floatController.dispose();
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
    final background = widget.done
        ? AppColors.blobMint
        : AppColors.blobLavender;
    final radius = _blobRadius();
    return AnimatedBuilder(
      animation: Listenable.merge([_hoverController, _floatController]),
      builder: (context, child) {
        final t = _hoverController.value;
        final wiggle = sin(t * pi * 3) * 0.03 * t;
        final scale = 1.0 + t * 0.02;
        final floatT = _floatController.value;
        final floatDy = sin(floatT * pi) * 2.4;
        final floatAngle = sin(floatT * pi) * 0.012;
        return Transform.translate(
          offset: Offset(0, floatDy),
          child: Transform.rotate(
            angle: wiggle + floatAngle,
            child: Transform.scale(scale: scale, child: child),
          ),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.label,
                        style: pathLabelFont(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      if (widget.subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle!,
                          style: bodyFont(
                            fontSize: 10.5,
                            color: AppColors.inkSoft,
                          ),
                        ),
                      ],
                    ],
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
