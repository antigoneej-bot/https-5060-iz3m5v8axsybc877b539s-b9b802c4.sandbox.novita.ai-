import '../../l10n/app_language.dart';
import 'package:flutter/material.dart';
import '../models/seed.dart';
import 'living_garden_scene.dart';
import '../integration/planting_mind.dart';

/// Uses the same six-species growth artwork and IDs as the saved 2.5D garden.
class GardenPlantPicker extends StatefulWidget {
  const GardenPlantPicker({
    super.key,
    required this.tokens,
    required this.seeds,
    required this.onPlant,
    required this.onLocate,
    required this.onCare,
    this.chooseLocation = false,
    this.mindPlanting = false,
    this.plantingDetails,
    this.onAddMind,
    this.onRecord,
    this.onMeditate,
  });
  final int tokens;
  final bool chooseLocation;
  final bool mindPlanting;
  final Widget? plantingDetails;
  final Future<void> Function(SeedType)? onAddMind;
  final VoidCallback? onRecord, onMeditate;
  final Map<String, int> seeds;
  final Future<void> Function(SeedType) onPlant;
  final ValueChanged<SeedType> onLocate, onCare;
  @override
  State<GardenPlantPicker> createState() => _GardenPlantPickerState();
}

class _GardenPlantPickerState extends State<GardenPlantPicker> {
  final _pages = PageController(viewportFraction: .88);
  int _index = 0;
  bool _busy = false;
  bool _showPlanted = false;
  String? _error;
  Widget _filters() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Wrap(
      spacing: 8,
      children: [
        for (final planted in [false, true])
          ChoiceChip(
            label: Text(planted ? tr('이미 심은 식물') : tr('심을 수 있는 씨앗')),
            selected: _showPlanted == planted,
            onSelected: _busy
                ? null
                : (_) {
                    setState(() {
                      _showPlanted = planted;
                      _index = 0;
                      _error = null;
                    });
                    if (_pages.hasClients) _pages.jumpToPage(0);
                  },
          ),
      ],
    ),
  );
  @override
  void initState() {
    super.initState();
    _showPlanted =
        widget.mindPlanting &&
        SeedType.all.every((s) => (widget.seeds[s.id] ?? 0) > 0);
  }

  Future<void> _addMind(SeedType seed) async {
    if (_busy || widget.onAddMind == null) return;
    setState(() => _busy = true);
    try {
      await widget.onAddMind!(seed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _go(int page) {
    if (_busy) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _pages.jumpToPage(page);
    } else {
      _pages.animateToPage(
        page,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _plant(SeedType seed) async {
    if (_busy || widget.tokens < 1 || (widget.seeds[seed.id] ?? 0) > 0) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onPlant(seed);
    } catch (_) {
      if (mounted)
        setState(() => _error = tr('심지 못했어요. 정원과 씨앗을 확인한 뒤 다시 시도해 주세요.'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    final catalog = widget.chooseLocation
        ? SeedType.all
              .where((s) => ((widget.seeds[s.id] ?? 0) > 0) == _showPlanted)
              .toList()
        : SeedType.all;
    if (catalog.isEmpty)
      return SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _filters(),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _showPlanted
                      ? tr('아직 심은 식물이 없어요.')
                      : tr('모든 종류를 심었어요. 내 식물에서 가꿔주세요.'),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(tr("닫기")),
              ),
            ],
          ),
        ),
      );
    final seed = catalog[_index.clamp(0, catalog.length - 1)];
    final planted = (widget.seeds[seed.id] ?? 0) > 0;
    final screen = MediaQuery.sizeOf(context);
    final baseHeight =
        (screen.width * .74).clamp(225.0, 320.0) +
        (MediaQuery.textScalerOf(context).scale(16) - 16).clamp(0.0, 65.0);
    // Keep plant art readable at 2x text too. Measure the longest translated
    // card instead of constraining expanded text to a phone-width-based height.
    final textWidth = screen.width * .88 - 40;
    double textHeight(String text, TextStyle style) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout(maxWidth: textWidth);
      final height = painter.height;
      painter.dispose();
      return height;
    }

    final bodyStyle = DefaultTextStyle.of(context).style;
    final titleStyle = Theme.of(context).textTheme.titleLarge ?? bodyStyle;
    final cardHeight = catalog.fold<double>(baseHeight, (height, item) {
      final count = widget.seeds[item.id] ?? 0;
      final needed =
          160 +
          32 +
          textHeight(item.label, titleStyle) +
          textHeight(
            widget.mindPlanting ? plantingMeaning(item) : item.description,
            bodyStyle,
          ) +
          textHeight(
            count > 0
                ? tr('심은 식물 · {0}', [item.growthLabel(count)])
                : tr('다 자란 모습 미리보기'),
            bodyStyle,
          );
      return needed > height ? needed : height;
    });
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.chooseLocation) _filters(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      tr(widget.mindPlanting ? '마음을 담을 식물' : '씨앗과 나무'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: tr("닫기"),
                    onPressed: _busy ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(tr("좌우로 넘겨 골라요 · 씨앗 {0}개", [widget.tokens])),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: cardHeight,
              child: PageView.builder(
                key: const Key('plant-carousel'),
                controller: _pages,
                physics: _busy ? const NeverScrollableScrollPhysics() : null,
                itemCount: catalog.length,
                onPageChanged: (page) => setState(() {
                  _index = page;
                  _error = null;
                }),
                itemBuilder: (context, i) {
                  final item = catalog[i];
                  final count = widget.seeds[item.id] ?? 0;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F3E4),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: GardenPlantArt(
                            seed: item,
                            count: count > 0 ? count : 10,
                          ),
                        ),
                        Text(
                          item.label,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          widget.mindPlanting
                              ? plantingMeaning(item)
                              : item.description,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          count > 0
                              ? tr("심은 식물 · {0}", [item.growthLabel(count)])
                              : tr('다 자란 모습 미리보기'),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: tr('이전 식물'),
                  onPressed: _index == 0 || _busy
                      ? null
                      : () => _go(_index - 1),
                  icon: const Icon(Icons.chevron_left),
                ),
                Text('${_index + 1} / ${catalog.length}'),
                IconButton(
                  tooltip: tr('다음 식물'),
                  onPressed: _index == catalog.length - 1 || _busy
                      ? null
                      : () => _go(_index + 1),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error != null)
                    Text(
                      _error!,
                      key: const Key('plant-error'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  if (planted) ...[
                    if (widget.onAddMind != null) ...[
                      if (widget.plantingDetails != null)
                        widget.plantingDetails!,
                      FilledButton.icon(
                        key: const Key('save-plant-mind'),
                        onPressed: _busy ? null : () => _addMind(seed),
                        icon: const Icon(Icons.favorite_border),
                        label: Text(tr(_busy ? '저장하고 있어요…' : '이 식물에 마음 남기기')),
                      ),
                      Text(
                        tr('씨앗을 쓰지 않고 추억만 더해요.'),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                    ],
                    FilledButton.icon(
                      key: const Key('locate-plant'),
                      onPressed: _busy ? null : () => widget.onLocate(seed),
                      icon: const Icon(Icons.my_location),
                      label: Text(tr("{0} 위치 보기", [seed.label])),
                    ),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : () => widget.onCare(seed),
                      icon: const Icon(Icons.auto_stories_outlined),
                      label: Text(tr('추억 보기')),
                    ),
                  ] else ...[
                    if (widget.plantingDetails != null) widget.plantingDetails!,
                    FilledButton.icon(
                      key: const Key('plant-selected'),
                      onPressed: _busy || widget.tokens < 1
                          ? null
                          : () => _plant(seed),
                      icon: _busy
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.spa_outlined),
                      label: Text(
                        _busy
                            ? tr('확인하고 있어요…')
                            : widget.chooseLocation
                            ? tr("{0} 심을 자리 고르기", [seed.label])
                            : tr("{0} 심기 · 씨앗 1개", [seed.label]),
                      ),
                    ),
                    Text(
                      widget.tokens > 0
                          ? widget.chooseLocation
                                ? tr('자리 선택 후 확인할 때만 씨앗 1개를 사용해요.')
                                : tr('심은 뒤 하루 한 번 물을 주며 키워요.')
                          : tr('편지나 명상으로 씨앗을 얻을 수 있어요.'),
                      textAlign: TextAlign.center,
                    ),
                    if (widget.tokens < 1)
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        children: [
                          if (widget.onRecord != null)
                            TextButton.icon(
                              key: const Key('mind-get-seed-record'),
                              onPressed: _busy ? null : widget.onRecord,
                              icon: const Icon(Icons.edit_note),
                              label: Text(tr('마음 기록하기')),
                            ),
                          if (widget.onMeditate != null)
                            TextButton.icon(
                              key: const Key('mind-get-seed-meditate'),
                              onPressed: _busy ? null : widget.onMeditate,
                              icon: const Icon(Icons.spa_outlined),
                              label: Text(tr('명상 둘러보기')),
                            ),
                        ],
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
