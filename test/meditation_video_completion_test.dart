import 'package:flutter_app/services/meditation_sleep_service.dart';
import 'package:flutter_app/services/meditation_completion_service.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'package:audioplayers_platform_interface/audioplayers_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_app/widgets/meditation_video_player.dart';
import 'package:flutter_app/mongi/integration/mongi_garden_store.dart';
import 'support/fake_audioplayers_platform.dart';
import 'support/fake_global_audioplayers_platform.dart';

class VideoPlatform extends VideoPlayerPlatform {
  final events = StreamController<VideoEvent>();
  bool playing = false;
  @override
  Future<void> init() async {}
  @override
  Future<int?> create(DataSource source) async {
    events.add(
      VideoEvent(
        eventType: VideoEventType.initialized,
        duration: const Duration(seconds: 10),
        size: const Size(100, 100),
      ),
    );
    return 1;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int id) => events.stream;
  @override
  Future<void> dispose(int id) async {}
  @override
  Future<void> play(int id) async {
    playing = true;
  }

  @override
  Future<void> pause(int id) async {
    playing = false;
  }

  @override
  Future<void> setLooping(int id, bool looping) async {}
  @override
  Future<void> setVolume(int id, double volume) async {}
  @override
  Future<void> setPlaybackSpeed(int id, double speed) async {}
  @override
  Future<void> seekTo(int id, Duration position) async {}
  @override
  Future<Duration> getPosition(int id) async => Duration.zero;
  @override
  Widget buildView(int id) => const SizedBox();
}

void main() {
  testWidgets('fireplace loops without duplicate reward or check-in', (
    tester,
  ) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    AudioplayersPlatformInterface.instance = FakeAudioplayersPlatform();
    GlobalAudioplayersPlatformInterface.instance =
        FakeGlobalAudioplayersPlatform();
    final platform = VideoPlatform();
    VideoPlayerPlatform.instance = platform;
    const path = 'assets/video/meditation/fireplaceRest.mp4';
    await tester.runAsync(() => MongiGardenStore.instance.reload());
    final before = MongiGardenStore.instance.value.seedTokens;
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MeditationVideoPlayer(assetPath: path, accent: Colors.green),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('장작 이미지와 소리 재생'));
    await tester.pumpAndSettle();
    expect(platform.playing, true);
    MeditationSleepService.instance.setRepeat(true);
    expect(MongiGardenStore.instance.value.seedTokens, before);
    platform.events.add(VideoEvent(eventType: VideoEventType.completed));
    await tester.pumpAndSettle();
    for (
      var i = 0;
      i < 30 && MongiGardenStore.instance.value.seedTokens == before;
      i++
    ) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    expect(MongiGardenStore.instance.value.seedTokens, before + 1);
    expect(platform.playing, true);
    final completed = MeditationCompletionService.instance.completed.value;
    platform.events.add(VideoEvent(eventType: VideoEventType.completed));
    await tester.pumpAndSettle();
    expect(MongiGardenStore.instance.value.seedTokens, before + 1);
    expect(platform.playing, true);
    expect(MeditationCompletionService.instance.completed.value, completed);
    await tester.pumpWidget(const SizedBox());
    unawaited(platform.events.close());
    await tester.pumpAndSettle();
  });
}
