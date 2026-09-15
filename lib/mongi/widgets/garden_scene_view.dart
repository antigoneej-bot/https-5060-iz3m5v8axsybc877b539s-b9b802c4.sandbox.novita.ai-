import '../integration/garden_care_tree.dart';
import '../../providers/app_state_provider.dart';
import '../../data/shadow_cats_data.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/garden_season_l10n.dart';
import '../l10n/gen/app_localizations.dart';
import '../l10n/seed_l10n.dart';
import '../l10n/tree_growth_l10n.dart';
import '../models/garden_decoration.dart';
import '../models/garden_season.dart';
import '../models/mongi_care_item.dart';
import '../models/seed.dart';
import '../models/tree_growth.dart';
import '../providers/garden_provider.dart';
import 'garden_decoration_sheet.dart';
import 'mongi_care_sheet.dart';

/// "내 정원" - 구독자(사용자) 한 명 한 명의 개인 정원을 하나의 살아있는 그림으로
/// 시각화하는 씬. 목록이 아니라 실제 정원처럼 씨앗이 자라난 화분과, 장착해둔
/// 장식 아이템들이 각자의 자리에 놓여 눈에 보이게 배치된다.
///
/// - 배경: assets/mongi/images/garden_scene_bg.png (잔디밭 + 하늘)
/// - 씨앗: [SeedType.all]을 순회하며 각자의 [SeedType.sceneAnchor] 위치에
///   [seedCounts] 누적치에 따른 성장 단계 이모지를 그린다.
/// - 장식: 장착된([GardenProvider.isDecorationEquipped]) 항목만 각자의
///   [GardenDecoration.sceneAnchor] 위치에 그린다.
///
/// 데이터 기반 배치 구조라서, 새로운 씨앗/장식 종류가 추가돼도 이 위젯의
/// 코드는 수정할 필요가 없다 - 좌표만 모델에 정해주면 자동으로 그려진다.
///
/// "정원의 계절 변화"(Idea #4): 실제 달력 월([GardenSeason.current])에 따라
/// 은은한 색 틴트 + 떠다니는 파티클(꽃잎/반짝임/낙엽/눈)을 씬 위에 얹어,
/// 배경 이미지를 새로 그리지 않고도 "같은 정원인데 계절이 다르다"는 느낌을
/// 낸다. 유저가 아무것도 하지 않아도 그날그날 정원이 다르게 보인다.
class GardenSceneView extends StatelessWidget {
  /// true면 우측 상단에 "꾸미기" 버튼을 보여줘서 [GardenDecorationSheet]를 열 수 있다.
  final bool interactive;
  final double height;

  const GardenSceneView({
    super.key,
    this.interactive = true,
    this.height = 320,
  });

  @override
  Widget build(BuildContext context) {
    final garden = context.watch<GardenProvider>();
    final season = GardenSeason.current;
    final met = context.watch<AppStateProvider>().metCatIds;
    final cats = shadowCats
        .where((cat) => met.contains(cat.id))
        .take(6)
        .toList();
    final l10n = AppLocalizations.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 배경 정원 그림
            Image.asset(
              'assets/mongi/images/garden_scene_bg.png',
              fit: BoxFit.cover,
            ),

            // 계절 색 틴트 - 배경을 다시 그리지 않고도 계절 분위기를 낸다.
            Container(
              color: season.tintColor.withValues(alpha: season.tintAlpha),
            ),

            // 계절 파티클(꽃잎/반짝임/낙엽/눈)이 은은하게 떠다닌다.
            _SeasonParticleOverlay(season: season, height: height),

            // 은은한 하단 그림자 (지면 느낌 강조)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: height * 0.28,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.0),
                      Colors.black.withValues(alpha: 0.08),
                    ],
                  ),
                ),
              ),
            ),

            // 장착된 장식 아이템들 (데이터 기반 배치)
            ...GardenDecoration.all
                .where((d) => garden.isDecorationEquipped(d))
                .map(
                  (d) => _ScenePlacedItem(
                    alignment: d.sceneAnchor,
                    scale: d.sceneScale,
                    child: _DecorationBadge(emoji: d.emoji),
                  ),
                ),

            // 몽이 돌봄 선물(담요/몽이의 집) - 한 번 선물하면 영구히 자리를 지킨다.
            ...MongiCareItem.all
                .where((i) => i.isKeepsake && garden.hasMongiKeepsake(i))
                .map(
                  (i) => _ScenePlacedItem(
                    alignment: i.sceneAnchor,
                    scale: i.sceneScale,
                    child: _DecorationBadge(emoji: i.emoji),
                  ),
                ),

            // 씨앗별 화분/성장 (데이터 기반 배치)
            ...SeedType.all
                .where(
                  (seed) =>
                      (garden.seedCounts[seed.id] ?? 0) > 0 ||
                      {'forgiveness', 'love', 'peace'}.contains(seed.id),
                )
                .map((seed) {
                  final count = garden.seedCounts[seed.id] ?? 0;
                  return _ScenePlacedItem(
                    alignment: seed.sceneAnchor,
                    child: _SeedPot(seed: seed, count: count),
                  );
                }),

            // 몽이의 성장나무 (누적 점수 기반, C.2) - 씨앗들보다 살짝 위쪽 중앙에 배치.
            // 아직 첫 단계(새싹)에도 못 미치면 그리지 않는다.
            if (garden.treeStageIndex >= 0)
              _ScenePlacedItem(
                alignment: const Alignment(0.0, -0.32),
                child: _GrowthTree(
                  stageIndex: garden.treeStageIndex,
                  isWilted: garden.isTreeWilted,
                ),
              ),

            if (cats.isNotEmpty)
              Positioned(
                bottom: 8,
                left: 12,
                right: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: cats
                      .map(
                        (cat) => Tooltip(
                          message: cat.nameKr,
                          child: SizedBox(
                            width: 40,
                            height: 44,
                            child: Image.asset(
                              cat.imageAsset,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            const Positioned(right: 16, bottom: 70, child: GardenCareTree()),
            // 상단 타이틀 배지 + 계절 배지
            Positioned(
              top: 14,
              left: 14,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _GlassBadge(
                    child: Text(
                      l10n.gardenSceneTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: Color(0xFF3D5A3D),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _GlassBadge(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(gardenSeasonGreeting(l10n, season)),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Text(
                      '${season.emoji} ${gardenSeasonLabel(l10n, season)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                        color: Color(0xFF3D5A3D),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 꾸미기 / 돌봄 버튼
            if (interactive)
              Positioned(
                top: 14,
                right: 14,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _GlassBadge(
                      onTap: () => MongiCareSheet.show(context),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🍚', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 4),
                          Text(
                            l10n.gardenSceneCareButton,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12.5,
                              color: Color(0xFF3D5A3D),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    _GlassBadge(
                      onTap: () => showGardenDecorationSheet(context),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🎨', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 4),
                          Text(
                            l10n.gardenSceneDecorateButton,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12.5,
                              color: Color(0xFF3D5A3D),
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
      ),
    );
  }
}

/// Alignment 기반 좌표로 씬 위에 자식을 배치하는 헬퍼.
class _ScenePlacedItem extends StatelessWidget {
  final Alignment alignment;
  final double scale;
  final Widget child;

  const _ScenePlacedItem({
    required this.alignment,
    required this.child,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Transform.scale(scale: scale, child: child),
    );
  }
}

/// 씨앗 하나의 화분 표현: 성장 단계 이모지 + 살짝 흔들리는 애니메이션으로
/// "살아있는 정원" 느낌을 준다.
class _SeedPot extends StatefulWidget {
  final SeedType seed;
  final int count;

  const _SeedPot({required this.seed, required this.count});

  @override
  State<_SeedPot> createState() => _SeedPotState();
}

class _SeedPotState extends State<_SeedPot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tier = widget.seed.tierForCount(widget.count);
    final emoji = widget.seed.emojiForCount(widget.count);
    final fontSize = 26.0 + tier * 5.0;
    final l10n = AppLocalizations.of(context);

    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.count > 0
                  ? l10n.gardenSeedPotWatered(
                      seedLabel(l10n, widget.seed),
                      widget.count,
                    )
                  : l10n.gardenSeedPotNotPlanted(seedLabel(l10n, widget.seed)),
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final sway = (_controller.value - 0.5) * 0.10; // 살짝 좌우로 흔들림
          return Transform.rotate(
            angle: widget.count > 0 ? sway : 0.0,
            child: Text(emoji, style: TextStyle(fontSize: fontSize)),
          );
        },
      ),
    );
  }
}

/// 몽이의 성장나무 하나의 씬 표현: 성장 단계 일러스트 + 살짝 흔들리는 애니메이션으로
/// "살아있는 정원" 느낌을 준다. [_SeedPot]과 같은 구조를 따른다.
class _GrowthTree extends StatefulWidget {
  final int stageIndex;
  final bool isWilted;

  const _GrowthTree({required this.stageIndex, this.isWilted = false});

  @override
  State<_GrowthTree> createState() => _GrowthTreeState();
}

class _GrowthTreeState extends State<_GrowthTree>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asset = TreeGrowth.stageAssets[widget.stageIndex];
    final l10n = AppLocalizations.of(context);
    final label = treeStageLabel(l10n, widget.stageIndex);
    final height = 56.0 + widget.stageIndex * 14.0;

    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isWilted
                  ? l10n.gardenTreeWiltedSnackbar
                  : l10n.gardenTreeStageSnackbar(label),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          // 시들었을 때는 흔들림 폭도 살짝 줄여서 "기운 없는" 느낌을 은은하게 더한다.
          final swayRange = widget.isWilted ? 0.04 : 0.08;
          final sway = (_controller.value - 0.5) * swayRange;
          final tree = Image.asset(asset, height: height);
          final wiltedTree = widget.isWilted
              ? ColorFiltered(
                  colorFilter: const ColorFilter.matrix(<double>[
                    0.55, 0.35, 0.10, 0, -6, // R - 채도를 낮춰 살짝 바랜 톤으로
                    0.25, 0.55, 0.10, 0, -6, // G
                    0.20, 0.30, 0.40, 0, -6, // B
                    0, 0, 0, 1, 0, // A
                  ]),
                  child: Opacity(opacity: 0.82, child: tree),
                )
              : tree;
          return Transform.rotate(angle: sway, child: wiltedTree);
        },
      ),
    );
  }
}

/// 계절별 파티클(꽃잎/반짝임/낙엽/눈)이 정원 씬 위에서 위에서 아래로
/// 천천히 흩날리는 오버레이. 각 파티클은 서로 다른 시작 위치/속도/흔들림
/// 위상을 랜덤으로 갖되, [season]이 바뀌기 전까진 매 프레임 같은 시드로
/// 재계산되어 자연스럽게 순환한다(무한 반복, 끊김 없음).
class _SeasonParticleOverlay extends StatefulWidget {
  final GardenSeason season;
  final double height;

  const _SeasonParticleOverlay({required this.season, required this.height});

  @override
  State<_SeasonParticleOverlay> createState() => _SeasonParticleOverlayState();
}

class _SeasonParticleOverlayState extends State<_SeasonParticleOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late List<_SeasonParticleSpec> _specs;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
    _specs = _buildSpecs(widget.season);
  }

  @override
  void didUpdateWidget(_SeasonParticleOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.season != widget.season) {
      _specs = _buildSpecs(widget.season);
    }
  }

  List<_SeasonParticleSpec> _buildSpecs(GardenSeason season) {
    final rand = math.Random(season.index * 97 + 13);
    return List.generate(season.particleCount, (i) {
      return _SeasonParticleSpec(
        startX: rand.nextDouble(),
        // 각 파티클이 서로 다른 시점에서 시작하도록 위상을 어긋나게 준다.
        phase: rand.nextDouble(),
        // 파티클마다 낙하 속도를 조금씩 다르게 해 층이 생기는 느낌을 준다.
        speed: 0.6 + rand.nextDouble() * 0.7,
        swayAmplitude: 10 + rand.nextDouble() * 18,
        size: 12 + rand.nextDouble() * 8,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : 320.0;
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Stack(
                children: _specs.map((spec) {
                  // t: 0.0~1.0 반복 - 화면 위에서 아래로 흐르는 진행도.
                  final t = (_controller.value + spec.phase) % 1.0;
                  final y = t * widget.height;
                  final sway =
                      math.sin(t * 2 * math.pi * 1.6) * spec.swayAmplitude;
                  // 위/아래 끝에서는 살짝 페이드 인/아웃되어 갑자기 나타나거나
                  // 사라지는 느낌을 줄인다.
                  final fade = (t < 0.08)
                      ? (t / 0.08)
                      : (t > 0.9 ? (1.0 - t) / 0.1 : 1.0);
                  return Positioned(
                    left: (spec.startX * width + sway).clamp(0.0, width),
                    top: y,
                    child: Opacity(
                      opacity: fade.clamp(0.0, 1.0) * 0.85,
                      child: Text(
                        widget.season.particleEmoji,
                        style: TextStyle(fontSize: spec.size),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          );
        },
      ),
    );
  }
}

/// 파티클 하나의 고정된 특성(랜덤이지만 계절이 바뀌기 전까지는 유지됨).
class _SeasonParticleSpec {
  final double startX; // 0.0~1.0 (가로 위치 비율)
  final double phase; // 0.0~1.0 (애니메이션 시작 위상)
  final double speed; // 낙하 속도 배율(현재는 시각적 의미만, phase로 층 표현)
  final double swayAmplitude; // 좌우로 흔들리는 폭(px)
  final double size; // 이모지 폰트 크기

  const _SeasonParticleSpec({
    required this.startX,
    required this.phase,
    required this.speed,
    required this.swayAmplitude,
    required this.size,
  });
}

/// 장착된 장식 아이템 하나를 씬 위에 표시하는 뱃지.
class _DecorationBadge extends StatelessWidget {
  final String emoji;
  const _DecorationBadge({required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Text(emoji, style: const TextStyle(fontSize: 30));
  }
}

/// 반투명 유리질감 뱃지 (타이틀/버튼 공용).
class _GlassBadge extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _GlassBadge({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.82),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: child,
        ),
      ),
    );
  }
}
