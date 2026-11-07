import '../l10n/app_language.dart';
import 'package:flutter/material.dart';
import '../screens/care_journal_screen.dart';
import '../screens/garden_memory_book_screen.dart';
import '../theme.dart';

/// Two calm entry points; no forced prompt, reply badge, or purchase overlay.
class GardenContinuityShortcuts extends StatelessWidget {
  const GardenContinuityShortcuts({super.key});

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        TextButton.icon(
          key: const ValueKey('open-care-journal'),
          icon: const Icon(Icons.spa_outlined, size: 19),
          label: Text(tr("나를 돌보는 방법")),
          style: TextButton.styleFrom(foregroundColor: AppColors.catSage),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const CareJournalScreen()),
          ),
        ),
        TextButton.icon(
          key: const ValueKey('open-garden-memory-book'),
          icon: const Icon(Icons.auto_stories_outlined, size: 19),
          label: Text(tr("정원 기록집")),
          style: TextButton.styleFrom(foregroundColor: AppColors.catSage),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const GardenMemoryBookScreen(),
            ),
          ),
        ),
      ],
    );
  }
}
