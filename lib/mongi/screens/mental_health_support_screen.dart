import '../../theme.dart' show AppColors;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/gen/app_localizations.dart';
import 'nearby_counseling_screen.dart';
import 'safety_plan_screen.dart';

/// "마음이 힘들 때" - 정신건강 위기 상담 및 자살예방 관련 공식 안내를
/// 모아 보여주는 화면.
///
/// 이 화면은 절대 진단/상담을 대신하지 않는다. 몽이는 어디까지나 감정을
/// 가볍게 마주하고 기록하도록 돕는 도구일 뿐, 실제로 마음이 많이 힘든
/// 상황에서는 전문 상담기관과 연결되는 것이 훨씬 중요하다는 걸 분명히
/// 안내하고, 그 연결을 최대한 쉽게(탭 한 번으로 전화 연결) 만드는 것이
/// 이 화면의 유일한 목적이다.
///
/// 표시하는 번호는 모두 대한민국 보건복지부 공식 상담 채널이다(2025년
/// 기준). 번호 자체가 바뀔 수 있으므로, 값은 이 파일 상단에 상수로 모아
/// 관리한다.
///
/// 한국어가 아닌 로케일(영어 등)에서는 위 한국 번호가 걸리지 않으므로,
/// [_globalHelplineMeta]의 글로벌 자원(Find A Helpline 디렉토리 + 미국
/// 예시 번호)으로 대체해 보여준다. 전화가 아닌 항목(디렉토리 웹사이트,
/// 문자상담)은 number 대신 [_HelplineNumberEmojiColor.url]을 사용한다.
class MentalHealthSupportScreen extends StatelessWidget {
  const MentalHealthSupportScreen({super.key});

  static const List<_HelplineNumberEmojiColor> _helplineMeta = [
    _HelplineNumberEmojiColor(
      emoji: '🆘',
      number: '109',
      color: Color(0xFFE86A5B),
    ),
    _HelplineNumberEmojiColor(
      emoji: '💬',
      number: '1577-0199',
      color: Color(0xFF5FB8AE),
    ),
    _HelplineNumberEmojiColor(
      emoji: '🧒',
      number: '1388',
      color: Color(0xFFE0A72E),
    ),
    _HelplineNumberEmojiColor(
      emoji: '🚨',
      number: '112',
      color: Color(0xFF6B5B95),
    ),
  ];

  /// 한국어가 아닌 로케일에서 사용하는 글로벌 자원 목록.
  /// 1) Find A Helpline - 130개국 이상 상담 전화 디렉토리(전화 없이 웹으로 연결)
  /// 2) 988 - 미국 자살예방/위기 상담(전화)
  /// 3) Crisis Text Line - 미국 문자상담(전화 대신 문자 발송)
  /// 4) SAMHSA - 미국 정신건강/약물 상담(전화)
  static const List<_HelplineNumberEmojiColor> _globalHelplineMeta = [
    _HelplineNumberEmojiColor(
      emoji: '🌍',
      url: 'https://findahelpline.com',
      color: Color(0xFF5FB8AE),
    ),
    _HelplineNumberEmojiColor(number: '988', color: Color(0xFFE86A5B)),
    _HelplineNumberEmojiColor(
      emoji: '💬',
      number: '741741',
      color: Color(0xFFE0A72E),
      isSms: true,
      smsBody: 'HOME',
    ),
    _HelplineNumberEmojiColor(
      emoji: '🧠',
      number: '1-800-662-4357',
      color: Color(0xFF7A6C8C),
    ),
  ];

  bool _isKorean(BuildContext context) =>
      Localizations.localeOf(context).languageCode != 'en';

  Future<void> _call(BuildContext context, String number) async {
    final l10n = AppLocalizations.of(context);
    final uri = Uri(scheme: 'tel', path: number);
    final ok = await launchUrl(uri);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.mentalHealthCallFailedSnackbar(number))),
      );
    }
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final l10n = AppLocalizations.of(context);
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.mentalHealthActionFailedSnackbar(url))),
      );
    }
  }

  /// 문자(SMS) 상담용 - 전화(tel:)가 아니라 sms: 스킴으로 연다.
  /// 예: 미국 Crisis Text Line은 741741로 "전화"가 아니라 "HOME" 문자를
  /// 보내야 하므로, tel: 스킴을 쓰면 안 된다.
  Future<void> _sendSms(
    BuildContext context,
    String number, {
    String? body,
  }) async {
    final l10n = AppLocalizations.of(context);
    final uri = Uri(
      scheme: 'sms',
      path: number,
      queryParameters: body != null ? {'body': body} : null,
    );
    final ok = await launchUrl(uri);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.mentalHealthSmsFailedSnackbar(number))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isKorean = _isKorean(context);
    final helplines = isKorean
        ? [
            _HelplineInfo(
              emoji: _helplineMeta[0].emoji,
              name: l10n.mentalHealthHelpline1Name,
              number: _helplineMeta[0].number,
              description: l10n.mentalHealthHelpline1Desc,
              color: _helplineMeta[0].color,
            ),
            _HelplineInfo(
              emoji: _helplineMeta[1].emoji,
              name: l10n.mentalHealthHelpline2Name,
              number: _helplineMeta[1].number,
              description: l10n.mentalHealthHelpline2Desc,
              color: _helplineMeta[1].color,
            ),
            _HelplineInfo(
              emoji: _helplineMeta[2].emoji,
              name: l10n.mentalHealthHelpline3Name,
              number: _helplineMeta[2].number,
              description: l10n.mentalHealthHelpline3Desc,
              color: _helplineMeta[2].color,
            ),
            _HelplineInfo(
              emoji: _helplineMeta[3].emoji,
              name: l10n.mentalHealthHelpline4Name,
              number: _helplineMeta[3].number,
              description: l10n.mentalHealthHelpline4Desc,
              color: _helplineMeta[3].color,
            ),
          ]
        : [
            _HelplineInfo(
              emoji: _globalHelplineMeta[0].emoji,
              name: l10n.mentalHealthGlobalHelpline1Name,
              url: _globalHelplineMeta[0].url,
              description: l10n.mentalHealthGlobalHelpline1Desc,
              color: _globalHelplineMeta[0].color,
            ),
            _HelplineInfo(
              emoji: _globalHelplineMeta[1].emoji,
              name: l10n.mentalHealthGlobalHelpline2Name,
              number: _globalHelplineMeta[1].number,
              description: l10n.mentalHealthGlobalHelpline2Desc,
              color: _globalHelplineMeta[1].color,
            ),
            _HelplineInfo(
              emoji: _globalHelplineMeta[2].emoji,
              name: l10n.mentalHealthGlobalHelpline3Name,
              number: _globalHelplineMeta[2].number,
              description: l10n.mentalHealthGlobalHelpline3Desc,
              color: _globalHelplineMeta[2].color,
              isSms: _globalHelplineMeta[2].isSms,
              smsBody: _globalHelplineMeta[2].smsBody,
            ),
            _HelplineInfo(
              emoji: _globalHelplineMeta[3].emoji,
              name: l10n.mentalHealthGlobalHelpline4Name,
              number: _globalHelplineMeta[3].number,
              description: l10n.mentalHealthGlobalHelpline4Desc,
              color: _globalHelplineMeta[3].color,
            ),
          ];
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
                      if (!isKorean) ...[
                        const SizedBox(height: 14),
                        _buildGlobalIntroNote(l10n),
                      ],
                      const SizedBox(height: 20),
                      Text(
                        l10n.mentalHealthCallSectionTitle,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...helplines.map(
                        (h) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _HelplineCard(
                            info: h,
                            openLabel: l10n.mentalHealthOpenButtonLabel,
                            smsLabel: l10n.mentalHealthSendSmsButtonLabel,
                            onAction: () {
                              if (h.url != null) {
                                _openUrl(context, h.url!);
                              } else if (h.isSms) {
                                _sendSms(context, h.number!, body: h.smsBody);
                              } else {
                                _call(context, h.number!);
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildNearbyCounselingEntryCard(context, l10n),
                      const SizedBox(height: 12),
                      _buildSafetyPlanEntryCard(context, l10n),
                      const SizedBox(height: 16),
                      _buildSignsCard(l10n),
                      const SizedBox(height: 16),
                      _buildFooterNote(l10n, isKorean: isKorean),
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
              l10n.mentalHealthHeaderTitle,
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
            l10n.mentalHealthIntroBody1,
            style: const TextStyle(
              fontSize: 13.5,
              color: AppColors.ink,
              height: 1.6,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.mentalHealthIntroBody2,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.inkSoft,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyCounselingEntryCard(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF5FB8AE).withValues(alpha: 0.25),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NearbyCounselingScreen()),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text('📍', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.mentalHealthNearbyCounselingTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.mentalHealthNearbyCounselingSubtitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.inkSoft,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSafetyPlanEntryCard(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF7A6C8C).withValues(alpha: 0.25),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const SafetyPlanScreen()));
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text('🧭', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.mentalHealthSafetyPlanTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.mentalHealthSafetyPlanSubtitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.inkSoft,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignsCard(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E9),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.mentalHealthSignsTitle,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 10),
          _SignItem(text: l10n.mentalHealthSign1),
          _SignItem(text: l10n.mentalHealthSign2),
          _SignItem(text: l10n.mentalHealthSign3),
          _SignItem(text: l10n.mentalHealthSign4),
          const SizedBox(height: 4),
          Text(
            l10n.mentalHealthSignsFooter,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.inkSoft,
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalIntroNote(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF5FB8AE).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        l10n.mentalHealthGlobalIntroNote,
        style: const TextStyle(
          fontSize: 11.5,
          color: AppColors.ink,
          height: 1.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildFooterNote(AppLocalizations l10n, {required bool isKorean}) {
    return Text(
      isKorean
          ? l10n.mentalHealthFooterNote
          : l10n.mentalHealthGlobalFooterNote,
      style: const TextStyle(
        fontSize: 10.5,
        color: Color(0xFFB0A79D),
        height: 1.6,
      ),
    );
  }
}

/// 헬프라인의 다국어와 무관한 고정 값(이모지/전화번호/색상)만 모아둔 작은
/// 데이터 클래스. 이름/설명은 다국어 문구이므로 build() 시점에
/// AppLocalizations로 별도로 채운다.
class _HelplineNumberEmojiColor {
  final String emoji;
  final String? number;
  final String? url;
  final Color color;
  final bool isSms;
  final String? smsBody;

  const _HelplineNumberEmojiColor({
    this.emoji = '',
    this.number,
    this.url,
    required this.color,
    this.isSms = false,
    this.smsBody,
  });
}

class _HelplineInfo {
  final String emoji;
  final String name;
  final String? number;
  final String? url;
  final String description;
  final Color color;
  final bool isSms;
  final String? smsBody;

  const _HelplineInfo({
    required this.emoji,
    required this.name,
    this.number,
    this.url,
    required this.description,
    required this.color,
    this.isSms = false,
    this.smsBody,
  });

  /// 카드에 표시할 액션 라벨(전화번호 또는 "문자 보내기"/"열기" 텍스트).
  String actionLabel(String openLabel, String smsLabel) {
    if (isSms) return smsLabel;
    return number ?? openLabel;
  }
}

class _HelplineCard extends StatelessWidget {
  final _HelplineInfo info;
  final String openLabel;
  final String smsLabel;
  final VoidCallback onAction;

  const _HelplineCard({
    required this.info,
    required this.openLabel,
    required this.smsLabel,
    required this.onAction,
  });

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
        onTap: onAction,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: info.color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Text(info.emoji, style: const TextStyle(fontSize: 20)),
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
                    const SizedBox(height: 2),
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
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: info.color,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      info.isSms
                          ? Icons.sms
                          : (info.number != null
                                ? Icons.call
                                : Icons.open_in_new),
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      info.actionLabel(openLabel, smsLabel),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignItem extends StatelessWidget {
  final String text;

  const _SignItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '· ',
            style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.ink,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
