import '../l10n/app_language.dart';
import 'package:flutter/material.dart';
import '../models/care_next_step.dart';
import '../theme.dart';

class CareNextStepCard extends StatelessWidget {
  const CareNextStepCard({
    super.key,
    required this.summary,
    required this.onRepeat,
    required this.onFeedback,
    required this.onChoose,
    required this.onGarden,
    this.busy = false,
  });
  final CareNextStep summary;
  final VoidCallback onRepeat, onFeedback, onChoose, onGarden;
  final bool busy;
  @override
  Widget build(BuildContext context) => Card(
    color: AppColors.catSageBg,
    margin: const EdgeInsets.only(bottom: 18),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr("오늘 다시 꺼내볼 돌봄"),
            style: titleFont(fontSize: 20, color: AppColors.ink),
          ),
          const SizedBox(height: 8),
          if (summary.awaitingFeedback != null) ...[
            Text(
              tr("해봤다고 남긴 “{0}”, 어떠셨나요?", [
                summary.awaitingFeedback!.actionLabel,
              ]),
            ),
            TextButton(
              onPressed: busy ? null : onFeedback,
              child: Text(tr("해본 뒤의 느낌 남기기")),
            ),
          ],
          if (summary.suggested != null) ...[
            Text('“${summary.suggested!.actionLabel}”'),
            if (summary.suggested!.contextLabel != null)
              Text(tr("당시 상황: {0}", [summary.suggested!.contextLabel])),
            Text(
              tr("최근 30일에 남긴 후기 {0}회 중 {1}회는 도움이 됐다고 남겼어요.", [
                summary.reviewed,
                summary.helped,
              ]),
            ),
            const SizedBox(height: 6),
            Text(
              tr("지난 경험이에요. 오늘은 다른 것을 골라도 괜찮아요."),
              style: TextStyle(fontSize: 12),
            ),
            FilledButton(
              onPressed: busy ? null : onRepeat,
              child: Text(tr("다시 해볼 계획 남기기")),
            ),
          ] else
            Text(tr("최근에 도움이 됐다고 남긴 돌봄이 아직 없어요. 지금 끌리는 것부터 골라보세요.")),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              TextButton(
                onPressed: busy ? null : onChoose,
                child: Text(tr("다른 돌봄 고르기")),
              ),
              TextButton(
                onPressed: busy ? null : onGarden,
                child: Text(tr("정원에서 쉬기")),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
