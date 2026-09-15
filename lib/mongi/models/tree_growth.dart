/// 점수(score) 누적에 따라 자라나는 "몽이의 성장나무" 모델.
///
/// [SeedType]이 "씨앗을 심은 횟수"로 자라는 것과는 별개로, 이 나무는
/// 스테이지를 완료할 때마다 쌓이는 누적 점수([GardenProvider.score])로 자란다.
///
/// 성장 순서: (아직 안 자람) -> 새싹 -> 나무 -> 꽃 -> 열매
/// 각 단계는 assets/mongi/images/tree_stage*.png 커스텀 일러스트로 표현한다.
class TreeGrowth {
  TreeGrowth._();

  /// 성장 단계별 이미지 경로 (index 0 = 새싹, 마지막 = 열매).
  static const List<String> stageAssets = [
    'assets/mongi/images/tree_stage1_sprout.png',
    'assets/mongi/images/tree_stage2_young.png',
    'assets/mongi/images/tree_stage3_bloom.png',
    'assets/mongi/images/tree_stage4_fruit.png',
  ];

  /// 각 단계의 한글 이름.
  static const List<String> stageLabels = ['새싹', '나무', '꽃', '열매'];

  /// 각 단계에 도달하기 위해 필요한 최소 누적 점수.
  /// index i에 도달하려면 score >= stageThresholds[i] 이어야 한다.
  ///
  /// 스테이지 완료 1회당 평균 20~40점 정도를 얻는다는 기준으로, 새싹은
  /// 며칠 안에 금방 보여주고(초반 동기부여), 열매까지는 꾸준히 며칠~몇 주에
  /// 걸쳐 도달하도록 이전 대비 크게 상향했다(예전 값: [50, 150, 350, 700] -
  /// 너무 낮아 나무가 하루 이틀 만에 다 자라버려 장기 목표감이 없었음).
  static const List<int> stageThresholds = [200, 600, 1500, 3000];

  /// 각 단계에 처음 도달했을 때 지급하는 축하 보너스(빛의 정수). 단계가
  /// 오를수록 더 크게 지급해서, 뒤로 갈수록 "거의 다 왔다"는 손실회피 심리를
  /// 자극한다(처벌형이 아닌, 뒤로 갈수록 커지는 보상 차등형).
  static const List<int> stageMilestoneLightEssence = [15, 30, 60, 120];

  /// 지금 점수로 도달한 성장 단계 인덱스. 아직 첫 단계(새싹)에도 못 미치면 -1
  /// (=아직 씨앗도 심기 전, 흙만 있는 상태)을 반환한다.
  static int stageIndexForScore(int score) {
    for (int i = stageThresholds.length - 1; i >= 0; i--) {
      if (score >= stageThresholds[i]) return i;
    }
    return -1;
  }

  /// 지금 점수에 해당하는 나무 이미지 경로. 아직 자라기 전이면 null.
  static String? assetForScore(int score) {
    final idx = stageIndexForScore(score);
    return idx < 0 ? null : stageAssets[idx];
  }

  /// 지금 점수에 해당하는 단계 이름. 아직 자라기 전이면 '씨앗'.
  static String labelForScore(int score) {
    final idx = stageIndexForScore(score);
    return idx < 0 ? '씨앗' : stageLabels[idx];
  }

  /// 다음 성장 단계까지 남은 점수. 이미 마지막 단계(열매)라면 0.
  static int pointsToNextStage(int score) {
    final idx = stageIndexForScore(score);
    if (idx >= stageThresholds.length - 1) return 0;
    final nextThreshold = stageThresholds[idx + 1];
    return (nextThreshold - score).clamp(0, nextThreshold);
  }

  /// 가장 마지막(가장 자란) 단계 인덱스.
  static int get maxStageIndex => stageAssets.length - 1;
}
