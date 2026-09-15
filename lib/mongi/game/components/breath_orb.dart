import '../../../theme.dart' show appFontFallback;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import '../runner_game.dart';
import 'cat_player.dart';

/// 6번: "숨결 구슬" - 파워빛볼처럼 한 판에 드물게(한 번 정도) 등장하는
/// 특별한 아이템. 몽이가 닿으면 주먹/점프처럼 "빠르게 반응하기"가 아니라
/// 정반대로 "잠깐 멈춰서 호흡을 따라가기"라는 세 번째 성격의 입력을
/// 요구하는 [RunnerGame.startBreathingMoment]를 트리거한다.
///
/// 파워빛볼(⚡, 노란색, 회전)과 시각적으로 뚜렷이 구분되도록 옅은 청록색
/// 숨결 링 + 부드럽게 커졌다 작아지는(호흡을 암시하는) 펄스 효과, 그리고
/// 회전 없는 고정된 이모지(🌬)를 쓴다.
class BreathOrb extends PositionComponent with CollisionCallbacks {
  final RunnerGame game;
  final double speed;

  BreathOrb({required this.game, this.speed = 220})
    : super(anchor: Anchor.bottomCenter, size: Vector2(64, 64));

  bool _handled = false;

  @override
  Future<void> onLoad() async {
    // 은은한 청록빛 후광 링 - 파워빛볼보다 훨씬 느린 주기로 커졌다 작아져
    // "천천히, 여유롭게"라는 호흡의 인상을 시각적으로 미리 암시한다.
    add(
      CircleComponent(
        radius: 30,
        anchor: Anchor.center,
        position: Vector2(size.x / 2, size.y / 2),
        paint: Paint()
          ..color = const Color(0xFF8FE3D0).withValues(alpha: 0.32)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      )..add(
        ScaleEffect.to(
          Vector2.all(1.3),
          EffectController(
            duration: 1.4,
            alternate: true,
            infinite: true,
            curve: Curves.easeInOut,
          ),
        ),
      ),
    );
    add(
      TextComponent(
        text: '🌬',
        anchor: Anchor.center,
        position: Vector2(size.x / 2, size.y / 2),
        textRenderer: TextPaint(
          style: const TextStyle(
            fontFamily: 'GowunDodum',
            fontFamilyFallback: appFontFallback,
            fontSize: 38,
          ),
        ),
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
    if (!game.stageCompleted) {
      game.startBreathingMoment();
    }
    removeFromParent();
  }
}
