import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../l10n/app_language.dart';
import '../models/home_moments_snapshot.dart';
import '../models/letter_entry.dart';
import '../mongi/integration/mongi_garden_store.dart';

/// Local saved activity, below the primary journal and garden actions.
/// No network requests, reward grants, new records, or reply generation.
class HomeMoments extends StatefulWidget {
  const HomeMoments({
    super.key,
    required this.letters,
    required this.onRecords,
    required this.onReview,
    required this.onMemoryBook,
    required this.onPlant,
    this.garden,
    this.reloadGarden,
    this.now,
  });
  final List<LetterEntry> letters;
  final VoidCallback onRecords, onReview, onMemoryBook;
  final ValueChanged<String> onPlant;
  final ValueListenable<MongiGardenData>? garden;
  final Future<void> Function()? reloadGarden;
  final DateTime Function()? now;

  @override
  State<HomeMoments> createState() => _HomeMomentsState();
}

class _HomeMomentsState extends State<HomeMoments> with WidgetsBindingObserver {
  bool _ready = false, _failed = false, _busy = false, _foreground = true;
  Timer? _midnight;
  DateTime get _now => (widget.now?.call() ?? DateTime.now()).toLocal();
  ValueListenable<MongiGardenData> get _garden =>
      widget.garden ?? MongiGardenStore.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _reload();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleMidnight();
  }

  void _scheduleMidnight() {
    _midnight?.cancel();
    if (!_foreground || !TickerMode.of(context)) return;
    final now = _now;
    final next = DateTime(now.year, now.month, now.day + 1);
    _midnight = Timer(next.difference(now), () {
      if (!mounted) return;
      setState(() {});
      _scheduleMidnight();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) {
      setState(() {});
      _reload();
    }
    _scheduleMidnight();
  }

  Future<void> _reload() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      await (widget.reloadGarden ?? MongiGardenStore.instance.reload)();
      if (mounted) setState(() => _ready = true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _ready = false;
          _failed = true;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _midnight?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Widget _entry({
    required Key key,
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) => ListTile(
    key: key,
    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
    leading: Icon(icon, color: const Color(0xff6d8869)),
    title: Text(title),
    subtitle: subtitle == null ? null : Text(subtitle),
    trailing: const Icon(Icons.chevron_right, size: 20),
    onTap: onTap,
  );

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<MongiGardenData>(
    valueListenable: _garden,
    builder: (context, garden, _) {
      final summary = HomeMomentsSnapshot(
        letters: widget.letters,
        garden: _ready ? garden : null,
        now: _now,
      );
      if (!summary.hasToday && !summary.hasRecords && !_failed) {
        return const SizedBox.shrink();
      }
      return Card(
        key: const Key('home-saved-moments'),
        elevation: 0,
        color: const Color(0xfff0f3e9),
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                tr(summary.hasToday ? '오늘 남긴 작은 흔적' : '다시 펼쳐보는 시간'),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (summary.recordsToday > 0)
                _entry(
                  key: const Key('home-saved-records'),
                  icon: Icons.edit_note,
                  title: tr('오늘의 마음 기록'),
                  subtitle: summary.recordsToday == 1
                      ? tr('기록 하나를 간직했어요.')
                      : tr('기록 {0}개를 간직했어요.', [summary.recordsToday]),
                  onTap: widget.onRecords,
                ),
              for (final plant in summary.wateredPlants)
                _entry(
                  key: ValueKey('home-watered-${plant.seed.id}'),
                  icon: Icons.water_drop_outlined,
                  title: tr('{0}에 물을 줬어요', [plant.seed.label]),
                  subtitle: tr('{0} · 정원에서 보기', [
                    plant.seed.growthLabel(plant.growth),
                  ]),
                  onTap: () => widget.onPlant(plant.seed.id),
                ),
              if (_failed)
                TextButton.icon(
                  key: const Key('home-moments-retry'),
                  onPressed: _busy ? null : _reload,
                  icon: const Icon(Icons.refresh),
                  label: Text(tr('정원 소식을 불러오지 못했어요. 다시 보기')),
                ),
              if (summary.hasRecords) ...[
                _entry(
                  key: const Key('home-reflection'),
                  icon: Icons.auto_stories_outlined,
                  title: tr('감정의 흐름 돌아보기'),
                  subtitle: tr('주간·월간 만화책과 감정 통계'),
                  onTap: widget.onReview,
                ),
                TextButton.icon(
                  key: const Key('home-memory-book'),
                  onPressed: widget.onMemoryBook,
                  icon: const Icon(Icons.book_outlined),
                  label: Text(tr('정원 기록집 펼치기')),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}
