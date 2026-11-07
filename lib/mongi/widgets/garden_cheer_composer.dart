import 'package:flutter/material.dart';
import '../models/garden_gifts.dart';
import '../models/public_garden.dart';
import '../l10n/gen/app_localizations.dart';
import '../l10n/public_cheer_l10n.dart';
import 'garden_gift_art.dart';

Future<({int message, String flower, String? reaction})?> composeGardenCheer(
  BuildContext context, {
  bool includeFlower = true,
}) {
  var message = 0;
  var flower = 'daisy';
  String? reaction = 'heart';
  return showModalBottomSheet<({int message, String flower, String? reaction})>(
    context: context,
    isScrollControlled: true,
    builder: (context) => StatefulBuilder(
      builder: (context, update) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .78,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        includeFlower ? '오늘의 꽃 선물하기' : '정원에 응원 남기기',
                        style: const TextStyle(fontSize: 22),
                      ),
                      const SizedBox(height: 16),
                      if (includeFlower) ...[
                        const Text(
                          '상대가 원하는 때 정원에 심을 수 있어요. 꽃 선물은 같은 이웃에게 하루 한 번 보낼 수 있어요.',
                        ),
                        const SizedBox(height: 12),
                        const Text('선물할 꽃'),
                        Wrap(
                          spacing: 8,
                          children: gardenFlowerNames.entries
                              .map(
                                (f) => SizedBox(
                                  width: 90,
                                  child: Column(
                                    children: [
                                      SizedBox(
                                        width: 74,
                                        height: 74,
                                        child: GardenFlowerArt(kind: f.key),
                                      ),
                                      ChoiceChip(
                                        label: Text(f.value),
                                        selected: flower == f.key,
                                        onSelected: (_) =>
                                            update(() => flower = f.key),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (!includeFlower)
                        const Text('같은 정원에 하루 한 번 응원을 남길 수 있어요.'),
                      const Text('24시간 머무는 응원'),
                      Wrap(
                        spacing: 8,
                        children: [
                          if (includeFlower)
                            ChoiceChip(
                              label: const Text('없음'),
                              selected: reaction == null,
                              onSelected: (_) => update(() => reaction = null),
                            ),
                          ...gardenReactionNames.entries.map(
                            (r) => ChoiceChip(
                              label: Text(
                                '${gardenReactionEmoji[r.key]} ${r.value}',
                              ),
                              selected: reaction == r.key,
                              onSelected: (_) => update(() => reaction = r.key),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text('함께 전할 한마디'),
                      ...List.generate(
                        kPublicCheerMessageCount,
                        (i) => CheckboxListTile(
                          value: i == message,
                          onChanged: (_) => update(() => message = i),
                          title: Text(
                            publicCheerOptionText(
                              AppLocalizations.of(context),
                              i,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, (
                    message: message,
                    flower: flower,
                    reaction: reaction,
                  )),
                  child: Text(includeFlower ? '꽃 선물하기' : '응원 보내기'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
