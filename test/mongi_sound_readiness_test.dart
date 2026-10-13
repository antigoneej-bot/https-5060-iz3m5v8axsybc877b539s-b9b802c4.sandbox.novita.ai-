import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:audioplayers_platform_interface/audioplayers_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/mongi/services/sound_manager.dart';
import 'support/fake_audioplayers_platform.dart';
import 'support/fake_global_audioplayers_platform.dart';

class DelayedVolumePlatform extends FakeAudioplayersPlatform {
  String? delayedId;
  Completer<void> entered = Completer<void>();
  Completer<void> releaseVolume = Completer<void>();
  String? delayedResumeId;
  Completer<void> resumeEntered = Completer<void>();
  Completer<void> releaseResume = Completer<void>();

  void delay(String id) {
    delayedId = id;
    entered = Completer<void>();
    releaseVolume = Completer<void>();
  }

  void delayResume(String id) {
    delayedId = null;
    delayedResumeId = id;
    resumeEntered = Completer<void>();
    releaseResume = Completer<void>();
  }

  @override
  Future<void> resume(String playerId) async {
    if (playerId == delayedResumeId) {
      if (!resumeEntered.isCompleted) resumeEntered.complete();
      await releaseResume.future;
    }
    await super.resume(playerId);
  }

  @override
  Future<void> setVolume(String playerId, double volume) async {
    if (playerId == delayedId) {
      if (!entered.isCompleted) entered.complete();
      await releaseVolume.future;
    }
    await super.setVolume(playerId, volume);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'readiness stays silent and delayed sound initialization cannot outlive stop',
    () async {
      final platform = DelayedVolumePlatform();
      AudioplayersPlatformInterface.instance = platform;
      GlobalAudioplayersPlatformInterface.instance =
          FakeGlobalAudioplayersPlatform();
      final sound = SoundManager.instance;
      final temp = await Directory.systemTemp.createTemp('mongi-audio-race-');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (_) async => temp.path,
          );
      sound.setEnabled(true);
      sound.musicEnabled = true;
      try {
        await sound.pauseForUser();
        await sound.startBgm();
        await sound.startAmbientNature();
        expect(platform.calls.where((c) => c.method == 'create'), isEmpty);
        await sound.releaseUserPause(resume: false);

        platform.delay('bgm_player');
        final bgm = sound.startBgm();
        await platform.entered.future.timeout(const Duration(seconds: 2));
        await sound.stopBgm();
        platform.releaseVolume.complete();
        await bgm;
        expect(platform.calls.where((c) => c.method == 'resume'), isEmpty);

        platform.delay('ambient_birds_player');
        final ambient = sound.startAmbientNature();
        await platform.entered.future.timeout(const Duration(seconds: 2));
        await sound.stopAmbientNature();
        platform.releaseVolume.complete();
        await ambient;
        expect(platform.calls.where((c) => c.method == 'resume'), isEmpty);

        // General SFX used to ignore pause/stop between setVolume and play.
        platform.delay('sfx_jump_player');
        final jump = sound.playJump();
        await platform.entered.future.timeout(const Duration(seconds: 2));
        await sound.pauseForUser();
        platform.releaseVolume.complete();
        await jump;
        expect(
          platform.calls.where(
            (c) => c.id == 'sfx_jump_player' && c.method == 'resume',
          ),
          isEmpty,
        );
        await sound.releaseUserPause();

        platform.delay('sfx_rock_player');
        final rock = sound.playRockBreak();
        await platform.entered.future.timeout(const Duration(seconds: 2));
        await sound.pauseAllForBackground();
        platform.releaseVolume.complete();
        await rock;
        expect(
          platform.calls.where(
            (c) => c.id == 'sfx_rock_player' && c.method == 'resume',
          ),
          isEmpty,
        );
        await sound.resumeAllFromBackground();

        // Even stop followed immediately by resume must cancel the old footstep.
        platform.delay('sfx_footstep_player');
        final footstep = sound.playFootstep();
        await platform.entered.future.timeout(const Duration(seconds: 2));
        await sound.stopFootstep();
        sound.resumeFootstep();
        platform.releaseVolume.complete();
        await footstep;
        expect(
          platform.calls.where(
            (c) => c.id == 'sfx_footstep_player' && c.method == 'resume',
          ),
          isEmpty,
        );

        // A native play can finish after stop. Its final stop must run before
        // a newer effect on the same player, otherwise that newer sound is cut.
        platform.delayResume('sfx_jump_player');
        final oldJump = sound.playJump();
        await platform.resumeEntered.future.timeout(const Duration(seconds: 2));
        await sound.stopEverything();
        final newJump = sound.playJump();
        platform.releaseResume.complete();
        await Future.wait([oldJump, newJump]);
        final jumpCalls = platform.calls
            .where((c) => c.id == 'sfx_jump_player')
            .toList();
        expect(jumpCalls.last.method, 'resume');
        expect(jumpCalls.where((c) => c.method == 'resume').length, 2);
      } finally {
        if (!platform.releaseVolume.isCompleted)
          platform.releaseVolume.complete();
        if (!platform.releaseResume.isCompleted)
          platform.releaseResume.complete();
        await sound.stopEverything();
        await sound.releaseUserPause(resume: false);
        await sound.dispose();
        await temp.delete(recursive: true);
      }
    },
  );
}
