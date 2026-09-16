import '../data/solutions_data.dart';
import 'access_policy.dart';
import 'subscription_service.dart';
import 'meditation_library_store.dart';
import 'meditation_sleep_service.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'media_coordinator.dart';
import 'meditation_completion_service.dart';
import 'background_audio_bridge.dart';

class MeditationAudioService with WidgetsBindingObserver {
  static final instance = MeditationAudioService._();
  MeditationAudioService._() {
    WidgetsBinding.instance.addObserver(this);
    BackgroundAudioBridge.onCommands(
      stop: () => MediaCoordinator.instance.stopAll(),
      play: () async {
        final asset = _asset;
        if (asset != null && playing.value == null) await toggle(asset);
      },
      pause: () => _queue(() async {
        if (playing.value == null) return;
        await _player.pause();
        MeditationSleepService.instance.detach(this);
        playing.value = null;
        await _syncNative();
        _notify();
      }),
    );
    _player.onDurationChanged.listen((value) {
      duration = value;
      unawaited(_syncNative().catchError((Object _) {}));
      _notify();
    });
    _player.onPositionChanged.listen((value) {
      position = value;
      _notify();
    });
    _player.onPlayerComplete.listen((_) {
      final completedAsset = playing.value;
      if (completedAsset == null) return;
      unawaited(
        _queue(() async {
          if (_asset != completedAsset || playing.value != completedAsset)
            return;
          final key = completedAsset.split('/').last.split('.').first;
          if (!_sessionCompleted) {
            _sessionCompleted = true;
            await MeditationCompletionService.instance.complete(guideKey: key);
          }
          final sleep = MeditationSleepService.instance;
          if (key == 'rainThunderRest' &&
              identical(sleep.owner, this) &&
              sleep.repeat &&
              AccessPolicy.meditationAllowed(
                key,
                await SubscriptionService().isPremium(),
              ) &&
              (sleep.deadline == null || sleep.remaining > Duration.zero)) {
            await _player.seek(Duration.zero);
            position = Duration.zero;
            await _player.resume();
            await _syncNative();
            _notify();
            return;
          }
          sleep.detach(this);
          playing.value = null;
          _asset = null;
          MediaCoordinator.instance.release(this);
          await BackgroundAudioBridge.stop();
          position = Duration.zero;
          duration = Duration.zero;
          _notify();
        }),
      );
    });
  }

  final _player = AudioPlayer();
  final playing = ValueNotifier<String?>(null);
  String? _asset;
  bool _sessionCompleted = false;
  String? get activeAsset => _asset;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  double volume = 0.75;
  double speed = 1.0;
  final changes = ValueNotifier<int>(0);
  void _notify() => changes.value++;

  Future<void> _queue(Future<void> Function() action) =>
      MediaCoordinator.instance.run(action);
  Future<void> _pauseDirect() async {
    MeditationSleepService.instance.detach(this);
    await _player.pause();
    playing.value = null;
    await BackgroundAudioBridge.stop();
    _notify();
  }

  Future<void> setVolume(double value) => _queue(() async {
    final next = value.clamp(0.0, 1.0);
    if (_asset != null)
      await _player.setVolume(next * MeditationSleepService.instance.factor);
    volume = next;
    _notify();
  });

  Future<void> setSpeed(double value) => _queue(() async {
    if (![0.85, 1.0, 1.15].contains(value)) return;
    if (_asset != null) await _player.setPlaybackRate(value);
    speed = value;
    await _syncNative();
    _notify();
  });

  Future<void> restart(String asset) => _queue(() async {
    if (_asset != asset) return;
    await _player.seek(Duration.zero);
    position = Duration.zero;
    await _syncNative();
    _notify();
  });

  Future<void> toggle(String asset) {
    unawaited(MeditationCompletionService.instance.retry());
    return _queue(() async {
      try {
        if (playing.value == asset) {
          await _pauseDirect();
          MediaCoordinator.instance.release(this);
          return;
        }
        final key = asset.split('/').last.split('.').first;
        if (!AccessPolicy.meditationAllowed(
          key,
          await SubscriptionService().isPremium(),
        ))
          throw const SubscriptionRequired('전체 명상은 마음냥 구독으로 이용할 수 있어요.');
        await MediaCoordinator.instance.claim(this, _pauseDirect);
        await _player.setAudioContext(
          AudioContext(
            android: const AudioContextAndroid(stayAwake: true),
            iOS: AudioContextIOS(category: AVAudioSessionCategory.playback),
          ),
        );
        await BackgroundAudioBridge.start();
        if (_asset != asset) {
          _sessionCompleted = false;
          await MeditationCompletionService.instance.begin(
            asset.split('/').last.split('.').first,
          );
          MeditationSleepService.instance.detach(this);
          await _player.stop();
          position = Duration.zero;
          duration = Duration.zero;
          await _player.setSource(
            AssetSource(asset.substring('assets/'.length)),
          );
          await _player.setVolume(volume);
          await _player.setPlaybackRate(speed);
        }
        _asset = asset;
        await _player.setReleaseMode(ReleaseMode.stop);
        await _player.setVolume(volume);
        await _player.resume();
        playing.value = asset;
        MeditationSleepService.instance.attach(
          this,
          volume: (factor) => _queue(() async {
            if (_asset == asset &&
                identical(MeditationSleepService.instance.owner, this))
              await _player.setVolume(volume * factor);
          }),
          stop: () => pause(asset),
        );
        unawaited(
          MeditationLibraryStore.instance
              .played(asset.split('/').last.split('.').first)
              .catchError((Object _) {}),
        );
        await _syncNative();
        _notify();
      } catch (_) {
        MeditationSleepService.instance.detach(this);
        await _player.stop();
        playing.value = null;
        _asset = null;
        MediaCoordinator.instance.release(this);
        await BackgroundAudioBridge.stop();
        rethrow;
      }
    });
  }

  Future<void> pause(String asset) => _queue(() async {
    if (_asset == asset) {
      await _pauseDirect();
      MediaCoordinator.instance.release(this);
    }
  });

  /// A course must start a fresh run even if this same file was paused earlier.
  Future<void> stopForNewSession() => _queue(() async {
    if (_asset == null) return;
    await _pauseDirect();
    await _player.stop();
    _asset = null;
    _sessionCompleted = false;
    position = Duration.zero;
    duration = Duration.zero;
    MediaCoordinator.instance.release(this);
    _notify();
  });

  Future<void> _syncNative() async {
    final asset = _asset;
    if (asset == null) return;
    final key = asset.split('/').last.split('.').first;
    await BackgroundAudioBridge.update(
      title: breathingGuide[key]?.title ?? '마음냥 정원 명상',
      playing: playing.value != null,
      position: position,
      duration: duration,
      speed: speed,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Audio intentionally continues while locked/backgrounded. Explicit exit,
    // another player, route disposal, or the notification can stop playback.
    if (state == AppLifecycleState.resumed)
      unawaited(MeditationSleepService.instance.tick());
    if (state == AppLifecycleState.detached) {
      unawaited(MediaCoordinator.instance.stopAll());
    }
  }
}
