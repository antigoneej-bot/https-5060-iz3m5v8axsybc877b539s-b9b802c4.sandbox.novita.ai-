import 'dart:math';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/cat_care_state.dart';
import '../utils/korean_particle.dart';

/// 반려 고양이가 다음 성장 단계로 올라간 순간, 화면 전체를 살짝 덮으며
/// 등장하는 축하 오버레이. 반짝임 + 살짝 튀어오르는(팝) 등장 애니메이션과
/// 콘페티(색종이) 흩날림으로 '레벨업'의 기쁨을 짧고 가볍게 전달합니다.
/// 힐링 가든 톤에 맞춰 요란하지 않고 파스텔하게 표현했습니다.
class LevelUpOverlay extends StatefulWidget {
  final CatGrowthStage stage;
  final String companionName;
  final String imageAsset;
  final VoidCallback onDismiss;

  const LevelUpOverlay({
    super.key,
    required this.stage,
    required this.companionName,
    required this.imageAsset,
    required this.onDismiss,
  });

  @override
  State<LevelUpOverlay> createState() => _LevelUpOverlayState();
}

class _LevelUpOverlayState extends State<LevelUpOverlay>
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

  String get _stageEmoji {
    switch (widget.stage) {
      case CatGrowthStage.baby:
        return '🐾';
      case CatGrowthStage.teen:
        return '🌱';
      case CatGrowthStage.young:
        return '🌿';
      case CatGrowthStage.adult:
        return '🌟';
    }
  }

  String get _stageLabel {
    switch (widget.stage) {
      case CatGrowthStage.baby:
        return '0단계 · 아기 고양이';
      case CatGrowthStage.teen:
        return '1단계 · 소년 고양이';
      case CatGrowthStage.young:
        return '2단계 · 청년 고양이';
      case CatGrowthStage.adult:
        return '3단계 · 다 자란 고양이';
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.companionName;
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
              // 은은한 색종이 흩날림
              AnimatedBuilder(
                animation: _confettiController,
                builder: (context, _) {
                  return CustomPaint(
                    size: Size.infinite,
                    painter: _ConfettiPainter(t: _confettiController.value),
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
                child: _LevelUpCard(
                  imageAsset: widget.imageAsset,
                  stageEmoji: _stageEmoji,
                  stageLabel: _stageLabel,
                  name: name,
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

class _LevelUpCard extends StatelessWidget {
  final String imageAsset;
  final String stageEmoji;
  final String stageLabel;
  final String name;
  final VoidCallback onClose;

  const _LevelUpCard({
    required this.imageAsset,
    required this.stageEmoji,
    required this.stageLabel,
    required this.name,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // 카드 내부 탭은 배경 닫기로 전파되지 않도록
      onTap: () {},
      child: Container(
        width: 280,
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: AppColors.blobButterAccent.withValues(alpha: 0.5),
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.blobButterAccent.withValues(alpha: 0.35),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(stageEmoji, style: const TextStyle(fontSize: 30)),
            const SizedBox(height: 6),
            Text(
              '레벨업!',
              style: titleFont(fontSize: 22, color: AppColors.blobPeachAccent),
            ),
            const SizedBox(height: 12),
            _BouncingImage(imageAsset: imageAsset),
            const SizedBox(height: 14),
            Text(
              '$name${topicParticle(name)}\n$stageLabel로 자라났어요',
              textAlign: TextAlign.center,
              style: pathLabelFont(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '꾸준히 돌봐준 마음이 모여\n이렇게 자라났어요 🌷',
              textAlign: TextAlign.center,
              style: bodyFont(fontSize: 12, color: AppColors.inkSoft),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onClose,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blobButterAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  '고마워, 앞으로도 잘 부탁해',
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

/// 카드 안에서 살짝 통통 튀며 반짝이는 간단한 움직임의 고양이 이미지.
class _BouncingImage extends StatefulWidget {
  final String imageAsset;
  const _BouncingImage({required this.imageAsset});

  @override
  State<_BouncingImage> createState() => _BouncingImageState();
}

class _BouncingImageState extends State<_BouncingImage>
    with TickerProviderStateMixin {
  late final AnimationController _bounceController;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bounceController,
      builder: (context, child) {
        final t = _bounceController.value;
        final dy = -6 * sin(t * pi);
        final scale = 1.0 + 0.03 * sin(t * pi);
        return Transform.translate(
          offset: Offset(0, dy),
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: Container(
        width: 128,
        height: 128,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              AppColors.blobButter.withValues(alpha: 0.9),
              AppColors.blobButter.withValues(alpha: 0.3),
            ],
          ),
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(10),
        child: ClipOval(
          child: Image.asset(widget.imageAsset, fit: BoxFit.cover),
        ),
      ),
    );
  }
}

/// 파스텔 톤 색종이 조각이 위에서 아래로 은은하게 흩날리는 간단한 커스텀 페인터.
class _ConfettiPainter extends CustomPainter {
  final double t;
  static final List<_ConfettiPiece> _pieces = List.generate(
    22,
    (i) => _ConfettiPiece(Random(i * 97 + 3)),
  );

  _ConfettiPainter({required this.t});

  static const _colors = [
    AppColors.blobMintAccent,
    AppColors.blobPeachAccent,
    AppColors.blobLavenderAccent,
    AppColors.blobRoseAccent,
    AppColors.blobButterAccent,
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
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.t != t;
}

class _ConfettiPiece {
  final double x;
  final double phase;
  final double size;
  final double spin;
  final int colorIndex;

  _ConfettiPiece(Random rng)
    : x = rng.nextDouble(),
      phase = rng.nextDouble(),
      size = 6 + rng.nextDouble() * 6,
      spin = 1 + rng.nextDouble() * 2,
      colorIndex = rng.nextInt(5);
}
