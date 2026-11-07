import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_app/mongi/services/banner_ads_client.dart';
import 'package:flutter_app/mongi/services/consent_service.dart';
import 'package:flutter_app/mongi/widgets/banner_ad_slot.dart';
import 'package:flutter_app/services/cloud_service.dart';
import 'package:flutter_app/services/garden_ad_routes.dart';
import 'package:flutter_test/flutter_test.dart';

class _Ad implements GardenBannerAd {
  @override
  final int width;
  @override
  int get height => 50;
  final VoidCallback loaded;
  final VoidCallback failed;
  bool disposed = false;
  int loads = 0;
  _Ad(this.width, this.loaded, this.failed);
  @override
  Widget buildView() => const Text('TEST BANNER');
  @override
  Future<void> load() async {
    loads++;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

class _Client implements BannerAdsClient {
  @override
  bool configured = true;
  bool eligible = true;
  bool failEligibility = false;
  final List<_Ad> ads = [];
  Completer<void>? holdCreation;
  @override
  Future<bool> allowed() async {
    if (failEligibility) throw StateError('status offline');
    return eligible;
  }

  @override
  Future<GardenBannerAd?> createBannerAd({
    required int width,
    required VoidCallback onLoaded,
    required VoidCallback onFailed,
    required bool Function() placementActive,
  }) async {
    final ad = _Ad(width, onLoaded, onFailed);
    ads.add(ad);
    await holdCreation?.future;
    return ad;
  }
}

Future<void> _show(
  WidgetTester t,
  _Client client, {
  double width = 360,
  GlobalKey<NavigatorState>? navigator,
}) async {
  await t.binding.setSurfaceSize(Size(width, 800));
  await t.pumpWidget(
    MaterialApp(
      navigatorKey: navigator,
      navigatorObservers: [gardenAdRoutes],
      home: Scaffold(
        body: MediaQuery(
          data: MediaQueryData(
            size: Size(width, 800),
            textScaler: const TextScaler.linear(1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Text('HOME CONTENT'),
                BannerAdSlot(client: client),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await t.pump();
  await t.pump();
}

Future<void> flush(WidgetTester t) async {
  await t.pump();
  await t.pump();
}

void main() {
  tearDown(() {
    ConsentService.instance.privacyOptionsOpen = false;
  });
  testWidgets('360/390 px adaptive banner stays inside home padding', (
    t,
  ) async {
    addTearDown(() => t.binding.setSurfaceSize(null));
    for (final width in [360.0, 390.0]) {
      final c = _Client();
      await _show(t, c, width: width);
      expect(c.ads.single.width, width - 48);
      c.ads.single.loaded();
      await flush(t);
      expect(find.text('TEST BANNER'), findsOneWidget);
      expect(find.text('광고'), findsOneWidget);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      await flush(t);
      expect(c.ads.single.disposed, isTrue);
    }
  });
  testWidgets('premium or unknown status never requests an ad', (t) async {
    addTearDown(() => t.binding.setSurfaceSize(null));
    final c = _Client()..eligible = false;
    await _show(t, c);
    expect(c.ads, isEmpty);
    c.eligible = true;
    c.failEligibility = true;
    CloudService.entitlementChanges.value++;
    await flush(t);
    expect(c.ads, isEmpty);
    expect(find.text('HOME CONTENT'), findsOneWidget);
    expect(find.text('광고'), findsNothing);
  });
  testWidgets('purchase while loading discards the late ad', (t) async {
    addTearDown(() => t.binding.setSurfaceSize(null));
    final c = _Client();
    await _show(t, c);
    final ad = c.ads.single;
    c.eligible = false;
    CloudService.entitlementChanges.value++;
    ad.loaded();
    await flush(t);
    expect(ad.disposed, isTrue);
    expect(find.text('TEST BANNER'), findsNothing);
  });
  testWidgets('failed ad collapses and never blocks content', (t) async {
    addTearDown(() => t.binding.setSurfaceSize(null));
    final c = _Client();
    await _show(t, c);
    c.ads.single.failed();
    await flush(t);
    expect(c.ads.single.disposed, isTrue);
    expect(find.text('광고'), findsNothing);
    expect(find.text('HOME CONTENT'), findsOneWidget);
    await t.pump(const Duration(seconds: 1));
    expect(c.ads.length, 1);
  });
  testWidgets('covered route releases banner; returning rechecks eligibility', (
    t,
  ) async {
    addTearDown(() => t.binding.setSurfaceSize(null));
    final nav = GlobalKey<NavigatorState>();
    final c = _Client();
    await _show(t, c, navigator: nav);
    c.ads.single.loaded();
    await flush(t);
    unawaited(
      nav.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('PRIVATE LETTER')),
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(c.ads.first.disposed, isTrue);
    final count = c.ads.length;
    await t.pump(const Duration(seconds: 65));
    expect(c.ads.length, count);
    c.eligible = false;
    nav.currentState!.pop();
    await t.pumpAndSettle();
    expect(c.ads.length, count);
    expect(find.text('TEST BANNER'), findsNothing);
  });
  testWidgets('background and consent change remove displayed ads', (t) async {
    addTearDown(() => t.binding.setSurfaceSize(null));
    final c = _Client();
    await _show(t, c);
    c.ads.single.loaded();
    await flush(t);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await flush(t);
    expect(c.ads.first.disposed, isTrue);
    await t.pump(const Duration(seconds: 65));
    expect(c.ads.length, 1);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await flush(t);
    expect(c.ads.length, 2);
    c.ads.last.loaded();
    await flush(t);
    c.eligible = false;
    ConsentService.instance.changes.value++;
    await flush(t);
    expect(c.ads.last.disposed, isTrue);
    expect(find.text('TEST BANNER'), findsNothing);
  });
  testWidgets('late creation after unmount is disposed without loading', (
    t,
  ) async {
    addTearDown(() => t.binding.setSurfaceSize(null));
    final c = _Client()..holdCreation = Completer<void>();
    await _show(t, c);
    await t.pumpWidget(const SizedBox());
    c.holdCreation!.complete();
    await flush(t);
    expect(c.ads.single.disposed, isTrue);
    expect(c.ads.single.loads, 0);
    expect(t.takeException(), isNull);
  });
}
