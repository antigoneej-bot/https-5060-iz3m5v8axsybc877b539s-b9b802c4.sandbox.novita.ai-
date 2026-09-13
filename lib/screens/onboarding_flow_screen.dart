import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/shadow_cat.dart';
import '../providers/app_state_provider.dart';
import '../providers/cat_care_provider.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../theme.dart';
import '../widgets/animated_cat_art.dart';
import '../widgets/mood_picker.dart';
import '../widgets/stars_background.dart';

/// 고양이를 처음 만난 순간 이어지는 최초 1회 온보딩 플로우.
/// 편지쓰기(비회원) → 전송 연출 → 이 기기에서 계속하기 → 알림 동의 → 홈으로.
///
/// 회원가입을 앞세우지 않고, 사용자가 이미 감정적으로 몰입한 순간(편지를 보낸 직후)에만
/// 자연스럽게 기록 유지를 요청합니다. B-1 범위에서는 로컬 전용 플로우만 제공하며
/// 가짜 소셜 로그인 UI는 사용하지 않습니다.
class OnboardingFlowScreen extends StatefulWidget {
  final ShadowCat cat;

  /// 앱 부트스트랩(인트로 직후) 단계에서 사용할 때 전달합니다. 이 화면이
  /// 별도의 라우트로 push되지 않고 상위 AnimatedSwitcher 안에서 직접
  /// 보여지는 경우, 완료 시 Navigator를 pop하는 대신 이 콜백으로 알립니다.
  /// null이면(=고양이선택 후 편지쓰기 버튼에서 push된 기존 경로) 기존처럼
  /// Navigator.popUntil로 화면을 닫습니다.
  final VoidCallback? onFinished;

  const OnboardingFlowScreen({super.key, required this.cat, this.onFinished});

  @override
  State<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

enum _OnboardingStep { letter, sending, signup, notification }

class _OnboardingFlowScreenState extends State<OnboardingFlowScreen> {
  _OnboardingStep _step = _OnboardingStep.letter;
  final TextEditingController _letterController = TextEditingController();
  bool _busy = false;
  String? _moodEmoji;

  @override
  void dispose() {
    _letterController.dispose();
    super.dispose();
  }

  Future<void> _onSendLetter() async {
    final hasText = _letterController.text.trim().isNotEmpty;
    final hasMood = _moodEmoji != null;
    if ((!hasText && !hasMood) || _busy) return;
    setState(() {
      _busy = true;
      _step = _OnboardingStep.sending;
    });

    final minShow = Future<void>.delayed(const Duration(milliseconds: 1400));
    var saved = false;
    try {
      await context.read<AppStateProvider>().saveOnboardingLetter(
        _letterController.text.trim(),
        widget.cat,
        moodEmoji: _moodEmoji,
      );
      saved = true;
    } catch (_) {
      saved = false;
    }

    await minShow;
    if (!mounted) return;

    if (!saved) {
      setState(() {
        _busy = false;
        _step = _OnboardingStep.letter;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('편지를 저장하지 못했어요. 다시 보내 주세요')),
      );
      return;
    }

    // journaling은 다음 단계를 막지 않음
    final care = context.read<CatCareProvider>();
    unawaited(() async {
      try {
        await care.journaling();
      } catch (_) {}
    }());

    setState(() {
      _busy = false;
      _step = _OnboardingStep.signup;
    });
  }

  /// B-1: 로컬 전용 계속. provider는 표시/분석용 문자열이며 OAuth는 수행하지 않습니다.
  Future<void> _onContinueLocal() async {
    if (_busy) return;
    setState(() => _busy = true);
    await Future.delayed(const Duration(milliseconds: 350));
    await StorageService.setLoginProvider('local');
    if (!mounted) return;
    setState(() {
      _busy = false;
      _step = _OnboardingStep.notification;
    });
  }

  Future<void> _onNotificationChoice(bool optIn) async {
    await StorageService.setOnboardingCompleted();
    if (!mounted) return;
    final app = context.read<AppStateProvider>();
    final care = context.read<CatCareProvider>();
    app.finishOnboarding();

    // 홈으로 먼저 이동 — 알림 권한/스케줄·로드는 뒤에서
    if (widget.onFinished != null) {
      widget.onFinished!();
    } else {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }

    unawaited(() async {
      try {
        await NotificationService().applyOnboardingOptIn(optIn);
        await care.load();
        await app.refreshStreak();
      } catch (_) {}
    }());
  }

  Widget _buildStep() {
    switch (_step) {
      case _OnboardingStep.letter:
        return _OnboardingLetterStep(
          key: const ValueKey('letter'),
          cat: widget.cat,
          controller: _letterController,
          busy: _busy,
          moodEmoji: _moodEmoji,
          onMoodChanged: (v) => setState(() => _moodEmoji = v),
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
          onContinueLocal: _onContinueLocal,
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
  final String? moodEmoji;
  final ValueChanged<String?> onMoodChanged;
  final VoidCallback onSend;
  const _OnboardingLetterStep({
    super.key,
    required this.cat,
    required this.controller,
    required this.busy,
    required this.moodEmoji,
    required this.onMoodChanged,
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
          const SizedBox(height: 14),
          MoodPicker(selectedEmoji: moodEmoji, onChanged: onMoodChanged),
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

/// 2단계 후반부: 로컬 기록 유지 안내 (B-1 — 가짜 소셜 로그인 제거)
class _SignupPromptStep extends StatelessWidget {
  final bool busy;
  final Future<void> Function() onContinueLocal;
  const _SignupPromptStep({
    super.key,
    required this.busy,
    required this.onContinueLocal,
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
            '당신과 이 아이의 이야기는 이 기기에 안전하게 남아요.\n쓴 편지와 마음의 온도를 기억해 두고,\n다음에 와도 이어서 지켜볼게요.',
            textAlign: TextAlign.center,
            style: bodyFont(
              fontSize: 13.5,
              color: AppColors.inkSoft,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: busy ? null : onContinueLocal,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.goldSoft,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      '이 기기에서 계속하기',
                      style: bodyFont(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '계정 로그인 없이 이 기기에만 저장돼요.\n앱을 삭제하면 기록도 함께 사라질 수 있어요.',
            textAlign: TextAlign.center,
            style: bodyFont(
              fontSize: 12,
              color: AppColors.inkSoft,
              height: 1.5,
            ),
          ),
        ],
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
