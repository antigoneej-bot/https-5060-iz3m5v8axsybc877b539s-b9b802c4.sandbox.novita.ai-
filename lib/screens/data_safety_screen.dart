import '../services/analytics_service.dart';
import '../services/app_lock_service.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../providers/cat_care_provider.dart';
import '../providers/promise_provider.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/backup_codec.dart';
import '../services/backup_service.dart';
import '../services/cloud_service.dart';
import '../services/auto_backup_service.dart';
import '../services/subscription_service.dart';
import '../theme.dart';

class DataSafetyScreen extends StatefulWidget {
  const DataSafetyScreen({super.key});
  @override
  State<DataSafetyScreen> createState() => _DataSafetyScreenState();
}

class _DataSafetyScreenState extends State<DataSafetyScreen> {
  bool _busy = false;
  String _message = '기록은 현재 이 기기에 저장됩니다.';
  final _email = TextEditingController();
  final _loginPassword = TextEditingController();
  @override
  void dispose() {
    _email.dispose();
    _loginPassword.dispose();
    super.dispose();
  }

  Future<void> _work(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    AutoBackupService.instance.paused = true;
    try {
      await action();
    } catch (e) {
      if (mounted)
        setState(
          () => _message = e is PlatformException && e.code == 'no-device-lock'
              ? '휴대전화 설정에서 PIN·패턴·비밀번호 잠금을 먼저 설정해 주세요.'
              : e is CloudException
              ? e.toString()
              : e is FirebaseAuthException
              ? '로그인 정보를 확인해 주세요. 이메일 인증 또는 비밀번호 재설정이 필요할 수 있어요.'
              : '완료하지 못했어요. 암호·파일·저장 공간과 연결을 확인해 주세요. 기존 기록은 지우지 않았어요.',
        );
    } finally {
      AutoBackupService.instance.paused = false;
      if (mounted) {
        if (CloudService.enabled) {
          final app = context.read<AppStateProvider>();
          final care = context.read<CatCareProvider>();
          final promise = context.read<PromiseProvider>();
          try {
            await app.refreshPremiumStatus();
            await care.load();
            await promise.load();
          } catch (_) {}
        }
        if (mounted) setState(() => _busy = false);
      }
    }
  }

  Future<String?> _password({required bool creating}) async {
    final controller = TextEditingController();
    final confirm = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: Text(creating ? '백업 암호 정하기' : '백업 암호 입력'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '앱 로그인 암호와 별개예요. 암호를 잃으면 새 기기에서 백업을 복원할 수 없어요. 안전한 곳에 보관해 주세요.',
                ),
                TextField(
                  controller: controller,
                  obscureText: true,
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: const InputDecoration(labelText: '백업 암호'),
                  onChanged: (_) => update(() {}),
                ),
                if (creating)
                  TextField(
                    controller: confirm,
                    obscureText: true,
                    enableSuggestions: false,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: '암호 다시 입력 (12자 이상)',
                    ),
                    onChanged: (_) => update(() {}),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed:
                  controller.text.isNotEmpty &&
                      (!creating ||
                          (controller.text.length >= 12 &&
                              controller.text == confirm.text))
                  ? () => Navigator.pop(context, controller.text)
                  : null,
              child: const Text('확인'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    confirm.dispose();
    return result;
  }

  Future<void> _export() async {
    final password = await _password(creating: true);
    if (password == null) return;
    final bytes = await BackupCodec.encrypt(
      await BackupService.snapshot(),
      password,
    );
    final path = await FilePicker.platform.saveFile(
      dialogTitle: '암호화 백업 저장',
      fileName: 'maeumnyang-${DateTime.now().millisecondsSinceEpoch}.mng',
      bytes: bytes,
    );
    if (path != null && mounted)
      setState(() => _message = '암호화 백업 파일을 저장했어요. 파일과 암호를 안전한 곳에 보관해 주세요.');
  }

  Future<void> _restoreBytes(Uint8List bytes, {String? cloudUid}) async {
    final password = await _password(creating: false);
    if (password == null) return;
    final data = await BackupCodec.decrypt(bytes, password);
    BackupService.validate(data);
    final existing = await BackupService.hasLocalRecords();
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('복원 미리보기'),
        content: Text(
          '백업 날짜: ${data['createdAt']}\n기록·초안·답장 항목: ${BackupService.count(data)}개\n\n'
          '기존 항목과 같은 ID는 현재 기록을 유지하고, 없는 항목만 추가해요.\n'
          '${existing ? '현재 정원 이름·성장 설정은 유지해요.' : '새 정원에는 백업의 이름·성장 설정도 가져와요.'}\n'
          '복원 후 앱을 다시 열어 주세요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('복원'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (cloudUid != null)
      await CloudService.ensureGardenOwner(cloudUid, bind: true);
    final added = await BackupService.restore(data);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text('복원 완료'),
          content: Text(
            '$added개 항목을 추가했어요. 같은 ID는 현재 기록을 유지했어요. 앱을 닫은 뒤 다시 열어 주세요.',
          ),
          actions: [
            TextButton(
              onPressed: () => SystemNavigator.pop(),
              child: const Text('앱 닫기'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _import() async {
    final selected = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: false,
    );
    if (selected == null || selected.files.single.path == null) return;
    final file = File(selected.files.single.path!);
    if (await file.length() > BackupCodec.maxBytes)
      throw const FormatException('파일이 너무 커요.');
    await _restoreBytes(await file.readAsBytes());
  }

  Future<void> _cloudRestore() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final result = await CloudService.call('listBackups', const {}, uid);
    final versions = List<Map<String, dynamic>>.from(
      (result['versions'] as List).map(
        (v) => Map<String, dynamic>.from(v as Map),
      ),
    );
    if (!mounted) return;
    if (versions.isEmpty) {
      setState(() => _message = '서버에 저장된 백업이 없어요.');
      return;
    }
    final id = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('복원할 백업 선택'),
        children: [
          for (final version in versions)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, version['id']),
              child: Text(
                version['createdAt']?.toString() ?? version['id'] as String,
              ),
            ),
        ],
      ),
    );
    if (id == null) return;
    final backup = await CloudService.call('downloadBackup', {'id': id}, uid);
    await _restoreBytes(
      Uint8List.fromList(utf8.encode(jsonEncode(backup['envelope']))),
      cloudUid: uid,
    );
  }

  Future<void> _signIn(bool create) async {
    if (create) {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _email.text.trim(),
            password: _loginPassword.text,
          );
      await credential.user!.sendEmailVerification();
      if (mounted) setState(() => _message = '인증 메일을 확인한 뒤 아래의 인증 확인을 눌러 주세요.');
    } else {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _loginPassword.text,
      );
      if (mounted)
        setState(
          () =>
              _message = '로그인했어요. 이 기기에는 하나의 정원이 저장되며 로그인만으로 다른 기록을 가져오지는 않아요.',
        );
    }
    _loginPassword.clear();
  }

  @override
  Widget build(BuildContext context) {
    final user = CloudService.enabled
        ? FirebaseAuth.instance.currentUser
        : null;
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(title: const Text('기록 보관과 백업')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.catSageBg,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.shield_outlined,
                    color: AppColors.titlePastelGreen,
                    size: 30,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '소중한 기록을 안전하게',
                    style: titleFont(
                      fontSize: 26,
                      color: AppColors.titlePastelGreen,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _message,
                    style: bodyFont(fontSize: 14, color: AppColors.ink),
                  ),
                ],
              ),
            ),
            if (_busy)
              const Padding(
                padding: EdgeInsets.all(12),
                child: LinearProgressIndicator(),
              ),
            const SizedBox(height: 16),
            const Text('편지는 기기에 자동 저장해요. 앱 삭제·분실에 대비하려면 별도 백업이 필요해요.'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _busy ? null : () => _work(_export),
              child: const Text('암호화 백업 파일 저장'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _busy ? null : () => _work(_import),
              child: const Text('백업 파일에서 복원'),
            ),
            const Divider(height: 32),
            ValueListenableBuilder<bool>(
              valueListenable: AnalyticsService.sharingEnabled,
              builder: (_, enabled, __) => SwitchListTile(
                title: const Text('앱 개선을 위한 사용 통계 공유'),
                subtitle: const Text(
                  '선택 사항이에요. 일기 본문·선택한 감정은 보내지 않아요. Firebase가 앱 인스턴스·기기 정보를 처리할 수 있어요.',
                ),
                value: enabled,
                onChanged: _busy
                    ? null
                    : (value) =>
                          _work(() => AnalyticsService().setSharing(value)),
              ),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: AppLockService.enabled,
              builder: (_, enabled, __) => SwitchListTile(
                title: const Text('앱 잠금'),
                subtitle: const Text(
                  '휴대전화 PIN·패턴·비밀번호로 열어요. 잠금을 켜면 화면 캡처와 최근 앱 미리보기도 차단해요.',
                ),
                value: enabled,
                onChanged: _busy
                    ? null
                    : (value) => _work(() async {
                        final accepted = await AppLockService.setEnabled(value);
                        if (mounted)
                          setState(
                            () => _message = accepted
                                ? (value ? '앱 잠금을 켰어요.' : '앱 잠금을 껐어요.')
                                : '잠금 변경을 취소했어요.',
                          );
                      }),
              ),
            ),
            TextButton(
              onPressed: _busy
                  ? null
                  : () => _work(() async {
                      if (!await BackupService.hasDeferred()) {
                        if (mounted) setState(() => _message = '보류한 복원이 없어요.');
                        return;
                      }
                      final added = await BackupService.retryDeferred();
                      if (!mounted) return;
                      await showDialog<void>(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => PopScope(
                          canPop: false,
                          child: AlertDialog(
                            title: const Text('보류한 복원 완료'),
                            content: Text(
                              '$added개 항목을 추가했어요. 앱을 닫은 뒤 다시 열어 주세요.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => SystemNavigator.pop(),
                                child: const Text('앱 닫기'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
              child: const Text('보류한 복원 다시 시도'),
            ),
            TextButton(
              onPressed: _busy
                  ? null
                  : () => _work(() async {
                      if (!await BackupService.hasDeferred()) {
                        if (mounted) setState(() => _message = '보류한 복원이 없어요.');
                        return;
                      }
                      if (!mounted) return;
                      final accepted = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('보류한 복원을 그만할까요?'),
                          content: const Text(
                            '이미 추가된 기록은 유지해요. 아직 추가되지 않은 내용은 자동으로 복원하지 않으며 복원 원본은 기기에 암호화 보관해요. 이후 원본 백업 파일로 다시 복원할 수 있어요.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('취소'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('복원 그만하기'),
                            ),
                          ],
                        ),
                      );
                      if (accepted == true) {
                        await BackupService.archiveDeferred();
                        if (mounted)
                          setState(
                            () => _message =
                                '보류한 복원을 마무리했어요. 현재 기록을 유지하며 새 백업·복원을 이용할 수 있어요.',
                          );
                      }
                    }),
              child: const Text('보류한 복원 그만하기'),
            ),
            const Divider(height: 32),
            if (!CloudService.enabled)
              const Text(
                '계정과 자동 백업은 서버 연결 준비 후 이용할 수 있어요. 현재는 위의 파일 백업을 이용해 주세요.',
              )
            else ...[
              if (user == null) ...[
                const Text('자동 백업·서버 결제 확인을 위한 계정'),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: '이메일'),
                ),
                TextField(
                  controller: _loginPassword,
                  obscureText: true,
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: const InputDecoration(labelText: '로그인 비밀번호'),
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => _work(() => _signIn(false)),
                      child: const Text('로그인'),
                    ),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => _work(() => _signIn(true)),
                      child: const Text('계정 만들기'),
                    ),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => _work(() async {
                              await FirebaseAuth.instance
                                  .sendPasswordResetEmail(
                                    email: _email.text.trim(),
                                  );
                              if (mounted)
                                setState(
                                  () => _message =
                                      '입력한 이메일의 비밀번호 재설정 안내를 확인해 주세요.',
                                );
                            }),
                      child: const Text('비밀번호 재설정'),
                    ),
                  ],
                ),
              ] else ...[
                Text('계정: ${user.email ?? ''}'),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => _work(() async {
                          await user.reload();
                          await FirebaseAuth.instance.currentUser?.getIdToken(
                            true,
                          );
                          final verified =
                              FirebaseAuth
                                  .instance
                                  .currentUser
                                  ?.emailVerified ==
                              true;
                          if (verified)
                            await SubscriptionService().restorePurchases();
                          if (mounted)
                            setState(
                              () => _message = verified
                                  ? '이메일 인증을 확인했어요.'
                                  : '아직 이메일 인증 전이에요.',
                            );
                        }),
                  child: const Text('이메일 인증 확인'),
                ),
                const Text(
                  '이 기기의 정원 전체를 이 계정에 백업합니다. 처음 백업하거나 서버에서 복원한 계정에 연결되며 다른 계정으로는 백업·복원할 수 없어요. 로그아웃해도 기기 기록은 남아요.',
                ),
                const Text(
                  '자동 백업은 구독 중 앱을 열었을 때 하루 한 번 시도합니다. 최근 10개 버전을 보관하며 구독 종료 후에도 기존 백업은 복원할 수 있어요.',
                ),
                ValueListenableBuilder<String>(
                  valueListenable: AutoBackupService.instance.status,
                  builder: (_, value, __) => Text(value),
                ),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => _work(() async {
                          final password = await _password(creating: true);
                          if (password == null) return;
                          // Explicit consent: this stores the backup password in device secure storage.
                          if (!mounted) return;
                          final consent = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('이 계정에 자동 백업할까요?'),
                              content: const Text(
                                '백업 암호를 기기의 보안 저장소에 보관해 자동 백업에 사용해요. 새 기기에서 복원할 암호는 별도로 보관해 주세요. 암호를 변경하면 이전 백업에는 이전 암호가 필요해요.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('취소'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('켜기'),
                                ),
                              ],
                            ),
                          );
                          if (consent == true) {
                            AutoBackupService.instance.paused = false;
                            await AutoBackupService.instance.enable(password);
                          }
                        }),
                  child: const Text('자동 백업 켜기'),
                ),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => _work(() async {
                          AutoBackupService.instance.paused = false;
                          await AutoBackupService.instance.run(force: true);
                        }),
                  child: const Text('지금 서버에 백업'),
                ),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => _work(AutoBackupService.instance.disable),
                  child: const Text('자동 백업 끄기'),
                ),
                TextButton(
                  onPressed: _busy ? null : () => _work(_cloudRestore),
                  child: const Text('서버 백업에서 복원'),
                ),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => _work(() async {
                          await AutoBackupService.instance.disable();
                          await FirebaseAuth.instance.signOut();
                          if (mounted)
                            setState(
                              () => _message = '로그아웃했어요. 이 기기의 기록은 그대로 남아 있어요.',
                            );
                        }),
                  child: const Text('로그아웃'),
                ),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => _work(() async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('서버 계정과 백업을 삭제할까요?'),
                              content: const Text(
                                '이 작업은 되돌릴 수 없어요. 기기 기록과 Play 구독은 별도로 남아요. 구독 해지는 Play에서 해주세요. 최근 5분 이내 로그인해야 삭제할 수 있어요.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('취소'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('삭제'),
                                ),
                              ],
                            ),
                          );
                          if (confirm != true) return;
                          await CloudService.call('deleteCloudAccount');
                          await CloudService.clearGardenOwner();
                          await AutoBackupService.instance.disable();
                          await FirebaseAuth.instance.signOut();
                          if (mounted)
                            setState(
                              () => _message =
                                  '서버 계정과 백업을 삭제했어요. 이 기기 기록은 남아 있어요.',
                            );
                        }),
                  child: const Text('서버 계정과 백업 삭제'),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
