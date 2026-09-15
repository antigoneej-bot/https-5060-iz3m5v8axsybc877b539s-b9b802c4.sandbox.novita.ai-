import '../../../theme.dart' show appFontFallback;
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

/// 게임 플레이 도중, 같은 감정을 3번 연속으로 먹었을 때 화면 위쪽에 크게
/// 튀어나오는 짧은 힐링 메시지 컷인.
///
/// "게임 끝나야만 힐링 파트가 나온다"는 경계를 없애기 위한 컴포넌트 - 콤보를
/// 쌓는 순간(=감정을 연속으로 마주하는 순간) 자체가 곧 그 감정의 healMessage가
/// 튀어나오는 게임 이펙트가 되도록 한다.
///
/// 주의: [TextComponent]는 OpacityProvider를 구현하지 않으므로(floating_label.dart
/// 참고) OpacityEffect를 쓰면 안 된다. 카드 배경은 애니메이션 없이 고정 알파의
/// 사각형이라 이 제약과 무관하고, 등장/퇴장은 ScaleEffect + MoveEffect +
/// RemoveEffect 조합만 사용한다.
class EmotionCutIn extends PositionComponent {
  final String text;
  final Color accentColor;
  final double areaWidth;

  EmotionCutIn({
    required this.text,
    required this.accentColor,
    required this.areaWidth,
    required Vector2 topCenter,
  }) : super(position: topCenter, anchor: Anchor.topCenter, priority: 900) {
    scale = Vector2.zero();
  }

  @override
  Future<void> onLoad() async {
    final cardWidth = areaWidth * 0.8 < 220
        ? 220.0
        : (areaWidth * 0.8 > 340 ? 340.0 : areaWidth * 0.8);
    add(
      RectangleComponent(
        anchor: Anchor.topCenter,
        position: Vector2.zero(),
        size: Vector2(cardWidth, 82),
        paint: Paint()..color = Colors.white.withValues(alpha: 0.95),
      ),
    );
    add(
      TextComponent(
        text: text,
        anchor: Anchor.center,
        position: Vector2(0, 41),
        textRenderer: TextPaint(
          style: TextStyle(
            fontFamily: 'GowunDodum',
            fontFamilyFallback: appFontFallback,
            color: accentColor,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            height: 1.35,
          ),
        ),
      ),
    );

    add(
      MoveEffect.by(
        Vector2(0, 8),
        EffectController(duration: 1.6, curve: Curves.easeOut),
      ),
    );
    add(
      ScaleEffect.to(
        Vector2.all(1.0),
        EffectController(duration: 0.25, curve: Curves.easeOutBack),
      ),
    );
    add(RemoveEffect(delay: 1.8));
  }
}
