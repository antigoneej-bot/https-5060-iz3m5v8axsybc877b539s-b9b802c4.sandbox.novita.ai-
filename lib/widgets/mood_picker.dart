import 'package:flutter/material.dart';
import '../theme.dart';
import 'garden_path_card.dart';

/// 오늘의 기분을 나타내는 이모티콘 후보들. 날씨 아이콘을 고르듯 지금
/// 마음과 가장 닮은 하나를 선택할 수 있습니다.
class MoodOption {
  final String emoji;
  final String label;
  const MoodOption(this.emoji, this.label);
}

const List<MoodOption> kMoodOptions = [
  MoodOption('☀️', '맑음'),
  MoodOption('🌤️', '괜찮음'),
  MoodOption('⛅', '그저 그럼'),
  MoodOption('🌧️', '우울함'),
  MoodOption('⛈️', '힘듦'),
  MoodOption('🌪️', '화남'),
  MoodOption('❄️', '지침'),
  MoodOption('🌈', '설렘'),
  MoodOption('😊', '행복'),
  MoodOption('😢', '슬픔'),
  MoodOption('😴', '무기력'),
  MoodOption('😌', '평온'),
];

/// 날씨처럼 오늘의 기분을 고르는 이모티콘 선택 위젯. 글을 쓰기 힘들거나
/// 귀찮을 때는 이 위젯에서 이모티콘 하나만 골라도 그날의 기록으로
/// 대체할 수 있습니다.
class MoodPicker extends StatelessWidget {
  final String? selectedEmoji;
  final ValueChanged<String?> onChanged;
  const MoodPicker({
    super.key,
    required this.selectedEmoji,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GlassBlob(
      accent: AppColors.blobButterAccent,
      background: AppColors.blobButter,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '오늘 기분은 날씨처럼 어땠나요?',
            style: pathLabelFont(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '글쓰기가 힘들거나 귀찮다면, 이모티콘 하나로 대신 남겨보세요',
            style: bodyFont(fontSize: 11.5, color: AppColors.inkSoft),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: kMoodOptions.map((opt) {
              final selected = opt.emoji == selectedEmoji;
              return GestureDetector(
                onTap: () => onChanged(selected ? null : opt.emoji),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected
                          ? AppColors.blobButterAccent
                          : Colors.transparent,
                      width: 1.4,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(opt.emoji, style: const TextStyle(fontSize: 22)),
                      const SizedBox(height: 3),
                      Text(
                        opt.label,
                        style: bodyFont(
                          fontSize: 9.5,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// 기록(history)에서 이모티콘만으로 남긴 편지를 보여줄 때 쓰는 헬퍼.
String moodLabelFor(String emoji) {
  for (final opt in kMoodOptions) {
    if (opt.emoji == emoji) return opt.label;
  }
  return '';
}
