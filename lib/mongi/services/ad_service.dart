import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../services/access_policy.dart';
import '../../services/cloud_service.dart';
import '../../services/subscription_service.dart';
import 'ad_config.dart';
import 'banner_ads_client.dart';
import 'consent_service.dart';

/// Home banner only. No private content or emotion/identity targeting fields.
class AdService implements BannerAdsClient {
  AdService._();
  static final instance = AdService._();
  static const interstitialEveryNStages =
      3; // Legacy breathing-widget reference.
  static const config = GardenAdConfig(
    appId: String.fromEnvironment('ADMOB_ANDROID_APP_ID'),
    bannerId: String.fromEnvironment('ADMOB_ANDROID_BANNER_ID'),
    testAds: bool.fromEnvironment('ADMOB_TEST_ADS'),
  );
  Future<void>? _initializing;
  bool _ready = false;

  @override
  bool get configured =>
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android &&
      config.enabled;
  bool get isReady => _ready;

  @override
  Future<bool> allowed() async {
    try {
      if (!configured || ConsentService.instance.privacyOptionsOpen)
        return false;
      if (await SubscriptionService().isPremium()) return false;
      // Missing/stale account cache is NOT proof of a free subscription.
      if (CloudService.enabled) {
        return AccessPolicy.adsAllowed(
          await CloudService.cachedAdFreeEntitlement(),
        );
      }
      return !kReleaseMode;
    } catch (_) {
      return false;
    }
  }

  Future<void> init({required bool Function() placementActive}) async {
    if (!await allowed() || _ready) return;
    final pending = _initializing;
    if (pending != null) return pending;
    final future = _initialize(placementActive);
    _initializing = future;
    try {
      await future;
    } finally {
      _initializing = null;
    }
  }

  Future<void> _initialize(bool Function() placementActive) async {
    try {
      await ConsentService.instance.requestConsentAndLoad(
        onDone: () {},
        canShowForm: placementActive,
      );
      if (!placementActive() ||
          !await allowed() ||
          !await ConsentInformation.instance.canRequestAds())
        return;
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(maxAdContentRating: MaxAdContentRating.pg),
      );
      await MobileAds.instance.setAppMuted(true);
      await MobileAds.instance.initialize();
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  @override
  Future<GardenBannerAd?> createBannerAd({
    required int width,
    required void Function() onLoaded,
    required void Function() onFailed,
    required bool Function() placementActive,
  }) async {
    await init(placementActive: placementActive);
    if (!_ready || !placementActive() || !await allowed() || width < 200)
      return null;
    try {
      if (!await ConsentInformation.instance.canRequestAds()) return null;
      final size =
          await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
      if (size == null ||
          size.width > width ||
          !placementActive() ||
          !await allowed())
        return null;
      final banner = BannerAd(
        adUnitId: kReleaseMode
            ? config.requestUnit
            : GardenAdConfig.testBannerId,
        size: size,
        request: const AdRequest(nonPersonalizedAds: true),
        listener: BannerAdListener(
          onAdLoaded: (_) => onLoaded(),
          onAdFailedToLoad: (_, error) => onFailed(),
        ),
      );
      return _GoogleBanner(banner);
    } catch (_) {
      return null;
    }
  }

  Future<void> showRewarded({
    required void Function(bool rewarded) onResult,
    void Function()? onAdStarted,
  }) async => onResult(false);
  Future<void> maybeShowInterstitialAfterStage() async {}
  void dispose() {
    _ready = false;
  }
}

class _GoogleBanner implements GardenBannerAd {
  final BannerAd ad;
  _GoogleBanner(this.ad);
  @override
  int get width => ad.size.width;
  @override
  int get height => ad.size.height;
  @override
  Widget buildView() => AdWidget(ad: ad);
  @override
  Future<void> load() => ad.load();
  @override
  Future<void> dispose() => ad.dispose();
}
