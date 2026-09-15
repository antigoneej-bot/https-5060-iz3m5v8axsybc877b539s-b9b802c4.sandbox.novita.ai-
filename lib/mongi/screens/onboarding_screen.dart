import '../../theme.dart' show AppColors;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/gen/app_localizations.dart';
import '../providers/garden_provider.dart';
import 'emotion_input_screen.dart';

/// 처음 실행할 때만 보여주는 짧은 튜토리얼.
/// - 몽이 소개 -> 조작법(걷기/주먹/점프) -> 감정 먹기 -> 정원 성장 순서로
///   4장을 넘기면서 핵심 플레이 방식을 부담 없이 알려준다.
/// 언제든 "건너뛰기"로 바로 시작할 수 있다.
class OnboardingScreen extends StatefulWidget {
  /// true이면 "다시보기"로 열린 경우 - 끝나면 이전 화면으로 되돌아간다(pop).
  /// false(기본, 최초 실행)면 끝나면 첫 화면으로 교체(pushReplacement)한다.
  final bool isReplay;

  const OnboardingScreen({super.key, this.isReplay = false});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  static const int _pageCount = 4;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (widget.isReplay) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    await context.read<GardenProvider>().markOnboardingSeen();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const EmotionInputScreen()),
    );
  }

  void _next() {
    if (_page == _pageCount - 1) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFE8EE), Color(0xFFEAF6FF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8, top: 2),
                  child: TextButton(
                    onPressed: _finish,
                    child: Text(
                      l10n.onboardingSkip,
                      style: const TextStyle(
                        color: AppColors.inkSoft,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _controller,
                  onPageChanged: (i) => setState(() => _page = i),
                  children: [
                    _OnboardingPage(
                      image: 'assets/mongi/images/cat_idle.png',
                      title: l10n.onboardingPage1Title,
                      description: l10n.onboardingPage1Desc,
                    ),
                    _OnboardingPage(
                      image: 'assets/mongi/images/cat_walk_1.png',
                      title: l10n.onboardingPage2Title,
                      description: l10n.onboardingPage2Desc,
                      emojiHint: '🏃🐾',
                    ),
                    _OnboardingPage(
                      image: 'assets/mongi/images/cat_punch.png',
                      title: l10n.onboardingPage3Title,
                      description: l10n.onboardingPage3Desc,
                    ),
                    _OnboardingPage(
                      image: 'assets/mongi/images/cat_eating.png',
                      title: l10n.onboardingPage4Title,
                      description: l10n.onboardingPage4Desc,
                    ),
                  ],
                ),
              ),
              _buildIndicator(),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _next,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.roseStrong,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      elevation: 4,
                    ),
                    child: Text(
                      _page == _pageCount - 1
                          ? l10n.onboardingFinish
                          : l10n.onboardingNext,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pageCount, (i) {
        final active = i == _page;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? AppColors.roseStrong : const Color(0xFFFFD1DC),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final String image;
  final String title;
  final String description;
  final String? emojiHint;

  const _OnboardingPage({
    required this.image,
    required this.title,
    required this.description,
    this.emojiHint,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.75),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Image.asset(image, height: 160),
          ),
          if (emojiHint != null) ...[
            const SizedBox(height: 12),
            Text(emojiHint!, style: const TextStyle(fontSize: 28)),
          ],
          const SizedBox(height: 28),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14.5,
              color: AppColors.inkSoft,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
