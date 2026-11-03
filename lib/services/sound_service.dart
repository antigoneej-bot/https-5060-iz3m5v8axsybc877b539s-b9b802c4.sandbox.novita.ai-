import 'package:shared_preferences/shared_preferences.dart';
import '../mongi/services/sound_manager.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'storage_service.dart';
import 'local_record_transaction.dart';

class SoundService extends ChangeNotifier {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();
  @visibleForTesting
  SoundService.forTesting();

  final AudioPlayer _bgmPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _meowPlayer = AudioPlayer();
  final AudioPlayer _purrPlayer = AudioPlayer();
  final AudioPlayer _bubblePlayer = AudioPlayer();

  bool sleepStopped = false;
  bool narrationPlaying = false;
  bool gardenSuspended = false;
  final _bgmQueue = LocalRecordQueue();
  Future<void> _bgmAction(Future<void> Function() action) =>
      _bgmQueue.run(action);

  bool _appAudible = true;
  bool _bgmPrepared = false;
  String? bgmError;
  final _effectContexts = <AudioPlayer>{};
  final _effectQueues = <AudioPlayer, LocalRecordQueue>{};
  // Only BGM/meditation owns focus. A short cat effect must not permanently
  // pause BGM through Android's default AUDIOFOCUS_GAIN request.
  static final _effectContext = AudioContext(
    android: const AudioContextAndroid(audioFocus: AndroidAudioFocus.none),
    iOS: AudioContextIOS(options: const {AVAudioSessionOptions.mixWithOthers}),
  );

  void _audioFailed(Object error) {
    _bgmStarted = false;
    bgmError = '음악을 불러오지 못했어요. 다시 재생해 주세요.';
    notifyListeners();
    if (kDebugMode) debugPrint('BGM error: $error');
  }

  bool get _canPlayBgm =>
      !sleepStopped &&
      bgmEnabled &&
      _appAudible &&
      !narrationPlaying &&
      !gardenSuspended;

  /// App visibility is updated synchronously, so a late decoder completion
  /// cannot start music after the app is hidden or locked.
  Future<void> setAppAudible(bool value, {bool autoplay = true}) {
    _appAudible = value;
    SoundManager.instance.appAudible = value;
    if (!value) {
      unawaited(SoundManager.instance.pauseAmbientNature());
    } else if (SoundManager.instance.ambientRequested &&
        !sleepStopped &&
        !narrationPlaying) {
      unawaited(
        SoundManager.instance.ambientNaturePlaying
            ? SoundManager.instance.resumeAmbientNatureIfNeeded()
            : SoundManager.instance.startAmbientNature(),
      );
    }
    if (value) return autoplay ? tryStartBgm() : Future<void>.value();
    return _bgmAction(() async {
      if (_appAudible) return;
      await _bgmPlayer.pause();
      _bgmStarted = false;
    });
  }

  Future<void> _prepareBgm() async {
    if (_bgmPrepared) return;
    // Keep normal media focus for BGM so other apps and calls can interrupt it.
    await _bgmPlayer.setAudioContext(AudioContext());
    await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    await _bgmPlayer.setVolume(bgmVolume);
    await _bgmPlayer.setSource(AssetSource('audio/bgm_mystic.mp3'));
    _bgmPrepared = true;
  }

  Future<void> stopAll() async {
    await stopBgm();
    for (final player in [
      _sfxPlayer,
      _meowPlayer,
      _purrPlayer,
      _bubblePlayer,
    ]) {
      await player.stop();
    }
  }

  bool catSoundEnabled = true;
  double catVolume = .6;
  DateTime _lastCatSound = DateTime.fromMillisecondsSinceEpoch(0);
  final _catQueue = LocalRecordQueue();
  Future<void> setCatSound({bool? enabled, double? volume}) async {
    catSoundEnabled = enabled ?? catSoundEnabled;
    catVolume = (volume ?? catVolume).clamp(0.0, 1.0).toDouble();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('cat_sound_enabled', catSoundEnabled);
    await prefs.setDouble('cat_sound_volume', catVolume);
    if (!catSoundEnabled || catVolume == 0) {
      await _meowPlayer.stop();
      await _purrPlayer.stop();
    }
  }

  Future<void> _catSound(bool purr) async {
    if (!catSoundEnabled ||
        catVolume == 0 ||
        !_canPlayEffect ||
        DateTime.now().difference(_lastCatSound).inMilliseconds < 1800)
      return;
    _lastCatSound = DateTime.now();
    try {
      await _catQueue.run(() async {
        if (!catSoundEnabled || !_canPlayEffect) return;
        await _meowPlayer.stop();
        await _purrPlayer.stop();
        final player = purr ? _purrPlayer : _meowPlayer;
        await player.setVolume(catVolume);
        await _playEffect(
          player,
          purr ? 'audio/sfx_purr.mp3' : 'audio/sfx_meow.mp3',
        );
      });
    } catch (_) {
      /* Sound must not block greeting or care. */
    }
  }

  bool sfxEnabled = true;
  bool bgmEnabled = false;
  double bgmVolume = 0.35;
  bool _bgmStarted = false;

  Future<void> init() async {
    final catPrefs = await SharedPreferences.getInstance();
    catSoundEnabled = catPrefs.getBool('cat_sound_enabled') ?? true;
    catVolume = (catPrefs.getDouble('cat_sound_volume') ?? .6)
        .clamp(0.0, 1.0)
        .toDouble();
    await SoundManager.instance.loadNatureSettings();
    sfxEnabled = await StorageService.getSfxEnabled();
    bgmEnabled = await StorageService.getBgmEnabled();
    bgmVolume = _validVolume(await StorageService.getBgmVolume());
    notifyListeners();
    // Prepare the bundled audio during startup; playing still waits for the
    // visible app. Audio failure must not block access to the user's records.
    if (bgmEnabled && !kIsWeb) {
      unawaited(
        _bgmAction(_prepareBgm).catchError((Object e) {
          _audioFailed(e);
        }),
      );
    }
  }

  Future<void> tryStartBgm() => startBgm();

  Future<void> startBgm() => _bgmAction(_startBgmDirect);

  Future<void> _startBgmDirect() async {
    if (!_canPlayBgm || _bgmStarted) return;
    try {
      await _prepareBgm();
      await _bgmPlayer.setVolume(bgmVolume);
      if (!_canPlayBgm) return;
      await _bgmPlayer.resume();
      _bgmStarted = true;
      if (bgmError != null) {
        bgmError = null;
        notifyListeners();
      }
    } catch (e) {
      _audioFailed(e);
    }
  }

  /// Explicit user recovery. Native Android focus loss can leave the Dart
  /// player state marked playing even though the native player is paused.
  /// Releasing also recovers a decoder error; ordinary taps never reset music.
  Future<bool> retryBgm() => _bgmQueue.run(() async {
    if (!_canPlayBgm || bgmVolume == 0) return false;
    _bgmStarted = false;
    _bgmPrepared = false;
    try {
      await _bgmPlayer.release();
      await _startBgmDirect();
      return _bgmStarted && _canPlayBgm;
    } catch (e) {
      _audioFailed(e);
      return false;
    }
  });

  Future<void> stopBgm() => _bgmAction(() async {
    _bgmStarted = false;
    await _bgmPlayer.stop();
  });

  Future<void> setBgmEnabled(bool v) async {
    final wasEnabled = bgmEnabled;
    bgmEnabled = v;
    if (!v) bgmError = null;
    notifyListeners();
    await StorageService.setBgmEnabled(v);
    if (v) {
      if (wasEnabled) {
        await retryBgm();
      } else {
        await startBgm();
      }
    } else {
      await stopBgm();
    }
  }

  Future<void> setSfxEnabled(bool v) async {
    sfxEnabled = v;
    notifyListeners();
    await StorageService.setSfxEnabled(v);
  }

  static double _validVolume(double value) =>
      value.isFinite ? value.clamp(0.0, 1.0) : 0.35;

  Future<void> setBgmVolume(double v) async {
    bgmVolume = _validVolume(v);
    notifyListeners();
    await StorageService.setBgmVolume(bgmVolume);
    await _bgmAction(() async {
      try {
        await _bgmPlayer.setVolume(bgmVolume);
      } catch (e) {
        _audioFailed(e);
      }
    });
  }

  bool get _canPlayEffect =>
      !sleepStopped &&
      sfxEnabled &&
      _appAudible &&
      !gardenSuspended &&
      !narrationPlaying;

  Future<void> _playEffect(AudioPlayer player, String asset) {
    if (!_canPlayEffect) return Future<void>.value();
    return _effectQueues.putIfAbsent(player, LocalRecordQueue.new).run(
      () async {
        if (!_canPlayEffect) return;
        try {
          if (!_effectContexts.contains(player)) {
            await player.setAudioContext(_effectContext);
            _effectContexts.add(player);
          }
          await player.setSource(AssetSource(asset));
          if (_canPlayEffect &&
              (!(player == _meowPlayer || player == _purrPlayer) ||
                  catSoundEnabled && catVolume > 0))
            await player.resume();
        } catch (_) {
          // A missing effect must never prevent the user's care/record action.
        }
      },
    );
  }

  Future<void> playShuffle() =>
      _playEffect(_sfxPlayer, 'audio/sfx_shuffle.mp3');
  Future<void> playFlip() => _playEffect(_sfxPlayer, 'audio/sfx_flip.mp3');
  Future<void> playChime() => _playEffect(_sfxPlayer, 'audio/sfx_chime.mp3');
  Future<void> playMeow() => _catSound(false);
  Future<void> playPurr() => _catSound(true);
  Future<void> stopPurr() => _effectQueues
      .putIfAbsent(_purrPlayer, LocalRecordQueue.new)
      .run(() async {
        try {
          await _purrPlayer.stop();
        } catch (_) {
          /* Safe during teardown. */
        }
      });
  Future<void> playBubblePop() =>
      _playEffect(_bubblePlayer, 'audio/sfx_bubble_pop.mp3');
  Future<void> playGardenComplete() =>
      _playEffect(_sfxPlayer, 'audio/sfx_garden_complete.mp3');
}
