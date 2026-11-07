import 'package:flutter/material.dart';

class LightEssenceShopSheet extends StatelessWidget {
  const LightEssenceShopSheet({super.key});
  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    builder: (_) => const LightEssenceShopSheet(),
  );
  @override
  Widget build(BuildContext context) => const SafeArea(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome),
          SizedBox(height: 12),
          Text('빛의 정수는 플레이로 모아요'),
          SizedBox(height: 8),
          Text('현금 충전 없이 게임과 기존 활동 보상으로 모을 수 있어요. 모아둔 재화와 아이템은 계속 보관돼요.'),
        ],
      ),
    ),
  );
}
