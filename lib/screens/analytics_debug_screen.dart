import 'package:flutter/material.dart';
import '../services/analytics_service.dart';
import '../services/storage_service.dart';
import '../theme.dart';
import '../widgets/garden_path_card.dart';

/// 개발자/운영자용 로컬 지표 확인 화면.
///
/// ⚠️ 이 화면은 "이 기기 하나"의 누적 이벤트 횟수와 리텐션 마일스톤
/// 도달 여부만 보여줍니다. 실제 시장에서 여러 사용자에 걸친 리텐션
/// 비율(D1/D7/D30 %)을 보려면 Firebase Analytics 콘솔 연결이 필요합니다
/// (analytics_service.dart 상단 주석 참고).
class AnalyticsDebugScreen extends StatefulWidget {
  const AnalyticsDebugScreen({super.key});

  @override
  State<AnalyticsDebugScreen> createState() => _AnalyticsDebugScreenState();
}

class _AnalyticsDebugScreenState extends State<AnalyticsDebugScreen> {
  bool _loading = true;
  Map<String, int> _counts = {};
  List<int> _reachedMilestones = [];
  int _daysSinceInstall = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final counts = await AnalyticsService().getAllKnownEventCounts();
    final milestones = await AnalyticsService().getReachedRetentionMilestones();
    final days = await StorageService.daysSinceInstall();
    if (!mounted) return;
    setState(() {
      _counts = counts;
      _reachedMilestones = milestones;
      _daysSinceInstall = days;
      _loading = false;
    });
  }

  static const Map<String, String> _labels = {
    AnalyticsEvents.letterSent: '편지 전송',
    AnalyticsEvents.meditationCompleted: '명상 완료',
    AnalyticsEvents.shareCard: '카드 공유',
    AnalyticsEvents.saveCardToGallery: '카드 갤러리 저장',
    AnalyticsEvents.premiumScreenView: '구독 화면 조회',
    AnalyticsEvents.premiumPurchase: '구독 결제(로컬 스텁)',
    AnalyticsEvents.bondCodeGenerated: '묘연 코드 생성/공유',
    AnalyticsEvents.bondCodeRedeemed: '묘연 코드 입력 성공',
    AnalyticsEvents.weeklyReflectionView: '주간 회고 조회',
    AnalyticsEvents.monthlyReflectionView: '월간 회고 조회',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '이 기기에서 지금까지 발생한 이벤트 횟수와, 설치 후 며칠째\n다시 앱을 열었는지(리텐션 마일스톤)를 보여줍니다.',
          style: bodyFont(fontSize: 12.5, color: AppColors.inkSoft, height: 1.6),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 16, color: AppColors.gold),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '이 기기 1대만의 데이터입니다. 실제 시장 리텐션(%)을 보려면\nFirebase Analytics 연결이 필요합니다.',
                  style: bodyFont(fontSize: 11, color: AppColors.inkSoft, height: 1.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (_loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
          )
        else ...[
          GlassBlob(
            accent: AppColors.blobRoseAccent,
            background: AppColors.blobRose,
            floatSeed: 41,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '설치 후 경과일: $_daysSinceInstall일째',
                  style: pathLabelFont(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '도달한 리텐션 마일스톤',
                  style: bodyFont(fontSize: 12, color: AppColors.inkSoft),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [1, 3, 7, 14, 30].map((d) {
                    final reached = _reachedMilestones.contains(d);
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: reached
                            ? AppColors.blobRoseAccent.withValues(alpha: 0.9)
                            : Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'D$d',
                        style: bodyFont(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: reached ? Colors.white : AppColors.inkSoft,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassBlob(
            accent: AppColors.blobButterAccent,
            background: AppColors.blobButter,
            floatSeed: 42,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '누적 이벤트 횟수',
                  style: pathLabelFont(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 12),
                ..._labels.entries.map((entry) {
                  final count = _counts[entry.key] ?? 0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.value,
                            style: bodyFont(
                              fontSize: 12.5,
                              color: AppColors.inkSoft,
                            ),
                          ),
                        ),
                        Text(
                          '$count',
                          style: numberFont(
                            fontSize: 14,
                            color: AppColors.blobButterAccent,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              onPressed: () {
                setState(() => _loading = true);
                _load();
              },
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('새로고침'),
            ),
          ),
        ],
      ],
    );
  }
}
