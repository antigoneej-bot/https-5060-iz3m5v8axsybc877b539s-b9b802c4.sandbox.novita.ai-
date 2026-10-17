import '../../theme.dart' show AppColors;
import '../../providers/app_state_provider.dart';
import '../../services/emotion_summary_service.dart';
import '../../services/unified_emotion_summary_service.dart';
import '../../screens/emotion_statistics_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/emotion_trigger_l10n.dart';
import '../l10n/gen/app_localizations.dart';
import '../l10n/mood_trend_l10n.dart';
import '../l10n/weekday_l10n.dart';
import '../l10n/mind_reflection_l10n.dart';
import '../models/emotion.dart';
import '../providers/garden_provider.dart';
import '../services/emotion_insight_service.dart';
import '../services/mind_reflection_service.dart';
import 'diary_screen.dart';
import 'emotion_calendar_screen.dart';
import 'emotion_collection_screen.dart';
import 'gratitude_log_screen.dart';
import 'mental_health_support_screen.dart';
import 'mood_trend_screen.dart';
import 'settings_screen.dart';

/// "마음 리포트" - 지금까지 흩어져 있던 감정 기록(주간 리포트, 감정 캘린더,
/// 감정 도감, 다이어리)을 한 화면에서 미리 볼 수 있는 통합 대시보드.
///
/// 각 기능을 새로 만드는 대신, 기존 화면들이 계산해둔 값([EmotionInsightService])을
/// 요약 카드로 재사용하고, 카드를 탭하면 각 화면(전체 뷰)으로 이동하는
/// "허브" 구조로 설계했다. 이렇게 하면:
/// 1) 유저가 여러 아이콘을 뒤지지 않고 한 곳에서 "내 마음이 요즘 어떤지"를
///    바로 확인할 수 있고,
/// 2) 기존 화면들의 상세 UI/공유 기능은 그대로 보존된다.
///
/// 정신건강 안내([MentalHealthSupportScreen])로 가는 입구도 이 화면에
/// 항상 노출한다 - 데이터 패턴상 마음이 많이 무거워 보일 때는 더 눈에 띄게,
/// 그렇지 않을 때도 조용히 항상 열려 있게.
class MindReportScreen extends StatefulWidget {
  const MindReportScreen({super.key});
  @override
  State<MindReportScreen> createState() => _MindReportScreenState();
}

class _MindReportScreenState extends State<MindReportScreen> {
  bool _gardenLoading = true;
  bool _gardenFailed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadGarden();
    });
  }

  Future<void> _loadGarden() async {
    setState(() {
      _gardenLoading = true;
      _gardenFailed = false;
    });
    try {
      final garden = context.read<GardenProvider>();
      if (!garden.isInitialized) await garden.ensureInitialized();
    } catch (_) {
      if (mounted) setState(() => _gardenFailed = true);
    } finally {
      if (mounted) setState(() => _gardenLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final garden = context.watch<GardenProvider>();
    final diaryEntries = garden.diaryEntries;
    final now = DateTime.now();
    final records = UnifiedEmotionSummaryService.read(
      letters: context.watch<AppStateProvider>().history,
      gardenDiary: diaryEntries,
    );
    final weekly = UnifiedEmotionSummaryService.period(
      records,
      EmotionSummaryService.weekStart(now),
      now,
    );
    final monthly = UnifiedEmotionSummaryService.period(
      records,
      DateTime(now.year, now.month),
      now,
    );
    final weekdayPattern = EmotionInsightService.buildWeekdayPattern(
      diaryEntries: diaryEntries,
    );
    final triggerInsight = EmotionInsightService.buildTriggerInsightKind(
      diaryEntries: diaryEntries,
    );
    final metCount = Emotion.all
        .where((e) => (garden.flowerCounts[e.type.name] ?? 0) > 0)
        .length;
    final suggestSupport = EmotionInsightService.shouldSuggestSupport(
      diaryEntries: diaryEntries,
    );

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFDF0F5), AppColors.bg0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, l10n),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (suggestSupport) ...[
                        _buildSupportAlertCard(context, l10n),
                        const SizedBox(height: 18),
                      ],
                      _buildIntroText(l10n),
                      const SizedBox(height: 18),
                      if (_gardenLoading) const LinearProgressIndicator(),
                      if (_gardenFailed)
                        TextButton.icon(
                          onPressed: _loadGarden,
                          icon: const Icon(Icons.refresh),
                          label: const Text('정원 일기를 불러오지 못했어요. 다시 시도'),
                        ),
                      _UnifiedPeriodCard(summary: weekly),
                      const SizedBox(height: 14),
                      _UnifiedPeriodCard(summary: monthly, monthly: true),
                      const SizedBox(height: 14),
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: const Text('정원 일기만 자세히 살펴보기'),
                        subtitle: const Text('아래 패턴은 정원 일기 기준이며 편지는 포함하지 않아요.'),
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: Text(
                              '마음 흐름은 선택한 감정과 강도로 계산한 참고값이에요. 직접 매긴 기분 점수나 심리 상태의 진단이 아니에요.',
                            ),
                          ),
                          const _MoodTrendSummaryCard(),
                          const SizedBox(height: 14),
                          _WeekdayPatternCard(pattern: weekdayPattern),
                          const SizedBox(height: 14),
                          _TriggerPatternCard(insight: triggerInsight),
                          const SizedBox(height: 14),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _CollectionSummaryCard(metCount: metCount),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(child: _DiarySummaryCard()),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const _GratitudeSummaryCard(),
                      const SizedBox(height: 14),
                      const _MindReflectionCard(),
                      const SizedBox(height: 20),
                      _buildSupportEntryCard(context, l10n),
                    ],
                  ),
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
          Expanded(
            child: Text(
              l10n.mindReportHeaderTitle,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroText(AppLocalizations l10n) {
    return Text(
      '편지와 정원 일기에 남긴 마음을 함께 돌아봐요. 기록 횟수는 마음이 좋아지거나 나빠진 정도를 뜻하지 않아요.',
      style: const TextStyle(
        fontSize: 12.5,
        color: AppColors.inkSoft,
        height: 1.5,
      ),
    );
  }

  /// 최근 2주 패턴상 무거운 마음이 반복됐을 때만 노출되는 강조 카드.
  /// 절대 "진단"하지 않고, 그저 도움받을 곳이 있다는 사실만 다정하게 알려준다.
  Widget _buildSupportAlertCard(BuildContext context, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7A6C8C), Color(0xFF5B9BD5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const MentalHealthSupportScreen(),
            ),
          );
        },
        child: Row(
          children: [
            const Text('🤍', style: TextStyle(fontSize: 30)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.mindReportSupportAlertTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.mindReportSupportAlertBody,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportEntryCard(BuildContext context, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF7A6C8C).withValues(alpha: 0.2),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const MentalHealthSupportScreen(),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text('🆘', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.mindReportSupportEntryLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    color: AppColors.ink,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.inkSoft,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Both entry points use exactly the same dated records as emotion statistics.
class _UnifiedPeriodCard extends StatelessWidget {
  final UnifiedEmotionPeriod summary;
  final bool monthly;
  const _UnifiedPeriodCard({required this.summary, this.monthly = false});

  @override
  Widget build(BuildContext context) {
    return _ReportCardShell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EmotionStatisticsScreen(initialMonthly: monthly),
        ),
      ),
      accentColor: const Color(0xFF5FB8AE),
      emoji: monthly ? '🗓️' : '📊',
      title: monthly ? '이번 달 함께 모은 마음' : '이번 주 함께 모은 마음',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${summary.recordedDays}일 · ${summary.records.length}개의 기록',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text('편지 ${summary.letterCount}개 · 정원 일기 ${summary.gardenCount}개'),
          const SizedBox(height: 6),
          Text(
            summary.records.isEmpty
                ? '감정 하나를 골라 남겨도 괜찮아요.'
                : '날짜를 눌러 당시의 글과 감정을 다시 볼 수 있어요.',
            style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft),
          ),
          if (monthly)
            const Text(
              '월간 상세 분석은 구독으로 이용해요.',
              style: TextStyle(fontSize: 12, color: AppColors.inkSoft),
            ),
        ],
      ),
    );
  }
}

/// "마음 흐름 그래프" 요약 카드 - Daylio/Bearable 벤치마킹(벤치마킹 #2).
/// [MoodTrendScreen]의 최근 14일 흐름 판단만 미리 보여주고, 탭하면 전체
/// 그래프(7/14/30일 토글)로 이동한다.
class _MoodTrendSummaryCard extends StatelessWidget {
  const _MoodTrendSummaryCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final garden = context.watch<GardenProvider>();
    final series = EmotionInsightService.buildMoodTrendSeries(
      diaryEntries: garden.diaryEntries,
    );
    return _ReportCardShell(
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const MoodTrendScreen()));
      },
      accentColor: const Color(0xFF5FB8AE),
      emoji: '📈',
      title: l10n.mindReportMoodTrendTitle,
      child: series.hasEnoughData
          ? Text(
              moodTrendDirectionText(l10n, series.direction),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.inkSoft,
                height: 1.4,
              ),
            )
          : Text(
              l10n.mindReportMoodTrendNotEnoughData,
              style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft),
            ),
    );
  }
}

/// 요일별 마음 패턴 요약 카드 - [EmotionCalendarScreen]의 "요일별 마음 흐름"
/// 섹션 미리보기. 탭하면 감정 캘린더로 이동해 전체 차트를 볼 수 있다.
class _WeekdayPatternCard extends StatelessWidget {
  final WeekdayEmotionPattern pattern;

  const _WeekdayPatternCard({required this.pattern});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _ReportCardShell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const EmotionCalendarScreen()),
        );
      },
      accentColor: const Color(0xFF8CA88C),
      emoji: '📅',
      title: l10n.mindReportWeekdayTitle,
      child: Text(
        weekdayObservationText(l10n, pattern.observationResult),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 12.5,
          color: AppColors.inkSoft,
          height: 1.4,
        ),
      ),
    );
  }
}

/// "마음의 원인" 요약 카드 - [EmotionInsightService.buildTriggerInsightKind]가
/// 계산한, 결과 화면에서 선택한 트리거 태그의 최근 패턴을 보여준다.
/// 아직 트리거 인사이트만을 위한 전용 화면은 없으므로, 탭하면 원본 태그가
/// 실제로 붙어있는 [DiaryScreen]으로 이동해 자세히 볼 수 있게 한다.
class _TriggerPatternCard extends StatelessWidget {
  final TriggerInsightResult? insight;

  const _TriggerPatternCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _ReportCardShell(
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const DiaryScreen()));
      },
      accentColor: const Color(0xFFC97B63),
      emoji: '🔍',
      title: l10n.mindReportTriggerTitle,
      child: insight != null
          ? Text(
              triggerInsightText(l10n, insight!),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.inkSoft,
                height: 1.4,
              ),
            )
          : Text(
              l10n.mindReportTriggerNotEnoughData,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft),
            ),
    );
  }
}

/// 감사 & 작은 성취 기록 요약 카드.
class _GratitudeSummaryCard extends StatelessWidget {
  const _GratitudeSummaryCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final garden = context.watch<GardenProvider>();
    final count = garden.gratitudeEntries.length;
    final doneToday = garden.isInitialized && garden.hasGratitudeEntryToday;
    return _ReportCardShell(
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const GratitudeLogScreen()));
      },
      accentColor: const Color(0xFFE0A31A),
      emoji: '🌻',
      title: l10n.mindReportGratitudeTitle,
      child: Row(
        children: [
          Text(
            count == 0
                ? l10n.mindReportGratitudeEmpty
                : l10n.mindReportGratitudeCount(count),
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.inkSoft,
              height: 1.4,
            ),
          ),
          const Spacer(),
          if (doneToday)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFE0A31A).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                l10n.mindReportGratitudeDoneToday,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFE0A31A),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// "몽이의 마음 성찰" 카드 - 옵트인 AI 리플렉션(벤치마킹 #6).
/// [MindReflectionService]가 감정×요일, 원인×부정감정, 감사×무드 등을
/// 교차 분석한 통찰을 보여준다. 서버/외부 AI 호출 없이 이 기기 데이터만으로
/// 계산되며, 설정에서 명시적으로 동의(opt-in)한 사용자에게만 노출된다.
class _MindReflectionCard extends StatelessWidget {
  const _MindReflectionCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final garden = context.watch<GardenProvider>();

    if (!garden.aiReflectionOptIn) {
      return _ReportCardShell(
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
        },
        accentColor: const Color(0xFF5FB8AE),
        emoji: '🌿',
        title: l10n.mindReportReflectionTitle,
        child: Row(
          children: [
            Expanded(
              child: Text(
                l10n.mindReportReflectionOptInPrompt,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.inkSoft,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final result = MindReflectionService.buildReflection(
      diaryEntries: garden.diaryEntries,
      gratitudeEntries: garden.gratitudeEntries,
      checkInStreak: garden.checkInStreak,
    );

    return _ReportCardShell(
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
      },
      accentColor: const Color(0xFF5FB8AE),
      emoji: '🌿',
      title: l10n.mindReportReflectionTitle,
      child: result.hasEnoughData
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final insight in result.insights)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '· ${mindReflectionInsightText(l10n, insight)}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.inkSoft,
                        height: 1.4,
                      ),
                    ),
                  ),
              ],
            )
          : Text(
              l10n.mindReportReflectionNotEnoughData,
              style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft),
            ),
    );
  }
}

/// 감정 도감 진행도 미니 카드.
class _CollectionSummaryCard extends StatelessWidget {
  final int metCount;

  const _CollectionSummaryCard({required this.metCount});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final total = Emotion.all.length;
    final ratio = total == 0 ? 0.0 : metCount / total;
    return _MiniCardShell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const EmotionCollectionScreen()),
        );
      },
      accentColor: const Color(0xFF8B6BB5),
      emoji: '📖',
      title: l10n.mindReportCollectionTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$metCount / $total',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: Color(0xFF8B6BB5),
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: const Color(0xFFF0EAE3),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF8B6BB5)),
            ),
          ),
        ],
      ),
    );
  }
}

/// 감정 다이어리 진입 미니 카드.
class _DiarySummaryCard extends StatelessWidget {
  const _DiarySummaryCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final garden = context.watch<GardenProvider>();
    final count = garden.diaryEntries.length;
    return _MiniCardShell(
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const DiaryScreen()));
      },
      accentColor: const Color(0xFFE38FB0),
      emoji: '📔',
      title: l10n.mindReportDiaryTitle,
      child: Text(
        l10n.mindReportDiaryCount(count),
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 16,
          color: Color(0xFFE38FB0),
        ),
      ),
    );
  }
}

/// 큰 요약 카드(주간/월간)의 공통 껍데기.
class _ReportCardShell extends StatelessWidget {
  final VoidCallback onTap;
  final Color accentColor;
  final String emoji;
  final String title;
  final Widget child;

  const _ReportCardShell({
    required this.onTap,
    required this.accentColor,
    required this.emoji,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          accentColor.withValues(alpha: .09),
          AppColors.bg1,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: accentColor.withValues(alpha: 0.6),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// 작은 요약 카드(도감/다이어리)의 공통 껍데기.
class _MiniCardShell extends StatelessWidget {
  final VoidCallback onTap;
  final Color accentColor;
  final String emoji;
  final String title;
  final Widget child;

  const _MiniCardShell({
    required this.onTap,
    required this.accentColor,
    required this.emoji,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          accentColor.withValues(alpha: .09),
          AppColors.bg1,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 11.5,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
