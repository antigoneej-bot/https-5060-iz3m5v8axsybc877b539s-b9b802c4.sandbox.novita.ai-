import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:audioplayers_platform_interface/audioplayers_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/services/garden_sound_timer.dart';
import 'package:flutter_app/services/sound_service.dart';
import 'package:flutter_app/services/media_coordinator.dart';
import 'package:flutter_app/mongi/services/sound_manager.dart';
import 'support/fake_audioplayers_platform.dart';
import 'support/fake_global_audioplayers_platform.dart';

class _CachedAssets extends AudioCache {
  @override
  Future<String> loadPath(String name) async => '/test-assets/$name';
}
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeAudioplayersPlatform platform;
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    AudioCache.instance = _CachedAssets();
    GlobalAudioplayersPlatformInterface.instance = FakeGlobalAudioplayersPlatform();
    platform = FakeAudioplayersPlatform(); AudioplayersPlatformInterface.instance = platform;
    await SoundService().init(); await pumpEventQueue();
  });
  tearDown(() async {
    GardenSoundTimer.instance.setMinutes(null);
    SoundService().bgmEnabled = false;
    SoundManager.instance.ambientRequested = false;
    await GardenSoundTimer.instance.resumeSound();
    await SoundManager.instance.stopEverything();
  });
  test('deadline stops current media exactly once without starting music again', () async {
    final timer = GardenSoundTimer.instance, owner = Object();
    var stops = 0;
    await MediaCoordinator.instance.run(() => MediaCoordinator.instance.claim(owner, () async { stops++; }));
    timer.setMinutes(5); final end = timer.deadline!;
    await timer.tick(now: end.subtract(const Duration(seconds: 1))); expect(stops, 0);
    await timer.tick(now: end); expect(stops, 1); expect(timer.stopped, isTrue);
    expect(SoundService().sleepStopped, isTrue); expect(SoundManager.instance.sleepStopped, isTrue);
    final before = platform.calls.where((c) => c.method == 'resume').length;
    await SoundService().tryStartBgm(); await SoundManager.instance.startAmbientNature();
    expect(platform.calls.where((c) => c.method == 'resume').length, before);
    await timer.tick(now: end.add(const Duration(minutes: 1))); expect(stops, 1);
  });
  test('cancelled deadline does not stop media; nature settings persist independently', () async {
    final timer = GardenSoundTimer.instance;
    timer.setMinutes(15); final old = timer.deadline!; timer.setMinutes(null);
    await timer.tick(now: old); expect(timer.stopped, isFalse);
    final manager = SoundManager.instance;
    manager.musicEnabled = false;
    await manager.setNature(enabled: true, birds: .25, water: .45);
    await manager.loadNatureSettings();
    expect(manager.natureEnabled, isTrue); expect(manager.birdsVolume, .25); expect(manager.waterVolume, .45);
    expect(manager.musicEnabled, isFalse);
  });
}
