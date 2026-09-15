import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../runner_game.dart';
import 'cat_player.dart';

/// 장애물 돌멩이.
/// - 큰 돌멩이: 항상 점프로 피해야 한다 (부딪히면 살짝 움찔 + 목숨 -1).
/// - 작은 돌멩이: 첫 단계부터, 화면을 미리 한 번 톡 쳐서 "주먹 준비" 상태를 만든 뒤
///   맞으면 손을 뻗어 부순다 (몽이가 알아서 부수는 게 아니라 플레이어가 타이밍을
///   맞춰야 한다). 준비 없이 맞으면 그냥 부딫혀서 목숨이 줄어든다.
/// 부딪혀도 게임오버는 없다 - 살짝 움찔하는 정도의 부드러운 페널티만 준다 (치유 게임 톤 유지).
class ObstacleRock extends SpriteComponent with CollisionCallbacks {
  final RunnerGame game;
  final bool isBig;
  final double baseSize;
  double speed;

  ObstacleRock({
    required this.game,
    this.isBig = false,
    this.baseSize = 72,
    this.speed = 250,
  }) : super(anchor: Anchor.bottomCenter);

  bool _handled = false;

  @override
  Future<void> onLoad() async {
    size = Vector2.all(baseSize);
    sprite = await Sprite.load(isBig ? 'rock_big.png' : 'rock.png');
    add(
      RectangleHitbox(
        size: Vector2(size.x * 0.6, size.y * 0.55),
        position: Vector2(size.x * 0.2, size.y * 0.35),
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    // 스테이지가 끝난 뒤(마무리 애니메이션 중)에는 남은 장애물도 멈춰서,
    // 아직 게임이 계속 진행 중인 것처럼 보이지 않게 한다.
    if (!game.isHolding || game.stageCompleted) return;
    position.x -= speed * game.powerSpeedBoost * dt;
    if (tryPunch()) return;
    if (position.x < -160) {
      if (!_handled) {
        // 충돌 없이(=주먹도, 실패도 아닌) 화면 밖으로 지나갔다는 건 점프로
        // 잘 피했다는 뜻이다. 콤보를 이어준다 (퍼펙트 판정은 주먹에만 적용).
        game.registerSuccess();
      }
      removeFromParent();
    }
  }

  /// 몸 충돌 전에 주먹 사거리에서 처리하고 중복 보상을 막는다.
  bool tryPunch() {
    if (_handled || !isMounted || !(!isBig) || !game.isInPunchReach(this)) return false;
    _handled = true;
    final perfect = game.punchReadyRemainingRatio >= 0.65;
    game.cat.punch();
    game.onRockPunched();
    game.consumePunchReady();
    game.registerSuccess(perfect: perfect);
    removeFromParent();
    return true;
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (_handled || other is! CatPlayer || !isMounted) return;
    if (!game.stageCompleted && !game.acceptsGameplayInput) return;
    _handled = true;

    // 스테이지가 이미 끝난 뒤(목숨 소진/시간 초과 등)에도 화면에 남아있던
    // 장애물이 뒤늦게 부딪히면서 몽이가 다시 움찔하거나 목숨이 깎이는 것처럼
    // 보이는 버그 방지 - 마무리 애니메이션 중에는 판정 없이 그냥 사라진다.
    if (game.stageCompleted) {
      removeFromParent();
      return;
    }

    if (game.isPoweredUp) {
      // 파워빛볼로 최강 상태일 때는 크기와 무관하게 그대로 부수며 지나간다.
      other.smashThrough();
      game.registerPowerSmash(position.clone());
      removeFromParent();
      return;
    }

    if (!isBig && game.canPunchSmallRocks && game.punchReady) {
      // 화면을 한 번 톡 쳐서 타이밍을 맞췄을 때만 손을 뻗어 부순다 (패널티 없음).
      // 준비 창이 많이 남아있을수록(=거의 즉시 부딫힘) 반응이 빨랐다는 뜻이라
      // "완벽한 타이밍"으로 판정해 보너스 피드백을 준다.
      final perfect = game.punchReadyRemainingRatio >= 0.65;
      other.punch();
      game.onRockPunched();
      game.consumePunchReady();
      game.registerSuccess(perfect: perfect);
    } else {
      // 타이밍을 놓쳤거나 큰 돌멩이 - "아얏!" 하고 목숨이 하나 줄어든다.
      other.stumble();
      game.registerRockHit();
    }
    removeFromParent();
  }
}
