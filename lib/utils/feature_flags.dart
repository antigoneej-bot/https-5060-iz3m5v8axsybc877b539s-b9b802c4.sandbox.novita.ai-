/// 앱 전역 기능 플래그.
///
/// 새 편지 생성 시스템(8모듈 조합 엔진)을 즉시 롤백할 수 있도록 하나의
/// 스위치로 감싸둡니다. 문제가 생기면 [useNewLetterEngine]만 false로
/// 바꾸면 기존 방식(레거시 `generateCatReply`)으로 즉시 되돌아갑니다.
class FeatureFlags {
  FeatureFlags._();

  /// true: 새 8모듈 편지 조합 엔진(LetterComposerEngine) 사용
  /// false: 레거시 4조각 조합(opener+comfortMessage+guidance+closer) 사용
  // Legacy composer only. Active v5 entry point is reply_text_builder.dart.
  static const bool useNewLetterEngine = true;

  /// ⚠️ 디버그 전용: true로 켜면 "다음날 오전 6시" 대기 없이 편지를 보낸
  /// 즉시 답장을 열어볼 수 있습니다. 새 편지 생성 엔진 결과를 빠르게
  /// 확인하기 위한 임시 스위치이며, 확인이 끝나면 반드시 false로 되돌려야
  /// 합니다(정식 배포 시에는 항상 false).
  static const bool debugInstantReply = true;

  /// true: 편지 몇몇 모듈(인사/고양이감정/마무리)에 태그 기반 이모지를
  /// 자동으로 붙입니다(문장 원본은 그대로 두고 조합 단계에서만 덧붙임).
  /// false: 순수 텍스트만 사용(기존 방식).
  static const bool useLetterEmoji = true;
}
