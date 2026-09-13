import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AppLockService {
  static const channel = MethodChannel('garden/app_lock');
  static final enabled = ValueNotifier<bool>(false);
  static bool authenticating = false;
  static Future<bool> load() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    enabled.value = await channel.invokeMethod<bool>('isEnabled') ?? true;
    return enabled.value;
  }
  static Future<bool> authenticate() => _request('authenticate');
  static Future<bool> setEnabled(bool value) async {
    final accepted = await _request('setEnabled', {'enabled': value});
    if (accepted) enabled.value = value;
    return accepted;
  }
  static Future<bool> _request(String method, [Map<String, dynamic>? args]) async {
    if (authenticating) return false;
    authenticating = true;
    try { return await channel.invokeMethod<bool>(method, args) ?? false; }
    finally { authenticating = false; }
  }
}
