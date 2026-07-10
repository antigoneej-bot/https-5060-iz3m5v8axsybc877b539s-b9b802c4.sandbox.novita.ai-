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
    try {
      await _bgmPlayer.play(
        AssetSource('audio/bgm_mystic.mp3'),
        volume: bgmVolume,
      );
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
      await _sfxPlayer.play(AssetSource('audio/sfx_shuffle.mp3'));
    } catch (_) {}
  }

  Future<void> playFlip() async {
    if (!sfxEnabled) return;
    try {
      await _sfxPlayer.play(AssetSource('audio/sfx_flip.mp3'));
    } catch (_) {}
  }

  Future<void> playChime() async {
    if (!sfxEnabled) return;
    try {
      await _sfxPlayer.play(AssetSource('audio/sfx_chime.mp3'));
    } catch (_) {}
  }

  Future<void> playMeow() async {
    if (!sfxEnabled) return;
    try {
      await _meowPlayer.play(AssetSource('audio/sfx_meow.mp3'));
    } catch (_) {}
  }
}
