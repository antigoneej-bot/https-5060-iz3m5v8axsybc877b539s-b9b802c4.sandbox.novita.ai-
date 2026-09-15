import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ad_service.dart';

/// 홈 화면 등에 상시 배치하는 작은 배너 광고 슬롯.
///
/// 광고가 아직 로드되지 않았거나(웹/로딩 실패 포함) 로드에 실패한 동안에는
/// 화면에 아무 공간도 차지하지 않는다(SizedBox.shrink) - 로딩 중 빈 회색
/// 박스가 힐링 게임의 따뜻한 톤을 방해하지 않도록 하기 위함이다.
class BannerAdSlot extends StatefulWidget {
  const BannerAdSlot({super.key});

  @override
  State<BannerAdSlot> createState() => _BannerAdSlotState();
}

class _BannerAdSlotState extends State<BannerAdSlot> {
  BannerAd? _bannerAd;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _bannerAd = AdService.instance.createBannerAd(
      onLoaded: () {
        if (mounted) setState(() => _loaded = true);
      },
    );
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _bannerAd;
    if (ad == null || !_loaded) return const SizedBox.shrink();
    return Container(
      alignment: Alignment.center,
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      margin: const EdgeInsets.only(top: 6),
      child: AdWidget(ad: ad),
    );
  }
}
