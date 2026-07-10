import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/emotion_provider.dart';
import '../theme.dart';
import '../screens/monthly_report_screen.dart';

const _monthNames = [
  '',
  '1월',
  '2월',
  '3월',
  '4월',
  '5월',
  '6월',
  '7월',
  '8월',
  '9월',
  '10월',
  '11월',
  '12월',
];

/// 감정기록이 있는 달들 중 하나를 골라 월간 리포트로 이동하는 바텀시트
class MonthlyReportPickerSheet extends StatelessWidget {
  const MonthlyReportPickerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const MonthlyReportPickerSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final emotion = context.watch<EmotionProvider>();
    final months = emotion.availableMonths;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bg1,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                '🌙 마음 리포트',
                style: serifFont(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '돌아보고 싶은 달을 골라보세요',
                style: bodyFont(fontSize: 12.5, color: AppColors.inkSoft),
              ),
              const SizedBox(height: 18),
              if (months.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      '아직 기록된 감정이 없어요.\n오늘의 마음부터 기록해보세요.',
                      textAlign: TextAlign.center,
                      style: bodyFont(
                        fontSize: 13,
                        color: AppColors.inkSoft,
                        height: 1.6,
                      ),
                    ),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 360),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: months.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final (year, month) = months[i];
                      final isCurrentMonth =
                          DateTime.now().year == year &&
                          DateTime.now().month == month;
                      return Material(
                        color: AppColors.bg0,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            Navigator.of(context).pop();
                            final report = context
                                .read<EmotionProvider>()
                                .reportFor(year, month);
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    MonthlyReportScreen(report: report),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.line),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  '🌘',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    '$year년 ${_monthNames[month]}${isCurrentMonth ? ' (진행 중)' : ''}',
                                    style: bodyFont(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.inkSoft,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
