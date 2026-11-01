import 'package:flutter/material.dart';
import '../theme.dart';
import 'care_journal_screen.dart';
import 'garden_memory_book_screen.dart';
import 'self_care_screen.dart';

/// One entrance to existing records; no duplicate storage or paid gate.
class MindReviewScreen extends StatelessWidget {
  const MindReviewScreen({super.key, required this.onOpenRecords});
  final VoidCallback onOpenRecords;

  @override
  Widget build(BuildContext context) {
    void open(Widget page) => Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => page));
    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(title: const Text('지난 마음 보기')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  '남긴 마음을 천천히 돌아봐요',
                  style: titleFont(
                    fontSize: 23,
                    color: AppColors.titlePastelGreen,
                  ),
                ),
                const SizedBox(height: 8),
                const Text('읽기만 해도 괜찮아요. 필요할 때 작은 돌봄으로 이어가요.'),
                const SizedBox(height: 20),
                _entry(
                  Icons.mail_outline,
                  '내가 쓴 편지',
                  '날짜별 기록을 다시 읽어요.',
                  () {
                    Navigator.pop(context);
                    onOpenRecords();
                  },
                ),
                _entry(
                  Icons.spa_outlined,
                  '도움이 됐던 돌봄',
                  '간직한 말 · 해보고 싶은 일 · 해본 뒤의 느낌',
                  () => open(const CareJournalScreen()),
                ),
                _entry(
                  Icons.insights_outlined,
                  '마음의 흐름',
                  '주간·월간 마음 점수와 돌봄 후기를 살펴봐요.',
                  () => open(const SelfCareScreen()),
                ),
                _entry(
                  Icons.auto_stories_outlined,
                  '정원 기록집',
                  '내 문장과 나무의 기억을 한 달씩 모아봐요.',
                  () => open(const GardenMemoryBookScreen()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _entry(IconData icon, String title, String detail, VoidCallback tap) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: AppColors.catSageBg,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Icon(icon, color: AppColors.titlePastelGreen),
            title: Text(title),
            subtitle: Text(detail),
            trailing: const Icon(Icons.chevron_right),
            onTap: tap,
          ),
        ),
      );
}
