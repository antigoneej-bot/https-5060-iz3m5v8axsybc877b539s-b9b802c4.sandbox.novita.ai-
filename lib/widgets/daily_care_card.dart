import 'package:flutter/material.dart';
import '../theme.dart';
import '../mongi/integration/mongi_garden_store.dart';

/// Optional entry points with persisted common-reward status.
class DailyCareCard extends StatefulWidget {
  final VoidCallback onWrite, onRest, onRun, onGarden;
  const DailyCareCard({
    super.key,
    required this.onWrite,
    required this.onRest,
    required this.onRun,
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

  Widget _choice({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Material(
      color: color,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, color: AppColors.titlePastelGreen, size: 25),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: bodyFont(
                        fontSize: 16,
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: bodyFont(fontSize: 13, color: AppColors.inkSoft),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right,
                color: AppColors.titlePastelGreen,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<MongiGardenData>(
    valueListenable: MongiGardenStore.instance,
    builder: (context, data, _) {
      final done =
          _loaded &&
          data.careDays.contains(MongiGardenData.dayKey(DateTime.now()));
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.catSageBg,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '오늘의 마음 돌봄',
              style: bodyFont(
                fontSize: 13,
                color: AppColors.titlePastelGreen,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '오늘은 어떻게\n마음을 돌볼까요?',
              style: titleFont(fontSize: 29, color: AppColors.titlePastelGreen),
            ),
            const SizedBox(height: 6),
            Text(
              done ? '정원에서 쉬어도, 다른 활동을 골라도 좋아요.' : '지금 끌리는 것 하나면 충분해요.',
              style: bodyFont(fontSize: 14, color: AppColors.inkSoft),
            ),
            _choice(
              icon: Icons.edit_note_rounded,
              title: '편지 쓰기',
              subtitle: '감정 고양이를 골라 마음을 남겨요',
              color: AppColors.catPeachBg,
              onTap: widget.onWrite,
            ),
            _choice(
              icon: Icons.spa_outlined,
              title: '조용히 쉬기',
              subtitle: '나에게 맞는 호흡·명상을 골라요',
              color: AppColors.catLavenderBg,
              onTap: widget.onRest,
            ),
            _choice(
              icon: Icons.pets_outlined,
              title: '몽이와 달리기',
              subtitle: '감정을 고르고 몽이와 한 판 달려요',
              color: AppColors.cardFace2,
              onTap: widget.onRun,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: widget.onGarden,
              icon: const Icon(Icons.local_florist_outlined),
              label: const Text('내 정원으로 가기'),
            ),
            const SizedBox(height: 14),
            if (_failed)
              TextButton(onPressed: _load, child: const Text('오늘의 보상 상태 다시 확인'))
            else if (!_loaded)
              Text(
                '오늘의 돌봄 기록을 확인하고 있어요.',
                style: bodyFont(fontSize: 12, color: AppColors.inkSoft),
              )
            else
              Text(
                done
                    ? '오늘의 공통 돌봄 보상을 받았어요 🌱'
                    : '편지·명상·고요 모드는 하루 한 번 씨앗 1개와 빛의 정수 20개를 줘요. 달리기는 게임 보상을 받아요.',
                style: bodyFont(fontSize: 12, color: AppColors.inkSoft),
              ),
          ],
        ),
      );
    },
  );
}
