import 'package:flutter_app/mongi/services/ad_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const app = 'ca-app-pub-1234567890123456~1234567890';
  const banner = 'ca-app-pub-1234567890123456/1234567890';
  test('production requires both well-formed matching publisher IDs', () {
    expect(const GardenAdConfig(appId: app, bannerId: banner).enabled, isTrue);
    for (final c in [
      const GardenAdConfig(appId: '', bannerId: ''),
      const GardenAdConfig(appId: app, bannerId: ''),
      const GardenAdConfig(appId: '', bannerId: banner),
      const GardenAdConfig(appId: banner, bannerId: app),
      const GardenAdConfig(
        appId: app,
        bannerId: 'ca-app-pub-1111111111111111/1234567890',
      ),
      const GardenAdConfig(appId: '$app\n', bannerId: banner),
      const GardenAdConfig(
        appId: GardenAdConfig.testAppId,
        bannerId: GardenAdConfig.testBannerId,
      ),
    ]) {
      expect(c.enabled, isFalse);
    }
  });
  test('explicit test mode always uses the Google test unit', () {
    const config = GardenAdConfig(appId: app, bannerId: banner, testAds: true);
    expect(config.enabled, isTrue);
    expect(config.requestUnit, GardenAdConfig.testBannerId);
  });
}
