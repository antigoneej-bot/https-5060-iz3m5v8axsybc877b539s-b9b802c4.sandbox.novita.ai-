import '../../l10n/app_language.dart';
import 'package:flutter/material.dart';
import '../integration/mongi_garden_data.dart';
import '../models/seed.dart';
import 'living_garden_scene.dart';
import '../../widgets/storybook_art.dart';

class GardenCoreTools extends StatelessWidget {
  const GardenCoreTools({
    super.key,
    required this.onPlant,
    required this.onWater,
    required this.onPlants,
    required this.onOverview,
    this.watering = false,
    this.overview = false,
    this.disabled = false,
    this.compact = false,
  });
  final VoidCallback onPlant, onWater, onPlants, onOverview;
  final bool watering, overview, disabled, compact;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final large = MediaQuery.textScalerOf(context).scale(14) > 20;
      final columns = large && box.maxWidth < 650 ? 2 : 4;
      final names = [
        tr('씨앗 심기'),
        watering ? tr('물주기 마치기') : tr('물주기'),
        tr('내 식물'),
        tr('전체보기'),
      ];
      final actions = [onPlant, onWater, onPlants, onOverview];
      final pictures = <Widget>[
        const StorySprite.icon(9),
        Image.asset(
          'assets/mongi/images/watering_can.png',
          fit: BoxFit.contain,
          excludeFromSemantics: true,
        ),
        const StorySprite.icon(5),
        const Icon(Icons.map_outlined, color: Color(0xFF6C8861), size: 38),
      ];
      return Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (var i = 0; i < 4; i++)
            SizedBox(
              width: (box.maxWidth - 6 * (columns - 1)) / columns,
              child: Material(
                color: i == 1 && watering
                    ? const Color(0xFFE1F0E4)
                    : const Color(0xF7FFFAEF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: Color(0xFFE8D8B9)),
                ),
                clipBehavior: Clip.antiAlias,
                child: TextButton(
                  key: ValueKey('cultivation-tool-$i'),
                  onPressed: disabled ? null : actions[i],
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 8,
                    ),
                    minimumSize: const Size(48, 48),
                    foregroundColor: const Color(0xFF344A32),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!compact)
                        SizedBox(height: 40, width: 48, child: pictures[i]),
                      const SizedBox(height: 4),
                      Text(
                        names[i],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                        semanticsLabel: i == 3 ? tr('가로 전체화면') : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}

class GardenPlantList extends StatefulWidget {
  const GardenPlantList({
    super.key,
    required this.data,
    required this.onLocate,
    required this.onWater,
    required this.onMemory,
    this.onMove,
  });
  final MongiGardenData data;
  final ValueChanged<SeedType> onLocate, onMemory;
  final ValueChanged<SeedType>? onMove;
  final Future<bool> Function(String) onWater;
  @override
  State<GardenPlantList> createState() => _GardenPlantListState();
}

class _GardenPlantListState extends State<GardenPlantList> {
  final _busy = <String>{};
  String? _error;
  Future<void> _water(String id) async {
    if (_busy.contains(id)) return;
    setState(() {
      _busy.add(id);
      _error = null;
    });
    try {
      await widget.onWater(id);
    } catch (_) {
      if (mounted) setState(() => _error = tr('물주기를 저장하지 못했어요. 다시 시도해 주세요.'));
    } finally {
      if (mounted) setState(() => _busy.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final plants = SeedType.all
        .where((s) => (widget.data.seeds[s.id] ?? 0) > 0)
        .toList();
    final today = MongiGardenData.dayKey(DateTime.now());
    return SafeArea(
      child: SingleChildScrollView(
        key: const Key('my-plants-list'),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(tr('내 식물'), style: Theme.of(context).textTheme.titleLarge),
            Text(tr('식물을 누르면 정원 속 위치로 이동해요.')),
            if (plants.isEmpty)
              Padding(
                padding: EdgeInsets.all(24),
                child: Text(tr('아직 심은 식물이 없어요. 씨앗을 골라 심어보세요.')),
              ),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            for (final seed in plants)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      ListTile(
                        key: ValueKey('locate-${seed.id}'),
                        onTap: () => widget.onLocate(seed),
                        leading: SizedBox(
                          width: 64,
                          height: 64,
                          child: GardenPlantArt(
                            seed: seed,
                            count: widget.data.seeds[seed.id]!,
                          ),
                        ),
                        title: Text(seed.label),
                        subtitle: Text(
                          '${seed.growthLabel(widget.data.seeds[seed.id]!)} · ${widget.data.wateredOn[seed.id] == today ? tr('오늘 물주기 완료') : tr('오늘 물주기 전')}\n'
                          '${seed.careUntilNextTier(widget.data.seeds[seed.id]!) > 0 ? tr("물주기만 할 경우 다음 성장까지 {0}회", [seed.careUntilNextTier(widget.data.seeds[seed.id]!)]) : tr('다 자랐어요. 편하게 감상해 주세요.')}',
                        ),
                        trailing: const Icon(Icons.my_location),
                      ),
                      Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 8,
                        children: [
                          TextButton.icon(
                            key: ValueKey('locate-button-${seed.id}'),
                            onPressed: () => widget.onLocate(seed),
                            icon: const Icon(Icons.my_location),
                            label: Text(tr('위치 보기')),
                          ),
                          if (widget.onMove != null)
                            TextButton.icon(
                              key: ValueKey('move-button-${seed.id}'),
                              onPressed: _busy.contains(seed.id)
                                  ? null
                                  : () => widget.onMove!(seed),
                              icon: const Icon(Icons.open_with),
                              label: Text(tr('위치 옮기기')),
                            ),
                          TextButton.icon(
                            key: ValueKey('water-${seed.id}'),
                            onPressed:
                                _busy.contains(seed.id) ||
                                    widget.data.wateredOn[seed.id] == today
                                ? null
                                : () => _water(seed.id),
                            icon: const Icon(Icons.water_drop_outlined),
                            label: Text(tr('물주기')),
                          ),
                          TextButton.icon(
                            onPressed: _busy.contains(seed.id)
                                ? null
                                : () => widget.onMemory(seed),
                            icon: const Icon(Icons.menu_book_outlined),
                            label: Text(tr('추억 기록')),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
