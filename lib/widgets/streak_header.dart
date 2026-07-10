import 'package:flutter/material.dart';
import '../theme.dart';

class StreakHeader extends StatelessWidget {
  final int streak;
  const StreakHeader({super.key, required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.bg1,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 800),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFFF1D6),
                ),
                child: ClipOval(
                  child: Align(
                    alignment: Alignment.center,
                    child: Transform.scale(
                      scale: value,
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            center: Alignment(-0.3, -0.4),
                            colors: [
                              Color(0xFFFFF6DF),
                              AppColors.goldSoft,
                              AppColors.gold,
                            ],
                            stops: [0, 0.55, 1],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 16),
          RichText(
            text: TextSpan(
              style: bodyFont(fontSize: 13.5, color: AppColors.moon),
              children: [
                TextSpan(
                  text: '$streak',
                  style: numberFont(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: AppColors.goldSoft,
                  ),
                ),
                const TextSpan(text: '일째 함께하는 중'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
