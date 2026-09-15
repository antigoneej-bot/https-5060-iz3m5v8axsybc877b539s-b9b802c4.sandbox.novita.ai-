import '../../theme.dart' show AppColors;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/gen/app_localizations.dart';
import '../l10n/safety_plan_l10n.dart';
import '../models/safety_plan.dart';
import '../providers/garden_provider.dart';

/// "나만의 안전 계획" - 마음이 힘들어지기 전에 미리 준비해두는 짧은 메모장.
///
/// 정신건강 위기개입에서 쓰이는 안전 계획(Safety Planning) 개념을 참고해,
/// "위험 신호 → 스스로 할 수 있는 것 → 도움 요청할 사람 → 안심되는 장소 →
/// 소중한 이유" 순서로 가볍게 구성했다. 절대 진단/치료 도구가 아니고,
/// 작성한 내용은 이 기기(Hive)에만 저장되며 서버로 전송되지 않는다.
///
/// 평온할 때 미리 써두면, 정작 마음이 힘들어졌을 때 "무엇부터 해야 할지"를
/// 스스로 떠올리기 어려운 순간에 큰 도움이 될 수 있다는 것이 핵심 설계 의도다.
class SafetyPlanScreen extends StatefulWidget {
  const SafetyPlanScreen({super.key});

  @override
  State<SafetyPlanScreen> createState() => _SafetyPlanScreenState();
}

class _SafetyPlanScreenState extends State<SafetyPlanScreen> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, bool> _editing = {};

  @override
  void initState() {
    super.initState();
    final garden = context.read<GardenProvider>();
    for (final section in SafetyPlanSection.all) {
      _controllers[section.id] = TextEditingController(
        text: garden.safetyPlan[section.id] ?? '',
      );
      _editing[section.id] = false;
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save(String sectionId) async {
    final l10n = AppLocalizations.of(context);
    final garden = context.read<GardenProvider>();
    await garden.saveSafetyPlanSection(
      sectionId,
      _controllers[sectionId]!.text,
    );
    if (!mounted) return;
    setState(() => _editing[sectionId] = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.safetyPlanSavedSnackbar),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  bool get _isKorean => Localizations.localeOf(context).languageCode != 'en';

  Future<void> _callNow() async {
    final l10n = AppLocalizations.of(context);
    if (_isKorean) {
      final uri = Uri(scheme: 'tel', path: '109');
      final ok = await launchUrl(uri);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.safetyPlanCallFailedSnackbar)),
        );
      }
    } else {
      final uri = Uri.parse('https://findahelpline.com');
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.safetyPlanGlobalOpenFailedSnackbar)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildIntroCard(context),
                      const SizedBox(height: 18),
                      ...SafetyPlanSection.all.map(
                        (s) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _buildSectionCard(context, s),
                        ),
                      ),
                      const SizedBox(height: 6),
                      _buildEmergencyCard(context),
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
              AppLocalizations.of(context).safetyPlanHeaderTitle,
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

  Widget _buildIntroCard(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
            l10n.safetyPlanIntroLine1,
            style: const TextStyle(
              fontSize: 13.5,
              color: AppColors.ink,
              height: 1.6,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.safetyPlanIntroLine2,
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

  Widget _buildSectionCard(BuildContext context, SafetyPlanSection section) {
    final l10n = AppLocalizations.of(context);
    final sectionText = safetyPlanSectionText(l10n, section);
    final controller = _controllers[section.id]!;
    final isEditing = _editing[section.id] ?? false;
    final hasContent = controller.text.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(section.emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  sectionText.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.ink,
                  ),
                ),
              ),
              if (!isEditing)
                IconButton(
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: AppColors.inkSoft,
                  ),
                  onPressed: () => setState(() => _editing[section.id] = true),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            sectionText.hint,
            style: const TextStyle(
              fontSize: 11.5,
              color: AppColors.inkSoft,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          if (isEditing) ...[
            TextField(
              controller: controller,
              maxLines: 3,
              minLines: 2,
              style: const TextStyle(fontSize: 13, color: AppColors.ink),
              decoration: InputDecoration(
                hintText: sectionText.placeholder,
                hintStyle: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFFBDB3A8),
                ),
                filled: true,
                fillColor: AppColors.bg0,
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    controller.text =
                        context.read<GardenProvider>().safetyPlan[section.id] ??
                        '';
                    setState(() => _editing[section.id] = false);
                  },
                  child: Text(
                    l10n.commonCancel,
                    style: const TextStyle(color: AppColors.inkSoft),
                  ),
                ),
                const SizedBox(width: 4),
                ElevatedButton(
                  onPressed: () => _save(section.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7A6C8C),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(l10n.safetyPlanSaveButton),
                ),
              ],
            ),
          ] else
            GestureDetector(
              onTap: () => setState(() => _editing[section.id] = true),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bg0,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  hasContent
                      ? controller.text
                      : l10n.safetyPlanTapToWriteHint(sectionText.placeholder),
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.5,
                    color: hasContent ? AppColors.ink : const Color(0xFFBDB3A8),
                    fontWeight: hasContent ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmergencyCard(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isKorean = _isKorean;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7A6C8C), Color(0xFF5B9BD5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: _callNow,
        child: Row(
          children: [
            const Text('🆘', style: TextStyle(fontSize: 26)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.safetyPlanEmergencyTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isKorean
                        ? l10n.safetyPlanEmergencySubtitle
                        : l10n.safetyPlanGlobalEmergencySubtitle,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isKorean ? Icons.call : Icons.open_in_new,
                    color: const Color(0xFF7A6C8C),
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isKorean ? '109' : l10n.safetyPlanGlobalButtonLabel,
                    style: const TextStyle(
                      color: Color(0xFF7A6C8C),
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
    );
  }
}
