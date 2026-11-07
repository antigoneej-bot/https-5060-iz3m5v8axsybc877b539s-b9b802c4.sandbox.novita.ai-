import '../../theme.dart' show AppColors;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/gen/app_localizations.dart';
import '../l10n/gratitude_entry_type_l10n.dart';
import '../models/gratitude_entry_type.dart';
import '../providers/garden_provider.dart';

/// "감사 한 줄 / 작은 성취 기록" - 게임 세션과 무관하게 하루 중 언제든
/// 가볍게 남길 수 있는 긍정 기록 화면.
///
/// 감정 다이어리([DiaryScreen])와는 별개로 존재하는 이유:
/// - 감정 다이어리는 러너 게임 한 판이 끝나야만 남길 수 있는 "감정 회고"고,
/// - 이 화면은 게임을 하지 않은 날에도, 하루 중 아무 때나 "오늘 감사했던
///   것/작은 성취"를 즉시 남길 수 있는 훨씬 가벼운 습관 기록이다.
class GratitudeLogScreen extends StatefulWidget {
  const GratitudeLogScreen({super.key});

  @override
  State<GratitudeLogScreen> createState() => _GratitudeLogScreenState();
}

class _GratitudeLogScreenState extends State<GratitudeLogScreen> {
  GratitudeEntryType _selectedType = GratitudeEntryType.gratitude;
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final l10n = AppLocalizations.of(context);
    final garden = context.read<GardenProvider>();
    await garden.addGratitudeEntry(type: _selectedType.id, text: text);
    _controller.clear();
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    // "1번 개선": 오늘 첫 기록이었다면 방금 시즌 경험치가 함께 지급됐을 것이고,
    // 그 경험치로 "마음 마일스톤"에 막 도달했다면 그 문구를 우선 보여준다
    // (매일 습관처럼 남기는 이 화면이 시즌 패스와도 자연스럽게 연결되도록).
    final milestoneMessage = garden.lastSeasonMilestoneMessage;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          milestoneMessage != null
              ? l10n.seasonMilestoneSnackbar(milestoneMessage)
              : l10n.gratitudeLogSubmittedSnackbar(_selectedType.emoji),
        ),
        duration: Duration(seconds: milestoneMessage != null ? 4 : 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final garden = context.watch<GardenProvider>();
    final entries = garden.gratitudeEntries;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF7E0), AppColors.bg0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, l10n),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    _buildIntroCard(l10n),
                    const SizedBox(height: 16),
                    _buildInputCard(l10n),
                    const SizedBox(height: 20),
                    if (entries.isEmpty)
                      _buildEmptyState(l10n)
                    else
                      ...List.generate(entries.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _GratitudeEntryCard(
                            l10n: l10n,
                            entry: entries[index],
                            onDelete: () => garden.removeGratitudeEntry(index),
                          ),
                        );
                      }),
                  ],
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
          Text(
            l10n.gratitudeLogHeaderTitle,
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

  Widget _buildIntroCard(AppLocalizations l10n) {
    return Text(
      l10n.gratitudeLogIntro,
      style: const TextStyle(
        fontSize: 12.5,
        color: AppColors.inkSoft,
        height: 1.5,
      ),
    );
  }

  Widget _buildInputCard(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
            children: GratitudeEntryType.values.map((type) {
              final selected = _selectedType == type;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedType = type),
                  child: Container(
                    margin: EdgeInsets.only(
                      right: type == GratitudeEntryType.gratitude ? 8 : 0,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFFFFC24B) : AppColors.bg0,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${type.emoji} ${gratitudeEntryTypeLabel(l10n, type)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: selected ? Colors.white : AppColors.inkSoft,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Text(
            gratitudeEntryTypeHint(l10n, _selectedType),
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.inkSoft,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            maxLines: 2,
            maxLength: 60,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              hintText: gratitudeEntryTypePlaceholder(l10n, _selectedType),
              hintStyle: const TextStyle(fontSize: 13),
              filled: true,
              fillColor: AppColors.bg0,
              counterText: '',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC24B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                l10n.gratitudeLogSubmitButton,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            const Text('🌻', style: TextStyle(fontSize: 36)),
            const SizedBox(height: 10),
            Text(
              l10n.gratitudeLogEmptyTitle,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.gratitudeLogEmptySubtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft),
            ),
          ],
        ),
      ),
    );
  }
}

/// 저장된 감사/성취 기록 한 항목 카드.
class _GratitudeEntryCard extends StatelessWidget {
  final AppLocalizations l10n;
  final Map<String, dynamic> entry;
  final VoidCallback onDelete;

  const _GratitudeEntryCard({
    required this.l10n,
    required this.entry,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final type = GratitudeEntryType.fromId(entry['type'] as String?);
    final date = entry['date'] as String? ?? '';
    final text = entry['text'] as String? ?? '';
    final color = type == GratitudeEntryType.gratitude
        ? const Color(0xFFFFC24B)
        : const Color(0xFF7FB37A);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Text(type.emoji, style: const TextStyle(fontSize: 15)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: AppColors.ink,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$date · ${gratitudeEntryTypeLabel(l10n, type)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: AppColors.inkSoft),
            tooltip: l10n.gratitudeLogDeleteTooltip,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
