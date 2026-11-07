/// IDs are public identifiers. Both must belong to the same AdMob publisher.
/// Empty/invalid release settings disable requests rather than using test ads.
class GardenAdConfig {
  static const testAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const testBannerId = 'ca-app-pub-3940256099942544/9214589741';
  final String appId;
  final String bannerId;
  final bool testAds;
  const GardenAdConfig({
    required this.appId,
    required this.bannerId,
    this.testAds = false,
  });

  bool get enabled {
    if (testAds) return true;
    final app = RegExp(r'^ca-app-pub-(\d{16})~\d{10}$').firstMatch(appId);
    final banner = RegExp(r'^ca-app-pub-(\d{16})/\d{10}$').firstMatch(bannerId);
    return app != null &&
        banner != null &&
        app.group(1) == banner.group(1) &&
        app.group(1) != '3940256099942544';
  }

  String get requestUnit => testAds ? testBannerId : bannerId;
}
