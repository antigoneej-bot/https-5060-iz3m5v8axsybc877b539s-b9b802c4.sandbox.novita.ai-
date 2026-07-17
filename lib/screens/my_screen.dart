import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../providers/app_state_provider.dart';
import '../providers/cat_care_provider.dart';
import '../theme.dart';
import '../services/sound_service.dart';
import '../services/notification_service.dart';
import '../services/subscription_service.dart';
import '../widgets/growth_header.dart';
import '../widgets/garden_path_card.dart';
import 'privacy_policy_screen.dart';
import 'premium_screen.dart';
import 'about_app_screen.dart';
import 'app_tutorial_screen.dart';
import '../widgets/feature_scaffold.dart';
import 'analytics_debug_screen.dart';

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
        const SizedBox(height: 14),
        const _PremiumCard(),
        const SizedBox(height: 16),
        GrowthHeader(state: context.watch<CatCareProvider>().state),
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
        const SizedBox(height: 14),
        const _FeedbackCard(),
        const SizedBox(height: 12),
        _InfoLinkRow(
          icon: Icons.map_rounded,
          label: '앱 사용법 튜토리얼',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const FeatureScaffold(
                  title: '앱 사용법',
                  child: AppTutorialScreen(),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 4),
        _InfoLinkRow(
          icon: Icons.menu_book_rounded,
          label: '고양이 그림자 정원 소개',
          onTap: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const AboutAppScreen()));
          },
        ),
        const SizedBox(height: 4),
        _InfoLinkRow(
          icon: Icons.privacy_tip_rounded,
          label: '개인정보처리방침 · 정신건강 안내',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
            );
          },
        ),
        // 개발/운영 확인용 - 사용자에게는 노출하지 않고 디버그 빌드에서만 표시
        if (kDebugMode) ...[
          const SizedBox(height: 4),
          _InfoLinkRow(
            icon: Icons.query_stats_rounded,
            label: '(개발자용) 로컬 지표 확인',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const FeatureScaffold(
                    title: '로컬 지표',
                    child: AnalyticsDebugScreen(),
                  ),
                ),
              );
            },
          ),
        ],
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

/// 마이 탭 상단에서 정원 플러스 구독 상태를 보여주고, 눌러서 구독
/// 안내(PremiumScreen)로 이동할 수 있는 카드.
class _PremiumCard extends StatefulWidget {
  const _PremiumCard();

  @override
  State<_PremiumCard> createState() => _PremiumCardState();
}

class _PremiumCardState extends State<_PremiumCard> {
  bool _isPremium = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final premium = await SubscriptionService().isPremium();
    if (!mounted) return;
    setState(() {
      _isPremium = premium;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () async {
          await Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const PremiumScreen()));
          _load();
        },
        child: GlassBlob(
          accent: AppColors.blobPeriwinkleAccent,
          background: AppColors.blobPeriwinkle,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
                child: const Text('🌷', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _loading
                          ? '정원 플러스'
                          : _isPremium
                          ? '정원 플러스 이용 중'
                          : '정원 플러스로 더 깊이 돌아보기',
                      style: pathLabelFont(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isPremium ? '마음 리포트 전체 잠금 해제됨' : '상세 마음 리포트 잠금 해제하기',
                      style: bodyFont(fontSize: 11.5, color: AppColors.inkSoft),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.blobPeriwinkleAccent,
                size: 20,
              ),
            ],
          ),
        ),
      ),
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
/// 아침 / 저녁 알림을 각각 켜고 끄고 시간을 조절할 수 있고, 위기 알림(3일
/// 이상 미접속) · 스트릭 임박 알림(오늘 미완료)도 개별적으로 켜고 끌 수
/// 있습니다.
class _ReminderCard extends StatefulWidget {
  const _ReminderCard();

  @override
  State<_ReminderCard> createState() => _ReminderCardState();
}

class _ReminderCardState extends State<_ReminderCard> {
  final _notif = NotificationService();
  bool _loading = true;

  bool _morningEnabled = false;
  int _morningHour = 9;
  int _morningMinute = 0;

  bool _eveningEnabled = false;
  int _eveningHour = 20;
  int _eveningMinute = 0;

  bool _crisisEnabled = true;
  bool _streakEnabled = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final morningEnabled = await _notif.isMorningEnabled();
    final (mh, mm) = await _notif.getMorningTime();
    final eveningEnabled = await _notif.isEveningEnabled();
    final (eh, em) = await _notif.getEveningTime();
    final crisisEnabled = await _notif.isCrisisEnabled();
    final streakEnabled = await _notif.isStreakEnabled();
    if (!mounted) return;
    setState(() {
      _morningEnabled = morningEnabled;
      _morningHour = mh;
      _morningMinute = mm;
      _eveningEnabled = eveningEnabled;
      _eveningHour = eh;
      _eveningMinute = em;
      _crisisEnabled = crisisEnabled;
      _streakEnabled = streakEnabled;
      _loading = false;
    });
  }

  void _showPermissionDenied() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('알림 권한이 필요해요. 기기 설정에서 알림을 허용해주세요.')),
    );
  }

  Future<void> _onToggleMorning(bool v) async {
    if (v) {
      final granted = await _notif.enableMorning(
        hour: _morningHour,
        minute: _morningMinute,
      );
      if (!mounted) return;
      if (!granted) {
        _showPermissionDenied();
        setState(() => _morningEnabled = false);
        return;
      }
      setState(() => _morningEnabled = true);
    } else {
      await _notif.disableMorning();
      if (!mounted) return;
      setState(() => _morningEnabled = false);
    }
  }

  Future<void> _onToggleEvening(bool v) async {
    if (v) {
      final granted = await _notif.enableEvening(
        hour: _eveningHour,
        minute: _eveningMinute,
      );
      if (!mounted) return;
      if (!granted) {
        _showPermissionDenied();
        setState(() => _eveningEnabled = false);
        return;
      }
      setState(() => _eveningEnabled = true);
    } else {
      await _notif.disableEvening();
      if (!mounted) return;
      setState(() => _eveningEnabled = false);
    }
  }

  Future<void> _pickMorningTime() async {
    final picked = await _showTimePicker(_morningHour, _morningMinute);
    if (picked == null) return;
    setState(() {
      _morningHour = picked.hour;
      _morningMinute = picked.minute;
    });
    await _notif.updateMorningTime(picked.hour, picked.minute);
  }

  Future<void> _pickEveningTime() async {
    final picked = await _showTimePicker(_eveningHour, _eveningMinute);
    if (picked == null) return;
    setState(() {
      _eveningHour = picked.hour;
      _eveningMinute = picked.minute;
    });
    await _notif.updateEveningTime(picked.hour, picked.minute);
  }

  Future<TimeOfDay?> _showTimePicker(int hour, int minute) {
    return showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: hour, minute: minute),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(
            context,
          ).colorScheme.copyWith(primary: AppColors.blobPeachAccent),
        ),
        child: child!,
      ),
    );
  }

  String _timeLabel(int hour, int minute) {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
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
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Icon(
                  Icons.notifications_active_rounded,
                  color: AppColors.blobPeachAccent,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  '돌보기 리마인더',
                  style: pathLabelFont(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else ...[
            Divider(
              height: 1,
              color: AppColors.blobPeachAccent.withValues(alpha: 0.18),
            ),
            _reminderRow(
              emoji: '🌤️',
              label: '아침 알림',
              value: _morningEnabled,
              onChanged: _onToggleMorning,
              timeLabel: _morningEnabled
                  ? _timeLabel(_morningHour, _morningMinute)
                  : null,
              onPickTime: _pickMorningTime,
            ),
            Divider(
              height: 1,
              color: AppColors.blobPeachAccent.withValues(alpha: 0.18),
            ),
            _reminderRow(
              emoji: '🌙',
              label: '저녁 알림',
              value: _eveningEnabled,
              onChanged: _onToggleEvening,
              timeLabel: _eveningEnabled
                  ? _timeLabel(_eveningHour, _eveningMinute)
                  : null,
              onPickTime: _pickEveningTime,
            ),
            Divider(
              height: 1,
              color: AppColors.blobPeachAccent.withValues(alpha: 0.18),
            ),
            _reminderRow(
              emoji: '🐈‍⬛',
              label: '위기 알림 (3일 이상 미접속 시)',
              value: _crisisEnabled,
              onChanged: (v) async {
                await _notif.setCrisisEnabled(v);
                if (!mounted) return;
                setState(() => _crisisEnabled = v);
              },
            ),
            Divider(
              height: 1,
              color: AppColors.blobPeachAccent.withValues(alpha: 0.18),
            ),
            _reminderRow(
              emoji: '🔥',
              label: '스트릭 임박 알림 (오늘 미완료 시)',
              value: _streakEnabled,
              onChanged: (v) async {
                await _notif.setStreakEnabled(v);
                if (!mounted) return;
                setState(() => _streakEnabled = v);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _reminderRow({
    required String emoji,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    String? timeLabel,
    VoidCallback? onPickTime,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: bodyFont(fontSize: 12.5, color: AppColors.moon),
            ),
          ),
          if (timeLabel != null && onPickTime != null) ...[
            Material(
              color: Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: onPickTime,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Text(
                    timeLabel,
                    style: bodyFont(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.blobPeachAccent,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.blobPeachAccent,
          ),
        ],
      ),
    );
  }
}

/// 사용자 의견/피드백을 이메일로 보낼 수 있는 카드.
/// 서버 없이도 기기의 이메일 앱을 열어 미리 채워진 제목/본문으로
/// 바로 보낼 수 있게 합니다. 앱 버전·플랫폼 정보를 자동으로 담아
/// 보내주므로, 어떤 사용자가 어떤 상황에서 의견을 남겼는지 파악하기
/// 쉬워집니다.
class _FeedbackCard extends StatefulWidget {
  const _FeedbackCard();

  @override
  State<_FeedbackCard> createState() => _FeedbackCardState();
}

class _FeedbackCardState extends State<_FeedbackCard> {
  static const _feedbackEmail = 'antigone.ej@gmail.com';

  bool _sending = false;

  Future<void> _openFeedback() async {
    if (_sending) return;
    setState(() => _sending = true);
    try {
      String versionInfo = '';
      try {
        final info = await PackageInfo.fromPlatform();
        versionInfo = '앱 버전: ${info.version}+${info.buildNumber}';
      } catch (_) {
        // 버전 정보를 못 가져와도 피드백 발송 자체는 계속 진행합니다.
      }
      String platformInfo = 'Platform: web';
      if (!kIsWeb) {
        try {
          platformInfo =
              'Platform: ${Platform.operatingSystem} '
              '${Platform.operatingSystemVersion}';
        } catch (_) {
          // ignore
        }
      }

      final body =
          '여기에 의견을 자유롭게 적어주세요! 😊\n\n\n\n'
          '─────────────────\n'
          '(아래 정보는 문제 파악에 도움이 되니 지우지 말아주세요)\n'
          '$versionInfo\n'
          '$platformInfo';

      final uri = Uri(
        scheme: 'mailto',
        path: _feedbackEmail,
        query: _encodeQuery({'subject': '[고양이 그림자 정원] 의견 보내기', 'body': body}),
      );

      final launched = await launchUrl(uri);
      if (!launched && mounted) {
        _showFallback();
      }
    } catch (_) {
      if (mounted) _showFallback();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _showFallback() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('이메일 앱을 열 수 없어요. $_feedbackEmail 로 직접 보내주세요.')),
    );
  }

  String _encodeQuery(Map<String, String> params) {
    return params.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&');
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: _openFeedback,
        child: GlassBlob(
          accent: AppColors.blobMintAccent,
          background: AppColors.blobMint,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
                child: const Text('💌', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '의견 보내기',
                      style: pathLabelFont(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '더 좋은 정원을 만드는 데 목소리를 들려주세요',
                      style: bodyFont(fontSize: 11.5, color: AppColors.inkSoft),
                    ),
                  ],
                ),
              ),
              if (_sending)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.blobMintAccent,
                  size: 20,
                ),
            ],
          ),
        ),
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
