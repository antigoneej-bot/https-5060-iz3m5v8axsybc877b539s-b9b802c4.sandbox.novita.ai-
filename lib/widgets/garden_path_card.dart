import 'dart:math';
import 'package:flutter/material.dart';
import '../theme.dart';

/// '정원 산책로' 컨셉의 메뉴 카드.
/// - 딱딱한 흰 사각형 박스 대신, 모서리 반경이 서로 다른 유기적인 알약/블롭
///   모양을 사용합니다.
/// - 배경은 반투명 파스텔 톤이라 뒤의 정원 배경(꽃잎·나뭇잎·고양이)이 은은하게
///   비쳐 보입니다.
/// - 항상 아주 미세하게 위아래로 떠다니는 느낌(부유 애니메이션)을 주고,
///   마우스를 올리면(hover) 나뭇잎이 흔들리듯 살짝 커지며 좌우로 흔들립니다.
/// - 모바일 터치에서도 누르는 순간 같은 흔들림 피드백을 줍니다.
class GardenPathCard extends StatefulWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color accent;
  final Color background;
  final VoidCallback onTap;

  /// -1(왼쪽) ~ 1(오른쪽) 사이 값으로, 오솔길을 따라 카드가 좌우로
  /// 비대칭적으로 놓이도록 합니다.
  final double alignX;

  /// 카드의 상대적 너비(0~1). 산책로를 걷다 만나는 팻말처럼 크기가
  /// 조금씩 달라지는 느낌을 줍니다.
  final double widthFactor;

  /// 부유 애니메이션의 시작 위상을 다르게 주기 위한 값(카드마다 달라야 함)
  final int floatSeed;

  const GardenPathCard({
    super.key,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.background,
    required this.onTap,
    this.alignX = 0,
    this.widthFactor = 0.86,
    this.floatSeed = 0,
  });

  @override
  State<GardenPathCard> createState() => _GardenPathCardState();
}

class _GardenPathCardState extends State<GardenPathCard>
    with TickerProviderStateMixin {
  late final AnimationController _floatController;
  late final AnimationController _hoverController;
  bool _hovering = false;

  @override
  void initState() {
    super.initState();
    final rng = Random(widget.floatSeed * 17 + 3);
    _floatController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 3600 + rng.nextInt(1800)),
    )..repeat(reverse: true);
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      lowerBound: 0,
      upperBound: 1,
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    _hoverController.dispose();
    super.dispose();
  }

  void _setHover(bool v) {
    if (_hovering == v) return;
    setState(() => _hovering = v);
    if (v) {
      _hoverController.forward();
    } else {
      _hoverController.reverse();
    }
  }

  /// 카드마다 조금씩 다른 '블롭' 모서리 반경을 만들어 하나하나가 손으로
  /// 다듬은 듯한 유기적인 형태가 되도록 합니다.
  BorderRadius _blobRadius() {
    final rng = Random(widget.floatSeed * 31 + 7);
    double r(double base) => base + rng.nextDouble() * 14;
    return BorderRadius.only(
      topLeft: Radius.circular(r(34)),
      topRight: Radius.circular(r(26)),
      bottomLeft: Radius.circular(r(26)),
      bottomRight: Radius.circular(r(38)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final radius = _blobRadius();
    return Align(
      alignment: Alignment(widget.alignX, 0),
      child: FractionallySizedBox(
        widthFactor: widget.widthFactor,
        child: AnimatedBuilder(
          animation: Listenable.merge([_floatController, _hoverController]),
          builder: (context, child) {
            final floatT = _floatController.value; // 0..1..0
            final floatAngle = sin(floatT * pi) * 0.012;
            final floatDy = sin(floatT * pi) * 3.2;
            final hoverT = _hoverController.value;
            final wiggle = sin(hoverT * pi * 3) * 0.045 * hoverT;
            final scale = 1.0 + hoverT * 0.045;
            return Transform.translate(
              offset: Offset(0, floatDy - hoverT * 4),
              child: Transform.rotate(
                angle: floatAngle + wiggle,
                child: Transform.scale(scale: scale, child: child),
              ),
            );
          },
          child: MouseRegion(
            onEnter: (_) => _setHover(true),
            onExit: (_) => _setHover(false),
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTapDown: (_) => _setHover(true),
              onTapCancel: () => _setHover(false),
              onTapUp: (_) => _setHover(false),
              onTap: widget.onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  borderRadius: radius,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.background.withValues(alpha: 0.86),
                      widget.background.withValues(alpha: 0.55),
                    ],
                  ),
                  border: Border.all(
                    color: widget.accent.withValues(
                      alpha: _hovering ? 0.55 : 0.28,
                    ),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.accent.withValues(
                        alpha: _hovering ? 0.28 : 0.14,
                      ),
                      blurRadius: _hovering ? 26 : 16,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.55),
                        border: Border.all(
                          color: widget.accent.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        widget.emoji,
                        style: const TextStyle(fontSize: 21),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: pathLabelFont(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.subtitle,
                            style: bodyFont(
                              fontSize: 11.5,
                              color: AppColors.inkSoft,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: widget.accent,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 카드와 카드 사이, 오솔길을 잇는 은은한 점선 곡선 + 발자국/나비 장식.
/// 정원을 산책하듯 다음 카드로 자연스럽게 시선이 이어지도록 합니다.
class GardenPathConnector extends StatelessWidget {
  final double startX; // -1..1 (이전 카드의 alignX)
  final double endX; // -1..1 (다음 카드의 alignX)
  final String decorEmoji; // '🐾' 또는 '🦋'
  final double height;
  const GardenPathConnector({
    super.key,
    required this.startX,
    required this.endX,
    this.decorEmoji = '🐾',
    this.height = 46,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final startPx = (startX + 1) / 2 * w;
          final endPx = (endX + 1) / 2 * w;
          return Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _DottedCurvePainter(
                    start: Offset(startPx, 2),
                    end: Offset(endPx, height - 2),
                    color: AppColors.titlePastelGreen.withValues(alpha: 0.38),
                  ),
                ),
              ),
              Positioned(
                left: ((startPx + endPx) / 2 - 10).clamp(0, w - 20),
                top: height / 2 - 10,
                child: Opacity(
                  opacity: 0.55,
                  child: Text(
                    decorEmoji,
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DottedCurvePainter extends CustomPainter {
  final Offset start;
  final Offset end;
  final Color color;
  _DottedCurvePainter({
    required this.start,
    required this.end,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final control = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const dotSpacing = 9.0;
    final metric = path.computeMetrics().first;
    final total = metric.length;
    var dist = 0.0;
    while (dist < total) {
      final tangent = metric.getTangentForOffset(dist);
      if (tangent != null) {
        canvas.drawCircle(tangent.position, 1.6, paint);
      }
      dist += dotSpacing;
    }
  }

  @override
  bool shouldRepaint(covariant _DottedCurvePainter oldDelegate) => false;
}

/// 흰 박스 없이, 반투명 파스텔 블롭 형태로 요약 정보를 보여주는 공용 컨테이너.
/// StreakHeader, GrowthHeader 등 대시보드 상단 요약 위젯에 사용합니다.
class GlassBlob extends StatelessWidget {
  final Widget child;
  final Color accent;
  final Color background;
  final EdgeInsetsGeometry padding;
  const GlassBlob({
    super.key,
    required this.child,
    required this.accent,
    required this.background,
    this.padding = const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            background.withValues(alpha: 0.85),
            background.withValues(alpha: 0.5),
          ],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.25), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}
