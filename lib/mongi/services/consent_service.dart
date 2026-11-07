import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// UMP controls regional privacy choices. Analytics consent is independent.
class ConsentService {
  ConsentService._();
  static final instance = ConsentService._();
  final changes = ValueNotifier<int>(0);
  Completer<void>? _pending;
  bool _updated = false;
  bool privacyOptionsOpen = false;
  bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> requestConsentAndLoad({
    required void Function() onDone,
    bool Function()? canShowForm,
  }) async {
    if (!_supported || _updated) {
      onDone();
      return;
    }
    final pending = _pending;
    if (pending != null) {
      await pending.future;
      onDone();
      return;
    }
    final completer = Completer<void>();
    _pending = completer;
    void finish() {
      if (completer.isCompleted) return;
      _pending = null;
      completer.complete();
    }

    try {
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () async {
          try {
            // A delayed response must not open a form over a private activity.
            if (canShowForm != null && !canShowForm()) {
              finish();
              return;
            }
            // Check required forms even when previous consent permits requests.
            await ConsentForm.loadAndShowConsentFormIfRequired((error) {
              _updated = error == null;
              finish();
            });
          } catch (_) {
            finish();
          }
        },
        (_) => finish(),
      );
      await completer.future;
    } catch (_) {
      finish();
    }
    onDone();
  }

  Future<bool> showPrivacyOptionsFormIfRequired() async {
    if (!_supported || privacyOptionsOpen) return false;
    privacyOptionsOpen = true;
    changes.value++;
    try {
      await requestConsentAndLoad(onDone: () {});
      final status = await ConsentInformation.instance
          .getPrivacyOptionsRequirementStatus();
      if (status != PrivacyOptionsRequirementStatus.required) return false;
      var succeeded = false;
      await ConsentForm.showPrivacyOptionsForm((error) {
        succeeded = error == null;
      });
      return succeeded;
    } catch (_) {
      return false;
    } finally {
      privacyOptionsOpen = false;
      changes.value++;
    }
  }

  @visibleForTesting
  void resetSessionForTest() {
    _updated = false;
    _pending = null;
    privacyOptionsOpen = false;
  }
}
