/// "감정 몬스터 도감"의 레어도(진화) 시스템 - 순수 함수 모음.
///
/// 같은 감정을 여러 번 마주할수록(=정원에 그 감정의 꽃이 여러 번 심어질수록)
/// 몬스터가 조금씩 더 성숙한 형태로 "진화"한다. 새 이미지를 그리는 대신,
/// 기존 이모지/색상은 그대로 두고 "이름"과 카드 테두리 스타일만 바꿔서
/// 수집욕구를 자극한다 (MVP 원칙: 최소 자원으로 최대 효과).
///
/// 예: 화(anger) - 화르르(0~4번) → 잔불이(5~19번) → 온기(20번 이상)
///
/// 6번: 감정 마스터(50번) 이후에도 끝이 아니다 - 아무 예고 없이 100번째
/// 마주침에 딱 한 번 더 "초월(4단계)"한다. 다른 단계와 달리 도감 UI 어디에도
/// "100번 남았어요" 같은 카운트다운을 보여주지 않아([remainingToNextStage]가
/// 마스터 단계부터는 항상 null을 반환하는 기존 동작을 그대로 재사용), 정말로
/// 자주 찾아준 사람만 어느 날 문득 발견하게 되는 히든 마일스톤이다.
class EmotionEvolutionService {
  const EmotionEvolutionService._();

  /// 진화 기준 횟수: 5번째부터 1차 진화, 20번째부터 2차 진화.
  /// 50번은 "마스터(완전 진화)" 판정선으로, 이름은 2차 진화와 같지만
  /// 카드에 별도의 "마스터" 표식과 황금 프레임 추첨 자격이 주어진다.
  static const int firstEvolutionCount = 5;
  static const int secondEvolutionCount = 20;
  static const int masteredCount = 50;

  /// 6번: 히든 4단계("초월") 판정선. 의도적으로 도감 안내 문구
  /// ("5번·20번·50번")에는 이 숫자를 노출하지 않는다 - 예고 없이 조용히
  /// 채워지다가 우연히 다다르는 순간에만 발견되는 재미를 위해서다.
  static const int transcendedCount = 100;

  /// 지금까지 마주한 횟수로 진화 단계 인덱스(0/1/2/3)를 계산한다.
  static int stageIndexForCount(int count) {
    if (count >= transcendedCount) return 3;
    if (count >= secondEvolutionCount) return 2;
    if (count >= firstEvolutionCount) return 1;
    return 0;
  }

  /// 완전히 진화(마스터)했는지 여부 - 황금 프레임 추첨 자격 조건.
  static bool isMastered(int count) => count >= masteredCount;

  /// 6번: 히든 4단계("초월")에 도달했는지 여부.
  static bool isTranscended(int count) => count >= transcendedCount;

  /// 다음 진화까지 남은 횟수. 이미 2차 진화(마스터 이름)까지 도달했다면 null.
  ///
  /// 6번: 마스터(50번) 이후 히든 4단계(100번)가 하나 더 있지만, 이 함수는
  /// 의도적으로 여기서 멈춘다 - "몇 번 더 하면 되는지" 카운트다운을 보여주는
  /// 순간 더 이상 "히든"이 아니게 되기 때문이다.
  static int? remainingToNextStage(int count) {
    if (count < firstEvolutionCount) return firstEvolutionCount - count;
    if (count < secondEvolutionCount) return secondEvolutionCount - count;
    return null;
  }
}
