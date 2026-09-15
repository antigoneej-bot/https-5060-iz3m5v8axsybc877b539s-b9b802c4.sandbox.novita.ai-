import 'package:flutter/material.dart';

import '../services/emotion_insight_service.dart';

/// Daylio/Bearable식 "마음 흐름 그래프" - 하루당 무드 점수(-1.0~+1.0)를
/// 꺾은선으로 이어 그린다. 기록이 없는 날은 선을 끊어서(점을 잇지 않고)
/// "빈 구간"으로 자연스럽게 표시한다.
///
/// 외부 차트 패키지 없이 [CustomPainter]로 가볍게 구현했다 - 이 앱의 기존
/// 주간/요일 차트([emotion_calendar_screen.dart])도 같은 원칙을 따른다.
class MoodTrendChart extends StatelessWidget {
  final MoodTrendSeries series;
  final double height;

  const MoodTrendChart({super.key, required this.series, this.height = 140});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _MoodTrendPainter(series: series)),
    );
  }
}

class _MoodTrendPainter extends CustomPainter {
  final MoodTrendSeries series;

  static const Color _positiveColor = Color(0xFFF5C244);
  static const Color _negativeColor = Color(0xFF8C9CB4);
  static const Color _lineColor = Color(0xFF5FB8AE);
  static const Color _baselineColor = Color(0xFFE3DCD3);

  _MoodTrendPainter({required this.series});

  @override
  void paint(Canvas canvas, Size size) {
    final points = series.points;
    if (points.isEmpty) return;

    final topPadding = 10.0;
    final bottomPadding = 10.0;
    final chartHeight = size.height - topPadding - bottomPadding;
    final zeroY = topPadding + chartHeight / 2;

    // 0(중립) 기준선 - 점선.
    final baselinePaint = Paint()
      ..color = _baselineColor
      ..strokeWidth = 1;
    const dashWidth = 4.0;
    const dashGap = 3.0;
    var dashX = 0.0;
    while (dashX < size.width) {
      canvas.drawLine(
        Offset(dashX, zeroY),
        Offset((dashX + dashWidth).clamp(0, size.width), zeroY),
        baselinePaint,
      );
      dashX += dashWidth + dashGap;
    }

    final n = points.length;
    final stepX = n <= 1 ? 0.0 : size.width / (n - 1);

    Offset offsetFor(int i, double score) {
      final x = n <= 1 ? size.width / 2 : stepX * i;
      // score: -1.0 ~ +1.0 -> y: bottom ~ top
      final y = zeroY - (score.clamp(-1.0, 1.0) * (chartHeight / 2));
      return Offset(x, y);
    }

    final linePaint = Paint()
      ..color = _lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    Path? currentPath;
    for (var i = 0; i < n; i++) {
      final point = points[i];
      if (!point.hasData) {
        if (currentPath != null) {
          canvas.drawPath(currentPath, linePaint);
          currentPath = null;
        }
        continue;
      }
      final offset = offsetFor(i, point.averageScore!);
      if (currentPath == null) {
        currentPath = Path()..moveTo(offset.dx, offset.dy);
      } else {
        currentPath.lineTo(offset.dx, offset.dy);
      }
    }
    if (currentPath != null) {
      canvas.drawPath(currentPath, linePaint);
    }

    // 데이터가 있는 날마다 색 점(양/음)을 찍는다.
    for (var i = 0; i < n; i++) {
      final point = points[i];
      if (!point.hasData) continue;
      final offset = offsetFor(i, point.averageScore!);
      final dotColor = point.averageScore! >= 0
          ? _positiveColor
          : _negativeColor;
      canvas.drawCircle(offset, 4.2, Paint()..color = Colors.white);
      canvas.drawCircle(offset, 3.2, Paint()..color = dotColor);
    }
  }

  @override
  bool shouldRepaint(covariant _MoodTrendPainter oldDelegate) {
    return oldDelegate.series != series;
  }
}
