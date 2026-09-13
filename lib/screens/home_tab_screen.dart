import 'emotion_statistics_screen.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../providers/cat_care_provider.dart';
import '../providers/buried_emotion_provider.dart';
import '../data/shadow_cats_data.dart';
import '../models/letter_entry.dart';
import '../services/reflection_service.dart';
import '../utils/cat_palette.dart';
import '../theme.dart';
import '../widgets/growth_header.dart';
import '../widgets/garden_path_card.dart';
import '../widgets/mochi_cat.dart';
import '../widgets/feature_scaffold.dart';
import 'pet_care_screen.dart';
import 'daily_card_screen.dart';
import 'todays_promise_screen.dart';
import 'day_close_screen.dart';
import 'bubble_garden_screen.dart';
import 'sprout_reflection_screen.dart';
import 'cat_bond_screen.dart';
import 'heart_letters_screen.dart';
import 'heart_letter_history_screen.dart';
import '../services/special_letter_service.dart';
import '../models/special_letter_entry.dart';
import '../widgets/category_list_screen.dart';
import 'premium_screen.dart';

/// 홈페이지 탭 - '힐링 정원 산책로' 컨셉의 대시보드.
/// 딱딱한 흰 사각 카드를 모두 걷어내고, 오솔길을 걷듯 좌우로 살짝씩 흔들리며
/// 놓인 반투명 알약형 카드들을 순서대로 만나게 됩니다.
class HomeTabScreen extends StatelessWidget {
  final VoidCallback onGoToCatSelect;
  final VoidCallback onGoToMeditation;
  final VoidCallback onGoToRecords;
  const HomeTabScreen({
    super.key,
    required this.onGoToCatSelect,
    required this.onGoToMeditation,
    required this.onGoToRecords,
  });

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppStateProvider>();
    final unseenReply = app.letterWithUnseenReadyReply;
    final unseenHeartReply = SpecialLetterService.unseenReadyReply;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TodayInviteCard(
          hasUnseenReply: unseenReply != null,
          onTap: unseenReply != null ? onGoToRecords : onGoToCatSelect,
        ),
        const SizedBox(height: 16),
        if (unseenReply != null) ...[
          _CatReplyBanner(entry: unseenReply, onTap: onGoToRecords),
          const SizedBox(height: 16),
        ],
        if (unseenHeartReply != null) ...[
          _HeartLetterReplyBanner(
            entry: unseenHeartReply,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    HeartLetterHistoryScreen(type: unseenHeartReply.type),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        const _SproutBannerArea(),
        const _ReflectionBannerArea(),
        Text(
          'MIND CAT GARDEN',
          textAlign: TextAlign.center,
          style: bodyFont(
            fontSize: 12,
            color: AppColors.titlePastelGreenSoft,
            letterSpacing: 4,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '마음냥 정원',
          textAlign: TextAlign.center,
          style: brandFont(fontSize: 44, color: AppColors.titlePastelGreen),
        ),
        const SizedBox(height: 10),
        Text(
          '42마리 그림자 고양이를 한 마리씩 만나며,\n내 감정을 스스로 알아차리는 시간',
          textAlign: TextAlign.center,
          style: bodyFont(
            fontSize: 13.5,
            color: AppColors.inkSoft,
            height: 1.7,
          ),
        ),
        const SizedBox(height: 30),
        _JourneyHero(
          metCount: app.metCatCount,
          // ⚠️ 유료(Basic 구독) 고양이는 잠겨있으면 탭해도 "만남" 처리가
          // 되지 않아, 비구독자는 42마리를 넘어 "만날" 수 없습니다.
          // shadowCats.length(52)를 분모로 쓰면 영원히 채울 수 없는 목표가
          // 되므로 무료 42마리 기준으로 표시합니다.
          total: freeShadowCats.length,
          onMeetCat: onGoToCatSelect,
        ),
        const SizedBox(height: 26),
        Builder(
          builder: (context) {
            final careDays =
                context.watch<CatCareProvider>().state.growthDays;
            // 설치일 기준(streak)과 출석일(growthDays) 중 큰 값으로 맞춤
            final days = math.max(app.streak, careDays);
            return _StreakBlob(streak: days);
          },
        ),
        const SizedBox(height: 18),
        GrowthHeader(state: context.watch<CatCareProvider>().state),
        const SizedBox(height: 44),
        _PathSignpost(title: '고양이를 만난 뒤엔, 이렇게 돌봐요'),
        const SizedBox(height: 6),
        GardenPathCard(
          emoji: '🌿',
          title: '마음 돌보기',
          subtitle: '명상·움직임, 몸 돌봄, 오늘의 고양이 카드을 모아뒀어요',
          accent: AppColors.blobMintAccent,
          background: AppColors.blobMint,
          alignX: 0.28,
          widthFactor: 0.92,
          floatSeed: 2,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CategoryListScreen(
                title: '마음 돌보기',
                headerEmoji: '🌿',
                headerSubtitle: '몸과 마음을 함께 돌보는 시간이에요.\n필요한 곳을 골라 들어가보세요',
                items: [
                  CategoryItem(
                    emoji: '🧘',
                    title: '명상 · 움직임 둘러보기',
                    subtitle: '호흡, 알아차림, 움직임, 표현하기 가이드를 살펴보세요',
                    accent: AppColors.blobLavenderAccent,
                    background: AppColors.blobLavender,
                    onTap: (ctx) {
                      // 카테고리 목록이 탭 셸 위에 덮여 있으므로, 먼저 닫고
                      // 명상 탭으로 바꿔야 바로 보입니다.
                      Navigator.of(ctx).pop();
                      onGoToMeditation();
                    },
                  ),
                  CategoryItem(
                    emoji: '🐟',
                    title: '마음 돌보기(몸 돌봄)',
                    subtitle: '밥·물·목욕과 호흡·걷기 명상으로 고양이를 함께 키워보세요',
                    accent: AppColors.blobRoseAccent,
                    background: AppColors.blobRose,
                    onTap: (ctx) => pushFullScreen(
                      ctx,
                      '마음 돌보기',
                      const PetCareScreen(),
                    ),
                  ),
                  CategoryItem(
                    emoji: '🔮',
                    title: '오늘의 고양이 카드',
                    subtitle: '오늘의 카드를 뽑아 위로와 지침을 받아보세요',
                    accent: AppColors.blobPeriwinkleAccent,
                    background: AppColors.blobPeriwinkle,
                    onTap: (ctx) => pushFullScreen(
                      ctx,
                      '오늘의 고양이 카드',
                      const DailyCardScreen(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const GardenPathConnector(startX: 0.28, endX: -0.28, decorEmoji: '🐾'),
        GardenPathCard(
          emoji: '💌',
          title: '편지 쓰기',
          subtitle: '마음편지와 오늘의 약속, 마음을 짧게 적어보는 곳이에요',
          accent: AppColors.blobButterAccent,
          background: AppColors.blobButter,
          alignX: -0.28,
          widthFactor: 0.92,
          floatSeed: 12,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CategoryListScreen(
                title: '편지 쓰기',
                headerEmoji: '💌',
                headerSubtitle: '짧게 적어도 괜찮아요.\n마음을 편지로 남겨보세요',
                items: [
                  CategoryItem(
                    emoji: '💌',
                    title: '마음편지',
                    subtitle: '감사·용서·미안함·사랑, 짧게 적으면 내일 답장이 와요',
                    accent: AppColors.blobButterAccent,
                    background: AppColors.blobButter,
                    onTap: (ctx) => pushFullScreen(
                      ctx,
                      '마음편지',
                      const HeartLettersScreen(),
                    ),
                  ),
                  CategoryItem(
                    emoji: '🌱',
                    title: '오늘의 약속',
                    subtitle: '오늘 나를 위해 지켜주고 싶은 작은 약속을 남겨보세요',
                    accent: AppColors.blobRoseAccent,
                    background: AppColors.blobRose,
                    onTap: (ctx) => pushFullScreen(
                      ctx,
                      '오늘의 약속',
                      const TodaysPromiseScreen(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const GardenPathConnector(startX: -0.28, endX: 0.26, decorEmoji: '🦋'),
        GardenPathCard(
          emoji: '📖',
          title: '돌아보기 & 기록',
          subtitle: '마음 온도, 주간 지도, 하루 닫기, 그림자 방울을 살펴보세요',
          accent: AppColors.blobPeachAccent,
          background: AppColors.blobPeach,
          alignX: 0.26,
          widthFactor: 0.92,
          floatSeed: 9,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CategoryListScreen(
                title: '돌아보기 & 기록',
                headerEmoji: '📖',
                headerSubtitle: '지나온 마음의 흐름을\n천천히 돌아보는 시간이에요',
                items: [
                  CategoryItem(
                    emoji: '🌡️',
                    title: '마음 온도 기록 보기',
                    subtitle: '지난 편지와 마음 온도 변화를 돌아보세요',
                    accent: AppColors.blobRoseAccent,
                    background: AppColors.blobRose,
                    onTap: (ctx) {
                      Navigator.of(ctx).pop();
                      onGoToRecords();
                    },
                  ),
                  CategoryItem(
                    emoji: '🗺️',
                    title: '감정 통계',
                    subtitle: '이번 주 자주 마주한 감정 Top 3를 지도처럼 살펴보세요',
                    accent: AppColors.blobPeachAccent,
                    background: AppColors.blobPeach,
                    onTap: (ctx) => pushFullScreen(
                      ctx,
                      '감정 통계',
                      const EmotionStatisticsScreen(),
                    ),
                  ),
                  CategoryItem(
                    emoji: '🌙',
                    title: '하루 닫기',
                    subtitle: '오늘 곁에 남긴 약속들을 조용히 돌아보며 하루를 닫아요',
                    accent: AppColors.blobPeriwinkleAccent,
                    background: AppColors.blobPeriwinkle,
                    onTap: (ctx) => pushFullScreen(
                      ctx,
                      '하루 닫기',
                      const DayCloseScreen(),
                    ),
                  ),
                  CategoryItem(
                    emoji: '🫧',
                    title: '오늘의 그림자 방울 터뜨리기',
                    subtitle: '오늘 마주한 감정을 방울로 만나, 하나씩 터뜨려 놓아주세요',
                    accent: AppColors.blobLavenderAccent,
                    background: AppColors.blobLavender,
                    onTap: (ctx) => pushFullScreen(
                      ctx,
                      '오늘의 그림자 방울 터뜨리기',
                      const BubbleGardenScreen(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const GardenPathConnector(startX: 0.26, endX: -0.24, decorEmoji: '🐾'),
        GardenPathCard(
          emoji: '🧵',
          title: '묘연 나누기',
          subtitle: '내 그림자 고양이 코드를 친구에게 보내고 나란히 살펴보세요',
          accent: AppColors.blobLavenderAccent,
          background: AppColors.blobLavender,
          alignX: -0.24,
          widthFactor: 0.9,
          floatSeed: 11,
          onTap: () => pushFullScreen(context, '묘연 나누기', const CatBondScreen()),
        ),
        const SizedBox(height: 40),
        _GardenHintCaption(),
      ],
    );
  }
}

/// 홈 화면 최상단, '36 그림자 고양이 여정'을 앱의 핵심 후크로 내세우는
/// 히어로 섹션. 오늘 만날 고양이 CTA와 도감(수집 진행률) 진입점을 함께
/// 보여주어, 다른 모든 기능이 이 여정을 중심으로 이어지도록 합니다.
class _JourneyHero extends StatelessWidget {
  final int metCount;
  final int total;
  final VoidCallback onMeetCat;
  const _JourneyHero({
    required this.metCount,
    required this.total,
    required this.onMeetCat,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : metCount / total;
    final remaining = total - metCount;
    return GlassBlob(
      accent: AppColors.blobPeachAccent,
      background: AppColors.blobPeach,
      floatSeed: 1,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.55),
                  border: Border.all(
                    color: AppColors.blobPeachAccent.withValues(alpha: 0.35),
                  ),
                ),
                child: const Text('🐾', style: TextStyle(fontSize: 21)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '그림자 고양이 여정',
                      style: pathLabelFont(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      metCount == 0
                          ? '아직 만난 고양이가 없어요. 지금 첫 고양이를 만나볼까요?'
                          : remaining == 0
                          ? '$total마리를 모두 만났어요. 정원이 가득 채워졌네요 🌸'
                          : '$total마리 중 $metCount마리를 만났어요 · $remaining마리가 기다리는 중',
                      style: bodyFont(
                        fontSize: 11.5,
                        color: AppColors.inkSoft,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              backgroundColor: Colors.white.withValues(alpha: 0.55),
              valueColor: const AlwaysStoppedAnimation(
                AppColors.blobPeachAccent,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _JourneyHeroButton(
            label: metCount == 0 ? '고양이 만나기' : '오늘의 고양이 만나기',
            emoji: '🐈',
            filled: true,
            onTap: onMeetCat,
          ),
        ],
      ),
    );
  }
}

class _JourneyHeroButton extends StatelessWidget {
  final String label;
  final String emoji;
  final bool filled;
  final VoidCallback onTap;
  const _JourneyHeroButton({
    required this.label,
    required this.emoji,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: filled
                ? AppColors.blobPeachAccent.withValues(alpha: 0.88)
                : Colors.white.withValues(alpha: 0.55),
            border: Border.all(
              color: AppColors.blobPeachAccent.withValues(
                alpha: filled ? 0 : 0.4,
              ),
              width: 1.1,
            ),
          ),
          child: Text(
            '$emoji  $label',
            style: pathLabelFont(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: filled ? Colors.white : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

/// 오솔길 입구에 세워진 나무 팻말 느낌의 섹션 안내 - 딱딱한 사이드바 대신
/// 손글씨 폰트와 은은한 초록 밑줄로 위계를 드러냅니다.
class _PathSignpost extends StatelessWidget {
  final String title;
  const _PathSignpost({required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: titleFont(fontSize: 20, color: AppColors.ink),
        ),
        const SizedBox(height: 8),
        Container(
          width: 64,
          height: 3,
          decoration: BoxDecoration(
            color: AppColors.titlePastelGreenSoft,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ],
    );
  }
}

/// 홈 화면 맨 위, 오늘의 감정 기록을 안내하는 카드.
/// 딱딱한 텍스트+아웃라인 버튼 조합 대신, 앱 전체의 파스텔 유리질감
/// (GlassBlob) 카드 스타일과 통일해 손글씨 라벨 폰트와 알약형 CTA 버튼으로
/// 다시 꾸몄습니다. 아직 열어보지 않은 답장이 있으면 문구/버튼이 바뀝니다.
class _TodayInviteCard extends StatelessWidget {
  final bool hasUnseenReply;
  final VoidCallback onTap;
  const _TodayInviteCard({required this.hasUnseenReply, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlassBlob(
      accent: AppColors.blobLavenderAccent,
      background: AppColors.blobLavender,
      floatSeed: 1,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text('🌸', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hasUnseenReply
                      ? '고양이의 답장이 도착했어요'
                      : '오늘은 한 가지면 충분해요',
                  style: pathLabelFont(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.blobLavenderAccent,
                backgroundColor: Colors.white.withValues(alpha: 0.55),
                side: BorderSide(
                  color: AppColors.blobLavenderAccent.withValues(alpha: 0.45),
                  width: 1.2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text(
                hasUnseenReply ? '도착한 고양이 편지 읽기' : '오늘의 감정 고르고 한 줄 보내기',
                style: pathLabelFont(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.blobLavenderAccent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 저녁에 쓴 편지에 대해 다음날 아침 고양이의 답장이 도착했음을 알려주는
/// 배너. 아직 열어보지 않은 답장이 있을 때만 홈 화면 최상단 근처에
/// 나타나며, 탭하면 기록 탭으로 이동해 바로 열어볼 수 있습니다.
class _CatReplyBanner extends StatelessWidget {
  final LetterEntry entry;
  final VoidCallback onTap;
  const _CatReplyBanner({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cat = shadowCatById(entry.catId);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.blobButter.withValues(alpha: 0.92),
                AppColors.blobButter.withValues(alpha: 0.62),
              ],
            ),
            border: Border.all(
              color: AppColors.blobButterAccent.withValues(alpha: 0.32),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.blobButterAccent.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Text('💌', style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${cat.nameKr}에게서 답장이 도착했어요',
                      style: pathLabelFont(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '어제 보낸 편지에 대한 답장을 열어보세요',
                      style: bodyFont(fontSize: 11.5, color: AppColors.inkSoft),
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
    );
  }
}

/// 마음편지(감사·용서·미안함·사랑)에 대한 답장이 도착했음을 알려주는
/// 배너. [_CatReplyBanner]와 동일한 톤으로, 아직 열어보지 않은 답장이
/// 있을 때만 나타납니다.
class _HeartLetterReplyBanner extends StatelessWidget {
  final SpecialLetterEntry entry;
  final VoidCallback onTap;
  const _HeartLetterReplyBanner({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.blobRose.withValues(alpha: 0.92),
                AppColors.blobRose.withValues(alpha: 0.62),
              ],
            ),
            border: Border.all(
              color: AppColors.blobRoseAccent.withValues(alpha: 0.32),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.blobRoseAccent.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  entry.type.emoji,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry.type.label} 답장이 도착했어요',
                      style: pathLabelFont(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '어제 보낸 편지에 대한 답장을 열어보세요',
                      style: bodyFont(fontSize: 11.5, color: AppColors.inkSoft),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.blobRoseAccent,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 며칠 전 땅에 묻어둔 감정이 새싹으로 다시 떠올랐을 때 조용히 보여주는
/// 배너. "미해결 문제"가 아니라 "언제든 들여다볼 수 있는 마음이 있어요"
/// 정도의 가벼운 존재감만 전달합니다 - 누르지 않아도 아무 문제가 없습니다.
class _SproutBannerArea extends StatelessWidget {
  const _SproutBannerArea();

  @override
  Widget build(BuildContext context) {
    final sprouts = context.watch<BuriedEmotionProvider>().sprouts;
    if (sprouts.isEmpty) return const SizedBox.shrink();
    final entry = sprouts.first;
    final accent = entry.catId.isEmpty
        ? CatPalette.emptyDay
        : CatPalette.accentFor(entry.catId);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => FeatureScaffold(
                title: '다시 떠오른 마음',
                child: SproutReflectionScreen(entry: entry),
              ),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.blobPeach.withValues(alpha: 0.9),
                  AppColors.blobPeach.withValues(alpha: 0.6),
                ],
              ),
              border: Border.all(
                color: accent.withValues(alpha: 0.3),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Text('🌱', style: TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '정원에 작은 새싹이 돋아났어요',
                        style: pathLabelFont(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '며칠 전 묻어둔 마음이에요 · 지금 들여다봐도, 그냥 두어도 괜찮아요',
                        style: bodyFont(
                          fontSize: 11.5,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: accent, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 며칠째 함께하는지를 보여주는 반투명 유기적 블롭 - 흰 사각 박스를 대체.
/// 숫자만 보여주던 이전 버전에서, 최근 7일 중 어느 날 기록했는지를 작은
/// 점으로 함께 보여주도록 확장했습니다 - "오늘 안 하면 끊긴다"는 감각을
/// 시각적으로 상기시켜 리텐션에 도움이 되도록 하는 목적입니다(강제 알림이
/// 아니라 화면에 조용히 보이는 정도로만).
class _StreakBlob extends StatelessWidget {
  final int streak;
  const _StreakBlob({required this.streak});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppStateProvider>();
    final last7 = app.last7DaysCatIds();
    final recordedToday = last7.isNotEmpty && last7.last.value != null;
    return GlassBlob(
      accent: AppColors.blobButterAccent,
      background: AppColors.blobButter,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 800),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: const MochiCat(size: 48, static: true),
                  );
                },
              ),
              const SizedBox(width: 16),
              RichText(
                text: TextSpan(
                  style: bodyFont(fontSize: 13.5, color: AppColors.moon),
                  children: [
                    TextSpan(
                      text: '$streak',
                      style: numberFont(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: AppColors.goldSoft,
                      ),
                    ),
                    const TextSpan(text: '일째 함께하는 중'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _StreakWeekDots(days: last7),
          const SizedBox(height: 8),
          Text(
            '숫자는 앱과 함께한(출석) 일수예요.\n아래 점은 최근 7일 중 편지를 남긴 날이에요',
            textAlign: TextAlign.center,
            style: bodyFont(fontSize: 11, color: AppColors.inkSoft),
          ),
          if (!recordedToday && streak > 0) ...[
            const SizedBox(height: 10),
            Text(
              '오늘 아직 기록이 없어요 · 지금 만나면 마음이 이어져요',
              style: bodyFont(fontSize: 11, color: AppColors.blobButterAccent),
            ),
          ],
          _StreakMilestoneUpsell(streak: streak),
        ],
      ),
    );
  }
}

/// 스트릭이 의미 있는 마일스톤(7/14/30일)에 도달한, 가장 몰입도 높은
/// 순간에만 아주 짧게 구독을 제안하는 카드. 매번 노출되면 잔소리가 되므로
/// 딱 그날 하루(스트릭 값이 정확히 마일스톤과 같을 때)에만 보여줍니다.
class _StreakMilestoneUpsell extends StatelessWidget {
  final int streak;
  const _StreakMilestoneUpsell({required this.streak});

  static const _milestones = {
    7: '일주일째 마음을 돌보고 있어요',
    14: '2주째 꾸준히 이어오고 있어요',
    30: '한 달째 함께하고 있어요',
  };

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppStateProvider>();
    final label = _milestones[streak];
    if (label == null || app.isPremiumUser) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PremiumScreen()),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Text('🌟', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$label. 더 깊이 들여다볼 준비가 됐어요',
                  style: bodyFont(fontSize: 11.5, color: AppColors.ink),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: AppColors.gold,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 최근 7일간의 기록 여부를 작은 원형 점으로 나란히 보여주는 시각화.
/// 오늘 칸이 비어 있으면 살짝 테두리를 강조해 "오늘만 채우면 이어진다"는
/// 느낌을 은은하게 줍니다.
class _StreakWeekDots extends StatelessWidget {
  final List<MapEntry<DateTime, String?>> days;
  const _StreakWeekDots({required this.days});

  static const _weekdayLabels = ['월', '화', '수', '목', '금', '토', '일'];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < days.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Column(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: days[i].value != null
                        ? CatPalette.accentFor(
                            days[i].value!,
                          ).withValues(alpha: 0.9)
                        : Colors.white.withValues(alpha: 0.5),
                    border: i == days.length - 1 && days[i].value == null
                        ? Border.all(
                            color: AppColors.blobButterAccent.withValues(
                              alpha: 0.7,
                            ),
                            width: 1.6,
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _weekdayLabels[days[i].key.weekday - 1],
                  style: bodyFont(fontSize: 9.5, color: AppColors.inkSoft),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// 주간/월간 통계 자동 노출 배너 영역.
/// 진입 조건(가입 후 7일/30일 경과 등)을 만족하고, 아직 이번 주기 안에
/// 보지 않았을 때만 나타납니다. 사용자가 앱을 열었을 때 화면에 조용히
/// 보이는 카드일 뿐, 푸시 알림 등 어떤 강제 알림도 사용하지 않습니다.
class _ReflectionBannerArea extends StatefulWidget {
  const _ReflectionBannerArea();

  @override
  State<_ReflectionBannerArea> createState() => _ReflectionBannerAreaState();
}

class _ReflectionBannerAreaState extends State<_ReflectionBannerArea> {
  bool _showWeekly = false;
  bool _showMonthly = false;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final app = context.read<AppStateProvider>();
    final weekly = await ReflectionService.shouldShowWeeklyBanner(app);
    final monthly = await ReflectionService.shouldShowMonthlyBanner(app);
    if (!mounted) return;
    setState(() {
      _showWeekly = weekly;
      // 같은 화면에 두 배너가 겹치지 않도록, 월간이 뜰 조건이면 월간을
      // 우선합니다(더 큰 주기의 관찰이 더 의미 있는 시점이기 때문).
      _showMonthly = monthly;
      _showWeekly = weekly && !monthly;
      _checked = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked || (!_showWeekly && !_showMonthly)) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: _showMonthly
          ? _ReflectionReadyBanner(
              emoji: '📖',
              title: '이번 달 돌아보기가 도착했어요',
              subtitle: '한 달간의 감정 흐름을 문장으로 되짚어볼 수 있어요',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const EmotionStatisticsScreen(initialMonthly: true),
                ),
              ),
            )
          : _ReflectionReadyBanner(
              emoji: '🗓️',
              title: '이번 주 돌아보기가 도착했어요',
              subtitle: '이번 주 함께한 고양이와 요일별 흐름을 살펴보세요',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const EmotionStatisticsScreen(),
                ),
              ),
            ),
    );
  }
}

class _ReflectionReadyBanner extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ReflectionReadyBanner({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.blobMint.withValues(alpha: 0.9),
                AppColors.blobMint.withValues(alpha: 0.6),
              ],
            ),
            border: Border.all(
              color: AppColors.blobMintAccent.withValues(alpha: 0.3),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: pathLabelFont(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: bodyFont(fontSize: 11.5, color: AppColors.inkSoft),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.blobMintAccent,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 카드가 아니라, 화면 가장자리에서 조용히 살아가는 그림자 고양이들의 존재를
/// 은은하게 알려주는 짧은 캡션. 장식이 아니라 '함께 있음'을 상기시키는 문구입니다.
class _GardenHintCaption extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          '🐈‍⬛  그림자 고양이들이 정원 어딘가에서\n조용히 당신의 마음을 지켜보고 있어요',
          textAlign: TextAlign.center,
          style: bodyFont(
            fontSize: 11.5,
            color: AppColors.inkSoft,
            height: 1.8,
          ),
        ),
      ),
    );
  }
}
