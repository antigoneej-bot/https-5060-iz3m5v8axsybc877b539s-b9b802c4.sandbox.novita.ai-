import 'package:flutter/material.dart';
import '../theme.dart';
import 'garden_path_card.dart';

/// 마음의 온도를 기록하는 슬라이더 블롭.
/// 딱딱한 흰 박스 대신 로즈 톤 GlassBlob 위에 얹어, 따뜻한 온기가
/// 느껴지도록 합니다.
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
    return GlassBlob(
      accent: AppColors.blobRoseAccent,
      background: AppColors.blobRose,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: pathLabelFont(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${label(value)}  ·  ${value.round()}°',
            style: numberFont(fontSize: 19, color: AppColors.blobRoseAccent),
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
                        AppColors.blobRoseAccent,
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
    Color background;
    if (same) {
      message = '마음의 온도가 그대로 유지되었어요';
      accent = AppColors.blobButterAccent;
      background = AppColors.blobButter;
    } else if (improved) {
      message = '마음이 ${diff.abs().round()}도만큼 따뜻해졌어요 · 오늘도 성장했어요 🌱';
      accent = AppColors.blobPeachAccent;
      background = AppColors.blobPeach;
    } else {
      message = '마음이 ${diff.abs().round()}도만큼 차분해졌어요';
      accent = AppColors.blobPeriwinkleAccent;
      background = AppColors.blobPeriwinkle;
    }
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: GlassBlob(
        accent: accent,
        background: background,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          children: [
            Text(
              '실천 전 · 후 변화',
              style: pathLabelFont(
                fontSize: 14,
                fontWeight: FontWeight.w700,
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
          style: numberFont(fontSize: 18, color: AppColors.ink),
        ),
      ],
    );
  }
}
