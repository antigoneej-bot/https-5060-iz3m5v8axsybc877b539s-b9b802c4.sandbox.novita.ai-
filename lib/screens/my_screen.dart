import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../theme.dart';
import '../services/sound_service.dart';
import '../services/notification_service.dart';
import '../widgets/growth_header.dart';
import '../widgets/garden_path_card.dart';
import 'privacy_policy_screen.dart';

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
        const SizedBox(height: 14),
        const _ReminderCard(),
        const SizedBox(height: 12),
        _InfoLinkRow(
          icon: Icons.privacy_tip_rounded,
          label: '개인정보처리방침 · 정신건강 안내',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
            );
          },
        ),
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

/// 데일리 돌보기 알림(로컬 푸시 리마인더) 설정 카드.
/// 켜면 매일 지정한 시간에 "고양이가 기다리고 있어요" 알림을 받습니다.
class _ReminderCard extends StatefulWidget {
  const _ReminderCard();

  @override
  State<_ReminderCard> createState() => _ReminderCardState();
}

class _ReminderCardState extends State<_ReminderCard> {
  final _notif = NotificationService();
  bool _loading = true;
  bool _enabled = false;
  int _hour = 20;
  int _minute = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final enabled = await _notif.isEnabled();
    final (hour, minute) = await _notif.getReminderTime();
    if (!mounted) return;
    setState(() {
      _enabled = enabled;
      _hour = hour;
      _minute = minute;
      _loading = false;
    });
  }

  Future<void> _onToggle(bool v) async {
    if (v) {
      final granted = await _notif.enableReminder(hour: _hour, minute: _minute);
      if (!mounted) return;
      if (!granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('알림 권한이 필요해요. 기기 설정에서 알림을 허용해주세요.')),
        );
        setState(() => _enabled = false);
        return;
      }
      setState(() => _enabled = true);
    } else {
      await _notif.disableReminder();
      if (!mounted) return;
      setState(() => _enabled = false);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _hour, minute: _minute),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(
            context,
          ).colorScheme.copyWith(primary: AppColors.blobPeachAccent),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      _hour = picked.hour;
      _minute = picked.minute;
    });
    await _notif.updateReminderTime(picked.hour, picked.minute);
  }

  String get _timeLabel {
    final h = _hour.toString().padLeft(2, '0');
    final m = _minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return GlassBlob(
      accent: AppColors.blobPeachAccent,
      background: AppColors.blobPeach,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(
                  Icons.notifications_active_rounded,
                  color: AppColors.blobPeachAccent,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '돌보기 리마인더',
                    style: bodyFont(fontSize: 13.5, color: AppColors.moon),
                  ),
                ),
                _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Switch(
                        value: _enabled,
                        onChanged: _onToggle,
                        activeTrackColor: AppColors.blobPeachAccent,
                      ),
              ],
            ),
          ),
          if (!_loading && _enabled) ...[
            Divider(
              height: 1,
              color: AppColors.blobPeachAccent.withValues(alpha: 0.18),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    color: AppColors.blobPeachAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '매일 $_timeLabel에 알려드려요',
                      style: bodyFont(fontSize: 13, color: AppColors.moon),
                    ),
                  ),
                  Material(
                    color: Colors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(999),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: _pickTime,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        child: Text(
                          '시간 변경',
                          style: bodyFont(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.blobPeachAccent,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 개인정보처리방침 등 안내 화면으로 이동하는 얇은 링크형 행.
/// 별도 카드 없이 담백하게 눌러서 이동할 수 있도록 합니다.
class _InfoLinkRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _InfoLinkRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppColors.inkSoft),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: bodyFont(fontSize: 12.5, color: AppColors.inkSoft),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 13,
                color: AppColors.inkSoft.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
