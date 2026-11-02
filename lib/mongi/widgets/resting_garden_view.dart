import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/cat_visit.dart';
import '../../models/companion_coat.dart';
import '../../providers/cat_care_provider.dart';
import '../models/garden_layout.dart';
import '../providers/garden_provider.dart';
import 'garden_world_view.dart';

/// A finished landscape for looking and resting. It never receives the user's
/// plants, currency, layout store, planting, watering or editing callbacks.
class RestingGardenView extends StatefulWidget {
  const RestingGardenView({
    super.key,
    this.cameraGestures = true,
    this.onFullscreen,
    this.fullscreen = false,
  });
  final bool cameraGestures, fullscreen;
  final VoidCallback? onFullscreen;
  @override
  State<RestingGardenView> createState() => _RestingGardenViewState();
}

class _RestingGardenViewState extends State<RestingGardenView> {
  bool _overview = false;
  bool _toolsOpen = true;
  bool? _night;
  @override
  Widget build(BuildContext context) {
    final care = context.watch<CatCareProvider>();
    final garden = context.watch<GardenProvider>();
    final overview = widget.fullscreen || _overview;
    return Column(
      key: const Key('resting-garden-space'),
      children: [
        Expanded(
          child: GardenWorldView(
            key: const Key('resting-garden-canvas'),
            originalScenery: false,
            cameraGestures: widget.cameraGestures,
            readOnly: true,
            cultivationMode: true,
            fillViewport: true,
            overviewRequested: widget.fullscreen || _overview,
            nightOverride: _night,
            layout: GardenLayout(spaces: 3),
            seeds: const {},
            decorations: const [],
            motionEnabled: garden.gardenMotionEnabled,
            companionName: care.displayName,
            companionScale: care.journey.visualScale,
            companionBondStage: care.journey.stage,
            companionAutomaticBehavior:
                care.journeyReady && care.journey.automaticBehavior,
            visitingHost: VisitingCat(
              coat: care.journey.coat ?? CompanionCoat.ginger,
              stage: care.journey.keepBaby ? 0 : care.journey.stage,
              name: care.displayName,
            ),
            onMove: (_, __) async {},
            onMemory: (_) {},
            onPlant: () {},
            onDecorate: () {},
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                if (!widget.fullscreen || _toolsOpen) ...[
                  const Text(
                    '여기서는 고양이와 잠시 쉬어요.',
                    style: TextStyle(fontSize: 12),
                  ),
                  TextButton.icon(
                    key: const Key('rest-garden-overview'),
                    onPressed:
                        widget.onFullscreen ??
                        () => setState(() => _overview = !_overview),
                    icon: Icon(
                      overview ? Icons.zoom_in : Icons.zoom_out_map,
                      size: 18,
                    ),
                    label: Text(overview ? '가까이 보기' : '풍경 전체보기'),
                  ),
                  PopupMenuButton<String>(
                    tooltip: '쉬어가는 정원 낮·밤',
                    onSelected: (value) => setState(
                      () => _night = value == 'auto' ? null : value == 'night',
                    ),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'day', child: Text('햇살 풍경')),
                      PopupMenuItem(value: 'night', child: Text('별빛 풍경')),
                      PopupMenuItem(value: 'auto', child: Text('현재 시간에 맞추기')),
                    ],
                    icon: const Icon(Icons.brightness_6_outlined, size: 20),
                  ),
                ],
                if (widget.fullscreen)
                  TextButton.icon(
                    key: const Key('rest-garden-tools-toggle'),
                    onPressed: () => setState(() => _toolsOpen = !_toolsOpen),
                    icon: Icon(
                      _toolsOpen ? Icons.expand_more : Icons.expand_less,
                    ),
                    label: Text(_toolsOpen ? '도구 접기' : '도구 펼치기'),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
