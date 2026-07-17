import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/shadow_cats_data.dart';
import '../data/alternative_emotion_mapping.dart';
import '../models/shadow_cat.dart';
import '../providers/app_state_provider.dart';
import '../services/storage_service.dart';
import '../services/subscription_service.dart';
import '../theme.dart';
import '../widgets/garden_path_card.dart';
import 'premium_screen.dart';

/// 42마리 무료 + 10마리 유료(Basic 구독) 그림자 감정 고양이 카드 그리드에서
/// 지금 내 기분과 닮은 고양이 한 마리를 골라 선택하는 화면.
/// 딱딱한 사각 카드 그리드 대신, 카드마다 조금씩 다른 유기적인 블롭
/// 모양과 파스텔 톤을 주어 정원의 화단처럼 느껴지도록 합니다.
///
/// 유료 캐릭터는 항상 그리드에 노출되지만(절대 완전히 숨기지 않음), 흐림+저채도의
/// '안개' 처리로 표시됩니다. 탭하면 곧바로 결제창으로 보내지 않고, 먼저 그
/// 캐릭터를 짧게 소개한 뒤 가장 가까운 무료 캐릭터를 대안으로 안내합니다.
class CatSelectionScreen extends StatefulWidget {
  const CatSelectionScreen({super.key});

  @override
  State<CatSelectionScreen> createState() => _CatSelectionScreenState();
}

class _CatSelectionScreenState extends State<CatSelectionScreen> {
  bool _showReassurance = false;
  bool _checkedReassurance = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _maybeShowReassurance(),
    );
  }

  Future<void> _maybeShowReassurance() async {
    final seen = await StorageService.hasSeenFreeTierReassurance();
    if (!mounted) return;
    if (!seen) {
      setState(() {
        _showReassurance = true;
        _checkedReassurance = true;
      });
      await StorageService.markFreeTierReassuranceSeen();
    } else {
      setState(() => _checkedReassurance = true);
    }
  }

  void _dismissReassurance() {
    setState(() => _showReassurance = false);
  }

  Future<void> _onTapPremiumCat(ShadowCat cat) async {
    await StorageService.recordPremiumCatAttempt(cat.id);
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PremiumCatIntroSheet(cat: cat),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allCats = shadowCats.where((c) => c.selectable).toList();
    final isPremiumUser = context.watch<AppStateProvider>().isPremiumUser;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '지금 내 기분과 가장 닮은\n고양이를 골라보세요',
          textAlign: TextAlign.center,
          style: titleFont(
            fontSize: 19,
            color: AppColors.titlePastelGreen,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${allCats.length}마리의 그림자 감정 고양이 카드 중\n마음에 닿는 카드를 골라보세요',
          textAlign: TextAlign.center,
          style: bodyFont(
            fontSize: 12.5,
            color: AppColors.inkSoft,
            height: 1.5,
          ),
        ),
        if (_checkedReassurance)
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            child: _showReassurance
                ? Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: _ReassuranceBanner(onDismiss: _dismissReassurance),
                  )
                : const SizedBox.shrink(),
          ),
        const SizedBox(height: 18),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: allCats.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.78,
          ),
          itemBuilder: (context, index) {
            final cat = allCats[index];
            final locked = cat.isPremium && !isPremiumUser;
            return _CatCard(
              cat: cat,
              seed: index,
              locked: locked,
              onTap: locked
                  ? () => _onTapPremiumCat(cat)
                  : () => context.read<AppStateProvider>().selectCat(cat),
            );
          },
        ),
      ],
    );
  }
}

/// 감정체크 화면 최초 진입 시 1회만 보여주는, 부담을 낮추는 안내 문구.
/// '유료 캐릭터를 못 봐서 아쉽다'는 느낌이 아니라, 지금 가진 것만으로도
/// 충분하다는 다정한 톤을 유지합니다.
class _ReassuranceBanner extends StatelessWidget {
  final VoidCallback onDismiss;
  const _ReassuranceBanner({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return GlassBlob(
      accent: AppColors.blobMintAccent,
      background: AppColors.blobMint,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Text('🌿', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '42가지 감정으로도 충분히 마음을 표현할 수 있어요',
              style: bodyFont(fontSize: 12, color: AppColors.ink, height: 1.4),
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: AppColors.inkSoft,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 유료 캐릭터를 탭했을 때 나타나는 바텀시트.
/// 1단계: 캐릭터 이름 + 짧은 설명 + 가장 가까운 무료 캐릭터 대안 안내
/// 2단계: "더 자세히 표현하고 싶다면?" + 구독 CTA + 동일한 크기의 "나중에" 버튼
/// (다크패턴 방지: CTA와 '나중에' 버튼은 항상 같은 크기/시각적 비중으로 노출)
class _PremiumCatIntroSheet extends StatelessWidget {
  final ShadowCat cat;
  const _PremiumCatIntroSheet({required this.cat});

  @override
  Widget build(BuildContext context) {
    final altIds = alternativeFreeCatIdsFor(cat.id);
    final altCats = <ShadowCat>[];
    for (final id in altIds) {
      for (final c in shadowCats) {
        if (c.id == id) {
          altCats.add(c);
          break;
        }
      }
    }

    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.bg0,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Opacity(
                    opacity: 0.85,
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                      child: Image.asset(
                        cat.imageAsset,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${cat.emoji} ${cat.nameKr}',
                        style: titleFont(fontSize: 17, color: AppColors.ink),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '정원 플러스 Basic 캐릭터',
                        style: bodyFont(
                          fontSize: 11,
                          color: AppColors.blobButterAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '${cat.keyword}과는 다른, 더 섬세한 감정이에요',
              style: bodyFont(
                fontSize: 13.5,
                color: AppColors.ink,
                height: 1.6,
              ),
            ),
            if (altCats.isNotEmpty) ...[
              const SizedBox(height: 14),
              GlassBlob(
                accent: AppColors.blobLavenderAccent,
                background: AppColors.blobLavender,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '지금은 ${altCats.map((c) => "${c.emoji} ${c.nameKr}").join(" 또는 ")}로도\n비슷한 마음을 표현해볼 수 있어요',
                        style: bodyFont(
                          fontSize: 12.5,
                          color: AppColors.ink,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.read<AppStateProvider>().selectCat(altCats.first);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ink,
                    side: BorderSide(
                      color: AppColors.blobLavenderAccent.withValues(
                        alpha: 0.4,
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: Text(
                    '${altCats.first.emoji} ${altCats.first.nameKr}로 기록하기',
                    style: bodyFont(fontSize: 13, color: AppColors.ink),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Text(
              '더 자세히 표현하고 싶다면?',
              textAlign: TextAlign.center,
              style: titleFont(fontSize: 15, color: AppColors.titlePastelGreen),
            ),
            const SizedBox(height: 12),
            // 다크패턴 방지: CTA와 '나중에' 버튼을 같은 높이/같은 시각적 비중으로 배치
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.inkSoft,
                        side: BorderSide(color: AppColors.line),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: Text(
                        '나중에',
                        style: bodyFont(fontSize: 14, color: AppColors.inkSoft),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PremiumScreen(),
                          ),
                        );
                        if (context.mounted) {
                          await context
                              .read<AppStateProvider>()
                              .refreshPremiumStatus();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: Text(
                        '자세히 보기',
                        style: serifFont(fontSize: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                SubscriptionService.displayPrice,
                style: bodyFont(fontSize: 11, color: AppColors.inkSoft),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CatCard extends StatefulWidget {
  final ShadowCat cat;
  final int seed;
  final bool locked;
  final VoidCallback onTap;
  const _CatCard({
    required this.cat,
    required this.seed,
    required this.onTap,
    this.locked = false,
  });

  @override
  State<_CatCard> createState() => _CatCardState();
}

class _CatCardState extends State<_CatCard>
    with SingleTickerProviderStateMixin {
  bool _hovering = false;
  late final AnimationController _floatController;

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
    // 카드마다 조금씩 다른 리듬으로 저절로 살짝 떠다니게 합니다(터치 기기에서도
    // 정원의 화단처럼 계속 살아있는 느낌을 주기 위함).
    final rng = Random(widget.seed * 41 + 9);
    _floatController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 3400 + rng.nextInt(2200)),
    )..repeat(reverse: true, min: rng.nextDouble() * 0.6, max: 1);
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  BorderRadius _blobRadius() {
    final rng = Random(widget.seed * 13 + 5);
    double r(double base) => base + rng.nextDouble() * 10;
    return BorderRadius.only(
      topLeft: Radius.circular(r(20)),
      topRight: Radius.circular(r(16)),
      bottomLeft: Radius.circular(r(16)),
      bottomRight: Radius.circular(r(24)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accents[widget.seed % _accents.length];
    final background = _backgrounds[widget.seed % _backgrounds.length];
    final radius = _blobRadius();
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _floatController,
          builder: (context, child) {
            final t = _floatController.value;
            final dy = sin(t * pi) * 2.6;
            final angle = sin(t * pi) * 0.018;
            return Transform.translate(
              offset: Offset(0, dy),
              child: Transform.rotate(angle: angle, child: child),
            );
          },
          child: AnimatedScale(
            scale: _hovering ? 1.05 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: radius,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    background.withValues(alpha: _hovering ? 0.9 : 0.72),
                    background.withValues(alpha: _hovering ? 0.6 : 0.42),
                  ],
                ),
                border: Border.all(
                  color: accent.withValues(alpha: _hovering ? 0.45 : 0.22),
                  width: 1.1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: _hovering ? 0.22 : 0.1),
                    blurRadius: _hovering ? 16 : 8,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          widget.locked
                              ? ColorFiltered(
                                  colorFilter: const ColorFilter.matrix([
                                    0.35, 0.35, 0.35, 0, 0, //
                                    0.35, 0.35, 0.35, 0, 0, //
                                    0.35, 0.35, 0.35, 0, 0, //
                                    0, 0, 0, 1, 0, //
                                  ]),
                                  child: ImageFiltered(
                                    imageFilter: ImageFilter.blur(
                                      sigmaX: 3.2,
                                      sigmaY: 3.2,
                                    ),
                                    child: Opacity(
                                      opacity: 0.55,
                                      child: Image.asset(
                                        widget.cat.imageAsset,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                      ),
                                    ),
                                  ),
                                )
                              : Image.asset(
                                  widget.cat.imageAsset,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                          if (widget.locked)
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.white.withValues(alpha: 0.05),
                                      Colors.white.withValues(alpha: 0.32),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          if (widget.locked)
                            Positioned(
                              bottom: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '✨',
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(widget.cat.emoji, style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(
                    widget.locked ? '？？？' : widget.cat.nameKr,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: pathLabelFont(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: widget.locked ? AppColors.inkSoft : AppColors.ink,
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
