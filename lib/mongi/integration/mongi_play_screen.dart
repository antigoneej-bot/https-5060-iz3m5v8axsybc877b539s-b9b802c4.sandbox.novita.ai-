import 'dart:async';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../../services/sound_service.dart';
import '../../services/media_coordinator.dart';
import '../game/runner_game.dart';
import '../models/emotion.dart';
import '../services/sound_manager.dart';
import '../widgets/breathing_moment_sheet.dart';
import 'mongi_garden_store.dart';

class MongiPlayScreen extends StatefulWidget {
  final List<Emotion> emotions;
  final int stage;
  const MongiPlayScreen({
    super.key,
    required this.emotions,
    required this.stage,
  });
  @override
  State<MongiPlayScreen> createState() => _MongiPlayScreenState();
}

class _MongiPlayScreenState extends State<MongiPlayScreen>
    with WidgetsBindingObserver {
  late final RunnerGame _game;
  Timer? _hud;
  bool _prepared = false, _paused = false, _finished = false, _saving = false;
  bool _cleared = false, _saved = false, _leaving = false;
  String? _saveError;
  int? _jumpPointer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Flame.images.prefix = 'assets/mongi/images/';
    _game = RunnerGame(
      emotions: widget.emotions,
      targetName: null,
      stage: widget.stage,
      targetEatenCount: RunnerGame.targetForStage(widget.stage),
      onRockHit: () {},
      onProgressChanged: (_) {},
      onStageComplete: (_, {bool earlyStop = false}) {
        if (_finished) return;
        _finished = true;
        _cleared = !earlyStop;
        scheduleMicrotask(_finish);
      },
      onBreathingMomentStart: () {
        scheduleMicrotask(() async {
          if (!mounted || _leaving) return;
          final succeeded = await BreathingMomentSheet.show(context);
          if (mounted && !_leaving) {
            _game.resolveBreathingMoment(succeeded: succeeded);
          }
        });
      },
      onLivesExhausted: (count, {required bool requiresAd}) async {
        if (!mounted || requiresAd || _leaving) return false;
        return await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('한 번 더 달릴까요?'),
                content: Text(
                  '이번 판에 ${RunnerGame.freeRevivesPerRun - count}번 더 이어갈 수 있어요.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('여기까지'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('이어 달리기'),
                  ),
                ],
              ),
            ) ??
            false;
      },
    );
    SoundService().gardenSuspended = true;
    _prepare();
  }

  Future<void> _prepare() async {
    try {
      await MediaCoordinator.instance.stopAll();
      await SoundService().stopAll();
    } catch (_) {}
    if (!mounted) return;
    SoundManager.instance.setMuted(
      !SoundService().sfxEnabled && !SoundService().bgmEnabled,
    );
    SoundManager.instance.musicEnabled = SoundService().bgmEnabled;
    SoundManager.instance.effectsEnabled = SoundService().sfxEnabled;
    setState(() => _prepared = true);
    _hud = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (mounted) {
        if (_paused || _finished) _game.pauseEngine();
        setState(() {});
      }
    });
  }

  Future<void> _finish() async {
    if (!mounted) return;
    _game.pauseEngine();
    await SoundManager.instance.pauseAllForBackground();
    if (!_cleared) {
      if (mounted) setState(() {});
      return;
    }
    await _save();
  }

  Future<void> _save() async {
    if (_saving || _saved || !mounted) return;
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      await MongiGardenStore.instance.completeStage(widget.stage);
      _saved = true;
    } catch (_) {
      _saveError = '보상을 저장하지 못했어요.';
    }
    if (mounted) setState(() => _saving = false);
  }

  void _pause() {
    _game.pauseEngine();
    if (_game.isHolding) _game.setJumpHeld(false);
    _jumpPointer = null;
    SoundManager.instance.pauseAllForBackground();
    if (mounted) setState(() => _paused = true);
  }

  void _resume() {
    if (_finished || _leaving) return;
    setState(() => _paused = false);
    _game.resumeEngine();
    SoundManager.instance.resumeAllFromBackground();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _pause();
  }

  Future<void> _exit() async {
    if (_leaving || _saving) return;
    _pause();
    if (!_finished || (_cleared && !_saved)) {
      final leave = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('정원으로 돌아갈까요?'),
          content: Text(
            _cleared
                ? '아직 보상을 저장하지 못했어요. 나가면 이번 보상은 받지 못해요.'
                : '이번 판을 마쳐야 씨앗을 받을 수 있어요.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('계속하기'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('돌아가기'),
            ),
          ],
        ),
      );
      if (!mounted || leave != true) {
        if (mounted) _resume();
        return;
      }
    }
    if (!mounted) return;
    setState(() => _leaving = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop(_saved);
    });
  }

  @override
  void dispose() {
    SoundService().gardenSuspended = false;
    _leaving = true;
    _hud?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _game.pauseEngine();
    // Run after the old GameWidget has detached and its onRemove has stopped audio.
    Future<void>(() async {
      await SoundManager.instance.pauseAllForBackground();
      await SoundManager.instance.stopBgm();
      await SoundManager.instance.stopAmbientNature();
      try {
        await SoundService().tryStartBgm();
      } catch (_) {}
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _leaving,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _exit();
    },
    child: Scaffold(
      appBar: AppBar(
        title: Text('몽이 · 스테이지 ${widget.stage}'),
        leading: IconButton(
          onPressed: _exit,
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [IconButton(onPressed: _pause, icon: const Icon(Icons.pause))],
      ),
      body: !_prepared
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Positioned.fill(
                  child: ClipRect(
                    child: GameWidget(
                      game: _game,
                      loadingBuilder: (_) =>
                          const Center(child: CircularProgressIndicator()),
                      errorBuilder: (_, error) => const Center(
                        child: Text('게임을 불러오지 못했어요. 뒤로 가서 다시 시도해 주세요.'),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 16,
                  right: 16,
                  child: IgnorePointer(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(
                          '감정 ${_game.eatenCount}/${_game.targetEatenCount}  ·  ♥ ${_game.lives}  ·  ${_game.secondsRemaining}초',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
                if (!_finished && !_paused)
                  Positioned(
                    bottom: 24,
                    left: 24,
                    right: 24,
                    child: SafeArea(
                      top: false,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _control('✊ 주먹', () {
                            if (_game.isHolding) _game.punchAction();
                          }),
                          Listener(
                            onPointerDown: (event) {
                              if (!_game.isHolding || _jumpPointer != null) {
                                return;
                              }
                              _jumpPointer = event.pointer;
                              _game.jump();
                              _game.setJumpHeld(true);
                            },
                            onPointerUp: _releaseJump,
                            onPointerCancel: _releaseJump,
                            child: _control('점프 ↑', null),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_paused && !_finished)
                  Positioned.fill(
                    child: ColoredBox(
                      color: Colors.black54,
                      child: Center(
                        child: FilledButton(
                          onPressed: _resume,
                          child: const Text('계속 달리기'),
                        ),
                      ),
                    ),
                  ),
                if (_finished)
                  Positioned.fill(
                    child: ColoredBox(
                      color: Colors.black54,
                      child: Center(
                        child: Card(
                          margin: const EdgeInsets.all(24),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _cleared ? '스테이지 클리어!' : '몽이와 함께 잘 달렸어요.',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _cleared
                                      ? (_saved
                                            ? '씨앗 1개와 빛의 정수 30개를 받았어요.\n우리 정원에 심어 볼까요?'
                                            : '정원에 보상을 저장하고 있어요.')
                                      : '준비되면 다시 달려요. 정원은 그대로 기다려요.',
                                ),
                                if (_saving)
                                  const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: CircularProgressIndicator(),
                                  ),
                                if (_saveError != null) ...[
                                  const Text('보상을 저장하지 못했어요.'),
                                  TextButton(
                                    onPressed: _saving ? null : _save,
                                    child: const Text('저장 다시 시도'),
                                  ),
                                ],
                                FilledButton(
                                  onPressed: _saving ? null : _exit,
                                  child: const Text('정원으로 돌아가기'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    ),
  );

  void _releaseJump(PointerEvent event) {
    if (_jumpPointer != event.pointer) return;
    _jumpPointer = null;
    if (_game.isHolding) _game.setJumpHeld(false);
  }

  Widget _control(String text, VoidCallback? action) => GestureDetector(
    onTapDown: action == null ? null : (_) => action(),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
      ),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
    ),
  );
}
