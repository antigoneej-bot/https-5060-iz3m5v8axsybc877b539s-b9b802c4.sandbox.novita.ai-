import 'dart:async';
import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'cloud_service.dart';
import 'notification_service.dart';
import 'garden_bell.dart';

/// Device opt-in is account-specific. No prompt is shown at startup.
class GardenPushService with WidgetsBindingObserver {
  GardenPushService._();
  static final instance = GardenPushService._();
  final changes = ValueNotifier<int>(0);
  bool _started = false;
  final _seen = <String>{};
  Future<void> _queue = Future.value();
  bool get supported =>
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android &&
      CloudService.enabled;
  Future<T> _serial<T>(Future<T> Function() operation) {
    final next = _queue.then((_) => operation());
    _queue = next.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return next;
  }

  String? get _uid => CloudService.currentUser?.uid;
  Future<Map<String, bool>> settings() async {
    final uid = _uid;
    final prefs = await SharedPreferences.getInstance();
    return {
      for (final kind in ['social', 'booking'])
        kind: uid != null && prefs.getBool('push_${uid}_$kind') == true,
    };
  }

  Future<void> start() async {
    if (!supported || _started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    FirebaseAuth.instance.authStateChanges().listen((_) {
      unawaited(sync().catchError((Object _) {}));
      changes.value++;
    });
    FirebaseMessaging.instance.onTokenRefresh.listen(
      (_) => unawaited(sync().catchError((Object _) {})),
    );
    FirebaseMessaging.onMessageOpenedApp.listen((m) => unawaited(_open(m)));
    FirebaseMessaging.onMessage.listen((m) => unawaited(_foreground(m)));
    final first = await FirebaseMessaging.instance.getInitialMessage();
    if (first != null) await _open(first);
    await sync();
  }

  Future<bool> _belongs(RemoteMessage message) async {
    final uid = _uid;
    if (uid == null || !['social', 'booking'].contains(message.data['kind']))
      return false;
    final digest = (await Sha256().hash(
      utf8.encode(uid),
    )).bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return _uid == uid && message.data['owner'] == digest;
  }

  Future<void> _open(RemoteMessage message) async {
    if (!await _belongs(message)) return;
    NotificationService().openGardenUpdate(message.data['kind'] as String);
  }

  Future<void> _foreground(RemoteMessage message) async {
    if (!await _belongs(message)) return;
    final kind = message.data['kind'] as String;
    if ((await settings())[kind] != true) return;
    final id = message.messageId ?? message.data['notice']?.toString();
    if (id != null && !_seen.add(id)) return;
    if (_seen.length > 200) _seen.remove(_seen.first);
    await NotificationService().showGardenUpdate(kind);
  }

  Future<void> setEnabled(String kind, bool enabled) => _serial(() async {
    if (!supported || !['social', 'booking'].contains(kind))
      throw StateError('Android 앱에서 이용해 주세요.');
    final uid = _uid;
    if (uid == null) throw const CloudException('authentication-required');
    if (enabled) {
      final permission = await FirebaseMessaging.instance.requestPermission();
      if (permission.authorizationStatus != AuthorizationStatus.authorized)
        throw StateError('휴대전화 설정에서 마음냥 알림을 허용해 주세요.');
    }
    if (_uid != uid) throw const CloudException('account-changed');
    final prefs = await SharedPreferences.getInstance();
    final next = await settings()
      ..[kind] = enabled;
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) throw StateError('알림 연결을 준비하지 못했어요. 다시 시도해 주세요.');
    await CloudService.call('setPushDevice', {
      'token': token,
      'enabled': next.values.any((v) => v),
      ...next,
      'bellSound': await GardenBell.enabled(),
    }, uid);
    if (_uid != uid) throw const CloudException('account-changed');
    await prefs.setBool('push_${uid}_$kind', enabled);
    await prefs.setString('push_device_owner', uid);
    await prefs.setString('push_device_token', token);
    changes.value++;
  });
  Future<void> sync() => _serial(() async {
    if (!supported) return;
    final uid = _uid;
    final prefs = await SharedPreferences.getInstance();
    final old = prefs.getString('push_device_owner');
    if (old != null && old != uid) {
      // Delete rather than reuse the previous account's FCM registration.
      await FirebaseMessaging.instance.deleteToken();
      await prefs.remove('push_device_token');
      await prefs.remove('push_device_owner');
    }
    if (uid == null) return;
    final chosen = await settings();
    final permission = await FirebaseMessaging.instance
        .getNotificationSettings();
    final allowed =
        permission.authorizationStatus == AuthorizationStatus.authorized;
    final token = allowed && chosen.values.any((v) => v)
        ? await FirebaseMessaging.instance.getToken()
        : prefs.getString('push_device_token');
    if (token == null || _uid != uid) return;
    await CloudService.call('setPushDevice', {
      'token': token,
      'enabled': allowed && chosen.values.any((v) => v),
      ...chosen,
      'bellSound': await GardenBell.enabled(),
    }, uid);
    if (_uid != uid) return;
    await prefs.setString('push_device_owner', uid);
    await prefs.setString('push_device_token', token);
    changes.value++;
  });
  Future<void> beforeSignOut() => _serial(() async {
    if (!supported) return;
    final uid = _uid;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('push_device_token');
    bool revoked = token == null;
    if (uid != null && token != null) {
      try {
        await CloudService.call('setPushDevice', {
          'token': token,
          'enabled': false,
        }, uid);
        revoked = true;
      } catch (_) {}
    }
    try {
      await FirebaseMessaging.instance.deleteToken();
      revoked = true;
    } catch (_) {}
    if (!revoked) throw StateError('알림 연결을 해제하지 못했어요. 연결을 확인한 뒤 로그아웃해 주세요.');
    await prefs.remove('push_device_token');
    await prefs.remove('push_device_owner');
  });
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed)
      unawaited(sync().catchError((Object _) {}));
  }
}
