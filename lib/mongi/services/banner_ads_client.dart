import 'package:flutter/widgets.dart';

/// Native boundary, injectable so subscription/lifecycle races can be tested
/// without serving live advertisements.
abstract interface class GardenBannerAd {
  int get width;
  int get height;
  Widget buildView();
  Future<void> load();
  Future<void> dispose();
}

abstract interface class BannerAdsClient {
  bool get configured;
  Future<bool> allowed();
  Future<GardenBannerAd?> createBannerAd({
    required int width,
    required void Function() onLoaded,
    required void Function() onFailed,
    required bool Function() placementActive,
  });
}
