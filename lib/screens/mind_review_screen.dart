import '../l10n/app_language.dart';
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
    Localizations.localeOf(context);
    void open(Widget page) => Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => page));
    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(title: Text(tr('지난 마음 보기'))),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 620),
            child: ListView(
              padding: EdgeInsets.all(20),
              children: [
                Text(
                  tr('남긴 마음을 천천히 돌아봐요'),
                  style: titleFont(
                    fontSize: 23,
                    color: AppColors.titlePastelGreen,
                  ),
                ),
                SizedBox(height: 8),
                Text(tr('읽기만 해도 괜찮아요. 필요할 때 작은 돌봄으로 이어가요.')),
                SizedBox(height: 20),
                _entry(
                  Icons.mail_outline,
                  tr('내가 쓴 편지'),
                  tr('날짜별 기록을 다시 읽어요.'),
                  () {
                    Navigator.pop(context);
                    onOpenRecords();
                  },
                ),
                _entry(
                  Icons.spa_outlined,
                  tr('도움이 됐던 돌봄'),
                  tr('간직한 말 · 해보고 싶은 일 · 해본 뒤의 느낌'),
                  () => open(CareJournalScreen()),
                ),
                _entry(
                  Icons.insights_outlined,
                  tr('마음의 흐름'),
                  tr('주간·월간 마음 점수와 돌봄 후기를 살펴봐요.'),
                  () => open(SelfCareScreen()),
                ),
                _entry(
                  Icons.auto_stories_outlined,
                  tr("정원 기록집"),
                  tr('내 문장과 나무의 기억을 한 달씩 모아봐요.'),
                  () => open(GardenMemoryBookScreen()),
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
        padding: EdgeInsets.only(bottom: 12),
        child: Material(
          color: AppColors.catSageBg,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            contentPadding: EdgeInsets.all(16),
            leading: Icon(icon, color: AppColors.titlePastelGreen),
            title: Text(title),
            subtitle: Text(detail),
            trailing: Icon(Icons.chevron_right),
            onTap: tap,
          ),
        ),
      );
}
