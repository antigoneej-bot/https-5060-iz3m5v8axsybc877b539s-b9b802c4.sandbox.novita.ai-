import '../l10n/app_language.dart';

/// Contact confirmed by the operator. Other release details remain configurable.
class PrivacyConfig {
  static const errorReportingNotice =
      "오류 보고 공유는 기본으로 꺼져 있으며 사용 통계 공유와 별도로 선택합니다. 기록 보관과 백업에서 켜면 Firebase Crashlytics에 오류 유형·호출 위치, 앱·운영체제·기기 및 설치 진단 정보와 제한된 연결 소요 시간을 보내 안정성 개선에 사용합니다. 앱은 편지·감정 원문, 선택한 감정 ID, 이메일·계정 식별자와 인증 정보를 보고서에 직접 첨부하지 않습니다. 사용 통계에도 동의하면 이용 이벤트가 오류 분석에 포함될 수 있습니다.\n\n언제든 오류 보고 공유를 끌 수 있습니다. 끄면 앱의 새 오류 전송을 중단하고 SDK 수집 중지와 미전송 보고서 삭제를 시도합니다. SDK 적용 실패는 안내하며 앱을 다시 실행하면 저장된 끄기 설정을 다시 적용합니다. 이미 전송된 보고서가 즉시 삭제된다는 의미는 아닙니다. 수집을 새로 켜기 전에는 미전송 보고서 정리를 먼저 시도하고 정리에 실패하면 켜지 않습니다. Google의 진단 처리·보관 및 국외 처리에 관한 문의는 운영자에게 요청할 수 있습니다.";
  static const operatorName = String.fromEnvironment(
    'PRIVACY_OPERATOR',
    defaultValue: '박은정 (마음냥 정원)',
  );
  static const contact = String.fromEnvironment(
    'PRIVACY_CONTACT',
    defaultValue: 'maeumnyang.help@gmail.com',
  );
  static const policyUrl = String.fromEnvironment(
    'PRIVACY_POLICY_URL',
    defaultValue:
        'https://mindnyang-privacy.antigone-ej.chatgpt.site/privacy.html',
  );
  static const deletionUrl = String.fromEnvironment(
    'ACCOUNT_DELETION_URL',
    defaultValue:
        'https://mindnyang-privacy.antigone-ej.chatgpt.site/delete-account.html',
  );
  static String get operatorNotice => tr(
    "운영·문의: {0}\n일반 문의·개인정보 문의·계정 삭제 요청: {1}",
    [operatorName.isEmpty ? tr("출시 전 확정 예정") : tr(operatorName), contact],
  );
}
