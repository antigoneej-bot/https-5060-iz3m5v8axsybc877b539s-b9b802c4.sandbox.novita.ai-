import '../../../theme.dart' show appFontFallback;
import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

/// 스테이지 목표를 다 채워서 성공적으로 끝났을 때(_endStage(earlyStop: false))
/// 화면 중앙에 크게 떠오르는 "클리어" 배너.
///
/// 기존에는 목숨을 다 써서 끝났을 때나 목표를 다 채워서 끝났을 때나 똑같이
/// 작은 [FloatingLabel] 한 줄("골골~ 😽")만 떴었다. 이 방식이 몬스터를 먹을
/// 때마다 뜨는 "냠!" 텍스트와 시각적으로 거의 구분이 안 돼서, "죽은 건지
/// 스테이지를 완료한 건지 알 수가 없다"는 피드백으로 이어졌다. 이 컴포넌트는
/// 화면 중앙을 크게 차지하는 카드 + 색종이 이펙트 + 영문 "CLEAR!" 문구로,
/// 성공적으로 끝났다는 걸 실패(early stop)와 뚜렷이 구분되게 알려준다.
///
/// 주의: 카드 배경/보더는 애니메이션 없는 정적 RectangleComponent라
/// OpacityEffect 제약과 무관하고, 색종이는 CircleComponent(HasPaint로
/// OpacityProvider 구현)라 OpacityEffect를 안전하게 쓸 수 있다. 오직
/// TextComponent에는 OpacityEffect를 쓰면 안 된다는 제약(FloatingLabel/
/// EmotionCutIn 참고)만 그대로 지킨다.
class StageClearBanner extends PositionComponent {
  final Vector2 areaSize;
  final math.Random _rand = math.Random();

  StageClearBanner({required this.areaSize})
    : super(
        position: Vector2(areaSize.x / 2, areaSize.y * 0.38),
        anchor: Anchor.center,
        priority: 1000,
      ) {
    scale = Vector2.zero();
  }

  @override
  Future<void> onLoad() async {
    final cardWidth = (areaSize.x * 0.82).clamp(240.0, 380.0);
    const cardHeight = 172.0;

    // 카드 배경 - 은은한 크림색 바탕에 금빛 보더로 "상장/축하 카드" 느낌을 낸다.
    add(
      RectangleComponent(
        anchor: Anchor.center,
        position: Vector2.zero(),
        size: Vector2(cardWidth, cardHeight),
        paint: Paint()..color = const Color(0xFFFFF7E0),
      ),
    );
    add(
      RectangleComponent(
        anchor: Anchor.center,
        position: Vector2.zero(),
        size: Vector2(cardWidth - 10, cardHeight - 10),
        paint: Paint()
          ..color = const Color(0xFFFFD54F)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5,
      ),
    );

    add(
      TextComponent(
        text: '🎉 CLEAR! 🎉',
        anchor: Anchor.center,
        position: Vector2(0, -48),
        textRenderer: TextPaint(
          style: const TextStyle(
            fontFamily: 'GowunDodum',
            fontFamilyFallback: appFontFallback,
            color: Color(0xFFE8871E),
            fontSize: 34,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
    add(
      TextComponent(
        text: '스테이지 클리어!',
        anchor: Anchor.center,
        position: Vector2(0, -4),
        textRenderer: TextPaint(
          style: const TextStyle(
            fontFamily: 'GowunDodum',
            fontFamilyFallback: appFontFallback,
            color: Color(0xFF6B4A23),
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
    add(
      TextComponent(
        text: '목표를 모두 채웠어요, 골골~ 😽',
        anchor: Anchor.center,
        position: Vector2(0, 36),
        textRenderer: TextPaint(
          style: const TextStyle(
            fontFamily: 'GowunDodum',
            fontFamilyFallback: appFontFallback,
            color: Color(0xFF8A7355),
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );

    // 카드가 살짝 튕기며 팝업되는 등장 애니메이션.
    add(
      ScaleEffect.to(
        Vector2.all(1.0),
        EffectController(duration: 0.32, curve: Curves.easeOutBack),
      ),
    );

    // 카드 주변으로 사방으로 흩어지는 색종이(작은 원) - 여러 색을 섞어
    // 실패(early stop)와는 명확히 다른 축제 분위기를 준다.
    const confettiColors = [
      Color(0xFFFF8FAB),
      Color(0xFFFFD54F),
      Color(0xFF80CBC4),
      Color(0xFF90CAF9),
      Color(0xFFCE93D8),
    ];
    for (var i = 0; i < 16; i++) {
      final angle = _rand.nextDouble() * math.pi * 2;
      final distance = 90 + _rand.nextDouble() * 80;
      final dot = CircleComponent(
        radius: 4 + _rand.nextDouble() * 3,
        anchor: Anchor.center,
        position: Vector2.zero(),
        paint: Paint()..color = confettiColors[i % confettiColors.length],
      );
      add(dot);
      dot.add(
        MoveEffect.by(
          Vector2(math.cos(angle) * distance, math.sin(angle) * distance - 20),
          EffectController(duration: 0.9, curve: Curves.easeOut),
        ),
      );
      dot.add(
        OpacityEffect.fadeOut(
          EffectController(
            duration: 0.6,
            startDelay: 0.5,
            curve: Curves.easeIn,
          ),
        ),
      );
    }

    add(RemoveEffect(delay: 1.95));
  }
}
