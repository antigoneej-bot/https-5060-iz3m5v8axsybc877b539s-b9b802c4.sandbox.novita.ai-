import '../../../theme.dart' show appFontFallback;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import '../runner_game.dart';
import 'cat_player.dart';

/// "파워빛볼" - 한 판에 한두 번(엔드리스 모드는 계속) 드물게 등장하는 황금빛
/// 구슬. 몽이가 닿으면 [RunnerGame.activatePowerMode]가 호출되어 잠깐 동안
/// 최강 상태가 되고, 그동안은 돌멩이/장애물을 피하지 않고 그대로 몸으로
/// 부수며 시원하게 질주할 수 있다. 일반 보너스([BonusItem])보다 훨씬
/// 드물게 등장하는 특별한 순간이라, 더 화려한 회전+펄스 효과를 준다.
class PowerOrb extends PositionComponent with CollisionCallbacks {
  final RunnerGame game;
  final double speed;

  PowerOrb({required this.game, this.speed = 230})
    : super(anchor: Anchor.bottomCenter, size: Vector2(64, 64));

  bool _handled = false;

  @override
  Future<void> onLoad() async {
    // 은은한 후광 링 - 계속 커졌다 작아지며 존재감을 알린다.
    add(
      CircleComponent(
        radius: 28,
        anchor: Anchor.center,
        position: Vector2(size.x / 2, size.y / 2),
        paint: Paint()
          ..color = const Color(0xFFFFD84D).withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      )..add(
        ScaleEffect.to(
          Vector2.all(1.35),
          EffectController(
            duration: 0.6,
            alternate: true,
            infinite: true,
            curve: Curves.easeInOut,
          ),
        ),
      ),
    );
    add(
      TextComponent(
        text: '⚡',
        anchor: Anchor.center,
        position: Vector2(size.x / 2, size.y / 2),
        textRenderer: TextPaint(
          style: const TextStyle(
            fontFamily: 'GowunDodum',
            fontFamilyFallback: appFontFallback,
            fontSize: 40,
          ),
        ),
      )..add(
        RotateEffect.by(6.28, EffectController(duration: 2.2, infinite: true)),
      ),
    );
    add(
      RectangleHitbox(
        size: Vector2(40, 40),
        position: Vector2(size.x / 2 - 20, size.y / 2 - 20),
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isHolding || game.stageCompleted) return;
    position.x -= speed * dt;
    if (position.x < -90) {
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (_handled || other is! CatPlayer || !isMounted) return;
    _handled = true;
    if (!game.stageCompleted) {
      game.activatePowerMode();
    }
    removeFromParent();
  }
}
