import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

/// 긍정적인 감정을 몽이가 가슴으로 받아 안는 순간, 그 자리에서 은은하게
/// 퍼졌다가 사라지는 빛무리. "먹어서 사라짐"이 아니라 "빛이 되어 스며듦"을
/// 표현하기 위한 전용 이펙트다.
///
/// [CircleComponent]는 [HasPaint]를 통해 OpacityProvider를 구현하므로
/// [TextComponent]와 달리 [OpacityEffect]를 안전하게 사용할 수 있다
/// (FloatingLabel/EmotionCutIn의 TextComponent OpacityEffect 금지 사항은
/// 이 컴포넌트에는 해당하지 않는다).
class LightBurst extends PositionComponent {
  final Color color;

  LightBurst({required Vector2 position, required this.color})
    : super(position: position, anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    // 여러 겹의 원이 서로 다른 속도로 커지며 퍼져나가는 빛무리 - 하나의
    // 딱딱한 원보다 부드러운 광채처럼 보이게 한다.
    for (final ring in const [
      (radius: 46.0, alpha: 0.55, growTo: 1.9, duration: 0.65),
      (radius: 30.0, alpha: 0.75, growTo: 2.3, duration: 0.55),
      (radius: 16.0, alpha: 0.9, growTo: 2.6, duration: 0.45),
    ]) {
      final circle = CircleComponent(
        radius: ring.radius,
        anchor: Anchor.center,
        position: Vector2.zero(),
        paint: Paint()
          ..color = color.withValues(alpha: ring.alpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
      add(circle);
      circle.add(
        ScaleEffect.to(
          Vector2.all(ring.growTo),
          EffectController(duration: ring.duration, curve: Curves.easeOut),
        ),
      );
      circle.add(
        OpacityEffect.fadeOut(
          EffectController(duration: ring.duration, curve: Curves.easeIn),
        ),
      );
    }
    add(RemoveEffect(delay: 0.7));
  }
}
