import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'storage_service.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  final AudioPlayer _bgmPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _meowPlayer = AudioPlayer();
  final AudioPlayer _purrPlayer = AudioPlayer();
  final AudioPlayer _bubblePlayer = AudioPlayer();

  bool narrationPlaying = false;
  bool sfxEnabled = true;
  bool bgmEnabled = false;
  double bgmVolume = 0.35;
  bool _bgmStarted = false;

  Future<void> init() async {
    sfxEnabled = await StorageService.getSfxEnabled();
    bgmEnabled = await StorageService.getBgmEnabled();
    bgmVolume = await StorageService.getBgmVolume();
    await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    await _bgmPlayer.setVolume(bgmVolume);
  }

  Future<void> tryStartBgm() async {
    if (bgmEnabled && !_bgmStarted) {
      await startBgm();
    }
  }

  Future<void> startBgm() async {
    if (narrationPlaying) return;
    try {
      await _bgmPlayer
          .play(AssetSource('audio/bgm_mystic.mp3'), volume: bgmVolume)
          .timeout(const Duration(seconds: 2));
      _bgmStarted = true;
    } catch (e) {
      if (kDebugMode) debugPrint('BGM start error: $e');
    }
  }

  Future<void> stopBgm() async {
    await _bgmPlayer.stop();
    _bgmStarted = false;
  }

  Future<void> setBgmEnabled(bool v) async {
    bgmEnabled = v;
    await StorageService.setBgmEnabled(v);
    if (v) {
      await startBgm();
    } else {
      await stopBgm();
    }
  }

  Future<void> setSfxEnabled(bool v) async {
    sfxEnabled = v;
    await StorageService.setSfxEnabled(v);
  }

  Future<void> setBgmVolume(double v) async {
    bgmVolume = v;
    await StorageService.setBgmVolume(v);
    await _bgmPlayer.setVolume(v);
  }

  Future<void> playShuffle() async {
    if (!sfxEnabled) return;
    try {
      await _sfxPlayer
          .play(AssetSource('audio/sfx_shuffle.mp3'))
          .timeout(const Duration(seconds: 2));
    } catch (_) {}
  }

  Future<void> playFlip() async {
    if (!sfxEnabled) return;
    try {
      await _sfxPlayer
          .play(AssetSource('audio/sfx_flip.mp3'))
          .timeout(const Duration(seconds: 2));
    } catch (_) {}
  }

  Future<void> playChime() async {
    if (!sfxEnabled) return;
    try {
      await _sfxPlayer
          .play(AssetSource('audio/sfx_chime.mp3'))
          .timeout(const Duration(seconds: 2));
    } catch (_) {}
  }

  Future<void> playMeow() async {
    if (!sfxEnabled) return;
    try {
      await _meowPlayer
          .play(AssetSource('audio/sfx_meow.mp3'))
          .timeout(const Duration(seconds: 2));
    } catch (_) {}
  }

  /// 고양이를 연속으로 여러 번 쓰다듬었을 때 나오는 골골송(퍼링) 사운드.
  Future<void> playPurr() async {
    if (!sfxEnabled) return;
    try {
      await _purrPlayer
          .play(AssetSource('audio/sfx_purr.mp3'))
          .timeout(const Duration(seconds: 2));
    } catch (_) {}
  }

  /// '오늘의 그림자 방울 터뜨리기'에서 방울 하나를 터뜨렸을 때 나는
  /// 아주 작고 부드러운 소리.
  Future<void> playBubblePop() async {
    if (!sfxEnabled) return;
    try {
      await _bubblePlayer
          .play(AssetSource('audio/sfx_bubble_pop.mp3'))
          .timeout(const Duration(seconds: 2));
    } catch (_) {}
  }

  /// 방울을 모두 터뜨려 오늘의 의식을 마쳤을 때 나는 잔잔한 완료 사운드.
  Future<void> playGardenComplete() async {
    if (!sfxEnabled) return;
    try {
      await _sfxPlayer
          .play(AssetSource('audio/sfx_garden_complete.mp3'))
          .timeout(const Duration(seconds: 2));
    } catch (_) {}
  }
}
