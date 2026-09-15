import 'package:flutter_app/services/meditation_course_store.dart';
import 'package:flutter_app/services/meditation_sleep_service.dart';
import 'package:flutter_app/services/meditation_library_store.dart';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:audioplayers_platform_interface/audioplayers_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/services/meditation_audio_service.dart';
import 'package:flutter_app/services/sound_service.dart';
import 'package:flutter_app/services/media_coordinator.dart';
import 'package:flutter_app/services/meditation_completion_service.dart';
import 'package:flutter_app/mongi/integration/mongi_garden_store.dart';
import 'support/fake_audioplayers_platform.dart';
import 'support/fake_global_audioplayers_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'audio controls preserve pause, restart, settings and lifecycle order',
    () async {
      final platform = FakeAudioplayersPlatform();
      AudioplayersPlatformInterface.instance = platform;
      GlobalAudioplayersPlatformInterface.instance =
          FakeGlobalAudioplayersPlatform();
      SharedPreferences.setMockInitialValues({});
      final temp = Directory.systemTemp.createTempSync('audio-test-');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (_) async => temp.path,
          );
      final bridgeCalls = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('garden/background_audio'),
            (call) async {
              bridgeCalls.add(call.method);
              return null;
            },
          );
      final audio = MeditationAudioService.instance;
      const asset = 'assets/audio/meditation/sleepMeditation.mp3';
      await audio.setSpeed(0.85);
      await audio.setVolume(0.4);
      await audio.toggle(asset);
      expect(audio.playing.value, asset);
      expect(SoundService().narrationPlaying, isTrue);
      final id = platform.calls.lastWhere((c) => c.method == 'resume').id;
      expect(
        platform.calls
            .where((c) => c.id == id && c.method == 'setPlaybackRate')
            .last
            .value,
        0.85,
      );
      expect(
        platform.calls
            .where((c) => c.id == id && c.method == 'setVolume')
            .last
            .value,
        0.4,
      );
      platform.eventStreamControllers[id]!.add(
        const AudioEvent(
          eventType: AudioEventType.duration,
          duration: Duration(seconds: 318),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(audio.duration.inSeconds, 318);
      await audio.toggle(asset);
      expect(audio.playing.value, isNull);
      expect(audio.activeAsset, asset);
      await audio.restart(asset);
      expect(
        platform.calls.lastWhere((c) => c.method == 'seek').value,
        Duration.zero,
      );
      expect(audio.playing.value, isNull); // restart must not autoplay
      await audio.toggle(asset);
      final pause = audio.pause(asset);
      final resume = audio.toggle(asset);
      audio.didChangeAppLifecycleState(AppLifecycleState.paused);
      await pause;
      await resume;
      await audio.setVolume(0.5);
      expect(audio.playing.value, asset); // screen lock keeps audio playing
      expect(SoundService().narrationPlaying, isTrue);
      expect(audio.activeAsset, asset);
      await audio.setSpeed(2);
      expect(audio.speed, 0.85);
      await audio.pause('assets/audio/meditation/other.mp3');
      expect(audio.playing.value, asset);
      await audio.pause(asset);
      // Video takes ownership, then audio takes it back, then explicit exit.
      final media = MediaCoordinator.instance;
      var videoPlaying = false;
      final video = Object();
      await audio.toggle(asset);
      await media.run(() async {
        await media.claim(video, () async {
          videoPlaying = false;
        });
        videoPlaying = true;
      });
      expect(audio.playing.value, isNull);
      expect(videoPlaying, isTrue);
      await audio.toggle(asset);
      expect(videoPlaying, isFalse);
      expect(audio.playing.value, asset);
      await media.stopAll();
      expect(audio.playing.value, isNull);
      expect(SoundService().narrationPlaying, isFalse);
      expect(bridgeCalls, contains('start'));
      expect(bridgeCalls.last, 'stop');
      SoundService().bgmEnabled = true;
      SoundService().gardenSuspended = true;
      final count = platform.calls.where((c) => c.method == 'resume').length;
      await SoundService().startBgm();
      expect(platform.calls.where((c) => c.method == 'resume').length, count);
      SoundService().gardenSuspended = false;
      // Audio and video completion share a persisted daily allowance.
      final store = MongiGardenStore.instance;
      await store.reload();
      final before = store.value.seedTokens;
      await Future.wait([
        MeditationCompletionService.instance.complete(),
        MeditationCompletionService.instance.complete(),
      ]);
      expect(store.value.seedTokens, before + 1);
      await store.reload();
      await MeditationCompletionService.instance.complete();
      expect(store.value.seedTokens, before + 1);
      for (final feeling in ['better', 'same', 'worse']) {
        await MeditationLibraryStore.instance.checkIn(
          'reward-$feeling',
          'forestRest',
          feeling,
        );
        expect(store.value.seedTokens, before + 1);
      }
      const rain = 'assets/audio/meditation/rainThunderRest.mp3';
      await audio.toggle(rain);
      MeditationSleepService.instance.setRepeat(true);
      final playerId = platform.calls.lastWhere((c) => c.method == 'resume').id;
      platform.eventStreamControllers[playerId]!.add(
        const AudioEvent(eventType: AudioEventType.complete),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await media.run(() async {});
      expect(audio.playing.value, rain);
      final checkIn = MeditationCompletionService.instance.completed.value;
      expect(checkIn?.key, 'rainThunderRest');
      platform.eventStreamControllers[playerId]!.add(
        const AudioEvent(eventType: AudioEventType.complete),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await media.run(() async {});
      expect(MeditationCompletionService.instance.completed.value, checkIn);
      expect(store.value.seedTokens, before + 1);
      await MeditationSleepService.instance.setTimer(15);
      await MeditationSleepService.instance.tick(
        now: MeditationSleepService.instance.deadline!,
      );
      expect(audio.playing.value, isNull);
      expect(MeditationSleepService.instance.owner, isNull);
      await media.stopAll();
      const forest = 'assets/audio/meditation/forestRest.mp3';
      await audio.toggle(forest);
      await audio.pause(forest);
      await audio.stopForNewSession();
      expect(audio.activeAsset, isNull);
      await MeditationCourseStore.instance.activate('first7');
      await audio.toggle(forest);
      final forestId = platform.calls.lastWhere((c) => c.method == 'resume').id;
      platform.eventStreamControllers[forestId]!.add(
        const AudioEvent(eventType: AudioEventType.complete),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await media.run(() async {});
      expect(MeditationCourseStore.instance.progress['first7'], 1);
      await media.stopAll();
      temp.deleteSync(recursive: true);
    },
  );
}
