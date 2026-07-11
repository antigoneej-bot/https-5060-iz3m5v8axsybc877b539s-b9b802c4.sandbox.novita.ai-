import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../services/reflection_service.dart';
import '../services/subscription_service.dart';
import '../theme.dart';
import '../utils/cat_palette.dart';
import '../widgets/garden_path_card.dart';
import '../widgets/stars_background.dart';
import 'premium_screen.dart';
import 'reflection_letter_screen.dart';

/// 월간 회고 — 화면3(서술형 요약) + 화면4(리플렉션 레터 유도, 프리미엄
/// 전환점)를 세로로 이어 보여주는 스크롤 화면.
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
  bool _loadingPremium = true;
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    ReflectionService.markMonthlySeen();
    _loadPremium();
  }

  Future<void> _loadPremium() async {
    final premium = await SubscriptionService().isPremium();
    if (!mounted) return;
    setState(() {
      _isPremium = premium;
      _loadingPremium = false;
    });
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
                                const SizedBox(height: 22),
                                _ReflectionLetterInviteCard(
                                  isPremium: _isPremium,
                                  loading: _loadingPremium,
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

/// 화면 3 — 4주간 데이터를 문장으로 자동 생성한 서술형 요약.
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
            '4주간의 기록을 살펴본 관찰 결과입니다',
            textAlign: TextAlign.center,
            style: bodyFont(fontSize: 11.5, color: accent),
          ),
        ],
      ),
    );
  }
}

/// 화면 4 — 월간 리플렉션 레터 유도(프리미엄 전환점).
/// 무료 유저는 탭하면 프리미엄 안내로, 프리미엄 유저는 실제 답장 작성
/// 화면으로 이동합니다.
class _ReflectionLetterInviteCard extends StatelessWidget {
  final bool isPremium;
  final bool loading;
  const _ReflectionLetterInviteCard({
    required this.isPremium,
    required this.loading,
  });

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
            isPremium ? '리플렉션 레터 열기' : '프리미엄 · 리플렉션 레터 열기',
            textAlign: TextAlign.center,
            style: bodyFont(fontSize: 12, color: AppColors.blobLavenderAccent),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: loading
                  ? null
                  : () {
                      if (isPremium) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ReflectionLetterScreen(),
                          ),
                        );
                      } else {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PremiumScreen(),
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blobLavenderAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      isPremium ? '답장 쓰러 가기' : '프리미엄 알아보기',
                      style: serifFont(fontSize: 14.5, color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
