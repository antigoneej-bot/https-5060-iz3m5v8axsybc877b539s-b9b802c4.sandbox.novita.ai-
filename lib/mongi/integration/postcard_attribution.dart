import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/analytics_service.dart';
import 'postcard_link.dart';

/// Aggregate Play campaign only. No sender identifier or journal data.
class PostcardAttribution {
  static bool _running = false;
  static Future<void> check() async {
    if (_running ||
        kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android ||
        gardenPostcardLink(
              const String.fromEnvironment('GARDEN_PUBLIC_PLAY_URL'),
            ) ==
            null) {
      return;
    }
    _running = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      const key =
          'garden_postcard_attribution_checked_v1'; // intentionally not backed up
      if (prefs.getBool(key) == true) return;
      final source = await const MethodChannel(
        'garden/install_referrer',
      ).invokeMethod<String>('read').timeout(const Duration(seconds: 8));
      if (source != 'garden_postcard' && source != 'other') return;
      if (!await prefs.setBool(key, true)) return;
      if (source == 'garden_postcard') {
        await AnalyticsService().logEvent('garden_postcard_install_open');
      }
    } catch (_) {
      /* retry at next launch; never block the app */
    } finally {
      _running = false;
    }
  }
}
