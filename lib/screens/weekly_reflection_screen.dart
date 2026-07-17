import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../data/shadow_cats_data.dart';
import '../services/analytics_service.dart';
import '../services/reflection_service.dart';
import '../theme.dart';
import '../utils/cat_palette.dart';
import '../widgets/garden_path_card.dart';
import '../widgets/lively_cat_image.dart';
import '../widgets/share_reflection_card.dart';
import '../widgets/stars_background.dart';

/// 주간 회고 — 화면1(가장 빈번한 고양이) + 화면2(요일별 흐름 바)를
/// 세로로 이어 보여주는 스크롤 화면.
///
/// 전체 원칙: 이 화면은 '관찰'의 언어만 씁니다. 감정에 옳고 그름을 매기지
/// 않고, 어떤 알림도 강제로 띄우지 않습니다(사용자가 직접 들어왔을 때만
/// 보임).
class WeeklyReflectionScreen extends StatefulWidget {
  const WeeklyReflectionScreen({super.key});

  @override
  State<WeeklyReflectionScreen> createState() => _WeeklyReflectionScreenState();
}

class _WeeklyReflectionScreenState extends State<WeeklyReflectionScreen> {
  @override
  void initState() {
    super.initState();
    // 사용자가 직접 들어와 확인했으므로, 자동 노출 배너가 이번 주 안에
    // 다시 뜨지 않도록 '봤음' 표시만 남깁니다(강제 알림과는 무관).
    ReflectionService.markWeeklySeen();
    AnalyticsService().logEvent(AnalyticsEvents.weeklyReflectionView);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppStateProvider>();
    final topCatId = app.mostFrequentCatIdThisWeek;
    final entryCount = app.weeklyEntryCount;
    final recordedDays = app.weeklyRecordedDayCount;
    final days = app.last7DaysCatIds();

    return Scaffold(
      body: GardenScaffoldBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: AppColors.ink,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '이번 주 돌아보기',
                          style: titleFont(
                            fontSize: 19,
                            color: AppColors.titlePastelGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(22, 12, 22, 40),
                      child: entryCount == 0
                          ? const _NoDataYet()
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _WeeklyTopCatCard(
                                  topCatId: topCatId,
                                  entryCount: entryCount,
                                  recordedDays: recordedDays,
                                ),
                                const SizedBox(height: 22),
                                _WeeklyFlowCard(days: days),
                                const SizedBox(height: 22),
                                _ShareWeeklyButton(
                                  topCatId: topCatId,
                                  recordedDays: recordedDays,
                                  days: days,
                                ),
                              ],
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

class _NoDataYet extends StatelessWidget {
  const _NoDataYet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          const Text('🌙', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 14),
          Text(
            '아직 이번 주 기록이 없어요',
            style: bodyFont(fontSize: 13.5, color: AppColors.inkSoft),
          ),
          const SizedBox(height: 6),
          Text(
            '그림자 고양이를 만나 편지를 쓰면\n이곳에서 이번 주를 돌아볼 수 있어요',
            textAlign: TextAlign.center,
            style: bodyFont(fontSize: 12.5, color: AppColors.inkSoft),
          ),
        ],
      ),
    );
  }
}

/// 이번 주 그림자 지도를 캡처 가능한 카드로 공유하는 버튼.
/// 별도 화면 진입 없이, 이미 화면에 있는 데이터를 그대로 카드에 옮겨
/// 보여줍니다(무료 기능이라 부담 없이 노출할 수 있음).
class _ShareWeeklyButton extends StatelessWidget {
  final String? topCatId;
  final int recordedDays;
  final List<MapEntry<DateTime, String?>> days;
  const _ShareWeeklyButton({
    required this.topCatId,
    required this.recordedDays,
    required this.days,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: OutlinedButton.icon(
        onPressed: () {
          final catName = topCatId != null
              ? ReflectionService.catNameFor(topCatId)
              : null;
          showShareReflectionCard(
            context,
            cardContent: ShareWeeklyCardContent(
              topCatId: topCatId,
              recordedDays: recordedDays,
              days: days,
            ),
            shareText: catName != null
                ? '이번 주 나의 그림자 고양이는 $catName였어요 🐾 #고양이그림자정원'
                : '이번 주 그림자 지도를 살펴보고 있어요 🐾 #고양이그림자정원',
          );
        },
        icon: Icon(
          Icons.ios_share_rounded,
          size: 16,
          color: AppColors.blobMintAccent,
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.blobMintAccent,
          side: BorderSide(
            color: AppColors.blobMintAccent.withValues(alpha: 0.5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        label: Text(
          '이번 주 지도 공유하기',
          style: pathLabelFont(fontSize: 13, color: AppColors.blobMintAccent),
        ),
      ),
    );
  }
}

/// 화면 1 — "이번 주, 당신은 '{가장 빈번한 고양이}'와 가장 자주 함께 있었어요."
class _WeeklyTopCatCard extends StatelessWidget {
  final String? topCatId;
  final int entryCount;
  final int recordedDays;
  const _WeeklyTopCatCard({
    required this.topCatId,
    required this.entryCount,
    required this.recordedDays,
  });

  @override
  Widget build(BuildContext context) {
    if (topCatId == null) {
      return const _NoDataYet();
    }
    final cat = shadowCatById(topCatId!);
    final accent = CatPalette.accentFor(topCatId!);
    final background = CatPalette.backgroundFor(topCatId!);
    return GlassBlob(
      accent: accent,
      background: background,
      floatSeed: 21,
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
      child: Column(
        children: [
          LivelyCatImage(
            imageAsset: cat.imageAsset,
            width: 84,
            height: 84,
            borderRadius: BorderRadius.circular(20),
          ),
          const SizedBox(height: 16),
          Text(
            "이번 주, 당신은\n'${cat.nameKr}'과\n가장 자주 함께 있었어요",
            textAlign: TextAlign.center,
            style: titleFont(fontSize: 19, color: AppColors.ink, height: 1.5),
          ),
          const SizedBox(height: 10),
          Text(
            '7일 중 $recordedDays일 · 관찰 결과입니다',
            textAlign: TextAlign.center,
            style: bodyFont(fontSize: 12, color: accent),
          ),
        ],
      ),
    );
  }
}

/// 화면 2 — 요일별(월~일) 7칸 흐름 바.
/// 감정에 좋다/나쁘다 색상 매핑을 하지 않고, 고양이별 고유 색만 사용합니다.
class _WeeklyFlowCard extends StatelessWidget {
  final List<MapEntry<DateTime, String?>> days;
  const _WeeklyFlowCard({required this.days});

  @override
  Widget build(BuildContext context) {
    final weekdayLabels = days
        .map((e) => DateFormat('E', 'ko_KR').format(e.key))
        .toList();
    return GlassBlob(
      accent: AppColors.blobMintAccent,
      background: AppColors.blobMint,
      floatSeed: 22,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '이번 주 흐름 보기',
            style: pathLabelFont(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: days
                .map(
                  (e) => Expanded(
                    child: _DayBar(date: e.key, catId: e.value),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 10),
          Text(
            '${weekdayLabels.join(' · ')} · 요일별 감정 색으로 표시',
            textAlign: TextAlign.center,
            style: bodyFont(fontSize: 11, color: AppColors.inkSoft),
          ),
        ],
      ),
    );
  }
}

class _DayBar extends StatelessWidget {
  final DateTime date;
  final String? catId;
  const _DayBar({required this.date, required this.catId});

  @override
  Widget build(BuildContext context) {
    final hasRecord = catId != null;
    final color = hasRecord
        ? CatPalette.accentFor(catId!)
        : CatPalette.emptyDay;
    final weekdayLabel = DateFormat('E', 'ko_KR').format(date);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: hasRecord ? () => _showDayLetter(context, date, catId!) : null,
        child: Column(
          children: [
            Container(
              height: 64,
              decoration: BoxDecoration(
                color: color.withValues(alpha: hasRecord ? 0.85 : 0.55),
                borderRadius: BorderRadius.circular(12),
                border: hasRecord
                    ? null
                    : Border.all(
                        color: AppColors.inkSoft.withValues(alpha: 0.15),
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              weekdayLabel,
              style: bodyFont(fontSize: 10.5, color: AppColors.inkSoft),
            ),
          ],
        ),
      ),
    );
  }

  void _showDayLetter(BuildContext context, DateTime day, String catId) {
    final app = context.read<AppStateProvider>();
    final entry = app.history.firstWhere(
      (e) =>
          e.date.year == day.year &&
          e.date.month == day.month &&
          e.date.day == day.day,
      orElse: () => app.history.first,
    );
    final cat = shadowCatById(entry.catId);
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
                CatPalette.backgroundFor(entry.catId).withValues(alpha: 0.7),
              ],
            ),
            border: Border.all(
              color: CatPalette.accentFor(entry.catId).withValues(alpha: 0.25),
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
                      cat.nameKr,
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
                DateFormat('yyyy년 M월 d일 (E)', 'ko_KR').format(entry.date),
                style: bodyFont(fontSize: 11.5, color: AppColors.inkSoft),
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  cat.imageAsset,
                  height: 130,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 14),
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
            ],
          ),
        ),
      ),
    );
  }
}
