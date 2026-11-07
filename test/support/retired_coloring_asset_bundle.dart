import 'dart:io';
import 'package:flutter/services.dart';

/// Reads the original PNG for legacy drawing/persistence regressions without
/// shipping that retired template in APK/AAB assets. Other assets use Flutter.
class RetiredColoringAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    if (key != 'assets/coloring/love_cat.png') return rootBundle.load(key);
    final bytes = await File(key).readAsBytes();
    return ByteData.sublistView(bytes);
  }
}
