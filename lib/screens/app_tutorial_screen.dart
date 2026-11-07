import '../l10n/app_language.dart';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/garden_path_card.dart';
import 'about_app_screen.dart';
import 'premium_screen.dart';

/// 앱 사용법 튜토리얼 화면.
///
/// [AboutAppScreen](마이 > 마음냥 정원 소개)이 "이 앱이 어떤 생각에서
/// 시작됐는지"를 다루는 철학적 소개라면, 이 화면은 "실제로 무엇을 할 수 있고
/// 어떻게 쓰면 되는지"를 다루는 기능 지도(사용 설명서)입니다.
///
/// 좌우 네 공간(홈 / 정원 / 마음돌보기 / 모든 기능)과 세부 기능을 안내하며,
/// 각 탭 안에 있는 세부 기능을 펼쳐서 볼 수 있는 아코디언 목록으로 구성합니다.
/// 마지막에는 무료/정원 플러스(구독) 범위를 정리하고, 이 앱의 기반이 되는
/// 생각(칼 융의 그림자 개념)을 짧게 짚어준 뒤 [AboutAppScreen]으로 더 깊이
/// 들어갈 수 있는 링크를 제공합니다.
class AppTutorialScreen extends StatelessWidget {
  const AppTutorialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    if (AppLanguage.instance.isEnglish) return _englishTutorial(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _TutorialIntroCard(),
        const SizedBox(height: 18),
        _SectionLabel(emoji: '🗺️', text: '기능별로 살펴보기'),
        const SizedBox(height: 10),
        _TutorialSection(
          emoji: '🐾',
          title: '새 화면 빠르게 익히기',
          subtitle: '홈 · 내 정원 · 이웃 · 힐링 · 기록을 좌우로 넘겨요',
          accent: AppColors.blobMintAccent,
          background: AppColors.blobMint,
          startExpanded: true,
          items: const [
            _FeatureBullet(
              emoji: '↔️',
              title: '좌우로 공간 이동',
              desc: '큰 카드를 좌우로 넘기거나 아래 메뉴를 눌러 이동해요. 각 공간 안의 내용은 위아래로 볼 수 있어요.',
            ),
            _FeatureBullet(
              emoji: '👤',
              title: '오른쪽 위 간편로그인',
              desc: '홈 오른쪽 위에서 계정 화면을 열고 로그인해요. 로그인한 뒤에는 내 계정으로 표시돼요.',
            ),
            _FeatureBullet(
              emoji: '🐈',
              title: '함께할 고양이 6종',
              desc:
                  '마음돌보기의 고양이 선택에서 원하는 고양이를 골라요. 선택한 친구가 정원과 마음돌보기에 함께해요. 선택·성장에서는 성장과 가족을 살펴봐요. 감정을 기록하는 37마리 고양이와는 별개예요. 테스트 기간에는 구독 기능도 열려 있어요.',
            ),
            _FeatureBullet(
              emoji: '📖',
              title: '마음냥 만화책 = 주간·월간 감정 통계',
              desc:
                  '내가 남긴 편지와 정원 일기를 주간 또는 월간으로 모아 만화책처럼 보여줘요. 마지막 장에서 자주 기록한 감정과 기록한 날짜를 한눈에 봐요. 상단 주간·월간 버튼으로 기간을 바꾸고 상세 통계도 볼 수 있어요.',
            ),
            _FeatureBullet(
              emoji: '🌳',
              title: '정원을 가로로 넓게',
              desc:
                  '정원 공간에서 가로 전체보기를 누르고 휴대폰을 가로로 돌려요. 가로 화면 끝까지 정원이 펼쳐져요. 손가락으로 옆으로 이동하거나 확대해서 둘러봐요. 가로 화면 왼쪽 위에서 세로로 돌아가거나 정원을 나가요. 뒤로 나오면 방향 제한이 풀려요.',
            ),
            _FeatureBullet(
              emoji: '💌',
              title: '기록과 다른 기능 찾기',
              desc:
                  '마음 기록하기로 오늘의 감정 고양이를 만나요. 지난 편지와 통계는 기록 화면에서, 수집·설정은 전체 기능에서 찾아요.',
            ),
          ],
        ),
        _TutorialSection(
          emoji: '🐈',
          title: '고양이선택',
          subtitle: '오늘의 감정과 닮은 고양이를 만나는 핵심 루틴',
          accent: AppColors.blobLavenderAccent,
          background: AppColors.blobLavender,
          items: const [
            _FeatureBullet(
              emoji: '1️⃣',
              title: '고양이 고르기',
              desc:
                  '37마리 고양이 중, 지금 내 기분과 가장 닮은 한 마리를 '
                  '직접 골라요.',
              badge: _Badge.free,
            ),
            _FeatureBullet(
              emoji: '2️⃣',
              title: '사연 보기',
              desc: '고른 고양이가 왜 그런 감정을 느끼는지 짧은 이야기를 읽어요.',
            ),
            _FeatureBullet(
              emoji: '3️⃣',
              title: '편지쓰기',
              desc:
                  '그 고양이에게 하고 싶은 말을 편지로 남겨요. 저장한 뒤 마음의 변화나 '
                  '해보고 싶은 돌봄을 선택할 수 있고, 바로 마무리해도 괜찮아요.',
            ),
            _FeatureBullet(
              emoji: '4️⃣',
              title: '명상 추천',
              desc: '지금 감정에 맞는 명상/움직임 가이드로 바로 이동할 수 있어요.',
            ),
            _FeatureBullet(
              emoji: '5️⃣',
              title: '기록 완료 · 정원 돌보기',
              desc:
                  '편지를 보내면 활동을 표시하는 돌봄 온기가 1도 올라요. '
                  '명상은 원할 때 이어가세요. 이 온도는 감정 상태를 평가하는 점수가 아니에요.',
            ),
          ],
        ),
        _TutorialSection(
          emoji: '🧘',
          title: '명상',
          subtitle: '호흡 · 알아차림 · 움직임 · 표현하기 가이드',
          accent: AppColors.blobMintAccent,
          background: AppColors.blobMint,
          items: const [
            _FeatureBullet(
              emoji: '📚',
              title: '카테고리별 자유 열람',
              desc:
                  '우울할 때, 화날 때, 불안할 때 등 상황별 카테고리로 나뉜 '
                  '가이드를 원하는 만큼 펼쳐서 볼 수 있어요.',
              badge: _Badge.free,
            ),
            _FeatureBullet(
              emoji: '🎬',
              title: '영상으로 따라하기',
              desc:
                  '일부 가이드는 영상이 준비되면 "영상으로 따라하기" 버튼이 '
                  '자동으로 나타나요. 아직 영상이 없는 가이드는 텍스트 단계만 '
                  '보여줘요.',
            ),
            _FeatureBullet(
              emoji: '🔁',
              title: '고양이선택에서도 바로 접근',
              desc:
                  '고양이에게 편지를 쓴 뒤 "명상 추천"을 누르면, 지금 감정에 '
                  '맞는 카테고리만 펼쳐진 채로 이 화면과 같은 가이드를 보여줘요.',
            ),
          ],
        ),
        _TutorialSection(
          emoji: '🌡️',
          title: tr("기록"),
          subtitle: '지나온 마음을 다시 꺼내보는 곳',
          accent: AppColors.blobRoseAccent,
          background: AppColors.blobRose,
          items: const [
            _FeatureBullet(
              emoji: '📈',
              title: '마음냥 만화책',
              desc:
                  '편지와 정원 일기를 주간·월간 감정 통계로 모아 만화책처럼 보여줘요. 마지막 장에서 자주 기록한 감정과 날짜를 살펴봐요.',
              badge: _Badge.free,
            ),
            _FeatureBullet(
              emoji: '🗓️',
              title: '이번 주 돌아보기',
              desc: '이번 주 가장 자주 만난 고양이와 요일별 감정 흐름을 보여줘요.',
              badge: _Badge.free,
            ),
            _FeatureBullet(
              emoji: '📖',
              title: '이번 달 돌아보기',
              desc:
                  '한 달간의 감정 흐름을 문장으로 정리해줘요. 더 깊은 리플렉션 '
                  '레터(그때의 나에게 답장 쓰기)는 정원 플러스 전용이에요.',
              badge: _Badge.plus,
            ),
            _FeatureBullet(
              emoji: '💌',
              title: '보낸 편지 목록',
              desc:
                  '지금까지 고양이에게 쓴 편지를 모두 모아 보여줘요. 편지를 '
                  '누르면 내 편지와 이전에 저장된 답장을 다시 볼 수 있어요.',
              badge: _Badge.free,
            ),
          ],
        ),
        _TutorialSection(
          emoji: '🙋',
          title: tr("마이"),
          subtitle: '나의 여정과 앱 설정을 관리하는 곳',
          accent: AppColors.blobButterAccent,
          background: AppColors.blobButter,
          items: [
            _FeatureBullet(
              emoji: '👤',
              title: '프로필 카드',
              desc: '연속 방문일수와 지금까지 보낸 편지 수를 보여줘요.',
            ),
            _FeatureBullet(
              emoji: '💌',
              title: '정원 플러스 안내',
              desc: '구독 상태를 확인하고, 구독/해지 화면으로 이동할 수 있어요.',
            ),
            _FeatureBullet(
              emoji: '🌷',
              title: tr("냥이 마을 · 내 이웃"),
              desc:
                  '로그인 후 친구 코드로 이웃을 찾거나 공개된 정원을 둘러봐요. '
                  '이웃 신청을 수락하면 서로의 정원을 방문하고 응원과 꽃을 나눌 수 있어요. '
                  '방문을 받으려면 정원 공개 범위도 설정해 주세요.',
            ),
            _FeatureBullet(
              emoji: '⚙️',
              title: tr("설정"),
              desc:
                  '배경음악·효과음 켜고 끄기, 아침/저녁 리마인더 알림을 '
                  '관리해요.',
            ),
            _FeatureBullet(
              emoji: '📘',
              title: '앱 소개 · 개인정보처리방침',
              desc:
                  '이 앱이 무엇에 기반했는지 더 깊은 소개와, 개인정보 처리 '
                  '방침을 확인할 수 있어요.',
            ),
          ],
        ),
        _TutorialSection(
          emoji: '🐾',
          title: '마음 돌보기',
          subtitle: '내가 이름 지은 고양이와 함께하는 돌봄 공간',
          accent: AppColors.blobPeriwinkleAccent,
          background: AppColors.blobPeriwinkle,
          items: const [
            _FeatureBullet(
              emoji: '🍚',
              title: '밥 주기 · 물 주기 · 목욕 · 청소',
              desc: '하루 동안 고양이를 돌보며 돌봄 온기를 조금씩 쌓아요.',
              badge: _Badge.free,
            ),
            _FeatureBullet(
              emoji: '🐱',
              title: '고양이의 반응',
              desc: '고양이가 표정과 짧은 인사로 반겨줘요. 쉬었다 돌아와도 괜찮아요.',
            ),
            _FeatureBullet(
              emoji: '🌿',
              title: '성장 단계',
              desc:
                  '함께 돌보며 아기 → 청소년 → 청년 → 성묘 순으로 자라나요. '
                  '지금까지 함께한 모습과 성장 단계를 돌아볼 수 있어요.',
            ),
            _FeatureBullet(
              emoji: '🛍️',
              title: '정원 플러스 상점',
              desc:
                  '구독자는 돌봄 온기가 100도에 닿을 때마다 포인트를 받아요. '
                  '그림자 방울로도 포인트를 모을 수 있고, 상점에서 먹거리와 꾸미기 아이템에 써요.',
            ),
            _FeatureBullet(
              emoji: '🏅',
              title: '뱃지 컬렉션',
              desc: '출석, 졸업, 수집, 애정표현 등 다양한 활동으로 뱃지를 모아요.',
            ),
            _FeatureBullet(
              emoji: '🎓',
              title: '졸업 앨범',
              desc:
                  '성체까지 다 키운 고양이를 졸업일과 함께 모아봐요. 37마리 '
                  '전체를 졸업시키는 게 목표예요.',
              badge: _Badge.free,
            ),
            _FeatureBullet(
              emoji: '🍼',
              title: '새 아기고양이',
              desc:
                  '한 마리를 졸업시키면, 다음으로 키울 아기고양이를 새로 고를 '
                  '수 있어요.',
            ),
          ],
        ),
        _TutorialSection(
          emoji: '🌱',
          title: '그 외의 작은 의식들',
          subtitle: '전체 기능에서 찾아보세요',
          accent: AppColors.blobPeachAccent,
          background: AppColors.blobPeach,
          items: [
            _FeatureBullet(
              emoji: '🔮',
              title: '오늘의 고양이 카드 (카드뽑기)',
              desc:
                  '무작위로 뽑는 재미용 카드예요. 심리 검사나 미래 예측이 아니며, '
                  '마음에 와닿는 이야기만 가볍게 돌아보세요.',
            ),
            _FeatureBullet(
              emoji: '🌸',
              title: '오늘의 약속',
              desc:
                  '오늘 나를 위해 지켜주고 싶은 작은 일을 남기고, 지킨 만큼 '
                  '체크해나가요. "할 일 목록"이 아니라 스스로에게 건네는 '
                  '다정한 약속이에요.',
            ),
            _FeatureBullet(
              emoji: '🫧',
              title: '오늘의 그림자 방울 터뜨리기',
              desc:
                  '오늘 감정체크(편지쓰기)를 마친 뒤에만 열려요. 오늘 마주한 '
                  '감정을 방울로 만나 하나씩 터뜨리며 가만히 놓아주는 시간이에요.',
            ),
            _FeatureBullet(
              emoji: '🌙',
              title: tr("하루 닫기"),
              desc: '오늘 남긴 약속들을 조용히 돌아보며 하루를 마무리해요.',
              badge: _Badge.free,
            ),
            _FeatureBullet(
              emoji: '🗺️',
              title: '주간 그림자 지도',
              desc:
                  '이번 주 자주 마주한 감정 Top 3를 지도처럼 보여줘요. 지난 '
                  '달/분기 비교와 요일·시간대 패턴은 정원 플러스에서 더 '
                  '깊이 볼 수 있어요.',
              badge: _Badge.plus,
            ),
          ],
        ),
        const SizedBox(height: 6),
        _SectionLabel(emoji: '💌', text: '무료 vs 정원 플러스, 어디까지 다른가요?'),
        const SizedBox(height: 10),
        const _PlusComparisonCard(),
        const SizedBox(height: 18),
        _SectionLabel(emoji: '🌒', text: '이 앱은 무엇에 기반했나요?'),
        const SizedBox(height: 10),
        _BasisCard(),
        const SizedBox(height: 24),
        Center(
          child: Text(
            '궁금한 점을 하나씩 눌러보며,\n천천히 정원을 걸어보세요 🐈‍⬛',
            textAlign: TextAlign.center,
            style: bodyFont(
              fontSize: 12,
              color: AppColors.inkSoft,
              height: 1.7,
            ),
          ),
        ),
      ],
    );
  }
}

/// 최상단 인사말 카드
class _TutorialIntroCard extends StatelessWidget {
  const _TutorialIntroCard();

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    return GlassBlob(
      accent: AppColors.blobMintAccent,
      background: AppColors.blobMint,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📘', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '마음냥 정원, 이렇게 써보세요',
                  style: pathLabelFont(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '이 화면은 앱의 모든 기능이 어디에 있고, 어떻게 쓰면 되는지 '
            '차근차근 안내해드려요. 각 항목을 눌러 펼쳐보세요.',
            style: bodyFont(fontSize: 13, color: AppColors.moon, height: 1.7),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String emoji;
  final String text;
  const _SectionLabel({required this.emoji, required this.text});

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 6),
          Text(
            text,
            style: pathLabelFont(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

enum _Badge { free, plus }

/// 기능 하나를 나타내는 불릿 항목. [badge]가 있으면 "무료"/"PLUS" 태그를
/// 함께 보여줘 무료 범위와 구독 전용 기능을 한눈에 구분할 수 있게 합니다.
class _FeatureBullet extends StatelessWidget {
  final String emoji;
  final String title;
  final String desc;
  final _Badge? badge;
  const _FeatureBullet({
    required this.emoji,
    required this.title,
    required this.desc,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: bodyFont(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    if (badge != null) _BadgeChip(badge: badge!),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: bodyFont(
                    fontSize: 11.5,
                    color: AppColors.inkSoft,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  final _Badge badge;
  const _BadgeChip({required this.badge});

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    final isPlus = badge == _Badge.plus;
    final color = isPlus
        ? AppColors.blobLavenderAccent
        : AppColors.blobMintAccent;
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Text(
        isPlus ? 'PLUS' : '무료',
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

/// 탭 하나(또는 탭 안 세부 기능 묶음)를 펼쳐볼 수 있는 아코디언 카드.
class _TutorialSection extends StatefulWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color accent;
  final Color background;
  final List<_FeatureBullet> items;
  final bool startExpanded;
  const _TutorialSection({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.background,
    required this.items,
    this.startExpanded = false,
  });

  @override
  State<_TutorialSection> createState() => _TutorialSectionState();
}

class _TutorialSectionState extends State<_TutorialSection> {
  late bool _expanded = widget.startExpanded;

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassBlob(
        accent: widget.accent,
        background: widget.background,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _expanded = !_expanded),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                    child: Text(
                      widget.emoji,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: pathLabelFont(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle,
                          style: bodyFont(
                            fontSize: 11,
                            color: AppColors.inkSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: _expanded
                  ? Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: widget.items,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

/// 무료 기능과 정원 플러스(구독) 추가 기능을 정리한 비교 카드.
/// (과거에는 유료 전용 고양이 5마리가 있었지만, 현재는 전원 무료로
/// 전환되어 고양이 관련 구분은 더 이상 존재하지 않습니다.)
class _PlusComparisonCard extends StatelessWidget {
  const _PlusComparisonCard();

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    return GlassBlob(
      accent: AppColors.blobRoseAccent,
      background: AppColors.blobRose,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _BadgeChip(badge: _Badge.free),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '37마리 고양이, 기록과 기본 정원, 기본 주간 통계는 무료예요. '
                  '기본 돌봄 기록과 이웃 응원도 무료예요. 명상은 숲 명상과 빗소리부터 이용할 수 있어요.',
                  style: bodyFont(
                    fontSize: 12,
                    color: AppColors.moon,
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const _BadgeChip(badge: _Badge.plus),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '마음냥 구독은 정원 기록집 만들기, 공동 기념 나무 만들기, 정원 장식과 이야기, '
                  '전체 공개 명상과 상세 돌아보기를 넓혀줘요. 기본 기록집 첫 권은 무료이며, '
                  '구독 종료 후에도 이미 만든 기록집과 내 기록을 볼 수 있어요.',
                  style: bodyFont(
                    fontSize: 12,
                    color: AppColors.moon,
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const PremiumScreen())),
              child: Text(
                '정원 플러스 자세히 보기 →',
                style: bodyFont(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.blobRoseAccent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 앱의 철학적 기반을 짧게 짚어주고, 전체 소개(AboutAppScreen)로 이어주는 카드.
class _BasisCard extends StatelessWidget {
  const _BasisCard();

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    return GlassBlob(
      accent: AppColors.blobLavenderAccent,
      background: AppColors.blobLavender,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '마음냥 정원은 심리학자 칼 융(Carl Jung)의 "그림자(Shadow)" '
            '개념에서 출발했어요. 슬픔, 질투, 분노처럼 밀어내고 싶은 감정도 '
            '없애야 할 것이 아니라 있는 그대로 바라볼 때 나를 더 온전하게 '
            '만들어준다는 생각이에요.\n\n'
            '고양이 고르기는 내가 느낀 감정을 표현하는 활동이고, '
            '오늘의 고양이 카드는 우연히 만난 이야기로 생각을 넓히는 재미용 활동이에요. '
            '카드는 숨겨진 마음을 알아내거나 진단하지 않아요.',
            style: bodyFont(fontSize: 12.5, color: AppColors.moon, height: 1.7),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const AboutAppScreen())),
              child: Text(
                '더 깊은 이야기 읽어보기 →',
                style: bodyFont(
                  fontSize: 12,
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

/// English guidance follows the current five-page layout and content availability.
Widget _englishTutorial(BuildContext context) {
  Widget section(
    String emoji,
    String title,
    String subtitle,
    List<(String, String)> entries, {
    bool open = false,
  }) => _TutorialSection(
    emoji: emoji,
    title: title,
    subtitle: subtitle,
    accent: AppColors.blobMintAccent,
    background: AppColors.blobMint,
    startExpanded: open,
    items: [
      for (final e in entries)
        _FeatureBullet(emoji: '•', title: e.$1, desc: e.$2),
    ],
  );
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('Make yourself at home', style: titleFont(fontSize: 26)),
      const SizedBox(height: 12),
      const Text(
        'There is no perfect routine to keep. Start with a cat, a few words, or a quiet moment in your garden.',
      ),
      const SizedBox(height: 18),
      section('🐾', 'Find your way around', 'Five spaces, all at your own pace', [
        (
          'Home · My garden · Neighbors · Unwind · Journal',
          'Swipe left or right, or use the bottom menu to move between all five pages. Scroll up and down within each page.',
        ),
        (
          'Find a feature',
          'Open All features to browse categories or search for a name, such as backup, breathing, or cards.',
        ),
        (
          'Your account',
          'Open the account button at the top of Home to sign in and manage your account.',
        ),
        (
          'Your companion and your mood cats',
          'Choose from six cat coats for your garden companion. The 37 mood cats are a separate collection that helps you put your feelings into words.',
        ),
      ], open: true),
      section('💌', 'Feelings & letters', 'A little space for whatever you feel', [
        (
          'Choose a mood cat',
          'Choose a cat that feels familiar today and read its story. You decide which feeling fits.',
        ),
        (
          'Write a letter',
          'Write as much or as little as you like. You can also choose a feeling without writing. These are private journal entries, not messages sent to another person.',
        ),
        (
          'Care warmth',
          'Writing and other activities can add care warmth. It marks participation, not your mental health or how well you are doing.',
        ),
        (
          'Look back',
          'Find past letters, your mood calendar, and weekly or monthly reflections in Journal. Your comic book gathers entries into pages, with a summary at the end.',
        ),
        (
          'Delete with care',
          'Read the confirmation before deleting an entry. Check Storage & backup for ways to keep a copy.',
        ),
      ]),
      section('🌱', 'Make your garden your own', 'Plant, care, and remember', [
        (
          'Planting and finding plants',
          'Use your garden tools to plant and care for flowers and trees. Use the plant list to find something you planted.',
        ),
        (
          'A wider view',
          'Open landscape full screen and turn your phone sideways. Pan or zoom to explore. Use the controls to return or leave the garden.',
        ),
        (
          'Memory seeds',
          'Plant a seed of love, forgiveness, or peace. Add a date and a few words to keep with it as it grows.',
        ),
        (
          'Photos and artwork',
          'Use the garden camera to save a moment. Previously displayed artwork stays in your garden. Photos stay private unless you export them.',
        ),
        (
          'Fruit and storage',
          'Harvest fruit, manage your storage, and use the available sell or gift actions. Check quantities before confirming.',
        ),
      ]),
      section('🤝', 'Meet your neighbors', 'Requests, kind words, and gifts', [
        (
          'Connect',
          'Sign in, share your friend code, or enter a friend’s code. Accept a request to connect. Set your garden visibility if you want neighbors to visit.',
        ),
        (
          'Requests',
          'Open Neighbors → Requests to see incoming and outgoing requests. Accept, decline, or cancel from there.',
        ),
        (
          'Gifts',
          'Open Gifts for received and sent gifts. Tap an item to read its details. Collect flower gifts, then plant them when you like. Fruit and treats are stored automatically.',
        ),
        (
          'Privacy',
          'Your private letters and mood entries are not shared with neighbors. You can change visibility, remove a neighbor, or block someone.',
        ),
        (
          'Updates and bookings',
          'Read team announcements and check booking changes for your signed-in account. Availability depends on the event.',
        ),
      ]),
      section('🫧', 'Rest & recharge', 'Small moments of care', [
        (
          'Walk and explore',
          'Take a walk with your cat, look for treasures, or let a feeling drift away in a bubble. The walk pouch is a preview feature.',
        ),
        (
          'English meditation',
          'English meditation and breathing content is still being prepared. It is not available to purchase or play yet.',
        ),
        (
          'Your self-care toolkit',
          'Save words that helped, activities you want to try, and how you felt afterward. A small promise or a moment of gratitude is enough.',
        ),
        (
          'A card for today',
          'Cat cards are playful prompts for reflection. They are not psychological tests, diagnoses, or predictions.',
        ),
      ]),
      section('🐈', 'Care & collections', 'Enjoy being together', [
        (
          'Everyday care',
          'Feed your cat, offer water, bathe, or clean using the available care buttons. Taking a break is okay.',
        ),
        (
          'Growth and memories',
          'Look back at growth stages, cats you have met, badges, and memory cards. Cards can be displayed or traded when eligible.',
        ),
        (
          'Care points',
          'Care points and Light Essence are separate. Check the shop’s cost and requirements before spending either.',
        ),
      ]),
      section('🔐', 'Keep your entries safe', 'Accounts, backups, and settings', [
        (
          'Local storage',
          'Your entries are saved on this device. You could lose them if you uninstall the app or lose your device, so keep a separate backup.',
        ),
        (
          'Encrypted backups',
          'Keep both the backup file and its password. The backup password is separate from your sign-in password and is needed to restore on a new device.',
        ),
        (
          'Cloud backup',
          'Your garden is linked to its backup account. Auto-backup requires an active subscription. Existing backups can still be restored after the subscription ends.',
        ),
        (
          'Sound and reminders',
          'Manage music, effects, volume, and care reminders in account settings. You can turn reminders off.',
        ),
        (
          'Subscriptions',
          'Check the subscription screen for current features and prices, and to restore purchases. Deleting the app or your account does not cancel a store subscription.',
        ),
      ]),
      const SizedBox(height: 12),
      TextButton(
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const PremiumScreen())),
        child: const Text('View subscription details'),
      ),
      const SizedBox(height: 12),
      const Text(
        'A note about the idea behind the garden: Mindnyang draws on Carl Jung’s concept of the shadow—making room for feelings we might otherwise push away. Choosing a cat is a way to express yourself. Neither the cats nor the cards reveal hidden feelings or diagnose you.',
      ),
    ],
  );
}
