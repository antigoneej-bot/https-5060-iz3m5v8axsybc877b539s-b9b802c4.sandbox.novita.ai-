import '../../theme.dart' show AppColors;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/emotion_l10n.dart';
import '../l10n/emotion_trigger_l10n.dart';
import '../l10n/gen/app_localizations.dart';
import '../models/emotion.dart';
import '../models/emotion_trigger.dart';
import '../providers/garden_provider.dart';
import '../widgets/emotion_share_sheet.dart';

/// "감정 다이어리" - 스테이지를 클리어할 때마다 남긴 한 줄 기록을
/// 최신순으로 모아 보는 화면.
class DiaryScreen extends StatelessWidget {
  const DiaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final garden = context.watch<GardenProvider>();
    final entries = garden.diaryEntries;
    final l10n = AppLocalizations.of(context);

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
              _buildHeader(context, l10n),
              Expanded(
                child: entries.isEmpty
                    ? _buildEmptyState(l10n)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        itemCount: entries.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _DiaryEntryCard(
                              entry: entries[index],
                              l10n: l10n,
                            ),
                          );
                        },
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
            l10n.diaryHeaderTitle,
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

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              const Text('📔', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 12),
              Text(
                l10n.diaryEmptyTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.diaryEmptySubtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.inkSoft,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 다이어리 한 항목 카드.
class _DiaryEntryCard extends StatelessWidget {
  final Map<String, dynamic> entry;
  final AppLocalizations l10n;

  const _DiaryEntryCard({required this.entry, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final emotion = Emotion.byTypeName(entry['emotionType'] as String? ?? '');
    final date = entry['date'] as String? ?? '';
    final targetName = entry['targetName'] as String?;
    final eatenCount = (entry['eatenCount'] as num?)?.toInt() ?? 0;
    final note = entry['note'] as String?;
    final intensity = (entry['intensity'] as num?)?.toInt();
    final triggerIds = (entry['triggers'] as List?)
        ?.whereType<String>()
        .toList();

    final localizedEmotionLabel = emotionLabel(l10n, emotion.type);
    final nameLabel = (targetName != null && targetName.isNotEmpty)
        ? l10n.diaryNameLabel(targetName, localizedEmotionLabel)
        : localizedEmotionLabel;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: emotion.color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: emotion.color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  emotion.gardenIcon,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nameLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: emotion.color,
                      ),
                    ),
                    Text(
                      l10n.milestoneTimelineDateCount(date, eatenCount),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.ios_share,
                  size: 18,
                  color: emotion.color.withValues(alpha: 0.8),
                ),
                tooltip: l10n.diaryShareTooltip,
                onPressed: () => EmotionShareSheet.show(
                  context,
                  emotion: emotion,
                  targetName: targetName,
                  eatenCount: eatenCount,
                  maxCombo: 0,
                  choseLove: true,
                  note: note ?? '',
                ),
              ),
            ],
          ),
          if (note != null && note.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bg0,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '"$note"',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.inkSoft,
                  height: 1.4,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
          if ((intensity != null && intensity >= 1 && intensity <= 5) ||
              (triggerIds != null && triggerIds.isNotEmpty)) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (intensity != null && intensity >= 1 && intensity <= 5)
                  _MiniTag(
                    label: l10n.calendarIntensityLabel(
                      '${'●' * intensity}${'○' * (5 - intensity)}',
                    ),
                    color: emotion.color,
                  ),
                if (triggerIds != null)
                  for (final id in triggerIds)
                    _MiniTag(
                      label: emotionTriggerDisplay(
                        l10n,
                        EmotionTrigger.byId(id),
                      ),
                      color: AppColors.inkSoft,
                    ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// 다이어리 카드 안에서 강도/트리거를 작게 보여주는 알약 모양 태그.
class _MiniTag extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: color.withValues(alpha: 0.85),
        ),
      ),
    );
  }
}
