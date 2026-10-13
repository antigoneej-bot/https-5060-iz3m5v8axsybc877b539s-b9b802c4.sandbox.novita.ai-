import 'package:flutter/material.dart';
import '../services/meditation_sleep_service.dart';
import '../theme.dart';

class MeditationSleepControls extends StatelessWidget {
  final Object owner;
  final bool allowRepeat;
  const MeditationSleepControls({
    super.key,
    required this.owner,
    this.allowRepeat = false,
  });
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: MeditationSleepService.instance,
    builder: (context, _) {
      final s = MeditationSleepService.instance;
      if (!identical(s.owner, owner)) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            '자동 종료 · 마지막 10초는 소리가 서서히 작아져요',
            style: bodyFont(fontSize: 12, color: AppColors.inkSoft),
          ),
          Wrap(
            spacing: 6,
            children: [
              for (final m in <int?>[null, 15, 30, 60])
                ActionChip(
                  label: Text(m == null ? '타이머 해제' : '$m분'),
                  onPressed: () async {
                    try {
                      await s.setTimer(m);
                    } catch (_) {
                      if (context.mounted)
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('타이머 설정을 확인하지 못했어요. 다시 시도해 주세요.'),
                          ),
                        );
                    }
                  },
                ),
            ],
          ),
          if (s.deadline != null)
            Text(
              '종료까지 약 ${(s.remaining.inSeconds / 60).ceil().clamp(0, 60)}분',
              style: bodyFont(fontSize: 12, color: AppColors.ink),
            ),
          if (allowRepeat)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('자연음 반복 재생'),
              value: s.repeat,
              onChanged: s.setRepeat,
            ),
          Text(
            '일시정지하거나 다른 명상으로 바꾸면 타이머가 해제돼요.',
            style: bodyFont(fontSize: 11, color: AppColors.inkSoft),
          ),
        ],
      );
    },
  );
}
