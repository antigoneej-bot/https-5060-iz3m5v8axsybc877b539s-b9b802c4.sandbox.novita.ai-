import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/stars_background.dart';
import '../widgets/garden_path_card.dart';
import '../services/subscription_service.dart';

/// '정원 플러스' 구독 안내 및 구매 화면 (페이월).
///
/// ⚠️ 실제 결제(Google Play 인앱결제)는 아직 연결되어 있지 않습니다.
/// [SubscriptionService.purchasePremium]의 주석을 참고해 개발자가 실제
/// 결제를 연동하면, 이 화면의 "구독 시작하기" 버튼이 바로 실결제로 이어집니다.
class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  final _sub = SubscriptionService();
  bool _isPremium = false;
  bool _loading = true;
  bool _purchasing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final premium = await _sub.isPremium();
    if (!mounted) return;
    setState(() {
      _isPremium = premium;
      _loading = false;
    });
  }

  Future<void> _purchase() async {
    setState(() => _purchasing = true);
    final ok = await _sub.purchasePremium();
    if (!mounted) return;
    setState(() {
      _purchasing = false;
      _isPremium = ok;
    });
    if (ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('정원 플러스 멤버십이 시작되었어요 🌷')));
    }
  }

  Future<void> _cancel() async {
    await _sub.cancelPremium();
    if (!mounted) return;
    setState(() => _isPremium = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('정원 플러스 멤버십이 해지되었어요')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GardenScaffoldBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
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
                          '정원 플러스',
                          style: titleFont(
                            fontSize: 20,
                            color: AppColors.titlePastelGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _HeroCard(isPremium: _isPremium),
                                const SizedBox(height: 20),
                                const _FeatureList(),
                                const SizedBox(height: 24),
                                if (_isPremium) ...[
                                  Center(
                                    child: Text(
                                      '이미 정원 플러스 멤버십을 이용 중이에요 🌿',
                                      textAlign: TextAlign.center,
                                      style: bodyFont(
                                        fontSize: 13,
                                        color: AppColors.inkSoft,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  _SecondaryButton(
                                    label: '멤버십 해지하기',
                                    onTap: _cancel,
                                  ),
                                ] else ...[
                                  _PrimaryPurchaseButton(
                                    loading: _purchasing,
                                    onTap: _purchase,
                                  ),
                                  const SizedBox(height: 10),
                                  Center(
                                    child: Text(
                                      '언제든 해지할 수 있어요 · 구독은 자동 갱신됩니다',
                                      style: bodyFont(
                                        fontSize: 11,
                                        color: AppColors.inkSoft,
                                      ),
                                    ),
                                  ),
                                ],
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

class _HeroCard extends StatelessWidget {
  final bool isPremium;
  const _HeroCard({required this.isPremium});

  @override
  Widget build(BuildContext context) {
    return GlassBlob(
      accent: AppColors.blobButterAccent,
      background: AppColors.blobButter,
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
      child: Column(
        children: [
          const Text('🌷', style: TextStyle(fontSize: 34)),
          const SizedBox(height: 14),
          Text(
            '정원을 더 깊이\n돌아볼 수 있어요',
            textAlign: TextAlign.center,
            style: titleFont(fontSize: 21, color: AppColors.ink, height: 1.4),
          ),
          const SizedBox(height: 10),
          Text(
            '마음 리포트의 상세 그래프와 분석을 잠금 해제하고,\n나의 감정 흐름을 더 자세히 들여다보세요',
            textAlign: TextAlign.center,
            style: bodyFont(
              fontSize: 12.5,
              color: AppColors.inkSoft,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: AppColors.blobButterAccent.withValues(alpha: 0.35),
              ),
            ),
            child: Text(
              isPremium ? '현재 이용 중 ✓' : SubscriptionService.displayPrice,
              style: numberFont(
                fontSize: 16,
                color: AppColors.blobButterAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureList extends StatelessWidget {
  const _FeatureList();

  static const _features = [
    ('📈', '마음 리포트 상세 그래프', '날짜별 감정 흐름, 감정 빈도, 긍정·부정 비교 그래프까지 모두 확인'),
    ('🐈', '정원 고양이의 속삭임 · 다정한 조언', '이 달의 분석과 조언을 전체 다 읽어보기'),
    ('🧘', '맞춤 명상 추천 상세 가이드', '리포트 기반 추천 명상의 전체 단계 가이드 열람'),
    ('🌙', '무제한 지난 달 리포트 보기', '몇 달 전 마음도 언제든 다시 꺼내볼 수 있어요'),
  ];

  @override
  Widget build(BuildContext context) {
    return GlassBlob(
      accent: AppColors.blobLavenderAccent,
      background: AppColors.blobLavender,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      child: Column(
        children: [
          for (final f in _features)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(f.$1, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          f.$2,
                          style: pathLabelFont(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          f.$3,
                          style: bodyFont(
                            fontSize: 11.5,
                            color: AppColors.inkSoft,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PrimaryPurchaseButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;
  const _PrimaryPurchaseButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: AppColors.gold.withValues(alpha: 0.35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
            : Text(
                '정원 플러스 시작하기',
                style: serifFont(fontSize: 15.5, color: Colors.white),
              ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SecondaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.inkSoft,
          side: BorderSide(color: AppColors.line),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        child: Text(
          label,
          style: bodyFont(fontSize: 13.5, color: AppColors.inkSoft),
        ),
      ),
    );
  }
}
