import 'package:flutter/material.dart';
import '../theme.dart';
import '../mongi/integration/mongi_garden_store.dart';

/// Optional entry points with persisted common-reward status.
class DailyCareCard extends StatefulWidget {
  final VoidCallback onWrite, onRest, onGarden;
  const DailyCareCard({
    super.key,
    required this.onWrite,
    required this.onRest,
    required this.onGarden,
  });
  @override
  State<DailyCareCard> createState() => _DailyCareCardState();
}

class _DailyCareCardState extends State<DailyCareCard>
    with WidgetsBindingObserver {
  bool _loaded = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  Future<void> _load() async {
    try {
      await MongiGardenStore.instance.reload();
      if (mounted)
        setState(() {
          _loaded = true;
          _failed = false;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _loaded = false;
          _failed = true;
        });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<MongiGardenData>(
    valueListenable: MongiGardenStore.instance,
    builder: (context, data, _) {
      final done =
          _loaded &&
          data.careDays.contains(MongiGardenData.dayKey(DateTime.now()));
      final choices = [
        (icon: Icons.edit_note_rounded, label: '편지 쓰기', tap: widget.onWrite),
        (icon: Icons.spa_outlined, label: '조용히 쉬기', tap: widget.onRest),
      ];
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.catSageBg.withValues(alpha: .72),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.catSage.withValues(alpha: .18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '오늘의 마음 돌봄',
              style: titleFont(fontSize: 21, color: AppColors.titlePastelGreen),
            ),
            const SizedBox(height: 6),
            Text(
              '지금 끌리는 것 하나면 충분해요.',
              style: bodyFont(fontSize: 13, color: AppColors.inkSoft),
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, box) {
                final columns =
                    box.maxWidth < 240 ||
                        MediaQuery.textScalerOf(context).scale(13) > 26
                    ? 1
                    : 2;
                final width = (box.maxWidth - (columns - 1) * 8) / columns;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final choice in choices)
                      SizedBox(
                        width: width,
                        child: OutlinedButton(
                          onPressed: choice.tap,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 12,
                            ),
                            foregroundColor: AppColors.catSage,
                            backgroundColor: Colors.white.withValues(alpha: .6),
                            side: BorderSide(color: AppColors.sageLine),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(choice.icon, size: 23),
                              const SizedBox(height: 7),
                              Text(
                                choice.label,
                                textAlign: TextAlign.center,
                                style: bodyFont(
                                  fontSize: 12,
                                  color: AppColors.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 6),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: widget.onGarden,
                  icon: const Icon(Icons.local_florist_outlined, size: 17),
                  label: const Text('내 정원으로 가기'),
                ),
                if (_failed)
                  TextButton(onPressed: _load, child: const Text('돌봄 기록 다시 확인'))
                else if (_loaded && done)
                  Text(
                    '오늘의 돌봄 완료 🌱',
                    style: bodyFont(fontSize: 12, color: AppColors.inkSoft),
                  ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
