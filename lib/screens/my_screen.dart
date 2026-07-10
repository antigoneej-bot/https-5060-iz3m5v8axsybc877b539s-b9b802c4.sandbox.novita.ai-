import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../theme.dart';
import '../services/sound_service.dart';
import '../widgets/growth_header.dart';

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
          style: serifFont(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.ink,
          ),
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
        Text(
          '설정',
          style: serifFont(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.ink,
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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bg1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Color(0xFFFFF6DF), AppColors.goldSoft, AppColors.gold],
                stops: [0, 0.55, 1],
              ),
            ),
            child: const Text('🐱', style: TextStyle(fontSize: 26)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _statColumn('$streak일', '연속 방문')),
                Container(width: 1, height: 32, color: AppColors.line),
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
          style: serifFont(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.goldSoft,
          ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.bg1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
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
          const Divider(height: 1, color: AppColors.line),
          _switchRow(
            icon: Icons.graphic_eq_rounded,
            label: '효과음',
            value: sound.sfxEnabled,
            onChanged: (v) async {
              await sound.setSfxEnabled(v);
              onChanged();
            },
          ),
          const Divider(height: 1, color: AppColors.line),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                const Icon(
                  Icons.volume_up_rounded,
                  color: AppColors.inkSoft,
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
                      activeTrackColor: AppColors.gold,
                      inactiveTrackColor: const Color(0xFFE9DEC6),
                      thumbColor: AppColors.gold,
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
          Icon(icon, color: AppColors.inkSoft, size: 20),
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
            activeTrackColor: AppColors.gold,
          ),
        ],
      ),
    );
  }
}
