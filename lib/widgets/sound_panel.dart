import '../l10n/app_language.dart';
import '../mongi/services/sound_manager.dart';
import '../services/garden_sound_timer.dart';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/sound_service.dart';

class SoundToggleButton extends StatelessWidget {
  final SoundService? sound;
  const SoundToggleButton({super.key, this.sound});

  @override
  Widget build(BuildContext context) {
    final audio = sound ?? SoundService();
    return AnimatedBuilder(
      animation: audio,
      builder: (context, _) => IconButton.filledTonal(
        tooltip: tr("소리 설정"),
        style: IconButton.styleFrom(
          backgroundColor: AppColors.bg2,
          foregroundColor: AppColors.moon,
        ),
        icon: Icon(
          audio.bgmEnabled && audio.bgmVolume > 0
              ? Icons.volume_up
              : Icons.volume_off,
        ),
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          showDragHandle: true,
          backgroundColor: AppColors.bg1,
          builder: (_) => SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(tr("소리 설정"), style: titleFont(fontSize: 21)),
                  const SizedBox(height: 12),
                  SoundSettingsControls(sound: audio),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shared by the home sound sheet and My settings. The sheet uses a real
/// overlay: controls painted outside the old 34px Stack could not be tapped.
class SoundSettingsControls extends StatefulWidget {
  final SoundService sound;
  const SoundSettingsControls({super.key, required this.sound});

  @override
  State<SoundSettingsControls> createState() => _SoundSettingsControlsState();
}

class _SoundSettingsControlsState extends State<SoundSettingsControls> {
  bool _retrying = false;
  String? _message;

  Future<void> _change(Future<void> Function() action) async {
    try {
      await action();
      if (mounted) setState(() => _message = null);
    } catch (_) {
      if (mounted)
        setState(() => _message = tr("소리 설정을 저장하지 못했어요. 다시 시도해 주세요."));
    }
  }

  Future<void> _retry() async {
    if (_retrying) return;
    setState(() {
      _retrying = true;
      _message = null;
    });
    try {
      final started = await widget.sound.retryBgm();
      if (mounted)
        setState(
          () => _message = started
              ? tr("재생을 다시 요청했어요. 소리가 없으면 휴대전화 미디어 음량과 블루투스 연결을 확인해 주세요.")
              : widget.sound.narrationPlaying
              ? tr("명상 재생을 멈춘 뒤 다시 눌러 주세요.")
              : tr("현재 음악을 시작할 수 없어요. 배경 음악과 음량을 확인해 주세요."),
        );
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([widget.sound, GardenSoundTimer.instance]),
    builder: (context, _) {
      final sound = widget.sound;
      final percent = (sound.bgmVolume * 100).round();
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(tr("배경 음악")),
            value: sound.bgmEnabled,
            onChanged: (value) => _change(() => sound.setBgmEnabled(value)),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(tr("효과음")),
            value: sound.sfxEnabled,
            onChanged: (value) => _change(() => sound.setSfxEnabled(value)),
          ),
          SwitchListTile.adaptive(
            title: Text(tr("고양이 소리")),
            subtitle: Text(tr("야옹·그릉그릉 · 전체 효과음 설정도 적용돼요")),
            value: sound.catSoundEnabled,
            onChanged: (v) => _change(() => sound.setCatSound(enabled: v)),
          ),
          Text(tr("고양이 음량 {0}%", [(sound.catVolume * 100).round()])),
          Slider(
            key: const Key('sound-cat-volume'),
            value: sound.catVolume,
            onChanged: (v) => _change(() => sound.setCatSound(volume: v)),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(tr("음악 볼륨 · {0}%", [percent])),
          ),
          Slider(
            key: const Key('sound-bgm-volume'),
            value: sound.bgmVolume,
            label: '$percent%',
            semanticFormatterCallback: (value) =>
                tr("음악 볼륨 {0}퍼센트", [(value * 100).round()]),
            onChanged: (value) => _change(() => sound.setBgmVolume(value)),
          ),
          if (!sound.bgmEnabled)
            Text(tr("배경 음악이 꺼져 있어요."))
          else if (sound.bgmVolume == 0)
            Text(tr("음악 볼륨이 0이에요. 위에서 음량을 올려 주세요.")),
          if (sound.bgmError != null) Text(sound.bgmError!),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _retrying || !sound.bgmEnabled || sound.bgmVolume == 0
                  ? null
                  : _retry,
              icon: const Icon(Icons.refresh),
              label: Text(_retrying ? tr("음악 불러오는 중…") : tr("음악 다시 재생")),
            ),
          ),
          const Divider(),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(tr("정원 자연음")),
            subtitle: Text(tr("조용히 쉬는 동안 재생해요. 배경 음악과 따로 조절해요.")),
            value: SoundManager.instance.natureEnabled,
            onChanged: (v) =>
                _change(() => SoundManager.instance.setNature(enabled: v)),
          ),
          Text(
            tr("새소리 {0}%", [(SoundManager.instance.birdsVolume * 100).round()]),
          ),
          Slider(
            key: const Key('sound-birds-volume'),
            value: SoundManager.instance.birdsVolume,
            onChanged: (v) =>
                _change(() => SoundManager.instance.setNature(birds: v)),
          ),
          Text(
            tr("물소리 {0}%", [(SoundManager.instance.waterVolume * 100).round()]),
          ),
          Slider(
            key: const Key('sound-water-volume'),
            value: SoundManager.instance.waterVolume,
            onChanged: (v) =>
                _change(() => SoundManager.instance.setNature(water: v)),
          ),
          const Divider(),
          Text(tr("소리 종료 타이머 · 음악·자연음·재생 중인 명상을 멈춰요")),
          Wrap(
            spacing: 8,
            children: [
              for (final minutes in [5, 15, 30, 60])
                TextButton(
                  onPressed: GardenSoundTimer.instance.stopped
                      ? null
                      : () => GardenSoundTimer.instance.setMinutes(minutes),
                  child: Text(tr("{0}분", [minutes])),
                ),
              TextButton(
                onPressed: () => GardenSoundTimer.instance.setMinutes(null),
                child: Text(tr("타이머 취소")),
              ),
            ],
          ),
          if (GardenSoundTimer.instance.deadline != null)
            Text(
              tr("종료까지 {0}분", [
                (GardenSoundTimer.instance.remaining.inSeconds.clamp(0, 3600) /
                        60)
                    .ceil(),
              ]),
            ),
          if (GardenSoundTimer.instance.stopped)
            TextButton.icon(
              onPressed: () => _change(GardenSoundTimer.instance.resumeSound),
              icon: const Icon(Icons.play_arrow),
              label: Text(tr("다시 듣기")),
            ),
          if (_message != null) Text(_message!, style: bodyFont(fontSize: 13)),
        ],
      );
    },
  );
}
