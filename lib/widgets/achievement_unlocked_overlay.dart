import 'dart:math';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/cat_achievement.dart';

/// 새 뱃지를 달성한 순간, 화면 위쪽에서 살짝 튀어나오듯 등장하는 작은
/// 축하 배너. [LevelUpOverlay]보다 훨씬 가볍고 짧게 스치듯 지나가는
/// 톤으로, 매번 화면을 다 덮지 않아도 되는 소소한 성취를 표현합니다.
class AchievementUnlockedOverlay extends StatefulWidget {
  final CatAchievement achievement;
  final VoidCallback onDismiss;

  const AchievementUnlockedOverlay({
    super.key,
    required this.achievement,
    required this.onDismiss,
  });

  @override
  State<AchievementUnlockedOverlay> createState() =>
      _AchievementUnlockedOverlayState();
}

class _AchievementUnlockedOverlayState extends State<AchievementUnlockedOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _sparkleController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    Future.delayed(const Duration(milliseconds: 2800), () {
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
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.achievement;
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.97),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppColors.blobButterAccent.withValues(alpha: 0.5),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.blobButterAccent.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  AnimatedBuilder(
                    animation: _sparkleController,
                    builder: (context, child) {
                      final s =
                          1.0 + 0.08 * sin(_sparkleController.value * 2 * pi);
                      return Transform.scale(scale: s, child: child);
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.blobButter.withValues(alpha: 0.95),
                            AppColors.blobButter.withValues(alpha: 0.5),
                          ],
                        ),
                      ),
                      child: Text(
                        a.emoji,
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🎉 새 뱃지 달성!',
                          style: bodyFont(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.blobButterAccent,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          a.title,
                          style: pathLabelFont(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        Text(
                          a.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: bodyFont(
                            fontSize: 10.5,
                            color: AppColors.inkSoft,
                          ),
                        ),
                      ],
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
