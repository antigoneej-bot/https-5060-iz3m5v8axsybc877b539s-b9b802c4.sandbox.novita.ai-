import '../l10n/app_language.dart';
import '../mongi/models/garden_village.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../services/social_auth_service.dart';
import '../services/garden_village_service.dart';
import '../services/garden_return_store.dart';
import '../services/sound_service.dart';
import '../mongi/screens/garden_village_screen.dart';

/// Only reads real deliveries. Opening a bubble never grants a gift itself.
class NeighborNewsBubble extends StatefulWidget {
  const NeighborNewsBubble({
    super.key,
    this.expanded = false,
    this.service,
    this.currentAccount,
    this.neighbors,
  });

  /// Parent-owned snapshot avoids fetching the same neighbor list twice.
  final GardenNeighborLists? neighbors;
  final bool expanded;
  final GardenVillageService? service;
  final String? Function()? currentAccount;
  @override
  State<NeighborNewsBubble> createState() => _NeighborNewsBubbleState();
}

class _NeighborNewsBubbleState extends State<NeighborNewsBubble>
    with WidgetsBindingObserver {
  Timer? _timer;
  bool _busy = false, _foreground = true;
  String? _owner;
  int _gifts = 0, _cheers = 0, _requests = 0, _food = 0;
  bool _more = false;
  String? get _currentOwner => widget.currentAccount != null
      ? widget.currentAccount!()
      : SocialAuthService.currentUser?.uid;
  @override
  void initState() {
    super.initState();
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _foreground = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    _timer = Timer.periodic(Duration(seconds: 45), (_) => _load());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (TickerMode.of(context))
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) _load();
  }

  Future<void> _load() async {
    if (!mounted ||
        _busy ||
        !_foreground ||
        !TickerMode.of(context) ||
        !(ModalRoute.of(context)?.isCurrent ?? true))
      return;
    final owner = _currentOwner;
    if (owner == null) {
      if (_owner != null)
        setState(() {
          _owner = null;
          _gifts = _cheers = _requests = _food = 0;
        });
      return;
    }
    _busy = true;
    bool current() =>
        mounted &&
        owner == _currentOwner &&
        _foreground &&
        TickerMode.of(context) &&
        (ModalRoute.of(context)?.isCurrent ?? true);
    try {
      final service = widget.service ?? GardenVillageService();
      // Compact home news never displays incoming friend requests. The village
      // supplies its already loaded list to the expanded presentation.
      final people = widget.expanded
          ? widget.neighbors ?? await service.listNeighbors()
          : null;
      if (!current()) return;
      final page = await service.listReceivedCheers(pageSize: 30);
      if (!current()) return;
      var food = 0;
      try {
        final orchard = await service.orchardState();
        if (!current()) return;
        final gifts = ((orchard['orchard'] as Map)['gifts'] as List);
        final prefs = await SharedPreferences.getInstance();
        if (!current()) return;
        final seen = prefs.getInt('orchard_gifts_seen_$owner') ?? 0;
        food = gifts
            .where((g) => ((g as Map)['receivedAt'] as num? ?? 0) > seen)
            .length;
      } catch (_) {
        /* Flower and cheer notifications remain available. */
      }
      if (!current()) return;
      await GardenReturnStore.instance.observe(
        owner,
        page.cheers,
        retiredIds: page.retiredIds,
      );
      if (!current()) return;
      setState(() {
        _owner = owner;
        _requests = people?.incoming.length ?? 0;
        _food = food;
        _gifts = page.cheers
            .where(
              (c) =>
                  c.deliveryKind != 'cheer' && !c.claimed && !c.bloomConfirmed,
            )
            .length;
        _cheers = page.cheers
            .where(
              (c) =>
                  c.deliveryKind == 'cheer' &&
                  !c.claimed &&
                  !GardenReturnStore.instance.isSeen(owner, c.id),
            )
            .length;
        _more = page.nextCursor != null;
      });
    } catch (_) {
      // Never turn a network error into a false new-message notification.
    } finally {
      _busy = false;
    }
  }

  Future<void> _open(int tab, {int filter = 0}) async {
    unawaited(SoundService().playMeow());
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) =>
            GardenVillageScreen(initialTab: tab, inboxFilter: filter),
      ),
    );
    if (mounted) await _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    final valid = _owner != null && _owner == _currentOwner;
    final gifts = valid ? _gifts + _food : 0,
        cheers = valid ? _cheers : 0,
        requests = valid ? _requests : 0;
    if (!widget.expanded) {
      if (gifts + cheers == 0) return SizedBox.shrink();
      return TweenAnimationBuilder<double>(
        key: ValueKey('$gifts:$cheers:$_owner'),
        tween: Tween(begin: .85, end: 1),
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : Duration(milliseconds: 350),
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: FilledButton.tonalIcon(
          key: Key('cat-neighbor-news'),
          onPressed: () => _open(
            2,
            filter: _gifts > 0
                ? 0
                : _food > 0
                ? 3
                : 1,
          ),
          icon: Icon(
            gifts > 0 ? Icons.card_giftcard : Icons.favorite,
            color: Color(0xffc77b86),
          ),
          label: Text(
            '${gifts > 0 ? tr('선물') : tr('응원')} ${gifts + cheers}${_more ? '+' : ''}',
          ),
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.all(12),
      child: Column(
        children: [
          Text(
            tr("이웃 소식"),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            alignment: WrapAlignment.center,
            children: [
              ActionChip(
                label: Text(tr('받은 신청 {0}', [requests])),
                avatar: Icon(Icons.person_add_outlined),
                onPressed: () => _open(3),
              ),
              ActionChip(
                label: Text(
                  tr('선물 소식 {0}{1}', [gifts, valid && _more ? '+' : '']),
                ),
                avatar: Icon(Icons.card_giftcard),
                onPressed: () => _open(
                  2,
                  filter: _gifts > 0
                      ? 0
                      : _food > 0
                      ? 3
                      : 0,
                ),
              ),
              ActionChip(
                label: Text(
                  tr('새 응원 {0}{1}', [cheers, valid && _more ? '+' : '']),
                ),
                avatar: Icon(Icons.favorite_border),
                onPressed: () => _open(2, filter: 1),
              ),
            ],
          ),
          if (valid && _more)
            Text(
              tr("최근 소식 기준 · 전체 내역은 선물함에서 확인해요"),
              style: TextStyle(fontSize: 12),
            ),
        ],
      ),
    );
  }
}
