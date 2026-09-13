import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/meditation_audio_service.dart';

class MeditationAudioPlayer extends StatefulWidget {
  final String guideKey;
  const MeditationAudioPlayer({super.key, required this.guideKey});
  @override
  State<MeditationAudioPlayer> createState() => _MeditationAudioPlayerState();
}
class _MeditationAudioPlayerState extends State<MeditationAudioPlayer> {
  late final String _asset = 'assets/audio/meditation/${widget.guideKey}.mp3';
  bool _available = false;
  bool _busy = false;
  @override
  void initState() { super.initState(); _check(); }
  Future<void> _check() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      if (mounted) setState(() => _available = manifest.listAssets().contains(_asset));
    } catch (_) { /* Missing recordings do not show an unusable button. */ }
  }
  Future<void> _toggle() async {
    setState(() => _busy = true);
    try { await MeditationAudioService.instance.toggle(_asset); }
    catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('오디오를 재생하지 못했어요. 다시 시도해 주세요.'))); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  @override
  void dispose() {
    if (_available) unawaited(MeditationAudioService.instance.pause(_asset).catchError((Object _) {}));
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    if (!_available) return const SizedBox.shrink();
    return ValueListenableBuilder<String?>(valueListenable: MeditationAudioService.instance.playing,
      builder: (_, playing, __) => OutlinedButton.icon(
        onPressed: _busy ? null : _toggle,
        icon: Icon(playing == _asset ? Icons.pause : Icons.headphones),
        label: Text(playing == _asset ? '명상 오디오 일시정지' : '명상 오디오 듣기'),
      ));
  }
}
