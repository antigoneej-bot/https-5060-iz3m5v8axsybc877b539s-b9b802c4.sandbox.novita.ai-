import 'package:flutter/material.dart';
import '../models/reply_style.dart';
import '../theme.dart';

class ReplyStylePicker extends StatelessWidget {
  final ReplyStyle value;
  final ValueChanged<ReplyStyle> onChanged;
  final bool enabled;
  const ReplyStylePicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.catSageBg,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '오늘은 어떻게 곁에 있어 줄까?',
          style: bodyFont(
            fontSize: 16,
            color: AppColors.titlePastelGreen,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final style in ReplyStyle.values)
              ChoiceChip(
                label: Text(style.label),
                labelStyle: bodyFont(fontSize: 13, color: AppColors.ink),
                selectedColor: AppColors.catPeachBg,
                backgroundColor: Colors.white.withValues(alpha: 0.7),
                side: BorderSide(
                  color: AppColors.titlePastelGreen.withValues(alpha: 0.3),
                ),
                selected: value == style,
                onSelected: enabled ? (_) => onChanged(style) : null,
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(switch (value) {
          ReplyStyle.listen => '조언이나 질문을 덧붙이지 않고 들어줄게. 기본 선택이야.',
          ReplyStyle.reflect => '적어준 일과 마음을 짚어볼게. 모르는 사정은 짐작하지 않을게.',
          ReplyStyle.suggest => '마음부터 듣고, 해볼 만한 작은 방법 하나를 제안할게.',
        }, style: bodyFont(fontSize: 13, color: AppColors.inkSoft)),
        const SizedBox(height: 8),
        Text(
          '답장은 기기 안에서 준비된 문장과 편지 속 표현으로 만들어요. 복잡한 사연은 다르게 읽을 수 있어요.',
          style: bodyFont(fontSize: 12, color: AppColors.inkSoft),
        ),
      ],
    ),
  );
}
