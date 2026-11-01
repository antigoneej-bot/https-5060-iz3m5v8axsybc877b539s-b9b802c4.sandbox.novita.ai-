import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/companion_reminder.dart';
import '../services/notification_service.dart';

/// Shared by My and the companion sheet; changes stay synchronized.
class CompanionReminderSettingsTile extends StatefulWidget {
  final NotificationService? service;
  const CompanionReminderSettingsTile({super.key, this.service});
  @override
  State<CompanionReminderSettingsTile> createState() => _SettingsState();
}

class _SettingsState extends State<CompanionReminderSettingsTile> {
  late final _service = widget.service ?? NotificationService();
  var _settings = const CompanionReminderSettings();
  bool _loading = true, _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service.companionReminderChanges.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    _service.companionReminderChanges.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final settings = await _service.getCompanionReminderSettings();
      if (mounted)
        setState(() {
          _settings = settings;
          _loading = false;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _loading = false;
          _error = '고양이 소식 설정을 읽지 못했어요. 다시 시도해 주세요.';
        });
    }
  }

  Future<void> _change({bool? enabled, int? hour, int? minute}) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final ok = await _service.changeCompanionReminders(
        enabled: enabled,
        hour: hour,
        minute: minute,
      );
      await _load();
      if (mounted && !ok)
        setState(() => _error = '알림을 변경하지 못했어요. 기기 알림 권한을 확인하고 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _settings.hour, minute: _settings.minute),
      initialEntryMode: TimePickerEntryMode.input,
      helpText: '고양이 소식 시간 (08:00~21:59)',
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;
    if (picked.hour < 8 || picked.hour > 21) {
      setState(() => _error = '편안히 쉴 수 있도록 08:00~21:59 사이로 골라 주세요.');
      return;
    }
    await _change(hour: picked.hour, minute: picked.minute);
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SwitchListTile.adaptive(
        key: const Key('companion-reminder-toggle'),
        contentPadding: EdgeInsets.zero,
        title: const Text('고양이 소식'),
        subtitle: Text(
          kIsWeb
              ? '휴대전화 앱에서 알림을 켤 수 있어요.'
              : '하루 최대 한 번, 밥·놀이·손길을 청해요. 오늘 돌봤다면 쉬어요.',
        ),
        value: _settings.enabled,
        onChanged: _loading || _busy || kIsWeb
            ? null
            : (value) => _change(enabled: value),
      ),
      if (_settings.enabled)
        ListTile(
          key: const Key('companion-reminder-time'),
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.schedule_outlined),
          title: Text(
            '알림 시간  ${_settings.hour.toString().padLeft(2, '0')}:${_settings.minute.toString().padLeft(2, '0')}',
          ),
          subtitle: const Text(
            '오랫동안 방문하지 않으면 알림도 쉬어요. 기기에 따라 조금 늦게 도착할 수 있어요.',
          ),
          trailing: const Icon(Icons.edit_outlined, size: 20),
          onTap: _busy ? null : _pickTime,
        ),
      if (_error != null)
        Text(
          _error!,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
    ],
  );
}
