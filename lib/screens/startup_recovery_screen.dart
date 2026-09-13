import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../services/backup_service.dart';
import '../services/backup_codec.dart';
import '../widgets/app_lock_gate.dart';

class StartupRecoveryApp extends StatelessWidget {
  final Future<void> Function() retry;
  final bool canDefer;
  const StartupRecoveryApp({super.key, required this.retry, this.canDefer = false});
  @override
  Widget build(BuildContext context) => MaterialApp(
    builder: (_, child) => AppLockGate(child: child!),
    home: _RecoveryScreen(retry: retry, canDefer: canDefer),
  );
}
class _RecoveryScreen extends StatefulWidget {
  final Future<void> Function() retry;
  final bool canDefer;
  const _RecoveryScreen({required this.retry, required this.canDefer});
  @override
  State<_RecoveryScreen> createState() => _RecoveryScreenState();
}
class _RecoveryScreenState extends State<_RecoveryScreen> {
  bool _busy = false;
  String? _message;
  Future<void> _work(Future<void> Function() action) async {
    if (_busy) return;
    setState(() { _busy = true; _message = null; });
    try { await action(); }
    catch (_) { if (mounted) setState(() => _message = '완료하지 못했어요. 저장 공간을 확인한 뒤 다시 시도해 주세요.'); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  Future<void> _export() async {
    final password = TextEditingController();
    final confirm = TextEditingController();
    final value = await showDialog<String>(context: context, builder: (context) => StatefulBuilder(
      builder: (context, update) => AlertDialog(
        title: const Text('현재 기록의 암호화 백업'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('아직 복원되지 않은 항목은 포함되지 않을 수 있어요. 기존 백업 원본도 보관해 주세요.'),
          TextField(controller: password, obscureText: true, enableSuggestions: false, autocorrect: false,
            decoration: const InputDecoration(labelText: '백업 암호 (12자 이상)'), onChanged: (_) => update(() {})),
          TextField(controller: confirm, obscureText: true, enableSuggestions: false, autocorrect: false,
            decoration: const InputDecoration(labelText: '암호 다시 입력'), onChanged: (_) => update(() {})),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          FilledButton(onPressed: password.text.length >= 12 && password.text == confirm.text
            ? () => Navigator.pop(context, password.text) : null, child: const Text('백업'))],
      ),
    ));
    password.dispose(); confirm.dispose();
    if (value == null) return;
    final bytes = await BackupCodec.encrypt(await BackupService.snapshot(), value);
    final path = await FilePicker.platform.saveFile(fileName: 'maeumnyang-recovery.mng', bytes: bytes);
    if (path != null && mounted) setState(() => _message = '백업 파일을 저장했어요. 암호도 별도로 보관해 주세요.');
  }
  Future<void> _defer() async {
    final accepted = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('복원을 보류하고 열까요?'),
      content: const Text('이미 추가된 기록은 유지하고 나머지 복원은 보류해요. 복원 전으로 되돌리는 기능은 아니에요. 보류한 내용은 이 기기에 남으며 기록 보관과 백업에서 재시도할 수 있어요.'),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('현재 기록으로 열기'))],
    ));
    if (accepted != true) return;
    await BackupService.deferPending();
    await widget.retry();
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('기록 복구 안내')),
    body: SafeArea(child: ListView(padding: const EdgeInsets.all(24), children: [
      Text(widget.canDefer ? '이전 백업 복원을 마치지 못했어요.' : '기록을 여는 중 문제가 생겼어요.'),
      const SizedBox(height: 12),
      const Text('기록을 자동으로 지우거나 초기화하지 않았어요. 저장 공간을 확인한 뒤 다시 시도해 주세요. 앱 삭제나 앱 데이터 삭제는 피해주세요.'),
      if (_message != null) Padding(padding: const EdgeInsets.only(top: 16), child: Text(_message!)),
      if (_busy) const LinearProgressIndicator(),
      FilledButton(onPressed: _busy ? null : () => _work(widget.retry), child: const Text('다시 시도')),
      if (widget.canDefer) ...[
        OutlinedButton(onPressed: _busy ? null : () => _work(_export), child: const Text('현재 기록 백업하기')),
        TextButton(onPressed: _busy ? null : () => _work(_defer), child: const Text('복원을 보류하고 현재 기록으로 열기')),
      ],
    ])),
  );
}
