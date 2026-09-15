import 'package:flutter/material.dart';
import '../../theme.dart';
import 'garden_moments.dart';
import 'mongi_garden_data.dart';

class GardenMomentsCard extends StatelessWidget {
  final MongiGardenData data;
  final int catCount;
  const GardenMomentsCard({
    super.key,
    required this.data,
    required this.catCount,
  });
  @override
  Widget build(BuildContext context) {
    final opened = gardenMoments
        .where((m) => m.isAvailable(data, catCount))
        .length;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.catSageBg,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '우리 정원에 쌓인 이야기',
            style: titleFont(fontSize: 25, color: AppColors.titlePastelGreen),
          ),
          const SizedBox(height: 8),
          Text(
            '편지를 쓰고, 쉬고, 달리며 생긴 작은 장면들이에요.',
            style: bodyFont(fontSize: 14, color: AppColors.inkSoft),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            icon: const Icon(Icons.auto_stories_outlined),
            label: Text('이야기 펼치기 · $opened / ${gardenMoments.length}'),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    GardenMomentsScreen(data: data, catCount: catCount),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GardenMomentsScreen extends StatelessWidget {
  final MongiGardenData data;
  final int catCount;
  const GardenMomentsScreen({
    super.key,
    required this.data,
    required this.catCount,
  });
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('우리 정원의 작은 이야기')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          '마음이 가는 장면부터 읽어요.',
          style: titleFont(fontSize: 27, color: AppColors.titlePastelGreen),
        ),
        const SizedBox(height: 8),
        Text(
          '순서대로 하지 않아도, 매일 오지 않아도 괜찮아요.\n모든 작은 이야기는 무료예요.',
          style: bodyFont(fontSize: 14, color: AppColors.inkSoft),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < gardenMoments.length; i++)
          _chapter(context, gardenMoments[i], i),
      ],
    ),
  );
  Widget _chapter(BuildContext context, GardenMoment moment, int index) {
    final available = moment.isAvailable(data, catCount);
    return Card(
      color: [
        AppColors.catSageBg,
        AppColors.catPeachBg,
        AppColors.catLavenderBg,
        AppColors.cardFace2,
      ][index % 4],
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 12,
        ),
        title: Text(
          moment.title,
          style: bodyFont(
            fontSize: 17,
            color: AppColors.titlePastelGreen,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            available ? '언제든 읽을 수 있어요' : moment.condition,
            style: bodyFont(fontSize: 13, color: AppColors.inkSoft),
          ),
        ),
        trailing: Icon(
          available ? Icons.menu_book_outlined : Icons.lock_outline,
          color: AppColors.titlePastelGreen,
        ),
        onTap: available
            ? () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GardenMomentReader(moment: moment),
                ),
              )
            : null,
      ),
    );
  }
}

class GardenMomentReader extends StatelessWidget {
  final GardenMoment moment;
  const GardenMomentReader({super.key, required this.moment});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('정원의 한 장면')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.catSageBg,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              moment.title,
              style: titleFont(fontSize: 30, color: AppColors.titlePastelGreen),
            ),
            const SizedBox(height: 22),
            SelectableText(
              moment.body,
              style: bodyFont(fontSize: 17, color: AppColors.ink, height: 1.9),
            ),
            const SizedBox(height: 22),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('다른 이야기 보기'),
            ),
          ],
        ),
      ),
    ),
  );
}
