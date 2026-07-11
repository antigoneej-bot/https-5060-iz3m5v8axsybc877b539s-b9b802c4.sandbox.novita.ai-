import 'dart:math';
import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/sound_service.dart';
import '../theme.dart';
import 'privacy_policy_screen.dart';

/// 랜덤 이름 추천 후보 목록
const List<String> kRandomCatNames = [
  '구름',
  '별이',
  '모모',
  '나비',
  '콩이',
  '두부',
  '보리',
  '자몽',
  '몽이',
  '설이',
  '루비',
  '토리',
  '삐약',
  '깜지',
  '솜이',
  '연두',
  '초코',
  '망고',
];

/// 앱을 처음 설치하고 실행했을 때 딱 한 번 보여주는 프리미엄 웰컴 투어.
/// Calm · Headspace 수준의 여백과 따뜻함을 지향하며, 과한 모션 없이
/// 스와이프에 따라 아주 부드럽게 페이드 + 스케일되는 패럴랙스만 사용합니다.
class WelcomeIntroScreen extends StatefulWidget {
  final VoidCallback onFinished;
  const WelcomeIntroScreen({super.key, required this.onFinished});

  @override
  State<WelcomeIntroScreen> createState() => _WelcomeIntroScreenState();
}

class _IntroPageData {
  final String? imageAsset;
  final String title;
  final String? subtitle;
  final bool isNamingPage;
  final bool isJourneyStartPage;
  const _IntroPageData({
    this.imageAsset,
    required this.title,
    this.subtitle,
    this.isNamingPage = false,
    this.isJourneyStartPage = false,
  });
}

class _WelcomeIntroScreenState extends State<WelcomeIntroScreen> {
  final PageController _pageController = PageController();
  double _page = 0;
  final TextEditingController _nameController = TextEditingController();
  bool _saving = false;
  bool _showGreeting = false;
  String _greetingName = '';

  // 이름짓기 화면을 앱 실행 시 가장 먼저 보여줘서, 이름을 지어준 순간부터
  // 곧바로 그 이름과 함께 몰입할 수 있도록 첫 페이지에 배치합니다.
  static const List<_IntroPageData> _pages = [
    _IntroPageData(
      imageAsset: 'assets/onboarding_intro/intro_naming_kitten.png',
      title: '당신과 함께 성장할 아기고양이에게\n이름을 지어주세요.',
      subtitle: '이 아이는 당신의 마음을 함께 돌보고,\n명상과 기록을 통해 조금씩 성장합니다.',
      isNamingPage: true,
    ),
    _IntroPageData(
      imageAsset: 'assets/onboarding_intro/intro_1_garden_smile.png',
      title: '마음을 돌보는\n가장 따뜻한 여행이 시작됩니다.',
    ),
    _IntroPageData(
      imageAsset: 'assets/onboarding_intro/intro_2_circle_emotions.png',
      title: '오늘의 마음을 닮은\n고양이를 만나보세요.',
    ),
    _IntroPageData(
      imageAsset: 'assets/onboarding_intro/intro_3_growth.png',
      title: '명상을 할수록\n당신과 고양이가 함께 성장합니다.',
    ),
    _IntroPageData(title: '작은 실천이\n당신의 마음을 변화시킵니다.'),
    _IntroPageData(
      imageAsset: 'assets/onboarding_intro/intro_5_garden_grown.png',
      title: '이제 당신만의\n마음 정원을 만들어 보세요.',
      isJourneyStartPage: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() => _page = _pageController.page ?? 0);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _goNext() {
    SoundService().tryStartBgm();
    if (_pageController.page == null) return;
    final next = _pageController.page!.round() + 1;
    if (next < _pages.length) {
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeOutCubic,
      );
    }
  }

  /// 이름짓기(첫 페이지)에서 [함께 시작하기]를 눌렀을 때 - 이름을 저장하고
  /// 아기고양이가 반겨주는 짧은 인사를 보여준 뒤, 나머지 웰컴 투어로 이어집니다.
  Future<void> _confirmName() async {
    if (_saving) return;
    SoundService().tryStartBgm();
    setState(() => _saving = true);
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      await StorageService.setCompanionName(name);
    }
    if (!mounted) return;
    setState(() {
      _greetingName = name.isNotEmpty ? name : '아이';
      _showGreeting = true;
      _saving = false;
    });
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;
    setState(() => _showGreeting = false);
    _goNext();
  }

  /// 마지막 페이지(여행 시작하기)에서 호출 - 웰컴 투어를 완전히 마칩니다.
  Future<void> _finish() async {
    SoundService().tryStartBgm();
    await StorageService.setWelcomeIntroCompleted();
    if (!mounted) return;
    widget.onFinished();
  }

  void _suggestRandomName() {
    SoundService().tryStartBgm();
    final rng = Random();
    String candidate;
    do {
      candidate = kRandomCatNames[rng.nextInt(kRandomCatNames.length)];
    } while (candidate == _nameController.text.trim() &&
        kRandomCatNames.length > 1);
    setState(() {
      _nameController.text = candidate;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      final data = _pages[index];
                      final delta = (_page - index);
                      final opacity = (1 - delta.abs() * 1.1).clamp(0.0, 1.0);
                      final scale = (1 - delta.abs() * 0.08).clamp(0.85, 1.0);
                      final slide = delta * 26;
                      return Opacity(
                        opacity: opacity,
                        child: Transform.translate(
                          offset: Offset(slide, 0),
                          child: Transform.scale(
                            scale: scale,
                            child: _buildPageContent(data, index),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                _buildBottomArea(),
                const SizedBox(height: 8),
                _DotsIndicator(count: _pages.length, page: _page),
                const SizedBox(height: 22),
              ],
            ),
          ),
          if (_showGreeting) _GreetingOverlay(name: _greetingName),
        ],
      ),
    );
  }

  Widget _buildPageContent(_IntroPageData data, int index) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
      child: Column(
        children: [
          Expanded(
            child: data.imageAsset != null
                ? _ImageArt(imageAsset: data.imageAsset!)
                : const _GrowthPreviewArt(),
          ),
          const SizedBox(height: 22),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: serifFont(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
              height: 1.5,
            ),
          ),
          if (data.subtitle != null) ...[
            const SizedBox(height: 10),
            Text(
              data.subtitle!,
              textAlign: TextAlign.center,
              style: bodyFont(
                fontSize: 12.5,
                color: AppColors.inkSoft,
                height: 1.6,
              ),
            ),
          ],
          if (data.isNamingPage) ...[
            const SizedBox(height: 20),
            _NameField(
              controller: _nameController,
              onRandomTap: _suggestRandomName,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomArea() {
    final index = _page.round();
    final current = _pages[index];

    if (current.isNamingPage) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: _PrimaryButton(
          label: '이름 정해주기',
          onTap: _saving ? null : _confirmName,
          loading: _saving,
        ),
      );
    }
    if (current.isJourneyStartPage) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          children: [
            _PrimaryButton(label: '시작하기', onTap: _finish),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const PrivacyPolicyScreen(),
                  ),
                );
              },
              child: Text(
                '개인정보처리방침 · 정신건강 안내 보기',
                style: bodyFont(
                  fontSize: 11.5,
                  color: AppColors.inkSoft,
                  height: 1.4,
                ).copyWith(decoration: TextDecoration.underline),
              ),
            ),
          ],
        ),
      );
    }
    // 화면 1(가든 스마일)·2·3·4: 스와이프로도 넘어갈 수 있고, 부드러운 다음
    // 버튼도 함께 제공합니다. "시작하기" 문구는 마지막 페이지에만 남깁니다.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Align(
        alignment: Alignment.centerRight,
        child: _NextArrowButton(onTap: _goNext),
      ),
    );
  }
}

class _ImageArt extends StatelessWidget {
  final String imageAsset;
  const _ImageArt({required this.imageAsset});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 30,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Image.asset(
          imageAsset,
          fit: BoxFit.cover,
          width: double.infinity,
        ),
      ),
    );
  }
}

/// 화면 4: 마음 온도계 · 감정 기록 · 명상 기록 · 성장 배지를 코드로 표현한 프리뷰
class _GrowthPreviewArt extends StatelessWidget {
  const _GrowthPreviewArt();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.bg1,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: AppColors.line),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '마음 온도',
              style: bodyFont(fontSize: 12, color: AppColors.inkSoft),
            ),
            const SizedBox(height: 8),
            Container(
              width: 180,
              height: 14,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF6FA8DC),
                    AppColors.gold,
                    Color(0xFFD9695A),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _miniBadge(
                  icon: Icons.favorite_rounded,
                  label: '감정 기록',
                  color: AppColors.catDustyRose,
                  bg: AppColors.catDustyRoseBg,
                ),
                const SizedBox(width: 12),
                _miniBadge(
                  icon: Icons.self_improvement_rounded,
                  label: '명상 기록',
                  color: AppColors.catLavender,
                  bg: AppColors.catLavenderBg,
                ),
                const SizedBox(width: 12),
                _miniBadge(
                  icon: Icons.emoji_events_rounded,
                  label: '성장 배지',
                  color: AppColors.gold,
                  bg: const Color(0xFFFCEFD2),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniBadge({
    required IconData icon,
    required String label,
    required Color color,
    required Color bg,
  }) {
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 6),
        Text(label, style: bodyFont(fontSize: 10.5, color: AppColors.inkSoft)),
      ],
    );
  }
}

class _NameField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onRandomTap;
  const _NameField({required this.controller, required this.onRandomTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.bg1,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line),
          ),
          child: TextField(
            controller: controller,
            textAlign: TextAlign.center,
            style: serifFont(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              hintText: '예) 구름, 별이, 모모, 나비',
              hintStyle: bodyFont(fontSize: 13.5, color: AppColors.inkSoft),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onRandomTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.bg2,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🎲', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 6),
                  Text(
                    '랜덤 이름 추천',
                    style: bodyFont(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.goldSoft,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  const _PrimaryButton({
    required this.label,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: AppColors.gold.withValues(alpha: 0.35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: serifFont(fontSize: 15.5, color: Colors.white),
              ),
      ),
    );
  }
}

class _NextArrowButton extends StatelessWidget {
  final VoidCallback onTap;
  const _NextArrowButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.bg2,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 54,
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.arrow_forward_rounded,
            color: AppColors.goldSoft,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _DotsIndicator extends StatelessWidget {
  final int count;
  final double page;
  const _DotsIndicator({required this.count, required this.page});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final dist = (page - i).abs().clamp(0.0, 1.0);
        final width = 8.0 + (1 - dist) * 12.0;
        final color = Color.lerp(AppColors.line, AppColors.goldSoft, 1 - dist)!;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: width,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

/// 이름을 지어준 순간, 아기고양이가 반겨주는 짧은 인사 오버레이.
/// "기다리고 있었어요. 야옹" 문구가 부드럽게 떠오르며 여운을 남깁니다.
class _GreetingOverlay extends StatefulWidget {
  final String name;
  const _GreetingOverlay({required this.name});

  @override
  State<_GreetingOverlay> createState() => _GreetingOverlayState();
}

class _GreetingOverlayState extends State<_GreetingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _rise;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _rise = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: FadeTransition(
        opacity: _fade,
        child: Container(
          color: AppColors.bg0.withValues(alpha: 0.97),
          child: SafeArea(
            child: Center(
              child: SlideTransition(
                position: _rise,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 36),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Color(0xFFFFF6DF),
                              AppColors.goldSoft,
                              AppColors.gold,
                            ],
                            stops: [0, 0.55, 1],
                          ),
                        ),
                        child: const Text('🐱', style: TextStyle(fontSize: 40)),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        widget.name,
                        textAlign: TextAlign.center,
                        style: serifFont(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.gold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '기다리고 있었어요. 야옹',
                        textAlign: TextAlign.center,
                        style: serifFont(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
