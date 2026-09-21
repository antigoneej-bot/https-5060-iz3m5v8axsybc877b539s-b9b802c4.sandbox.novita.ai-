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

  /// ⚠️ 테스트 전용: true로 켜면 "다음날 오전 6시" 대기 없이 편지를 보낸
  /// 즉시 답장을 열어볼 수 있습니다. 답장 파이프라인을 빠르게 확인하기
  /// 위한 임시 스위치이며, 정식 배포(APK/AAB 빌드) 전 반드시 false로
  /// 되돌려야 합니다.
  static const bool debugInstantReply = true;

  /// ⚠️ 테스트 전용: [debugInstantReply]가 true인 동안, 답장 도착 로컬
  /// 알림(고양이 답장 · 마음편지 답장)도 원래의 "다음날 오전 6시"가 아니라
  /// 편지를 보낸 지 이 시간(초) 뒤에 즉시 울리도록 당깁니다. 실기기에서
  /// 알림 배너/사운드 동작 자체를 빠르게 확인하기 위한 것이며, 정식 배포
  /// 전 [debugInstantReply]와 함께 반드시 되돌려야 합니다(그러면 이 값은
  /// 자동으로 무시됩니다).
  static const int debugInstantReplyNotificationDelaySeconds = 8;

  /// ⚠️ 테스트 전용: true면 실제 구독 여부와 관계없이 앱 전체가 항상
  /// "구독 중"인 것처럼 동작합니다(프리미엄 고양이, 명상 전체, 아이템,
  /// 광고 제거, 무제한 답장 등 모든 잠금 해제). 실제 결제 연동 여부와
  /// 무관하게 켜지므로, 정식 배포(APK/AAB 빌드) 전 반드시 false로
  /// 되돌려야 합니다. [SubscriptionService.isPremium] 에서 확인합니다.
  /// (단위 테스트가 무료 등급 로직을 검증할 수 있도록 const가 아닌
  /// static 변수로 두되, 기본값은 true입니다.)
  static bool debugUnlockAllPremium = true;

  /// true: 편지 몇몇 모듈(인사/고양이감정/마무리)에 태그 기반 이모지를
  /// 자동으로 붙입니다(문장 원본은 그대로 두고 조합 단계에서만 덧붙임).
  /// false: 순수 텍스트만 사용(기존 방식).
  static const bool useLetterEmoji = true;
}
