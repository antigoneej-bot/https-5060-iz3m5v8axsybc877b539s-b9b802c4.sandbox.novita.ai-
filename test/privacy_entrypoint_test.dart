import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/screens/privacy_policy_screen.dart' as current;
import 'package:flutter_app/mongi/screens/privacy_policy_screen.dart' as legacy;
import 'package:flutter_app/services/privacy_config.dart';
void main() {
  test('both privacy entry points resolve to current policy, not local-only copy', () {
    expect(const legacy.PrivacyPolicyScreen(), isA<current.PrivacyPolicyScreen>());
  });
  test('default contact uses the operator-confirmed name and support email', () {
    expect(PrivacyConfig.operatorName, '박은정 (마음냥 정원)');
    expect(PrivacyConfig.contact, 'maeumnyang.help@gmail.com');
    expect(PrivacyConfig.operatorNotice, contains(PrivacyConfig.operatorName));
    expect(PrivacyConfig.operatorNotice, contains(PrivacyConfig.contact));
  });
  test('published policy and deletion URLs are available by default', () {
    expect(PrivacyConfig.policyUrl, 'https://mindnyang-privacy.antigone-ej.chatgpt.site/privacy.html');
    expect(PrivacyConfig.deletionUrl, 'https://mindnyang-privacy.antigone-ej.chatgpt.site/delete-account.html');
  });
}
