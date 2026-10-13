import '../../widgets/subscription_gate.dart';
import '../../theme.dart' show AppColors;
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
import '../widgets/power_charm_shop_sheet.dart';
import '../widgets/revive_offer_sheet.dart';
import 'endless_result_screen.dart';

/// "무한의 계단"식 엔드리스 도전 모드 화면.
/// 목표 개수 없이 무한히 진행되며, 시간이 지날수록 점점 빨라진다.
/// 목숨을 다 쓰면 그 판이 끝나고 "오늘 내 최고 기록"과 비교하는 결과 화면으로 넘어간다.
/// 조작 방식은 스테이지 모드(runner_game_screen.dart)와 완전히 동일: 몽이는
/// 항상 자동으로 달리고, 화면 하단에 눈에 보이는 두 버튼 - 왼쪽 "✊ 주먹" /
/// 오른쪽 "🦘 점프" - 을 눌러 조작한다. 스페이스바/방향키도 동일하게 동작한다.
class EndlessModeScreen extends StatefulWidget {
  final List<Emotion> emotions;
  final String? targetName;

  /// 1번(벤치마킹 제안: 감정 강도-게임 난이도 매칭) - 감정 선택 화면에서
  /// 미리 물어온 강도(1~5, 기본값 3=보통). [RunnerGame]에 그대로 전달된다.
  final int emotionIntensity;

  const EndlessModeScreen({
    super.key,
    required this.emotions,
    required this.targetName,
    this.emotionIntensity = 3,
  });

  @override
  State<EndlessModeScreen> createState() => _EndlessModeScreenState();
}

class _EndlessModeScreenState extends State<EndlessModeScreen> {
  static const int _maxLives = 3;

  late RunnerGame _game;
  int _eatenCount = 0;
  int _lives = _maxLives;
  int _combo = 0;
  int _elapsedSeconds = 0;
  final FocusNode _focusNode = FocusNode();
  bool _navigated = false;
  bool _showHint = true;
  bool _isPoweredUp = false;
  int _powerSecondsRemaining = 0;

  // --- 화면 하단 전용 버튼 조작 ---------------------------------------------
  // 예전에는 "한 번 톡 = 주먹 / 두 번 톡(더블탭) = 점프"로 화면 전체를 눌러
  // 조작했는데, 스테이지 모드(runner_game_screen.dart)에 있는 눈에 보이는
  // 전용 버튼(✊ 주먹 / 🦘 점프)이 무한도전 모드에는 없어 "여기서는 어떻게
  // 점프하는지 헷갈린다"는 문제가 있었다. 스테이지 모드와 동일한 방식으로
  // 통일한다 - 화면 하단에 항상 보이는 버튼 두 개, Listener로 즉시 반응.
  /// 점프를 발동시킨 손가락(포인터)의 id. 그 손가락이 버튼에서 떨어질 때만
  /// [RunnerGame.setJumpHeld]를 꺼주기 위해 구분한다.

  bool _gameInitialized = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_gameInitialized) return;
    _gameInitialized = true;
    _game = _createGame();
    _scheduleHintHide();
    _startTicker();
    AdService.instance.init(); // 부활 광고를 미리 로드해둔다(Android만, 웹은 no-op).
  }

  /// 목숨을 다 썼을 때 "이어하기"를 제안한다. 엔드리스 모드는 도전 성격이
  /// 강하므로, 부활을 통해 "오늘의 최고 기록"에 한 번 더 다가갈 기회를 준다.
  /// 처음 [RunnerGame.freeRevivesPerRun]번은 광고 없이, 그 이후부터는 광고를
  /// 봐야만 이어갈 수 있다.
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

  void _scheduleHintHide() {
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted) setState(() => _showHint = false);
    });
  }

  /// "파워 부적" 사용 - 스테이지 모드(runner_game_screen.dart)와 동일한
  /// 로직. 보유한 부적이 있으면 즉시 소비해 무적 모드를 발동하고, 없으면
  /// 구매 시트를 열어준다.
  bool _usingPowerCharm = false;
  Future<void> _usePowerCharm() async {
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

  /// HUD에 흐른 시간을 실시간으로 보여주기 위한 1초 간격 갱신 루프.
  void _startTicker() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted || _navigated) return false;
      setState(() {
        _elapsedSeconds = _game.elapsedSeconds;
        _isPoweredUp = _game.isPoweredUp;
        _powerSecondsRemaining = _game.powerRemainingSeconds;
      });
      return true;
    });
  }

  RunnerGame _createGame() {
    final garden = context.read<GardenProvider>();
    final equipped = garden.equippedCostume;
    return RunnerGame(
      emotions: widget.emotions,
      targetName: widget.targetName,
      isEndless: true,
      maxLives: _maxLives,
      emotionIntensity: widget.emotionIntensity,
      equippedCostumeAsset: equipped?.imageAsset,
      costumeOffsetXRatio: equipped?.offsetXRatio ?? 0.5,
      costumeOffsetYRatio: equipped?.offsetYRatio ?? 0.16,
      costumeScaleRatio: equipped?.scaleRatio ?? 0.62,
      priorMetCounts: Map<String, int>.of(garden.flowerCounts),
      // 10번: 엔드리스 모드에서도 동일하게, 실제 다이어리 기록과 연결된
      // 컷인 문구를 보여줄 수 있게 전달한다.
      diaryEntries: List<Map<String, dynamic>>.of(garden.diaryEntries),
      onProgressChanged: (count) {
        if (!mounted) return;
        setState(() => _eatenCount = count);
      },
      onRockHit: () {},
      onLivesChanged: (lives) {
        if (!mounted) return;
        setState(() => _lives = lives);
      },
      onComboChanged: (combo) {
        if (!mounted) return;
        setState(() => _combo = combo);
      },
      onLivesExhausted: _offerRevive,
      onStageComplete: (count, {bool earlyStop = false}) {
        if (_navigated) return;
        _navigated = true;
        final maxCombo = _game.maxCombo;
        final eatenByType = Map<EmotionType, int>.of(_game.eatenByType);
        final survivedSeconds = _game.elapsedSeconds;
        Future.delayed(const Duration(milliseconds: 350), () async {
          if (!mounted) return;
          // 스테이지 모드와 동일하게, 가끔(BreathingScheduler가 정한
          // 타이밍에만) 결과 화면으로 넘어가기 전 잠깐 숨을 고르는
          // 인터스티셜을 먼저 보여준다.
          if (BreathingScheduler.instance.shouldShow()) {
            await BreathingInterstitial.show(context);
          }
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => EndlessResultScreen(
                emotions: widget.emotions,
                targetName: widget.targetName,
                eatenByType: eatenByType,
                survivedSeconds: survivedSeconds,
                maxCombo: maxCombo,
              ),
            ),
          );
        });
      },
    );
  }

  @override
  void dispose() {
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

  /// 웹/데스크톱 테스트용 키보드 조작 - 스테이지 모드와 동일하게 점프는
  /// 누른 키별로 점프 홀드를 관리하고, 엔터·아래 방향키로 주먹을 실행한다.
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
      _game.releaseJumpInput(('key', event.logicalKey.keyId));
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// 점프를 발동시킨 손가락이 버튼에서 떨어지는 순간(또는 취소되는 경우)
  /// 호출된다 - 스테이지 모드와 동일한 차지 점프 해제 처리.
  void _handleJumpPointerRelease(PointerEvent event) {
    _game.releaseJumpInput(('pointer', event.pointer));
  }

  /// 화면 하단 오른쪽 "🦘 점프" 버튼(또는 스페이스바·방향키 위) -> 점프.
  /// 누르고 있는 동안 차지 점프로 더 길게/높게 이어진다.
  void _handleJumpInput({required Object source}) {
    if (!_game.acceptsGameplayInput) return;
    if (_showHint) {
      setState(() => _showHint = false);
    }
    _game.pressJumpInput(source);
  }

  /// 화면 하단 왼쪽 "✊ 주먹" 버튼(또는 엔터·방향키 아래) -> 주먹으로 작은
  /// 돌멩이 부수기 준비.
  void _handlePunchInput() {
    if (!_game.acceptsGameplayInput) return;
    if (_showHint) {
      setState(() => _showHint = false);
    }
    _game.punchAction();
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
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
              Positioned.fill(child: GameWidget(game: _game)),
              _buildTapHint(),
              _buildHud(),
              _buildTimeOfDayBadge(),
              _buildComboBadge(),
              _buildPowerModeBadge(),
              _buildCloseButton(),
              _buildPowerCharmButton(),
              _buildPunchButton(),
              _buildJumpButton(),
            ],
          ),
        ),
      ),
    );
  }

  /// 화면 하단 왼쪽에 항상 떠 있는 "✊ 주먹" 버튼(스테이지 모드와 동일).
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

  /// 화면 하단 오른쪽에 항상 떠 있는 "🦘 점프" 버튼(스테이지 모드와 동일).
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

  /// 주먹/점프 버튼 공통 원형 스타일(스테이지 모드와 동일한 디자인).
  Widget _buildActionButton({
    required String emoji,
    required String label,
    required Color color,
  }) {
    return Container(
      width: 86,
      height: 86,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.92),
        shape: BoxShape.circle,
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
              color: Colors.white,
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
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.62),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('♾️🐾', style: TextStyle(fontSize: 26)),
                  const SizedBox(height: 4),
                  Text(
                    l10n.endlessHintTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.gameHintControlsStage2Plus,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.endlessHintGoal,
                    style: const TextStyle(
                      color: Colors.white70,
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
    final garden = context.watch<GardenProvider>();
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_game.biome.emoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(
                  _formatTime(_elapsedSeconds),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '🍬 $_eatenCount',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: widget.emotions.first.color,
                  ),
                ),
                if (garden.bestEndlessCount > 0) ...[
                  const SizedBox(width: 10),
                  Text(
                    AppLocalizations.of(
                      context,
                    ).endlessHudBestRecord(garden.bestEndlessCount),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ],
                const SizedBox(width: 10),
                Row(
                  children: List.generate(_maxLives, (i) {
                    final filled = i < _lives;
                    return Text(
                      filled ? '❤️' : '🤍',
                      style: const TextStyle(fontSize: 13),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 실제 기기 시각이 새벽/밤일 때만 살짝 나타나는 작은 배지. 스테이지
  /// 모드(runner_game_screen.dart)와 동일한 문구/스타일을 사용한다.
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

  /// 파워빛볼을 먹어 무적 모드일 때 화면 중앙 위쪽에 크게 뜨는 배지 - 스테이지
  /// 모드(runner_game_screen.dart)와 동일한 문구/스타일을 사용한다.
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
          padding: const EdgeInsets.only(left: 10, top: 10),
          child: Material(
            color: Colors.white.withValues(alpha: 0.88),
            shape: const CircleBorder(),
            child: IconButton(
              icon: const Icon(Icons.close, color: AppColors.inkSoft),
              onPressed: _confirmExit,
            ),
          ),
        ),
      ),
    );
  }

  /// 화면 오른쪽 위, 닫기 버튼 아래에 떠 있는 "⚡ 파워 부적" 버튼(스테이지
  /// 모드와 동일한 디자인/동작).
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

  /// 스테이지 모드(runner_game_screen.dart)와 동일한 종료 확인 다이얼로그.
  /// "종료"를 선택하면 재생 중인 모든 소리를 완전히 멈추고 화면을 벗어난다.
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
    _navigated = true;
    await SoundManager.instance.stopEverything();
    if (!mounted) return;
    Navigator.of(context).pop();
  }
}
