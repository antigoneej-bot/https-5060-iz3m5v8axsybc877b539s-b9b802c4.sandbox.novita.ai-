import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'package:flutter_app/widgets/emotion_cat_video.dart';

class FakeVideos extends VideoPlayerPlatform {
  int created = 0;
  final playing = <int>{};
  @override
  Future<void> init() async {}
  @override
  Future<int?> create(DataSource source) async => ++created;
  @override
  Stream<VideoEvent> videoEventsFor(int id) => Stream.value(
    VideoEvent(
      eventType: VideoEventType.initialized,
      duration: const Duration(seconds: 5),
      size: const Size(100, 100),
    ),
  );
  @override
  Future<void> dispose(int id) async {
    playing.remove(id);
  }

  @override
  Future<void> play(int id) async {
    playing.add(id);
  }

  @override
  Future<void> pause(int id) async {
    playing.remove(id);
  }

  @override
  Future<void> setLooping(int id, bool value) async {}
  @override
  Future<void> setVolume(int id, double value) async {}
  @override
  Future<void> setPlaybackSpeed(int id, double value) async {}
  @override
  Future<void> seekTo(int id, Duration value) async {}
  @override
  Future<Duration> getPosition(int id) async => Duration.zero;
  @override
  Widget buildView(int id) => const ColoredBox(color: Colors.green);
}

void main() {
  testWidgets('only one card plays and backgrounding pauses it', (
    tester,
  ) async {
    final old = VideoPlayerPlatform.instance;
    final fake = FakeVideos();
    VideoPlayerPlatform.instance = fake;
    addTearDown(() => VideoPlayerPlatform.instance = old);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              for (final id in ['02', '03'])
                SizedBox(
                  width: 150,
                  height: 150,
                  child: EmotionCatVideo(
                    imageAsset: 'assets/cards36/cat_$id.png',
                    videoAsset: 'assets/cards36/videos/cat_${id}_loop.mp4',
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(fake.created, 0);
    await tester.tap(find.byTooltip('움직임 보기').first);
    await tester.pumpAndSettle();
    expect(fake.playing, {1});
    await tester.tap(find.byTooltip('움직임 보기').first);
    await tester.pumpAndSettle();
    expect(fake.playing, {2});
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(fake.playing, isEmpty);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(fake.playing, isEmpty);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
  testWidgets('scrolling a playing card out of view pauses it', (tester) async {
    final old = VideoPlayerPlatform.instance;
    final fake = FakeVideos();
    VideoPlayerPlatform.instance = fake;
    addTearDown(() => VideoPlayerPlatform.instance = old);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                  width: 150,
                  height: 150,
                  child: EmotionCatVideo(
                    imageAsset: 'assets/cards36/cat_02.png',
                    videoAsset: 'assets/cards36/videos/cat_02_loop.mp4',
                  ),
                ),
                SizedBox(height: 1500),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('움직임 보기'));
    await tester.pumpAndSettle();
    expect(fake.playing, {1});
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -600),
    );
    await tester.pumpAndSettle();
    expect(fake.playing, isEmpty);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
