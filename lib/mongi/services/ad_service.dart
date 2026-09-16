import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../services/access_policy.dart';
import '../../services/subscription_service.dart';
import 'consent_service.dart';

/// Free users: banner on Mongi entry. Premium/trial: no ads.
/// Full-screen and rewarded ads remain disabled.
class AdService {
  AdService._();
  static final instance = AdService._();
  static const interstitialEveryNStages = 3;
  static const _unit = String.fromEnvironment('ADMOB_ANDROID_BANNER_ID');
  static const _testUnit = 'ca-app-pub-3940256099942544/6300978111';
  Future<void>? _initializing;
  bool _ready = false;
  bool get configured =>
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android &&
      (!kReleaseMode ||
          (_unit.startsWith('ca-app-pub-') &&
              _unit.contains('/') &&
              !_unit.contains('3940256099942544')));
  bool get isReady => _ready;

  Future<bool> allowed() async {
    try {
      return configured &&
          AccessPolicy.adsAllowed(await SubscriptionService().isPremium());
    } catch (_) {
      return false; // Unknown entitlement must not show ads to a subscriber.
    }
  }

  Future<void> init() async {
    if (!await allowed()) return;
    if (_ready) return;
    final pending = _initializing;
    if (pending != null) return pending;
    final future = _initialize();
    _initializing = future;
    try {
      await future;
    } finally {
      _initializing = null;
    }
  }

  Future<void> _initialize() async {
    try {
      await ConsentService.instance.requestConsentAndLoad(onDone: () {});
      if (!await allowed() ||
          !await ConsentInformation.instance.canRequestAds())
        return;
      await MobileAds.instance.initialize();
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  Future<BannerAd?> createBannerAd({
    required void Function() onLoaded,
    required void Function() onFailed,
  }) async {
    await init();
    if (!_ready || !await allowed()) return null;
    try {
      if (!await ConsentInformation.instance.canRequestAds()) return null;
      if (!await allowed()) return null;
      return BannerAd(
        adUnitId: kReleaseMode ? _unit : _testUnit,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (_) => onLoaded(),
          onAdFailedToLoad: (_, error) => onFailed(),
        ),
      );
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
