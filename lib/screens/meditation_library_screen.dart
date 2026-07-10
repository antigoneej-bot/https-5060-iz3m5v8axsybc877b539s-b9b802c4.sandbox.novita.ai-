import 'package:flutter/material.dart';
import '../theme.dart';
import '../data/solutions_data.dart';
import '../widgets/guide_steps.dart';

/// 명상 탭 - 카테고리별로 모든 명상/움직임 가이드를 자유롭게 둘러보는 화면
class MeditationLibraryScreen extends StatelessWidget {
  const MeditationLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '명상 · 움직임',
          textAlign: TextAlign.center,
          style: serifFont(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '마음이 편안해지는 방법들을 자유롭게 둘러보고 실천해보세요',
          textAlign: TextAlign.center,
          style: bodyFont(fontSize: 12.5, color: AppColors.inkSoft),
        ),
        const SizedBox(height: 20),
        ...solutionCategories.map(
          (cat) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _CategorySection(category: cat),
          ),
        ),
      ],
    );
  }
}

class _CategorySection extends StatelessWidget {
  final SolutionCategory category;
  const _CategorySection({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bg1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(category.icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                category.label,
                style: serifFont(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...category.guideKeys.map((key) => _GuideTile(guideKey: key)),
        ],
      ),
    );
  }
}

class _GuideTile extends StatefulWidget {
  final String guideKey;
  const _GuideTile({required this.guideKey});

  @override
  State<_GuideTile> createState() => _GuideTileState();
}

class _GuideTileState extends State<_GuideTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final guide = breathingGuide[widget.guideKey]!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          Material(
            color: AppColors.bg0,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => setState(() => _expanded = !_expanded),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.line),
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
                      color: AppColors.inkSoft,
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
