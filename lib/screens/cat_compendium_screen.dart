import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/shadow_cats_data.dart';
import '../models/shadow_cat.dart';
import '../providers/app_state_provider.dart';
import '../theme.dart';
import '../widgets/lively_cat_image.dart';
import '../widgets/garden_path_card.dart';

/// "그림자 고양이 도감" - 지금까지 만난 고양이와, 아직 만나지 못한 고양이를
/// 한눈에 볼 수 있는 수집 화면. 앱의 핵심 후크인 '36마리 그림자 감정 고양이
/// 여정'의 진행 상황을 보여주고, 아직 만나지 못한 고양이에 대한 궁금증을
/// 자연스럽게 자극합니다.
class CatCompendiumScreen extends StatelessWidget {
  const CatCompendiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppStateProvider>();
    final metIds = app.metCatIds;
    final metCount = metIds.length;
    final total = shadowCats.length;
    final progress = total == 0 ? 0.0 : metCount / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '그림자 고양이 도감',
          textAlign: TextAlign.center,
          style: titleFont(fontSize: 24, color: AppColors.ink),
        ),
        const SizedBox(height: 8),
        Text(
          '$total마리 중 $metCount마리를 만났어요',
          textAlign: TextAlign.center,
          style: bodyFont(fontSize: 13, color: AppColors.inkSoft),
        ),
        const SizedBox(height: 16),
        GlassBlob(
          accent: AppColors.blobPeachAccent,
          background: AppColors.blobPeach,
          floatSeed: 31,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  backgroundColor: Colors.white.withValues(alpha: 0.55),
                  valueColor: const AlwaysStoppedAnimation(
                    AppColors.blobPeachAccent,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                metCount == total
                    ? '36마리를 모두 만났어요. 정원이 가득 채워졌네요 🌸'
                    : '아직 만나지 못한 ${total - metCount}마리가\n정원 어딘가에서 조용히 기다리고 있어요',
                textAlign: TextAlign.center,
                style: bodyFont(
                  fontSize: 12,
                  color: AppColors.inkSoft,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
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
            final met = metIds.contains(cat.id);
            return _CompendiumTile(cat: cat, met: met, seed: index);
          },
        ),
      ],
    );
  }
}

class _CompendiumTile extends StatelessWidget {
  final ShadowCat cat;
  final bool met;
  final int seed;
  const _CompendiumTile({
    required this.cat,
    required this.met,
    required this.seed,
  });

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

  BorderRadius _blobRadius() {
    final rng = Random(seed * 13 + 5);
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
    final accent = _accents[seed % _accents.length];
    final background = _backgrounds[seed % _backgrounds.length];
    final radius = _blobRadius();
    return GestureDetector(
      onTap: () => met ? _showMetDetail(context) : _showLockedTeaser(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: met
                ? [
                    background.withValues(alpha: 0.78),
                    background.withValues(alpha: 0.46),
                  ]
                : [
                    AppColors.bg2.withValues(alpha: 0.7),
                    AppColors.bg2.withValues(alpha: 0.4),
                  ],
          ),
          border: Border.all(
            color: met
                ? accent.withValues(alpha: 0.28)
                : AppColors.line.withValues(alpha: 0.6),
            width: 1.1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: met
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: LivelyCatImage(
                        imageAsset: cat.imageAsset,
                        width: double.infinity,
                        height: double.infinity,
                        borderRadius: BorderRadius.circular(14),
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ColorFiltered(
                            colorFilter: const ColorFilter.matrix(<double>[
                              0,
                              0,
                              0,
                              0,
                              30,
                              0,
                              0,
                              0,
                              0,
                              30,
                              0,
                              0,
                              0,
                              0,
                              34,
                              0,
                              0,
                              0,
                              0.55,
                              0,
                            ]),
                            child: Image.asset(
                              cat.imageAsset,
                              fit: BoxFit.cover,
                            ),
                          ),
                          BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 3.2, sigmaY: 3.2),
                            child: Container(
                              color: Colors.black.withValues(alpha: 0.06),
                            ),
                          ),
                          const Center(
                            child: Text(
                              '?',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            Text(met ? cat.emoji : '🌫️', style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 2),
            Text(
              met ? cat.nameKr : '???',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: pathLabelFont(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: met ? AppColors.ink : AppColors.inkSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMetDetail(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.bg0.withValues(alpha: 0.98),
                background.withValues(alpha: 0.7),
              ],
            ),
            border: Border.all(
              color: accent.withValues(alpha: 0.25),
              width: 1.2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${cat.emoji} ${cat.nameKr}',
                      style: titleFont(fontSize: 19, color: AppColors.ink),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: const Icon(
                      Icons.close,
                      color: AppColors.inkSoft,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(cat.keyword, style: bodyFont(fontSize: 11.5, color: accent)),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  cat.imageAsset,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  cat.story,
                  style: bodyFont(
                    fontSize: 13,
                    color: AppColors.moon,
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLockedTeaser(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: AppColors.bg0.withValues(alpha: 0.98),
            border: Border.all(color: AppColors.line, width: 1.2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🌫️', style: TextStyle(fontSize: 34)),
              const SizedBox(height: 12),
              Text(
                '아직 만나지 못한 고양이예요',
                style: pathLabelFont(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '오늘의 기분을 골라 편지를 써보면,\n언젠가 이 고양이와 마주치게 될지도 몰라요',
                textAlign: TextAlign.center,
                style: bodyFont(
                  fontSize: 12,
                  color: AppColors.inkSoft,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  '알겠어요',
                  style: bodyFont(fontSize: 12.5, color: AppColors.inkSoft),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color get accent => _accents[seed % _accents.length];
  Color get background => _backgrounds[seed % _backgrounds.length];
}
