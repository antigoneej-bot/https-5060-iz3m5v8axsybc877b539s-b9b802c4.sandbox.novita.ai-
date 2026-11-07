import '../l10n/app_language.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/shadow_cat.dart';
import '../theme.dart';
import 'emotion_cat_video.dart';

/// Browsing changes focus only; the explicit button commits the emotion.
class EmotionCatCarousel extends StatefulWidget {
  final List<ShadowCat> cats;
  final Set<String> favorites;
  final ValueChanged<ShadowCat> onSelect;
  final ValueChanged<String> onFavorite;
  const EmotionCatCarousel({
    super.key,
    required this.cats,
    required this.favorites,
    required this.onSelect,
    required this.onFavorite,
  }) : assert(cats.length > 0);

  @override
  State<EmotionCatCarousel> createState() => _EmotionCatCarouselState();
}

class _EmotionCatCarouselState extends State<EmotionCatCarousel>
    with SingleTickerProviderStateMixin {
  final _pages = PageController(viewportFraction: .82);
  late final _float = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  );
  int _index = 0;
  bool _moving = false;

  static const _colors = [
    AppColors.blobMint,
    AppColors.blobPeach,
    AppColors.blobLavender,
    AppColors.blobRose,
    AppColors.blobButter,
    AppColors.blobPeriwinkle,
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) || !TickerMode.of(context)) {
      _float.stop();
    } else if (!_float.isAnimating) {
      _float.repeat();
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    _float.dispose();
    super.dispose();
  }

  void _move(int delta) {
    final target = (_index + delta).clamp(0, widget.cats.length - 1);
    if (MediaQuery.disableAnimationsOf(context)) {
      _pages.jumpToPage(target);
    } else {
      _pages.animateToPage(
        target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    final cat = widget.cats[_index];
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final height = (constraints.maxWidth * .88).clamp(220.0, 380.0);
            return SizedBox(
              height: height,
              child: NotificationListener<ScrollNotification>(
                onNotification: (notice) {
                  if (notice.depth == 0) {
                    if (notice is ScrollStartNotification && !_moving) {
                      setState(() => _moving = true);
                    } else if (notice is ScrollEndNotification && _moving) {
                      setState(() => _moving = false);
                    }
                  }
                  return false;
                },
                child: PageView.builder(
                  key: const ValueKey('emotion-carousel-pages'),
                  controller: _pages,
                  itemCount: widget.cats.length,
                  onPageChanged: (value) => setState(() => _index = value),
                  itemBuilder: (context, index) {
                    final item = widget.cats[index];
                    final focused = index == _index;
                    return AnimatedScale(
                      scale: focused ? 1 : .9,
                      duration: Duration(milliseconds: reduced ? 0 : 220),
                      child: AnimatedBuilder(
                        animation: _float,
                        builder: (context, child) => Transform.translate(
                          offset: Offset(
                            0,
                            reduced || !focused
                                ? 0
                                : math.sin(_float.value * math.pi * 2) * 3,
                          ),
                          child: child,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(7, 10, 7, 14),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _colors[index % _colors.length],
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.ink.withValues(alpha: .08),
                                  blurRadius: 12,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ExcludeSemantics(
                              excluding: !focused,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(22),
                                    child: TickerMode(
                                      enabled: focused && !_moving,
                                      child: EmotionCatVideo(
                                        key: ValueKey(item.id),
                                        imageAsset: item.imageAsset,
                                        imageCacheWidth: 900,
                                        videoAsset: focused
                                            ? item.videoAsset
                                            : null,
                                      ),
                                    ),
                                  ),
                                  if (focused)
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: IconButton.filledTonal(
                                        tooltip:
                                            widget.favorites.contains(item.id)
                                            ? tr("즐겨찾기 해제")
                                            : tr("즐겨찾기 추가"),
                                        onPressed: () =>
                                            widget.onFavorite(item.id),
                                        icon: Icon(
                                          widget.favorites.contains(item.id)
                                              ? Icons.star_rounded
                                              : Icons.star_border_rounded,
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
                  },
                ),
              ),
            );
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              tooltip: tr("이전 감정"),
              onPressed: _index > 0 && !_moving ? () => _move(-1) : null,
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Semantics(
              liveRegion: true,
              child: Text(
                '${_index + 1} / ${widget.cats.length}',
                style: bodyFont(fontSize: 13, color: AppColors.inkSoft),
              ),
            ),
            IconButton(
              tooltip: tr("다음 감정"),
              onPressed: _index < widget.cats.length - 1 && !_moving
                  ? () => _move(1)
                  : null,
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
        Text(
          '${cat.emoji} ${cat.displayKeyword}',
          textAlign: TextAlign.center,
          style: titleFont(fontSize: 23, color: AppColors.ink),
        ),
        const SizedBox(height: 6),
        Text(
          cat.displayName,
          textAlign: TextAlign.center,
          style: bodyFont(fontSize: 14, color: AppColors.inkSoft),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Text(
            cat.comfortMessage,
            textAlign: TextAlign.center,
            style: bodyFont(fontSize: 14, height: 1.6, color: AppColors.ink),
          ),
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: FilledButton(
            key: const ValueKey('confirm-emotion'),
            onPressed: _moving ? null : () => widget.onSelect(cat),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.titlePastelGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
            child: Text(
              tr("지금 내 마음이에요"),
              style: bodyFont(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
