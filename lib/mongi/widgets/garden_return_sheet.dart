import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/garden_return_store.dart';
import '../providers/garden_provider.dart';
import '../screens/garden_village_screen.dart';
import 'garden_keepsake_sheets.dart';
import 'public_garden_update_card.dart';

Future<void> showGardenReturnSheet(
  BuildContext context,
  GardenReturnSummary? summary,
) {
  // A sheet can outlive the account that opened it. Watch the account for the
  // whole sheet, not only its inbox badge, so a prior owner's recap disappears
  // immediately on sign-out or account switch.
  final openedOwner = context.read<GardenProvider>().publicGardenAccount;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => Consumer<GardenProvider>(
      builder: (_, garden, _) {
        final currentSummary = garden.publicGardenAccount == openedOwner
            ? summary
            : null;
        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    currentSummary?.greeting ?? '정원에 남은 작은 소식',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  Text(currentSummary?.description ?? '지금의 정원에서 잠깐 쉬어가도 괜찮아요.'),
                  const SizedBox(height: 16),
                  ListenableBuilder(
                    listenable: GardenReturnStore.instance,
                    builder: (_, _) {
                      final unseen = GardenReturnStore.instance.hasUnseen(
                        garden.publicGardenAccount,
                      );
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          unseen
                              ? Icons.mark_email_unread_outlined
                              : Icons.mail_outline,
                        ),
                        title: Text(unseen ? '확인하지 않은 마음이 있어요' : '받은 마음 살펴보기'),
                        subtitle: const Text('새 소식은 앱에서 연결을 확인한 뒤 표시돼요.'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.pop(sheetContext);
                          if (!context.mounted) return;
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  const GardenVillageScreen(initialTab: 2),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.park_outlined),
                    title: const Text('기억의 나무 다시 보기'),
                    subtitle: const Text('마음을 남겼던 날들을 천천히 돌아봐요.'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      if (context.mounted) showMemoryTree(context);
                    },
                  ),
                  const PublicGardenUpdateCard(),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

class ReceivedHeartIcon extends StatelessWidget {
  final String? owner;
  final double size;
  const ReceivedHeartIcon({super.key, required this.owner, this.size = 18});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: GardenReturnStore.instance,
    builder: (_, _) => Badge(
      isLabelVisible: GardenReturnStore.instance.hasUnseen(owner),
      child: Icon(Icons.mail_outline, size: size),
    ),
  );
}
