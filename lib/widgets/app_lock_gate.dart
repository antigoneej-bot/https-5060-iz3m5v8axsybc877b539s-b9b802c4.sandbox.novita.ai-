import 'package:flutter/material.dart';
import '../services/app_lock_service.dart';

/// Above the navigator, so pushed routes and dialogs are also hidden.
class AppLockGate extends StatefulWidget {
  final Widget child;
  const AppLockGate({super.key, required this.child});
  @override
  State<AppLockGate> createState() => _AppLockGateState();
}
class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  bool _ready = false;
  bool _locked = true;
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AppLockService.enabled.addListener(_settingChanged);
    _load();
  }
  Future<void> _load() async {
    try {
      final enabled = await AppLockService.load();
      if (mounted) setState(() { _ready = true; _locked = enabled; _error = null; });
    } catch (_) {
      if (mounted) setState(() => _error = '잠금 설정을 확인하지 못했어요. 다시 시도해 주세요.');
    }
  }
  void _settingChanged() {
    if (mounted) setState(() { _locked = false; });
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && AppLockService.enabled.value &&
        !AppLockService.authenticating && mounted) {
      setState(() => _locked = true);
    }
  }
  Future<void> _unlock() async {
    if (_busy) return;
    setState(() { _busy = true; _error = null; });
    try {
      final accepted = await AppLockService.authenticate();
      if (mounted) setState(() { _locked = !accepted; });
    } catch (_) {
      if (mounted) setState(() => _error = '휴대전화의 화면 잠금 설정을 확인한 뒤 다시 시도해 주세요.');
    } finally { if (mounted) setState(() => _busy = false); }
  }
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AppLockService.enabled.removeListener(_settingChanged);
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final hidden = !_ready || _locked;
    return Stack(children: [
      Offstage(offstage: hidden, child: TickerMode(enabled: !hidden, child: widget.child)),
      if (hidden) Positioned.fill(child: PopScope(canPop: false, child: Scaffold(
        body: SafeArea(child: Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(
          mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.lock_outline, size: 48),
            const SizedBox(height: 16),
            const Text('마음냥 정원 · 나의 기록'),
            const SizedBox(height: 12),
            if (_error != null) Text(_error!),
            if (!_ready && _error == null) const CircularProgressIndicator()
            else FilledButton(onPressed: _busy ? null : (_ready ? _unlock : _load),
              child: Text(_ready ? '휴대전화 잠금으로 열기' : '다시 확인')),
          ],
        )))),
      ))),
    ]);
  }
}
