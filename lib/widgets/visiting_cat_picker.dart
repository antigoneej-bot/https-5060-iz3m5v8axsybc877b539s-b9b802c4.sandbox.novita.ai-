import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cat_visit.dart';
import '../models/companion_coat.dart';
import '../providers/cat_care_provider.dart';
import 'companion_coat_art.dart';
import 'companion_coat_preview.dart';

Future<VisitingCat?> pickVisitingCat(
  BuildContext context, {
  String title = '함께 갈 고양이',
}) async {
  final care = context.read<CatCareProvider>();
  await care.loadJourney();
  if (!context.mounted) return null;
  if (!care.journeyReady) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(care.journeyError ?? '고양이 기록을 다시 확인해 주세요.')),
    );
    return null;
  }
  return showModalBottomSheet<VisitingCat>(
    context: context,
    isScrollControlled: true,
    builder: (sheet) => SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(sheet).height * .65,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Text('털색·성장 모습·고양이 이름만 이웃과 나눠요. 마음 기록은 공유하지 않아요.'),
            for (final member in care.journey.residents.entries)
              Builder(
                builder: (context) {
                  final stage = member.value >= 90
                      ? 3
                      : member.value >= 30
                      ? 2
                      : member.value >= 7
                      ? 1
                      : 0;
                  final cat = VisitingCat(
                    coat: member.key,
                    stage: care.journey.keepBaby ? 0 : stage,
                    name: String.fromCharCodes(
                      (member.key == (care.journey.coat ?? CompanionCoat.ginger)
                              ? care.displayName
                              : member.key.label)
                          .runes
                          .take(20),
                    ),
                  );
                  return ListTile(
                    key: ValueKey('visit-cat-${member.key.name}'),
                    leading: SizedBox(
                      width: 64,
                      height: 64,
                      child: CompanionCoatScope(
                        useLocalChoice: true,
                        coat: cat.coat,
                        growthStage: cat.stage,
                        child: CompanionCoatPreview(coat: cat.coat),
                      ),
                    ),
                    title: Text(cat.name),
                    subtitle: Text(
                      '${member.key.label} · ${const ['아기', '자라는 중', '든든한 고양이', '성묘'][stage]}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.pop(sheet, cat),
                  );
                },
              ),
          ],
        ),
      ),
    ),
  );
}
