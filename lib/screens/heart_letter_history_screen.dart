import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/special_letter_entry.dart';
import '../services/special_letter_service.dart';
import '../theme.dart';
import '../widgets/garden_path_card.dart';
import 'heart_letters_screen.dart';
import '../widgets/feature_scaffold.dart';

/// 특정 마음편지 종류(감사·용서·미안함·사랑)의 지난 편지와 답장을
/// 최신순으로 모아보는 화면.
///
/// [HeartLettersScreen]의 답장 결과 화면에서 "지난 편지 보기"를 눌렀을 때
/// 진입합니다. 자체적으로 [FeatureScaffold]를 감싸 뒤로가기와 배경을
/// 다른 화면들과 동일하게 유지합니다.
class HeartLetterHistoryScreen extends StatelessWidget {
  final SpecialLetterType type;
  const HeartLetterHistoryScreen({super.key, required this.type});

  static const Map<SpecialLetterType, ({Color accent, Color background})>
  _palette = {
    SpecialLetterType.gratitude: (
      accent: AppColors.blobButterAccent,
      background: AppColors.blobButter,
    ),
    SpecialLetterType.forgiveness: (
      accent: AppColors.blobPeriwinkleAccent,
      background: AppColors.blobPeriwinkle,
    ),
    SpecialLetterType.apology: (
      accent: AppColors.blobLavenderAccent,
      background: AppColors.blobLavender,
    ),
    SpecialLetterType.love: (
      accent: AppColors.blobRoseAccent,
      background: AppColors.blobRose,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final palette = _palette[type]!;
    final entries = SpecialLetterService.getEntriesOfType(type);
    return FeatureScaffold(
      title: type.label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 4),
          Center(child: Text(type.emoji, style: const TextStyle(fontSize: 30))),
          const SizedBox(height: 8),
          Text(
            '${type.label} 모음',
            textAlign: TextAlign.center,
            style: titleFont(fontSize: 21, color: AppColors.ink),
          ),
          const SizedBox(height: 6),
          Text(
            entries.isEmpty
                ? '아직 쓴 편지가 없어요'
                : '지금까지 ${entries.length}통의 편지를 썼어요',
            textAlign: TextAlign.center,
            style: bodyFont(fontSize: 12.5, color: AppColors.inkSoft),
          ),
          const SizedBox(height: 24),
          if (entries.isEmpty)
            _EmptyHistoryHint(accent: palette.accent, background: palette.background)
          else
            for (int i = 0; i < entries.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _HistoryLetterCard(
                  entry: entries[i],
                  accent: palette.accent,
                  background: palette.background,
                  floatSeed: 20 + i,
                ),
              ),
        ],
      ),
    );
  }
}

class _EmptyHistoryHint extends StatelessWidget {
  final Color accent;
  final Color background;
  const _EmptyHistoryHint({required this.accent, required this.background});

  @override
  Widget build(BuildContext context) {
    return GlassBlob(
      accent: accent,
      background: background,
      child: Column(
        children: [
          Text('🌿', style: const TextStyle(fontSize: 26)),
          const SizedBox(height: 10),
          Text(
            '언제든 짧게 한 통 적어보세요.\n답장은 내일 아침에 도착해요.',
            textAlign: TextAlign.center,
            style: bodyFont(fontSize: 12.5, color: AppColors.inkSoft, height: 1.6),
          ),
        ],
      ),
    );
  }
}

/// 편지 원문(짧게 접혀 있음)과 그에 대한 답장을 함께 보여주는 카드.
/// 목록 전체가 한 번에 펼쳐져 있으면 부담스러울 수 있어, 편지 원문은
/// 한 줄만 미리 보이고, 필요하면 펼쳐서 전체를 볼 수 있게 했습니다.
class _HistoryLetterCard extends StatefulWidget {
  final SpecialLetterEntry entry;
  final Color accent;
  final Color background;
  final int floatSeed;
  const _HistoryLetterCard({
    required this.entry,
    required this.accent,
    required this.background,
    required this.floatSeed,
  });

  @override
  State<_HistoryLetterCard> createState() => _HistoryLetterCardState();
}

class _HistoryLetterCardState extends State<_HistoryLetterCard> {
  bool _expanded = false;

  void _onExpandToggle() {
    final entry = widget.entry;
    if (entry.isReplyReady && !entry.replySeen) {
      SpecialLetterService.markReplySeen(entry.id);
    }
    setState(() => _expanded = !_expanded);
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final dateLabel = DateFormat('yyyy.MM.dd (E) HH:mm', 'ko_KR').format(entry.createdAt);
    return GlassBlob(
      accent: widget.accent,
      background: widget.background,
      floatSeed: widget.floatSeed,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit_note_rounded, size: 15, color: widget.accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  dateLabel,
                  style: pathLabelFont(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.inkSoft,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _onExpandToggle,
            child: Text(
              entry.letterText,
              maxLines: _expanded ? null : 2,
              overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
              style: bodyFont(fontSize: 13, color: AppColors.moon, height: 1.6),
            ),
          ),
          const SizedBox(height: 12),
          if (!entry.isReplyReady)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: AppColors.blobLavender.withValues(alpha: 0.5),
                border: Border.all(
                  color: AppColors.blobLavenderAccent.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  const Text('🌙', style: TextStyle(fontSize: 15)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '답장은 내일 아침에 도착해요',
                      style: bodyFont(fontSize: 12, color: AppColors.inkSoft),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white.withValues(alpha: 0.7),
                border: Border.all(color: widget.accent.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('💌', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 5),
                      Text(
                        '받은 답장',
                        style: pathLabelFont(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: widget.accent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    entry.replyText,
                    style: bodyFont(fontSize: 12.5, color: AppColors.moon, height: 1.6),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
