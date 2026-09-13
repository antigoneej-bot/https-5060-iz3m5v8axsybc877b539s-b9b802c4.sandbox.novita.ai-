import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'sound_service.dart';

class MeditationAudioService with WidgetsBindingObserver {
  static final instance = MeditationAudioService._();
  MeditationAudioService._() {
    WidgetsBinding.instance.addObserver(this);
    _player.onPlayerComplete.listen((_) { playing.value = null; _asset = null; SoundService().narrationPlaying = false; });
  }
  final _player = AudioPlayer();
  final playing = ValueNotifier<String?>(null);
  String? _asset;
  Future<void> _tail = Future.value();
  Future<void> toggle(String asset) {
    final result = _tail.catchError((Object _) {}).then((_) async {
      try {
        if (playing.value == asset) {
          await _player.pause(); playing.value = null; SoundService().narrationPlaying = false; return;
        }
        SoundService().narrationPlaying = true;
        await SoundService().stopBgm();
        if (_asset == asset) { await _player.resume(); }
        else {
          await _player.stop();
          await _player.play(AssetSource(asset.substring('assets/'.length)));
        }
        _asset = asset; playing.value = asset;
      } catch (_) { playing.value = null; _asset = null; SoundService().narrationPlaying = false; rethrow; }
    });
    _tail = result.catchError((Object _) {});
    return result;
  }
  Future<void> pause(String asset) {
    final result = _tail.catchError((Object _) {}).then((_) async {
      if (playing.value == asset) { await _player.pause(); playing.value = null; SoundService().narrationPlaying = false; }
    });
    _tail = result.catchError((Object _) {});
    return result;
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      // Queue after any in-flight play so backgrounding cannot restart audio.
      final result = _tail.catchError((Object _) {}).then((_) async {
        await _player.pause(); playing.value = null; SoundService().narrationPlaying = false;
      });
      _tail = result.catchError((Object _) {});
    }
  }
}
