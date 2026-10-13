import '../../providers/cat_care_provider.dart';
import '../screens/garden_world_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/garden_provider.dart';
import '../models/seed.dart';
import '../integration/plant_memory_store.dart';
import '../integration/plant_memory_editor.dart';
import 'living_garden_scene.dart';

/// Loads persisted garden data; the scene itself stays usable while loading.
class LivingGardenEntry extends StatefulWidget {
  final VoidCallback? onWrite, onGarden, onNeighbors;
  const LivingGardenEntry({
    super.key,
    this.onWrite,
    this.onGarden,
    this.onNeighbors,
  });
  @override
  State<LivingGardenEntry> createState() => _LivingGardenEntryState();
}

class _LivingGardenEntryState extends State<LivingGardenEntry> {
  bool _loading = true, _failed = false, _openingMemory = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      await context.read<GardenProvider>().ensureInitialized();
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _memory(SeedType plant) async {
    if (_openingMemory) return;
    _openingMemory = true;
    try {
      await PlantMemoryStore.instance.reload();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => PlantMemoryEditor(plant: plant),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('정원의 추억을 불러오지 못했어요. 다시 시도해 주세요.')),
        );
      }
    } finally {
      _openingMemory = false;
    }
  }

  void _openWorld() => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => GardenWorldScreen(onOpenCollection: widget.onGarden),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final garden = context.watch<GardenProvider>();
    final companionName = context.watch<CatCareProvider>().displayName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) => Center(
            child: SizedBox(
              width: constraints.maxWidth.clamp(0.0, 360.0).toDouble(),
              child: LivingGardenScene(
                compact: true,
                companionName: companionName,
                seeds: garden.seedCounts,
                motionEnabled: garden.gardenMotionEnabled,
                onWrite: widget.onWrite,
                onGarden: widget.onGarden == null ? null : _openWorld,
                onNeighbors: widget.onNeighbors,
                onPlant: _loading || _failed ? null : _memory,
              ),
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: _openWorld,
          icon: const Icon(Icons.landscape_outlined),
          label: const Text('넓은 정원 산책 · 아이템 배치'),
        ),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text('정원의 기록을 불러오고 있어요.', textAlign: TextAlign.center),
          ),
        if (_failed)
          TextButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: const Text('정원 기록 다시 불러오기'),
          ),
      ],
    );
  }
}
