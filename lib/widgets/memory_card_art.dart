import '../l10n/app_language.dart';
import 'package:flutter/material.dart';
import '../models/companion_coat.dart';
import 'companion_coat_art.dart';

Map<String, String> get memoryThemes => {
  'rain': tr("비 오는 날의 낮잠"),
  'apple': tr("사과 향기 가득"),
  'moon': tr("달빛 산책"),
  'friends': tr("둘이어서 따뜻해"),
  'artist': tr("작은 화가"),
  'blossom': tr("꽃잎 속의 쉼"),
};
const memorySymbols = {
  'rain': '☔',
  'apple': '🍎',
  'moon': '🌙',
  'friends': '💕',
  'artist': '🎨',
  'blossom': '🌸',
};

class MemoryCardArt extends StatelessWidget {
  final String id;
  const MemoryCardArt(this.id, {super.key});
  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    final parts = id.split('.');
    final theme = parts.first,
        coat =
            CompanionCoat.parse(parts.length > 1 ? parts[1] : '') ??
            CompanionCoat.ginger;
    final frame = int.tryParse(parts.last) ?? 0;
    final colors = [
      const Color(0xFFF4D9AF),
      const Color(0xFFC7DDE8),
      const Color(0xFFD9C5EE),
    ];
    return AspectRatio(
      aspectRatio: 0.72,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, colors[frame.clamp(0, 2)]],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colors[frame.clamp(0, 2)], width: 3),
        ),
        child: Column(
          children: [
            Text(
              [tr("햇살 테두리"), tr("물빛 테두리"), tr("별빛 테두리")][frame.clamp(0, 2)],
              style: const TextStyle(fontSize: 10, color: Color(0xFF75677F)),
            ),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                clipBehavior: Clip.hardEdge,
                alignment: Alignment.center,
                children: [
                  Positioned.fill(child: CustomPaint(painter: _Scene(theme))),
                  Align(
                    alignment: Alignment.topRight,
                    child: Icon(
                      {
                        'rain': Icons.umbrella_rounded,
                        'apple': Icons.apple,
                        'moon': Icons.nightlight_round,
                        'friends': Icons.favorite_rounded,
                        'artist': Icons.palette_rounded,
                        'blossom': Icons.local_florist_rounded,
                      }[theme],
                      size: 28,
                      color: const Color(0xFFAD839E),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 18),
                    child: CompanionCoatArt(coat: coat),
                  ),
                  if (theme == 'friends')
                    Positioned(
                      right: 0,
                      bottom: 8,
                      width: 65,
                      height: 70,
                      child: CompanionCoatArt(
                        coat: CompanionCoat.values[(coat.index + 1) % 6],
                      ),
                    ),
                ],
              ),
            ),
            Text(
              memoryThemes[theme] ?? '정원의 추억',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            Text(coat.label, style: const TextStyle(fontSize: 10)),
            Text(
              tr("마음냥 정원"),
              style: TextStyle(fontSize: 9, color: Color(0xFF867A91)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Scene extends CustomPainter {
  final String theme;
  _Scene(this.theme);
  @override
  void paint(Canvas c, Size s) {
    final p = Paint();
    c.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & s, const Radius.circular(18)),
      p
        ..color = theme == 'moon'
            ? const Color(0xFFD4D4F1)
            : const Color(0xFFE3F3E7),
    );
    c.drawOval(
      Rect.fromLTWH(
        -s.width * .1,
        s.height * .68,
        s.width * 1.2,
        s.height * .34,
      ),
      p..color = const Color(0xFFBBDCC2),
    );
    for (var i = 0; i < 12; i++) {
      final x = (i * 37 % 97) / 100 * s.width,
          y = (i * 23 % 71) / 100 * s.height;
      if (theme == 'rain') {
        c.drawLine(
          Offset(x, y),
          Offset(x - 3, y + 10),
          p
            ..color = const Color(0xFF94BFD7)
            ..strokeWidth = 2,
        );
      } else {
        c.drawCircle(
          Offset(x, y),
          theme == 'blossom' ? 4 : 2,
          p
            ..color = theme == 'blossom'
                ? const Color(0xFFF8BFD4)
                : Colors.white,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_Scene o) => theme != o.theme;
}
