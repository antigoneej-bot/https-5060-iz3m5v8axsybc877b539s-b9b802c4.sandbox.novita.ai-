import '../../../theme.dart' show appFontFallback;
import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

/// 4번: 감정 연속 먹기/받기 미니 이벤트 - 같은 감정을 3의 배수번 연속으로
/// 마주했을 때([RunnerGame]의 [GameNarrativeService.shouldTriggerCutIn]과
/// 같은 타이밍) 그 자리에서 작은 불꽃놀이처럼 터지는 축하 이펙트.
///
/// 기존에는 이 순간에 [EmotionCutIn] 텍스트 카드만 위쪽에 떴는데, 그것만으로는
/// "게임 플레이 자체가 신나진다"는 느낌보다는 "설명 카드가 뜬다"는 느낌에
/// 가까웠다. 이 컴포넌트는 몬스터가 사라진 그 자리에서 곧바로 반짝이는
/// 조각들이 사방으로 튀어나가는 순수한 시각적 보상을 더해, 스트릭을 쌓는
/// 행위 자체가 손맛 있게 느껴지도록 한다. 스트릭 티어([tier] = streak ~/ 3)가
/// 높아질수록 조각 수와 중심 별 크기가 조금씩 커져, 리듬을 오래 이어갈수록
/// 이벤트가 점점 더 화려해진다는 걸 체감할 수 있다.
///
/// 주의: [TextComponent]는 OpacityProvider를 구현하지 않으므로(다른 컴포넌트의
/// 주석 참고) 중앙의 별 이모지는 [OpacityEffect] 대신 [ScaleEffect]로만
/// 나타났다 사라지게 한다. 조각(CircleComponent)들은 [LightBurst]와 동일하게
/// OpacityEffect를 안전하게 사용할 수 있다.
class StreakBurst extends PositionComponent {
  final Color color;
  final int tier;

  StreakBurst({required Vector2 position, required this.color, this.tier = 1})
    : super(position: position, anchor: Anchor.center, priority: 850);

  @override
  Future<void> onLoad() async {
    final pieceCount = (7 + tier * 2).clamp(7, 15);
    final rand = math.Random();
    for (var i = 0; i < pieceCount; i++) {
      final angle = (i / pieceCount) * math.pi * 2 + rand.nextDouble() * 0.5;
      final distance = 42.0 + tier * 5 + rand.nextDouble() * 16;
      final target = Vector2(math.cos(angle), math.sin(angle)) * distance;
      final useWhite = i % 3 == 0;
      final radius = 4.0 + rand.nextDouble() * 3;
      final piece = CircleComponent(
        radius: radius,
        anchor: Anchor.center,
        paint: Paint()
          ..color = (useWhite ? Colors.white : color).withValues(alpha: 0.9),
      );
      add(piece);
      piece.add(
        MoveEffect.by(
          target,
          EffectController(
            duration: 0.45 + rand.nextDouble() * 0.2,
            curve: Curves.easeOut,
          ),
        ),
      );
      piece.add(
        OpacityEffect.fadeOut(
          EffectController(
            duration: 0.5,
            startDelay: 0.05,
            curve: Curves.easeIn,
          ),
        ),
      );
    }
    // 가운데서 한 번 반짝하고 사라지는 별 - 텍스트는 OpacityEffect를 못 쓰므로
    // FloatingLabel과 같은 방식(스케일 확대 후 0으로 축소)으로 흉내낸다.
    final star = TextComponent(
      text: tier >= 3 ? '🌟' : '✨',
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: TextStyle(
          fontFamily: 'GowunDodum',
          fontFamilyFallback: appFontFallback,
          fontSize: 24 + tier * 2.0,
        ),
      ),
    );
    star.scale = Vector2.zero();
    add(star);
    star.add(
      SequenceEffect([
        ScaleEffect.to(
          Vector2.all(1.25),
          EffectController(duration: 0.16, curve: Curves.easeOut),
        ),
        ScaleEffect.to(
          Vector2.all(0.0),
          EffectController(
            duration: 0.35,
            startDelay: 0.18,
            curve: Curves.easeIn,
          ),
        ),
      ]),
    );
    add(RemoveEffect(delay: 0.8));
  }
}
