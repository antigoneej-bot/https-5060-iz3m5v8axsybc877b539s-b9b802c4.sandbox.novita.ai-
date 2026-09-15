// Flame lifecycle is driven directly for deterministic engine tests.
// ignore_for_file: invalid_use_of_internal_member
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/flame.dart';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter_app/mongi/game/runner_game.dart';
import 'package:flutter_app/mongi/game/components/obstacle_rock.dart';
import 'package:flutter_app/mongi/game/components/emotion_monster_component.dart';
import 'package:flutter_app/mongi/game/components/obstacle_creature.dart';
import 'package:flutter_app/mongi/models/emotion.dart';
import 'package:flutter_app/mongi/services/sound_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('stage 1 and later: punch reach, misses, jumping, completion', () async {
    Flame.images.prefix = 'assets/mongi/images/';
    SoundManager.instance.setEnabled(false);
    for (final stage in [1, 2, 18]) {
      var hits = 0, breaks = 0;
      final game = RunnerGame(emotions: [Emotion.all.first], targetName: null,
        stage: stage, onStageComplete: (_, {earlyStop = false}) {},
        onRockHit: () => hits++, onRockPunched: () => breaks++,
        onProgressChanged: (_) {});
      game.onGameResize(Vector2(390,844));
      await game.load();
      game.mount();
      await game.ready();
      Future<void> mount(PositionComponent obstacle) async {
        await game.add(obstacle);
        await game.ready();
      }
      double front() => game.cat.children.whereType<RectangleHitbox>().first.toAbsoluteRect().right;
      // Body is still separated from the obstacle, but the fist can reach it.
      final rock = ObstacleRock(game:game,speed:0)..position=Vector2(front()+35,game.groundY);
      await mount(rock);
      game.punchAction();
      expect(rock.isRemoving, isTrue, reason:'stage $stage small rock');
      expect(breaks,1); expect(hits,0); expect(game.punchReady,isFalse);
      expect(rock.tryPunch(),isFalse); expect(breaks,1);
      final leaf = AnimatedObstacle(game:game,kind:ObstacleKind.leafBall,speed:0)
        ..position=Vector2(front()+35,game.groundY);
      await mount(leaf); game.punchAction();
      expect(leaf.isRemoving,isTrue,reason:'stage $stage leaf'); expect(breaks,2);
      final big = ObstacleRock(game:game,isBig:true,speed:0)..position=Vector2(front()+35,game.groundY);
      await mount(big); game.punchAction(); expect(big.isRemoving,isFalse);
      big.onCollisionStart({},game.cat); expect(hits,1); expect(breaks,2);
      final far = ObstacleRock(game:game,speed:0)..position=Vector2(front()+250,game.groundY);
      await mount(far); game.punchAction(); expect(far.isRemoving,isFalse);
      game.consumePunchReady();
      far.position.x=front()+35; expect(far.tryPunch(),isFalse);
      // No input: contact damages; one obstacle cannot charge two hits.
      far.onCollisionStart({},game.cat); far.onCollisionStart({},game.cat);
      expect(hits,2);
      game.punchAction(); game.jump();
      game.cat.update(0.05);
      expect(game.cat.position.y,lessThan(game.groundY));
      final y=game.cat.position.y;
      game.cat.update(0.05); expect(game.cat.position.y,lessThan(y));
      final groundLeaf=AnimatedObstacle(game:game,kind:ObstacleKind.leafBall,speed:0)
        ..position=Vector2(front()+35,game.groundY);
      await mount(groundLeaf); game.cat.position.y=game.groundY-250;
      game.punchAction(); expect(groundLeaf.isRemoving,isFalse);
      game.setHolding(false); game.consumePunchReady(); game.punchAction();
      expect(game.punchReady,isFalse);
      game.onRemove();
    }
  });
  for (final fps in [30, 60, 120]) {
    test('moving leaf reaches armed fist at $fps fps; emotions and clear are single-use', () async {
      Flame.images.prefix = 'assets/mongi/images/';
      SoundManager.instance.setEnabled(false);
      var breaks=0, hits=0, completed=0;
      final negative=Emotion.all.first;
      final positive=Emotion.all.firstWhere((e)=>e.isPositive);
      final game=RunnerGame(emotions:[negative,positive],targetName:null,
        targetEatenCount:2,onStageComplete:(_, {earlyStop=false}) {completed++;},
        onRockHit:()=>hits++,onRockPunched:()=>breaks++,onProgressChanged:(_){});
      game.onGameResize(Vector2(390,844)); await game.load(); game.mount(); await game.ready();
      final leaf=AnimatedObstacle(game:game,kind:ObstacleKind.leafBall,speed:250)
        ..position=Vector2(320,game.groundY);
      await game.add(leaf); await game.ready(); game.punchAction();
      for(var n=0;n<fps*0.8 && !leaf.isRemoving;n++) {game.update(1/fps); await game.ready();}
      expect(breaks,1); expect(hits,0);
      game.punchAction(); game.update(0.9); expect(game.punchReady,isFalse);
      game.pauseEngine(); game.punchAction(); expect(game.punchReady,isFalse); game.resumeEngine();
      game.activatePowerMode();
      final big=ObstacleRock(game:game,isBig:true,speed:0)..position=game.cat.position.clone();
      await game.add(big); await game.ready(); big.onCollisionStart({},game.cat);
      expect(big.isRemoving,isTrue); expect(hits,0);
      for(final emotion in [negative,positive]) {
        final monster=EmotionMonsterComponent(game:game,emotion:emotion,speed:0)
          ..position=game.cat.position.clone();
        await game.add(monster); await game.ready();
        monster.onCollisionStart({},game.cat); monster.onCollisionStart({},game.cat);
        expect(game.eatenByType[emotion.type],1);
      }
      expect(game.stageCompleted,isTrue); expect(game.eatenCount,2);
      final lives=game.lives; game.registerRockHit(); expect(game.lives,lives);
      game.consumePunchReady(); game.punchAction(); expect(game.punchReady,isFalse);
      game.update(2.2); game.update(2.2); expect(completed,1);
      game.onRemove();
    });
  }

  test('mixed jump holds, cancellation and pause do not leave stuck input', () async {
    Flame.images.prefix = 'assets/mongi/images/';
    SoundManager.instance.setEnabled(false);
    final game = RunnerGame(emotions: [Emotion.all.first], targetName: null,
      onStageComplete: (_, {earlyStop = false}) {}, onRockHit: () {},
      onRockPunched: () {}, onProgressChanged: (_) {});
    game.onGameResize(Vector2(390,844));
    await game.load(); game.mount(); await game.ready();
    const finger1 = ('pointer', 1), finger2 = ('pointer', 2);
    const space = ('key', 32), up = ('key', 38);
    game.pressJumpInput(finger1);
    game.pressJumpInput(finger2);
    game.pressJumpInput(space);
    game.pressJumpInput(up);
    game.releaseJumpInput(finger2);
    game.releaseJumpInput(space);
    game.releaseJumpInput(('pointer', 999)); // unrelated cancel
    var velocity = game.cat.velocityY;
    game.cat.update(0.01);
    expect(game.cat.velocityY - velocity, closeTo(1700 * 0.45 * 0.01, 0.001));
    game.releaseJumpInput(finger1);
    velocity = game.cat.velocityY;
    game.cat.update(0.01); // up still held
    expect(game.cat.velocityY - velocity, closeTo(1700 * 0.45 * 0.01, 0.001));
    game.releaseJumpInput(up);
    velocity = game.cat.velocityY;
    game.cat.update(0.01);
    expect(game.cat.velocityY - velocity, closeTo(1700 * 0.01, 0.001));

    game.pressJumpInput(finger1);
    game.punchAction();
    game.pauseEngine();
    expect(game.punchReady, isFalse);
    game.pressJumpInput(finger2); // paused presses must not be queued
    game.resumeEngine();
    velocity = game.cat.velocityY;
    game.cat.update(0.01);
    expect(game.cat.velocityY - velocity, closeTo(1700 * 0.01, 0.001));

    game.pressJumpInput(space);
    game.clearGameplayInput(); // focus loss / cancelled interaction
    velocity = game.cat.velocityY;
    game.cat.update(0.01);
    expect(game.cat.velocityY - velocity, closeTo(1700 * 0.01, 0.001));

    final positive = Emotion.all.firstWhere((e) => e.isPositive);
    game.cat.receiveLight(positive.color, 0.5, positive.type);
    expect(game.cat.isGrounded, isFalse);
    expect(game.cat.velocityY, velocity + 17);
    game.cat.eat(Emotion.all.first.type);
    expect(game.cat.isGrounded, isFalse);
    game.onRemove();
  });

}
