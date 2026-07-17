import 'dart:math';
import 'package:flutter/material.dart';
import '../theme.dart';

/// 반려 고양이가 성체(3단계)까지 다 자라 '졸업'하는 순간, 화면 전체를 살짝
/// 덮으며 등장하는 축하 오버레이. [LevelUpOverlay]와 같은 팝+콘페티 톤을
/// 쓰지만, 졸업(마무리)과 새 아기고양이 시작(새로운 시작)이라는 두 가지
/// 의미를 함께 전달하도록 문구를 다르게 구성했습니다.
class GraduationCelebrationOverlay extends StatefulWidget {
  final String graduatedName;
  final String graduatedImageAsset;
  final String newBabyImageAsset;
  final VoidCallback onDismiss;

  const GraduationCelebrationOverlay({
    super.key,
    required this.graduatedName,
    required this.graduatedImageAsset,
    required this.newBabyImageAsset,
    required this.onDismiss,
  });

  @override
  State<GraduationCelebrationOverlay> createState() =>
      _GraduationCelebrationOverlayState();
}

class _GraduationCelebrationOverlayState
    extends State<GraduationCelebrationOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _popController;
  late final AnimationController _confettiController;

  @override
  void initState() {
    super.initState();
    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _popController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onDismiss,
        child: Container(
          color: Colors.black.withValues(alpha: 0.38),
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              AnimatedBuilder(
                animation: _confettiController,
                builder: (context, _) {
                  return CustomPaint(
                    size: Size.infinite,
                    painter: _GradConfettiPainter(t: _confettiController.value),
                  );
                },
              ),
              AnimatedBuilder(
                animation: _popController,
                builder: (context, child) {
                  final t = Curves.elasticOut.transform(
                    _popController.value.clamp(0.0, 1.0),
                  );
                  final fade = Curves.easeOut.transform(
                    _popController.value.clamp(0.0, 1.0),
                  );
                  return Opacity(
                    opacity: fade,
                    child: Transform.scale(scale: 0.6 + 0.4 * t, child: child),
                  );
                },
                child: _GraduationCard(
                  graduatedName: widget.graduatedName,
                  graduatedImageAsset: widget.graduatedImageAsset,
                  newBabyImageAsset: widget.newBabyImageAsset,
                  onClose: widget.onDismiss,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GraduationCard extends StatelessWidget {
  final String graduatedName;
  final String graduatedImageAsset;
  final String newBabyImageAsset;
  final VoidCallback onClose;

  const _GraduationCard({
    required this.graduatedName,
    required this.graduatedImageAsset,
    required this.newBabyImageAsset,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 300,
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.5),
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.35),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎓', style: TextStyle(fontSize: 30)),
            const SizedBox(height: 6),
            Text(
              '졸업을 축하해요!',
              style: titleFont(fontSize: 22, color: AppColors.gold),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _MiniCatCircle(imageAsset: graduatedImageAsset),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.inkSoft,
                    size: 18,
                  ),
                ),
                _MiniCatCircle(imageAsset: newBabyImageAsset, isNew: true),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '$graduatedName와 함께한 시간이\n졸업 앨범에 소중히 담겼어요',
              textAlign: TextAlign.center,
              style: pathLabelFont(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '이제 새로운 아기고양이와\n또 다른 이야기를 시작해보세요 🌱',
              textAlign: TextAlign.center,
              style: bodyFont(fontSize: 12, color: AppColors.inkSoft),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onClose,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  '새 아기고양이와 시작하기',
                  style: pathLabelFont(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniCatCircle extends StatelessWidget {
  final String imageAsset;
  final bool isNew;
  const _MiniCatCircle({required this.imageAsset, this.isNew = false});

  @override
  Widget build(BuildContext context) {
    final color = isNew ? AppColors.blobMintAccent : AppColors.gold;
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.9),
        border: Border.all(color: color, width: 2.4),
      ),
      padding: const EdgeInsets.all(6),
      child: ClipOval(child: Image.asset(imageAsset, fit: BoxFit.cover)),
    );
  }
}

class _GradConfettiPainter extends CustomPainter {
  final double t;
  static final List<_GradConfettiPiece> _pieces = List.generate(
    22,
    (i) => _GradConfettiPiece(Random(i * 61 + 5)),
  );

  _GradConfettiPainter({required this.t});

  static const _colors = [
    AppColors.gold,
    AppColors.blobMintAccent,
    AppColors.blobPeachAccent,
    AppColors.blobLavenderAccent,
    AppColors.blobRoseAccent,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _pieces) {
      final progress = (t + p.phase) % 1.0;
      final dx = p.x * size.width;
      final dy = progress * (size.height + 40) - 20;
      final paint = Paint()
        ..color = _colors[p.colorIndex].withValues(
          alpha: (0.65 * (1 - (progress - 0.5).abs() * 0.6)).clamp(0.0, 0.65),
        );
      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(progress * 6.28 * p.spin);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: p.size,
          height: p.size * 0.5,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _GradConfettiPainter oldDelegate) =>
      oldDelegate.t != t;
}

class _GradConfettiPiece {
  final double x;
  final double phase;
  final double size;
  final double spin;
  final int colorIndex;

  _GradConfettiPiece(Random rng)
    : x = rng.nextDouble(),
      phase = rng.nextDouble(),
      size = 6 + rng.nextDouble() * 6,
      spin = 1 + rng.nextDouble() * 2,
      colorIndex = rng.nextInt(5);
}
