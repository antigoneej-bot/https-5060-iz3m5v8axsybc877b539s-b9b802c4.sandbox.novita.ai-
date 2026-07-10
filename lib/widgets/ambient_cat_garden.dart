import 'dart:math';
import 'package:flutter/material.dart';
import '../data/shadow_cats_data.dart';
import '../theme.dart';

/// 달빛 그림자 정원 - 카드 안이 아니라 화면 공간 그 자체에 독립적으로 존재하는
/// 고양이들의 배경 레이어.
/// - 각 고양이는 자신만의 위치·속도·타이밍·동작 주기를 가지고 조용히 살아갑니다.
/// - 절대 터치를 가로채지 않으며(IgnorePointer), 항상 콘텐츠보다 뒤쪽(z-order)에
///   그려져 텍스트·버튼·입력 영역을 가리지 않습니다.
/// - 성능을 위해 동시에 등장하는 고양이 수를 소수로 제한하고, 고양이당
///   AnimationController 1개만 사용해 모든 동작(걷기/앉기/꼬리흔들기/눈깜빡임/
///   고개돌리기/식물 뒤에서 나타나기)을 하나의 시간값에서 파생시킵니다.
class AmbientCatGardenLayer extends StatelessWidget {
  const AmbientCatGardenLayer({super.key});

  static const List<_AmbientCatSpec> _specs = [
    _AmbientCatSpec(
      catId: 'serene',
      alignment: Alignment(-0.97, -0.62),
      size: 36,
      walkRange: 9,
      periodSeconds: 24,
      phase: 0.04,
      flip: false,
    ),
    _AmbientCatSpec(
      catId: 'curious',
      alignment: Alignment(0.97, -0.22),
      size: 32,
      walkRange: 11,
      periodSeconds: 28,
      phase: 0.36,
      flip: true,
    ),
    _AmbientCatSpec(
      catId: 'sleepy',
      alignment: Alignment(-0.97, 0.34),
      size: 38,
      walkRange: 6,
      periodSeconds: 32,
      phase: 0.58,
      flip: false,
    ),
    _AmbientCatSpec(
      catId: 'comforted',
      alignment: Alignment(0.97, 0.66),
      size: 34,
      walkRange: 8,
      periodSeconds: 22,
      phase: 0.79,
      flip: true,
    ),
    _AmbientCatSpec(
      catId: 'affectionate',
      alignment: Alignment(0.95, -0.86),
      size: 28,
      walkRange: 9,
      periodSeconds: 26,
      phase: 0.17,
      flip: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [for (final spec in _specs) _AmbientCat(spec: spec)],
      ),
    );
  }
}

class _AmbientCatSpec {
  final String catId;
  final Alignment alignment;
  final double size;
  final double walkRange;
  final int periodSeconds;
  final double phase;
  final bool flip;
  const _AmbientCatSpec({
    required this.catId,
    required this.alignment,
    required this.size,
    required this.walkRange,
    required this.periodSeconds,
    required this.phase,
    required this.flip,
  });
}

class _AmbientCat extends StatefulWidget {
  final _AmbientCatSpec spec;
  const _AmbientCat({required this.spec});

  @override
  State<_AmbientCat> createState() => _AmbientCatState();
}

class _AmbientCatState extends State<_AmbientCat>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.spec.periodSeconds),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cat = shadowCatById(widget.spec.catId);
    final size = widget.spec.size;
    return Align(
      alignment: widget.spec.alignment,
      child: SizedBox(
        width: size + 30,
        height: size + 36,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final tp = (_controller.value + widget.spec.phase) % 1.0;
            final anim = _computeAnim(tp);
            return Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                // 고양이가 숨어 있다 나타나는 '식물(그늘)' - 은은하게 항상 자리를 지킵니다.
                Positioned(
                  bottom: 0,
                  child: Container(
                    width: size * 0.92,
                    height: size * 0.32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: AppColors.catSage.withValues(alpha: 0.14),
                    ),
                  ),
                ),
                Positioned(
                  bottom: size * 0.15,
                  child: Transform.translate(
                    offset: Offset(anim.dx, anim.dy),
                    child: Opacity(
                      opacity: anim.opacity,
                      child: Transform.scale(
                        scale: anim.scale,
                        child: Transform.rotate(
                          angle: anim.angle,
                          child: Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.diagonal3Values(
                              widget.spec.flip ? -1.0 : 1.0,
                              1.0,
                              1.0,
                            ),
                            child: Container(
                              width: size,
                              height: size,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.10),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  cat.imageAsset,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// 하나의 순환 주기(tp: 0~1)에서 등장-활동-퇴장의 모든 동작을 파생시킵니다.
  /// 0.00~0.10 : 식물 뒤에서 조용히 나타남
  /// 0.10~0.72 : 걷기 · 앉아있기 · 고개 돌리기 · 눈 깜빡임이 섞인 활동 구간
  /// 0.72~0.85 : 다시 식물 뒤로 사라짐
  /// 0.85~1.00 : 잠시 자리를 비움 (완전히 숨어있는 휴식 구간)
  _AmbientAnim _computeAnim(double tp) {
    const emergeEnd = 0.10;
    const activeEnd = 0.72;
    const retreatEnd = 0.85;
    const baseOpacity = 0.85;

    if (tp < emergeEnd) {
      final t = tp / emergeEnd;
      final e = Curves.easeOut.transform(t);
      return _AmbientAnim(
        opacity: e * baseOpacity,
        dy: (1 - e) * 16,
        dx: 0,
        scale: 0.85 + 0.15 * e,
        angle: 0,
      );
    }
    if (tp < activeEnd) {
      final t = (tp - emergeEnd) / (activeEnd - emergeEnd);
      // 걷기: 느리고 부드러운 왕복 이동
      final dx = widget.spec.walkRange * sin(t * 2 * pi);
      // 앉아 숨쉬는 듯한 미세한 스케일 펄스 + 꼬리 흔들림을 암시하는 아주 작은 회전
      final breathe =
          1.0 + 0.018 * sin(t * 2 * pi * 5 + widget.spec.phase * 10);
      final tailAndTurn = 0.05 * sin(t * 2 * pi * 1.3 + widget.spec.phase * 7);
      // 눈 깜빡임: 활동 구간 동안 짧게 세 번 정도 깜빡입니다.
      final blinkFrac = (t * 3) % 1.0;
      final blink = blinkFrac > 0.95 ? 0.3 : 1.0;
      return _AmbientAnim(
        opacity: baseOpacity * blink,
        dy: 0,
        dx: dx,
        scale: breathe,
        angle: tailAndTurn,
      );
    }
    if (tp < retreatEnd) {
      final t = (tp - activeEnd) / (retreatEnd - activeEnd);
      final e = Curves.easeIn.transform(t);
      return _AmbientAnim(
        opacity: (1 - e) * baseOpacity,
        dy: e * 16,
        dx: 0,
        scale: 1.0 - 0.15 * e,
        angle: 0,
      );
    }
    return const _AmbientAnim(opacity: 0, dy: 16, dx: 0, scale: 0.85, angle: 0);
  }
}

class _AmbientAnim {
  final double opacity;
  final double dy;
  final double dx;
  final double scale;
  final double angle;
  const _AmbientAnim({
    required this.opacity,
    required this.dy,
    required this.dx,
    required this.scale,
    required this.angle,
  });
}
