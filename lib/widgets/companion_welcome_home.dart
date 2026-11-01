import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/companion_coat.dart';
import '../utils/companion_name.dart';
import 'companion_coat_art.dart';
import 'home_companion_touch.dart';
import 'storybook_art.dart';
import 'storybook_motion.dart';

/// Presentation only. Appearance, name, records and care remain in their stores.
class CompanionWelcomeHome extends StatelessWidget {
  const CompanionWelcomeHome({
    super.key,
    required this.coat,
    required this.onRecord,
    required this.onGarden,
    required this.onChooseCat,
    required this.onCompanionTap,
    required this.onNotices,
    this.name,
    this.growthStage = 0,
    this.bondStage = 0,
    this.motionEnabled = true,
    this.automaticBehavior = true,
    this.loading = false,
    this.error,
    this.onRetry,
    this.selectedMood,
    this.onMoodSelected,
    this.selecting = false,
    this.footer = const SizedBox.shrink(),
  });
  final CompanionCoat? coat;
  final String? name, error;
  final int growthStage, bondStage;
  final bool motionEnabled, automaticBehavior, loading, selecting;
  final int? selectedMood;
  final ValueChanged<int>? onMoodSelected;
  final VoidCallback onRecord, onGarden, onChooseCat, onCompanionTap, onNotices;
  final VoidCallback? onRetry;
  final Widget footer;

  static const paper = Color(0xfffcf9f3);
  static const ink = Color(0xff292b26);
  static const sage = Color(0xff6d8869);
  static const line = Color(0xffe8e1d6);
  TextStyle text(
    double size, {
    FontWeight weight = FontWeight.w500,
    Color color = ink,
  }) => TextStyle(
    fontFamily: 'GowunDodum',
    fontSize: size,
    height: 1.35,
    fontWeight: weight,
    color: color,
  );

  Widget _identity(String displayName) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 5, 24, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                loading ? '함께하는 고양이' : displayName,
                key: const Key('home-companion-name'),
                textAlign: TextAlign.center,
                style: text(24, weight: FontWeight.w800),
              ),
            ),
            IconButton(
              tooltip: '고양이 선택',
              onPressed: selecting ? null : onChooseCat,
              icon: const Icon(Icons.pets_outlined, color: sage, size: 21),
            ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26),
        child: Text(
          '왔구나, 여기서 같이 쉬자.',
          key: const Key('home-greeting'),
          textAlign: TextAlign.center,
          style: text(15, color: const Color(0xff64745e)),
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final displayName = companionDisplayName(name);
    return ListView(
      key: const PageStorageKey('pastel-page-0'),
      padding: EdgeInsets.zero,
      children: [
        LayoutBuilder(
          builder: (context, box) {
            final largeText = MediaQuery.textScalerOf(context).scale(14) > 20;
            final catHeight = math
                .min(
                  box.maxWidth * .70,
                  MediaQuery.sizeOf(context).height * .31,
                )
                .clamp(165.0, 275.0);
            final hero = DecoratedBox(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/storybook_ui_v2/home-room.png'),
                  fit: BoxFit.cover,
                  alignment: Alignment.bottomCenter,
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: StorybookMotion(enabled: motionEnabled),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 10, 0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '마음냥 정원',
                                style: text(23, weight: FontWeight.w800),
                              ),
                            ),
                            IconButton(
                              key: const Key('home-notices'),
                              tooltip: '정원 소식',
                              onPressed: onNotices,
                              icon: const Icon(
                                Icons.notifications_none_rounded,
                                color: ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!largeText) _identity(displayName),
                      SizedBox(
                        height: catHeight,
                        width: double.infinity,
                        child: loading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  semanticsLabel: '고양이 정보 불러오는 중',
                                ),
                              )
                            : error != null
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        error!,
                                        textAlign: TextAlign.center,
                                        style: text(14),
                                      ),
                                      if (onRetry != null)
                                        TextButton(
                                          onPressed: onRetry,
                                          child: const Text('다시 불러오기'),
                                        ),
                                    ],
                                  ),
                                ),
                              )
                            : Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 22),
                                child: CompanionCoatScope(
                                  key: ValueKey('home-coat-${coat?.name ?? 'legacy'}'),
                                  useLocalChoice: true,
                                  coat: coat,
                                  growthStage: growthStage,
                                  child: HomeCompanionTouch(
                                    name: displayName,
                                    enabled: automaticBehavior,
                                    bondStage: bondStage,
                                  ),
                                ),
                              ),
                      ),
                      Center(child: TextButton.icon(
                        key: const Key('home-companion-care'),
                        onPressed: loading || error != null ? null : onCompanionTap,
                        icon: const Icon(Icons.favorite_border, size: 18),
                        label: const Text('돌봐주기'),
                      )),
                    ],
                  ),
                ],
              ),
            );
            // At large text sizes the cat comes first; long names never push
            // its eyes below the initial viewport or overlap the face.
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [hero, if (largeText) _identity(displayName)],
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '오늘 하루는 어땠어?',
                textAlign: TextAlign.center,
                style: text(22, weight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, box) {
                  final large = MediaQuery.textScalerOf(context).scale(13) > 18;
                  final columns = large ? 3 : 5;
                  const labels = ['좋아요', '평온해요', '보통', '힘들어요', '지쳤어요'];
                  return Wrap(
                    spacing: 5,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: [
                      for (var i = 0; i < 5; i++)
                        SizedBox(
                          width: (box.maxWidth - (columns - 1) * 5) / columns,
                          child: Semantics(
                            button: true,
                            selected: selectedMood == i,
                            label: labels[i],
                            child: Material(
                              color: selectedMood == i
                                  ? const Color(0xffeef2e7)
                                  : Colors.white.withValues(alpha: .86),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(17),
                                side: BorderSide(
                                  color: selectedMood == i
                                      ? sage
                                      : Colors.transparent,
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () => onMoodSelected?.call(i),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 7,
                                    horizontal: 2,
                                  ),
                                  child: Column(
                                    children: [
                                      SizedBox(
                                        height: 43,
                                        width: double.infinity,
                                        child: StorySprite.icon(i),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        labels[i],
                                        textAlign: TextAlign.center,
                                        style: text(
                                          12,
                                          weight: selectedMood == i
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 13),
              FilledButton.icon(
                key: const Key('home-record'),
                onPressed: onRecord,
                style: FilledButton.styleFrom(
                  backgroundColor: sage,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 53),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                icon: const Icon(Icons.edit_outlined, size: 22),
                label: Text(
                  '마음 기록하기',
                  style: text(18, weight: FontWeight.w700, color: Colors.white),
                ),
              ),
              const SizedBox(height: 12),
              Material(
                color: Colors.white.withValues(alpha: .85),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: line),
                ),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  key: const Key('home-garden'),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 3,
                  ),
                  leading: const SizedBox(
                    width: 52,
                    height: 52,
                    child: StorySprite.icon(5),
                  ),
                  title: Text(
                    '우리 정원 둘러보기',
                    style: text(16, weight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '함께 가꾼 작은 변화를 만나봐요',
                    style: text(12, color: const Color(0xff777b70)),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: sage,
                  ),
                  onTap: onGarden,
                ),
              ),
              const SizedBox(height: 8),
              footer,
            ],
          ),
        ),
      ],
    );
  }
}
