import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../../services/cloud_service.dart';
import '../../services/garden_ad_routes.dart';
import '../services/ad_service.dart';
import '../services/banner_ads_client.dart';
import '../services/consent_service.dart';

/// Inline, adaptive home banner. It releases the native view when covered,
/// backgrounded, signed into another account, or made ad-free by a purchase.
class BannerAdSlot extends StatefulWidget {
  const BannerAdSlot({super.key, this.client});
  final BannerAdsClient? client;
  @override
  State<BannerAdSlot> createState() => _BannerAdSlotState();
}

class _BannerAdSlotState extends State<BannerAdSlot>
    with WidgetsBindingObserver, RouteAware {
  BannerAdsClient get _client => widget.client ?? AdService.instance;
  GardenBannerAd? _banner;
  ModalRoute<void>? _route;
  bool _loaded = false, _loading = false, _visible = true, _foreground = true;
  int _generation = 0, _width = 0;
  DateTime? _lastAttempt;
  Timer? _timer;
  StreamSubscription<User?>? _authChanges;
  bool get _active => mounted && _visible && _foreground && _width >= 200;

  @override
  void initState() {
    super.initState();
    _foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
    CloudService.entitlementChanges.addListener(_changed);
    ConsentService.instance.changes.addListener(_changed);
    if (_client.configured &&
        CloudService.enabled &&
        Firebase.apps.isNotEmpty) {
      _authChanges = FirebaseAuth.instance.authStateChanges().listen(
        (_) => _changed(),
      );
    }
    // Checks eligibility/retries a failed load, not manual ad refresh. The SDK
    // owns refresh of a successfully loaded visible banner.
    if (_client.configured) {
      _timer = Timer.periodic(const Duration(seconds: 60), (_) => _refresh());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of<void>(context);
    if (route != _route) {
      gardenAdRoutes.unsubscribe(this);
      _route = route;
      _visible = route?.isCurrent ?? true;
      if (route != null) gardenAdRoutes.subscribe(this, route);
    }
  }

  static void _disposeAd(GardenBannerAd? ad) {
    if (ad != null) unawaited(ad.dispose().catchError((_) {}));
  }

  void _clear({bool rebuild = true}) {
    _generation++;
    _loading = false;
    final previous = _banner;
    _banner = null;
    _loaded = false;
    if (rebuild && mounted) setState(() {});
    // Remove the AdWidget before releasing its platform view.
    if (rebuild && mounted && _foreground) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _disposeAd(previous));
    } else {
      _disposeAd(previous);
    }
  }

  void _changed() {
    _clear();
    _lastAttempt = null;
    unawaited(_refresh());
  }

  Future<void> _refresh() async {
    if (!_client.configured || !_active || _loading) return;
    _loading = true;
    final generation = _generation;
    GardenBannerAd? candidate;
    try {
      final allowed = await _client.allowed();
      if (!_active || generation != _generation) return;
      if (!allowed) {
        _clear();
        return;
      }
      if (_banner != null) return;
      if (_lastAttempt != null &&
          DateTime.now().difference(_lastAttempt!) <
              const Duration(seconds: 60))
        return;
      _lastAttempt = DateTime.now();
      candidate = await _client.createBannerAd(
        width: _width,
        placementActive: () => _active && generation == _generation,
        onLoaded: () async {
          try {
            final allowed = await _client.allowed();
            if (!mounted || candidate != _banner || generation != _generation)
              return;
            if (!allowed || !_active) {
              _clear();
              return;
            }
            setState(() => _loaded = true);
          } catch (_) {
            if (mounted && candidate == _banner) _clear();
          }
        },
        onFailed: () {
          if (mounted && candidate == _banner) _clear();
        },
      );
      if (!_active || generation != _generation) {
        _disposeAd(candidate);
        return;
      }
      if (candidate != null &&
          (candidate.width > _width || candidate.height <= 0)) {
        _disposeAd(candidate);
        return;
      }
      _banner = candidate;
      await candidate?.load();
    } catch (_) {
      if (mounted && generation == _generation) _clear();
    } finally {
      if (mounted && generation == _generation) _loading = false;
    }
  }

  @override
  void didPushNext() {
    _visible = false;
    _clear();
  }

  @override
  void didPopNext() {
    _visible = true;
    _changed();
  }

  @override
  void didPush() {
    _visible = true;
  }

  @override
  void didPop() {
    _visible = false;
    _clear();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) {
      _changed();
    } else {
      _clear();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _authChanges?.cancel();
    CloudService.entitlementChanges.removeListener(_changed);
    ConsentService.instance.changes.removeListener(_changed);
    gardenAdRoutes.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _clear(rebuild: false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_client.configured) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth.floor()
            : 0;
        if (_width != width) {
          _width = width;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _changed();
          });
        }
        final ad = _banner;
        if (!_loaded || ad == null || ad.width > width || !_active)
          return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '광고',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: ad.width.toDouble(),
                height: ad.height.toDouble(),
                child: ad.buildView(),
              ),
            ],
          ),
        );
      },
    );
  }
}
