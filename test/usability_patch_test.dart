import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/mongi/models/garden_layout.dart';
import 'package:flutter_app/mongi/models/garden_decoration.dart';
import 'package:flutter_app/mongi/integration/mongi_garden_data.dart';
import 'package:flutter_app/screens/emotion_archive_screen.dart';
import 'package:flutter_app/services/unified_emotion_summary_service.dart';
import 'package:flutter_app/data/shadow_cats_data.dart';
import 'package:flutter_app/widgets/pastel_garden_shell.dart';
import 'package:flutter_app/models/companion_coat.dart';

void main() {
  test('moving changes only requested coordinate, not growth or inventory', () {
    final layout = GardenLayout(
      spaces: 3,
      positions: const {
        'seed:pine': Offset(.4, .7),
        'seed:cherry': Offset(.7, .7),
      },
    );
    final data = MongiGardenData(
      seeds: const {'pine': 7, 'cherry': 3},
      seedTokens: 5,
    );
    final before = data.toJson().toString();
    final next = layout.move('seed:pine', const Offset(.5, .85), [
      'seed:pine',
      'seed:cherry',
    ]);
    expect(next.positions['seed:pine'], const Offset(.5, .85));
    expect(next.positions['seed:cherry'], layout.positions['seed:cherry']);
    expect(layout.positions['seed:pine'], const Offset(.4, .7));
    expect(data.toJson().toString(), before);
    expect(
      () => layout.move('seed:pine', const Offset(.7, .7), [
        'seed:pine',
        'seed:cherry',
      ]),
      throwsStateError,
    );
  });
  test(
    'all decoration defaults fit expanded land without overlapping',
    () {
      final layout = GardenLayout(spaces: 3);
      expect(GardenDecoration.all.length, 24);
      for (final id in GardenLayout.itemIds) {
        expect(
          layout.placementError(id, layout.position(id), GardenLayout.itemIds),
          isNull,
          reason: id,
        );
      }
    },
  );
  test('daily care and record share allowance without duplicate payment', () {
    final day = DateTime(2026, 11, 2);
    final first = MongiGardenData()
        .claimCareDay(day)
        .claimRecordDay(day)
        .claimCareDay(day);
    expect(first.seedTokens, 1);
    expect(first.essence, 20);
    final restored = MongiGardenData.fromJson(
      first.toJson(),
    ).claimRecordDay(day);
    expect(restored.seedTokens, 1);
    expect(restored.essence, 20);
  });
  test(
    'letter records use the exact saved cat, unknown records invent no cat',
    () {
      UnifiedEmotionRecord record(String id) => UnifiedEmotionRecord(
        id: 'letter:$id',
        source: EmotionRecordSource.letter,
        date: DateTime(2026, 11, 2),
        hasTime: true,
        emotionId: id,
        label: id,
        emoji: '',
        color: Colors.green,
        background: Colors.white,
        note: '기록',
      );
      for (final cat in shadowCats) {
        expect(emotionRecordCatAsset(record(cat.id)), cat.imageAsset);
      }
      expect(emotionRecordCatAsset(record('unknown-legacy')), isNull);
    },
  );
  for (final size in [
    const Size(320, 640),
    const Size(390, 844),
    const Size(844, 390),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('all four pages swipe forward and backward $size text $scale', (
        t,
      ) async {
        t.view.physicalSize = size;
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        final selected = <int>[];
        await t.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: PastelGardenShell(
              coat: CompanionCoat.ginger,
              onAction: (_) {},
              onCoat: (_) {},
              motionEnabled: false,
              companionAutomaticBehavior: false,
              gardenPreview: const SizedBox(),
              actualGarden: const ColoredBox(color: Colors.green),
              onPageSelected: selected.add,
            ),
          ),
        );
        await t.pumpAndSettle();
        final pager = find.byKey(const Key('main-pastel-pager'));
        final rect = t.getRect(pager);
        // The search field owns horizontal text-selection drags. Exercise page
        // swipes from the page padding, with the entire gesture inside the viewport.
        Future<void> swipe(bool forward) async {
          await t.dragFrom(
            Offset(forward ? rect.right - 8 : rect.left + 8, rect.center.dy),
            Offset((forward ? -1 : 1) * rect.width * .75, 0),
          );
          await t.pumpAndSettle();
        }

        for (var i = 0; i < 3; i++) {
          await swipe(true);
        }
        expect(selected, [1, 2, 3]);
        for (var i = 0; i < 3; i++) {
          await swipe(false);
        }
        expect(selected, [1, 2, 3, 2, 1, 0]);
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
      });
    }
  }
}
