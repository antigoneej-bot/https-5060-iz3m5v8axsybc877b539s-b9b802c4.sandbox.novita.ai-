import 'meditation_sleep_controls.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/meditation_audio_service.dart';
import '../theme.dart';

class MeditationAudioPlayer extends StatefulWidget {
  final String guideKey;
  const MeditationAudioPlayer({super.key, required this.guideKey});
  @override
  State<MeditationAudioPlayer> createState() => _MeditationAudioPlayerState();
}

class _MeditationAudioPlayerState extends State<MeditationAudioPlayer> {
  String get _asset => 'assets/audio/meditation/${widget.guideKey}.mp3';
  bool _available = false;
  bool _busy = false;
  double? _volumeDraft;
  final _audio = MeditationAudioService.instance;
  @override
  void initState() {
    super.initState();
    _check();
  }

  @override
  void didUpdateWidget(covariant MeditationAudioPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.guideKey != widget.guideKey) {
      unawaited(
        _audio
            .pause('assets/audio/meditation/${oldWidget.guideKey}.mp3')
            .catchError((Object _) {}),
      );
      _available = false;
      _check();
    }
  }

  Future<void> _check() async {
    final asset = _asset;
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      if (mounted && asset == _asset)
        setState(() => _available = manifest.listAssets().contains(asset));
    } catch (_) {}
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('오디오를 조절하지 못했어요. 다시 시도해 주세요.')),
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    if (_available) unawaited(_audio.pause(_asset).catchError((Object _) {}));
    super.dispose();
  }

  String _time(Duration d) =>
      '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  @override
  Widget build(BuildContext context) {
    if (!_available) return const SizedBox.shrink();
    return ListenableBuilder(
      listenable: Listenable.merge([_audio.playing, _audio.changes]),
      builder: (context, _) {
        final active = _audio.activeAsset == _asset;
        final playing = _audio.playing.value == _asset;
        final position = active ? _audio.position : Duration.zero;
        final duration = active ? _audio.duration : Duration.zero;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.catSageBg,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.guideKey == 'rainThunderRest'
                    ? '자연의 소리와 함께 쉬어요'
                    : '목소리와 함께 쉬어요',
                style: bodyFont(
                  fontSize: 16,
                  color: AppColors.titlePastelGreen,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _run(() => _audio.toggle(_asset)),
                    icon: Icon(playing ? Icons.pause : Icons.headphones),
                    label: Text(
                      playing
                          ? '일시정지'
                          : active
                          ? '이어 듣기'
                          : '오디오 듣기',
                    ),
                  ),
                  if (active)
                    TextButton.icon(
                      onPressed: _busy
                          ? null
                          : () => _run(() => _audio.restart(_asset)),
                      icon: const Icon(Icons.replay),
                      label: const Text('처음으로'),
                    ),
                ],
              ),
              if (active) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  color: AppColors.titlePastelGreen,
                  backgroundColor: Colors.white,
                  value: duration.inMilliseconds > 0
                      ? (position.inMilliseconds / duration.inMilliseconds)
                            .clamp(0.0, 1.0)
                      : 0,
                  semanticsLabel: '명상 재생 진행',
                ),
                const SizedBox(height: 5),
                Text(
                  '${_time(position)} / ${duration > Duration.zero ? _time(duration) : "시간 확인 중"}',
                  style: bodyFont(fontSize: 12, color: AppColors.inkSoft),
                ),
              ],
              const SizedBox(height: 10),
              Text(
                '듣기 속도',
                style: bodyFont(fontSize: 13, color: AppColors.ink),
              ),
              Wrap(
                spacing: 8,
                children: [
                  for (final rate in [0.85, 1.0, 1.15])
                    ChoiceChip(
                      selectedColor: AppColors.catPeachBg,
                      backgroundColor: Colors.white.withValues(alpha: 0.7),
                      checkmarkColor: AppColors.titlePastelGreen,
                      side: BorderSide(
                        color: AppColors.titlePastelGreen.withValues(
                          alpha: 0.3,
                        ),
                      ),
                      labelStyle: bodyFont(fontSize: 13, color: AppColors.ink),
                      label: Text(rate == 1.0 ? '기본' : '${rate}배'),
                      selected: _audio.speed == rate,
                      onSelected: _busy
                          ? null
                          : (_) => _run(() => _audio.setSpeed(rate)),
                    ),
                ],
              ),
              Row(
                children: [
                  const Icon(
                    Icons.volume_down_outlined,
                    color: AppColors.titlePastelGreen,
                  ),
                  Expanded(
                    child: Slider(
                      value: _volumeDraft ?? _audio.volume,
                      divisions: 10,
                      label:
                          '${((_volumeDraft ?? _audio.volume) * 100).round()}%',
                      semanticFormatterCallback: (v) =>
                          '음량 ${(v * 100).round()}퍼센트',
                      onChanged: _busy
                          ? null
                          : (v) => setState(() => _volumeDraft = v),
                      onChangeEnd: (v) async {
                        await _run(() => _audio.setVolume(v));
                        if (mounted) setState(() => _volumeDraft = null);
                      },
                    ),
                  ),
                ],
              ),
              if (active)
                MeditationSleepControls(
                  owner: _audio,
                  allowRepeat: widget.guideKey == 'rainThunderRest',
                ),
              Text(
                '화면을 떠나면 잠시 멈춰요. 돌아와 이어 들을 수 있어요.',
                style: bodyFont(fontSize: 12, color: AppColors.inkSoft),
              ),
            ],
          ),
        );
      },
    );
  }
}
