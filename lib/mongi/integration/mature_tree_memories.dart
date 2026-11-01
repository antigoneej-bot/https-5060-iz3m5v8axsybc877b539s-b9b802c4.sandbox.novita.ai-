import 'package:flutter/material.dart';
import 'plant_memory.dart';

/// A read-only view over saved memories, never an automatic public post.
class MatureTreeMemories extends StatelessWidget {
  const MatureTreeMemories({
    super.key,
    required this.entries,
    required this.anniversaryOn,
    required this.onWrite,
    required this.onMonth,
    required this.onHistory,
    this.now,
  });
  final List<PlantMemoryEntry> entries;
  final String? anniversaryOn;
  final VoidCallback? onWrite;
  final VoidCallback? onHistory;
  final ValueChanged<DateTime>? onMonth;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final today = now ?? DateTime.now();
    final sorted = [...entries]..sort((a, b) => b.on.compareTo(a.on));
    final months = <String, int>{};
    for (final entry in sorted) {
      final month = entry.on.substring(0, 7);
      months[month] = (months[month] ?? 0) + 1;
    }
    final start = anniversaryOn == null
        ? null
        : parsePlantMemoryDay(anniversaryOn);
    final days = start == null
        ? null
        : DateTime.utc(today.year, today.month, today.day)
                  .difference(DateTime.utc(start.year, start.month, start.day))
                  .inDays +
              1;
    final next = days == null
        ? null
        : [30, 100, 365].where((d) => d > days).firstOrNull;
    return Card(
      key: const ValueKey('mature-tree-memories'),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '다 자란 나무, 계속 쌓이는 추억',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('내가 남긴 추억 ${entries.length}개 · 나만 볼 수 있어요'),
            if (days != null && days > 0)
              Text(
                '함께한 $days일${next == null ? '' : ' · $next일까지 ${next - days}일'}',
              ),
            if (days != null && days <= 0) Text('기념 시작일 · $anniversaryOn'),
            if (sorted.isEmpty)
              const Text('크기는 다 자랐지만 이야기는 계속돼요. 오늘 기억하고 싶은 한 장면을 남겨 보세요.'),
            for (final entry in sorted.take(3))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Text(
                  '${entry.on}\n${entry.note}',
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            Wrap(
              spacing: 6,
              children: [
                for (final month in months.entries)
                  ActionChip(
                    label: Text('${month.key} · ${month.value}개'),
                    onPressed:
                        onMonth == null ||
                            DateTime.parse(
                              '${month.key}-01',
                            ).isAfter(DateTime(today.year, today.month))
                        ? null
                        : () => onMonth!(DateTime.parse('${month.key}-01')),
                  ),
              ],
            ),
            if (months.isNotEmpty) const Text('달을 누르면 그 달의 정원 기록집을 열어요.'),
            Wrap(
              spacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed: onWrite,
                  child: const Text('오늘의 추억 더하기'),
                ),
                if (entries.isNotEmpty)
                  TextButton(
                    onPressed: onHistory,
                    child: const Text('모든 추억 보기'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
