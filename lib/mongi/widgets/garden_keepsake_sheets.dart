import '../../screens/keepsake_forest_screen.dart';
import '../integration/mongi_garden_store.dart';
import '../integration/plant_memory_store.dart';
import '../integration/plant_memory_editor.dart';
import '../models/seed.dart';
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

Future<void> showMemoryTree(BuildContext context) => Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => const KeepsakeForestScreen()));

Future<void> showLegacyGardenLetters(BuildContext context) async {
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
                  const Text('지난 편지 기록', style: TextStyle(fontSize: 22)),
                  OutlinedButton.icon(
                    onPressed: () => showPlantMemoryManager(sheetContext),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('내 나무 · 글 수정·삭제'),
                  ),
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

/// A visible management entrance, including tiny trees that are hard to tap.
Future<void> showPlantMemoryManager(BuildContext context) async {
  try {
    await PlantMemoryStore.instance.reload();
    await MongiGardenStore.instance.reload();
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheet) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(sheet).height * .7,
          child: ValueListenableBuilder<MongiGardenData>(
            valueListenable: MongiGardenStore.instance,
            builder: (_, data, _) =>
                ValueListenableBuilder<Map<String, PlantMemory>>(
                  valueListenable: PlantMemoryStore.instance,
                  builder: (_, memories, _) {
                    final plants = SeedType.all
                        .where((s) => (data.seeds[s.id] ?? 0) > 0)
                        .toList();
                    return ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        const Text(
                          '내 나무와 추억 관리',
                          style: TextStyle(fontSize: 22),
                        ),
                        const SizedBox(height: 8),
                        const Text('식물을 골라 이름·기념일·글을 수정하거나 삭제할 수 있어요.'),
                        if (plants.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Text('아직 심은 식물이 없어요.'),
                          ),
                        for (final plant in plants)
                          ListTile(
                            leading: Text(
                              plant.emojiForCount(data.seeds[plant.id]!),
                            ),
                            title: Text(
                              memories[plant.id]?.name.isNotEmpty == true
                                  ? memories[plant.id]!.name
                                  : plant.label,
                            ),
                            subtitle: Text(
                              '${plant.label} · 추억 ${memories[plant.id]?.timeline.length ?? 0}개',
                            ),
                            trailing: const Icon(Icons.edit_outlined),
                            onTap: () => showDialog<void>(
                              context: sheet,
                              barrierDismissible: false,
                              builder: (_) => PlantMemoryEditor(plant: plant),
                            ),
                          ),
                      ],
                    );
                  },
                ),
          ),
        ),
      ),
    );
  } catch (_) {
    if (context.mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('나무와 추억을 불러오지 못했어요. 다시 시도해 주세요.')),
      );
  }
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
          final flowers = CheerFlowerStore.instance
              .forOwner(owner)
              .where((f) => f.hasFlower)
              .toList();
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
                            ? '${_receivedOn(flower)}\n${gardenFlowerNames[flower.flowerKind]} · 정원에 심은 꽃${flower.bloomPending ? '\n연결되면 심기 기록을 확인해요' : ''}'
                            : '${_receivedOn(flower)}\n${gardenFlowerNames[flower.flowerKind]} · 눌러서 선물 보기',
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
                                                '꽃을 심지 못했어요. 연결 상태와 받은 마음을 확인한 뒤 다시 시도해 주세요.',
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
  final plant = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: SizedBox(
                width: 100,
                height: 100,
                child: GardenFlowerArt(kind: flower.flowerKind),
              ),
            ),
            Text(
              gardenFlowerNames[flower.flowerKind] ?? '응원 꽃',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 12),
            Text(_receivedOn(flower), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              publicCheerOptionText(
                AppLocalizations.of(context),
                flower.messageIndex,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (!flower.planted)
              FilledButton.icon(
                onPressed: () => Navigator.pop(sheetContext, true),
                icon: const Icon(Icons.local_florist_outlined),
                label: const Text('이 꽃을 정원에 심기'),
              )
            else
              const Text('정원에 심은 꽃이에요.', textAlign: TextAlign.center),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(sheetContext),
              child: const Text('닫기'),
            ),
          ],
        ),
      ),
    ),
  );
  if (plant != true) return;
  try {
    await plantGardenFlower(owner, flower.id);
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('꽃을 심지 못했어요. 연결 상태와 받은 마음을 확인한 뒤 다시 시도해 주세요.'),
        ),
      );
    }
  }
}

String _receivedOn(CheerFlower flower) {
  final day = flower.createdAt?.toLocal();
  final from = flower.senderNickname?.trim();
  final sender = from == null || from.isEmpty ? '이웃이 전한 마음' : '$from님이 전한 마음';
  return day == null
      ? sender
      : '$sender\n${day.year}.${day.month}.${day.day}에 받은 선물';
}
