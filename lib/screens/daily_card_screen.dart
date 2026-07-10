import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/daily_card_provider.dart';
import '../models/shadow_cat.dart';
import '../theme.dart';
import '../widgets/animated_cat_art.dart';
import '../widgets/garden_path_card.dart';

/// 데일리 내면소통 - 타로카드처럼 펼쳐진 카드 스프레드에서 한 장을 골라
/// 오늘의 내면 고양이와 위로/지침을 받는 화면
class DailyCardScreen extends StatefulWidget {
  const DailyCardScreen({super.key});

  @override
  State<DailyCardScreen> createState() => _DailyCardScreenState();
}

class _DailyCardScreenState extends State<DailyCardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<DailyCardProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DailyCardProvider>();

    if (provider.isLoading) {
      return Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.blobMintAccent),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '데일리 내면소통',
          textAlign: TextAlign.center,
          style: titleFont(fontSize: 24, color: AppColors.titlePastelGreen),
        ),
        const SizedBox(height: 6),
        Text(
          provider.stage == DailyCardStage.spread
              ? '마음 가는 카드 한 장을 골라보세요'
              : '오늘 당신에게 온 내면의 고양이예요',
          textAlign: TextAlign.center,
          style: bodyFont(fontSize: 12.5, color: AppColors.inkSoft),
        ),
        const SizedBox(height: 22),
        if (provider.stage == DailyCardStage.spread)
          _CardSpread(
            onPick: () => context.read<DailyCardProvider>().pickCard(),
          )
        else if (provider.drawnCard != null)
          _CardResult(cat: provider.drawnCard!),
      ],
    );
  }
}

class _CardSpread extends StatelessWidget {
  final VoidCallback onPick;
  const _CardSpread({required this.onPick});

  @override
  Widget build(BuildContext context) {
    const cardCount = 12;
    return SizedBox(
      height: 260,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final centerX = width / 2;
          return Stack(
            alignment: Alignment.bottomCenter,
            children: List.generate(cardCount, (i) {
              final t =
                  (i - (cardCount - 1) / 2) / (cardCount - 1); // -0.5 ~ 0.5
              final angle = t * 0.9; // 부채꼴 회전
              final dx = centerX + t * width * 0.85 - 34;
              final dy = 40 - (1 - (t.abs() * 2)) * 18; // 가운데가 살짝 위로
              return Positioned(
                left: dx,
                bottom: dy,
                child: Transform.rotate(
                  angle: angle,
                  alignment: Alignment.bottomCenter,
                  child: _SpreadCard(index: i, onTap: onPick),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

class _SpreadCard extends StatefulWidget {
  final int index;
  final VoidCallback onTap;
  const _SpreadCard({required this.index, required this.onTap});

  @override
  State<_SpreadCard> createState() => _SpreadCardState();
}

class _SpreadCardState extends State<_SpreadCard> {
  double _liftOffset = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() => _liftOffset = -18);
        Future.delayed(const Duration(milliseconds: 120), widget.onTap);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.translationValues(0, _liftOffset, 0),
        width: 68,
        height: 100,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.blobLavender.withValues(alpha: 0.95),
              AppColors.blobLavenderAccent.withValues(alpha: 0.55),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.blobLavenderAccent.withValues(alpha: 0.5),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.blobLavenderAccent.withValues(alpha: 0.18),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: const Text('🐈', style: TextStyle(fontSize: 22)),
      ),
    );
  }
}

class _CardResult extends StatefulWidget {
  final ShadowCat cat;
  const _CardResult({required this.cat});

  @override
  State<_CardResult> createState() => _CardResultState();
}

class _CardResultState extends State<_CardResult>
    with TickerProviderStateMixin {
  late final AnimationController _flipController;
  late final Animation<double> _flip;
  late final AnimationController _revealController;
  late final Animation<double> _scale;
  late final Animation<double> _glow;
  late final Animation<double> _catReveal;

  @override
  void initState() {
    super.initState();
    // 1단계: 카드가 뒤집히는 3D 회전 (0~600ms)
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _flip = CurvedAnimation(parent: _flipController, curve: Curves.easeOutBack);

    // 2단계: 뒤집힌 직후 살짝 확대되며 빛이 번지고, 고양이가 서서히 나타남 (450ms)
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.08,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.08,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 55,
      ),
    ]).animate(_revealController);
    // 빛 번짐: 0→1로 빠르게 커졌다가 다시 0으로 잦아드는 '한 번의 번짐' 곡선
    _glow = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 65,
      ),
    ]).animate(_revealController);
    _catReveal = CurvedAnimation(
      parent: _revealController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    );

    _flipController.forward().whenComplete(() {
      if (mounted) _revealController.forward();
    });
  }

  @override
  void dispose() {
    _flipController.dispose();
    _revealController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cat = widget.cat;
    return AnimatedBuilder(
      animation: Listenable.merge([_flip, _revealController]),
      builder: (context, child) {
        final angle = (1 - _flip.value) * pi / 2;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle),
          child: child,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: AnimatedBuilder(
              animation: _revealController,
              builder: (context, _) {
                return Transform.scale(
                  scale: _scale.value,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.blobPeach.withValues(alpha: 0.9),
                          AppColors.blobPeach.withValues(alpha: 0.55),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: AppColors.blobPeachAccent.withValues(alpha: 0.4),
                        width: 1.4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.blobPeachAccent.withValues(alpha: 0.12),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                        // 카드가 뒤집힌 직후 부드럽게 번지는 빛
                        BoxShadow(
                          color: AppColors.blobPeachAccent.withValues(
                            alpha: 0.4 * _glow.value,
                          ),
                          blurRadius: 30 * _glow.value + 4,
                          spreadRadius: 5 * _glow.value,
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // 빛 번짐 - 카드 중심에서 은은하게 퍼지는 방사형 글로우
                        Opacity(
                          opacity: _glow.value.clamp(0.0, 1.0),
                          child: Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  AppColors.blobPeach.withValues(alpha: 0.9),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                        // 고양이가 살짝 아래에서 위로, 투명→선명하게 나타남
                        Opacity(
                          opacity: _catReveal.value.clamp(0.0, 1.0),
                          child: Transform.translate(
                            offset: Offset(0, (1 - _catReveal.value) * 14),
                            child: AnimatedCatArt(
                              imageAsset: cat.imageAsset,
                              size: 180,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              '${cat.emoji} ${cat.nameKr}',
              style: titleFont(fontSize: 20, color: AppColors.ink),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              '#${cat.keyword}',
              style: bodyFont(fontSize: 12, color: AppColors.blobPeachAccent),
            ),
          ),
          const SizedBox(height: 18),
          _MessageCard(icon: '💌', title: '오늘의 위로', body: cat.comfortMessage),
          const SizedBox(height: 12),
          _MessageCard(icon: '🧭', title: '오늘의 지침', body: cat.guidance),
          const SizedBox(height: 16),
          Center(
            child: Text(
              '내일 다시 새로운 카드를 뽑을 수 있어요',
              style: bodyFont(fontSize: 11.5, color: AppColors.inkSoft),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final String icon;
  final String title;
  final String body;
  const _MessageCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final isFirst = icon == '💌';
    return GlassBlob(
      accent: isFirst ? AppColors.blobRoseAccent : AppColors.blobMintAccent,
      background: isFirst ? AppColors.blobRose : AppColors.blobMint,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                title,
                style: pathLabelFont(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: bodyFont(fontSize: 13, color: AppColors.moon, height: 1.5),
          ),
        ],
      ),
    );
  }
}
