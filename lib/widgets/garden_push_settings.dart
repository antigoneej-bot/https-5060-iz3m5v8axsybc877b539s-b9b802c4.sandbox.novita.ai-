import '../l10n/app_language.dart';
import '../screens/garden_updates_screen.dart';
import 'package:flutter/material.dart';
import '../services/garden_push_service.dart';
import '../services/garden_bell.dart';
import '../services/notification_service.dart';

class GardenPushSettings extends StatefulWidget {
  const GardenPushSettings({super.key});
  @override
  State<GardenPushSettings> createState() => _GardenPushSettingsState();
}

class _GardenPushSettingsState extends State<GardenPushSettings> {
  final service = GardenPushService.instance;
  Map<String, bool> _settings = const {};
  bool _busy = false;
  bool _bell = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    service.changes.addListener(_load);
    _load();
  }

  Future<void> _load() async {
    final value = await service.settings();
    final bell = await GardenBell.enabled();
    if (mounted)
      setState(() {
        _settings = value;
        _bell = bell;
      });
  }

  @override
  void dispose() {
    service.changes.removeListener(_load);
    super.dispose();
  }

  Future<void> _change(String kind, bool value) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await service.setEnabled(kind, value);
      await _load();
    } catch (error) {
      if (mounted)
        setState(
          () => _error = error is StateError
              ? '${error.message}'
              : tr("알림을 연결하지 못했어요. 로그인과 연결을 확인하고 다시 시도해 주세요."),
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(tr("맑은 유리종 알림음")),
        subtitle: Text(tr("새 소식에 짧게 울려요. 휴대폰의 무음·방해금지 설정을 따라요.")),
        value: _bell,
        onChanged: _busy
            ? null
            : (value) async {
                setState(() {
                  _busy = true;
                  _error = null;
                });
                try {
                  await GardenBell.setEnabled(value);
                  if (mounted) setState(() => _bell = value);
                  await NotificationService().restoreIfEnabled();
                  await service.sync();
                } catch (_) {
                  if (mounted)
                    setState(
                      () => _error = tr("설정 동기화를 마치지 못했어요. 연결을 확인해 주세요."),
                    );
                } finally {
                  if (mounted) setState(() => _busy = false);
                }
              },
      ),
      Text(tr("이웃·예약 소식"), style: TextStyle(fontWeight: FontWeight.bold)),
      Text(tr("로그인한 계정의 소식만 받아요. 알림에는 편지나 감정 내용을 넣지 않아요.")),
      for (final kind in ['social', 'booking'])
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(kind == 'social' ? tr("응원·선물 도착 알림") : tr("예약 변경·취소 알림")),
          value: _settings[kind] == true,
          onChanged: _busy || !service.supported
              ? null
              : (value) => _change(kind, value),
        ),
      TextButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const GardenUpdatesScreen()),
        ),
        child: Text(tr("예약 변경 소식 보기")),
      ),
      if (_busy) const LinearProgressIndicator(),
      if (_error != null)
        Text(
          _error!,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      if (!service.supported)
        Text(tr("Google Play에서 설치한 Android 앱에서 설정할 수 있어요.")),
    ],
  );
}
