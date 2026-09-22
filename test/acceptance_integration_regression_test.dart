import 'package:flutter_test/flutter_test.dart';
import '../tool/check_acceptance_integration.dart' as checks;

void main() {
  test('acceptance feedback, listening refusal and finite-pool regression', () {
    checks.main();
  });
}
