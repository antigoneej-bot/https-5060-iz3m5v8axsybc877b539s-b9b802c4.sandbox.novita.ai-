import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../integration/garden_layout_store.dart';
import '../integration/mongi_garden_store.dart';
import '../providers/garden_provider.dart';
import '../../providers/cat_care_provider.dart';
import 'garden_world_view.dart';

/// A quiet, small view of the same saved garden, not a second garden design.
class GardenHomePreview extends StatefulWidget {
  const GardenHomePreview({super.key});
  @override
  State<GardenHomePreview> createState() => _GardenHomePreviewState();
}
class _GardenHomePreviewState extends State<GardenHomePreview> {
  bool _ready = false, _failed = false;
  @override
  void initState() {
    super.initState();
    _load();
  }
  Future<void> _load() async {
    try {
      await context.read<GardenProvider>().ensureInitialized();
      await GardenLayoutStore.instance.reload();
      if (mounted) setState(() => _ready = true);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }
  @override
  Widget build(BuildContext context) {
    final name = context.watch<CatCareProvider>().displayName;
    return Semantics(label: '나의 정원 열기', button: true,
      child: ClipRRect(borderRadius: BorderRadius.circular(22),
        child: SizedBox(height: 164, child: Stack(fit: StackFit.expand, children: [
          if (_ready) IgnorePointer(child: AnimatedBuilder(
            animation: Listenable.merge([MongiGardenStore.instance, GardenLayoutStore.instance]),
            builder: (context, _) {
              final data = MongiGardenStore.instance.value;
              return GardenWorldView(preview: true, motionEnabled: false,
                companionName: name, layout: GardenLayoutStore.instance.value,
                seeds: data.seeds, decorations: data.placed.toList(),
                memoryDays: data.recordDays.length,
                onMove: (_, __) async {}, onMemory: (_) {},
                onPlant: () {}, onDecorate: () {});
            },
          )) else ColoredBox(color: const Color(0xFFE4EDDF),
            child: Center(child: Text(_failed ? '정원에 들어가 살펴보기' : '정원을 불러오고 있어요.'))),
          Positioned(left: 0, right: 0, bottom: 0,
            child: DecoratedBox(decoration: const BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Color(0x00364531), Color(0xD9364531)])),
              child: const Padding(padding: EdgeInsets.fromLTRB(16, 22, 16, 12),
                child: Row(children: [Expanded(child: Text('나의 정원',
                  style: TextStyle(color: Colors.white, fontSize: 14))),
                  Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 19)])))),
        ])),
      ),
    );
  }
}
