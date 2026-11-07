import 'package:firebase_auth/firebase_auth.dart';
import '../models/account_status_summary.dart';
import 'auto_backup_service.dart';
import 'cloud_service.dart';
import 'social_auth_service.dart';

class AccountStatusSnapshot {
  const AccountStatusSnapshot({
    required this.owner,
    required this.provider,
    required this.subscription,
    required this.backup,
  });
  final String? owner;
  final String provider;
  final SubscriptionStatusSummary subscription;
  final BackupStatusSummary backup;
}

/// The UI reads account-owned facts; payment actions stay in PremiumScreen.
class AccountStatusSource {
  String? get currentUid => SocialAuthService.currentUser?.uid;
  Stream<String?> get accountChanges => SocialAuthService.firebaseReady
      ? FirebaseAuth.instance.userChanges().map((user) => user?.uid)
      : const Stream.empty();

  Future<AccountStatusSnapshot> load({bool refresh = false}) async {
    final owner = currentUid;
    void checkOwner() {
      if (currentUid != owner) throw const CloudException('account-changed');
    }

    if (owner == null) {
      return const AccountStatusSnapshot(
        owner: null,
        provider: '로그인 전',
        subscription: SubscriptionStatusSummary(
          '무료 이용 중',
          '구매한 구독이 있다면 구매할 때 사용한 계정으로 로그인해 주세요.',
        ),
        backup: BackupStatusSummary(enabled: false),
      );
    }
    if (refresh && CloudService.enabled) {
      await CloudService.refreshEntitlement(expectedUid: owner);
      checkOwner();
    }
    final provider = await SocialAuthService.providerLabel();
    checkOwner();
    final record = await CloudService.cachedSubscriptionRecord(
      expectedUid: owner,
    );
    checkOwner();
    final backup = await AutoBackupService.instance.readSummary();
    checkOwner();
    return AccountStatusSnapshot(
      owner: owner,
      provider: provider,
      subscription: SubscriptionStatusSummary.fromRecord(
        record,
        now: DateTime.now(),
      ),
      backup: backup,
    );
  }
}
