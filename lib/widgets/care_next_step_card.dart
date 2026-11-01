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
            '오늘 다시 꺼내볼 돌봄',
            style: titleFont(fontSize: 20, color: AppColors.ink),
          ),
          const SizedBox(height: 8),
          if (summary.awaitingFeedback != null) ...[
            Text('해봤다고 남긴 “${summary.awaitingFeedback!.actionLabel}”, 어떠셨나요?'),
            TextButton(
              onPressed: busy ? null : onFeedback,
              child: const Text('해본 뒤의 느낌 남기기'),
            ),
          ],
          if (summary.suggested != null) ...[
            Text('“${summary.suggested!.actionLabel}”'),
            if (summary.suggested!.contextLabel != null)
              Text('당시 상황: ${summary.suggested!.contextLabel}'),
            Text(
              '최근 30일에 남긴 후기 ${summary.reviewed}회 중 ${summary.helped}회는 도움이 됐다고 남겼어요.',
            ),
            const SizedBox(height: 6),
            const Text(
              '지난 경험이에요. 오늘은 다른 것을 골라도 괜찮아요.',
              style: TextStyle(fontSize: 12),
            ),
            FilledButton(
              onPressed: busy ? null : onRepeat,
              child: const Text('다시 해볼 계획 남기기'),
            ),
          ] else
            const Text('최근에 도움이 됐다고 남긴 돌봄이 아직 없어요. 지금 끌리는 것부터 골라보세요.'),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              TextButton(
                onPressed: busy ? null : onChoose,
                child: const Text('다른 돌봄 고르기'),
              ),
              TextButton(
                onPressed: busy ? null : onGarden,
                child: const Text('정원에서 쉬기'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
