import 'package:flutter/material.dart';
import '../services/meditation_completion_service.dart';

class MeditationSaveStatus extends StatelessWidget {
  const MeditationSaveStatus({super.key});
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String?>(
    valueListenable: MeditationCompletionService.instance.saveProblem,
    builder: (context, problem, _) => problem == null
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Text(problem),
                TextButton(
                  onPressed: () => MeditationCompletionService.instance.retry(),
                  child: const Text('완료 기록 저장 다시 시도'),
                ),
              ],
            ),
          ),
  );
}
