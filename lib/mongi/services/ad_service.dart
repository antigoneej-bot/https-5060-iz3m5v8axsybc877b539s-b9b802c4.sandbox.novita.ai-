import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb, debugPrint;
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'consent_service.dart';

/// ⚠️ Google 공식 "테스트용" 광고 단위 ID들.
/// 실제 배포 전에는 반드시 사용자 본인의 AdMob 계정에서 만든 실제 광고 단위 ID로
/// 모두 교체해야 한다 (그리고 android/app/src/main/AndroidManifest.xml의
/// com.google.android.gms.ads.APPLICATION_ID도 실제 App ID로 함께 교체해야 한다).
/// 이 테스트 ID들을 그대로 배포해도 앱은 동작하지만, 항상 "테스트 광고"만 노출되고
/// 실제 수익은 발생하지 않는다.
///
/// 교체가 필요한 지점 3곳:
/// 1) 이 파일의 _kRewardedAdUnitIdAndroid / _kBannerAdUnitIdAndroid /
///    _kInterstitialAdUnitIdAndroid
/// 2) android/app/src/main/AndroidManifest.xml의 APPLICATION_ID 메타데이터
const String _kRewardedAdUnitIdAndroid =
    'ca-app-pub-3940256099942544/5224354917';

/// 홈 화면 하단에 상시 노출되는 배너 광고 단위 ID (테스트 ID).
const String _kBannerAdUnitIdAndroid = 'ca-app-pub-3940256099942544/6300978111';

/// 스테이지를 몇 판 클리어할 때마다 노출되는 전면 광고 단위 ID (테스트 ID).
const String _kInterstitialAdUnitIdAndroid =
    'ca-app-pub-3940256099942544/1033173712';

/// 앱 전체 광고(리워드/배너/전면)를 관리하는 서비스.
///
/// - Android: 실제 AdMob 광고를 미리 로드해두고, 필요할 때 즉시 보여준다.
///   (미리 로드해두지 않으면 보여줘야 할 순간에 몇 초씩 로딩 지연이 생겨 흐름이
///   끊기므로, 화면 진입 시점에 한 번 preload해둔다.)
/// - Web(kIsWeb): google_mobile_ads가 Flutter Web을 지원하지 않으므로, 실제 광고
///   대신 "광고 시청 중..." 느낌의 짧은 시뮬레이션(리워드) 또는 아예 표시하지
///   않음(배너/전면)으로 대체한다. 이 덕분에 웹 프리뷰에서도 핵심 흐름은 그대로
///   시연/테스트할 수 있다.
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  bool get configured => false; // No live AdMob configuration in the unified app.

  RewardedAd? _rewardedAd;
  bool _isLoading = false;
  bool _sdkInitialized = false;
  Completer<void>? _initInFlight;

  // ── 전면 광고 (스테이지 클리어 후, 빈도 제한) ─────────────────────────
  InterstitialAd? _interstitialAd;
  bool _interstitialLoading = false;
  int _stageClearCount = 0;

  /// 전면 광고를 몇 판마다 한 번씩 보여줄지. 힐링 컨셉을 해치지 않도록
  /// 매판 보여주지 않고, 흐름을 크게 끊지 않을 만큼의 간격을 둔다.
  static const int interstitialEveryNStages = 3;

  /// 앱 시작 시(또는 게임 화면 진입 시) 한 번 호출해서 SDK를 초기화하고 광고를
  /// 미리 로드해둔다. 웹에서는 완전히 no-op.
  ///
  /// ⚠️ EEA(유럽경제지역)·영국 등에서는 개인화 광고를 요청하기 전에 UMP
  /// 동의 절차를 먼저 마쳐야 한다(Google Play 정책 요구사항). 이 메서드는
  /// 내부적으로 [ConsentService.requestConsentAndLoad]가 끝난 뒤에만 실제
  /// MobileAds SDK를 초기화하도록 순서를 보장한다 - 이 함수를 여러 번
  /// 호출해도 안전하다(이미 초기화됐으면 즉시 preload만 다시 시도).
  Future<void> init() async {
    if (kIsWeb || !configured) return;
    if (_sdkInitialized) {
      _preload();
      _preloadInterstitial();
      return;
    }
    final inFlight = _initInFlight;
    if (inFlight != null) {
      // 다른 화면이 이미 초기화를 진행 중 - 같은 결과를 함께 기다린다.
      await inFlight.future;
      return;
    }
    final completer = Completer<void>();
    _initInFlight = completer;

    final consentDone = Completer<void>();
    await ConsentService.instance.requestConsentAndLoad(
      onDone: () {
        if (!consentDone.isCompleted) consentDone.complete();
      },
    );
    await consentDone.future;

    try {
      await MobileAds.instance.initialize();
      _sdkInitialized = true;
      _preload();
      _preloadInterstitial();
    } catch (e) {
      if (kDebugMode) debugPrint('AdService init failed: $e');
    } finally {
      _initInFlight = null;
      if (!completer.isCompleted) completer.complete();
    }
  }

  void _preload() {
    if (!configured || kIsWeb || _isLoading || _rewardedAd != null) return;
    _isLoading = true;
    RewardedAd.load(
      adUnitId: _kRewardedAdUnitIdAndroid,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isLoading = false;
        },
        onAdFailedToLoad: (error) {
          if (kDebugMode) debugPrint('RewardedAd load failed: $error');
          _rewardedAd = null;
          _isLoading = false;
        },
      ),
    );
  }

  /// 광고가 지금 당장 보여줄 준비가 되어 있는지 (Android에서만 의미 있음,
  /// 웹에서는 시뮬레이션이 항상 가능하므로 true를 반환한다).
  bool get isReady => configured && !kIsWeb && _rewardedAd != null;

  /// 리워드 광고를 보여주고, 사용자가 끝까지 시청해 보상을 받았는지 여부를
  /// [onResult]로 알려준다. 광고가 아직 로딩 중이거나 실패했다면 즉시
  /// false로 콜백된다(부활 제안 UI에서 "지금은 광고를 볼 수 없어요"로 처리).
  ///
  /// [onAdStarted]는 광고 표시가 실제로 시작되는 순간(웹은 시뮬레이션 시작
  /// 순간) 호출된다 - 호출부에서 로딩 인디케이터를 보여주는 데 쓸 수 있다.
  Future<void> showRewarded({
    required void Function(bool rewarded) onResult,
    void Function()? onAdStarted,
  }) async {
    if (!configured) { onResult(false); return; }
    if (kIsWeb) {
      // 웹 프리뷰: 실제 광고 SDK가 없으므로 "광고 시청 중..." 느낌의 짧은
      // 대기로 흐름을 시뮬레이션한다. 항상 보상을 지급한다(웹은 테스트 용도).
      onAdStarted?.call();
      await Future.delayed(const Duration(seconds: 3));
      onResult(true);
      return;
    }

    final ad = _rewardedAd;
    if (ad == null) {
      // 로딩이 안 되어 있으면(느린 네트워크 등) 보상 없이 즉시 알린다.
      onResult(false);
      _preload(); // 다음 기회를 위해 다시 시도.
      return;
    }

    _rewardedAd = null; // 한 번 쓰면 재사용하지 않고 즉시 다음 광고를 새로 로드.
    bool earnedReward = false;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) => onAdStarted?.call(),
      onAdDismissedFullScreenContent: (adRef) {
        adRef.dispose();
        onResult(earnedReward);
        _preload(); // 다음 부활 기회를 위해 미리 다시 로드.
      },
      onAdFailedToShowFullScreenContent: (adRef, error) {
        if (kDebugMode) debugPrint('RewardedAd show failed: $error');
        adRef.dispose();
        onResult(false);
        _preload();
      },
    );

    try {
      await ad.show(
        onUserEarnedReward: (adRef, reward) {
          earnedReward = true;
        },
      );
    } catch (e) {
      if (kDebugMode) debugPrint('RewardedAd show threw: $e');
      onResult(false);
    }
  }

  // ── 전면 광고 (스테이지 클리어 후, 빈도 제한) ─────────────────────────

  void _preloadInterstitial() {
    if (!configured || kIsWeb || _interstitialLoading || _interstitialAd != null) return;
    _interstitialLoading = true;
    InterstitialAd.load(
      adUnitId: _kInterstitialAdUnitIdAndroid,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialLoading = false;
        },
        onAdFailedToLoad: (error) {
          if (kDebugMode) debugPrint('InterstitialAd load failed: $error');
          _interstitialAd = null;
          _interstitialLoading = false;
        },
      ),
    );
  }

  /// 스테이지(일반 모드) 한 판이 끝날 때마다 호출한다. 내부 카운터를 올리고,
  /// [interstitialEveryNStages]판마다 한 번씩만 전면 광고를 실제로 보여준다
  /// (힐링 게임 톤을 해치지 않도록 매판 노출하지 않음). 웹에서는 항상 no-op.
  Future<void> maybeShowInterstitialAfterStage() async {
    if (kIsWeb || !configured) return;
    _stageClearCount++;
    if (_stageClearCount % interstitialEveryNStages != 0) return;
    final ad = _interstitialAd;
    if (ad == null) {
      _preloadInterstitial(); // 다음 기회를 위해 로드 시도.
      return;
    }
    _interstitialAd = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (adRef) {
        adRef.dispose();
        _preloadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (adRef, error) {
        if (kDebugMode) debugPrint('InterstitialAd show failed: $error');
        adRef.dispose();
        _preloadInterstitial();
      },
    );
    try {
      await ad.show();
    } catch (e) {
      if (kDebugMode) debugPrint('InterstitialAd show threw: $e');
    }
  }

  // ── 배너 광고 (홈 화면 하단 상시 노출) ─────────────────────────

  /// 홈 화면 등에서 상시 노출할 배너 광고를 새로 하나 만들어 로드한다.
  /// 웹에서는 null을 반환한다(호출부에서 배너 영역 자체를 렌더링하지 않음).
  BannerAd? createBannerAd({required void Function() onLoaded}) {
    if (kIsWeb || !configured) return null;
    final banner = BannerAd(
      adUnitId: _kBannerAdUnitIdAndroid,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => onLoaded(),
        onAdFailedToLoad: (ad, error) {
          if (kDebugMode) debugPrint('BannerAd load failed: $error');
          ad.dispose();
        },
      ),
    );
    banner.load();
    return banner;
  }

  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }
}
