import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/shadow_cat.dart';
import '../providers/app_state_provider.dart';
import '../services/storage_service.dart';
import '../theme.dart';
import '../widgets/animated_cat_art.dart';
import '../widgets/stars_background.dart';

/// 고양이를 처음 만난 순간 이어지는 최초 1회 온보딩 플로우.
/// 편지쓰기(비회원) → 전송 연출 → 가입 유도(소셜 로그인) → 알림 동의 → 홈으로.
///
/// 회원가입을 앞세우지 않고, 사용자가 이미 감정적으로 몰입한 순간(편지를 보낸 직후)에만
/// 자연스럽게 가입을 요청합니다. 사전 설문/목표선택/다단계 퀴즈는 두지 않습니다.
class OnboardingFlowScreen extends StatefulWidget {
  final ShadowCat cat;
  const OnboardingFlowScreen({super.key, required this.cat});

  @override
  State<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

enum _OnboardingStep { letter, sending, signup, notification }

class _OnboardingFlowScreenState extends State<OnboardingFlowScreen> {
  _OnboardingStep _step = _OnboardingStep.letter;
  final TextEditingController _letterController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _letterController.dispose();
    super.dispose();
  }

  Future<void> _onSendLetter() async {
    if (_letterController.text.trim().isEmpty || _busy) return;
    setState(() {
      _busy = true;
      _step = _OnboardingStep.sending;
    });
    // 편지를 실제로 저장 (비회원 상태에서도 로컬에 기록됨)
    await context.read<AppStateProvider>().saveOnboardingLetter(
      _letterController.text.trim(),
    );
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    setState(() {
      _busy = false;
      _step = _OnboardingStep.signup;
    });
  }

  Future<void> _onChooseProvider(String provider) async {
    if (_busy) return;
    setState(() => _busy = true);
    // 실제 OAuth 연동 전까지는, 로컬 전용 구조에 맞춰 클릭 한 번으로 가입을 완료 처리합니다.
    await Future.delayed(const Duration(milliseconds: 550));
    await StorageService.setLoginProvider(provider);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _step = _OnboardingStep.notification;
    });
  }

  Future<void> _onNotificationChoice(bool optIn) async {
    await StorageService.setNotificationOptIn(optIn);
    await StorageService.setOnboardingCompleted();
    if (!mounted) return;
    final app = context.read<AppStateProvider>();
    app.finishOnboarding();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Widget _buildStep() {
    switch (_step) {
      case _OnboardingStep.letter:
        return _OnboardingLetterStep(
          key: const ValueKey('letter'),
          cat: widget.cat,
          controller: _letterController,
          busy: _busy,
          onSend: _onSendLetter,
        );
      case _OnboardingStep.sending:
        return _SendingAnimationStep(
          key: const ValueKey('sending'),
          cat: widget.cat,
        );
      case _OnboardingStep.signup:
        return _SignupPromptStep(
          key: const ValueKey('signup'),
          busy: _busy,
          onChooseProvider: _onChooseProvider,
        );
      case _OnboardingStep.notification:
        return _NotificationPromptStep(
          key: const ValueKey('notification'),
          onChoice: _onNotificationChoice,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GardenScaffoldBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 420),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) =>
                      FadeTransition(opacity: animation, child: child),
                  child: _buildStep(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 1단계: 편지 쓰기 (비회원 가능, 텍스트 입력창 하나만 있는 단순한 화면)
class _OnboardingLetterStep extends StatelessWidget {
  final ShadowCat cat;
  final TextEditingController controller;
  final bool busy;
  final VoidCallback onSend;
  const _OnboardingLetterStep({
    super.key,
    required this.cat,
    required this.controller,
    required this.busy,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          AnimatedCatArt(imageAsset: cat.imageAsset, size: 120),
          const SizedBox(height: 20),
          Text(
            '${cat.nameKr}에게',
            style: serifFont(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            decoration: BoxDecoration(
              color: AppColors.bg1,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.line),
            ),
            child: TextField(
              controller: controller,
              minLines: 6,
              maxLines: 10,
              autofocus: true,
              style: bodyFont(fontSize: 14, color: AppColors.moon, height: 1.6),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: '지금 이 마음을 이 아이에게 들려주세요',
                hintStyle: bodyFont(
                  fontSize: 13.5,
                  color: AppColors.inkSoft,
                  height: 1.6,
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: busy ? null : onSend,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                elevation: 0,
              ),
              child: Text(
                '보내기',
                style: serifFont(fontSize: 15, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 2단계 전반부: 편지가 고양이에게 전달되는 짧은 연출 (1~2초)
class _SendingAnimationStep extends StatefulWidget {
  final ShadowCat cat;
  const _SendingAnimationStep({super.key, required this.cat});

  @override
  State<_SendingAnimationStep> createState() => _SendingAnimationStepState();
}

class _SendingAnimationStepState extends State<_SendingAnimationStep>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          SizedBox(
            height: 140,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final t = _controller.value;
                final letterOpacity = (1 - t * 1.4).clamp(0.0, 1.0);
                final letterScale = 1.0 - 0.5 * t;
                final letterDy = -30 * t;
                final catScale = 1.0 + 0.12 * sin(t * pi);
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.scale(
                      scale: catScale,
                      child: AnimatedCatArt(
                        imageAsset: widget.cat.imageAsset,
                        size: 96,
                      ),
                    ),
                    Transform.translate(
                      offset: Offset(0, letterDy - 40),
                      child: Opacity(
                        opacity: letterOpacity,
                        child: Transform.scale(
                          scale: letterScale,
                          child: const Text(
                            '💌',
                            style: TextStyle(fontSize: 40),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          Text(
            '편지가 ${widget.cat.nameKr}에게 도착했어요',
            style: serifFont(
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

/// 2단계 후반부: 가입 유도 (소셜 로그인 3개 크게, 이메일은 하단 작은 텍스트 링크)
class _SignupPromptStep extends StatelessWidget {
  final bool busy;
  final Future<void> Function(String provider) onChooseProvider;
  const _SignupPromptStep({
    super.key,
    required this.busy,
    required this.onChooseProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '이 편지, 계속 이어가고 싶다면',
            textAlign: TextAlign.center,
            style: serifFont(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '당신과 이 아이의 이야기는 여기서 계속돼요.\n당신이 쓴 편지를 기억하고,\n마음의 온도가 자라나는 걸 함께 지켜볼게요.',
            textAlign: TextAlign.center,
            style: bodyFont(
              fontSize: 13.5,
              color: AppColors.inkSoft,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 32),
          _SocialButton(
            label: '카카오로 계속하기',
            background: const Color(0xFFFEE500),
            foreground: const Color(0xFF391B1B),
            icon: const Text('💬', style: TextStyle(fontSize: 17)),
            onTap: busy ? null : () => onChooseProvider('kakao'),
          ),
          const SizedBox(height: 12),
          _SocialButton(
            label: 'Apple로 계속하기',
            background: const Color(0xFF1B1B1B),
            foreground: Colors.white,
            icon: const Icon(Icons.apple, size: 19, color: Colors.white),
            onTap: busy ? null : () => onChooseProvider('apple'),
          ),
          const SizedBox(height: 12),
          _SocialButton(
            label: 'Google로 계속하기',
            background: Colors.white,
            foreground: const Color(0xFF383032),
            border: AppColors.line,
            icon: const Text(
              'G',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4285F4),
              ),
            ),
            onTap: busy ? null : () => onChooseProvider('google'),
          ),
          const SizedBox(height: 18),
          if (busy)
            const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: AppColors.goldSoft,
                ),
              ),
            )
          else
            Center(
              child: TextButton(
                onPressed: () => onChooseProvider('email'),
                child: Text(
                  '이메일로 계속할게요',
                  style:
                      bodyFont(
                        fontSize: 12.5,
                        color: AppColors.inkSoft,
                        height: 1.4,
                      ).copyWith(
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.inkSoft,
                      ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final Color? border;
  final Widget icon;
  final VoidCallback? onTap;
  const _SocialButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.icon,
    required this.onTap,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: border != null ? BorderSide(color: border!) : BorderSide.none,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 8),
            Text(
              label,
              style: bodyFont(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 3단계: 알림 권한 요청 (선택적, 부드럽게 - 거절 버튼도 동등한 톤/크기)
class _NotificationPromptStep extends StatelessWidget {
  final Future<void> Function(bool optIn) onChoice;
  const _NotificationPromptStep({super.key, required this.onChoice});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          const Text('🔔', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 22),
          Text(
            '가끔 고양이들이\n당신 생각이 날 때 알려드려도 될까요?',
            textAlign: TextAlign.center,
            style: serifFont(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.ink,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 36),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () => onChoice(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.ink,
                      side: const BorderSide(color: AppColors.line),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      '나중에요',
                      style: bodyFont(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => onChoice(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      '네, 알려주세요',
                      style: bodyFont(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
