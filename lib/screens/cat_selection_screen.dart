import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/shadow_cats_data.dart';
import '../models/shadow_cat.dart';
import '../providers/app_state_provider.dart';
import '../theme.dart';

/// 36마리 그림자 감정 고양이 카드 그리드에서 지금 내 기분과 닮은
/// 고양이 한 마리를 골라 선택하는 화면.
/// 딱딱한 사각 카드 그리드 대신, 카드마다 조금씩 다른 유기적인 블롭
/// 모양과 파스텔 톤을 주어 정원의 화단처럼 느껴지도록 합니다.
class CatSelectionScreen extends StatelessWidget {
  const CatSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          '36마리의 그림자 감정 고양이 카드 중\n마음에 닿는 카드를 골라보세요',
          textAlign: TextAlign.center,
          style: bodyFont(
            fontSize: 12.5,
            color: AppColors.inkSoft,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 18),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: shadowCats.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.78,
          ),
          itemBuilder: (context, index) {
            final cat = shadowCats[index];
            return _CatCard(
              cat: cat,
              seed: index,
              onTap: () => context.read<AppStateProvider>().selectCat(cat),
            );
          },
        ),
      ],
    );
  }
}

class _CatCard extends StatefulWidget {
  final ShadowCat cat;
  final int seed;
  final VoidCallback onTap;
  const _CatCard({required this.cat, required this.seed, required this.onTap});

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
                      child: Image.asset(
                        widget.cat.imageAsset,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(widget.cat.emoji, style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(
                    widget.cat.nameKr,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: pathLabelFont(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
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
