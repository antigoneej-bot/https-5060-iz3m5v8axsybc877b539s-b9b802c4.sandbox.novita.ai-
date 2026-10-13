import 'package:flutter/material.dart';
import '../services/cat_care_service.dart';
import '../theme.dart';
import 'self_care_screen.dart';

/// Legacy route retained. The values are activity rewards, never mood ratings.
class MindTemperatureHistoryScreen extends StatefulWidget {
  const MindTemperatureHistoryScreen({super.key});
  @override
  State<MindTemperatureHistoryScreen> createState() =>
      _MindTemperatureHistoryScreenState();
}

class _MindTemperatureHistoryScreenState
    extends State<MindTemperatureHistoryScreen> {
  late Future<List<MapEntry<DateTime, int>>> _future;
  int _days = 7;
  @override
  void initState() {
    super.initState();
    _future = CatCareService.getTempHistory();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('돌봄 온기 기록', style: titleFont(fontSize: 22)),
      const SizedBox(height: 12),
      const Text(
        '출석·편지·돌봄으로 쌓인 활동 점수예요. 이전 기록은 그대로 보관해요.\n감정 상태나 회복 정도를 나타내는 점수가 아니에요. 구독 보상으로 100도에서 포인트로 바뀌면 온기가 낮아져 보일 수 있어요.',
      ),
      const SizedBox(height: 12),
      OutlinedButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SelfCareScreen()),
        ),
        child: const Text('직접 남긴 마음 상태 · 돌봄 후기 보기'),
      ),
      Wrap(
        spacing: 8,
        children: [
          for (final days in [7, 30])
            ChoiceChip(
              label: Text('최근 $days일'),
              selected: _days == days,
              onSelected: (_) => setState(() => _days = days),
            ),
        ],
      ),
      FutureBuilder<List<MapEntry<DateTime, int>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return TextButton(
              onPressed: () =>
                  setState(() => _future = CatCareService.getTempHistory()),
              child: const Text('기록을 불러오지 못했어요 · 다시 시도'),
            );
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final cutoff = DateTime(now.year, now.month, now.day - _days + 1);
          final rows =
              snapshot.data!
                  .where(
                    (e) => !e.key.isBefore(cutoff) && !e.key.isAfter(today),
                  )
                  .toList()
                ..sort((a, b) => b.key.compareTo(a.key));
          return Column(
            children: [
              if (rows.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('아직 돌봄 온기 기록이 없어요.'),
                ),
              for (final row in rows)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    '${row.key.year}.${row.key.month}.${row.key.day}',
                  ),
                  trailing: Text('${row.value} / 100°'),
                ),
            ],
          );
        },
      ),
    ],
  );
}
