import '../integration/mongi_garden_store.dart';
import '../../utils/garden_record_progress.dart';
import '../integration/garden_bloom_sync.dart';
import '../screens/garden_bloom_news_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/letter_entry.dart';
import '../../services/storage_service.dart';
import '../integration/cheer_flower_store.dart';
import '../models/garden_life.dart';
import '../models/garden_gifts.dart';
import 'garden_gift_art.dart';
import '../screens/public_garden_inbox_screen.dart';
import '../l10n/gen/app_localizations.dart';
import '../l10n/public_cheer_l10n.dart';

String? currentGardenOwner() =>
    Firebase.apps.isEmpty ? null : FirebaseAuth.instance.currentUser?.uid;

Future<void> showMemoryTree(BuildContext context) async {
  // Deleted originals disappear; private growth receipts remain.
  final letters = StorageService.getAllLetters();
  final days = gardenMemoryDays(letters);
  final growthDays = gardenRecordDays(
    MongiGardenStore.instance.value.recordDays,
    letters.map((entry) => entry.date),
    now: DateTime.now(),
  ).length;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(sheetContext).height * .7,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text('기억의 나무', style: TextStyle(fontSize: 22)),
                  const SizedBox(height: 6),
                  Text(gardenRecordMessage(growthDays)),
                  const Text(
                    '기쁜 날도 힘든 날도 모두 자라요. 기록을 쉬거나 편지를 삭제해도 성장은 남아요. 편지는 나만 볼 수 있어요.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            if (days.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('지금 보관 중인 편지는 없어요. 한 줄부터 남겨도 괜찮아요.'),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: days.length,
                itemBuilder: (_, index) {
                  final day = days[index];
                  final entries = letters.where((l) {
                    final d = l.date.toLocal();
                    return d.year == day.year &&
                        d.month == day.month &&
                        d.day == day.day;
                  }).toList();
                  return ListTile(
                    leading: const Icon(Icons.local_florist_outlined),
                    title: Text(
                      '${day.year}.${day.month.toString().padLeft(2, '0')}.${day.day.toString().padLeft(2, '0')}',
                    ),
                    subtitle: Text('편지 ${entries.length}개'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _readLetters(sheetContext, entries),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _readLetters(BuildContext context, List<LetterEntry> letters) =>
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('그날의 내 마음'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final letter in letters)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: SelectableText(
                      letter.letterText.isEmpty
                          ? (letter.moodEmoji ?? '마음을 남긴 날')
                          : letter.letterText,
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );

Future<void> showCheerFlowers(
  BuildContext context,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (context) => SafeArea(
    child: SizedBox(
      height: MediaQuery.sizeOf(context).height * .7,
      child: ValueListenableBuilder<Map<String, CheerFlower>>(
        valueListenable: CheerFlowerStore.instance,
        builder: (context, _, _) {
          final owner = currentGardenOwner();
          final flowers = CheerFlowerStore.instance.forOwner(owner);
          return Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(18),
                child: Text('응원이 남긴 꽃', style: TextStyle(fontSize: 22)),
              ),
              TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const GardenBloomNewsScreen(),
                  ),
                ),
                icon: const Icon(Icons.mark_email_read_outlined),
                label: const Text('내가 건넨 꽃 소식'),
              ),
              TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const PublicGardenInboxScreen(),
                  ),
                ),
                icon: const Icon(Icons.mail_outline),
                label: const Text('받은 응원함 열기'),
              ),
              if (flowers.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    '받은 응원은 꽃으로 남길 수 있어요. 이모티콘은 하루 동안 머물고, 심은 꽃은 계속 남아요.',
                    textAlign: TextAlign.center,
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: flowers.length,
                  itemBuilder: (context, index) {
                    final flower = flowers[index];
                    return ListTile(
                      onTap: owner == null
                          ? null
                          : () => chooseFlower(context, owner, flower),
                      leading: SizedBox(
                        width: 52,
                        height: 52,
                        child: GardenFlowerArt(kind: flower.flowerKind),
                      ),
                      title: Text(
                        publicCheerOptionText(
                          AppLocalizations.of(context),
                          flower.messageIndex,
                        ),
                      ),
                      subtitle: Text(
                        flower.planted
                            ? '${_receivedOn(flower)}\n${gardenFlowerNames[flower.flowerKind]} · 눌러서 꽃 바꾸기${flower.bloomPending ? '\n꽃은 저장됐어요 · 꽃 소식은 연결되면 전달해요' : ''}'
                            : '${_receivedOn(flower)}\n${gardenFlowerNames[flower.flowerKind]} · 눌러서 꽃 고르기',
                      ),
                      trailing: flower.planted
                          ? const Icon(Icons.check)
                          : IconButton(
                              tooltip: '정원에 심기',
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: owner == null
                                  ? null
                                  : () async {
                                      try {
                                        await plantGardenFlower(
                                          owner,
                                          flower.id,
                                        );
                                      } catch (_) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                '꽃을 저장하지 못했어요. 다시 눌러 주세요.',
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    },
                            ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    ),
  ),
);

Future<void> chooseFlower(
  BuildContext context,
  String owner,
  CheerFlower flower,
) async {
  final picked = await showModalBottomSheet<String>(
    context: context,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Wrap(
          spacing: 10,
          children: gardenFlowerNames.entries
              .map(
                (e) => SizedBox(
                  width: 90,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: GardenFlowerArt(kind: e.key),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, e.key),
                        child: Text(e.value),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    ),
  );
  if (picked == null) return;
  try {
    await plantGardenFlower(owner, flower.id, flowerKind: picked);
  } catch (_) {
    if (context.mounted)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('꽃을 저장하지 못했어요. 다시 눌러 주세요.')));
  }
}

String _receivedOn(CheerFlower flower) {
  final day = flower.createdAt?.toLocal();
  return day == null
      ? '나에게 도착한 응원'
      : '${day.year}.${day.month}.${day.day}에 도착한 응원';
}
