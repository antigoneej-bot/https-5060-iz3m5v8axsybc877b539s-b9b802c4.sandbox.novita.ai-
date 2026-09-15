/// 게임 플레이 도중(러너 게임) 같은 감정을 여러 번 연속으로 먹었을 때 컷인을
/// 몇 번마다 띄울지 판정하는 순수 로직 모음.
///
/// 이전에는 이 클래스가 FloatingLabel/카드 문구(콤보 서사, 조기종료 후크 등)의
/// 하드코딩된 한국어 텍스트도 함께 갖고 있었지만, 전부 [AppLocalizations] 기반
/// l10n 헬퍼(emotion_l10n.dart의 gameEatenLineText/gameReceivedLineText,
/// choice_narrative_l10n.dart의 comboNarrativeText/earlyStopHookText,
/// runner_game.dart의 l10n.game*Label 직접 호출)로 완전히 이전되어 이제
/// 아무도 호출하지 않는 죽은 코드였으므로 제거했다. [shouldTriggerCutIn]/
/// [cutInStreakInterval]만 실제로 여전히 쓰이는 순수 판정 로직이라 남겨둔다.
class GameNarrativeService {
  const GameNarrativeService._();

  /// 최소 몇 번 연속으로 먹어야 게임 플레이 중 컷인이 뜨는지, 그리고 그
  /// 이후 몇 번마다 반복되는지(너무 잦으면 플레이를 방해하므로).
  static const int cutInStreakInterval = 3;

  static bool shouldTriggerCutIn(int streak) =>
      streak >= cutInStreakInterval && streak % cutInStreakInterval == 0;
}
