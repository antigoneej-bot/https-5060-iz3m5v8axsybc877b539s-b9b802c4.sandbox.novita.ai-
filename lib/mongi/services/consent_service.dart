import 'dart:async';

import 'package:flutter/foundation.dart'
    show kDebugMode, kIsWeb, debugPrint, ValueNotifier;
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Google UMP(User Messaging Platform) 동의 관리 서비스.
///
/// EEA(유럽경제지역)·영국 등 일부 지역 사용자에게는 맞춤 광고를 보여주기
/// 전에 개인정보 처리 동의를 반드시 먼저 물어야 한다(Google Play 정책 +
/// GDPR 요구사항). 이 서비스는:
/// 1) 앱 시작 시 [requestConsentAndLoad]를 호출해 필요한 경우에만 동의
///    폼을 자동으로 보여준다(비대상 지역 사용자에게는 아무 것도 뜨지 않음).
/// 2) 동의 절차가 끝난 뒤에야 [AdService.init]으로 광고 SDK를 초기화하도록
///    순서를 보장한다(동의 전에 개인화 광고를 요청하면 정책 위반).
/// 3) 설정 화면에서 사용자가 언제든 "광고 개인정보 선택"을 다시 열어볼 수
///    있도록 [showPrivacyOptionsFormIfRequired]를 제공한다.
///
/// 웹(kIsWeb)에서는 google_mobile_ads 자체가 동작하지 않으므로 전부 no-op.
class ConsentService {
  ConsentService._();
  final changes = ValueNotifier<int>(0);
  static final ConsentService instance = ConsentService._();

  /// 진행 중인 동의 절차가 있으면 그 결과를 공유한다 - 여러 화면
  /// (emotion_input_screen, runner_game_screen, endless_mode_screen 등)이
  /// 거의 동시에 [AdService.init]을 호출해도, 두 번째 이후 호출은 새로
  /// 요청을 만들지 않고 이 Completer가 끝나는 시점을 함께 기다린다.
  /// (참고: 이 필드가 없으면 두 번째 호출이 아무 콜백도 받지 못한 채
  /// 영원히 멈추는 버그가 생긴다.)
  Completer<void>? _pending;

  /// 앱 시작 시 한 번 호출한다. 동의 정보를 갱신하고, 필요한 경우(EEA 등)
  /// 자동으로 동의 폼을 띄운 뒤, 이 과정이 모두 끝나면 콜백을 호출한다.
  /// 동의가 필요 없는 지역이면 즉시 콜백이 호출된다.
  ///
  /// 이 콜백이 끝난 뒤에 [AdService.init]을 호출해야 개인화 광고 요청이
  /// 동의 이전에 나가지 않는다.
  Future<void> requestConsentAndLoad({required void Function() onDone}) async {
    if (kIsWeb) {
      onDone();
      return;
    }

    final existing = _pending;
    if (existing != null) {
      // 이미 다른 화면이 요청 중 - 그 결과를 함께 기다렸다가 알려준다.
      await existing.future;
      onDone();
      return;
    }

    final completer = Completer<void>();
    _pending = completer;

    void finish() {
      _pending = null;
      if (!completer.isCompleted) completer.complete();
      onDone();
    }

    final params = ConsentRequestParameters();
    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        try {
          final canRequest = await ConsentInformation.instance.canRequestAds();
          if (!canRequest) {
            // 아직 필요한 동의를 받지 못한 상태 - 폼을 로드해 보여준다.
            await ConsentForm.loadAndShowConsentFormIfRequired((error) {
              if (error != null && kDebugMode) {
                debugPrint('UMP consent form error: ${error.message}');
              }
              finish();
            });
          } else {
            finish();
          }
        } catch (e) {
          if (kDebugMode) debugPrint('UMP canRequestAds failed: $e');
          finish();
        }
      },
      (error) {
        // 동의 정보 갱신 실패(네트워크 오류 등) - 광고 초기화는 계속 진행한다.
        if (kDebugMode) debugPrint('UMP consent update failed: $error');
        finish();
      },
    );
  }

  /// 설정 화면 등에서 사용자가 광고 개인정보 선택(동의 상태)을 다시 확인/
  /// 변경하고 싶을 때 호출한다. 대상 지역이 아니거나 아직 폼이 준비되지
  /// 않았으면 false를 반환한다(호출부에서 안내 메시지를 보여주면 된다).
  Future<bool> showPrivacyOptionsFormIfRequired() async {
    if (kIsWeb) return false;
    try {
      final status = await ConsentInformation.instance
          .getPrivacyOptionsRequirementStatus();
      if (status != PrivacyOptionsRequirementStatus.required) return false;
      var completed = false;
      await ConsentForm.showPrivacyOptionsForm((error) {
        if (error != null && kDebugMode) {
          debugPrint('UMP privacy options form error: ${error.message}');
        }
        completed = true;
        changes.value++;
      });
      return completed;
    } catch (e) {
      if (kDebugMode) debugPrint('UMP showPrivacyOptionsForm failed: $e');
      return false;
    }
  }
}
