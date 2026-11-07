import 'package:flutter/material.dart';
import '../l10n/gen/app_localizations.dart';
import '../models/breathing_technique.dart';
import '../services/sound_manager.dart';

/// 심호흡 인터스티셜을 "언제 보여줄지" 결정하는 스케줄러.
///
/// 원래는 스테이지(또는 엔드리스 한 판)가 끝날 때마다 매번 무조건 떴는데,
/// 약 24초짜리 호흡 연출이 매판 반복되면 오히려 "언제 나올지 뻔하고
/// 귀찮다"는 피로감을 줄 수 있고, 정작 힐링 앱의 취지인 "가끔, 예상 못한
/// 순간에 찾아오는 쉼표"라는 느낌은 사라진다. 그렇다고 아예 안 보여주면
/// 사용자가 이 기능의 존재 자체를 눈치채지 못할 수 있다.
///
/// 그래서 아래 타이밍으로 설계했다:
/// - **첫 판을 마친 직후에는 반드시 한 번 보여준다** - 신규/복귀 사용자가
///   "아, 이런 쉬어가는 순간도 있구나"를 자연스럽게 알게 되는 첫인상 역할.
/// - 그 다음부터는 [everyNRuns]판(기본 3판)에 한 번씩만 다시 등장한다 -
///   [AdService.interstitialEveryNStages]와 같은 "가끔씩, 하지만 흐름을
///   해치지 않게"라는 검증된 리듬을 그대로 재사용한 것이다. 매판 뜨는 것도
///   아니고, 언제 뜰지 사용자가 정확히 셀 수 있을 만큼 예측 가능하지도
///   않을 정도의 적당한 빈도다.
/// - 일반 스테이지 모드와 엔드리스 모드를 구분하지 않고 하나의 카운터를
///   공유한다 - 사용자 입장에서는 "한 판(러너 게임)이 강렬하게 끝난 직후"라는
///   경험 자체가 같기 때문에, 모드와 무관하게 "몇 판마다 한 번" 쉬어가는
///   것이 자연스럽다.
/// - 앱을 완전히 재시작하면(프로세스가 새로 뜨면) 카운터도 초기화된다 -
///   세션이 바뀌면 다시 "이번 접속에서의 첫 판"을 보여주는 것도 나쁘지
///   않은 타이밍이라 별도로 영구 저장하지 않았다(과도하게 정교한 개인화보다
///   단순하고 예측 가능한 규칙을 택함).
class BreathingScheduler {
  BreathingScheduler._();
  static final BreathingScheduler instance = BreathingScheduler._();

  static const int everyNRuns = 3;
  int _completedRuns = 0;

  /// 러너 게임 한 판(스테이지 성공/조기종료/엔드리스 게임오버 전부 포함)이
  /// 끝날 때마다 호출한다. 이번에 심호흡 인터스티셜을 보여줘야 하면 true.
  bool shouldShow() {
    _completedRuns++;
    // 1판째(첫 판) 또는 그 뒤로 everyNRuns판마다 한 번씩(4, 7, 10판째...).
    return _completedRuns % everyNRuns == 1;
  }
}

/// 스테이지가 끝난 직후, 결과/선택 화면으로 넘어가기 전에 잠깐 숨을 고르게
/// 하는 심호흡 인터스티셜.
///
/// "속도감 있는 러너 게임"으로 재미를 키운 만큼, 정작 이 앱의 정체성인
/// "힐링"이 흐려질 수 있다는 피드백에서 나온 장치다. 강렬한 리듬으로 달리고
/// 부딫히던 흐름이 끝나는 그 순간, 화면 전체가 잠깐 느려지며 "그래도 돼,
/// 잠깐 쉬어가도 돼" 하는 여백을 준다.
///
/// 언제 이 위젯을 띄울지는 [BreathingScheduler]가 결정한다(호출부에서
/// `BreathingScheduler.instance.shouldShow()`를 먼저 확인한 뒤에만 [show]를
/// 호출한다) - 더 이상 매판 무조건 뜨지 않는다.
///
/// 5번(벤치마킹 제안): 원래는 "4초 들숨 + 4초 날숨, 3회 반복"이라는 딱 한
/// 종류의 리듬만 있었는데, [BreathingTechniqueDef]로 여러 호흡 기법(불안
/// 완화용 4-7-8, 집중용 박스 호흡, 잠들기 전 호흡 등)을 재생할 수 있도록
/// 확장했다. [technique]을 지정하지 않으면 기존과 똑같은 기본 호흡
/// ([BreathingTechniqueId.calmBreath])이 재생되어, 게임 종료 후 자동으로
/// 뜨는 기존 호출부는 동작이 전혀 바뀌지 않는다. 그래도 강요처럼 느껴지지
/// 않도록 언제든 "건너뛰기"로 바로 닫을 수 있게 했고, 지금 몇 번째 호흡인지
/// 작은 점으로 보여준다.
class BreathingInterstitial extends StatefulWidget {
  final BreathingTechniqueDef technique;

  const BreathingInterstitial({super.key, BreathingTechniqueDef? technique})
    : technique = technique ?? const _DefaultTechnique();

  /// 인터스티셜을 띄우고, 호흡 사이클이 자연스럽게 끝나거나 사용자가
  /// 건너뛸 때까지 기다린다. 별도 라우트를 쌓는 대신 반투명 다이얼로그로
  /// 띄워서, 완료된 뒤 호출자가 그대로(pushReplacement 등) 다음 화면으로
  /// 자연스럽게 이어갈 수 있게 한다.
  ///
  /// [technique]을 지정하면 "몽이의 숨결 도감"에서 고른 그 기법으로,
  /// 지정하지 않으면 게임 종료 후 자동으로 뜨는 기존 기본 호흡으로 재생된다.
  /// 반환값은 사용자가 실제로 사이클을 다 마쳤는지(건너뛰지 않았는지) 여부다.
  static Future<bool> show(
    BuildContext context, {
    BreathingTechniqueDef? technique,
  }) {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'breathing',
      barrierColor: Colors.black.withValues(alpha: 0.0),
      transitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (context, animation, secondaryAnimation) {
        return BreathingInterstitial(technique: technique);
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    ).then((value) => value ?? false);
  }

  @override
  State<BreathingInterstitial> createState() => _BreathingInterstitialState();
}

/// [BreathingTechniqueDef]를 import하지 않고도 기존 호출부가 그대로 동작하게
/// 하기 위한 기본값(기존 하드코딩된 4-0-4-0, 3회와 완전히 동일하다).
class _DefaultTechnique extends BreathingTechniqueDef {
  const _DefaultTechnique()
    : super(
        id: BreathingTechniqueId.calmBreath,
        emoji: '🌬️',
        name: '차분한 숨',
        description: '',
        inhale: const Duration(milliseconds: 4000),
        holdAfterInhale: Duration.zero,
        exhale: const Duration(milliseconds: 4000),
        holdAfterExhale: Duration.zero,
        cycles: 3,
        rewardLightEssence: 5,
      );
}

class _BreathingInterstitialState extends State<BreathingInterstitial>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _closed = false;
  bool _completedNaturally = false;
  int _cycleIndex = 0;

  BreathingTechniqueDef get _technique => widget.technique;

  @override
  void initState() {
    super.initState();
    // 숨쉬기 순간에는 배경음악을 잠깐 끄고, 새소리/물소리 앰비언트만 남겨서
    // 정말로 숨을 고를 수 있는 조용한 여백을 만든다(앰비언트는 별도
    // 플레이어라 여기서 손대지 않아도 계속 이어진다).
    SoundManager.instance.pauseBgm();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _technique.cycleMs),
    );
    _controller.addStatusListener((status) {
      if (status != AnimationStatus.completed) return;
      if (_cycleIndex + 1 >= _technique.cycles) {
        _completedNaturally = true;
        _close();
        return;
      }
      setState(() => _cycleIndex++);
      _controller.forward(from: 0);
    });
    _controller.forward();
  }

  void _close() {
    if (_closed) return;
    _closed = true;
    if (mounted) Navigator.of(context).pop(_completedNaturally);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // 뒤로가기 제스처로 갑자기 화면이 사라지면 오히려 안내가 뚝 끊긴 듯 어색하니,
    // 시스템 back은 막아두고 오직 "건너뛰기" 버튼으로만 닫히게 한다.
    return PopScope(
      canPop: false,
      child: SizedBox.expand(
        child: Material(
          color: const Color(0xFF6E7B8B),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) => _buildBreathCircle(l10n),
                    ),
                    const SizedBox(height: 28),
                    _buildCycleDots(),
                    const SizedBox(height: 18),
                    Text(
                      l10n.breathingPromptText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 22),
                    TextButton(
                      onPressed: _close,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white70,
                      ),
                      child: Text(
                        l10n.onboardingSkip,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 지금 몇 번째 호흡인지 작은 점으로 보여준다 - 채워진 점은 이미 지나온
  /// 호흡, 지금 밝게 빛나는 점은 진행 중인 호흡, 나머지는 앞으로 남은 호흡.
  Widget _buildCycleDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_technique.cycles, (i) {
        final isPast = i < _cycleIndex;
        final isCurrent = i == _cycleIndex;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isCurrent ? 10 : 8,
          height: isCurrent ? 10 : 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (isPast || isCurrent)
                ? Colors.white
                : Colors.white.withValues(alpha: 0.3),
          ),
        );
      }),
    );
  }

  /// 원이 커지는 동안 "들이쉬고...", 유지 구간에는 "멈추고...", 작아지는
  /// 동안 "내쉬고..."를 보여주며, 색도 은은하게 함께 변한다 - 눈으로
  /// 리듬을 따라가기만 해도 자연스럽게 호흡 속도가 느려지도록 유도하는
  /// 전형적인 호흡 안내 UI 패턴이다.
  Widget _buildBreathCircle(AppLocalizations l10n) {
    final t = _technique;
    final totalMs = t.cycleMs;
    final elapsedMs = _controller.value * totalMs;
    final inhaleMs = t.inhale.inMilliseconds;
    final holdInMs = t.holdAfterInhale.inMilliseconds;
    final exhaleMs = t.exhale.inMilliseconds;

    late double scale;
    late String label;
    if (elapsedMs <= inhaleMs) {
      final p = inhaleMs == 0 ? 1.0 : (elapsedMs / inhaleMs).clamp(0.0, 1.0);
      scale = 0.55 + 0.45 * Curves.easeInOut.transform(p);
      label = l10n.breathingInhaleLabel;
    } else if (elapsedMs <= inhaleMs + holdInMs) {
      scale = 1.0;
      label = l10n.breathingHoldLabel;
    } else if (elapsedMs <= inhaleMs + holdInMs + exhaleMs) {
      final p = exhaleMs == 0
          ? 1.0
          : ((elapsedMs - inhaleMs - holdInMs) / exhaleMs).clamp(0.0, 1.0);
      scale = 1.0 - 0.45 * Curves.easeInOut.transform(p);
      label = l10n.breathingExhaleLabel;
    } else {
      scale = 0.55;
      label = l10n.breathingHoldLabel;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.scale(
          scale: scale,
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [Color(0xFFFFE8EE), Color(0xFF8FD3FF)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.45),
                  blurRadius: 30,
                  spreadRadius: 4,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 26),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
