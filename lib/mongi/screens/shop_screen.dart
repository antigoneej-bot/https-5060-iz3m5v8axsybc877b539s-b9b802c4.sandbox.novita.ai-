import '../../theme.dart' show AppColors;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/gen/app_localizations.dart';
import '../providers/garden_provider.dart';
import '../widgets/garden_decoration_sheet.dart';
import '../widgets/light_essence_shop_sheet.dart';
import '../widgets/mongi_care_sheet.dart';
import '../widgets/power_charm_shop_sheet.dart';
import 'mind_box_screen.dart';
import 'season_pass_screen.dart';

/// "상점" 허브 화면 - 지금까지 여기저기(홈 화면 상단 칩, 게임 화면, 정원
/// 화면)에 흩어져 있던 구매 관련 진입점들을 한 곳에 모아서 보여준다.
///
/// 실제 구매 로직/화면은 전부 기존 위젯(GardenDecorationSheet,
/// MongiCareSheet, PowerCharmShopSheet, LightEssenceShopSheet,
/// MindBoxScreen, SeasonPassScreen)을 그대로 재사용한다 - 이 화면은 순수하게
/// "어디서 무엇을 살 수 있는지"를 보여주는 목차/진입점 역할만 한다.
class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final garden = context.watch<GardenProvider>();
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        backgroundColor: AppColors.bg0,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l10n.shopTitle,
          style: const TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 4),
                    Text(
                      '${garden.lightEssence}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                        color: Color(0xFF8A6D1F),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _sectionLabel(l10n.shopSectionCurrency),
          _shopCard(
            emoji: '💡',
            iconBg: const Color(0xFFFFE9A3),
            title: '빛의 정수 모으기',
            subtitle: '현금 충전 없이 플레이 보상으로 모아요',
            onTap: () => LightEssenceShopSheet.show(context),
          ),
          const SizedBox(height: 20),
          _sectionLabel(l10n.shopSectionConsumables),
          _shopCard(
            emoji: '🎁',
            iconBg: const Color(0xFFFFE0A3),
            title: l10n.shopMindBoxTitle,
            subtitle: l10n.shopMindBoxSubtitle,
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const MindBoxScreen())),
          ),
          _shopCard(
            emoji: '⚡',
            iconBg: const Color(0xFFFFC93C),
            title: l10n.shopPowerCharmTitle,
            subtitle: l10n.shopPowerCharmSubtitle(garden.powerCharmCount),
            onTap: () => PowerCharmShopSheet.show(context),
          ),
          _shopCard(
            emoji: '🍚',
            iconBg: const Color(0xFFB8E0C0),
            title: l10n.shopMongiCareTitle,
            subtitle: l10n.shopMongiCareSubtitle,
            onTap: () => MongiCareSheet.show(context),
          ),
          _shopCard(
            emoji: '🌷',
            iconBg: const Color(0xFFD9F0DC),
            title: l10n.shopGardenDecoTitle,
            subtitle: l10n.shopGardenDecoSubtitle,
            onTap: () => showGardenDecorationSheet(context),
          ),
          const SizedBox(height: 20),
          _sectionLabel(l10n.shopSectionSeason),
          _shopCard(
            emoji: '🌟',
            iconBg: const Color(0xFFE8DBFF),
            title: l10n.shopSeasonPassTitle,
            subtitle: l10n.shopSeasonPassSubtitle,
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SeasonPassScreen())),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w800,
          color: AppColors.inkSoft,
        ),
      ),
    );
  }

  Widget _shopCard({
    required String emoji,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Color.alphaBlend(iconBg.withValues(alpha: 0.22), AppColors.bg1),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(emoji, style: const TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.inkSoft,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFFCBBFAF),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
