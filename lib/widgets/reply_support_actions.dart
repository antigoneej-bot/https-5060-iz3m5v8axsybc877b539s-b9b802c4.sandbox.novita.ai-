import 'package:flutter/material.dart';
import '../mongi/screens/mental_health_support_screen.dart';
import '../services/reply_safety.dart';

/// Always available independently of reply arrival, generation, or payment.
/// Opening this card only navigates inside the app; the user chooses any contact.
class ReplySupportActions extends StatelessWidget {
  final String letterText;
  const ReplySupportActions({super.key, required this.letterText});

  @override
  Widget build(BuildContext context) {
    final need = ReplySafety.assess(letterText);
    if (need == ReplySupportNeed.none) return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              ReplySafety.response(need),
              style: const TextStyle(fontSize: 14, height: 1.6),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => const MentalHealthSupportScreen(),
                ),
              ),
              icon: const Icon(Icons.support_agent),
              label: const Text('지금 도움받을 곳 보기'),
            ),
          ],
        ),
      ),
    );
  }
}
