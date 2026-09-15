import 'package:flutter/material.dart';
import '../services/meditation_completion_service.dart';
import '../services/meditation_library_store.dart';
import '../theme.dart';

class MeditationCheckIn extends StatefulWidget {
  final String guideKey;
  const MeditationCheckIn({super.key, required this.guideKey});
  @override
  State<MeditationCheckIn> createState() => _MeditationCheckInState();
}

class _MeditationCheckInState extends State<MeditationCheckIn> {
  String? _dismissed;
  String? _saved;
  bool _busy = false;
  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: MeditationCompletionService.instance.completed,
    builder: (context, event, _) {
      if (event == null ||
          event.key != widget.guideKey ||
          _dismissed == event.session)
        return const SizedBox.shrink();
      if (_saved == event.session)
        return const Padding(
          padding: EdgeInsets.all(12),
          child: Text('지금의 상태를 기록했어요. 편안한 속도로 쉬어가세요.'),
        );
      return Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.blobLavender,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '잠깐 쉬고 난 지금은 어떤가요?',
              style: bodyFont(
                fontSize: 14,
                color: AppColors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            const Text('선택하지 않아도 괜찮아요. 어떤 기분이든 완료 보상은 같아요.'),
            Wrap(
              spacing: 6,
              children: [
                for (final entry in const {
                  'better': '조금 편안해졌어요',
                  'same': '비슷해요',
                  'worse': '더 불편해요',
                }.entries)
                  ActionChip(
                    label: Text(entry.value),
                    onPressed: _busy
                        ? null
                        : () async {
                            setState(() => _busy = true);
                            try {
                              await MeditationLibraryStore.instance.checkIn(
                                event.session,
                                event.key,
                                entry.key,
                              );
                              if (mounted)
                                setState(() => _saved = event.session);
                            } catch (_) {
                              if (context.mounted)
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      '상태를 저장하지 못했어요. 완료 보상에는 영향이 없어요.',
                                    ),
                                  ),
                                );
                            } finally {
                              if (mounted) setState(() => _busy = false);
                            }
                          },
                  ),
              ],
            ),
            TextButton(
              onPressed: _busy
                  ? null
                  : () => setState(() => _dismissed = event.session),
              child: const Text('건너뛰기'),
            ),
          ],
        ),
      );
    },
  );
}
