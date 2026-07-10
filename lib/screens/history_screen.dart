import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../models/letter_entry.dart';
import '../data/shadow_cats_data.dart';
import '../theme.dart';
import '../widgets/lively_cat_image.dart';
import '../widgets/garden_path_card.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppStateProvider>();
    if (app.history.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            const Text('🌙', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 14),
            Text(
              '아직 기록된 편지가 없어요',
              style: bodyFont(fontSize: 13.5, color: AppColors.inkSoft),
            ),
            const SizedBox(height: 6),
            Text(
              '그림자 고양이를 만나 첫 편지를 써보세요',
              style: bodyFont(fontSize: 12.5, color: AppColors.inkSoft),
            ),
          ],
        ),
      );
    }
    return Column(
      children: app.history
          .asMap()
          .entries
          .map((e) => _HistoryItem(entry: e.value, seed: e.key))
          .toList(),
    );
  }
}

class _HistoryItem extends StatefulWidget {
  final LetterEntry entry;
  final int seed;
  const _HistoryItem({required this.entry, required this.seed});

  @override
  State<_HistoryItem> createState() => _HistoryItemState();
}

class _HistoryItemState extends State<_HistoryItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hoverController;
  bool _hovering = false;

  static const _accents = [
    AppColors.blobMintAccent,
    AppColors.blobPeachAccent,
    AppColors.blobLavenderAccent,
    AppColors.blobRoseAccent,
    AppColors.blobButterAccent,
    AppColors.blobPeriwinkleAccent,
  ];
  static const _backgrounds = [
    AppColors.blobMint,
    AppColors.blobPeach,
    AppColors.blobLavender,
    AppColors.blobRose,
    AppColors.blobButter,
    AppColors.blobPeriwinkle,
  ];

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  void _setHover(bool v) {
    if (_hovering == v) return;
    setState(() => _hovering = v);
    if (v) {
      _hoverController.forward();
    } else {
      _hoverController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final cat = shadowCatById(entry.catId);
    final dateStr = DateFormat(
      'yyyy.MM.dd (E) HH:mm',
      'ko_KR',
    ).format(entry.date);
    final accent = _accents[widget.seed % _accents.length];
    final background = _backgrounds[widget.seed % _backgrounds.length];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: MouseRegion(
        onEnter: (_) => _setHover(true),
        onExit: (_) => _setHover(false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => _showDetail(context, entry, cat.imageAsset, cat.nameKr),
          child: AnimatedScale(
            scale: _hovering ? 1.015 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: GlassBlob(
              accent: accent,
              background: background,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  LivelyCatImage(
                    imageAsset: cat.imageAsset,
                    width: 40,
                    height: 40,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateStr,
                          style: bodyFont(
                            fontSize: 11,
                            color: AppColors.inkSoft,
                          ),
                        ),
                        Text(
                          '${cat.emoji} ${cat.nameKr}',
                          style: pathLabelFont(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (entry.improved)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Icon(
                        Icons.trending_up_rounded,
                        color: accent,
                        size: 18,
                      ),
                    ),
                  Icon(
                    Icons.chevron_right,
                    color: accent.withValues(alpha: 0.6),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDetail(
    BuildContext context,
    LetterEntry entry,
    String imageAsset,
    String name,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.bg0.withValues(alpha: 0.98),
                AppColors.blobMint.withValues(alpha: 0.7),
              ],
            ),
            border: Border.all(
              color: AppColors.blobMintAccent.withValues(alpha: 0.25),
              width: 1.2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: titleFont(fontSize: 20, color: AppColors.ink),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: const Icon(
                      Icons.close,
                      color: AppColors.inkSoft,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('yyyy년 M월 d일 HH:mm', 'ko_KR').format(entry.date),
                style: bodyFont(fontSize: 11.5, color: AppColors.inkSoft),
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  imageAsset,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 14),
              if (entry.tempAfter != null)
                Text(
                  '마음 온도: 실천 전 ${entry.tempBefore.round()}° → 실천 후 ${entry.tempAfter!.round()}°',
                  style: bodyFont(
                    fontSize: 12.5,
                    color: AppColors.blobPeachAccent,
                  ),
                )
              else
                Text(
                  '마음 온도: ${entry.tempBefore.round()}°',
                  style: bodyFont(
                    fontSize: 12.5,
                    color: AppColors.blobPeachAccent,
                  ),
                ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  entry.letterText.isEmpty ? '(기록된 내용이 없어요)' : entry.letterText,
                  style: bodyFont(
                    fontSize: 13.5,
                    color: AppColors.moon,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    context.read<AppStateProvider>().deleteHistoryEntry(
                      entry.id,
                    );
                    Navigator.pop(ctx);
                  },
                  child: Text(
                    '삭제하기',
                    style: bodyFont(fontSize: 12.5, color: AppColors.rose),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
