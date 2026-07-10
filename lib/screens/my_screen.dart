import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../theme.dart';
import '../services/sound_service.dart';
import '../widgets/growth_header.dart';
import '../widgets/garden_path_card.dart';

/// 마이 탭 - 나의 성장 현황, 방문 기록, 사운드 설정 등을 관리하는 화면
class MyScreen extends StatefulWidget {
  const MyScreen({super.key});

  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  final sound = SoundService();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppStateProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '마이',
          textAlign: TextAlign.center,
          style: titleFont(fontSize: 26, color: AppColors.titlePastelGreen),
        ),
        const SizedBox(height: 6),
        Text(
          '나의 마음챙김 여정을 확인해보세요',
          textAlign: TextAlign.center,
          style: bodyFont(fontSize: 12.5, color: AppColors.inkSoft),
        ),
        const SizedBox(height: 22),
        _ProfileCard(streak: app.streak, totalLetters: app.history.length),
        const SizedBox(height: 16),
        GrowthHeader(
          level: app.growthLevel,
          points: app.growthPoints,
          elapsedDays: app.growthElapsedDays,
          goalPoints: AppStateProvider.growthGoalPoints,
          windowDays: AppStateProvider.growthWindowDays,
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.only(left: 6),
          child: Text(
            '⚙️ 설정',
            style: pathLabelFont(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _SettingsCard(sound: sound, onChanged: () => setState(() {})),
        const SizedBox(height: 20),
        Center(
          child: Text(
            '고양이 그림자 정원 v1.0',
            style: bodyFont(fontSize: 11, color: AppColors.inkSoft),
          ),
        ),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final int streak;
  final int totalLetters;
  const _ProfileCard({required this.streak, required this.totalLetters});

  @override
  Widget build(BuildContext context) {
    return GlassBlob(
      accent: AppColors.blobButterAccent,
      background: AppColors.blobButter,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFFFF6DF),
                  AppColors.blobButterAccent,
                  AppColors.blobButterAccent,
                ],
                stops: const [0, 0.55, 1],
              ),
            ),
            child: const Text('🐱', style: TextStyle(fontSize: 26)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _statColumn('$streak일', '연속 방문')),
                Container(
                  width: 1,
                  height: 32,
                  color: AppColors.blobButterAccent.withValues(alpha: 0.25),
                ),
                Expanded(child: _statColumn('$totalLetters통', '보낸 편지')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statColumn(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: numberFont(fontSize: 17, color: AppColors.blobButterAccent),
        ),
        const SizedBox(height: 2),
        Text(label, style: bodyFont(fontSize: 11, color: AppColors.inkSoft)),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final SoundService sound;
  final VoidCallback onChanged;
  const _SettingsCard({required this.sound, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GlassBlob(
      accent: AppColors.blobLavenderAccent,
      background: AppColors.blobLavender,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          _switchRow(
            icon: Icons.music_note_rounded,
            label: '배경 음악',
            value: sound.bgmEnabled,
            onChanged: (v) async {
              await sound.setBgmEnabled(v);
              onChanged();
            },
          ),
          Divider(
            height: 1,
            color: AppColors.blobLavenderAccent.withValues(alpha: 0.18),
          ),
          _switchRow(
            icon: Icons.graphic_eq_rounded,
            label: '효과음',
            value: sound.sfxEnabled,
            onChanged: (v) async {
              await sound.setSfxEnabled(v);
              onChanged();
            },
          ),
          Divider(
            height: 1,
            color: AppColors.blobLavenderAccent.withValues(alpha: 0.18),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Icon(
                  Icons.volume_up_rounded,
                  color: AppColors.blobLavenderAccent,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  '음악 볼륨',
                  style: bodyFont(fontSize: 13.5, color: AppColors.moon),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      activeTrackColor: AppColors.blobLavenderAccent,
                      inactiveTrackColor: Colors.white.withValues(alpha: 0.6),
                      thumbColor: AppColors.blobLavenderAccent,
                      overlayShape: SliderComponentShape.noOverlay,
                    ),
                    child: Slider(
                      value: sound.bgmVolume,
                      onChanged: (v) async {
                        await sound.setBgmVolume(v);
                        onChanged();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _switchRow({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: AppColors.blobLavenderAccent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: bodyFont(fontSize: 13.5, color: AppColors.moon),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.blobLavenderAccent,
          ),
        ],
      ),
    );
  }
}
