import 'dart:math' as math;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../runner_game.dart';
import 'cat_player.dart';

/// 돌멩이 외에 등장하는 새로운 애니메이션 장애물 3종.
/// - [leafBall]: 통통 구르며 회전하는 낙엽뭉치 - 작은 돌멩이와 똑같이 화면을
///   톡 쳐서 타이밍을 맞추면 손을 뻗어 부술 수 있다(패널티 없음).
/// - [sparrow]: 머리 높이로 휙 날아드는 참새 - 몬스터와 달리 먹는 대상이
///   아니라 반드시 점프로 피해야 하는 위험 요소다(부딫히면 목숨 -1).
/// - [frog]: 길 위에서 통통 뛰어오르는 개구리 - 큰 돌멩이처럼 항상 점프로만
///   피할 수 있다(주먹으로는 부술 수 없음).
/// 셋 다 정적 그림이 아니라 여러 프레임을 순환하는 [SpriteAnimation]으로
/// 살아 움직이는 느낌을 준다(회전/날갯짓/폴짝 뛰는 동작).
enum ObstacleKind { leafBall, sparrow, frog }

class AnimatedObstacle extends SpriteAnimationComponent
    with CollisionCallbacks {
  final RunnerGame game;
  final ObstacleKind kind;
  final double baseSize;
  double speed;

  AnimatedObstacle({
    required this.game,
    required this.kind,
    this.baseSize = 72,
    this.speed = 230,
  }) : super(anchor: Anchor.bottomCenter);

  bool _handled = false;
  double _bobPhase = 0;
  double _baseY = 0;

  bool get _isFloating => kind == ObstacleKind.sparrow;
  bool get _isPunchable => kind == ObstacleKind.leafBall;

  @override
  Future<void> onLoad() async {
    size = Vector2.all(baseSize);
    _baseY = position.y;
    animation = await _buildAnimation(kind);
    add(
      RectangleHitbox(
        size: Vector2(size.x * 0.6, size.y * 0.55),
        position: Vector2(size.x * 0.2, size.y * 0.35),
      ),
    );
  }

  static Future<SpriteAnimation> _buildAnimation(ObstacleKind kind) async {
    switch (kind) {
      case ObstacleKind.leafBall:
        // 낙엽뭉치가 통통 굴러오며 계속 회전하는 3프레임 루프.
        final frames = await Future.wait([
          Sprite.load('obstacle_leafball_0.png'),
          Sprite.load('obstacle_leafball_1.png'),
          Sprite.load('obstacle_leafball_2.png'),
        ]);
        return SpriteAnimation.spriteList(frames, stepTime: 0.09, loop: true);
      case ObstacleKind.sparrow:
        // 날개를 위-중간-아래로 오가며 자연스럽게 퍼덕이는 4프레임 루프.
        final mid = await Sprite.load('obstacle_sparrow_0.png');
        final up = await Sprite.load('obstacle_sparrow_1.png');
        final down = await Sprite.load('obstacle_sparrow_2.png');
        return SpriteAnimation.spriteList(
          [up, mid, down, mid],
          stepTime: 0.1,
          loop: true,
        );
      case ObstacleKind.frog:
        // 웅크렸다가(스쿼시) 힘차게 뛰어오른 뒤(스트레치) 잠깐 쉬는(레스트)
        // 세 박자 홉 사이클 - 프레임마다 다른 지속시간을 줘서 통통 튀는
        // 리듬감을 살린다.
        final rest = await Sprite.load('obstacle_frog_0.png');
        final jump = await Sprite.load('obstacle_frog_1.png');
        final squash = await Sprite.load('obstacle_frog_2.png');
        return SpriteAnimation([
          SpriteAnimationFrame(squash, 0.16),
          SpriteAnimationFrame(jump, 0.14),
          SpriteAnimationFrame(rest, 0.34),
        ], loop: true);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    // 스테이지가 끝난 뒤(마무리 애니메이션 중)에는 남은 장애물도 멈춘다.
    if (!game.isHolding || game.stageCompleted) return;
    position.x -= speed * game.powerSpeedBoost * dt;
    if (tryPunch()) return;
    if (_isFloating) {
      // 참새는 완전히 고정된 높이가 아니라 살짝 위아래로 흔들리며 날아온다.
      _bobPhase += dt * 3.0;
      position.y = _baseY + math.sin(_bobPhase) * 7;
    }
    if (position.x < -160) {
      if (!_handled) {
        // 충돌 없이 화면 밖으로 지나갔다는 건 점프(또는 회피)로 잘 처리했다는 뜻.
        game.registerSuccess();
      }
      removeFromParent();
    }
  }

  /// 몸 충돌 전에 주먹 사거리에서 처리하고 중복 보상을 막는다.
  bool tryPunch() {
    if (_handled || !isMounted || !(_isPunchable) || !game.isInPunchReach(this)) return false;
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

    // 스테이지가 이미 끝난 뒤에도 화면에 남아있던 장애물이 뒤늦게 부딪히며
    // 몽이가 다시 움찔하거나 목숨이 깎이는 것처럼 보이는 버그 방지.
    if (game.stageCompleted) {
      removeFromParent();
      return;
    }

    if (game.isPoweredUp) {
      // 파워빛볼로 최강 상태일 때는 참새/개구리처럼 원래 점프로만 피하던
      // 장애물도 그대로 부수며 지나간다.
      other.smashThrough();
      game.registerPowerSmash(position.clone());
      removeFromParent();
      return;
    }

    if (_isPunchable && game.canPunchSmallRocks && game.punchReady) {
      // 화면을 한 번 톡 쳐서 타이밍을 맞췄을 때만 손을 뻗어 부순다(패널티 없음).
      final perfect = game.punchReadyRemainingRatio >= 0.65;
      other.punch();
      game.onRockPunched();
      game.consumePunchReady();
      game.registerSuccess(perfect: perfect);
    } else {
      // 참새/개구리는 애초에 주먹으로 부술 수 없고, 낙엽뭉치도 타이밍을
      // 놓쳤으면 그냥 "아얏!" 하고 목숨이 하나 줄어든다.
      other.stumble();
      game.registerRockHit();
    }
    removeFromParent();
  }
}
