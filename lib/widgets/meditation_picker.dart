import 'package:flutter/material.dart';
import '../theme.dart';
import '../data/solutions_data.dart';
import 'guide_steps.dart';
import 'garden_path_card.dart';

/// 추천 명상/움직임 목록 중 하나를 선택해서 실천하는 위젯.
/// 딱딱한 흰 박스 대신 버터톤 GlassBlob 위에 둥근 알약형 선택 칩을 올립니다.
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
    final matchingKeys = publishedGuides(widget.guideKeys);
    final visibleKeys = matchingKeys.isNotEmpty
        ? matchingKeys
        : publishedGuides(publishedMeditationKeys);
    return GlassBlob(
      accent: AppColors.blobButterAccent,
      background: AppColors.blobButter,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🧘 오디오 · 영상 명상',
            style: pathLabelFont(
              fontSize: 15,
              fontWeight: FontWeight.w700,
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
            children: visibleKeys.map((key) {
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
                    borderRadius: BorderRadius.circular(999),
                    gradient: active
                        ? LinearGradient(
                            colors: [
                              AppColors.blobButterAccent,
                              AppColors.blobButterAccent.withValues(alpha: 0.8),
                            ],
                          )
                        : null,
                    color: active ? null : Colors.white.withValues(alpha: 0.55),
                    border: Border.all(
                      color: active
                          ? Colors.transparent
                          : AppColors.blobButterAccent.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(guide.icon, style: const TextStyle(fontSize: 18)),
                      if (meditationMedia[key] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            meditationMedia[key]!.label,
                            textAlign: TextAlign.center,
                            style: bodyFont(
                              fontSize: 10.5,
                              color: active ? Colors.white : AppColors.inkSoft,
                            ),
                          ),
                        ),
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
          if (selectedKey != null && visibleKeys.contains(selectedKey)) ...[
            const SizedBox(height: 16),
            GuideSteps(
              guide: breathingGuide[selectedKey]!,
              guideKey: selectedKey,
            ),
          ],
        ],
      ),
    );
  }
}
