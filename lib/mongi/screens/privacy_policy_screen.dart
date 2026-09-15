import '../../theme.dart' show AppColors;
import 'package:flutter/material.dart';
import '../l10n/gen/app_localizations.dart';
import '../services/consent_service.dart';

/// 개인정보처리방침 화면.
///
/// 몽이는 로그인/회원가입이 없는 "로컬 전용" 앱이라 수집하는 개인정보 자체가
/// 매우 적지만, 다음 두 가지 이유로 이 화면이 반드시 필요하다:
/// 1) AdMob(광고 식별자 등) / Google Play Billing(인앱 결제) SDK를 쓰는 앱은
///    로그인 여부와 무관하게 Google Play 등록 시 개인정보처리방침이 필수다.
/// 2) 사용자가 "이 앱이 내 감정 일기를 어디로 보내는지" 스스로 확인할 수 있어야
///    한다 - 실제로는 서버 전송이 없고 전부 기기에만 저장된다는 점이 오히려
///    이 앱의 프라이버시 강점이므로, 이를 명확히 알리는 것 자체가 신뢰 요소다.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  /// 문의 연락처 - 실제 배포 전 담당 이메일로 교체해야 한다.
  static const String _contactEmail = 'healinggarden.mongi@gmail.com';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.bg0,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, l10n),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildIntroCard(l10n),
                    const SizedBox(height: 16),
                    _buildAdConsentCard(context, l10n),
                    const SizedBox(height: 16),
                    _buildSection(
                      emoji: '🔐',
                      title: l10n.privacySection1Title,
                      body: l10n.privacySection1Body,
                    ),
                    _buildSection(
                      emoji: '📱',
                      title: l10n.privacySection2Title,
                      body: l10n.privacySection2Body,
                    ),
                    _buildSection(
                      emoji: '📊',
                      title: l10n.privacySection3Title,
                      body: l10n.privacySection3Body,
                    ),
                    _buildSection(
                      emoji: '💳',
                      title: l10n.privacySection4Title,
                      body: l10n.privacySection4Body,
                    ),
                    _buildSection(
                      emoji: '🔔',
                      title: l10n.privacySection5Title,
                      body: l10n.privacySection5Body,
                    ),
                    _buildSection(
                      emoji: '🧒',
                      title: l10n.privacySection6Title,
                      body: l10n.privacySection6Body,
                    ),
                    _buildSection(
                      emoji: '✉️',
                      title: l10n.privacySection7Title,
                      body: l10n.privacySection7Body(_contactEmail),
                    ),
                    _buildSection(
                      emoji: '📝',
                      title: l10n.privacySection8Title,
                      body: l10n.privacySection8Body,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.privacyLastUpdatedLabel(l10n.privacyLastUpdatedDate),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.inkSoft,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
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
            l10n.privacyHeaderTitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroCard(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFF8FAB).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🐾', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.privacyIntro,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6B5D52),
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// EEA(유럽경제지역)·영국 등에서는 사용자가 맞춤 광고 동의 여부를 언제든
  /// 다시 확인/변경할 수 있어야 한다(Google UMP 요구사항). 대상 지역이
  /// 아니거나 아직 준비되지 않았으면 안내 스낵바만 보여준다.
  Widget _buildAdConsentCard(BuildContext context, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🍪', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.privacyAdConsentTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            l10n.privacyAdConsentBody,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B5D52),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.ink,
                side: const BorderSide(color: Color(0xFFDDD0C4)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () async {
                final opened = await ConsentService.instance
                    .showPrivacyOptionsFormIfRequired();
                if (!opened && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.privacyAdConsentNotAvailable)),
                  );
                }
              },
              child: Text(
                l10n.privacyAdConsentButton,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String emoji,
    required String title,
    required String body,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              body,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6B5D52),
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
