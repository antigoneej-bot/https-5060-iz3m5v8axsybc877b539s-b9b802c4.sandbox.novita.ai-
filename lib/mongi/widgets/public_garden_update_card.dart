import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../integration/cheer_flower_store.dart';
import '../integration/garden_layout_store.dart';
import '../integration/mongi_garden_store.dart';
import '../providers/garden_provider.dart';
import '../screens/public_garden_settings_screen.dart';

/// A quiet entry beside garden tools. Opening it is explicit: this widget never
/// starts a network request or publishes a changed garden on its own.
class PublicGardenUpdateCard extends StatelessWidget {
  const PublicGardenUpdateCard({super.key, this.onOpen});
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final garden = context.watch<GardenProvider>();
    return AnimatedBuilder(
      animation: Listenable.merge([
        GardenLayoutStore.instance,
        MongiGardenStore.instance,
        CheerFlowerStore.instance,
      ]),
      builder: (context, _) {
        final changed = garden.hasUnpublishedGardenChanges;
        final title = garden.isGardenPublished && changed == true
            ? '이웃에게 보여줄 새 모습이 있어요'
            : '정원 공개와 업데이트';
        final subtitle = garden.gardenPublication == false
            ? '지금은 나만 보는 정원이에요.'
            : garden.isGardenPublished && changed == false
            ? '이웃이 지금의 정원 모습을 보고 있어요.'
            : garden.isGardenPublished && changed == true
            ? '가꾼 정원 모습을 확인하고 업데이트해 주세요.'
            : '공개 범위와 마지막으로 저장한 모습을 확인해요.';
        return Card(
          child: ListTile(
            key: const Key('public-garden-update-entry'),
            leading: Icon(
              changed == true && garden.isGardenPublished
                  ? Icons.cloud_upload_outlined
                  : Icons.public_outlined,
            ),
            title: Text(title),
            subtitle: Text(subtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap:
                onOpen ??
                () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => const PublicGardenSettingsScreen(),
                  ),
                ),
          ),
        );
      },
    );
  }
}
