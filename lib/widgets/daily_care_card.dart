import 'dart:math';
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
    with TickerProviderStateMixin, WidgetsBindingObserver {
  bool _loaded = false;
  bool _failed = false;
  late final AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 다른 정원 카드들(GardenPathCard, GlassBlob)과 같은 톤으로, 아주
    // 미세하게 위아래로 둥실거리는 느낌을 줍니다.
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4600),
    )..repeat(reverse: true);
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
    _floatController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// 손으로 다듬은 듯한 유기적인 블롭 모서리 - 다른 정원 산책로 카드들과
  /// 같은 느낌을 주기 위해 모서리 반경을 서로 다르게 줍니다.
  BorderRadius _blobRadius() {
    return const BorderRadius.only(
      topLeft: Radius.circular(42),
      topRight: Radius.circular(30),
      bottomLeft: Radius.circular(28),
      bottomRight: Radius.circular(46),
    );
  }

  Widget _choice({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color background,
    required Color accent,
    required VoidCallback onTap,
  }) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                background.withValues(alpha: 0.95),
                background.withValues(alpha: 0.62),
              ],
            ),
            border: Border.all(
              color: accent.withValues(alpha: 0.3),
              width: 1.1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.6),
                  border: Border.all(color: accent.withValues(alpha: 0.35)),
                ),
                child: Icon(icon, color: accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: pathLabelFont(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: bodyFont(fontSize: 11.5, color: AppColors.inkSoft),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.arrow_forward_rounded, color: accent, size: 18),
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
      return AnimatedBuilder(
        animation: _floatController,
        builder: (context, child) {
          final t = _floatController.value;
          final dy = sin(t * pi) * 3.2;
          final angle = sin(t * pi) * 0.008;
          return Transform.translate(
            offset: Offset(0, dy),
            child: Transform.rotate(angle: angle, child: child),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: _blobRadius(),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.catSageBg.withValues(alpha: 0.95),
                AppColors.catSageBg.withValues(alpha: 0.58),
              ],
            ),
            border: Border.all(
              color: AppColors.catSage.withValues(alpha: 0.28),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.catSage.withValues(alpha: 0.16),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
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
                background: AppColors.catPeachBg,
                accent: AppColors.catPeach,
                onTap: widget.onWrite,
              ),
              _choice(
                icon: Icons.spa_outlined,
                title: '조용히 쉬기',
                subtitle: '나에게 맞는 호흡·명상을 골라요',
                background: AppColors.catLavenderBg,
                accent: AppColors.catLavender,
                onTap: widget.onRest,
              ),
              _choice(
                icon: Icons.pets_outlined,
                title: '몽이와 달리기',
                subtitle: '감정을 고르고 몽이와 한 판 달려요',
                background: AppColors.cardFace2,
                accent: AppColors.goldSoft,
                onTap: widget.onRun,
              ),
              const SizedBox(height: 14),
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
        ),
      );
    },
  );
}
