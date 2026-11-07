import 'package:flutter/material.dart';
import '../theme.dart';

/// 돌봄 항목을 완료했을 때(몸 돌보기 4가지 완료, 또는 오늘의 돌봄 8가지 모두
/// 완료) 화면 위쪽에서 살짝 튀어나오듯 등장하는 축하 말풍선.
/// [AchievementUnlockedOverlay]와 같은 톤으로, 짧게 스치듯 지나가며 자동으로
/// 사라집니다.
class CareCelebrationOverlay extends StatefulWidget {
  final String emoji;
  final String message;
  final Color accent;
  final Color background;
  final VoidCallback onDismiss;

  const CareCelebrationOverlay({
    super.key,
    required this.emoji,
    required this.message,
    required this.accent,
    required this.background,
    required this.onDismiss,
  });

  @override
  State<CareCelebrationOverlay> createState() => _CareCelebrationOverlayState();
}

class _CareCelebrationOverlayState extends State<CareCelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..forward();
    Future.delayed(const Duration(milliseconds: 2600), () {
      if (mounted) _dismiss();
    });
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 18,
      left: 16,
      right: 16,
      child: SafeArea(
        bottom: false,
        child: GestureDetector(
          onTap: _dismiss,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final t = Curves.easeOutBack.transform(
                _controller.value.clamp(0.0, 1.0),
              );
              return Opacity(
                opacity: _controller.value.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, -24 * (1 - t)),
                  child: child,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                color: widget.background.withValues(alpha: 0.97),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: widget.accent.withValues(alpha: 0.55),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.accent.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(widget.emoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: pathLabelFont(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
