import '../../widgets/subscription_gate.dart';
import '../../theme.dart' show AppColors;
import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../game/runner_game.dart';
import '../l10n/gen/app_localizations.dart';
import '../models/emotion.dart';
import '../models/time_of_day_ambience.dart';
import '../providers/garden_provider.dart';
import '../services/ad_service.dart';
import '../services/sound_manager.dart';
import '../widgets/breathing_interstitial.dart';
import '../widgets/breathing_moment_sheet.dart';
import '../widgets/power_charm_shop_sheet.dart';
import '../widgets/revive_offer_sheet.dart';
import 'choice_screen.dart';

/// 러너 게임 플레이 화면.
/// 조작: 몽이는 항상 자동으로 앞으로 달린다(속도감 있는 러너 게임 리듬).
/// 화면 하단에 눈에 보이는 두 버튼 - 왼쪽 "✊ 주먹" / 오른쪽 "🦘 점프" - 을
/// 눌러 조작한다. 스페이스바/방향키도 동일하게 동작한다.
class RunnerGameScreen extends StatefulWidget {
  final List<Emotion> emotions;
  final String? targetName;

  /// 1번(벤치마킹 제안: 감정 강도-게임 난이도 매칭) - 감정 선택 화면에서
  /// 미리 물어온 강도(1~5, 기본값 3=보통). [RunnerGame]에 그대로 전달되어
  /// 속도/장애물 웨이브 조정에 쓰인다.
  final int emotionIntensity;
  final bool practice;

  const RunnerGameScreen({
    super.key,
    required this.emotions,
    required this.targetName,
    this.emotionIntensity = 3,
    this.practice = false,
  });

  @override
  State<RunnerGameScreen> createState() => _RunnerGameScreenState();
}

class _RunnerGameScreenState extends State<RunnerGameScreen> {
  static const int _maxLives = 3;

  late RunnerGame _game;
  int _eatenCount = 0;
  int _rockHits = 0;
  int _rockPunched = 0;
  int _lives = _maxLives;
  int _combo = 0;
  late int _stage;
  late final int _target;
  final FocusNode _focusNode = FocusNode();
  bool _navigated = false;
  bool _showHint = true;
  int _secondsRemaining = -1;
  Timer? _timerTicker;

  /// 파워빛볼 무적 모드 UI 표시용 - [RunnerGame.isPoweredUp]/
  /// [RunnerGame.powerRemainingSeconds]는 게임 쪽 상태라, 배지를 실시간으로
  /// 갱신하기 위해 남은 시간 타이머([_timerTicker])에 얹어 같이 갱신한다.
  bool _isPoweredUp = false;
  int _powerSecondsRemaining = 0;

  // --- 화면 하단 전용 버튼 조작 (더블탭/구역 판정 모두 폐기) ---------------
  // 1차: 화면을 위/아래로 나눈 "보이지 않는 구역" 방식을 시도했다가, 이후
  // 좌/우 구역으로 바꿔봤지만 두 방식 모두 "이 구역이 정확히 어디까지인지"가
  // 화면에 보이지 않아 사용자가 불안해했다. 지금은 화면 하단에 실제로 눈에
  // 보이는 원형 버튼 두 개를 고정 배치한다 - 왼쪽 "✊ 주먹", 오른쪽 "🦘 점프".
  // 각 버튼은 Listener(behavior: opaque)로 직접 pointerDown을 받아 그 즉시
  // 반응한다(GestureDetector의 탭 인식 지연이 전혀 없다).

  bool _gameInitialized = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_gameInitialized) return;
    _gameInitialized = true;
    _stage = widget.practice ? 1 : context.read<GardenProvider>().stage;
    // 스테이지가 오를수록 감정 목표 개수도 늘어난다: 1단계=20, 2단계=30, 3단계=40,
    // 4단계부터는 40 + (stage-3)*10.
    _target = widget.practice ? 10 : RunnerGame.targetForStage(_stage);
    _game = _createGame();
    _secondsRemaining = _game.secondsRemaining;
    _scheduleHintHide();
    if (!widget.practice)
      AdService.instance.init(); // 부활 광고를 미리 로드해둔다(Android만, 웹은 no-op).
    // 남은 시간 HUD를 매초 최신화한다.
    _timerTicker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted) return;
      final next = _game.secondsRemaining;
      final nextPowered = _game.isPoweredUp;
      final nextPowerSeconds = _game.powerRemainingSeconds;
      if (next != _secondsRemaining ||
          nextPowered != _isPoweredUp ||
          nextPowerSeconds != _powerSecondsRemaining) {
        setState(() {
          _secondsRemaining = next;
          _isPoweredUp = nextPowered;
          _powerSecondsRemaining = nextPowerSeconds;
        });
      }
    });
  }

  /// 목숨을 다 썼을 때 "이어하기"를 제안한다. 처음 [RunnerGame.freeRevivesPerRun]번은
  /// 광고 없이 바로 이어갈 수 있고([requiresAd]=false), 그 이후부터는 광고를
  /// 끝까지 봐야만 이어갈 수 있다([requiresAd]=true). 사용자가 이어하기로
  /// 결정하면 true를, 거절하거나(무료 이어하기 취소) 광고 시청에 실패하면
  /// false를 반환한다.
  Future<bool> _offerRevive(
    int reviveCountThisRun, {
    required bool requiresAd,
  }) {
    if (!mounted) return Future.value(false);
    return ReviveOfferSheet.show(
      context,
      reviveCountThisRun: reviveCountThisRun,
      requiresAd: requiresAd,
    );
  }

  /// "파워 부적" 사용 - 보유한 부적이 있으면 즉시 하나를 소비해 [RunnerGame.
  /// activatePowerMode]를 발동한다(우연히 만나는 파워빛볼과 완전히 동일한
  /// 효과 - 10초 무적). 보유 개수가 0이면 대신 구매 시트를 열어준다.
  bool _usingPowerCharm = false;
  Future<void> _usePowerCharm() async {
    if (widget.practice) return;
    if (_usingPowerCharm) return;
    _usingPowerCharm = true;
    _game.pauseEngine();
    try {
      final allowed = await requestSubscription(
        context,
        message: '모아둔 아이템을 사용하려면 마음냥 구독이 필요해요.',
      );
      if (!mounted || !allowed) return;
      final garden = context.read<GardenProvider>();
      if (garden.powerCharmCount <= 0) {
        await PowerCharmShopSheet.show(context);
        return;
      }
      final consumed = await garden.consumePowerCharm();
      if (consumed && mounted) _game.activatePowerMode();
    } finally {
      _usingPowerCharm = false;
      if (mounted) _game.resumeEngine();
    }
  }

  /// 6번(호흡 미니게임): "숨결 구슬"에 닿아 [RunnerGame.startBreathingMoment]가
  /// 호출되면(게임은 이미 pauseEngine() 상태) 실제 다이얼로그를 띄우고,
  /// 결과(성공적으로 호흡을 따라갔는지)를 다시 게임에 되돌려준다.
  void _handleBreathingMomentStart() {
    if (!mounted) return;
    BreathingMomentSheet.show(context).then((succeeded) {
      if (!mounted) return;
      _game.resolveBreathingMoment(succeeded: succeeded);
    });
  }

  void _scheduleHintHide() {
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted) setState(() => _showHint = false);
    });
  }

  RunnerGame _createGame() {
    final garden = context.read<GardenProvider>();
    final equipped = garden.equippedCostume;
    return RunnerGame(
      emotions: widget.emotions,
      targetName: widget.targetName,
      targetEatenCount: _target,
      stage: _stage,
      isPractice: widget.practice,
      maxLives: _maxLives,
      emotionIntensity: widget.emotionIntensity,
      l10n: AppLocalizations.of(context),
      equippedCostumeAsset: equipped?.imageAsset,
      costumeOffsetXRatio: equipped?.offsetXRatio ?? 0.5,
      costumeOffsetYRatio: equipped?.offsetYRatio ?? 0.16,
      costumeScaleRatio: equipped?.scaleRatio ?? 0.62,
      // 5번: 몬스터 감정 라벨링 - 이번 판 시작 전까지의 감정별 정원 기록을
      // 넘겨서, 몬스터 이름표에 알맞은 진화 애칭을 보여주고 "처음 만난
      // 마음이에요" 라벨링 컷인을 정확히 판단할 수 있게 한다.
      priorMetCounts: Map<String, int>.of(garden.flowerCounts),
      // 10번: 게임 중 스트릭 컷인이 "냠! 사라졌어요" 같은 정형화된 문구
      // 대신, 이 감정 타입으로 실제로 남겼던 최근 다이어리 한 줄을
      // 다시 들려줄 수 있게 전달한다.
      diaryEntries: List<Map<String, dynamic>>.of(garden.diaryEntries),
      onProgressChanged: (count) {
        if (!mounted) return;
        setState(() => _eatenCount = count);
      },
      onRockHit: () {
        if (!mounted) return;
        setState(() => _rockHits++);
      },
      onRockPunched: () {
        if (!mounted) return;
        setState(() => _rockPunched++);
      },
      onLivesChanged: (lives) {
        if (!mounted) return;
        setState(() => _lives = lives);
      },
      onComboChanged: (combo) {
        if (!mounted) return;
        setState(() => _combo = combo);
      },
      onLivesExhausted: _offerRevive,
      onBreathingMomentStart: _handleBreathingMomentStart,
      onStageComplete: (count, {bool earlyStop = false}) {
        if (_navigated) return;
        _navigated = true;
        final maxCombo = _game.maxCombo;
        final eatenByType = Map<EmotionType, int>.of(_game.eatenByType);
        Future.delayed(const Duration(milliseconds: 350), () async {
          if (!mounted) return;
          if (widget.practice) {
            await showDialog<void>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: const Text('몽이와 천천히 연습했어요'),
                content: const Text('주먹과 점프가 조금 익숙해졌나요? 원하는 때에 다시 연습할 수 있어요.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('돌아가기'),
                  ),
                ],
              ),
            );
            if (!mounted) return;
            await SoundManager.instance.stopEverything();
            if (mounted) Navigator.of(context).pop();
            return;
          }
          // 빠른 속도로 달리던 흐름을 곧바로 결과 화면으로 넘기지 않고,
          // 가끔(BreathingScheduler가 정한 타이밍에만) 잠깐 숨을 고르는
          // 인터스티셜을 먼저 보여준다("건너뛰기"로 언제든 바로 넘어갈 수
          // 있어 강요처럼 느껴지지 않는다).
          if (BreathingScheduler.instance.shouldShow()) {
            await BreathingInterstitial.show(context);
          }
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => ChoiceScreen(
                emotions: widget.emotions,
                targetName: widget.targetName,
                eatenByType: eatenByType,
                maxCombo: maxCombo,
                earlyStop: earlyStop,
                target: _target,
                playedStage: _stage,
              ),
            ),
          );
        });
      },
    );
  }

  @override
  void dispose() {
    _timerTicker?.cancel();
    _focusNode.dispose();
    SoundManager.instance.stopBgm();
    super.dispose();
  }

  static final _relevantKeys = {
    LogicalKeyboardKey.space,
    LogicalKeyboardKey.arrowUp,
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.arrowDown,
  };

  /// 웹/데스크톱 테스트용 키보드 조작. 몽이는 항상 자동으로 달리므로, 여기서는
  /// 오직 점프/주먹 액션만 즉시 트리거한다(더 이상 홀드 상태를 만들지 않음).
  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (!_relevantKeys.contains(event.logicalKey)) {
      return KeyEventResult.ignored;
    }
    final isJumpKey =
        event.logicalKey == LogicalKeyboardKey.space ||
        event.logicalKey == LogicalKeyboardKey.arrowUp;
    final isPunchKey =
        event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.arrowDown;
    if (event is KeyDownEvent && (isJumpKey || isPunchKey)) {
      if (isJumpKey) {
        _handleJumpInput(source: ('key', event.logicalKey.keyId));
      } else {
        _handlePunchInput();
      }
      return KeyEventResult.handled;
    }
    if (event is KeyUpEvent && isJumpKey) {
      // 스페이스바/방향키 위를 계속 누르고 있으면 점프가 길어지고, 떼는
      // 순간 곧바로 짧아진다 - 터치의 pointer up과 동일한 효과.
      _game.releaseJumpInput(('key', event.logicalKey.keyId));
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// 해제된 손가락만 제거하고, 다른 점프 입력이 남으면 홀드를 유지한다.
  void _handleJumpPointerRelease(PointerEvent event) {
    _game.releaseJumpInput(('pointer', event.pointer));
  }

  /// 화면 오른쪽 터치(또는 스페이스바·방향키 위) -> 점프. 큰 돌멩이는 반드시
  /// 이걸로 피해야 한다. 터치를 계속 누르고 있으면([_handleJumpPointerRelease]
  /// 전까지) 점프가 더 길게/높게 이어진다("차지 점프").
  void _handleJumpInput({required Object source}) {
    if (!_game.acceptsGameplayInput) return;
    if (_showHint) {
      setState(() => _showHint = false);
    }
    _game.pressJumpInput(source);
  }

  /// 화면 한 번 톡(싱글탭) / 엔터·방향키 아래 -> 주먹으로 작은 돌멩이 부수기 준비.
  /// 몽이가 알아서 부수는 게 아니라, 돌멩이가 오는 타이밍에 맞춰 직접 눌러야 한다.
  void _handlePunchInput() {
    if (!_game.acceptsGameplayInput) return;
    if (_showHint) {
      setState(() => _showHint = false);
    }
    _game.punchAction();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // 안드로이드 시스템 뒤로가기(백버튼/스와이프 제스처)로 화면을 나가는
      // 경로가 화면 안의 X 버튼(_confirmExit)을 완전히 건너뛰는 문제가
      // 있었다 - 그 경로에서는 dispose()의 stopBgm()만 호출되고 자연
      // 앰비언트(새소리/물소리)·발소리는 전혀 멈추지 않아 "게임을 종료해도
      // 효과음이 계속 들리는" 버그로 이어졌다. canPop: false로 시스템
      // pop을 우선 막고, 항상 _confirmExit()(소리 완전 정지 포함)을 거치게
      // 통일한다.
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _confirmExit();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFEAF6FF),
        body: Focus(
          focusNode: _focusNode,
          autofocus: true,
          onKeyEvent: _handleKey,
          onFocusChange: (focused) {
            if (!focused) _game.clearGameplayInput();
          },
          child: Stack(
            children: [
              Positioned.fill(
                child: GameWidget(
                  game: _game,
                  // GameWidget은 errorBuilder가 없으면 onLoad() 중 발생한
                  // 예외를 build 트리에 그대로 다시 던져, 화면이 아무 안내도
                  // 없는 회색으로만 보이는 문제가 있었다. 앞으로 비슷한
                  // 문제가 생겨도 사용자가 원인을 알아채고 다시 시도할 수
                  // 있도록 안내 UI를 보여준다.
                  errorBuilder: (context, error) => Container(
                    color: const Color(0xFFEAF6FF),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('😿', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        Text(
                          AppLocalizations.of(context).gameLoadErrorTitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          child: Text(
                            AppLocalizations.of(context).gameLoadErrorButton,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              _buildTapHint(),
              _buildHud(),
              _buildTimeOfDayBadge(),
              if (!widget.practice) _buildTimeBadge(),
              _buildComboBadge(),
              _buildPowerModeBadge(),
              _buildCloseButton(),
              if (!widget.practice) _buildPowerCharmButton(),
              if (widget.practice)
                const Positioned(
                  top: 110,
                  left: 16,
                  right: 16,
                  child: IgnorePointer(
                    child: Card(
                      color: Color(0xFFE8F3E8),
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: Text(
                          '편안한 연습 · 부딪혀도 괜찮아요\n시간 제한 없이 10개의 마음을 만나봐요.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
              _buildPunchButton(),
              _buildJumpButton(),
            ],
          ),
        ),
      ),
    );
  }

  /// 화면 하단 왼쪽에 항상 떠 있는 "✊ 주먹" 버튼. [Listener]로 직접
  /// pointerDown을 받기 때문에 GestureDetector 특유의 탭 인식 지연이 없다 -
  /// 손가락이 닿는 그 프레임에 즉시 [_handlePunchInput]이 실행된다.
  Widget _buildPunchButton() {
    return Positioned(
      left: 22,
      bottom: 28,
      child: SafeArea(
        top: false,
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (_) {
            if (_showHint) setState(() => _showHint = false);
            _handlePunchInput();
          },
          child: _buildActionButton(
            emoji: '✊',
            label: AppLocalizations.of(context).gamePunchLabel,
            color: const Color(0xFFFF8FAB),
          ),
        ),
      ),
    );
  }

  /// 화면 하단 오른쪽에 항상 떠 있는 "🦘 점프" 버튼. 이 버튼을 누르고 있는
  /// 동안(pointerUp/cancel까지)은 [_handleJumpInput]/[_handleJumpPointerRelease]로
  /// 차지 점프가 이어진다. 손가락이 버튼 밖으로 미끄러져 나가도 Flutter의
  /// 포인터 라우팅 덕분에 이 [Listener]가 계속 up/cancel을 전달받는다.
  Widget _buildJumpButton() {
    return Positioned(
      right: 22,
      bottom: 28,
      child: SafeArea(
        top: false,
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (event) {
            if (_showHint) setState(() => _showHint = false);
            _handleJumpInput(source: ('pointer', event.pointer));
          },
          onPointerUp: _handleJumpPointerRelease,
          onPointerCancel: _handleJumpPointerRelease,
          child: _buildActionButton(
            emoji: '🦘',
            label: AppLocalizations.of(context).gameJumpLabel,
            color: const Color(0xFF8FD3FF),
          ),
        ),
      ),
    );
  }

  /// 주먹/점프 버튼 공통 원형 스타일. 눈에 확실히 보이도록 흰 테두리와
  /// 그림자를 주고, 이모지 + 한글 라벨을 함께 표시해 어느 버튼이 어떤
  /// 동작인지 한눈에 알 수 있게 한다.
  Widget _buildActionButton({
    required String emoji,
    required String label,
    required Color color,
  }) {
    return Container(
      width: 86 + (MediaQuery.textScalerOf(context).scale(26) - 26),
      height: 86 + (MediaQuery.textScalerOf(context).scale(26) - 26) * 2,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.9),
          width: 3,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTapHint() {
    final l10n = AppLocalizations.of(context);
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: _showHint ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 400),
        child: Align(
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 110),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.catSageBg.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🏃🐾', style: TextStyle(fontSize: 26)),
                  const SizedBox(height: 4),
                  Text(
                    l10n.gameHintAutoRun,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.practice
                        ? '시간 제한 없이 천천히 연습해요'
                        : l10n.gameHintTimeLimit(_game.timeLimitSeconds),
                    style: const TextStyle(
                      color: AppColors.inkSoft,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.gameHintControlsStage2Plus,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.gameHintDodgeStage2Plus,
                    style: const TextStyle(
                      color: AppColors.inkSoft,
                      fontSize: 11.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHud() {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.bg1.withValues(alpha: .95),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.sageLine),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${_game.biome.emoji} ${AppLocalizations.of(context).gameHudStage(_stage)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.inkSoft,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$_eatenCount / $_target',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    value: (_eatenCount / _target).clamp(0.0, 1.0),
                    backgroundColor: AppColors.blobMint,
                    color: AppColors.titlePastelGreen,
                  ),
                ),
              ),
              if (_rockPunched > 0) ...[
                const SizedBox(width: 6),
                Text(
                  '💪 $_rockPunched',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
              const SizedBox(width: 8),
              Text(
                List.generate(
                  _maxLives,
                  (i) => i < _lives ? '❤️' : '🤍',
                ).join(),
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 실제 기기 시각이 새벽/밤일 때만 살짝 나타나는 작은 배지("밤 정원이에요
  /// 🌙" 등). 낮 시간에는 [TimeOfDayAmbience.label]이 빈 문자열이라 아무것도
  /// 그리지 않는다 - 평소 플레이 경험을 방해하지 않기 위함.
  Widget _buildTimeOfDayBadge() {
    final ambience = _game.timeOfDay;
    if (ambience.label.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final label = switch (ambience) {
      TimeOfDayAmbience.dawn => l10n.gameTimeOfDayDawn,
      TimeOfDayAmbience.night => l10n.gameTimeOfDayNight,
      TimeOfDayAmbience.day => '',
    };
    return IgnorePointer(
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 92),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.38),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '${ambience.emoji} ${l10n.gameTimeOfDayBadge(label)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 파워빛볼을 먹어 무적 모드일 때 화면 중앙 위쪽에 크게 뜨는 배지 -
  /// "지금은 뭐든 부수고 지나가도 된다"는 걸 한눈에 알 수 있게 한다.
  Widget _buildPowerModeBadge() {
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: _isPoweredUp ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 130),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC93C),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  AppLocalizations.of(
                    context,
                  ).gamePowerModeBadge(_powerSecondsRemaining),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 이번 판에 남은 시간(초)을 보여주는 배지. 메인 HUD 바로 아래, 화면
  /// 가운데에 떠 있으며, 남은 시간이 10초 이하로 줄어들면 붉은색으로 바뀌어
  /// 긴장감을 준다. (엔드리스 모드 화면에서는 이 위젯을 쓰지 않으므로 항상
  /// secondsRemaining >= 0.)
  Widget _buildTimeBadge() {
    final urgent = _secondsRemaining <= 10;
    return IgnorePointer(
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 54),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: urgent
                    ? const Color(0xFFFF5A5A).withValues(alpha: 0.92)
                    : Colors.white.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                AppLocalizations.of(context).gameTimeBadge(_secondsRemaining),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: urgent ? 15 : 12.5,
                  color: urgent ? Colors.white : const Color(0xFF9A8F86),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 미스 없이 연속 성공 중일 때(2콤보 이상)만 살짝 튀어나오는 콤보 배지.
  Widget _buildComboBadge() {
    return IgnorePointer(
      child: SafeArea(
        child: Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 10, right: 12),
            child: AnimatedScale(
              scale: _combo >= 2 ? 1.0 : 0.6,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              child: AnimatedOpacity(
                opacity: _combo >= 2 ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF8FAB),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    AppLocalizations.of(context).gameComboBadge(_combo),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCloseButton() {
    return SafeArea(
      child: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.only(left: 10, top: 62),
          child: Material(
            color: Colors.white.withValues(alpha: 0.88),
            shape: const CircleBorder(),
            child: IconButton(
              icon: const Icon(Icons.close, color: Color(0xFF6B6058)),
              onPressed: _confirmExit,
            ),
          ),
        ),
      ),
    );
  }

  /// 화면 오른쪽 위, 닫기 버튼 아래에 떠 있는 "⚡ 파워 부적" 버튼 - 보유한
  /// 부적 개수를 함께 보여주고, 누르면 즉시 사용(또는 없으면 구매 시트를
  /// 열어준다). 이미 무적 모드인 동안에는 눌러도 의미가 없으므로(중첩
  /// 없이 시간만 리필됨) 살짝 흐리게 표시해 지금 급하지 않다는 걸
  /// 암시한다(비활성화하지는 않음 - 남은 시간을 더 늘리고 싶을 수도 있으니).
  Widget _buildPowerCharmButton() {
    final garden = context.watch<GardenProvider>();
    return SafeArea(
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.only(right: 10, top: 62),
          child: Opacity(
            opacity: _isPoweredUp ? 0.55 : 1.0,
            child: Material(
              color: const Color(0xFFFFC93C),
              borderRadius: BorderRadius.circular(18),
              elevation: 3,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: _usePowerCharm,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('⚡', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 4),
                      Text(
                        '${garden.powerCharmCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
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

  /// "게임을 끝내고 싶을 때" 확실하게 완전히 끝낼 수 있는 종료 확인
  /// 다이얼로그. 실수로 닫는 걸 막기 위해 한 번 더 확인을 받고, "종료"를
  /// 선택하면 배경음악/자연 앰비언트/발소리 등 재생 중인 소리를 하나도
  /// 남기지 않고 전부 멈춘 뒤 게임 화면 자체를 완전히 벗어난다("소리도
  /// 안나게 만들어줘" 요구사항).
  Future<void> _confirmExit() async {
    _game.pauseEngine();
    final l10n = AppLocalizations.of(context);
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.gameExitConfirmTitle),
        content: Text(l10n.gameExitConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              l10n.gameExitConfirmButton,
              style: const TextStyle(
                color: Color(0xFFFF5A5A),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (shouldExit != true) {
      _game.resumeEngine();
      return;
    }
    _navigated = true; // onStageComplete 콜백이 뒤늦게 불려도 무시하도록.
    await SoundManager.instance.stopEverything();
    if (!mounted) return;
    Navigator.of(context).pop();
  }
}
