import 'package:flutter/material.dart';

/// 마음정원을 꾸미는 장식 아이템(벤치/분수대/오솔길/조명 등).
///
/// [SeedType]과 마찬가지로 리스트([all]) 기반 확장 구조로 설계했다 - 새 장식을
/// 추가해도 화면(GardenDecorationSheet, GardenScreen) 코드는 수정할 필요가 없다.
///
/// 무료 아이템은 앱을 자연스럽게 이용하다 보면 달성하게 되는 마일스톤으로
/// 잠금 해제되고(스트릭, 씨앗 완성, 정원 만개 등), 프리미엄 아이템은
/// [kGardenDecorationPackProductId] 인앱 상품을 구매하면 한 번에 전부 해제된다.
///
/// [sceneAnchor]/[sceneScale]는 "내 정원" 시각화 씬([GardenSceneView])에서
/// 이 장식을 어디에, 얼마나 크게 배치할지를 나타낸다. 데이터 기반 배치이므로
/// 새 장식을 추가할 때 씬 코드는 건드릴 필요 없이 좌표만 정해주면 된다.
class GardenDecoration {
  final String id;
  final String label;
  final String emoji;
  final bool isPremium;

  /// 무료 아이템: 어떻게 잠금 해제되는지 설명.
  /// 프리미엄 아이템: 어떤 팩을 구매하면 되는지 설명.
  final String unlockHint;

  /// 정원 씬 안에서의 위치 (-1.0 ~ 1.0 상대 좌표, Alignment 규칙과 동일).
  final Alignment sceneAnchor;

  /// 정원 씬에서 보여줄 때 이모지 크기 배율 (기본 1.0).
  final double sceneScale;

  const GardenDecoration({
    required this.id,
    required this.label,
    required this.emoji,
    required this.isPremium,
    required this.unlockHint,
    this.sceneAnchor = Alignment.center,
    this.sceneScale = 1.0,
  });

  static GardenDecoration byId(String id) {
    return all.firstWhere((d) => d.id == id, orElse: () => all.first);
  }

  static const List<GardenDecoration> all = [
    // 무료 - 자연스러운 이용 마일스톤으로 잠금 해제
    GardenDecoration(
      id: 'bench',
      label: '나무 벤치',
      emoji: '🪵',
      isPremium: false,
      unlockHint: '3일 연속 몽이를 만나면 잠금 해제돼요',
      sceneAnchor: Alignment(-0.82, 0.55),
      sceneScale: 1.1,
    ),
    GardenDecoration(
      id: 'path',
      label: '조약돌 오솔길',
      emoji: '🪨',
      isPremium: false,
      unlockHint: '정원을 처음 만개시키면 잠금 해제돼요',
      sceneAnchor: Alignment(0.0, 0.86),
      sceneScale: 1.3,
    ),
    GardenDecoration(
      id: 'fountain',
      label: '작은 분수대',
      emoji: '⛲',
      isPremium: false,
      unlockHint: '용서·사랑·평안 씨앗을 모두 심으면 잠금 해제돼요',
      sceneAnchor: Alignment(0.85, 0.5),
      sceneScale: 1.15,
    ),
    // 프리미엄 - 정원 장식팩 구매로 전부 잠금 해제
    GardenDecoration(
      id: 'lantern',
      label: '종이등',
      emoji: '🏮',
      isPremium: true,
      unlockHint: '정원 장식팩을 구매하면 사용할 수 있어요',
      sceneAnchor: Alignment(-0.9, -0.55),
      sceneScale: 1.0,
    ),
    GardenDecoration(
      id: 'rainbow_fence',
      label: '무지개 울타리',
      emoji: '🌈',
      isPremium: true,
      unlockHint: '정원 장식팩을 구매하면 사용할 수 있어요',
      sceneAnchor: Alignment(0.0, -0.78),
      sceneScale: 1.4,
    ),
    GardenDecoration(
      id: 'star_light',
      label: '반짝이는 별빛',
      emoji: '✨',
      isPremium: true,
      unlockHint: '정원 장식팩을 구매하면 사용할 수 있어요',
      sceneAnchor: Alignment(0.88, -0.6),
      sceneScale: 1.0,
    ),
    // ── 신규 무료 장식 - 조금 더 깊은 마일스톤으로 잠금 해제 ──
    GardenDecoration(
      id: 'wind_chime',
      label: '풍경 윈드차임',
      emoji: '🎐',
      isPremium: false,
      unlockHint: '7일 연속 몽이를 만나면 잠금 해제돼요',
      sceneAnchor: Alignment(-0.55, -0.72),
      sceneScale: 0.9,
    ),
    GardenDecoration(
      id: 'butterfly_garden',
      label: '나비 정원',
      emoji: '🦋',
      isPremium: false,
      unlockHint: '감정을 3개 이상 마스터 등급으로 키우면 잠금 해제돼요',
      sceneAnchor: Alignment(0.45, 0.72),
      sceneScale: 0.85,
    ),
    // ── 신규 프리미엄 장식 - 정원 장식팩 구매로 함께 잠금 해제 ──
    GardenDecoration(
      id: 'gazebo',
      label: '아늑한 정자',
      emoji: '🏯',
      isPremium: true,
      unlockHint: '정원 장식팩을 구매하면 사용할 수 있어요',
      sceneAnchor: Alignment(-0.35, 0.15),
      sceneScale: 1.2,
    ),
    GardenDecoration(
      id: 'lotus_pond',
      label: '연꽃 연못',
      emoji: '🪷',
      isPremium: true,
      unlockHint: '정원 장식팩을 구매하면 사용할 수 있어요',
      sceneAnchor: Alignment(0.35, 0.15),
      sceneScale: 1.05,
    ),
    // ── 한국적 신규 장식 - 무료(마일스톤) + 프리미엄 혼합 ──
    GardenDecoration(
      id: 'jangdokdae',
      label: '장독대',
      emoji: '🏺',
      isPremium: false,
      unlockHint: '꽃을 10번 이상 피우면 잠금 해제돼요',
      sceneAnchor: Alignment(-0.68, 0.68),
      sceneScale: 0.95,
    ),
    GardenDecoration(
      id: 'ginkgo_path',
      label: '은행나무길',
      emoji: '🍃',
      isPremium: false,
      unlockHint: '14일 연속 몽이를 만나면 잠금 해제돼요',
      sceneAnchor: Alignment(0.62, 0.78),
      sceneScale: 1.2,
    ),
    GardenDecoration(
      id: 'hanok_lantern',
      label: '한옥 처마등',
      emoji: '🏮',
      isPremium: true,
      unlockHint: '정원 장식팩을 구매하면 사용할 수 있어요',
      sceneAnchor: Alignment(0.78, -0.62),
      sceneScale: 1.0,
    ),
  ];
}
