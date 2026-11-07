import 'package:flutter/material.dart';
import 'garden_grounded_art.dart';

/// One cell from the generated botanical / walking atlases. Keeps source alpha.
class GardenAtlasArt extends StatelessWidget {
  final String asset;
  final int column, row, columns, rows;
  const GardenAtlasArt({
    super.key,
    required this.asset,
    required this.column,
    this.row = 0,
    this.columns = 4,
    this.rows = 2,
  });
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => ClipRect(
      child: SizedBox(
        width: box.maxWidth,
        height: box.maxHeight,
        child: Stack(
          children: [
            Positioned(
              left: -column * box.maxWidth,
              top: -row * box.maxHeight,
              width: columns * box.maxWidth,
              height: rows * box.maxHeight,
              child: Image.asset(
                asset,
                fit: BoxFit.fill,
                excludeFromSemantics: true,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class GardenFlowerArt extends StatelessWidget {
  final String kind;
  final bool night;
  const GardenFlowerArt({super.key, required this.kind, this.night = false});
  @override
  Widget build(BuildContext context) {
    final index = [
      'daisy',
      'tulip',
      'hydrangea',
      'gypsophila',
      'lavender',
    ].indexOf(kind);
    final cell = 3 + (index < 0 ? 0 : index);
    return GardenGroundedArt(
      night: night,
      child: GardenAtlasArt(
        asset: 'assets/living_garden/botanicals.webp',
        column: cell % 4,
        row: cell ~/ 4,
      ),
    );
  }
}
