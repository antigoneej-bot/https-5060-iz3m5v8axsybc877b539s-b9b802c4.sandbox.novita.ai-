import '../../theme.dart' show AppColors;
import 'package:flutter/material.dart';
import '../l10n/gen/app_localizations.dart';

/// 이용약관 화면.
///
/// 몽이는 인앱 결제(Google Play Billing)와 광고(AdMob)를 사용하는 앱이라,
/// 분쟁 예방과 Google Play 정책 준수를 위해 결제/광고/면책 조항을 명시한
/// 이용약관을 제공한다. 개인정보처리방침(PrivacyPolicyScreen)과 동일한
/// 시각적 스타일을 그대로 따른다.
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

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
                    _buildSection(
                      emoji: '🌱',
                      title: l10n.termsSection1Title,
                      body: l10n.termsSection1Body,
                    ),
                    _buildSection(
                      emoji: '💳',
                      title: l10n.termsSection2Title,
                      body: l10n.termsSection2Body,
                    ),
                    _buildSection(
                      emoji: '📢',
                      title: l10n.termsSection3Title,
                      body: l10n.termsSection3Body,
                    ),
                    _buildSection(
                      emoji: '🙏',
                      title: l10n.termsSection4Title,
                      body: l10n.termsSection4Body,
                    ),
                    _buildSection(
                      emoji: '🤍',
                      title: l10n.termsSection5Title,
                      body: l10n.termsSection5Body,
                    ),
                    _buildSection(
                      emoji: '📝',
                      title: l10n.termsSection6Title,
                      body: l10n.termsSection6Body,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.termsLastUpdatedLabel(l10n.termsLastUpdatedDate),
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
            l10n.termsHeaderTitle,
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
          const Text('📜', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.termsIntro,
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
