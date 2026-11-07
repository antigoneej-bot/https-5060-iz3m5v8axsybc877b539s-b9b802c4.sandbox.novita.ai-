import '../../l10n/app_language.dart';
import '../../services/garden_sound_timer.dart';
import 'dart:async';
import '../services/sound_manager.dart';
import '../../services/sound_service.dart';
import '../../widgets/garden_personal_canvas.dart';
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
    this.canvasOnly = false,
    this.overviewRequested = false,
    this.nightOverride,
    this.onNightChanged,
  });
  final bool cameraGestures, fullscreen, canvasOnly, overviewRequested;
  final bool? nightOverride;
  final ValueChanged<bool?>? onNightChanged;
  final VoidCallback? onFullscreen;
  @override
  State<RestingGardenView> createState() => _RestingGardenViewState();
}

class _RestingGardenViewState extends State<RestingGardenView>
    with WidgetsBindingObserver {
  bool _listening = false, _ownsNature = false, _foreground = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncNature();
    });
  }

  void _syncNature() {
    final active =
        _listening &&
        _foreground &&
        TickerMode.of(context) &&
        (ModalRoute.of(context)?.isCurrent ?? true);
    if (active &&
        !SoundService().narrationPlaying &&
        !SoundService().sleepStopped) {
      _ownsNature = true;
      unawaited(SoundManager.instance.startAmbientNature());
    } else if (_ownsNature) {
      _ownsNature = false;
      unawaited(SoundManager.instance.stopAmbientNature());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (mounted) _syncNature();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_ownsNature) unawaited(SoundManager.instance.stopAmbientNature());
    super.dispose();
  }

  bool _overview = false;
  bool _toolsOpen = true;
  bool? _night;
  Widget _frame(
    BuildContext context, {
    Key? key,
    required List<Widget> children,
  }) {
    if (!widget.fullscreen) return Column(key: key, children: children);
    return Stack(
      key: key,
      fit: StackFit.expand,
      children: [
        Positioned.fill(child: (children.first as Expanded).child),
        Positioned(
          left: 8,
          right: 8,
          bottom: 6,
          child: Material(
            color: const Color(0xE8FCF9F3),
            borderRadius: BorderRadius.circular(18),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * .3,
              ),
              child: SingleChildScrollView(child: children.last),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final care = context.watch<CatCareProvider>();
    final garden = context.watch<GardenProvider>();
    final overview = widget.overviewRequested || _overview;
    final canvas = GardenPersonalCanvas(
      prefetched: true,
      topPadding: widget.fullscreen ? 76 : 8,
      builder: (_) => GardenWorldView(
        key: const Key('resting-garden-canvas'),
        originalScenery: false,
        cameraGestures: widget.cameraGestures,
        readOnly: true,
        cultivationMode: true,
        fillViewport: true,
        overviewRequested: overview,
        nightOverride: widget.nightOverride ?? _night,
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
    );
    if (widget.canvasOnly)
      return Stack(
        fit: StackFit.expand,
        children: [
          canvas,
          Positioned(
            right: 8,
            bottom: 8,
            child: SafeArea(
              top: false,
              left: false,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width * .46,
                  maxHeight: MediaQuery.sizeOf(context).height * .3,
                ),
                child: Material(
                  color: const Color(0xE8FCF9F3),
                  borderRadius: BorderRadius.circular(18),
                  child: SingleChildScrollView(child: _natureButton()),
                ),
              ),
            ),
          ),
        ],
      );
    return _frame(
      context,
      key: const Key('resting-garden-space'),
      children: [
        Expanded(child: canvas),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                if (!widget.fullscreen || _toolsOpen)
                  Text(tr('여기서는 고양이와 잠시 쉬어요.'), style: TextStyle(fontSize: 12)),
                TextButton.icon(
                  key: const Key('rest-garden-overview'),
                  onPressed: widget.fullscreen
                      ? () => setState(() => _overview = !_overview)
                      : widget.onFullscreen ??
                            () => setState(() => _overview = !_overview),
                  icon: Icon(
                    overview ? Icons.zoom_in : Icons.zoom_out_map,
                    size: 18,
                  ),
                  label: Text(
                    widget.fullscreen
                        ? (overview ? tr('정원으로 돌아가기') : tr('정원 전체 지도'))
                        : tr('가로 전체화면'),
                  ),
                ),
                if (!widget.fullscreen || _toolsOpen) _natureButton(),
                if (!widget.fullscreen || _toolsOpen)
                  PopupMenuButton<String>(
                    tooltip: tr('쉬어가는 정원 낮·밤'),
                    onSelected: (value) {
                      final night = value == 'auto' ? null : value == 'night';
                      setState(() => _night = night);
                      widget.onNightChanged?.call(night);
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(value: 'day', child: Text(tr('햇살 풍경'))),
                      PopupMenuItem(value: 'night', child: Text(tr('별빛 풍경'))),
                      PopupMenuItem(
                        value: 'auto',
                        child: Text(tr('현재 시간에 맞추기')),
                      ),
                    ],
                    icon: const Icon(Icons.brightness_6_outlined, size: 20),
                  ),
                if (widget.fullscreen)
                  TextButton.icon(
                    key: const Key('rest-garden-tools-toggle'),
                    onPressed: () => setState(() => _toolsOpen = !_toolsOpen),
                    icon: Icon(
                      _toolsOpen ? Icons.expand_more : Icons.expand_less,
                    ),
                    label: Text(_toolsOpen ? tr('도구 접기') : tr('도구 펼치기')),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _natureButton() => TextButton.icon(
    onPressed: () async {
      setState(() => _listening = !_listening);
      try {
        if (_listening && !SoundManager.instance.natureEnabled)
          await SoundManager.instance.setNature(enabled: true);
        if (_listening && GardenSoundTimer.instance.stopped)
          await GardenSoundTimer.instance.resumeSound();
        if (mounted) _syncNature();
      } catch (_) {
        if (mounted) {
          setState(() => _listening = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(tr('자연음을 다시 켜 주세요.'))));
        }
      }
    },
    icon: Icon(_listening ? Icons.volume_off : Icons.nature_people_outlined),
    label: Text(_listening ? tr('자연음 끄기') : tr('자연음 듣기')),
  );
}
