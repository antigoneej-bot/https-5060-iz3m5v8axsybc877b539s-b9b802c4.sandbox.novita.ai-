import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/sound_service.dart';

class SoundToggleButton extends StatefulWidget {
  const SoundToggleButton({super.key});

  @override
  State<SoundToggleButton> createState() => _SoundToggleButtonState();
}

class _SoundToggleButtonState extends State<SoundToggleButton> {
  bool _open = false;
  final sound = SoundService();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: AppColors.bg2,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => setState(() => _open = !_open),
            child: SizedBox(
              width: 34,
              height: 34,
              child: Icon(
                sound.bgmEnabled || sound.sfxEnabled
                    ? Icons.volume_up
                    : Icons.volume_off,
                size: 16,
                color: AppColors.moon,
              ),
            ),
          ),
        ),
        if (_open)
          Positioned(
            top: 40,
            right: 0,
            child: _SoundPanelContent(onChanged: () => setState(() {})),
          ),
      ],
    );
  }
}

class _SoundPanelContent extends StatefulWidget {
  final VoidCallback onChanged;
  const _SoundPanelContent({required this.onChanged});

  @override
  State<_SoundPanelContent> createState() => _SoundPanelContentState();
}

class _SoundPanelContentState extends State<_SoundPanelContent> {
  final sound = SoundService();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.bg1,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row('효과음', sound.sfxEnabled, (v) async {
            await sound.setSfxEnabled(v);
            setState(() {});
            widget.onChanged();
          }),
          const SizedBox(height: 4),
          _row('배경 음악', sound.bgmEnabled, (v) async {
            await sound.setBgmEnabled(v);
            setState(() {});
            widget.onChanged();
          }),
          const SizedBox(height: 8),
          Text('음악 볼륨', style: bodyFont(fontSize: 12.5, color: AppColors.moon)),
          const SizedBox(height: 4),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              activeTrackColor: AppColors.gold,
              inactiveTrackColor: const Color(0xFFE9DEC6),
              thumbColor: AppColors.gold,
              overlayShape: SliderComponentShape.noOverlay,
            ),
            child: Slider(
              value: sound.bgmVolume,
              onChanged: (v) async {
                await sound.setBgmVolume(v);
                setState(() {});
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: bodyFont(fontSize: 12.5, color: AppColors.moon)),
          GestureDetector(
            onTap: () => onChanged(!value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 34,
              height: 19,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: value
                    ? const LinearGradient(
                        colors: [AppColors.goldSoft, AppColors.gold],
                      )
                    : null,
                color: value ? null : const Color(0xFFE9DEC6),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: value ? Colors.white : const Color(0xFFFFFBF2),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
