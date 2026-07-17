import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/garden_path_card.dart';
import 'about_app_screen.dart';
import 'premium_screen.dart';

/// 앱 사용법 튜토리얼 화면.
///
/// [AboutAppScreen](마이 > 고양이 그림자 정원 소개)이 "이 앱이 어떤 생각에서
/// 시작됐는지"를 다루는 철학적 소개라면, 이 화면은 "실제로 무엇을 할 수 있고
/// 어떻게 쓰면 되는지"를 다루는 기능 지도(사용 설명서)입니다.
///
/// 하단 5개 탭(홈페이지 / 고양이선택 / 명상 / 기록 / 마이) 순서를 그대로 따라가며,
/// 각 탭 안에 있는 세부 기능을 펼쳐서 볼 수 있는 아코디언 목록으로 구성합니다.
/// 마지막에는 무료/정원 플러스(구독) 범위를 정리하고, 이 앱의 기반이 되는
/// 생각(칼 융의 그림자 개념)을 짧게 짚어준 뒤 [AboutAppScreen]으로 더 깊이
/// 들어갈 수 있는 링크를 제공합니다.
class AppTutorialScreen extends StatelessWidget {
  const AppTutorialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _TutorialIntroCard(),
        const SizedBox(height: 18),
        _SectionLabel(emoji: '🗺️', text: '탭 순서대로 살펴보기'),
        const SizedBox(height: 10),
        _TutorialSection(
          emoji: '🏡',
          title: '홈페이지',
          subtitle: '정원의 중심 - 모든 기능으로 이어지는 산책로',
          accent: AppColors.blobPeachAccent,
          background: AppColors.blobPeach,
          startExpanded: true,
          items: const [
            _FeatureBullet(
              emoji: '🐾',
              title: '그림자 고양이 여정',
              desc: '지금까지 만난 고양이 수(무료 42마리 기준)와 진행률을 보여주고, '
                  '"오늘의 고양이 만나기" 버튼으로 고양이선택 탭으로 바로 이동해요.',
            ),
            _FeatureBullet(
              emoji: '🔥',
              title: '며칠째 함께하는 중 (스트릭)',
              desc: '앱을 연속으로 방문한 날짜 수를 보여줘요. 하루라도 건너뛰면 '
                  '다시 1일부터 세어져요.',
            ),
            _FeatureBullet(
              emoji: '🌱',
              title: '성장 현황',
              desc: '아기고양이 모찌가 지금 아기 / 청소년 / 청년 / 성묘 중 어느 '
                  '단계인지 한눈에 보여줘요.',
            ),
            _FeatureBullet(
              emoji: '🔗',
              title: '8개의 정원 산책로 카드',
              desc: '명상·움직임, 마음온도기록, 마음 돌보기, 데일리 내면소통, '
                  '오늘의 약속, 그림자 방울 터뜨리기, 주간 그림자 지도, 하루 닫기까지 '
                  '아래로 하나씩 이어져 있어요. 카드를 누르면 각 기능으로 이동해요.',
            ),
            _FeatureBullet(
              emoji: '💌',
              title: '답장 · 새싹 · 회고 배너',
              desc: '고양이의 답장이 도착했거나, 묻어둔 감정이 새싹으로 떠올랐거나, '
                  '주간/월간 돌아보기가 준비됐을 때만 상단에 조용히 나타나요. '
                  '강제 알림이 아니라 눌러야만 열리는 카드예요.',
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
              desc: '42마리 무료 고양이 + 10마리 정원 플러스 전용 고양이 중, '
                  '지금 내 기분과 가장 닮은 한 마리를 직접 골라요.',
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
              desc: '그 고양이에게 하고 싶은 말을 편지로 남겨요. 다음날 아침 '
                  '고양이의 답장이 도착해요(기록 탭에서 확인).',
            ),
            _FeatureBullet(
              emoji: '4️⃣',
              title: '명상 추천',
              desc: '지금 감정에 맞는 명상/움직임 가이드로 바로 이동할 수 있어요.',
            ),
            _FeatureBullet(
              emoji: '5️⃣',
              title: '마음 온도 체크 · 완료',
              desc: '편지를 쓰기 전/후 마음 온도를 기록해 변화를 남겨요.',
            ),
            _FeatureBullet(
              emoji: '🔒',
              title: '유료 고양이는 안개처리로만 노출',
              desc: '정원 플러스 전용 10마리는 카드가 흐릿하게 보이지만 완전히 '
                  '숨겨지진 않아요. 탭하면 소개만 볼 수 있고, 실제로 만나려면 '
                  '구독이 필요해요.',
              badge: _Badge.plus,
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
              desc: '우울할 때, 화날 때, 불안할 때 등 상황별 카테고리로 나뉜 '
                  '가이드를 원하는 만큼 펼쳐서 볼 수 있어요.',
              badge: _Badge.free,
            ),
            _FeatureBullet(
              emoji: '🎬',
              title: '영상으로 따라하기',
              desc: '일부 가이드는 영상이 준비되면 "영상으로 따라하기" 버튼이 '
                  '자동으로 나타나요. 아직 영상이 없는 가이드는 텍스트 단계만 '
                  '보여줘요.',
            ),
            _FeatureBullet(
              emoji: '🔁',
              title: '고양이선택에서도 바로 접근',
              desc: '고양이에게 편지를 쓴 뒤 "명상 추천"을 누르면, 지금 감정에 '
                  '맞는 카테고리만 펼쳐진 채로 이 화면과 같은 가이드를 보여줘요.',
            ),
          ],
        ),
        _TutorialSection(
          emoji: '🌡️',
          title: '기록',
          subtitle: '지나온 마음을 다시 꺼내보는 곳',
          accent: AppColors.blobRoseAccent,
          background: AppColors.blobRose,
          items: const [
            _FeatureBullet(
              emoji: '📈',
              title: '마음온도기록',
              desc: '그동안 기록한 마음 온도를 주간/월간 그래프로 볼 수 있어요.',
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
              desc: '한 달간의 감정 흐름을 문장으로 정리해줘요. 더 깊은 리플렉션 '
                  '레터(그때의 나에게 답장 쓰기)는 정원 플러스 전용이에요.',
              badge: _Badge.plus,
            ),
            _FeatureBullet(
              emoji: '💌',
              title: '보낸 편지 목록',
              desc: '지금까지 고양이에게 쓴 편지를 모두 모아 보여줘요. 편지를 '
                  '누르면 상세 내용과 답장을 다시 볼 수 있어요.',
              badge: _Badge.free,
            ),
          ],
        ),
        _TutorialSection(
          emoji: '🙋',
          title: '마이',
          subtitle: '나의 여정과 앱 설정을 관리하는 곳',
          accent: AppColors.blobButterAccent,
          background: AppColors.blobButter,
          items: const [
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
              emoji: '⚙️',
              title: '설정',
              desc: '배경음악·효과음 켜고 끄기, 아침/저녁 리마인더 알림을 '
                  '관리해요.',
            ),
            _FeatureBullet(
              emoji: '📘',
              title: '앱 소개 · 개인정보처리방침',
              desc: '이 앱이 무엇에 기반했는지 더 깊은 소개와, 개인정보 처리 '
                  '방침을 확인할 수 있어요.',
            ),
          ],
        ),
        _TutorialSection(
          emoji: '🐾',
          title: '마음 돌보기',
          subtitle: '아기고양이 모찌를 함께 키우는 육성 공간',
          accent: AppColors.blobPeriwinkleAccent,
          background: AppColors.blobPeriwinkle,
          items: const [
            _FeatureBullet(
              emoji: '🍚',
              title: '밥 주기 · 물 주기 · 목욕 · 청소',
              desc: '하루 동안 모찌를 돌보며 마음 온도를 조금씩 올려요.',
              badge: _Badge.free,
            ),
            _FeatureBullet(
              emoji: '🐱',
              title: '모찌의 감정 반응',
              desc: '며칠 만에 돌아왔는지에 따라 모찌의 표정이 반갑고 신났는지, '
                  '기다렸는지, 서운했는지, 걱정했는지로 바뀌어요.',
            ),
            _FeatureBullet(
              emoji: '🌿',
              title: '성장 단계',
              desc: '아기 → 청소년 → 청년 → 성묘 순으로 자라나요. 아기 단계는 '
                  '진짜 프레임 애니메이션(모찌)이고, 이후 단계는 정지 이미지에 '
                  '숨쉬기·부유 같은 잔잔한 움직임을 더한 모습으로 표현돼요.',
            ),
            _FeatureBullet(
              emoji: '🛍️',
              title: '정원 플러스 상점',
              desc: '마음 온도가 100도에 닿을 때마다 쌓이는 포인트로 먹거리, '
                  '옷·악세서리, 우리집 가구를 구매해요.',
            ),
            _FeatureBullet(
              emoji: '🏅',
              title: '뱃지 컬렉션',
              desc: '출석, 졸업, 수집, 애정표현 등 다양한 활동으로 뱃지를 모아요.',
            ),
            _FeatureBullet(
              emoji: '🎓',
              title: '졸업 앨범',
              desc: '성체까지 다 키운 고양이를 졸업일과 함께 모아봐요. 무료 42마리 '
                  '전체를 졸업시키는 게 목표예요.',
              badge: _Badge.free,
            ),
            _FeatureBullet(
              emoji: '🍼',
              title: '새 아기고양이',
              desc: '한 마리를 졸업시키면, 다음으로 키울 아기고양이를 새로 고를 '
                  '수 있어요.',
            ),
          ],
        ),
        _TutorialSection(
          emoji: '🌱',
          title: '그 외의 작은 의식들',
          subtitle: '홈페이지 산책로 곳곳에 숨어있는 짧은 기능들',
          accent: AppColors.blobPeachAccent,
          background: AppColors.blobPeach,
          items: const [
            _FeatureBullet(
              emoji: '🔮',
              title: '데일리 내면소통 (카드뽑기)',
              desc: '고양이를 직접 고르지 않고, 오늘의 카드 한 장을 무작위로 '
                  '뽑아 위로와 실천 지침을 받아요. 의식적으로 고른 고양이와 '
                  '뽑힌 고양이가 같으면 "동시성"이라 불러요.',
            ),
            _FeatureBullet(
              emoji: '🌸',
              title: '오늘의 약속',
              desc: '오늘 나를 위해 지켜주고 싶은 작은 일을 남기고, 지킨 만큼 '
                  '체크해나가요. "할 일 목록"이 아니라 스스로에게 건네는 '
                  '다정한 약속이에요.',
            ),
            _FeatureBullet(
              emoji: '🫧',
              title: '오늘의 그림자 방울 터뜨리기',
              desc: '오늘 감정체크(편지쓰기)를 마친 뒤에만 열려요. 오늘 마주한 '
                  '감정을 방울로 만나 하나씩 터뜨리며 가만히 놓아주는 시간이에요.',
            ),
            _FeatureBullet(
              emoji: '🌙',
              title: '하루 닫기',
              desc: '오늘 남긴 약속들을 조용히 돌아보며 하루를 마무리해요.',
              badge: _Badge.free,
            ),
            _FeatureBullet(
              emoji: '🗺️',
              title: '주간 그림자 지도',
              desc: '이번 주 자주 마주한 감정 Top 3를 지도처럼 보여줘요. 지난 '
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
            style: bodyFont(fontSize: 12, color: AppColors.inkSoft, height: 1.7),
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
                  '고양이 그림자 정원, 이렇게 써보세요',
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
    final isPlus = badge == _Badge.plus;
    final color = isPlus ? AppColors.blobLavenderAccent : AppColors.blobMintAccent;
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

/// 무료 42마리와 정원 플러스(구독) 10마리 + 추가 기능을 정리한 비교 카드.
class _PlusComparisonCard extends StatelessWidget {
  const _PlusComparisonCard();

  @override
  Widget build(BuildContext context) {
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
                  '42마리 고양이, 마음 돌보기, 명상 가이드 전체, 기록 기본 기능은 '
                  '누구나 무료로 계속 이용할 수 있어요.',
                  style: bodyFont(fontSize: 12, color: AppColors.moon, height: 1.6),
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
                  '정원 플러스(월 구독)는 냉소·시기 같은 섬세한 감정의 고양이 '
                  '10마리와, 주간 그림자 지도의 심층 분석(지난달/분기 비교, '
                  '요일·시간대 패턴)을 추가로 열어줘요.',
                  style: bodyFont(fontSize: 12, color: AppColors.moon, height: 1.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PremiumScreen()),
              ),
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
    return GlassBlob(
      accent: AppColors.blobLavenderAccent,
      background: AppColors.blobLavender,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '고양이 그림자 정원은 심리학자 칼 융(Carl Jung)의 "그림자(Shadow)" '
            '개념에서 출발했어요. 슬픔, 질투, 분노처럼 밀어내고 싶은 감정도 '
            '없애야 할 것이 아니라 있는 그대로 바라볼 때 나를 더 온전하게 '
            '만들어준다는 생각이에요.\n\n'
            '42마리 고양이는 그 감정의 스펙트럼을 나눈 것이고, "고양이 고르기"는 '
            '내가 의식적으로 알아차린 감정을, "데일리 내면소통(카드뽑기)"는 '
            '무의식이 보내는 신호를 들여다보는 두 가지 방법이에요.',
            style: bodyFont(fontSize: 12.5, color: AppColors.moon, height: 1.7),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AboutAppScreen()),
              ),
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
