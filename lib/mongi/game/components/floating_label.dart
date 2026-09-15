import '../../../theme.dart' show appFontFallback;
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

/// 감정을 먹었을 때 위로 살짝 떠오르며 사라지는 "냠!" 텍스트 이펙트.
///
/// 주의: [TextComponent]는 OpacityProvider를 구현하지 않으므로 [OpacityEffect]를
/// 적용하면 안 된다 (적용 시 onMount에서 UnsupportedError가 발생하고, 이 예외가
/// 컴포넌트 마운트 큐 처리를 중단시켜 몬스터를 먹을 때마다 게임 전체가 멈추는
/// 심각한 버그로 이어졌었다). 대신 살짝 커졌다가 작아지며 사라지는
/// [ScaleEffect] + 일정 시간 뒤 자동 제거되는 [RemoveEffect]로 동일한 느낌을 낸다.
class FloatingLabel extends TextComponent {
  FloatingLabel({required Vector2 position, String text = '냠!'})
    : super(
        text: text,
        position: position,
        anchor: Anchor.center,
        textRenderer: TextPaint(
          style: const TextStyle(
            fontFamily: 'GowunDodum',
            fontFamilyFallback: appFontFallback,
            color: Color(0xFFFF8FAB),
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
      );

  @override
  Future<void> onLoad() async {
    add(
      MoveEffect.by(
        Vector2(0, -46),
        EffectController(duration: 0.7, curve: Curves.easeOut),
      ),
    );
    add(
      SequenceEffect([
        ScaleEffect.to(
          Vector2.all(1.25),
          EffectController(duration: 0.12, curve: Curves.easeOut),
        ),
        ScaleEffect.to(
          Vector2.all(0.0),
          EffectController(
            duration: 0.45,
            startDelay: 0.15,
            curve: Curves.easeIn,
          ),
        ),
      ]),
    );
    add(RemoveEffect(delay: 0.75));
  }
}
