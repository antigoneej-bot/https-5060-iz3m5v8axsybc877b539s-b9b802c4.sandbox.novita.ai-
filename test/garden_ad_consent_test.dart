// SDK's codec is used only to replace the native transport in these tests.
// ignore_for_file: implementation_imports
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/mongi/services/consent_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_mobile_ads/src/ump/user_messaging_codec.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final channel = MethodChannel(
    'plugins.flutter.io/google_mobile_ads/ump',
    StandardMethodCodec(UserMessagingCodec()),
  );
  final calls = <String>[];
  Completer<void>? hold;
  bool failForm = false;
  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    ConsentService.instance.resetSessionForTest();
    calls.clear();
    hold = null;
    failForm = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          switch (call.method) {
            case 'ConsentInformation#requestConsentInfoUpdate':
              await hold?.future;
              return null;
            case 'ConsentInformation#canRequestAds':
              return true;
            case 'ConsentInformation#getPrivacyOptionsRequirementStatus':
              return 1;
            case 'UserMessagingPlatform#loadAndShowConsentFormIfRequired':
            case 'UserMessagingPlatform#showPrivacyOptionsForm':
              return failForm
                  ? FormError(errorCode: 3, message: 'offline')
                  : null;
          }
          throw StateError('Unexpected SDK call ${call.method}');
        });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    ConsentService.instance.resetSessionForTest();
    debugDefaultTargetPlatformOverride = null;
  });
  test(
    'launch checks required forms even when prior consent permits ads',
    () async {
      expect(await ConsentInformation.instance.canRequestAds(), isTrue);
      await ConsentService.instance.requestConsentAndLoad(onDone: () {});
      expect(
        calls,
        contains('UserMessagingPlatform#loadAndShowConsentFormIfRequired'),
      );
      await ConsentService.instance.requestConsentAndLoad(onDone: () {});
      expect(
        calls
            .where((c) => c == 'ConsentInformation#requestConsentInfoUpdate')
            .length,
        1,
      );
    },
  );
  test(
    'simultaneous requests share one update and complete both callers',
    () async {
      hold = Completer<void>();
      var completed = 0;
      final a = ConsentService.instance.requestConsentAndLoad(
        onDone: () => completed++,
      );
      final b = ConsentService.instance.requestConsentAndLoad(
        onDone: () => completed++,
      );
      hold!.complete();
      await Future.wait([a, b]);
      expect(completed, 2);
      expect(
        calls
            .where((c) => c == 'ConsentInformation#requestConsentInfoUpdate')
            .length,
        1,
      );
    },
  );
  test(
    'form failure can retry and privacy options report failures honestly',
    () async {
      failForm = true;
      await ConsentService.instance.requestConsentAndLoad(onDone: () {});
      failForm = false;
      await ConsentService.instance.requestConsentAndLoad(onDone: () {});
      expect(
        calls
            .where((c) => c == 'ConsentInformation#requestConsentInfoUpdate')
            .length,
        2,
      );
      expect(
        await ConsentService.instance.showPrivacyOptionsFormIfRequired(),
        isTrue,
      );
      failForm = true;
      expect(
        await ConsentService.instance.showPrivacyOptionsFormIfRequired(),
        isFalse,
      );
      expect(ConsentService.instance.privacyOptionsOpen, isFalse);
    },
  );
  test('late consent response cannot interrupt a private page', () async {
    hold = Completer<void>();
    var home = true;
    final pending = ConsentService.instance.requestConsentAndLoad(
      onDone: () {},
      canShowForm: () => home,
    );
    home = false;
    hold!.complete();
    await pending;
    expect(
      calls,
      isNot(contains('UserMessagingPlatform#loadAndShowConsentFormIfRequired')),
    );
    home = true;
    await ConsentService.instance.requestConsentAndLoad(
      onDone: () {},
      canShowForm: () => home,
    );
    expect(
      calls,
      contains('UserMessagingPlatform#loadAndShowConsentFormIfRequired'),
    );
  });
}
