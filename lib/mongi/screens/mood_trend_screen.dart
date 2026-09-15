import '../../theme.dart' show AppColors;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/gen/app_localizations.dart';
import '../l10n/mood_trend_l10n.dart';
import '../providers/garden_provider.dart';
import '../services/emotion_insight_service.dart';
import '../widgets/mood_trend_chart.dart';

/// "마음 흐름 그래프" - Daylio/Bearable 벤치마킹(벤치마킹 제안 #2).
///
/// 이 앱은 매일 별도의 "오늘 기분 1~5점" 입력을 새로 요구하지 않는다 -
/// 대신 이미 쌓인 [GardenProvider.diaryEntries](감정 종류 + 선택적 강도)를
/// [EmotionInsightService.buildMoodTrendSeries]가 그대로 재활용해서 하루당
/// 무드 점수를 근사 계산한다. 새로운 입력 행동을 요구하지 않는다는 MVP
/// 원칙(마음 챌린지와 동일)을 그대로 따른다.
///
/// 7일/14일/30일 창을 토글할 수 있고, 그래프는 외부 패키지 없이
/// [MoodTrendChart](CustomPainter)로 가볍게 그린다.
class MoodTrendScreen extends StatefulWidget {
  const MoodTrendScreen({super.key});

  @override
  State<MoodTrendScreen> createState() => _MoodTrendScreenState();
}

class _MoodTrendScreenState extends State<MoodTrendScreen> {
  int _windowDays = 14;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final garden = context.watch<GardenProvider>();
    final series = EmotionInsightService.buildMoodTrendSeries(
      diaryEntries: garden.diaryEntries,
      days: _windowDays,
    );

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE8F5F0), AppColors.bg0],
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
                      _buildIntroText(l10n),
                      const SizedBox(height: 16),
                      _buildWindowToggle(l10n),
                      const SizedBox(height: 16),
                      if (!series.hasEnoughData)
                        _buildNotEnoughDataCard(l10n)
                      else
                        _buildChartCard(l10n, series),
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
              l10n.moodTrendHeaderTitle,
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
      l10n.moodTrendIntroText,
      style: const TextStyle(
        fontSize: 12.5,
        color: AppColors.inkSoft,
        height: 1.5,
      ),
    );
  }

  Widget _buildWindowToggle(AppLocalizations l10n) {
    final options = <int, String>{
      7: l10n.moodTrendWindow7Days,
      14: l10n.moodTrendWindow14Days,
      30: l10n.moodTrendWindow30Days,
    };
    return Row(
      children: options.entries.map((entry) {
        final selected = _windowDays == entry.key;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(entry.value),
            selected: selected,
            onSelected: (_) => setState(() => _windowDays = entry.key),
            selectedColor: const Color(0xFF5FB8AE).withValues(alpha: 0.22),
            labelStyle: TextStyle(
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              fontSize: 12.5,
              color: selected ? const Color(0xFF3D8E82) : AppColors.inkSoft,
            ),
            backgroundColor: Colors.white.withValues(alpha: 0.7),
            side: BorderSide(
              color: selected
                  ? const Color(0xFF5FB8AE)
                  : const Color(0xFFE3DCD3),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNotEnoughDataCard(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Text('📈', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(
            l10n.moodTrendNotEnoughTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.moodTrendNotEnoughBody,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.inkSoft,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(AppLocalizations l10n, MoodTrendSeries series) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📈', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l10n.moodTrendChartTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.ink,
                  ),
                ),
              ),
              Text(
                l10n.moodTrendSessionsLabel(series.totalSessions),
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.inkSoft,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          MoodTrendChart(series: series),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              _LegendDot(color: Color(0xFFF5C244), isPositive: true),
              SizedBox(width: 14),
              _LegendDot(color: Color(0xFF8C9CB4), isPositive: false),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF5FB8AE).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              moodTrendDirectionText(l10n, series.direction),
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF3D8E82),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final bool isPositive;

  const _LegendDot({required this.color, required this.isPositive});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = isPositive
        ? l10n.moodTrendLegendPositive
        : l10n.moodTrendLegendNegative;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(fontSize: 11, color: AppColors.inkSoft),
        ),
      ],
    );
  }
}
