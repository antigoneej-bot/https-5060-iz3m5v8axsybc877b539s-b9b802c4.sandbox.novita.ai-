import 'package:flutter/material.dart';

/// 스테이지 클리어 후 "마음을 심기로" 선택했을 때, 구체적으로 어떤 마음의
/// 씨앗을 심을지 고르는 항목. 씨앗마다 독립적으로 누적 횟수가 쌓이고,
/// 그 누적 횟수에 따라 몽이의 작은 정원에서 눈으로 보이는 성장 단계가 달라진다.
///
/// 확장성: 새로운 씨앗 종류(예: '감사', '희망')를 추가하고 싶다면 이 파일의
/// [SeedType.all] 리스트에 항목 하나만 추가하면 된다 - 화면(ChoiceScreen,
/// GardenScreen) 쪽 코드는 이 리스트를 그대로 순회해서 그리므로 수정이 필요 없다.
/// 마찬가지로 나무 모양이 아닌 다른 성장 형태(꽃밭, 연못 등)도
/// [growthStages]에 원하는 이모지 시퀀스만 넣어주면 자유롭게 표현할 수 있다.
class SeedType {
  final String id;
  final String label; // 화면에 표시되는 한글 이름 (용서/사랑/평안 등)
  final String description; // 선택 화면에서 보여줄 짧은 설명
  final Color color;

  /// 성장 단계별로 보여줄 이모지 시퀀스. index 0 = 아직 심기 전(빈 흙),
  /// 마지막 index = 가장 만개/성장한 모습. 몇 단계든 자유롭게 늘릴 수 있다.
  final List<String> growthStages;

  /// "내 정원" 시각화 씬([GardenSceneView])에서 이 씨앗이 자라나는 화분의 위치.
  final Alignment sceneAnchor;

  const SeedType({
    required this.id,
    required this.label,
    required this.description,
    required this.color,
    required this.growthStages,
    this.sceneAnchor = Alignment.center,
  });

  /// 지금까지 심은(물을 준) 횟수 [count]에 해당하는 성장 단계 인덱스.
  /// 0,1-2,3-5,6-9,10+ 총 5단계 - growthStages가 5개 미만이면 자동으로 clamp된다.
  int tierForCount(int count) {
    int tier;
    if (count <= 0) {
      tier = 0;
    } else if (count <= 2) {
      tier = 1;
    } else if (count <= 5) {
      tier = 2;
    } else if (count <= 9) {
      tier = 3;
    } else {
      tier = 4;
    }
    return tier.clamp(0, growthStages.length - 1);
  }

  String emojiForCount(int count) => growthStages[tierForCount(count)];

  static SeedType byId(String id) {
    return all.firstWhere((s) => s.id == id, orElse: () => all.first);
  }

  static const List<SeedType> all = [
    SeedType(id: 'pine', label: '소나무', description: '사계절 푸른 나무',
      color: Color(0xFF408454), growthStages: ['🕳️', '🌱', '🌿', '🌲', '🌲✨'],
      sceneAnchor: Alignment(-0.7, -0.4)),
    SeedType(id: 'cherry', label: '벚꽃나무', description: '꽃이 피는 나무',
      color: Color(0xFFDB89A6), growthStages: ['🕳️', '🌱', '🌿', '🌸', '🌸✨'],
      sceneAnchor: Alignment(0.0, -0.35)),
    SeedType(id: 'maple', label: '단풍나무', description: '붉게 물드는 나무',
      color: Color(0xFFC66B46), growthStages: ['🕳️', '🌱', '🌿', '🍁', '🍁✨'],
      sceneAnchor: Alignment(0.7, -0.4)),
    SeedType(
      id: 'forgiveness',
      label: '용서',
      description: '마음에 맺힌 것을 놓아주는 씨앗',
      color: Color(0xFF7FB37A),
      growthStages: ['🕳️', '🌱', '🌿', '🌳', '🌳✨'],
      sceneAnchor: Alignment(-0.55, 0.05),
    ),
    SeedType(
      id: 'love',
      label: '사랑',
      description: '따뜻함을 나누는 씨앗',
      color: Color(0xFFFF8FAB),
      growthStages: ['🕳️', '🌱', '🌷', '💐', '💐✨'],
      sceneAnchor: Alignment(0.0, 0.15),
    ),
    SeedType(
      id: 'peace',
      label: '평안',
      description: '고요하고 잔잔한 마음의 씨앗',
      color: Color(0xFF6FA8DC),
      growthStages: ['🕳️', '🌱', '🪷', '🪷🌊', '🪷✨'],
      sceneAnchor: Alignment(0.55, 0.05),
    ),
  ];
}
