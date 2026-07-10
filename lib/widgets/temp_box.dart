import 'package:flutter/material.dart';
import '../theme.dart';

class TempBox extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final String title;
  const TempBox({
    super.key,
    required this.value,
    required this.onChanged,
    this.title = '지금 내 마음의 온도는?',
  });

  static String label(double v) {
    if (v < 20) return '차갑게 가라앉은';
    if (v < 40) return '조금 서늘한';
    if (v < 60) return '평온한';
    if (v < 80) return '따뜻하게 데워진';
    return '뜨겁게 일렁이는';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.bg1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: serifFont(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${label(value)}  ·  ${value.round()}°',
            style: serifFont(fontSize: 20, color: AppColors.goldSoft),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 28,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  height: 16,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF6FA8DC),
                        AppColors.gold,
                        Color(0xFFD9695A),
                      ],
                    ),
                  ),
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 0,
                    activeTrackColor: Colors.transparent,
                    inactiveTrackColor: Colors.transparent,
                    thumbColor: Colors.white,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 9,
                    ),
                    overlayShape: SliderComponentShape.noOverlay,
                  ),
                  child: Slider(
                    value: value,
                    min: 0,
                    max: 100,
                    onChanged: onChanged,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '차가움',
                style: bodyFont(fontSize: 11.5, color: AppColors.inkSoft),
              ),
              Text(
                '뜨거움',
                style: bodyFont(fontSize: 11.5, color: AppColors.inkSoft),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 실천 전/후 온도 변화를 비교해서 보여주는 위젯
class TempCompareBox extends StatelessWidget {
  final double before;
  final double after;
  const TempCompareBox({super.key, required this.before, required this.after});

  @override
  Widget build(BuildContext context) {
    final diff = after - before;
    final improved = diff > 0;
    final same = diff == 0;
    String message;
    Color accent;
    if (same) {
      message = '마음의 온도가 그대로 유지되었어요';
      accent = AppColors.goldSoft;
    } else if (improved) {
      message = '마음이 ${diff.abs().round()}도만큼 따뜻해졌어요 · 오늘도 성장했어요 🌱';
      accent = const Color(0xFFD9695A);
    } else {
      message = '마음이 ${diff.abs().round()}도만큼 차분해졌어요';
      accent = const Color(0xFF6FA8DC);
    }
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.bg1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Text(
            '실천 전 · 후 변화',
            style: serifFont(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _tempPill('실천 전', before),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: accent,
                  size: 20,
                ),
              ),
              _tempPill('실천 후', after),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: bodyFont(fontSize: 12.5, color: AppColors.moon),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _tempPill(String label, double v) {
    return Column(
      children: [
        Text(label, style: bodyFont(fontSize: 11, color: AppColors.inkSoft)),
        const SizedBox(height: 4),
        Text(
          '${v.round()}°',
          style: serifFont(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}
