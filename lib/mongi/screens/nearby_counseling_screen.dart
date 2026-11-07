import '../../theme.dart' show AppColors;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/gen/app_localizations.dart';

/// "내 주변 상담센터 찾기" - 전문 상담기관(정신건강복지센터, 청소년상담복지센터 등)의
/// 위치를 실제로 찾아갈 수 있도록 돕는 화면.
///
/// 이 앱 안에서 직접 지도를 그리거나 위치 권한을 요청하지 않는다(불필요한
/// 권한 요청은 최소화한다는 원칙). 대신:
/// 1) 이미 기기에 있는 지도 앱(Google 지도 등)의 검색 링크를 열어, 지도
///    앱이 알아서 사용자의 현재 위치 근처 상담기관을 보여주게 하고,
/// 2) 보건복지부가 운영하는 공식 "국가정신건강정보포털"의 기관 찾기
///    페이지로 바로 연결해, 신뢰할 수 있는 전체 목록도 확인할 수 있게 한다.
class NearbyCounselingScreen extends StatelessWidget {
  const NearbyCounselingScreen({super.key});

  /// 기관 유형 목록(이름/설명/지도 검색어는 언어별로 다르므로 [l10n]에서
  /// 매번 새로 조합한다 - const 목록으로 두면 다국어를 담을 수 없어서
  /// 기존 [emotion_share_sheet]/[season_pass] 화면과 같은 패턴을 따른다).
  ///
  /// [isKorean]이 false면 지도 검색어를 한국 특화 기관명(정신건강복지센터 등)
  /// 대신 해외에서도 통용되는 범용 검색어(mental health clinic 등)로 바꾼다.
  static List<_CenterTypeInfo> _centerTypes(
    AppLocalizations l10n, {
    required bool isKorean,
  }) => [
    _CenterTypeInfo(
      emoji: '🏥',
      name: l10n.nearbyCenterMentalHealthName,
      description: l10n.nearbyCenterMentalHealthDesc,
      mapQuery: isKorean
          ? l10n.nearbyCenterMentalHealthMapQuery
          : l10n.nearbyCenterMentalHealthMapQueryGlobal,
      color: const Color(0xFF5FB8AE),
    ),
    _CenterTypeInfo(
      emoji: '🧒',
      name: l10n.nearbyCenterYouthName,
      description: l10n.nearbyCenterYouthDesc,
      mapQuery: isKorean
          ? l10n.nearbyCenterYouthMapQuery
          : l10n.nearbyCenterYouthMapQueryGlobal,
      color: const Color(0xFFE0A72E),
    ),
    _CenterTypeInfo(
      emoji: '🌱',
      name: l10n.nearbyCenterSuicidePreventionName,
      description: l10n.nearbyCenterSuicidePreventionDesc,
      mapQuery: isKorean
          ? l10n.nearbyCenterSuicidePreventionMapQuery
          : l10n.nearbyCenterSuicidePreventionMapQueryGlobal,
      color: const Color(0xFFE86A5B),
    ),
    _CenterTypeInfo(
      emoji: '🧠',
      name: l10n.nearbyCenterPsychiatricName,
      description: l10n.nearbyCenterPsychiatricDesc,
      mapQuery: isKorean
          ? l10n.nearbyCenterPsychiatricMapQuery
          : l10n.nearbyCenterPsychiatricMapQueryGlobal,
      color: const Color(0xFF7A6C8C),
    ),
  ];

  Future<void> _openMapSearch(
    BuildContext context,
    AppLocalizations l10n,
    String query,
  ) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}',
    );
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.nearbyMapOpenFailedSnackbar)));
    }
  }

  Future<void> _openOfficialPortal(
    BuildContext context,
    AppLocalizations l10n, {
    required bool isKorean,
  }) async {
    final uri = Uri.parse(
      isKorean
          ? 'https://www.mentalhealth.go.kr/portal/health/fac/PotalHealthFacListTab1.do'
          : 'https://findahelpline.com',
    );
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.nearbyPortalOpenFailedSnackbar)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isKorean = Localizations.localeOf(context).languageCode != 'en';
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE8F0F5), AppColors.bg0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, l10n),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildIntroCard(l10n),
                      const SizedBox(height: 20),
                      Text(
                        l10n.nearbySectionTitle,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ..._centerTypes(l10n, isKorean: isKorean).map(
                        (info) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _CenterTypeCard(
                            info: info,
                            onTap: () =>
                                _openMapSearch(context, l10n, info.mapQuery),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildOfficialPortalCard(
                        context,
                        l10n,
                        isKorean: isKorean,
                      ),
                      const SizedBox(height: 16),
                      _buildFooterNote(l10n),
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
          Expanded(
            child: Text(
              l10n.nearbyHeaderTitle,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroCard(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
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
          const Text('🐱', style: TextStyle(fontSize: 32)),
          const SizedBox(height: 10),
          Text(
            l10n.nearbyIntroCardBody,
            style: const TextStyle(
              fontSize: 13.5,
              color: AppColors.ink,
              height: 1.6,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfficialPortalCard(
    BuildContext context,
    AppLocalizations l10n, {
    required bool isKorean,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF5FB8AE).withValues(alpha: 0.3),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _openOfficialPortal(context, l10n, isKorean: isKorean),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text('🏛️', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isKorean
                          ? l10n.nearbyOfficialPortalTitle
                          : l10n.nearbyGlobalOfficialPortalTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isKorean
                          ? l10n.nearbyOfficialPortalSubtitle
                          : l10n.nearbyGlobalOfficialPortalSubtitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.open_in_new, size: 16, color: AppColors.inkSoft),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooterNote(AppLocalizations l10n) {
    return Text(
      l10n.nearbyFooterNote,
      style: const TextStyle(
        fontSize: 11,
        color: AppColors.inkSoft,
        height: 1.5,
      ),
    );
  }
}

class _CenterTypeInfo {
  final String emoji;
  final String name;
  final String description;
  final String mapQuery;
  final Color color;

  const _CenterTypeInfo({
    required this.emoji,
    required this.name,
    required this.description,
    required this.mapQuery,
    required this.color,
  });
}

class _CenterTypeCard extends StatelessWidget {
  final _CenterTypeInfo info;
  final VoidCallback onTap;

  const _CenterTypeCard({required this.info, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: info.color.withValues(alpha: 0.25)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: info.color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Text(info.emoji, style: const TextStyle(fontSize: 19)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: info.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      info.description,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.inkSoft,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.map_outlined,
                size: 20,
                color: info.color.withValues(alpha: 0.8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
