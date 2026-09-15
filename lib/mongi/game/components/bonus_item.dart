import '../../../theme.dart' show appFontFallback;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import '../runner_game.dart';
import 'cat_player.dart';

enum BonusKind { treat, heart }

/// A rare, friendly surprise that shows up every so often while playing.
/// - [BonusKind.treat]: a sparkly treat worth +2 progress (and a bit of
///   combo/haptic celebration).
/// - [BonusKind.heart]: restores one life (only ever spawned when the
///   player is missing one).
/// Always auto-collected on contact, just like the emotion monsters - no
/// precision required. It's meant to feel like a small, welcome gift.
class BonusItem extends PositionComponent with CollisionCallbacks {
  final RunnerGame game;
  final BonusKind kind;
  final double speed;

  BonusItem({required this.game, required this.kind, this.speed = 210})
    : super(anchor: Anchor.bottomCenter, size: Vector2(60, 60));

  bool _handled = false;

  @override
  Future<void> onLoad() async {
    // Gentle continuous pulse so it visually stands out from regular
    // obstacles/monsters as something special.
    add(
      ScaleEffect.to(
        Vector2.all(1.18),
        EffectController(
          duration: 0.5,
          alternate: true,
          infinite: true,
          curve: Curves.easeInOut,
        ),
      ),
    );
    add(
      TextComponent(
        text: kind == BonusKind.treat ? '⭐' : '💗',
        anchor: Anchor.center,
        position: Vector2(size.x / 2, size.y / 2),
        textRenderer: TextPaint(
          style: const TextStyle(
            fontFamily: 'GowunDodum',
            fontFamilyFallback: appFontFallback,
            fontSize: 40,
          ),
        ),
      ),
    );
    add(
      RectangleHitbox(
        size: Vector2(38, 38),
        position: Vector2(size.x / 2 - 19, size.y / 2 - 19),
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    // 스테이지가 끝난 뒤(마무리 애니메이션 중)에는 보너스도 멈춘다.
    if (!game.isHolding || game.stageCompleted) return;
    position.x -= speed * game.powerSpeedBoost * dt;
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

    // 스테이지가 이미 끝난 뒤에는 보너스 획득 판정을 하지 않는다.
    if (game.stageCompleted) {
      removeFromParent();
      return;
    }
    if (kind == BonusKind.treat) {
      game.collectTreat(position.clone());
    } else {
      game.collectHeart(position.clone());
    }
    removeFromParent();
  }
}
