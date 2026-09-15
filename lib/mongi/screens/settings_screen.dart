import '../../theme.dart' show AppColors;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/gen/app_localizations.dart';
import '../l10n/notification_l10n.dart';
import '../providers/garden_provider.dart';
import 'mental_health_support_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_service_screen.dart';

/// "설정" - 매일 리마인더 알림 On/Off 및 시각을 조절하는 화면.
/// 리텐션 강화를 위한 가장 기본적인 장치이며, 결제와는 무관하게 모두 무료로 제공한다.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final garden = context.watch<GardenProvider>();

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF3E9), AppColors.bg0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildNotificationCard(context, garden),
                      if (kIsWeb) ...[
                        const SizedBox(height: 12),
                        _buildWebNotice(context),
                      ],
                      const SizedBox(height: 20),
                      _buildAiReflectionCard(context, garden),
                      const SizedBox(height: 20),
                      _buildMentalHealthSupportCard(context),
                      const SizedBox(height: 20),
                      _buildDataNoticeCard(context),
                      const SizedBox(height: 20),
                      _buildPrivacyPolicyCard(context),
                      const SizedBox(height: 12),
                      _buildTermsOfServiceCard(context),
                      const SizedBox(height: 20),
                      _buildResetCard(context, garden),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.ink),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 4),
          Text(
            l10n.settingsHeader,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, GardenProvider garden) {
    final l10n = AppLocalizations.of(context);
    final timeLabel =
        '${garden.notificationHour.toString().padLeft(2, '0')}:${garden.notificationMinute.toString().padLeft(2, '0')}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.roseStrong.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Text('🔔', style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.settingsNotifTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.ink,
                  ),
                ),
              ),
              Switch(
                value: garden.notificationsEnabled,
                activeThumbColor: AppColors.roseStrong,
                onChanged: kIsWeb
                    ? null
                    : (value) async {
                        final ok = await garden.setNotificationsEnabled(
                          value,
                          notificationContent: notificationContent(l10n),
                        );
                        if (!ok && value && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.settingsNotifPermissionDenied),
                            ),
                          );
                        }
                      },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.settingsNotifDesc,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.inkSoft,
              height: 1.5,
            ),
          ),
          if (garden.notificationsEnabled && !kIsWeb) ...[
            const SizedBox(height: 16),
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _pickTime(context, garden),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 18,
                      color: AppColors.ink,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      l10n.settingsNotifTimeLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      timeLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.roseStrong,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: AppColors.inkSoft,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 몽이는 로그인/회원가입이 없어 모든 정원·일기·진행도가 이 기기의
  /// 로컬 저장소에만 보관된다. 앱 삭제나 기기 변경 시 데이터가 함께
  /// 사라지고, 구매 내역만 구글 계정으로 복원된다는 점을 사용자가
  /// 미리 알 수 있도록 안내하는 카드.
  Widget _buildDataNoticeCard(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC078).withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Text('📱', style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.settingsDataNoticeTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.settingsDataNoticeBody,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.inkSoft,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// 정신건강 위기상담/자살예방 안내 화면으로 이동하는 카드.
  /// 설정 화면 어디서나 언제든 접근 가능하도록 상시 노출한다 - 특별한
  /// 신호가 없어도, 필요할 때 스스로 찾아올 수 있는 문이 되어준다.
  Widget _buildMentalHealthSupportCard(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7A6C8C), Color(0xFF5B9BD5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const MentalHealthSupportScreen(),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Text('🤍', style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.settingsMentalHealthTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.settingsMentalHealthSubtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  /// "마음 성찰" (옵트인 AI 리플렉션, 벤치마킹 #6) 사용 동의 토글 카드.
  /// 여러 감정 기록을 종합해서 보여주는 만큼 평소 화면보다 더 개인적으로
  /// 느껴질 수 있어, 기본값은 꺼짐이며 사용자가 직접 켜야만 [MindReportScreen]에
  /// 리플렉션 카드가 노출된다. 서버/외부 AI로 전송되는 데이터는 전혀 없다.
  Widget _buildAiReflectionCard(BuildContext context, GardenProvider garden) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF5FB8AE).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Text('🌿', style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.settingsAiReflectionTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.ink,
                  ),
                ),
              ),
              Switch(
                value: garden.aiReflectionOptIn,
                activeThumbColor: const Color(0xFF5FB8AE),
                onChanged: (value) => garden.setAiReflectionOptIn(value),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.settingsAiReflectionDesc,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.inkSoft,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// 개인정보처리방침 화면으로 이동하는 카드.
  /// AdMob·Google Play 결제를 쓰는 앱은 로그인 여부와 무관하게
  /// 개인정보처리방침 안내가 필요하므로 설정 화면에 항상 노출한다.
  Widget _buildPrivacyPolicyCard(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF7EB8DA).withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Text('🔒', style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.settingsPrivacyPolicy,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.ink,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: AppColors.inkSoft,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 이용약관 화면으로 이동하는 카드.
  /// 인앱 결제·광고를 다루는 앱이라 개인정보처리방침과 함께 항상 노출한다.
  Widget _buildTermsOfServiceCard(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TermsOfServiceScreen()),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF9A8AC9).withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Text('📜', style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.settingsTermsOfService,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.ink,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: AppColors.inkSoft,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 테스트/체험용 - 스테이지, 재화, 코스튬 등 이 기기에 쌓인 진행도를 전부
  /// 지우고 1단계 온보딩부터 처음 다시 시작할 수 있는 카드. 되돌릴 수 없는
  /// 동작이라 항상 확인 다이얼로그를 먼저 보여준다.
  Widget _buildResetCard(BuildContext context, GardenProvider garden) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Text('🔄', style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.settingsResetTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.settingsResetDesc,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.inkSoft,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => _confirmReset(context, garden),
              child: Text(
                l10n.settingsResetButton,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(
    BuildContext context,
    GardenProvider garden,
  ) async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('통합 정원 기록을 보호하기 위해 전체 초기화는 지원하지 않아요.')));
  }

  Widget _buildWebNotice(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        l10n.settingsWebNotice,
        style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
      ),
    );
  }

  Future<void> _pickTime(BuildContext context, GardenProvider garden) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: garden.notificationHour,
        minute: garden.notificationMinute,
      ),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(
            ctx,
          ).colorScheme.copyWith(primary: AppColors.roseStrong),
        ),
        child: child!,
      ),
    );
    if (picked != null && context.mounted) {
      final l10n = AppLocalizations.of(context);
      await garden.setNotificationTime(
        picked.hour,
        picked.minute,
        notificationContent: notificationContent(l10n),
      );
    }
  }
}
