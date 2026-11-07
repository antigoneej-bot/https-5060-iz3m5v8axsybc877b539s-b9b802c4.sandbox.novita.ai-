import '../l10n/app_language.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../screens/data_safety_screen.dart';
import '../screens/premium_screen.dart';
import '../services/account_status_source.dart';
import '../services/auto_backup_service.dart';
import '../services/cloud_service.dart';
import '../theme.dart';

class AccountStatusCard extends StatefulWidget {
  const AccountStatusCard({
    super.key,
    this.source,
    this.openSubscription,
    this.openBackup,
  });
  final AccountStatusSource? source;
  final Future<void> Function()? openSubscription, openBackup;
  @override
  State<AccountStatusCard> createState() => _AccountStatusCardState();
}

class _AccountStatusCardState extends State<AccountStatusCard>
    with WidgetsBindingObserver {
  late final _source = widget.source ?? AccountStatusSource();
  StreamSubscription<String?>? _accounts;
  AccountStatusSnapshot? _snapshot;
  String? _error;
  int _generation = 0;
  bool _loading = true;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _accounts = _source.accountChanges.listen((_) => _reload());
    CloudService.entitlementChanges.addListener(_changed);
    AutoBackupService.instance.status.addListener(_changed);
    _reload();
  }

  void _changed() {
    if (!_refreshing) unawaited(_reload());
  }

  Future<void> _reload({bool refresh = false}) async {
    if (!mounted) return;
    final request = ++_generation;
    final owner = _source.currentUid;
    setState(() {
      _loading = true;
      _error = null;
      if (_snapshot?.owner != owner) _snapshot = null;
      _refreshing = refresh;
    });
    try {
      final result = await _source
          .load(refresh: refresh)
          .timeout(const Duration(seconds: 12));
      if (!mounted || request != _generation) return;
      if (owner != _source.currentUid || result.owner != owner) {
        unawaited(_reload());
        return;
      }
      setState(() => _snapshot = result);
    } catch (_) {
      if (mounted && request == _generation) {
        if (owner != _source.currentUid) {
          unawaited(_reload());
          return;
        }
        setState(() => _error = tr("최신 상태를 확인하지 못했어요. 연결 후 다시 확인해 주세요."));
      }
    } finally {
      if (mounted && request == _generation) {
        setState(() {
          _loading = false;
          _refreshing = false;
        });
      }
    }
  }

  Future<void> _open({required bool backup}) async {
    final action = backup ? widget.openBackup : widget.openSubscription;
    if (action != null) {
      await action();
    } else {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) =>
              backup ? const DataSafetyScreen() : const PremiumScreen(),
        ),
      );
    }
    if (mounted) await _reload();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_reload());
  }

  @override
  void dispose() {
    _generation++;
    _accounts?.cancel();
    CloudService.entitlementChanges.removeListener(_changed);
    AutoBackupService.instance.status.removeListener(_changed);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = _snapshot?.owner == _source.currentUid ? _snapshot : null;
    return Container(
      key: const ValueKey('account-status-card'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.blobPeriwinkle,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr("구독과 기록 보관"),
            style: titleFont(fontSize: 19, color: AppColors.ink),
          ),
          const SizedBox(height: 8),
          if (data != null) ...[
            Text(
              data.owner == null
                  ? data.provider
                  : tr("{0} 로그인 계정", [data.provider]),
            ),
            const SizedBox(height: 12),
            Text(
              data.subscription.title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            Text(data.subscription.detail),
            const Divider(height: 24),
            Text(
              data.backup.title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            Text(data.backup.detail),
          ],
          if (_loading)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(tr("상태를 확인하고 있어요…")),
            ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            if (data != null) Text(tr("표시된 내용은 마지막으로 확인한 상태예요.")),
            Text(_error!, key: const ValueKey('account-status-error')),
          ],
          const SizedBox(height: 10),
          Text(
            tr("로그인만으로 기록이 다른 기기로 옮겨지지는 않아요."),
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              OutlinedButton(
                onPressed: () => _open(backup: false),
                child: Text(tr("구독 관리·구매 복원")),
              ),
              OutlinedButton(
                onPressed: () => _open(backup: true),
                child: Text(tr("기록 백업·복원")),
              ),
              TextButton(
                onPressed: _loading ? null : () => _reload(refresh: true),
                child: Text(tr("상태 새로고침")),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
