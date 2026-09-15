import 'package:flutter/material.dart';
import '../theme.dart';
import '../data/solutions_data.dart';
import 'guide_steps.dart';
import 'garden_path_card.dart';

/// 명상 카테고리 하나(예: "우울할 때")를 GlassBlob 카드로 보여주는 공용 위젯.
/// [MeditationLibraryScreen](전체 목록)과 감정 추천 화면 양쪽에서 재사용합니다.
class SolutionCategorySection extends StatelessWidget {
  final SolutionCategory category;
  final Color accent;
  final Color background;
  final bool startExpanded;
  const SolutionCategorySection({
    super.key,
    required this.category,
    required this.accent,
    required this.background,
    this.startExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final visibleKeys = publishedGuides(category.guideKeys);
    if (visibleKeys.isEmpty) return const SizedBox.shrink();
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
          ...visibleKeys.map(
            (key) => _GuideTile(
              guideKey: key,
              accent: accent,
              startExpanded: startExpanded,
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideTile extends StatefulWidget {
  final String guideKey;
  final Color accent;
  final bool startExpanded;
  const _GuideTile({
    required this.guideKey,
    required this.accent,
    this.startExpanded = false,
  });

  @override
  State<_GuideTile> createState() => _GuideTileState();
}

class _GuideTileState extends State<_GuideTile> {
  late bool _expanded = widget.startExpanded;
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            guide.title,
                            style: bodyFont(
                              fontSize: 13.5,
                              color: AppColors.ink,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            meditationMedia[widget.guideKey]?.label ??
                                guide.subtitle,
                            style: bodyFont(
                              fontSize: 11.5,
                              color: AppColors.inkSoft,
                            ),
                          ),
                        ],
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
            GuideSteps(guide: guide, guideKey: widget.guideKey),
          ],
        ],
      ),
    );
  }
}
