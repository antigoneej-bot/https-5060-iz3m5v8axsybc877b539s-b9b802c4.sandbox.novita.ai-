import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class BackgroundAudioBridge {
  static const _channel = MethodChannel('garden/background_audio');
  static bool get _native =>
      !kIsWeb &&
      [
        TargetPlatform.android,
        TargetPlatform.iOS,
      ].contains(defaultTargetPlatform);
  static void onCommands({
    required Future<void> Function() stop,
    required Future<void> Function() play,
    required Future<void> Function() pause,
  }) {
    if (_native)
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'stop') await stop();
        if (call.method == 'play') await play();
        if (call.method == 'pause') await pause();
      });
  }

  static Future<void> start() async {
    if (_native) await _channel.invokeMethod<void>('start');
  }

  static Future<void> stop() async {
    if (_native) await _channel.invokeMethod<void>('stop');
  }

  static Future<void> update({
    required String title,
    required bool playing,
    required Duration position,
    required Duration duration,
    required double speed,
  }) async {
    if (_native)
      await _channel.invokeMethod<void>('update', {
        'title': title,
        'playing': playing,
        'position': position.inMilliseconds,
        'duration': duration.inMilliseconds,
        'speed': speed,
      });
  }
}
