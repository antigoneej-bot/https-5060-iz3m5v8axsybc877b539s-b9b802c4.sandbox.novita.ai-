import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/daily_card_provider.dart';
import '../providers/app_state_provider.dart';
import '../models/shadow_cat.dart';
import '../services/reflection_service.dart';
import '../services/subscription_service.dart';
import '../services/consciousness_insight_service.dart';
import '../theme.dart';
import '../widgets/animated_cat_art.dart';
import '../widgets/garden_path_card.dart';
import 'premium_screen.dart';

/// 오늘의 고양이 카드 - 타로카드처럼 펼쳐진 카드 스프레드에서 한 장을 골라
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
          '오늘의 고양이 카드',
          textAlign: TextAlign.center,
          style: titleFont(fontSize: 24, color: AppColors.titlePastelGreen),
        ),
        const SizedBox(height: 6),
        Text(
          switch (provider.stage) {
            DailyCardStage.shuffling => '카드를 섞고 있어요...',
            DailyCardStage.spread => '마음 가는 카드 한 장을 골라보세요',
            DailyCardStage.revealed => '오늘 우연히 만난 고양이예요',
          },
          textAlign: TextAlign.center,
          style: bodyFont(fontSize: 12.5, color: AppColors.inkSoft),
        ),
        const SizedBox(height: 8),
        Text(
          '무작위로 뽑는 재미용 카드예요. 심리 검사나 미래 예측이 아니에요.\n마음에 와닿는 부분만 보고, 맞지 않으면 넘겨도 좋아요.',
          textAlign: TextAlign.center,
          style: bodyFont(fontSize: 11.5, color: AppColors.inkSoft),
        ),
        if (provider.stage == DailyCardStage.spread) ...[
          const SizedBox(height: 6),
          Text(
            '🌬️ 눈을 감고 호흡을 깊게 들이마시고 내쉬기를 3번 한 뒤,\n마음이 가는 카드를 골라주세요',
            textAlign: TextAlign.center,
            style: bodyFont(
              fontSize: 11.5,
              color: AppColors.blobLavenderAccent,
              height: 1.5,
            ),
          ),
        ],
        const SizedBox(height: 22),
        if (provider.stage == DailyCardStage.shuffling)
          _ShuffleAnimation(
            onFinished: () => context.read<DailyCardProvider>().finishShuffle(),
          )
        else if (provider.stage == DailyCardStage.spread)
          _CardSpread(
            onPick: () => context.read<DailyCardProvider>().pickCard(),
          )
        else if (provider.drawnCard != null)
          _CardResult(cat: provider.drawnCard!),
      ],
    );
  }
}

/// 카드를 섞는 3초 연출. 여러 장의 카드가 서로 자리를 바꾸며 뒤섞이는
/// 모습을 보여주고(사운드는 Provider.load()에서 이미 재생 시작됨), 3초가
/// 지나면 onFinished를 호출해 스프레드(고르기) 단계로 넘어갑니다.
class _ShuffleAnimation extends StatefulWidget {
  final VoidCallback onFinished;
  const _ShuffleAnimation({required this.onFinished});

  @override
  State<_ShuffleAnimation> createState() => _ShuffleAnimationState();
}

class _ShuffleAnimationState extends State<_ShuffleAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  static const _cardCount = 7;
  late final List<_ShuffleMove> _moves;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    // 각 카드마다 3초 동안 여러 번 자리를 바꾸는 랜덤한 경로를 미리 생성합니다.
    _moves = List.generate(_cardCount, (i) {
      final waypoints = List.generate(4, (_) {
        return Offset(
          (rng.nextDouble() - 0.5) * 90,
          (rng.nextDouble() - 0.5) * 40,
        );
      });
      final rotations = List.generate(4, (_) => (rng.nextDouble() - 0.5) * 0.7);
      return _ShuffleMove(waypoints: waypoints, rotations: rotations);
    });

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onFinished();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Offset _offsetAt(_ShuffleMove move, double t) {
    // 4개의 경유점을 t(0~1) 구간에 따라 부드럽게 보간합니다.
    final segment = (t * (move.waypoints.length - 1)).clamp(
      0.0,
      move.waypoints.length - 1.0,
    );
    final index = segment.floor();
    final localT = segment - index;
    if (index >= move.waypoints.length - 1) return move.waypoints.last;
    return Offset.lerp(
      move.waypoints[index],
      move.waypoints[index + 1],
      Curves.easeInOut.transform(localT),
    )!;
  }

  double _rotationAt(_ShuffleMove move, double t) {
    final segment = (t * (move.rotations.length - 1)).clamp(
      0.0,
      move.rotations.length - 1.0,
    );
    final index = segment.floor();
    final localT = segment - index;
    if (index >= move.rotations.length - 1) return move.rotations.last;
    final a = move.rotations[index];
    final b = move.rotations[index + 1];
    return a + (b - a) * Curves.easeInOut.transform(localT);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;
            return Stack(
              alignment: Alignment.center,
              children: List.generate(_cardCount, (i) {
                final move = _moves[i];
                final offset = _offsetAt(move, t);
                final rotation = _rotationAt(move, t);
                return Transform.translate(
                  offset: offset,
                  child: Transform.rotate(
                    angle: rotation,
                    child: _ShuffleCardBack(),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}

class _ShuffleMove {
  final List<Offset> waypoints;
  final List<double> rotations;
  const _ShuffleMove({required this.waypoints, required this.rotations});
}

class _ShuffleCardBack extends StatelessWidget {
  const _ShuffleCardBack();

  @override
  Widget build(BuildContext context) {
    return Container(
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
                          color: AppColors.blobPeachAccent.withValues(
                            alpha: 0.12,
                          ),
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
          const SizedBox(height: 12),
          _SynchronicitySection(unconsciousCatId: cat.id),
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

/// 오늘 무의식(카드뽑기)이 보여준 고양이와, 오늘 의식적으로 쓴 편지의
/// 고양이를 비교해 보여주는 섹션. 프리미엄 전용 기능이며, 무료 유저에게는
/// 잠금 카드(블러 + 안내)로 호기심을 유도합니다.
class _SynchronicitySection extends StatefulWidget {
  final String unconsciousCatId;
  const _SynchronicitySection({required this.unconsciousCatId});

  @override
  State<_SynchronicitySection> createState() => _SynchronicitySectionState();
}

class _SynchronicitySectionState extends State<_SynchronicitySection> {
  bool _loading = true;
  bool _isPremium = false;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final premium = await SubscriptionService().isPremium();
    if (!mounted) return;
    setState(() {
      _isPremium = premium;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();

    if (!_isPremium) {
      return _LockedSynchronicityCard(
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const PremiumScreen()));
        },
      );
    }

    final app = context.watch<AppStateProvider>();
    final consciousCatId = app.todaysLetter?.catId;
    final sentence = ReflectionService.synchronicitySentence(
      consciousCatId: consciousCatId,
      unconsciousCatId: widget.unconsciousCatId,
    );
    if (sentence == null) {
      return GlassBlob(
        accent: AppColors.blobPeriwinkleAccent,
        background: AppColors.blobPeriwinkle,
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const Text('✨', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '오늘 편지도 쓰면, 내 마음과 오늘의 카드을 비교해 볼 수 있어요',
                style: bodyFont(
                  fontSize: 12.5,
                  color: AppColors.moon,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      );
    }
    final insight = ConsciousnessInsightService.build(
      consciousCatId: consciousCatId,
      unconsciousCatId: widget.unconsciousCatId,
    );

    return GlassBlob(
      accent: AppColors.blobPeriwinkleAccent,
      background: AppColors.blobPeriwinkle,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('✨', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                '내 마음과 오늘의 카드',
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
            sentence,
            style: bodyFont(fontSize: 13, color: AppColors.moon, height: 1.5),
          ),
          if (insight != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Row(
                children: [
                  const Text('🔎', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '감정을 돌아보는 질문 더 보기',
                      style: pathLabelFont(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.blobPeriwinkleAccent,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: AppColors.blobPeriwinkleAccent,
                  ),
                ],
              ),
            ),
            if (_expanded) ...[
              const SizedBox(height: 10),
              _ConsciousnessInsightRow(
                icon: '🔍',
                title: '지금은 이런 상태예요',
                body: insight.stateDescription,
              ),
              const SizedBox(height: 10),
              _ConsciousnessInsightRow(
                icon: '🌿',
                title: '이렇게 해보면 좋아요',
                body: insight.solution,
              ),
              const SizedBox(height: 10),
              _ConsciousnessInsightRow(
                icon: '💛',
                title: '위로와 응원의 말',
                body: insight.comfort,
              ),
              const SizedBox(height: 10),
              _ConsciousnessInsightRow(
                icon: '🧘',
                title: '지금 상태에 맞는 명상법',
                body: insight.meditation,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ConsciousnessInsightRow extends StatelessWidget {
  final String icon;
  final String title;
  final String body;
  const _ConsciousnessInsightRow({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bg1.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 6),
              Text(
                title,
                style: pathLabelFont(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: bodyFont(fontSize: 12, color: AppColors.moon, height: 1.6),
          ),
        ],
      ),
    );
  }
}

class _LockedSynchronicityCard extends StatelessWidget {
  final VoidCallback onTap;
  const _LockedSynchronicityCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: GlassBlob(
              accent: AppColors.blobPeriwinkleAccent,
              background: AppColors.blobPeriwinkle,
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('✨', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Text(
                        '내 마음과 오늘의 카드',
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
                    '오늘 편지에서 고른 마음과, 무작위로 뽑힌 카드가\n같았는지 비교해볼 수 있어요.',
                    style: bodyFont(
                      fontSize: 13,
                      color: AppColors.moon,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    color: AppColors.blobPeriwinkleAccent,
                    size: 26,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '프리미엄 · 내 마음과 카드 비교',
                    style: bodyFont(
                      fontSize: 12,
                      color: AppColors.blobPeriwinkleAccent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
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
