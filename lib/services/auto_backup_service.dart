import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'cloud_service.dart';
import 'backup_service.dart';
import 'backup_codec.dart';
import 'backup_fingerprint.dart';
import '../models/account_status_summary.dart';

/// Runs on app resume and while open, not an Android background-job promise.
class AutoBackupService with WidgetsBindingObserver {
  static final instance = AutoBackupService._();
  AutoBackupService._();
  @visibleForTesting
  AutoBackupService.forTesting({
    required String? Function() owner,
    required Future<bool> Function() enabled,
    required Future<Map<String, dynamic>> Function() snapshot,
    required Future<Map<String, dynamic>> Function(Map<String, dynamic>, String)
    upload,
    required Future<String?> Function(String) password,
    required Future<bool> Function() restoring,
    required DateTime Function() now,
  }) : _ownerOverride = owner,
       _enabledOverride = enabled,
       _snapshotOverride = snapshot,
       _uploadOverride = upload,
       _passwordOverride = password,
       _restoringOverride = restoring,
       _now = now;
  String? Function()? _ownerOverride;
  Future<bool> Function()? _enabledOverride;
  Future<Map<String, dynamic>> Function()? _snapshotOverride;
  Future<Map<String, dynamic>> Function(Map<String, dynamic>, String)?
  _uploadOverride;
  Future<String?> Function(String)? _passwordOverride;
  Future<bool> Function()? _restoringOverride;
  DateTime Function() _now = DateTime.now;
  bool get _cloudEnabled => _ownerOverride != null || CloudService.enabled;
  Future<Map<String, dynamic>> _snapshot() =>
      _snapshotOverride?.call() ?? BackupService.snapshot();
  Future<bool> _restoring() async => _restoringOverride != null
      ? await _restoringOverride!()
      : await BackupService.hasPending() || await BackupService.hasDeferred();
  static const _secure = FlutterSecureStorage();
  bool _running = false;
  bool paused = false;
  Timer? _timer;
  String? _checkedOwner;
  bool? _pendingChanges;
  final status = ValueNotifier<String>('자동 백업 꺼짐');
  String? _uid() => _ownerOverride != null
      ? _ownerOverride!()
      : CloudService.enabled
      ? CloudService.currentUser?.uid
      : null;

  Future<BackupStatusSummary> readSummary() async {
    final owner = _uid();
    if (owner == null) return const BackupStatusSummary(enabled: false);
    final enabled = await isEnabled();
    final prefs = await SharedPreferences.getInstance();
    final last = DateTime.tryParse(
      prefs.getString('last_cloud_backup_$owner') ?? '',
    );
    if (_uid() != owner) throw const CloudException('account-changed');
    return BackupStatusSummary(
      enabled: enabled,
      pendingChanges: _checkedOwner == owner ? _pendingChanges : null,
      lastConfirmedAt: last != null && !last.isAfter(_now()) ? last : null,
    );
  }

  void start() {
    if (!_cloudEnabled || _timer != null) return;
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => unawaited(run()),
    );
    unawaited(run());
  }

  Future<bool> isEnabled() async {
    if (_enabledOverride != null) return _enabledOverride!();
    final uid = _uid();
    return uid != null &&
        await _secure.read(key: 'auto_backup_owner') == uid &&
        await _secure.read(key: 'auto_backup_password_$uid') != null &&
        _uid() == uid;
  }

  Future<void> enable(String password) async {
    final uid = _uid();
    if (uid == null || password.length < 12)
      throw StateError('로그인과 12자 이상의 백업 암호가 필요해요.');
    await CloudService.ensureGardenOwner(uid, bind: true);
    // A device contains one local garden. Explicitly bind it to the chosen account.
    await _secure.write(key: 'auto_backup_owner', value: uid);
    await _secure.write(key: 'auto_backup_password_$uid', value: password);
    await run(force: true);
  }

  Future<void> disable() async {
    final uid = _uid();
    await _secure.delete(key: 'auto_backup_owner');
    if (uid != null) await _secure.delete(key: 'auto_backup_password_$uid');
    status.value = '자동 백업 꺼짐';
  }

  Future<void> run({bool force = false}) async {
    if (_running || paused || !_cloudEnabled) return;
    _running = true;
    try {
      if (await _restoring()) {
        status.value = '복원을 마친 뒤 자동 백업을 다시 시도해요';
        return;
      }
      if (!await isEnabled()) {
        status.value = '자동 백업 꺼짐';
        return;
      }
      final uid = _uid()!;
      final prefs = await SharedPreferences.getInstance();
      final last = DateTime.tryParse(
        prefs.getString('last_cloud_backup_$uid') ?? '',
      );
      final snapshot = await _snapshot();
      final fingerprint = await backupFingerprint(snapshot);
      if (paused || _uid() != uid || !await isEnabled()) return;
      _checkedOwner = uid;
      _pendingChanges =
          fingerprint != prefs.getString('cloud_backup_digest_$uid');
      if (!force && !_pendingChanges!) {
        status.value = '마지막 서버 백업: ${last?.toLocal() ?? '확인 필요'}';
        return;
      }
      if (!force &&
          last != null &&
          !last.isAfter(_now()) &&
          _now().difference(last) < const Duration(minutes: 2)) {
        status.value = '새 기록 백업 대기 중 · 앱을 열어 두면 곧 저장해요';
        return;
      }
      status.value = '백업 준비 중';
      final password =
          await (_passwordOverride?.call(uid) ??
              _secure.read(key: 'auto_backup_password_$uid'));
      if (password == null) return;
      final bytes = await BackupCodec.encrypt(snapshot, password);
      if (paused || _uid() != uid || !await isEnabled()) return;
      final payload = <String, dynamic>{
        'envelope': jsonDecode(utf8.decode(bytes)),
      };
      final result =
          await (_uploadOverride?.call(payload, uid) ??
              CloudService.call('backup', payload, uid));
      if (_uid() != uid) return;
      final savedAt = DateTime.tryParse('${result['savedAt'] ?? ''}');
      if (savedAt == null)
        throw const FormatException('missing-backup-receipt');
      await prefs.setString(
        'last_cloud_backup_$uid',
        result['savedAt'] as String,
      );
      // A failed upload never advances the digest. A write during encryption or
      // upload remains dirty and is picked up by the next foreground check.
      await prefs.setString('cloud_backup_digest_$uid', fingerprint);
      if (_uid() != uid) return;
      _pendingChanges =
          await backupFingerprint(await _snapshot()) != fingerprint;
      if (_uid() != uid) return;
      status.value = _pendingChanges!
          ? '백업 후 새 기록이 생겼어요 · 다음 백업 대기 중'
          : '서버 백업 완료: ${result['savedAt']}';
    } catch (_) {
      status.value = '백업 대기 중 · 로그인·구독·연결을 확인해 주세요';
    } finally {
      _running = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(run());
  }
}
