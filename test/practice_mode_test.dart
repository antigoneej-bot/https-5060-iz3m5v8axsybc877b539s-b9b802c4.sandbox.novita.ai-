// ignore_for_file: invalid_use_of_internal_member
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/flame.dart';
import 'package:flame/components.dart';
import 'package:flutter_app/mongi/game/runner_game.dart';
import 'package:flutter_app/mongi/models/emotion.dart';
import 'package:flutter_app/mongi/services/sound_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('practice keeps lives and pace, with no timeout or revive', () async {
    Flame.images.prefix = 'assets/mongi/images/';
    SoundManager.instance.setEnabled(false);
    var finished = 0, hits = 0, revives = 0;
    final game = RunnerGame(
      emotions: [Emotion.all.first],
      targetName: null,
      isPractice: true,
      stage: 1,
      targetEatenCount: 10,
      onStageComplete: (_, {earlyStop = false}) {
        finished++;
      },
      onRockHit: () {
        hits++;
      },
      onProgressChanged: (_) {},
      onLivesExhausted: (_, {required requiresAd}) async {
        revives++;
        return true;
      },
    );
    game.onGameResize(Vector2(390, 844));
    await game.load();
    game.mount();
    await game.ready();
    for (var i = 0; i < 8; i++) game.registerRockHit();
    expect(hits, 8);
    expect(game.lives, 3);
    expect(revives, 0);
    expect(game.speedMultiplier, .65);
    game.elapsedTime = 1000;
    game.update(.016);
    expect(game.secondsRemaining, -1);
    expect(finished, 0);
    expect(game.stageCompleted, false);
    game.onRemove();
  });
}
