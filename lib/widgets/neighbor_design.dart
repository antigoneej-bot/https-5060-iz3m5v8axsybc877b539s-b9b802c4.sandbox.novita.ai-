import '../l10n/app_language.dart';
import '../models/companion_coat.dart';
import 'companion_coat_art.dart';
import 'package:flutter/material.dart';

const neighborCream = Color(0xFFFFF9F1);
const neighborInk = Color(0xFF51473E);
const neighborGreen = Color(0xFF7FA367);
const neighborLine = Color(0xFFE8DFD3);

class NeighborTheme extends StatelessWidget {
  const NeighborTheme({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Theme(
    data: Theme.of(context).copyWith(
      scaffoldBackgroundColor: neighborCream,
      colorScheme: Theme.of(context).colorScheme.copyWith(
        primary: neighborGreen,
        onPrimary: Colors.white,
        surface: neighborCream,
      ),
      textTheme: Theme.of(
        context,
      ).textTheme.apply(bodyColor: neighborInk, displayColor: neighborInk),
      cardTheme: CardThemeData(
        color: const Color(0xFFFFFCF7),
        elevation: 1,
        shadowColor: const Color(0x19846744),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(19),
          side: const BorderSide(color: neighborLine),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: neighborGreen,
          foregroundColor: Colors.white,
          minimumSize: const Size(72, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
          textStyle: const TextStyle(
            fontFamily: 'GowunDodum',
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: neighborInk,
          minimumSize: const Size(72, 44),
          side: const BorderSide(color: Color(0xFFA89D91)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
      ),
    ),
    child: child,
  );
}

/// Select artwork only from the approved board. No baked text or controls are
/// used; all labels, counters and actions remain accessible Flutter widgets.
class NeighborReferenceArt extends StatelessWidget {
  const NeighborReferenceArt({super.key, required this.region});
  final Rect region;
  static const asset = 'assets/neighbor_ui/approved-reference-02.png';
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final scale = box.maxWidth / region.width;
      return ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: 1536 * scale,
          maxWidth: 1536 * scale,
          minHeight: 1024 * scale,
          maxHeight: 1024 * scale,
          child: Transform.translate(
            offset: Offset(-region.left * scale, -region.top * scale),
            child: Image.asset(
              asset,
              width: 1536 * scale,
              height: 1024 * scale,
              fit: BoxFit.fill,
              excludeFromSemantics: true,
            ),
          ),
        ),
      );
    },
  );
}

class NeighborHeader extends StatelessWidget {
  const NeighborHeader({
    super.key,
    required this.title,
    required this.icon,
    this.gifts = false,
  });
  final String title;
  final IconData icon;
  final bool gifts;
  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height < 500;
    return LayoutBuilder(
      builder: (context, box) {
        final scale = box.maxWidth / 522;
        final height = compact ? 64.0 : 136 * scale;
        return SizedBox(
          height: height,
          child: Stack(
            children: [
              if (!compact) ...[
                Positioned(
                  left: 0,
                  top: 0,
                  right: 0,
                  height: 77 * scale,
                  child: NeighborReferenceArt(
                    region: Rect.fromLTWH(gifts ? 900 : 330, 67, 522, 77),
                  ),
                ),
                Positioned(
                  left: 235 * scale,
                  top: 77 * scale,
                  right: 0,
                  height: 53 * scale,
                  child: NeighborReferenceArt(
                    region: Rect.fromLTWH(gifts ? 1135 : 565, 144, 287, 53),
                  ),
                ),
              ],
              Positioned(
                left: 17,
                right: 12,
                bottom: 6,
                child: Row(
                  children: [
                    Icon(icon, size: 29, color: neighborInk),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.bold,
                          color: neighborInk,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class NeighborTabs extends StatelessWidget {
  const NeighborTabs({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelect,
  });
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelect;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      var longest = 0.0;
      for (final label in labels) {
        final painter = TextPainter(
          text: TextSpan(
            text: label,
            style: DefaultTextStyle.of(
              context,
            ).style.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout();
        if (painter.width > longest) longest = painter.width;
        painter.dispose();
      }
      final requiredWidth = (longest + 12) * labels.length + 6;
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: requiredWidth > bounds.maxWidth
              ? requiredWidth
              : bounds.maxWidth,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: labels.length == 2
                  ? const Color(0xFFFFFCF7)
                  : const Color(0xFFF1EADF),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: neighborLine),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < labels.length; i++)
                    Expanded(
                      child: Semantics(
                        selected: i == selected,
                        button: true,
                        child: Material(
                          color: Colors.transparent,
                          child: Ink(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              gradient: i == selected
                                  ? const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF95B67C),
                                        Color(0xFF71955D),
                                      ],
                                    )
                                  : null,
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(15),
                              onTap: () => onSelect(i),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minHeight: 44,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                    vertical: 8,
                                  ),
                                  child: Center(
                                    child: Text(
                                      labels[i],
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: i == selected
                                            ? Colors.white
                                            : neighborInk,
                                        fontWeight: i == selected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class NeighborPortrait extends StatelessWidget {
  const NeighborPortrait({super.key, this.size = 48, this.height, this.coat});
  final double size;
  final double? height;
  final CompanionCoat? coat;
  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    final region = coat == CompanionCoat.white
        ? const Rect.fromLTWH(364, 393, 163, 172)
        : coat == CompanionCoat.calico
        ? const Rect.fromLTWH(364, 615, 163, 172)
        : coat == CompanionCoat.tabby
        ? const Rect.fromLTWH(923, 553, 68, 69)
        : null;
    return Semantics(
      image: true,
      label: coat == null ? tr('고양이 정보 없음') : coat!.label,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * .20),
        child: Container(
          width: size,
          height: height ?? size,
          color: const Color(0xFFECEBDC),
          child: coat == null
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    const NeighborReferenceArt(
                      region: Rect.fromLTWH(364, 393, 163, 172),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: ColoredBox(
                        color: const Color(0xEEFFFCF7),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            tr(
                              size < 110 ||
                                      MediaQuery.textScalerOf(
                                            context,
                                          ).scale(10) >
                                          13
                                  ? '그림'
                                  : '기본 그림',
                            ),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 10,
                              color: neighborInk,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : region != null
              ? NeighborReferenceArt(region: region)
              : CompanionCoatArt(coat: coat!),
        ),
      ),
    );
  }
}

class NeighborRequestCard extends StatelessWidget {
  const NeighborRequestCard({
    super.key,
    required this.name,
    required this.onAccept,
    required this.onDecline,
    this.sent = false,
    this.coat,
  });
  final String name;
  final CompanionCoat? coat;
  final VoidCallback? onAccept, onDecline;
  final bool sent;
  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: LayoutBuilder(
          builder: (context, box) {
            final large =
                MediaQuery.textScalerOf(context).scale(16) > 24 ||
                box.maxWidth < 285;
            final details = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Icon(Icons.pets, size: 17, color: Color(0xFFFFBA9A)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  sent ? tr('이웃 신청을 보냈어요') : tr('이웃이 되고 싶어요'),
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    if (!sent)
                      FilledButton(onPressed: onAccept, child: Text(tr('수락'))),
                    OutlinedButton(
                      onPressed: onDecline,
                      child: Text(sent ? tr('취소') : tr('거절')),
                    ),
                  ],
                ),
              ],
            );
            final portrait = NeighborPortrait(
              size: large ? 86 : 116,
              height: large ? 92 : 126,
              coat: coat,
            );
            return large
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [portrait, const SizedBox(height: 10), details],
                  )
                : Row(
                    children: [
                      portrait,
                      const SizedBox(width: 16),
                      Expanded(child: details),
                    ],
                  );
          },
        ),
      ),
    );
  }
}

class NeighborGiftRow extends StatelessWidget {
  const NeighborGiftRow({
    super.key,
    required this.title,
    required this.art,
    required this.action,
    this.coat,
    this.onDetails,
    this.completed = false,
  });
  final String title;
  final Widget art, action;
  final CompanionCoat? coat;
  final VoidCallback? onDetails;
  final bool completed;
  @override
  Widget build(BuildContext context) => Card(
    color: completed ? const Color(0xFFF0EAE4) : null,
    margin: const EdgeInsets.only(bottom: 7),
    child: InkWell(
      onTap: onDetails,
      borderRadius: BorderRadius.circular(19),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        child: LayoutBuilder(
          builder: (context, box) {
            final label = Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            );
            if (MediaQuery.textScalerOf(context).scale(16) > 24 ||
                box.maxWidth < 275) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  label,
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      NeighborPortrait(size: 45, coat: coat),
                      art,
                      action,
                    ],
                  ),
                ],
              );
            }
            return Row(
              children: [
                NeighborPortrait(size: 45, coat: coat),
                const SizedBox(width: 9),
                Expanded(child: label),
                SizedBox(width: 48, height: 44, child: Center(child: art)),
                const SizedBox(width: 7),
                action,
              ],
            );
          },
        ),
      ),
    ),
  );
}

/// Render one cell from the bundled 5x2 illustration sheet; no emoji-font dependency.
class NeighborGiftArt extends StatelessWidget {
  const NeighborGiftArt({super.key, required this.kind, this.size = 44});
  final String kind;
  final double size;
  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    const kinds = [
      'apple',
      'persimmon',
      'tuna',
      'chicken',
      'kibble',
      'daisy',
      'tulip',
      'hydrangea',
      'gypsophila',
      'lavender',
    ];
    final index = kinds.indexOf(kind);
    if (index < 0)
      return Icon(Icons.card_giftcard, size: size, color: neighborGreen);
    return Semantics(
      label: kind,
      child: SizedBox(
        width: size,
        height: size,
        child: ClipRect(
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: size * 5,
            maxWidth: size * 5,
            minHeight: size * 2,
            maxHeight: size * 2,
            child: Transform.translate(
              offset: Offset(-(index % 5) * size, -(index ~/ 5) * size),
              child: Image.asset(
                'assets/neighbor_ui/gift-atlas.png',
                width: size * 5,
                height: size * 2,
                fit: BoxFit.fill,
                excludeFromSemantics: true,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
