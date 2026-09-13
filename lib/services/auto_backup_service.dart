import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'cloud_service.dart';
import 'backup_service.dart';
import 'backup_codec.dart';

/// Runs on app resume and while open, not an Android background-job promise.
class AutoBackupService with WidgetsBindingObserver {
  static final instance = AutoBackupService._();
  AutoBackupService._();
  static const _secure = FlutterSecureStorage();
  bool _running = false;
  bool paused = false;
  Timer? _timer;
  final status = ValueNotifier<String>('자동 백업 꺼짐');
  String? _uid() => CloudService.enabled ? FirebaseAuth.instance.currentUser?.uid : null;
  void start() {
    if (!CloudService.enabled || _timer != null) return;
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(minutes:5), (_) => unawaited(run()));
    unawaited(run());
  }
  Future<bool> isEnabled() async {
    final uid = _uid();
    return uid != null && await _secure.read(key:'auto_backup_owner') == uid &&
      await _secure.read(key:'auto_backup_password_$uid') != null;
  }
  Future<void> enable(String password) async {
    final uid = _uid();
    if (uid == null || password.length < 12) throw StateError('로그인과 12자 이상의 백업 암호가 필요해요.');
    await CloudService.ensureGardenOwner(uid, bind:true);
    // A device contains one local garden. Explicitly bind it to the chosen account.
    await _secure.write(key:'auto_backup_owner',value:uid);
    await _secure.write(key:'auto_backup_password_$uid',value:password);
    await run(force:true);
  }
  Future<void> disable() async {
    final uid = _uid();
    await _secure.delete(key:'auto_backup_owner');
    if (uid != null) await _secure.delete(key:'auto_backup_password_$uid');
    status.value = '자동 백업 꺼짐';
  }
  Future<void> run({bool force = false}) async {
    if (_running || paused || !CloudService.enabled) return;
    _running = true;
    try {
      if (await BackupService.hasPending() || await BackupService.hasDeferred()) {
        status.value = '복원을 마친 뒤 자동 백업을 다시 시도해요'; return;
      }
      if (!await isEnabled()) { status.value='자동 백업 꺼짐'; return; }
      final uid = _uid()!;
      final prefs = await SharedPreferences.getInstance();
      final last = DateTime.tryParse(prefs.getString('last_cloud_backup_$uid') ?? '');
      if (!force && last != null && DateTime.now().difference(last) < const Duration(hours:24)) {
        status.value='마지막 서버 백업: ${last.toLocal()}'; return;
      }
      status.value='백업 준비 중';
      final password = await _secure.read(key:'auto_backup_password_$uid');
      if (password == null) return;
      final bytes = await BackupCodec.encrypt(await BackupService.snapshot(), password);
      if (paused || _uid() != uid || !await isEnabled()) return;
      final result = await CloudService.call('backup',{'envelope':jsonDecode(utf8.decode(bytes))},uid);
      await prefs.setString('last_cloud_backup_$uid', result['savedAt'] as String);
      status.value='서버 백업 완료: ${result['savedAt']}';
    } catch (_) { status.value='백업 대기 중 · 로그인·구독·연결을 확인해 주세요'; }
    finally { _running = false; }
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(run());
  }
}
