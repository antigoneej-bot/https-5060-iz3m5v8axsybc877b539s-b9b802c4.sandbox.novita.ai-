import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../models/letter_entry.dart';
import '../data/shadow_cats_data.dart';
import '../data/cat_reply_data.dart';
import '../theme.dart';
import '../widgets/lively_cat_image.dart';
import '../widgets/garden_path_card.dart';
import '../widgets/feature_scaffold.dart';
import 'weekly_reflection_screen.dart';
import 'monthly_shadow_reflection_screen.dart';
import 'mind_temperature_history_screen.dart';

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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _ReflectionEntryRow(),
        const SizedBox(height: 20),
        ...app.history.asMap().entries.map(
          (e) => _HistoryItem(entry: e.value, seed: e.key),
        ),
      ],
    );
  }
}

/// 기록 탭 상단의 회고 진입점. 사용자가 직접 탭했을 때만 열리며, 어떤
/// 알림도 강제로 띄우지 않습니다.
class _ReflectionEntryRow extends StatelessWidget {
  const _ReflectionEntryRow();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GardenPathCard(
          emoji: '🌡️',
          title: '마음온도기록',
          subtitle: '그동안 기록했던 마음 온도를 주간/월간으로 살펴보세요',
          accent: AppColors.blobPeachAccent,
          background: AppColors.blobPeach,
          floatSeed: 40,
          onTap: () => pushFullScreen(
            context,
            '마음온도기록',
            const MindTemperatureHistoryScreen(),
          ),
        ),
        const SizedBox(height: 12),
        GardenPathCard(
          emoji: '🗓️',
          title: '이번 주 돌아보기',
          subtitle: '이번 주 함께한 고양이와 요일별 흐름을 살펴보세요',
          accent: AppColors.blobMintAccent,
          background: AppColors.blobMint,
          floatSeed: 41,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const WeeklyReflectionScreen()),
          ),
        ),
        const SizedBox(height: 12),
        GardenPathCard(
          emoji: '📖',
          title: '이번 달 돌아보기',
          subtitle: '한 달간의 감정 흐름을 문장으로 되짚어보세요',
          accent: AppColors.blobLavenderAccent,
          background: AppColors.blobLavender,
          floatSeed: 42,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const MonthlyShadowReflectionScreen(),
            ),
          ),
        ),
      ],
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
          onTap: () {
            if (entry.isReplyReady && !entry.replySeen) {
              context.read<AppStateProvider>().markReplySeen(entry.id);
            }
            _showDetail(context, entry, cat.imageAsset, cat.nameKr);
          },
          child: AnimatedScale(
            scale: _hovering ? 1.015 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: GlassBlob(
              accent: accent,
              background: background,
              floatSeed: widget.seed * 61 + 13,
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
                        Row(
                          children: [
                            Text(
                              '${cat.emoji} ${cat.nameKr}',
                              style: pathLabelFont(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                            if (entry.moodEmoji != null) ...[
                              const SizedBox(width: 6),
                              Text(
                                entry.moodEmoji!,
                                style: const TextStyle(fontSize: 15),
                              ),
                            ],
                            if (entry.isReplyReady && !entry.replySeen) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.blobRoseAccent.withValues(
                                    alpha: 0.85,
                                  ),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '💌 답장 도착',
                                  style: bodyFont(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (entry.meditationKey != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Icon(
                        Icons.self_improvement_rounded,
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
              Text(
                entry.meditationKey != null
                    ? '편지를 보내고 명상까지 실천해 마음 온도가 2도 올랐어요 🌱'
                    : '편지를 보내 마음 온도가 1도 올랐어요 🌱',
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
              const SizedBox(height: 14),
              _CatReplySection(entry: entry, catName: name),
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

/// 편지 상세 안, 그 고양이의 답장을 보여주는 섹션.
/// - 아직 다음날 아침이 되지 않았다면: "아직 도착 전" 안내만 조용히 표시
/// - 다음날 아침이 지났다면: 고양이의 답장 전문을 편지지 톤으로 보여줌
class _CatReplySection extends StatelessWidget {
  final LetterEntry entry;
  final String catName;
  const _CatReplySection({required this.entry, required this.catName});

  @override
  Widget build(BuildContext context) {
    if (!entry.isReplyReady) {
      final remaining = entry.replyAvailableAt.difference(DateTime.now());
      final hours = remaining.inHours.clamp(0, 999);
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.blobLavender.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.blobLavenderAccent.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            const Text('🌙', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hours > 0
                    ? '$catName의 답장은 내일 아침에 도착해요 (약 $hours시간 후)'
                    : '$catName의 답장은 내일 아침에 도착해요',
                style: bodyFont(fontSize: 12, color: AppColors.inkSoft),
              ),
            ),
          ],
        ),
      );
    }

    final cat = shadowCatById(entry.catId);
    final reply = generateCatReply(entry, cat);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.blobButter.withValues(alpha: 0.85),
            AppColors.blobButter.withValues(alpha: 0.55),
          ],
        ),
        border: Border.all(
          color: AppColors.blobButterAccent.withValues(alpha: 0.3),
          width: 1.1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('💌', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                '$catName의 답장',
                style: pathLabelFont(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            reply,
            style: bodyFont(fontSize: 13, color: AppColors.moon, height: 1.7),
          ),
        ],
      ),
    );
  }
}
