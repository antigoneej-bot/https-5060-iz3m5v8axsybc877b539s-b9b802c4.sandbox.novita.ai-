import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../models/backup_progress.dart';
import 'diagnostics_service.dart';
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
  Future<void>? _active;
  bool _manualRequested = false;
  int _generation = 0;
  bool paused = false;
  Timer? _timer;
  String? _checkedOwner;
  bool? _pendingChanges;
  final status = ValueNotifier<BackupProgress>(
    const BackupProgress(BackupPhase.off),
  );
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
    _generation++;
    _manualRequested = false;
    final uid = _uid();
    await _secure.delete(key: 'auto_backup_owner');
    if (uid != null) await _secure.delete(key: 'auto_backup_password_$uid');
    status.value = const BackupProgress(BackupPhase.off);
  }

  Future<void> run({bool force = false}) {
    if (_active != null) {
      _manualRequested |= force;
      return _active!;
    }
    if (paused || !_cloudEnabled) return Future<void>.value();
    final completion = Completer<void>();
    _active = completion.future;
    final generation = _generation;
    unawaited(() async {
      try {
        await _runOnce(force: force, generation: generation);
        // Join the in-flight receipt. Only a confirmed write with newer local
        // changes (or an automatic cooldown) needs one coalesced follow-up.
        // Never automatically retry an unconfirmed/failed write.
        final followUp =
            _manualRequested &&
            generation == _generation &&
            !paused &&
            {
              BackupPhase.waiting,
              BackupPhase.changedAfterSave,
            }.contains(status.value.phase);
        _manualRequested = false;
        if (followUp) await _runOnce(force: true, generation: generation);
        completion.complete();
      } catch (error, stack) {
        completion.completeError(error, stack);
      } finally {
        _active = null;
        _manualRequested = false;
      }
    }());
    return completion.future;
  }

  Future<void> _runOnce({required bool force, required int generation}) async {
    DateTime? confirmedAt;
    String? operationOwner;
    var phase = BackupPhase.preparing;
    Future<bool> canContinue(String uid) async {
      final enabled = await isEnabled();
      // Recheck after asynchronous secure storage reads, too: disabling or
      // switching accounts while that read is pending must prevent an upload.
      return enabled && !paused && generation == _generation && _uid() == uid;
    }

    void progress(BackupPhase value, {String? errorCode}) {
      if (generation != _generation) return;
      phase = value;
      status.value = BackupProgress(
        value,
        confirmedAt: confirmedAt,
        errorCode: errorCode,
      );
    }

    try {
      if (await _restoring()) {
        progress(BackupPhase.restoring);
        return;
      }
      if (!await isEnabled()) {
        progress(BackupPhase.off);
        return;
      }
      final uid = _uid()!;
      operationOwner = uid;
      final prefs = await SharedPreferences.getInstance();
      final last = DateTime.tryParse(
        prefs.getString('last_cloud_backup_$uid') ?? '',
      );
      confirmedAt = last;
      final snapshot = await _snapshot();
      final fingerprint = await backupFingerprint(snapshot);
      if (!await canContinue(uid)) return;
      _checkedOwner = uid;
      _pendingChanges =
          fingerprint != prefs.getString('cloud_backup_digest_$uid');
      if (!force && !_pendingChanges!) {
        progress(BackupPhase.unchanged);
        return;
      }
      if (!force &&
          last != null &&
          !last.isAfter(_now()) &&
          _now().difference(last) < const Duration(minutes: 2)) {
        progress(BackupPhase.waiting);
        return;
      }
      progress(BackupPhase.preparing);
      final password =
          await (_passwordOverride?.call(uid) ??
              _secure.read(key: 'auto_backup_password_$uid'));
      if (password == null) {
        progress(BackupPhase.failed, errorCode: 'password-unavailable');
        return;
      }
      progress(BackupPhase.encrypting);
      final bytes = await BackupCodec.encrypt(snapshot, password);
      if (!await canContinue(uid)) return;
      final payload = <String, dynamic>{
        'envelope': jsonDecode(utf8.decode(bytes)),
      };
      progress(BackupPhase.uploading);
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
      confirmedAt = savedAt;
      if (_uid() != uid) return;
      // Keep the confirmed receipt, but an older upload cannot reactivate an
      // opt-out or update the status of a later configuration.
      if (generation != _generation || !await isEnabled()) return;
      _pendingChanges =
          await backupFingerprint(await _snapshot()) != fingerprint;
      if (_uid() != uid) return;
      progress(
        _pendingChanges! ? BackupPhase.changedAfterSave : BackupPhase.saved,
      );
    } catch (error, stack) {
      if (operationOwner != null && operationOwner != _uid()) {
        status.value = const BackupProgress(BackupPhase.off);
        return;
      }
      final code = error is CloudException
          ? error.code
          : error is FirebaseAuthException
          ? 'authentication-required'
          : error is SocketException ||
                error is http.ClientException ||
                error is TimeoutException
          ? 'network-unavailable'
          : phase == BackupPhase.encrypting
          ? 'encryption-failed'
          : phase == BackupPhase.uploading && error is FormatException
          ? 'receipt-unconfirmed'
          : 'backup-failed';
      progress(BackupPhase.failed, errorCode: code);
      unawaited(DiagnosticsService.record(error, stack, 'backup'));
    } finally {
      if (operationOwner != null && operationOwner != _uid()) {
        status.value = const BackupProgress(BackupPhase.off);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(run());
  }
}
