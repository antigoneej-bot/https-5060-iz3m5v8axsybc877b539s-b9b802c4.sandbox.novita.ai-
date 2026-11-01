/// Contact confirmed by the operator. Other release details remain configurable.
class PrivacyConfig {
  static const operatorName = String.fromEnvironment('PRIVACY_OPERATOR', defaultValue: '박은정 (마음냥 정원)');
  static const contact = String.fromEnvironment(
    'PRIVACY_CONTACT', defaultValue: 'maeumnyang.help@gmail.com');
  static const policyUrl = String.fromEnvironment('PRIVACY_POLICY_URL',
    defaultValue: 'https://mindnyang-privacy.antigone-ej.chatgpt.site/privacy.html');
  static const deletionUrl = String.fromEnvironment('ACCOUNT_DELETION_URL',
    defaultValue: 'https://mindnyang-privacy.antigone-ej.chatgpt.site/delete-account.html');
  static String get operatorNotice =>
      '운영·문의: ${operatorName.isEmpty ? "출시 전 확정 예정" : operatorName}\n'
      '일반 문의·개인정보 문의·계정 삭제 요청: $contact';
}
