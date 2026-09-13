import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../services/analytics_service.dart';
import '../services/daily_card_service.dart';
import '../services/reflection_service.dart';
import '../theme.dart';
import '../utils/cat_palette.dart';
import '../widgets/garden_path_card.dart';
import '../widgets/share_reflection_card.dart';
import '../widgets/stars_background.dart';
import 'reflection_letter_screen.dart';

/// 월간 회고 — 화면3(서술형 요약) + 화면4(리플렉션 레터 유도)를 세로로
/// 이어 보여주는 스크롤 화면.
///
/// ⚠️ MVP 정책(6개월 한정): 월간 회고는 전체 무료로 공개합니다. 반응이
/// 좋으면 이후 유료 요소를 다시 검토할 수 있습니다. 심층 분석형 유료
/// 기능은 주간 그림자 지도([WeeklyShadowMapScreen])에만 유지됩니다.
///
/// 화면3의 문장은 규칙 기반(빈도 계산 + 템플릿)으로 생성되며, "힘든
/// 달이었네요" 같은 위로·평가형 표현은 절대 쓰지 않습니다.
class MonthlyShadowReflectionScreen extends StatefulWidget {
  const MonthlyShadowReflectionScreen({super.key});

  @override
  State<MonthlyShadowReflectionScreen> createState() =>
      _MonthlyShadowReflectionScreenState();
}

class _MonthlyShadowReflectionScreenState
    extends State<MonthlyShadowReflectionScreen> {
  @override
  void initState() {
    super.initState();
    ReflectionService.markMonthlySeen();
    AnalyticsService().logEvent(AnalyticsEvents.monthlyReflectionView);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppStateProvider>();
    final hasData = app.hasAnyEntryThisMonth();
    final (firstHalf, secondHalf) = app.monthlyHalvesDominantCatIds();

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
                          '이번 달 돌아보기',
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
                      child: !hasData
                          ? const _NoMonthlyDataYet()
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _MonthlySummaryCard(
                                  firstHalfCatId: firstHalf,
                                  secondHalfCatId: secondHalf,
                                ),
                                const SizedBox(height: 16),
                                _ShareMonthlyButton(
                                  firstHalfCatId: firstHalf,
                                  secondHalfCatId: secondHalf,
                                ),
                                const SizedBox(height: 22),
                                const _UnconsciousPatternCard(),
                                const SizedBox(height: 22),
                                const _ReflectionLetterInviteCard(),
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

class _NoMonthlyDataYet extends StatelessWidget {
  const _NoMonthlyDataYet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          const Text('🌙', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 14),
          Text(
            '아직 이번 달 기록이 없어요',
            style: bodyFont(fontSize: 13.5, color: AppColors.inkSoft),
          ),
          const SizedBox(height: 6),
          Text(
            '그림자 고양이를 만나 편지를 쓰면\n이곳에서 이번 달을 돌아볼 수 있어요',
            textAlign: TextAlign.center,
            style: bodyFont(fontSize: 12.5, color: AppColors.inkSoft),
          ),
        ],
      ),
    );
  }
}

/// 화면 3 — 이번 달 데이터를 문장으로 자동 생성한 서술형 요약.
/// 그래프/차트 없이, 문장 하나로 이번 달의 흐름을 관찰합니다.
class _MonthlySummaryCard extends StatelessWidget {
  final String? firstHalfCatId;
  final String? secondHalfCatId;
  const _MonthlySummaryCard({
    required this.firstHalfCatId,
    required this.secondHalfCatId,
  });

  @override
  Widget build(BuildContext context) {
    final sentence = ReflectionService.buildMonthlySummarySentence(
      firstHalfCatId: firstHalfCatId,
      secondHalfCatId: secondHalfCatId,
    );
    final accent = secondHalfCatId != null
        ? CatPalette.accentFor(secondHalfCatId!)
        : (firstHalfCatId != null
              ? CatPalette.accentFor(firstHalfCatId!)
              : AppColors.blobButterAccent);
    final background = secondHalfCatId != null
        ? CatPalette.backgroundFor(secondHalfCatId!)
        : (firstHalfCatId != null
              ? CatPalette.backgroundFor(firstHalfCatId!)
              : AppColors.blobButter);
    return GlassBlob(
      accent: accent,
      background: background,
      floatSeed: 31,
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
      child: Column(
        children: [
          const Text('📖', style: TextStyle(fontSize: 30)),
          const SizedBox(height: 14),
          Text(
            sentence,
            textAlign: TextAlign.center,
            style: titleFont(fontSize: 18, color: AppColors.ink, height: 1.6),
          ),
          const SizedBox(height: 10),
          Text(
            '이번 달 1일부터 오늘까지 남긴 기록을 살펴봤어요',
            textAlign: TextAlign.center,
            style: bodyFont(fontSize: 11.5, color: accent),
          ),
        ],
      ),
    );
  }
}

/// 이번 달 돌아보기 문장을 캡처 가능한 카드로 공유하는 버튼.
class _ShareMonthlyButton extends StatelessWidget {
  final String? firstHalfCatId;
  final String? secondHalfCatId;
  const _ShareMonthlyButton({
    required this.firstHalfCatId,
    required this.secondHalfCatId,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: OutlinedButton.icon(
        onPressed: () {
          final sentence = ReflectionService.buildMonthlySummarySentence(
            firstHalfCatId: firstHalfCatId,
            secondHalfCatId: secondHalfCatId,
          );
          final accentCatId = secondHalfCatId ?? firstHalfCatId;
          showShareReflectionCard(
            context,
            cardContent: ShareMonthlyCardContent(
              sentence: sentence,
              accentCatId: accentCatId,
            ),
            shareText: '이번 달 나의 그림자 정원 이야기 🌙 #마음냥정원',
          );
        },
        icon: Icon(
          Icons.ios_share_rounded,
          size: 16,
          color: AppColors.blobLavenderAccent,
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.blobLavenderAccent,
          side: BorderSide(
            color: AppColors.blobLavenderAccent.withValues(alpha: 0.5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        label: Text(
          '이번 달 이야기 공유하기',
          style: pathLabelFont(
            fontSize: 13,
            color: AppColors.blobLavenderAccent,
          ),
        ),
      ),
    );
  }
}

/// "이번 달 무의식이 보여준 패턴" — 데일리 카드뽑기(완전 무작위) 히스토리를
/// 바탕으로 반복되는 그림자를 알려주는 섹션.
///
/// ⚠️ MVP 정책(6개월 한정): 월간 회고는 전체 무료로 공개합니다(심층 분석은
/// 주간 그림자 지도([WeeklyShadowMapScreen])에만 유료로 유지).
class _UnconsciousPatternCard extends StatelessWidget {
  const _UnconsciousPatternCard();

  @override
  Widget build(BuildContext context) {
    final draws = DailyCardService.getAllDraws();
    final sentence = ReflectionService.repeatedShadowSentence(draws);
    return GlassBlob(
      accent: AppColors.blobPeriwinkleAccent,
      background: AppColors.blobPeriwinkle,
      floatSeed: 33,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
      child: Column(
        children: [
          const Text('🌘', style: TextStyle(fontSize: 28)),
          const SizedBox(height: 12),
          Text(
            '이번 달, 우연히\n만난 고양이들',
            textAlign: TextAlign.center,
            style: titleFont(fontSize: 18, color: AppColors.ink, height: 1.5),
          ),
          const SizedBox(height: 10),
          Text(
            sentence ??
                '아직 데일리 카드뽑기 기록이 충분하지 않아요.\n무작위 카드 기록이에요. 실제 감정의 빈도를 뜻하지 않아요.',
            textAlign: TextAlign.center,
            style: bodyFont(fontSize: 13, color: AppColors.moon, height: 1.5),
          ),
        ],
      ),
    );
  }
}

/// 화면 4 — 월간 리플렉션 레터 유도. MVP 기간엔 전체 무료로 공개합니다.
class _ReflectionLetterInviteCard extends StatelessWidget {
  const _ReflectionLetterInviteCard();

  @override
  Widget build(BuildContext context) {
    return GlassBlob(
      accent: AppColors.blobLavenderAccent,
      background: AppColors.blobLavender,
      floatSeed: 32,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
      child: Column(
        children: [
          const Text('✉️', style: TextStyle(fontSize: 28)),
          const SizedBox(height: 12),
          Text(
            '한 달간의 그림자들에게,\n답장을 써볼까요?',
            textAlign: TextAlign.center,
            style: titleFont(fontSize: 18, color: AppColors.ink, height: 1.5),
          ),
          const SizedBox(height: 8),
          Text(
            '리플렉션 레터 열기',
            textAlign: TextAlign.center,
            style: bodyFont(fontSize: 12, color: AppColors.blobLavenderAccent),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ReflectionLetterScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blobLavenderAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text(
                '답장 쓰러 가기',
                style: serifFont(fontSize: 14.5, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
