import 'package:flutter/material.dart';
import '../theme.dart';
import '../data/solutions_data.dart';
import 'guide_steps.dart';

/// 추천 명상/움직임 목록 중 하나를 선택해서 실천하는 위젯
class MeditationPicker extends StatefulWidget {
  final List<String> guideKeys;
  final ValueChanged<String?>? onSelected;
  const MeditationPicker({super.key, required this.guideKeys, this.onSelected});

  @override
  State<MeditationPicker> createState() => _MeditationPickerState();
}

class _MeditationPickerState extends State<MeditationPicker> {
  String? selectedKey;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.bg1,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🧘 추천 명상 · 움직임',
            style: serifFont(
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '마음이 편안해지는 방법을 하나 골라 실천해보세요',
            style: bodyFont(fontSize: 11.5, color: AppColors.inkSoft),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.guideKeys.map((key) {
              final guide = breathingGuide[key]!;
              final active = selectedKey == key;
              return GestureDetector(
                onTap: () => setState(() {
                  selectedKey = active ? null : key;
                  widget.onSelected?.call(selectedKey);
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: active
                        ? const LinearGradient(
                            colors: [AppColors.goldSoft, AppColors.gold],
                          )
                        : null,
                    color: active ? null : AppColors.bg0,
                    border: Border.all(
                      color: active ? Colors.transparent : AppColors.line,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(guide.icon, style: const TextStyle(fontSize: 18)),
                      const SizedBox(height: 4),
                      Text(
                        guide.title,
                        textAlign: TextAlign.center,
                        style: bodyFont(
                          fontSize: 12,
                          color: active ? Colors.white : AppColors.ink,
                          fontWeight: active
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          if (selectedKey != null) ...[
            const SizedBox(height: 16),
            GuideSteps(guide: breathingGuide[selectedKey]!),
          ],
        ],
      ),
    );
  }
}
