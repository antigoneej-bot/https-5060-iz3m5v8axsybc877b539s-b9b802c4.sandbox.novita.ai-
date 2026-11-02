import 'package:flutter/material.dart';
import '../integration/mongi_garden_data.dart';
import '../models/seed.dart';
import 'living_garden_scene.dart';

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
      final columns =
          box.maxWidth < 350 ||
              (MediaQuery.textScalerOf(context).scale(14) > 20 &&
                  box.maxWidth < 650)
          ? 2
          : 4;
      final names = [
        '씨앗 심기',
        watering ? '물주기 마치기' : '물주기',
        '내 식물',
        overview ? '원래 보기' : '전체보기',
      ];
      final icons = [
        Icons.spa_outlined,
        Icons.water_drop_outlined,
        Icons.park_outlined,
        Icons.zoom_out_map,
      ];
      final actions = [onPlant, onWater, onPlants, onOverview];
      return Material(
        color: const Color(0xFFFBF8F0),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Wrap(
              children: [
                for (var i = 0; i < 4; i++)
                  SizedBox(
                    width: (box.maxWidth - 12) / columns,
                    child: TextButton(
                      key: ValueKey('cultivation-tool-$i'),
                      onPressed: disabled ? null : actions[i],
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: compact
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(icons[i], size: 20),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      names[i],
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(icons[i], size: 23),
                                  const SizedBox(height: 3),
                                  Text(names[i], textAlign: TextAlign.center),
                                ],
                              ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
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
      if (mounted) setState(() => _error = '물주기를 저장하지 못했어요. 다시 시도해 주세요.');
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
            Text('내 식물', style: Theme.of(context).textTheme.titleLarge),
            const Text('식물을 누르면 정원 속 위치로 이동해요.'),
            if (plants.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('아직 심은 식물이 없어요. 씨앗을 골라 심어보세요.'),
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
                          '${seed.growthLabel(widget.data.seeds[seed.id]!)} · ${widget.data.wateredOn[seed.id] == today ? '오늘 물주기 완료' : '오늘 물주기 전'}',
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
                            label: const Text('위치 보기'),
                          ),
                          if (widget.onMove != null)
                            TextButton.icon(
                              key: ValueKey('move-button-${seed.id}'),
                              onPressed: _busy.contains(seed.id)
                                  ? null
                                  : () => widget.onMove!(seed),
                              icon: const Icon(Icons.open_with),
                              label: const Text('위치 옮기기'),
                            ),
                          TextButton.icon(
                            key: ValueKey('water-${seed.id}'),
                            onPressed:
                                _busy.contains(seed.id) ||
                                    widget.data.wateredOn[seed.id] == today
                                ? null
                                : () => _water(seed.id),
                            icon: const Icon(Icons.water_drop_outlined),
                            label: const Text('물주기'),
                          ),
                          TextButton.icon(
                            onPressed: _busy.contains(seed.id)
                                ? null
                                : () => widget.onMemory(seed),
                            icon: const Icon(Icons.menu_book_outlined),
                            label: const Text('추억 기록'),
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
