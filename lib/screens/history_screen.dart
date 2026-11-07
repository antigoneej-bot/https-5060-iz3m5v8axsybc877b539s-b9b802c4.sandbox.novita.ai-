import '../l10n/app_language.dart';
import '../services/hive_encryption.dart';
import '../services/storage_service.dart';
import '../widgets/letter_care_closing_card.dart';
import '../services/reply_safety.dart';
import '../widgets/reply_support_actions.dart';
import 'emotion_statistics_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../models/letter_entry.dart';
import '../data/shadow_cats_data.dart';
import '../services/personal_reply_service.dart';
import '../theme.dart';
import '../widgets/lively_cat_image.dart';
import '../widgets/garden_path_card.dart';
import '../widgets/feature_scaffold.dart';
import '../widgets/mood_picker.dart';
import 'mind_temperature_history_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

/// 한 번에 펼쳐 보여줄 편지 카드 개수. 편지가 쌓일수록 목록이 한없이
/// 길어지던 문제를 개선하기 위해, 처음에는 최근 기록만 보여주고
/// "더보기"를 눌러야 그 이전 기록까지 펼쳐지도록 합니다.
const int _kInitialVisibleCount = 8;

class _HistoryScreenState extends State<HistoryScreen> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    final app = context.watch<AppStateProvider>();
    if (app.history.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Text('🌙', style: TextStyle(fontSize: 40)),
            SizedBox(height: 14),
            Text(
              tr('아직 기록된 편지가 없어요'),
              style: bodyFont(fontSize: 13.5, color: AppColors.inkSoft),
            ),
            SizedBox(height: 6),
            Text(
              tr('그림자 고양이를 만나 첫 편지를 써보세요'),
              style: bodyFont(fontSize: 12.5, color: AppColors.inkSoft),
            ),
          ],
        ),
      );
    }

    final history = app.history; // 이미 최신순으로 정렬되어 있음
    final visibleCount = _showAll
        ? history.length
        : (history.length < _kInitialVisibleCount
              ? history.length
              : _kInitialVisibleCount);
    final hiddenCount = history.length - visibleCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ReflectionEntryRow(),
        SizedBox(height: 20),
        _CatMeetingSummaryTable(history: history),
        SizedBox(height: 20),
        Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            tr("편지 기록 (총 {0}통)", [history.length]),
            style: pathLabelFont(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ),
        ...history
            .take(visibleCount)
            .toList()
            .asMap()
            .entries
            .map((e) => _HistoryItem(entry: e.value, seed: e.key)),
        if (hiddenCount > 0)
          Padding(
            padding: EdgeInsets.only(top: 4, bottom: 8),
            child: Center(
              child: TextButton(
                onPressed: () => setState(() => _showAll = true),
                child: Text(
                  tr("이전 기록 {0}통 더보기", [hiddenCount]),
                  style: bodyFont(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.blobLavenderAccent,
                  ),
                ),
              ),
            ),
          )
        else if (_showAll && history.length > _kInitialVisibleCount)
          Padding(
            padding: EdgeInsets.only(top: 4, bottom: 8),
            child: Center(
              child: TextButton(
                onPressed: () => setState(() => _showAll = false),
                child: Text(
                  tr('접기'),
                  style: bodyFont(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkSoft,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// 지금까지 만난 그림자 고양이별로 몇 번씩 편지를 썼는지 집계해 보여주는
/// 요약표. 편지 카드가 쌓일수록 "누구를 몇 번 만났는지"를 한눈에 보기
/// 어려워진다는 피드백을 반영해, 개별 카드 목록보다 먼저 이 표를
/// 보여줍니다. 만남 횟수가 많은 고양이부터 순서대로 정렬합니다.
class _CatMeetingSummaryTable extends StatelessWidget {
  final List<LetterEntry> history;
  const _CatMeetingSummaryTable({required this.history});

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    final counts = <String, int>{};
    for (final e in history) {
      counts[e.catId] = (counts[e.catId] ?? 0) + 1;
    }
    final rows = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return GlassBlob(
      accent: AppColors.blobLavenderAccent,
      background: AppColors.blobLavender,
      padding: EdgeInsets.all(18),
      floatSeed: 5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('🐾', style: TextStyle(fontSize: 18)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  tr('지금까지 만난 그림자 고양이'),
                  style: pathLabelFont(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
              Text(
                tr("총 {0}종 · {1}회", [rows.length, history.length]),
                style: bodyFont(fontSize: 11, color: AppColors.inkSoft),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            tr('편지 카드 대신, 어떤 고양이를 몇 번 만났는지 숫자로 정리했어요'),
            style: bodyFont(fontSize: 11, color: AppColors.inkSoft),
          ),
          SizedBox(height: 14),
          ...rows.map((e) {
            final cat = shadowCatById(e.key);
            final ratio = history.isEmpty ? 0.0 : e.value / history.length;
            return Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Text(cat.emoji, style: TextStyle(fontSize: 16)),
                  SizedBox(width: 8),
                  SizedBox(
                    width: 82,
                    child: Text(
                      cat.displayName,
                      style: bodyFont(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: SizedBox(
                        height: 10,
                        child: Stack(
                          children: [
                            Container(
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                            FractionallySizedBox(
                              widthFactor: ratio.clamp(0.03, 1.0),
                              child: Container(
                                color: AppColors.blobLavenderAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  SizedBox(
                    width: 42,
                    child: Text(
                      tr("{0}회", [e.value]),
                      textAlign: TextAlign.right,
                      style: numberFont(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.blobLavenderAccent,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// 기록 탭 상단의 회고 진입점. 사용자가 직접 탭했을 때만 열리며, 어떤
/// 알림도 강제로 띄우지 않습니다.
class _ReflectionEntryRow extends StatelessWidget {
  const _ReflectionEntryRow();

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    return Column(
      children: [
        GardenPathCard(
          emoji: '🌡️',
          title: tr('돌봄 온기 기록'),
          subtitle: tr('활동으로 모은 온기를 살펴보세요 · 심리 점수가 아니에요'),
          accent: AppColors.blobPeachAccent,
          background: AppColors.blobPeach,
          floatSeed: 40,
          onTap: () => pushFullScreen(
            context,
            tr('돌봄 온기 기록'),
            MindTemperatureHistoryScreen(),
          ),
        ),
        SizedBox(height: 12),
        GardenPathCard(
          emoji: '🗓️',
          title: tr("감정 통계"),
          subtitle: tr('주간·월간 기록과 회고를 한곳에서 살펴보세요'),
          accent: AppColors.blobMintAccent,
          background: AppColors.blobMint,
          floatSeed: 41,
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => EmotionStatisticsScreen())),
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
      duration: Duration(milliseconds: 220),
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
    Localizations.localeOf(context);
    final entry = widget.entry;
    final cat = shadowCatById(entry.catId);
    final dateStr = DateFormat(
      'yyyy.MM.dd (E) HH:mm',
      AppLanguage.instance.isEnglish ? 'en_US' : 'ko_KR',
    ).format(entry.date);
    final accent = _accents[widget.seed % _accents.length];
    final background = _backgrounds[widget.seed % _backgrounds.length];
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: MouseRegion(
        onEnter: (_) => _setHover(true),
        onExit: (_) => _setHover(false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            _showDetail(context, entry, cat.imageAsset, cat.displayName);
          },
          child: AnimatedScale(
            scale: _hovering ? 1.015 : 1.0,
            duration: Duration(milliseconds: 200),
            child: GlassBlob(
              accent: accent,
              background: background,
              floatSeed: widget.seed * 61 + 13,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  LivelyCatImage(
                    imageAsset: cat.imageAsset,
                    width: 40,
                    height: 40,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  SizedBox(width: 12),
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
                              '${cat.emoji} ${cat.displayName}',
                              style: pathLabelFont(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                            if (entry.moodEmoji != null) ...[
                              SizedBox(width: 6),
                              Text(
                                entry.moodEmoji!,
                                style: TextStyle(fontSize: 15),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (entry.meditationKey != null)
                    Padding(
                      padding: EdgeInsets.only(right: 6),
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
        // 편지 내용 + 답장 전문까지 모두 들어가면 다이얼로그 높이가 화면을
        // 넘어설 수 있으므로, 화면 높이의 85%로 제한하고 그 안에서는
        // 스크롤로 끝까지 읽을 수 있게 합니다(답장 글이 화면 밖으로
        // 밀려 안 보이던 문제 수정).
        insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.85,
          ),
          child: Container(
            padding: EdgeInsets.all(22),
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
            child: SingleChildScrollView(
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
                        child: Icon(
                          Icons.close,
                          color: AppColors.inkSoft,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    DateFormat(
                      tr('yyyy년 M월 d일 HH:mm'),
                      AppLanguage.instance.isEnglish ? 'en_US' : 'ko_KR',
                    ).format(entry.date),
                    style: bodyFont(fontSize: 11.5, color: AppColors.inkSoft),
                  ),
                  SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      imageAsset,
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(height: 14),
                  Text(
                    entry.meditationKey != null
                        ? tr('편지를 보내고 명상까지 실천해 마음 온도가 2도 올랐어요 🌱')
                        : tr('편지를 보내 마음 온도가 1도 올랐어요 🌱'),
                    style: bodyFont(
                      fontSize: 12.5,
                      color: AppColors.blobPeachAccent,
                    ),
                  ),
                  if (entry.moodEmoji != null) ...[
                    SizedBox(height: 10),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.blobButter.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AppColors.blobButterAccent.withValues(
                            alpha: 0.35,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            entry.moodEmoji!,
                            style: TextStyle(fontSize: 18),
                          ),
                          SizedBox(width: 8),
                          Text(
                            tr("오늘 기분: {0}", [moodLabelFor(entry.moodEmoji!)]),
                            style: bodyFont(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      entry.letterText.isEmpty
                          ? (entry.moodEmoji != null
                                ? tr('(오늘은 이모티콘으로만 마음을 남겼어요)')
                                : tr('(기록된 내용이 없어요)'))
                          : entry.letterText,
                      style: bodyFont(
                        fontSize: 13.5,
                        color: AppColors.moon,
                        height: 1.6,
                      ),
                    ),
                  ),
                  SizedBox(height: 14),
                  LetterCareClosingCard(letter: entry),
                  SizedBox(height: 12),
                  _CatReplySection(entry: entry, catName: name),
                  SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () async {
                        try {
                          await context
                              .read<AppStateProvider>()
                              .deleteHistoryEntry(entry.id);
                          if (ctx.mounted) Navigator.pop(ctx);
                        } catch (_) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text(tr('삭제를 완료하지 못했어요. 다시 시도해 주세요.')),
                              ),
                            );
                          }
                        }
                      },
                      child: Text(
                        tr('편지 삭제 · 나무 성장은 유지'),
                        style: bodyFont(fontSize: 12.5, color: AppColors.rose),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Existing answers are an optional archive, never newly generated on open.
class _CatReplySection extends StatefulWidget {
  final LetterEntry entry;
  final String catName;
  const _CatReplySection({required this.entry, required this.catName});
  @override
  State<_CatReplySection> createState() => _CatReplySectionState();
}

class _CatReplySectionState extends State<_CatReplySection> {
  late Future<String?> _archive;
  @override
  void initState() {
    super.initState();
    _archive = _read();
  }

  @override
  void didUpdateWidget(covariant _CatReplySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry.id != widget.entry.id ||
        oldWidget.entry.letterText != widget.entry.letterText) {
      _archive = _read();
    }
  }

  Future<String?> _read() async {
    if (ReplySafety.assess(widget.entry.letterText) != ReplySupportNeed.none) {
      return null;
    }
    final source = StorageService.letterBox;
    final entry = widget.entry;
    final cache = await HiveEncryption.openBox('reply_cache_local_user');
    return PersonalReplyService.savedReply(
      'letter:${entry.id}',
      legacyReplyReader: () =>
          cache.get(entry.id) is String ? cache.get(entry.id) as String : null,
      sourceIsCurrent: () =>
          source.isOpen &&
          identical(source, StorageService.letterBox) &&
          source.containsKey(entry.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    if (ReplySafety.assess(widget.entry.letterText) != ReplySupportNeed.none) {
      return ReplySupportActions(letterText: widget.entry.letterText);
    }
    return FutureBuilder<String?>(
      future: _archive,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return TextButton(
            onPressed: () => setState(() => _archive = _read()),
            child: Text(tr('이전에 받은 답장 다시 읽기')),
          );
        }
        final text = snapshot.data;
        if (text == null) return SizedBox.shrink();
        return ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: Text(tr('이전에 받은 답장')),
          subtitle: Text(tr('과거에 저장된 내용이에요')),
          childrenPadding: EdgeInsets.only(bottom: 12),
          children: [
            SelectableText(
              text,
              style: bodyFont(fontSize: 13, color: AppColors.moon, height: 1.7),
            ),
          ],
        );
      },
    );
  }
}
