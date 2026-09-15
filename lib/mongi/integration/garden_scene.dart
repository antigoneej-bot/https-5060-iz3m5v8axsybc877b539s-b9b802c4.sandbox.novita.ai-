import 'package:flutter/material.dart';
import '../../models/shadow_cat.dart';
import '../models/seed.dart';
import '../models/garden_decoration.dart';
import 'mongi_garden_data.dart';

/// Visual garden only: never reads journals or private plant memories.
class GardenScene extends StatelessWidget {
  final MongiGardenData data;
  final List<ShadowCat> cats;
  const GardenScene({super.key, required this.data, required this.cats});
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(24),
    child: SizedBox(
      height: 340,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/mongi/images/garden_scene_bg.png',
            fit: BoxFit.cover,
          ),
          for (final seed in SeedType.all)
            if ((data.seeds[seed.id] ?? 0) > 0)
              Align(
                alignment: seed.sceneAnchor,
                child: Tooltip(
                  message: '${seed.label} · ${data.seeds[seed.id]}번 돌봄',
                  child: Text(
                    seed.emojiForCount(data.seeds[seed.id]!),
                    style: const TextStyle(fontSize: 48),
                  ),
                ),
              ),
          for (final decoration in GardenDecoration.all)
            if (data.placed.contains(decoration.id))
              Align(
                alignment: decoration.sceneAnchor,
                child: Tooltip(
                  message: decoration.label,
                  child: Text(
                    decoration.emoji,
                    style: TextStyle(fontSize: 32 * decoration.sceneScale),
                  ),
                ),
              ),
          if (cats.isEmpty)
            const Align(
              alignment: Alignment(0, 0.7),
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('만난 고양이들이 여기에 모여요.'),
                ),
              ),
            ),
          Align(
            alignment: const Alignment(0, 0.75),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: cats
                    .take(6)
                    .map(
                      (cat) => Tooltip(
                        message: cat.nameKr,
                        child: ClipOval(
                          child: Image.asset(
                            cat.imageAsset,
                            width: 42,
                            height: 42,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
