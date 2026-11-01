import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'cloud_service.dart';

/// The news role is independent of purchases and never unlocks premium access.
/// Only the server may issue garden_news_admin; this controls UI visibility, not
/// authorization. The backend checks the signed token again for every action.
bool hasGardenNewsAdminClaim(Map<String, dynamic> claims) {
  if (claims['garden_news_admin'] == true) return true;
  final email = claims['email'];
  return claims['email_verified'] == true &&
      email is String &&
      email.toLowerCase() == 'antigone.ej@gmail.com';
}

class GardenNewsAdminAccount {
  final String uid;
  final bool isAnonymous;

  const GardenNewsAdminAccount(this.uid, {this.isAnonymous = false});
}

/// Refreshes claims on entry/manual refresh and after authentication changes.
/// An account switch, failed refresh or out-of-order response clears access.
class GardenNewsAdminService extends ChangeNotifier {
  GardenNewsAdminService({
    required GardenNewsAdminAccount? Function() readAccount,
    required Future<Map<String, dynamic>> Function(String uid) refreshClaims,
    required Stream<String?> accountChanges,
    required bool Function() backendEnabled,
  }) : _readAccount = readAccount,
       _refreshClaims = refreshClaims,
       _backendEnabled = backendEnabled {
    _accountSubscription = accountChanges.listen(
      (_) => unawaited(refresh()),
      onError: (Object _, StackTrace __) => _invalidate(),
    );
  }

  factory GardenNewsAdminService.firebase() {
    User? currentUser() =>
        Firebase.apps.isEmpty ? null : FirebaseAuth.instance.currentUser;
    return GardenNewsAdminService(
      readAccount: () {
        final user = currentUser();
        return user == null
            ? null
            : GardenNewsAdminAccount(user.uid, isAnonymous: user.isAnonymous);
      },
      refreshClaims: (uid) async {
        final user = currentUser();
        if (user == null || user.uid != uid || user.isAnonymous) {
          throw StateError('account-changed');
        }
        final token = await user.getIdTokenResult(true);
        if (currentUser()?.uid != uid) throw StateError('account-changed');
        return token.claims ?? const <String, dynamic>{};
      },
      accountChanges: Firebase.apps.isEmpty
          ? const Stream<String?>.empty()
          : FirebaseAuth.instance.authStateChanges().map((user) => user?.uid),
      backendEnabled: () => CloudService.enabled,
    );
  }

  final GardenNewsAdminAccount? Function() _readAccount;
  final Future<Map<String, dynamic>> Function(String uid) _refreshClaims;
  final bool Function() _backendEnabled;
  late final StreamSubscription<String?> _accountSubscription;
  String? _grantedUid;
  int _generation = 0;
  bool _disposed = false;

  bool get canManage {
    if (_disposed || !_backendEnabled()) return false;
    final account = _readAccount();
    return account != null &&
        !account.isAnonymous &&
        account.uid == _grantedUid;
  }

  void _invalidate() {
    if (_disposed) return;
    _generation++;
    _grantedUid = null;
    notifyListeners();
  }

  Future<void> refresh() async {
    if (_disposed) return;
    _invalidate();
    final generation = _generation;
    final account = _readAccount();
    if (!_backendEnabled() || account == null || account.isAnonymous) return;
    try {
      final claims = await _refreshClaims(account.uid);
      final current = _readAccount();
      if (_disposed || generation != _generation) return;
      if (!_backendEnabled() ||
          current == null ||
          current.isAnonymous ||
          current.uid != account.uid) {
        return;
      }
      if (hasGardenNewsAdminClaim(claims)) _grantedUid = account.uid;
      notifyListeners();
    } catch (_) {
      // Access was cleared before the request. Never restore a cached grant.
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _grantedUid = null;
    unawaited(_accountSubscription.cancel());
    super.dispose();
  }
}
