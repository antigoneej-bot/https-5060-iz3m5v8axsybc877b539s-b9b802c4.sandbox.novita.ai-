import 'package:flutter/material.dart';
import '../theme.dart';
import '../data/solutions_data.dart';
import '../widgets/guide_steps.dart';
import '../widgets/garden_path_card.dart';

/// 명상 탭 - 카테고리별로 모든 명상/움직임 가이드를 자유롭게 둘러보는 화면
class MeditationLibraryScreen extends StatelessWidget {
  const MeditationLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const accents = [
      AppColors.blobLavenderAccent,
      AppColors.blobMintAccent,
      AppColors.blobPeachAccent,
      AppColors.blobButterAccent,
      AppColors.blobRoseAccent,
      AppColors.blobPeriwinkleAccent,
    ];
    const backgrounds = [
      AppColors.blobLavender,
      AppColors.blobMint,
      AppColors.blobPeach,
      AppColors.blobButter,
      AppColors.blobRose,
      AppColors.blobPeriwinkle,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '명상 · 움직임',
          textAlign: TextAlign.center,
          style: titleFont(fontSize: 24, color: AppColors.titlePastelGreen),
        ),
        const SizedBox(height: 6),
        Text(
          '마음이 편안해지는 방법들을 자유롭게 둘러보고 실천해보세요',
          textAlign: TextAlign.center,
          style: bodyFont(fontSize: 12.5, color: AppColors.inkSoft),
        ),
        const SizedBox(height: 20),
        ...solutionCategories.asMap().entries.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _CategorySection(
              category: e.value,
              accent: accents[e.key % accents.length],
              background: backgrounds[e.key % backgrounds.length],
            ),
          ),
        ),
      ],
    );
  }
}

class _CategorySection extends StatelessWidget {
  final SolutionCategory category;
  final Color accent;
  final Color background;
  const _CategorySection({
    required this.category,
    required this.accent,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return GlassBlob(
      accent: accent,
      background: background,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(category.icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                category.label,
                style: pathLabelFont(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...category.guideKeys.map(
            (key) => _GuideTile(guideKey: key, accent: accent),
          ),
        ],
      ),
    );
  }
}

class _GuideTile extends StatefulWidget {
  final String guideKey;
  final Color accent;
  const _GuideTile({required this.guideKey, required this.accent});

  @override
  State<_GuideTile> createState() => _GuideTileState();
}

class _GuideTileState extends State<_GuideTile> {
  bool _expanded = false;
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final guide = breathingGuide[widget.guideKey]!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          MouseRegion(
            onEnter: (_) => setState(() => _hovering = true),
            onExit: (_) => setState(() => _hovering = false),
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: Colors.white.withValues(alpha: _hovering ? 0.68 : 0.5),
                  border: Border.all(
                    color: widget.accent.withValues(
                      alpha: _hovering ? 0.4 : 0.2,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Text(guide.icon, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        guide.title,
                        style: bodyFont(
                          fontSize: 13.5,
                          color: AppColors.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: widget.accent,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: 8),
            GuideSteps(guide: guide),
          ],
        ],
      ),
    );
  }
}
