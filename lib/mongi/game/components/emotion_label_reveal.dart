import '../../../theme.dart' show appFontFallback;
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

/// 5번: 몬스터 감정 라벨링 - 태어나서(=정원에 한 번도 심어본 적 없는) 처음
/// 마주하는 감정 몬스터를 먹거나 받는 순간, 화면 위쪽에 크게 튀어나오는
/// "이름 붙이기" 컷인.
///
/// 심리학의 "감정에 이름을 붙이면 그 감정이 조금 가라앉는다(affect
/// labeling)"는 원리를 게임 이펙트로 옮긴 것 - 그냥 "화"라는 뭉뚱그린 범주가
/// 아니라 "화르르"라는 구체적인 애칭으로 불러주는 순간을 강조한다. 애칭은
/// 이미 [EmotionEvolutionService]에 있던 것을, 대사는 이미 [Emotion.catQuestion]에
/// 있던 것을 그대로 재사용해 새 카피 없이 구현했다.
///
/// 주의: [EmotionCutIn]과 마찬가지로 TextComponent에는 OpacityEffect를 쓰면
/// 안 되므로(onLoad에서 UnsupportedError 발생 -> 컴포넌트 마운트 큐가 멈춤),
/// ScaleEffect + MoveEffect + RemoveEffect 조합만 사용한다.
class EmotionLabelReveal extends PositionComponent {
  final String nickname;
  final String catLine;
  final Color accentColor;
  final double areaWidth;

  /// 카드 위쪽에 붙는 작은 태그 캡션(예: "🏷️ 처음 만난 마음이에요"). 언어별로
  /// 다르게 보여줄 수 있도록 호출부(=[l10n]에 접근 가능한 쪽)에서 문자열을
  /// 완성해 넘겨준다.
  final String caption;

  EmotionLabelReveal({
    required this.nickname,
    required this.catLine,
    required this.accentColor,
    required this.areaWidth,
    required this.caption,
    required Vector2 topCenter,
  }) : super(position: topCenter, anchor: Anchor.topCenter, priority: 950) {
    scale = Vector2.zero();
  }

  @override
  Future<void> onLoad() async {
    final cardWidth = areaWidth * 0.84 < 240
        ? 240.0
        : (areaWidth * 0.84 > 360 ? 360.0 : areaWidth * 0.84);
    const cardHeight = 108.0;

    add(
      RectangleComponent(
        anchor: Anchor.topCenter,
        position: Vector2.zero(),
        size: Vector2(cardWidth, cardHeight),
        paint: Paint()..color = Colors.white.withValues(alpha: 0.96),
      ),
    );
    // 왼쪽에 감정 컬러 포인트 바 - "이름표"라는 느낌을 살리기 위한 작은 태그 장식.
    add(
      RectangleComponent(
        anchor: Anchor.topLeft,
        position: Vector2(0, 0),
        size: Vector2(6, cardHeight),
        paint: Paint()..color = accentColor,
      ),
    );
    add(
      TextComponent(
        text: caption,
        anchor: Anchor.topCenter,
        position: Vector2(0, 14),
        textRenderer: TextPaint(
          style: const TextStyle(
            fontFamily: 'GowunDodum',
            fontFamilyFallback: appFontFallback,
            color: Color(0xFF9A8F86),
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
    add(
      TextComponent(
        text: nickname,
        anchor: Anchor.topCenter,
        position: Vector2(0, 34),
        textRenderer: TextPaint(
          style: TextStyle(
            fontFamily: 'GowunDodum',
            fontFamilyFallback: appFontFallback,
            color: accentColor,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
    add(
      TextComponent(
        text: catLine,
        anchor: Anchor.topCenter,
        position: Vector2(0, 62),
        textRenderer: TextPaint(
          style: const TextStyle(
            fontFamily: 'GowunDodum',
            fontFamilyFallback: appFontFallback,
            color: Color(0xFF4A3F35),
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
      ),
    );

    add(
      MoveEffect.by(
        Vector2(0, 8),
        EffectController(duration: 2.0, curve: Curves.easeOut),
      ),
    );
    add(
      ScaleEffect.to(
        Vector2.all(1.0),
        EffectController(duration: 0.28, curve: Curves.easeOutBack),
      ),
    );
    add(RemoveEffect(delay: 2.3));
  }
}
