import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../mongi/providers/garden_provider.dart';
import '../providers/app_state_provider.dart';
import '../providers/cat_care_provider.dart';
import '../providers/promise_provider.dart';
import '../services/cloud_service.dart';
import '../services/subscription_service.dart';

/// Account changes update access only. Local letters and garden ownership are
/// never moved or replaced by signing in, signing out, or changing providers.
class AccountAccessBridge extends StatefulWidget {
  const AccountAccessBridge({super.key, required this.child});
  final Widget child;

  @override
  State<AccountAccessBridge> createState() => _AccountAccessBridgeState();
}

class _AccountAccessBridgeState extends State<AccountAccessBridge>
    with WidgetsBindingObserver {
  StreamSubscription<User?>? _auth;
  Timer? _expiryCheck;
  DateTime? _lastResumeRefresh;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    CloudService.entitlementChanges.addListener(_queueAccessRefresh);
    if (Firebase.apps.isNotEmpty) {
      _expiryCheck = Timer.periodic(
        const Duration(minutes: 1),
        (_) => _queueAccessRefresh(),
      );
      _auth = FirebaseAuth.instance.authStateChanges().listen(
        _accountChanged,
        onError: (Object _) => _queueAccessRefresh(),
      );
    }
  }

  void _accountChanged(User? user) {
    _queueAccessRefresh();
    if (user != null && CloudService.enabled) {
      unawaited(_refreshServer(user.uid));
    }
  }

  Future<void> _refreshServer(String uid) async {
    try {
      if (!await CloudService.hasTrustedAccount()) return;
      if (CloudService.currentUser?.uid != uid) return;
      await CloudService.refreshEntitlement();
    } catch (_) {
      // A failed network request cannot prevent local journal/garden use.
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    _queueAccessRefresh();
    final now = DateTime.now();
    final last = _lastResumeRefresh;
    if (last != null && now.difference(last) < const Duration(seconds: 30)) {
      return;
    }
    _lastResumeRefresh = now;
    final uid = CloudService.currentUser?.uid;
    if (uid != null && CloudService.enabled) unawaited(_refreshServer(uid));
  }

  void _queueAccessRefresh() {
    final generation = ++_generation;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || generation != _generation) return;
      unawaited(_refreshAccess(generation));
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  Future<void> _refreshAccess(int generation) async {
    final uid = CloudService.currentUser?.uid;
    var premium = false;
    try {
      premium = await SubscriptionService().isPremium();
    } catch (_) {
      // Fail closed if Firebase/storage initialization is unavailable.
    }
    if (!mounted ||
        generation != _generation ||
        CloudService.currentUser?.uid != uid)
      return;
    context.read<AppStateProvider>().setAccountPremium(premium);
    context.read<CatCareProvider>().setAccountPremium(premium);
    context.read<PromiseProvider>().setAccountPremium(premium);
    context.read<GardenProvider>().setAccountPremium(premium);
  }

  @override
  void dispose() {
    _generation++;
    WidgetsBinding.instance.removeObserver(this);
    _expiryCheck?.cancel();
    CloudService.entitlementChanges.removeListener(_queueAccessRefresh);
    unawaited(_auth?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
