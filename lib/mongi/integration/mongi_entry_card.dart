import '../../theme.dart';
import 'mongi_experience.dart';
import 'package:flutter/material.dart';

class MongiEntryCard extends StatelessWidget {
  final VoidCallback onGoMeetCat;
  const MongiEntryCard({super.key, required this.onGoMeetCat});
  @override
  Widget build(BuildContext context) => Card(
    color: AppColors.catSageBg,
    margin: const EdgeInsets.symmetric(vertical: 8),
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const MongiExperience())),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.cardFace,
                borderRadius: BorderRadius.circular(18),
              ),
              padding: const EdgeInsets.all(8),
              child: Image.asset(
                'assets/mongi/images/cat_happy.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '몽이랑 달리기',
                    style: titleFont(
                      fontSize: 25,
                      color: AppColors.titlePastelGreen,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '마음을 만나고, 함께 정원을 가꿔요.',
                    style: bodyFont(fontSize: 13, color: AppColors.inkSoft),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_rounded,
              color: AppColors.titlePastelGreen,
              size: 20,
            ),
          ],
        ),
      ),
    ),
  );
}

/// Legacy callers enter the same experience as the current home card.
@Deprecated('Use MongiExperience')
class MongiLobbyScreen extends StatelessWidget {
  final VoidCallback onGoMeetCat;
  const MongiLobbyScreen({super.key, required this.onGoMeetCat});
  @override
  Widget build(BuildContext context) => const MongiExperience();
}
