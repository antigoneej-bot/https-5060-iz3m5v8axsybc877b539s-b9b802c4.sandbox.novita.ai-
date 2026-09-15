import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

/// 돌멩이에 부딪혔을 때(미스) 화면 전체가 살짝 붉게 번쩍이는 타격감 오버레이.
/// TextComponent가 아닌 순수 사각형 렌더링이라 OpacityEffect 버그와 무관하며,
/// 매 프레임 알파값을 직접 감쇠시키는 방식이라 예측 가능하고 가볍다.
class HitFlashOverlay extends PositionComponent {
  double _alpha = 0;
  static const double _decayPerSecond = 2.6;

  HitFlashOverlay() : super(priority: 1000);

  /// 미스가 발생한 순간 호출 - 화면을 붉게 번쩍이게 한다.
  void trigger() {
    _alpha = 0.32;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (parent is FlameGame) {
      size = (parent as FlameGame).size;
    }
    if (_alpha > 0) {
      _alpha = (_alpha - _decayPerSecond * dt).clamp(0.0, 1.0);
    }
  }

  @override
  void render(Canvas canvas) {
    if (_alpha <= 0) return;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = Colors.red.withValues(alpha: _alpha),
    );
  }
}
