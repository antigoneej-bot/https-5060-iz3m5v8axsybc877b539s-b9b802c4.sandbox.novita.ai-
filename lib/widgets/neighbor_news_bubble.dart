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
  });
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
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    _timer = Timer.periodic(const Duration(seconds: 45), (_) => _load());
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
    bool current() => mounted && owner == _currentOwner;
    try {
      final service = widget.service ?? GardenVillageService();
      final people = await service.listNeighbors();
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
        _requests = people.incoming.length;
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
    final valid = _owner != null && _owner == _currentOwner;
    final gifts = valid ? _gifts + _food : 0,
        cheers = valid ? _cheers : 0,
        requests = valid ? _requests : 0;
    if (!widget.expanded) {
      if (gifts + cheers == 0) return const SizedBox.shrink();
      return TweenAnimationBuilder<double>(
        key: ValueKey('$gifts:$cheers:$_owner'),
        tween: Tween(begin: .85, end: 1),
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 350),
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: FilledButton.tonalIcon(
          key: const Key('cat-neighbor-news'),
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
            color: const Color(0xffc77b86),
          ),
          label: Text(
            '${gifts > 0 ? '선물' : '응원'} ${gifts + cheers}${_more ? '+' : ''}',
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          const Text(
            '이웃 소식',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            alignment: WrapAlignment.center,
            children: [
              ActionChip(
                label: Text('받은 신청 $requests'),
                avatar: const Icon(Icons.person_add_outlined),
                onPressed: () => _open(3),
              ),
              ActionChip(
                label: Text('선물 소식 $gifts${valid && _more ? '+' : ''}'),
                avatar: const Icon(Icons.card_giftcard),
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
                label: Text('새 응원 $cheers${valid && _more ? '+' : ''}'),
                avatar: const Icon(Icons.favorite_border),
                onPressed: () => _open(2, filter: 1),
              ),
            ],
          ),
          if (valid && _more)
            const Text(
              '최근 소식 기준 · 전체 내역은 선물함에서 확인해요',
              style: TextStyle(fontSize: 12),
            ),
        ],
      ),
    );
  }
}
