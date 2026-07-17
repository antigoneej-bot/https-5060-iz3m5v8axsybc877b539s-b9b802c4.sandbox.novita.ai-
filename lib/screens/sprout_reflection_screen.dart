import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/shadow_cats_data.dart';
import '../models/buried_emotion_entry.dart';
import '../providers/buried_emotion_provider.dart';
import '../theme.dart';
import '../utils/cat_palette.dart';
import '../widgets/garden_path_card.dart';

/// 며칠 전 땅에 묻어둔 감정이 작은 새싹으로 다시 떠올랐을 때, 짧게
/// "그때 그 감정, 지금은 어때요?"를 되짚어볼 수 있는 화면.
///
/// 절대 "미해결 문제를 처리하라"는 압박으로 보이지 않도록, 재기록은 완전히
/// 선택 사항이며 건너뛰어도 새싹은 그저 조용히 사라질 뿐 아무 페널티가
/// 없습니다.
class SproutReflectionScreen extends StatefulWidget {
  final BuriedEmotionEntry entry;
  const SproutReflectionScreen({super.key, required this.entry});

  @override
  State<SproutReflectionScreen> createState() => _SproutReflectionScreenState();
}

class _SproutReflectionScreenState extends State<SproutReflectionScreen> {
  final _controller = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _saving) return;
    setState(() => _saving = true);
    await context.read<BuriedEmotionProvider>().saveReRecording(
      widget.entry.id,
      text,
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _skip() async {
    if (_saving) return;
    setState(() => _saving = true);
    await context.read<BuriedEmotionProvider>().skip(widget.entry.id);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cat = widget.entry.catId.isEmpty
        ? null
        : shadowCatById(widget.entry.catId);
    final accent = widget.entry.catId.isEmpty
        ? CatPalette.emptyDay
        : CatPalette.accentFor(widget.entry.catId);
    final background = widget.entry.catId.isEmpty
        ? CatPalette.emptyDay
        : CatPalette.backgroundFor(widget.entry.catId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 6),
        Center(
          child: Text(cat?.emoji ?? '🌱', style: const TextStyle(fontSize: 40)),
        ),
        const SizedBox(height: 16),
        Text(
          '그때 그 감정,\n지금은 어때요?',
          textAlign: TextAlign.center,
          style: titleFont(fontSize: 22, color: AppColors.ink, height: 1.4),
        ),
        const SizedBox(height: 10),
        Text(
          '며칠 전 잠시 땅에 묻어두었던 마음이에요.\n지금 다시 들여다봐도 되고, 그냥 흘려보내도 괜찮아요',
          textAlign: TextAlign.center,
          style: bodyFont(fontSize: 12, color: AppColors.inkSoft, height: 1.7),
        ),
        const SizedBox(height: 22),
        GlassBlob(
          accent: accent,
          background: background,
          floatSeed: widget.entry.id.hashCode,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '그때 남긴 마음',
                style: pathLabelFont(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.entry.letterSnippet.isEmpty
                    ? '(그날의 마음을 조용히 묻어두었어요)'
                    : widget.entry.letterSnippet,
                style: bodyFont(
                  fontSize: 12,
                  color: AppColors.inkSoft,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white.withValues(alpha: 0.75),
            border: Border.all(color: accent.withValues(alpha: 0.3)),
          ),
          child: TextField(
            controller: _controller,
            maxLines: 4,
            minLines: 3,
            style: bodyFont(fontSize: 13, color: AppColors.ink, height: 1.6),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.all(16),
              border: InputBorder.none,
              hintText: '지금 떠오르는 마음을 편하게 적어보세요 (선택)',
              hintStyle: bodyFont(fontSize: 12.5, color: AppColors.inkSoft),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _GhostButton(
                label: '조용히 흘려보내기',
                onTap: _saving ? null : _skip,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _FilledButton(
                label: '기록하기',
                accent: accent,
                onTap: _saving ? null : _save,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          '기록하지 않아도 이 새싹은 조용히 사라질 뿐, 아무 문제가 되지 않아요',
          textAlign: TextAlign.center,
          style: bodyFont(
            fontSize: 10.5,
            color: AppColors.inkSoft,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

class _GhostButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _GhostButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: Colors.white.withValues(alpha: 0.55),
            border: Border.all(color: AppColors.inkSoft.withValues(alpha: 0.3)),
          ),
          child: Text(
            label,
            style: pathLabelFont(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.inkSoft,
            ),
          ),
        ),
      ),
    );
  }
}

class _FilledButton extends StatelessWidget {
  final String label;
  final Color accent;
  final VoidCallback? onTap;
  const _FilledButton({
    required this.label,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: accent.withValues(alpha: 0.88),
          ),
          child: Text(
            label,
            style: pathLabelFont(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
