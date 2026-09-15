import '../../theme.dart' show AppColors;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/emotion_l10n.dart';
import '../l10n/gen/app_localizations.dart';
import '../l10n/weekly_observation_l10n.dart';
import '../providers/garden_provider.dart';
import '../services/emotion_insight_service.dart';

/// "이번 주 몽이의 관찰" - 감정 데이터 되돌려주기 2단계.
///
/// 최근 7일간의 [GardenProvider.diaryEntries]만으로 감정 비율, Top 감정,
/// 지난주 대비 변화, 한 줄 관찰 문구를 계산해서 보여준다. 서버/AI 없이
/// 전부 로컬 데이터 + 룰 기반 템플릿([EmotionInsightService])으로 동작한다.
///
/// 새 저장 로직은 "이번 주에 이미 자동으로 보여줬는지"를 기록하는 플래그
/// 하나뿐이며, 카드 자체는 [garden_growth_share_sheet.dart]와 동일한
/// RepaintBoundary + SharePlus 캡처 패턴으로 SNS 공유도 지원한다.
class WeeklyReportScreen extends StatefulWidget {
  const WeeklyReportScreen({super.key});

  @override
  State<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends State<WeeklyReportScreen> {
  final GlobalKey _cardKey = GlobalKey();
  bool _sharing = false;

  Future<void> _share(WeeklyEmotionReport report) async {
    if (_sharing) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _sharing = true);
    try {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final boundary =
          _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw StateError(l10n.shareCardNotFoundError);
      }
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw StateError(l10n.shareImageConvertError);
      }
      final bytes = byteData.buffer.asUint8List();

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              bytes,
              name: 'mongi_weekly_report.png',
              mimeType: 'image/png',
            ),
          ],
          text: l10n.weeklyReportShareText,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('weekly report share error: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.shareErrorSnackbar)));
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final garden = context.watch<GardenProvider>();
    final report = EmotionInsightService.buildWeeklyReport(
      diaryEntries: garden.diaryEntries,
    );

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF3E9), AppColors.bg0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, l10n),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  children: [
                    if (!report.hasEnoughData)
                      _buildNotEnoughDataCard(l10n)
                    else ...[
                      RepaintBoundary(
                        key: _cardKey,
                        child: _buildReportCard(report, l10n),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _sharing ? null : () => _share(report),
                          icon: _sharing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.ios_share, size: 18),
                          label: Text(
                            _sharing
                                ? l10n.gardenShareCardMakingButton
                                : l10n.weeklyReportShareButton,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE0A72E),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                    ],
                  ],
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
          Text(
            '📊 ${l10n.mindReportWeeklyTitle}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
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
          const Text('🌱', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(
            l10n.weeklyReportNotEnoughTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.weeklyReportNotEnoughBody,
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

  Widget _buildReportCard(WeeklyEmotionReport report, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE0A72E), Color(0xFFF5C244)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🐱', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l10n.mindReportWeeklyTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              Text(
                l10n.weeklyReportSessionsLabel(report.totalSessions),
                style: const TextStyle(color: Colors.white70, fontSize: 11.5),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildPositiveRatioBar(report, l10n),
          const SizedBox(height: 18),
          if (report.emotionCounts.isNotEmpty) ...[
            Text(
              l10n.weeklyReportEmotionsSectionTitle,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: report.emotionCounts.take(5).map((e) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    l10n.weeklyReportEmotionTag(
                      e.key.gardenIcon,
                      emotionLabel(l10n, e.key.type),
                      e.value,
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
          ],
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              weeklyObservationText(l10n, report.observationResult),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                height: 1.6,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPositiveRatioBar(
    WeeklyEmotionReport report,
    AppLocalizations l10n,
  ) {
    final positivePercent = (report.positiveRatio * 100).round();
    final negativePercent = 100 - positivePercent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.mindReportWeeklyPositiveLabel(positivePercent),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              l10n.weeklyReportNegativeLabel(negativePercent),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 10,
            child: Row(
              children: [
                Expanded(
                  flex: positivePercent.clamp(1, 100),
                  child: Container(color: Colors.white),
                ),
                Expanded(
                  flex: negativePercent.clamp(1, 100),
                  child: Container(color: Colors.black26),
                ),
              ],
            ),
          ),
        ),
        if (report.previousPositiveRatio != null) ...[
          const SizedBox(height: 6),
          Text(
            l10n.weeklyReportPreviousRatioLabel(
              (report.previousPositiveRatio! * 100).round(),
            ),
            style: const TextStyle(color: Colors.white70, fontSize: 10.5),
          ),
        ],
      ],
    );
  }
}
