import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../services/cloud_service.dart';
import '../services/ad_service.dart';
import '../services/consent_service.dart';

class BannerAdSlot extends StatefulWidget {
  const BannerAdSlot({super.key});
  @override
  State<BannerAdSlot> createState() => _BannerAdSlotState();
}

class _BannerAdSlotState extends State<BannerAdSlot>
    with WidgetsBindingObserver {
  BannerAd? _banner;
  bool _loaded = false;
  int _generation = 0;
  Timer? _timer;
  StreamSubscription<User?>? _authChanges;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    CloudService.entitlementChanges.addListener(_changed);
    ConsentService.instance.changes.addListener(_changed);
    if (CloudService.enabled) {
      _authChanges = FirebaseAuth.instance.authStateChanges().listen(
        (_) => _changed(),
      );
    }
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _refresh());
  }

  void _clear() {
    final previous = _banner;
    _banner = null;
    _loaded = false;
    if (mounted) setState(() {});
    // Remove AdWidget before releasing its native view.
    WidgetsBinding.instance.addPostFrameCallback((_) => previous?.dispose());
  }

  void _changed() {
    _generation++;
    _clear();
    _refresh();
  }

  Future<void> _refresh() async {
    final generation = ++_generation;
    final allowed = await AdService.instance.allowed();
    if (!mounted || generation != _generation) return;
    if (!allowed) {
      _clear();
      return;
    }
    if (_banner != null) return;
    BannerAd? candidate;
    candidate = await AdService.instance.createBannerAd(
      onLoaded: () async {
        final allowed = await AdService.instance.allowed();
        if (!mounted || candidate != _banner) return;
        if (!allowed) {
          _clear();
          return;
        }
        setState(() => _loaded = true);
      },
      onFailed: () {
        if (mounted && candidate == _banner) _clear();
      },
    );
    if (!mounted || generation != _generation) {
      candidate?.dispose();
      return;
    }
    _banner = candidate;
    try {
      await candidate?.load();
    } catch (_) {
      if (mounted && candidate == _banner) _clear();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _changed();
  }

  @override
  void dispose() {
    _generation++;
    _timer?.cancel();
    _authChanges?.cancel();
    CloudService.entitlementChanges.removeListener(_changed);
    ConsentService.instance.changes.removeListener(_changed);
    WidgetsBinding.instance.removeObserver(this);
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _banner;
    if (!_loaded || ad == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('광고', style: TextStyle(fontSize: 10, color: Colors.grey)),
          SizedBox(
            width: ad.size.width.toDouble(),
            height: ad.size.height.toDouble(),
            child: AdWidget(ad: ad),
          ),
        ],
      ),
    );
  }
}
