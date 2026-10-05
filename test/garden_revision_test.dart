import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/mongi/integration/mongi_garden_data.dart';
import 'package:flutter_app/mongi/models/public_garden.dart';
import 'package:flutter_app/mongi/models/garden_layout.dart';
import 'package:flutter_app/mongi/widgets/garden_world_view.dart';
import 'package:flutter_app/widgets/emotion_cat_video.dart';

void main() {
  test('recover missing days once while respecting earlier care rewards', () {
    final d = DateTime(2026, 10, 1), next = DateTime(2026, 10, 2);
    final original = MongiGardenData().claimCareDay(d);
    final recovered = original.reconcileRecordDays([d, d, next]);
    expect(recovered.seedTokens, 2);
    expect(recovered.essence, 40);
    expect(recovered.recordDays.length, 2);
    expect(
      identical(recovered.reconcileRecordDays([d, next]), recovered),
      isTrue,
    );
  });
  test('public garden preserves layout, supports old data without layout', () {
    final data = {
      'gardenId': 'test',
      'seedCounts': {'pine': 3},
      'equippedDecorationIds': ['bench'],
      'treeStageIndex': 1,
    };
    expect(PublicGarden.fromJson(data).layout, isNull);
    final garden = PublicGarden.fromJson({
      ...data,
      'layout': GardenLayout(
        spaces: 3,
        positions: {'seed:pine': const Offset(.2, .6)},
      ).toJson(),
    });
    expect(garden.layout!.spaces, 3);
    expect(garden.layout!.position('seed:pine'), const Offset(.2, .6));
  });
  testWidgets('visitors can view but cannot edit or open private memories', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GardenWorldView(
            readOnly: true,
            layout: GardenLayout(),
            seeds: const {'pine': 3},
            decorations: const [],
            onMove: (_, _) async {
              calls++;
            },
            onMemory: (_) {
              calls++;
            },
            onPlant: () {
              calls++;
            },
            onDecorate: () {
              calls++;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('배치 모드'), findsNothing);
    expect(find.text('씨앗 심기'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('world-item-seed:pine')));
    await tester.pump();
    expect(calls, 0);
    expect(tester.takeException(), isNull);
  });
  testWidgets('video cards show posters without auto-initializing players', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 150,
            height: 150,
            child: EmotionCatVideo(
              imageAsset: 'assets/cards36/cat_02.png',
              videoAsset: 'assets/cards36/videos/cat_02_loop.mp4',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('움직임 보기'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
