import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:audioplayers_platform_interface/audioplayers_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/services/sound_service.dart';
import 'package:flutter_app/services/media_coordinator.dart';
import 'package:flutter_app/services/app_lock_service.dart';
import 'package:flutter_app/widgets/app_lock_gate.dart';
import 'package:flutter_app/widgets/background_music_gate.dart';
import 'package:flutter_app/widgets/sound_panel.dart';
import 'support/fake_audioplayers_platform.dart';
import 'support/fake_global_audioplayers_platform.dart';

class _CachedAssets extends AudioCache {
  @override
  Future<String> loadPath(String fileName) async => '/test-assets/$fileName';
}

class _AudioPlatform extends FakeAudioplayersPlatform {
  // Model the bundled Android player's independent, exclusive focus requests.
  final contexts = <String, AudioContext>{};
  final nativePlaying = <String>{};
  @override
  Future<void> setAudioContext(String id, AudioContext context) async {
    contexts[id] = context;
    await super.setAudioContext(id, context);
  }

  @override
  Future<void> resume(String id) async {
    final focus = contexts[id]?.android.audioFocus ?? AndroidAudioFocus.gain;
    if (focus == AndroidAudioFocus.gain) nativePlaying.clear();
    nativePlaying.add(id);
    await super.resume(id);
  }

  @override
  Future<void> pause(String id) async {
    nativePlaying.remove(id);
    await super.pause(id);
  }

  @override
  Future<void> stop(String id) async {
    nativePlaying.remove(id);
    await super.stop(id);
  }

  Completer<void>? preparing;
  bool failSource = false;
  @override
  Future<void> setSourceUrl(
    String playerId,
    String url, {
    bool? isLocal,
    String? mimeType,
  }) async {
    if (failSource) {
      final error = PlatformException(code: 'decode-failed');
      eventStreamControllers[playerId]!.addError(error);
      throw error;
    }
    await preparing?.future;
    await super.setSourceUrl(
      playerId,
      url,
      isLocal: isLocal,
      mimeType: mimeType,
    );
  }
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  late _AudioPlatform platform;
  late SoundService sound;
  int resumes() => platform.calls.where((c) => c.method == 'resume').length;
  int sources() =>
      platform.calls.where((c) => c.method == 'setSourceUrl').length;
  setUpAll(() async {
    AudioCache.instance = _CachedAssets();
    GlobalAudioplayersPlatformInterface.instance =
        FakeGlobalAudioplayersPlatform();
  });
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'bgm_enabled': true,
      'bgm_volume': 0.24,
    });
    platform = _AudioPlatform();
    AudioplayersPlatformInterface.instance = platform;
    sound = SoundService.forTesting();
    await pumpEventQueue();
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });
  tearDown(() async {
    await sound.stopAll();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      AppLockService.channel,
      null,
    );
  });

  test(
    'startup prepares loop and saved volume without playing before visible',
    () async {
      await sound.init();
      expect(resumes(), 0);
      await sound.setAppAudible(true);
      expect(sources(), 1);
      expect(
        platform.calls.any(
          (c) => c.method == 'setReleaseMode' && c.value == ReleaseMode.loop,
        ),
        true,
      );
      expect(
        platform.calls.any((c) => c.method == 'setVolume' && c.value == 0.24),
        true,
      );
      await sound.setAppAudible(true);
      expect(resumes(), 1);
      await Future.wait(List.generate(8, (_) => sound.tryStartBgm()));
      expect(resumes(), 1); // Taps never restart the song or stack playback.
      expect(sources(), 1);
    },
  );

  test('cat effects do not steal the native BGM audio focus', () async {
    await sound.init();
    await sound.setAppAudible(true);
    final bgm = platform.nativePlaying.single;
    for (final effect in [
      sound.playMeow,
      sound.playPurr,
      sound.playChime,
      sound.playShuffle,
      sound.playFlip,
      sound.playBubblePop,
      sound.playGardenComplete,
    ]) {
      await effect();
      expect(platform.nativePlaying, contains(bgm));
    }
  });

  test('explicit retry recovers native pause hidden from Dart state', () async {
    await sound.init();
    await sound.setAppAudible(true);
    final bgm = platform.nativePlaying.single;
    platform.nativePlaying
        .clear(); // Android focus loss does not emit Dart state.
    await sound.tryStartBgm();
    expect(
      platform.nativePlaying,
      isEmpty,
    ); // Ordinary taps do not fight other apps.
    expect(await sound.retryBgm(), isTrue);
    expect(platform.nativePlaying, contains(bgm));
    expect(sources(), 2);
    expect(platform.calls.where((c) => c.method == 'release'), hasLength(1));
  });

  test(
    'retry respects OFF, zero volume, lock and meditation ownership',
    () async {
      await sound.init();
      await sound.setBgmEnabled(false);
      expect(await sound.retryBgm(), isFalse);
      await sound.setBgmVolume(0);
      await sound.setBgmEnabled(true);
      expect(await sound.retryBgm(), isFalse);
      expect(sound.bgmVolume, 0); // Never override deliberate silence.
      await sound.setBgmVolume(0.4);
      await sound.setAppAudible(false);
      expect(await sound.retryBgm(), isFalse);
      await sound.setAppAudible(true);
      sound.narrationPlaying = true;
      expect(await sound.retryBgm(), isFalse);
      sound.narrationPlaying = false;
      platform.nativePlaying.clear();
      await sound.setBgmEnabled(
        true,
      ); // Explicitly enabling an already-on setting recovers too.
      expect(platform.nativePlaying, isNotEmpty);
    },
  );

  test('effect still loading when app hides does not play later', () async {
    platform.preparing = Completer<void>();
    final effect = sound.playMeow();
    await pumpEventQueue();
    final hiding = sound.setAppAudible(false);
    platform.preparing!.complete();
    await Future.wait([effect, hiding]);
    expect(resumes(), 0);
  });

  test('saved OFF remains silent on launch, resume and touches', () async {
    SharedPreferences.setMockInitialValues({'bgm_enabled': false});
    await sound.init();
    await sound.setAppAudible(true);
    await sound.tryStartBgm();
    await sound.setAppAudible(false);
    await sound.setAppAudible(true);
    expect(resumes(), 0);
    expect(sources(), 0);
  });

  test(
    'background pauses and foreground resumes without reloading the song',
    () async {
      await sound.init();
      await sound.setAppAudible(true);
      await sound.setAppAudible(false);
      expect(platform.calls.where((c) => c.method == 'pause'), isNotEmpty);
      await sound.tryStartBgm();
      expect(resumes(), 1);
      await sound.setAppAudible(true);
      expect(resumes(), 2);
      expect(sources(), 1);
      expect(platform.calls.where((c) => c.method == 'seek'), isEmpty);
    },
  );

  test('decoder completing after OFF cannot start unwanted music', () async {
    sound.bgmEnabled = true;
    platform.preparing = Completer<void>();
    final starting = sound.tryStartBgm();
    await pumpEventQueue();
    final turningOff = sound.setBgmEnabled(false);
    platform.preparing!.complete();
    await starting;
    await turningOff;
    expect(resumes(), 0);
    expect(sound.bgmEnabled, false);
  });

  test('decoder completing after backgrounding remains silent', () async {
    sound.bgmEnabled = true;
    platform.preparing = Completer<void>();
    final starting = sound.tryStartBgm();
    await pumpEventQueue();
    final hiding = sound.setAppAudible(false);
    platform.preparing!.complete();
    await starting;
    await hiding;
    expect(resumes(), 0);
    await sound.setAppAudible(true);
    expect(resumes(), 1);
  });

  test(
    'transient preparation failure does not prevent the next start',
    () async {
      platform.failSource = true;
      await sound.init(); // Audio failure never fails the app bootstrap.
      await sound.setAppAudible(true);
      expect(resumes(), 0);
      platform.failSource = false;
      await sound.tryStartBgm();
      expect(resumes(), 1);
    },
  );

  test(
    'media release restores music, but background and exit stay silent',
    () async {
      await sound.init();
      await sound.setAppAudible(true);
      final media = MediaCoordinator(sound: sound);
      final owner = Object();
      await media.run(() => media.claim(owner, () async {}));
      await sound.tryStartBgm();
      expect(resumes(), 1);
      media.release(Object()); // A stale player cannot clear the active owner.
      expect(sound.narrationPlaying, true);
      media.release(owner);
      await sound.tryStartBgm();
      expect(resumes(), 2);
      await media.run(() => media.claim(owner, () async {}));
      await sound.setAppAudible(false);
      media.release(owner);
      await sound.tryStartBgm();
      expect(resumes(), 2);
      sound.gardenSuspended = true;
      await sound.setAppAudible(true);
      expect(resumes(), 2);
      sound.gardenSuspended = false;
      await sound.tryStartBgm();
      expect(resumes(), 3);
    },
  );

  Future<void> flush(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 30));
      await tester.runAsync(() => pumpEventQueue());
    }
  }

  for (final width in [360.0, 390.0]) {
    testWidgets('sound sheet is tappable at ${width}px and large text', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 800);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.runAsync(sound.init);
      await tester.pumpWidget(
        MaterialApp(
          builder: (_, child) => MediaQuery(
            data: MediaQueryData(
              size: Size(width, 800),
              textScaler: const TextScaler.linear(2),
            ),
            child: BackgroundMusicGate(sound: sound, child: child!),
          ),
          home: Scaffold(
            appBar: AppBar(actions: [SoundToggleButton(sound: sound)]),
          ),
        ),
      );
      await tester.tap(find.byTooltip('소리 설정'));
      await flush(tester);
      expect(find.text('배경 음악'), findsOneWidget);
      await tester.tap(find.text('배경 음악')); // real hit test, including label
      await flush(tester);
      expect(sound.bgmEnabled, isFalse);
      expect(find.text('배경 음악이 꺼져 있어요.'), findsOneWidget);
      await tester.tap(find.text('배경 음악'));
      await flush(tester);
      expect(sound.bgmEnabled, isTrue);
      final slider = find.byType(Slider);
      await tester.ensureVisible(slider);
      await tester.tapAt(tester.getCenter(slider) + const Offset(60, 0));
      await flush(tester);
      expect(sound.bgmVolume, greaterThan(0.5));
      await tester.ensureVisible(find.text('음악 다시 재생'));
      final before = sources();
      await tester.tap(find.text('음악 다시 재생'));
      await flush(tester);
      expect(sources(), before + 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await flush(tester);
    });
  }

  testWidgets(
    'native launch plays without tap; route changes keep one player',
    (tester) async {
      await tester.runAsync(sound.init);
      await tester.pumpWidget(
        MaterialApp(
          builder: (_, child) =>
              BackgroundMusicGate(sound: sound, child: child!),
          home: Builder(
            builder: (context) => Scaffold(
              body: FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const Scaffold(body: Text('NEXT')),
                  ),
                ),
                child: const Text('OPEN'),
              ),
            ),
          ),
        ),
      );
      await flush(tester);
      expect(resumes(), 1); // No user input has been sent.
      await tester.tap(find.text('OPEN'));
      await flush(tester);
      expect(find.text('NEXT'), findsOneWidget);
      expect(resumes(), 1);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await flush(tester);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await flush(tester);
      expect(resumes(), 2);
      await tester.pumpWidget(const SizedBox());
      await flush(tester);
    },
  );

  testWidgets(
    'privacy lock blocks automatic music until unlock including return',
    (tester) async {
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        AppLockService.channel,
        (call) async => true,
      );
      await tester.runAsync(sound.init);
      await tester.pumpWidget(
        MaterialApp(
          builder: (_, child) => AppLockGate(
            child: BackgroundMusicGate(sound: sound, child: child!),
          ),
          home: const Scaffold(body: Text('GARDEN')),
        ),
      );
      await flush(tester);
      expect(resumes(), 0);
      await tester.tap(find.text('휴대전화 잠금으로 열기'));
      await flush(tester);
      expect(resumes(), 1);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await flush(tester);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await flush(tester);
      expect(resumes(), 1);
      expect(find.text('휴대전화 잠금으로 열기'), findsOneWidget);
      await tester.tap(find.text('휴대전화 잠금으로 열기'));
      await flush(tester);
      expect(resumes(), 2);
      await tester.pumpWidget(const SizedBox());
      await flush(tester);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );
}
