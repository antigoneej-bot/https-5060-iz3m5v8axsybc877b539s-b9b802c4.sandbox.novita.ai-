import 'companion_welcome_home.dart';
import 'companion_coat_art.dart';
import 'companion_presence.dart';
import 'package:flutter/material.dart';
import '../models/companion_coat.dart';
import '../theme.dart';
import 'storybook_art.dart';
import 'storybook_motion.dart';

enum PastelAction {
  login,
  companion,
  write,
  comic,
  memories,
  garden,
  landscape,
  coats,
  orchard,
  meditation,
  coloring,
  care,
  neighbors,
  inbox,
  cards,
  records,
  settings,
  tutorial,
  all,
  sound,
  notices,
  exit,
  petCare,
  premium,
  discover,
  favorites,
  feed,
  water,
  bath,
  clean,
  calendar,
  memoryBook,
  dataSafety,
}

/// Four approved storybook pages. Persistence and permissions stay in existing routes.
class PastelGardenShell extends StatefulWidget {
  const PastelGardenShell({
    super.key,
    required this.onAction,
    required this.onCoat,
    required this.coat,
    required this.gardenPreview,
    this.signedIn = false,
    this.motionEnabled = true,
    this.selecting = false,
    this.footer = const SizedBox.shrink(),
    this.onMoodSelected,
    this.onPageSelected,
    this.completedCare = const {},
    this.careBusy = false,
    this.actualGarden,
    this.companionName,
    this.companionStage = 0,
    this.companionBondStage = 0,
    this.companionAutomaticBehavior = true,
    this.companionLoading = false,
    this.companionError,
    this.onRetryCompanion,
  });
  final ValueChanged<PastelAction> onAction;
  final ValueChanged<CompanionCoat> onCoat;
  final ValueChanged<int>? onMoodSelected;
  final ValueChanged<int>? onPageSelected;
  final CompanionCoat? coat;
  final String? companionName, companionError;
  final int companionStage, companionBondStage;
  final bool companionAutomaticBehavior;
  final bool companionLoading;
  final VoidCallback? onRetryCompanion;
  final bool signedIn, motionEnabled, selecting, careBusy;
  final Widget gardenPreview, footer;
  final Widget? actualGarden;
  final Set<PastelAction> completedCare;
  @override
  State<PastelGardenShell> createState() => _PastelGardenShellState();
}

class _StoryEntry {
  const _StoryEntry(this.label, this.icon, this.action);
  final String label;
  final int icon;
  final PastelAction action;
}

class _PastelGardenShellState extends State<PastelGardenShell> {
  static const ink = Color(0xFF292B26),
      green = Color(0xFF6D8869),
      cream = Color(0xFFFCF9F3);
  static const mint = Color(0xFFF0F3E4),
      lavender = Color(0xFFF2EAF6),
      peach = Color(0xFFFCECDD),
      butter = Color(0xFFF9F3DE);
  static const labels = ['홈', '정원', '마음돌보기', '모든 기능'];
  static const icons = [
    Icons.home_outlined,
    Icons.spa_outlined,
    Icons.favorite_border_rounded,
    Icons.grid_view_rounded,
  ];
  final _pages = PageController();
  final _search = TextEditingController();
  int _index = 0;
  int? _mood;
  String _query = '';
  @override
  void dispose() {
    _pages.dispose();
    _search.dispose();
    super.dispose();
  }

  void go(int i) {
    if (MediaQuery.disableAnimationsOf(context) || !widget.motionEnabled) {
      _pages.jumpToPage(i);
    } else {
      _pages.animateToPage(
        i,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Widget companionArt({bool resting = false}) => CompanionCoatScope(
    key: ValueKey('shell-coat-${widget.coat?.name ?? "legacy"}-$resting'),
    useLocalChoice: true,
    coat: widget.coat,
    growthStage: widget.companionStage,
    child: CompanionPresence(
      enabled:
          widget.companionAutomaticBehavior &&
          _index == 2,
      resting: resting,
    ),
  );

  Text heading(String value, {double size = 24, Color color = ink}) => Text(
    value,
    style: titleFont(
      fontSize: size,
      color: color,
      height: 1.2,
      letterSpacing: 0,
    ),
  );
  Text body(
    String value, {
    double size = 13,
    Color color = const Color(0xFF797D73),
  }) => Text(
    value,
    style: bodyFont(fontSize: size, color: color),
  );
  Widget art(int index, {double size = 72}) =>
      SizedBox(width: size, height: size, child: StorySprite.icon(index));

  Widget _hero(int page, double width) {
    if (MediaQuery.textScalerOf(context).scale(14) > 20) {
      return _largeHero(page, width);
    }
    final screen = MediaQuery.sizeOf(context);
    final height = screen.width > screen.height
        ? (screen.height * .50).clamp(160.0, 230.0).toDouble()
        : width * const [.91, 1.06, .78, .40][page];
    final asset = const [
      'home-scene',
      'garden-scene',
      'care-scene',
      'records-scene',
    ][page];
    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            '$storyAssets$asset.png',
            fit: BoxFit.cover,
            cacheWidth: 1200,
            excludeFromSemantics: true,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xF5FBF8F0),
                  Color(0x32FBF8F0),
                  Color(0x00FBF8F0),
                ],
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 20,
            right: 14,
            child: Row(
              children: [
                const Icon(Icons.eco_outlined, color: green, size: 25),
                const SizedBox(width: 8),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: heading('마음냥 정원', size: 26, color: green),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: cream.withValues(alpha: .96),
                  shape: const CircleBorder(),
                  child: IconButton(
                    key: const Key('quick-login'),
                    tooltip: widget.signedIn ? '내 계정' : '로그인',
                    onPressed: () => widget.onAction(PastelAction.login),
                    icon: const Icon(Icons.person_outline, color: ink),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 70,
            left: 24,
            right: page == 3 ? width * .35 : 20,
            child: heading(
              const ['오늘의 마음', '나의 정원', '마음돌보기', '기록과 보관함'][page],
              size: page == 0 ? 30 : 22,
              color: green,
            ),
          ),
          Positioned(
            bottom: page == 2 ? height * .07 : height * .025,
            left: page == 1
                ? width * .12
                : page == 2
                ? width * .13
                : page == 3
                ? width * .59
                : width * .58,
            width:
                width *
                (page == 1
                    ? .39
                    : page == 2
                    ? .66
                    : page == 3
                    ? .33
                    : .40),
            height:
                height *
                (page == 2
                    ? .61
                    : page == 3
                    ? .68
                    : .70),
            child: StorybookMotion(
              enabled: widget.motionEnabled && page == _index,
              breathing: true,
              child: companionArt(resting: page >= 2),
            ),
          ),
          Positioned.fill(
            child: StorybookMotion(
              enabled: widget.motionEnabled && page == _index,
            ),
          ),
          if (page == 1)
            Positioned(
              top: 124,
              right: 16,
              child: Material(
                color: cream,
                shape: const CircleBorder(),
                child: IconButton(
                  tooltip: '정원 전체 보기',
                  onPressed: () => widget.onAction(PastelAction.garden),
                  icon: const Icon(Icons.zoom_in_rounded, color: green),
                ),
              ),
            ),
          if (page == 2)
            Positioned(
              bottom: 12,
              right: 16,
              child: FilledButton.tonalIcon(
                onPressed: widget.selecting
                    ? null
                    : () => widget.onAction(PastelAction.coats),
                icon: const Icon(Icons.pets_outlined, size: 17),
                label: const Text('고양이 선택'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _largeHero(int page, double width) {
    final asset = const [
      'home-scene',
      'garden-scene',
      'care-scene',
      'records-scene',
    ][page];
    final imageHeight = width * (page == 3 ? .34 : .56);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 12, 4),
          child: Row(
            children: [
              const Icon(Icons.eco_outlined, color: green),
              const SizedBox(width: 8),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: heading('마음냥 정원', size: 24, color: green),
                ),
              ),
              IconButton(
                key: const Key('quick-login'),
                tooltip: widget.signedIn ? '내 계정' : '로그인',
                onPressed: () => widget.onAction(PastelAction.login),
                icon: const Icon(Icons.person_outline, color: ink),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: heading(
            const ['오늘의 마음', '나의 정원', '마음돌보기', '기록과 보관함'][page],
            size: 22,
            color: green,
          ),
        ),
        GestureDetector(
          onTap: page == 1 ? () => widget.onAction(PastelAction.garden) : null,
          child: SizedBox(
            height: imageHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  '${storyAssets}$asset.png',
                  fit: BoxFit.cover,
                  cacheWidth: 1200,
                  excludeFromSemantics: true,
                ),
                Positioned(
                  bottom: 4,
                  left: page == 1
                      ? width * .10
                      : page >= 2
                      ? width * .18
                      : width * .57,
                  width: width * (page >= 2 ? .62 : .40),
                  height: imageHeight * .95,
                  child: StorybookMotion(
                    enabled: widget.motionEnabled && page == _index,
                    breathing: true,
                    child: companionArt(resting: page >= 2),
                  ),
                ),
                Positioned.fill(
                  child: StorybookMotion(
                    enabled: widget.motionEnabled && page == _index,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (page == 2)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: FilledButton.tonalIcon(
              onPressed: widget.selecting
                  ? null
                  : () => widget.onAction(PastelAction.coats),
              icon: const Icon(Icons.pets_outlined),
              label: const Text('고양이 선택'),
            ),
          ),
      ],
    );
  }

  Widget _panel(List<Widget> children) => Container(
    decoration: const BoxDecoration(
      color: cream,
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
    ),
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  );

  Widget _primary(String label, VoidCallback onTap) => FilledButton(
    onPressed: onTap,
    style: FilledButton.styleFrom(
      backgroundColor: const Color(0xFF728B64),
      foregroundColor: Colors.white,
      minimumSize: const Size(0, 56),
      padding: const EdgeInsets.all(15),
      textStyle: titleFont(fontSize: 21, fontWeight: FontWeight.w700),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (MediaQuery.textScalerOf(context).scale(21) < 30) ...[
          const Icon(Icons.eco_outlined),
          const SizedBox(width: 12),
        ],
        Flexible(child: Text(label, textAlign: TextAlign.center)),
      ],
    ),
  );

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 10, 0, 8),
    child: Row(
      children: [
        const Icon(Icons.eco_outlined, size: 21, color: Color(0xFF83976C)),
        const SizedBox(width: 8),
        Expanded(child: heading(title, size: 23)),
      ],
    ),
  );

  Widget _tile(_StoryEntry entry, {Color color = mint, bool compact = false}) {
    final done = widget.completedCare.contains(entry.action);
    final disabled =
        done ||
        (widget.careBusy &&
            const [
              PastelAction.feed,
              PastelAction.water,
              PastelAction.bath,
              PastelAction.clean,
            ].contains(entry.action));
    return Material(
      color: switch (entry.action) {
        PastelAction.feed => peach,
        PastelAction.water => mint,
        PastelAction.bath => lavender,
        PastelAction.clean => butter,
        _ => color,
      },
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: disabled ? null : () => widget.onAction(entry.action),
        child: Padding(
          padding: EdgeInsets.all(compact ? 8 : 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: compact ? 64 : 80,
                width: double.infinity,
                child: StorySprite.icon(entry.icon),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      entry.label,
                      textAlign: TextAlign.center,
                      style: titleFont(fontSize: compact ? 17 : 20, color: ink),
                    ),
                  ),
                  if (done) ...[
                    const SizedBox(width: 3),
                    const Icon(Icons.check_circle, size: 17, color: green),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _grid(
    List<_StoryEntry> entries, {
    int columns = 3,
    bool compact = false,
  }) => LayoutBuilder(
    builder: (context, box) {
      final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
      final count = scale > 1.5 ? (columns == 4 ? 2 : 1) : columns;
      final width = (box.maxWidth - (count - 1) * 8) / count;
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var i = 0; i < entries.length; i++)
            SizedBox(
              width: width,
              child: _tile(
                entries[i],
                compact: compact,
                color: const [mint, lavender, butter, peach][i % 4],
              ),
            ),
        ],
      );
    },
  );

  Widget _row(_StoryEntry entry, {String? subtitle, Color color = butter}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: color,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 0,
            ),
            minTileHeight: 52,
            minVerticalPadding: 4,
            leading: MediaQuery.textScalerOf(context).scale(14) > 20
                ? null
                : art(entry.icon, size: 40),
            title: heading(entry.label, size: 20),
            subtitle: subtitle == null ? null : body(subtitle),
            trailing: const Icon(Icons.chevron_right_rounded, color: green),
            onTap: () => widget.onAction(entry.action),
          ),
        ),
      );

  Widget _home() => _panel([
    Center(child: heading('지금 어떤 기분인가요?', size: 24)),
    const SizedBox(height: 12),
    LayoutBuilder(
      builder: (context, box) {
        final large = MediaQuery.textScalerOf(context).scale(13) > 18;
        final count = large ? 3 : 5,
            width = (box.maxWidth - (count - 1) * 4) / count;
        return Wrap(
          spacing: 4,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (var i = 0; i < 5; i++)
              SizedBox(
                width: width,
                child: Semantics(
                  button: true,
                  selected: _mood == i,
                  label: const ['좋아요', '평온해요', '그냥 그래요', '힘들어요', '지쳤어요'][i],
                  child: Material(
                    color: _mood == i
                        ? const Color(0xFFFFE4D1)
                        : const Color(0xFFF6F3EB),
                    borderRadius: BorderRadius.circular(22),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
                        setState(() => _mood = i);
                        widget.onMoodSelected?.call(i);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 2,
                        ),
                        child: Column(
                          children: [
                            SizedBox(
                              height: 52,
                              width: double.infinity,
                              child: StorySprite.icon(i),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              const ['좋아요', '평온해요', '보통', '힘들어요', '지쳤어요'][i],
                              textAlign: TextAlign.center,
                              style: bodyFont(fontSize: 12, color: ink),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    ),
    const SizedBox(height: 16),
    _primary('마음 기록하기', () => widget.onAction(PastelAction.write)),
    const SizedBox(height: 16),
    Material(
      color: mint,
      borderRadius: BorderRadius.circular(23),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => widget.onAction(PastelAction.garden),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    heading('나의 정원', size: 22),
                    const SizedBox(height: 6),
                    body('오늘의 마음으로 가꾸는 정원'),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ExcludeSemantics(
                child: SizedBox(
                  width: 110,
                  height: 88,
                  child: IgnorePointer(child: widget.gardenPreview),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: green),
            ],
          ),
        ),
      ),
    ),
    const SizedBox(height: 8),
    Center(
      child: TextButton(
        onPressed: () => go(3),
        child: const Text('지난 기록 보기  ›'),
      ),
    ),
    widget.footer,
  ]);

  Widget _garden() => _panel([
    FilledButton.icon(
      key: const Key('enter-my-garden'),
      onPressed: () => widget.onAction(PastelAction.garden),
      icon: const Icon(Icons.door_front_door_outlined),
      label: const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text('내 정원 들어가기'),
      ),
    ),
    const SizedBox(height: 12),
    _grid(const [
      _StoryEntry('정원 꾸미기', 5, PastelAction.garden),
      _StoryEntry('기억의 나무', 6, PastelAction.memories),
      _StoryEntry('열매 정원', 7, PastelAction.orchard),
    ]),
    const SizedBox(height: 16),
    Material(
      color: lavender,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(
          builder: (context, box) {
            final narrow =
                box.maxWidth < 310 ||
                MediaQuery.textScalerOf(context).scale(14) > 20;
            final detail = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InkWell(
                  onTap: () => widget.onAction(PastelAction.neighbors),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: heading('이웃 정원', size: 26),
                  ),
                ),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        minimumSize: const Size(0, 48),
                        textStyle: bodyFont(fontSize: 12),
                      ),
                      onPressed: () => widget.onAction(PastelAction.discover),
                      icon: const Icon(Icons.explore_outlined, size: 17),
                      label: const Text('둘러보기'),
                    ),
                    FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        minimumSize: const Size(0, 48),
                        textStyle: bodyFont(fontSize: 12),
                      ),
                      onPressed: () => widget.onAction(PastelAction.favorites),
                      icon: const Icon(Icons.favorite_border, size: 17),
                      label: const Text('즐겨찾기'),
                    ),
                  ],
                ),
              ],
            );
            return narrow
                ? Column(children: [art(8, size: 116), detail])
                : Row(
                    children: [
                      art(8, size: 116),
                      const SizedBox(width: 12),
                      Expanded(child: detail),
                    ],
                  );
          },
        ),
      ),
    ),
    const SizedBox(height: 8),
    TextButton.icon(
      onPressed: () => widget.onAction(PastelAction.inbox),
      icon: const Icon(Icons.local_florist_outlined),
      label: const Text('받은 응원·선물'),
    ),
  ]);

  Widget _care() => _panel([
    _section('고양이 돌보기'),
    _grid(
      const [
        _StoryEntry('밥 주기', 10, PastelAction.feed),
        _StoryEntry('물 주기', 11, PastelAction.water),
        _StoryEntry('목욕', 12, PastelAction.bath),
        _StoryEntry('청소', 13, PastelAction.clean),
      ],
      columns: 4,
      compact: true,
    ),
    if (widget.careBusy)
      const Padding(
        padding: EdgeInsets.only(top: 8),
        child: LinearProgressIndicator(),
      ),
    const SizedBox(height: 16),
    const Divider(color: Color(0xFFE4DECF)),
    _section('나를 돌보기'),
    _grid(const [
      _StoryEntry('호흡·명상', 15, PastelAction.meditation),
      _StoryEntry('색칠 힐링', 16, PastelAction.coloring),
      _StoryEntry('돌봄 기록', 17, PastelAction.care),
    ]),
    const SizedBox(height: 8),
    TextButton(
      onPressed: () => widget.onAction(PastelAction.petCare),
      child: const Text('고양이와 함께한 기록·꾸미기  ›'),
    ),
  ]);

  Widget _recordPair(List<_StoryEntry> entries) => Row(
    children: [
      for (var i = 0; i < entries.length; i++) ...[
        if (i > 0) const SizedBox(width: 8),
        Expanded(
          child: Material(
            color: i == 0 ? mint : lavender,
            borderRadius: BorderRadius.circular(21),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => widget.onAction(entries[i].action),
              child: SizedBox(
                height: 88,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      art(entries[i].icon, size: 58),
                      const SizedBox(width: 4),
                      Expanded(child: heading(entries[i].label, size: 20)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ],
  );

  Widget _all() {
    const groups = {
      '지난 기록': [
        _StoryEntry('편지 기록', 20, PastelAction.records),
        _StoryEntry('감정 통계', 21, PastelAction.comic),
        _StoryEntry('감정 캘린더', 22, PastelAction.calendar),
      ],
      '수집·보관': [
        _StoryEntry('정원 기록집', 18, PastelAction.memoryBook),
        _StoryEntry('추억 카드', 19, PastelAction.cards),
      ],
      '설정': [
        _StoryEntry('계정·백업·잠금', 23, PastelAction.dataSafety),
        _StoryEntry('소리·알림', 24, PastelAction.sound),
        _StoryEntry('구독·혜택', 9, PastelAction.premium),
      ],
    };
    final large = MediaQuery.textScalerOf(context).scale(14) > 20;
    return _panel([
      TextField(
        controller: _search,
        onChanged: (value) => setState(() => _query = value.trim()),
        decoration: InputDecoration(
          hintText: '기능 찾기',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  tooltip: '검색 지우기',
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _search.clear();
                    setState(() => _query = '');
                  },
                ),
          filled: true,
          fillColor: const Color(0xFFF3F0E8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      for (final group in groups.entries) ...[
        if (group.value.any((entry) => entry.label.contains(_query)))
          _section(group.key),
        if (group.key == '지난 기록' && _query.isEmpty && !large) ...[
          _recordPair(group.value.take(2).toList()),
          const SizedBox(height: 8),
          _row(group.value.last),
        ] else
          for (final entry in group.value.where(
            (entry) => entry.label.contains(_query),
          ))
            _row(
              entry,
              color: group.key == '지난 기록'
                  ? mint
                  : group.key == '수집·보관'
                  ? butter
                  : const Color(0xFFF8F5ED),
            ),
      ],
      if (!groups.values
          .expand((entries) => entries)
          .any((entry) => entry.label.contains(_query)))
        Padding(
          padding: const EdgeInsets.all(16),
          child: body('찾는 메뉴가 없어요. 전체 기능에서 찾아보세요.'),
        ),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: () => widget.onAction(PastelAction.all),
        icon: const Icon(Icons.grid_view_rounded),
        label: Text(_query.isEmpty ? '전체 기능 둘러보기' : '다른 기능도 찾아보기'),
      ),
      const SizedBox(height: 8),
      Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        children: [
          TextButton(
            onPressed: () => widget.onAction(PastelAction.notices),
            child: const Text('공지사항'),
          ),
          TextButton(
            onPressed: () => widget.onAction(PastelAction.tutorial),
            child: const Text('사용법'),
          ),
          TextButton(
            onPressed: () => widget.onAction(PastelAction.exit),
            child: const Text('앱 종료'),
          ),
        ],
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: cream,
    body: SafeArea(
      bottom: false,
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              key: const Key('main-pastel-pager'),
              controller: _pages,
              physics: _index == 1 && widget.actualGarden != null
                  ? const NeverScrollableScrollPhysics()
                  : null,
              onPageChanged: (index) {
                FocusManager.instance.primaryFocus?.unfocus();
                setState(() => _index = index);
                widget.onPageSelected?.call(index);
              },
              itemCount: 4,
              itemBuilder: (context, index) => index == 0
                  ? TickerMode(
                      enabled: _index == 0,
                      child: CompanionWelcomeHome(
                        coat: widget.coat,
                        name: widget.companionName,
                        growthStage: widget.companionStage,
                        motionEnabled: widget.motionEnabled && _index == 0,
                        automaticBehavior: widget.companionAutomaticBehavior,
                        bondStage: widget.companionBondStage,
                        loading: widget.companionLoading,
                        error: widget.companionError,
                        onRetry: widget.onRetryCompanion,
                        selecting: widget.selecting,
                        selectedMood: _mood,
                        onMoodSelected: (value) {
                          setState(() => _mood = value);
                          widget.onMoodSelected?.call(value);
                        },
                        onRecord: () => widget.onAction(PastelAction.write),
                        onGarden: () => widget.onAction(PastelAction.garden),
                        onChooseCat: () => widget.onAction(PastelAction.coats),
                        onCompanionTap: () =>
                            widget.onAction(PastelAction.companion),
                        onNotices: () => widget.onAction(PastelAction.notices),
                        footer: widget.footer,
                      ),
                    )
                  : index == 1 && widget.actualGarden != null
                  ? TickerMode(
                      enabled: index == _index,
                      child: widget.actualGarden!,
                    )
                  : TickerMode(
                      enabled: index == _index,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 620),
                          child: LayoutBuilder(
                            builder: (context, box) => ListView(
                              key: PageStorageKey('pastel-page-$index'),
                              padding: EdgeInsets.zero,
                              children: [
                                _hero(index, box.maxWidth),
                                switch (index) {
                                  0 => _home(),
                                  1 => _garden(),
                                  2 => _care(),
                                  _ => _all(),
                                },
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          _navigation(),
        ],
      ),
    ),
  );

  Widget _navigation() => LayoutBuilder(
    builder: (context, box) {
      final large =
          MediaQuery.textScalerOf(context).scale(14) > 20 && box.maxWidth < 600;
      Widget item(int i) => Semantics(
        selected: _index == i,
        button: true,
        label: '${labels[i]} 화면',
        child: InkWell(
          onTap: () => go(i),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
            child: large
                ? Row(
                    children: [
                      Icon(
                        icons[i],
                        size: 25,
                        color: _index == i ? green : const Color(0xFF898781),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          labels[i],
                          style: bodyFont(
                            fontSize: 11,
                            color: _index == i
                                ? green
                                : const Color(0xFF77756F),
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icons[i],
                        size: 27,
                        color: _index == i
                            ? const Color(0xFF64845A)
                            : const Color(0xFF898781),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        labels[i],
                        textAlign: TextAlign.center,
                        style: bodyFont(
                          fontSize: 12,
                          color: _index == i ? green : const Color(0xFF77756F),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _index == i
                              ? const Color(0xFF809B69)
                              : Colors.transparent,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      );
      return DecoratedBox(
        decoration: const BoxDecoration(
          color: cream,
          border: Border(top: BorderSide(color: Color(0xFFEAE3D7))),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            child: large
                ? Wrap(
                    children: [
                      for (var i = 0; i < 4; i++)
                        SizedBox(width: (box.maxWidth - 8) / 2, child: item(i)),
                    ],
                  )
                : Row(
                    children: [
                      for (var i = 0; i < 4; i++) Expanded(child: item(i)),
                    ],
                  ),
          ),
        ),
      );
    },
  );
}
