import '../l10n/app_language.dart';
import 'package:flutter/material.dart';
import 'neighbor_design.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/orchard.dart';
import '../services/garden_village_service.dart';
import '../services/social_auth_service.dart';
import '../screens/orchard_screen.dart';

class OrchardGiftInbox extends StatefulWidget {
  const OrchardGiftInbox({
    super.key,
    this.service,
    this.currentAccount,
    this.compact = false,
  });
  final GardenVillageService? service;
  final bool compact;
  final String? Function()? currentAccount;
  @override
  State<OrchardGiftInbox> createState() => _OrchardGiftInboxState();
}

class _OrchardGiftInboxState extends State<OrchardGiftInbox> {
  List<Map<String, dynamic>>? _gifts;
  String? _owner, _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  String? get _currentOwner => widget.currentAccount != null
      ? widget.currentAccount!()
      : SocialAuthService.currentUser?.uid;

  Future<void> _load() async {
    final owner = _currentOwner;
    if (owner == null) {
      setState(() => _gifts = []);
      return;
    }
    try {
      final raw = await (widget.service ?? GardenVillageService())
          .orchardState();
      final data = OrchardState.fromJson(
        Map<String, dynamic>.from(raw['orchard'] as Map),
      );
      if (!mounted || owner != _currentOwner) return;
      setState(() {
        _gifts = data.gifts;
        _owner = owner;
        _error = null;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted ||
            owner != _currentOwner ||
            !(ModalRoute.of(context)?.isCurrent ?? true))
          return;
        final newest = data.gifts.fold<int>(0, (a, g) {
          final b = (g['receivedAt'] as num?)?.toInt() ?? 0;
          return a > b ? a : b;
        });
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('orchard_gifts_seen_$owner', newest);
      });
    } catch (_) {
      if (mounted && owner == _currentOwner)
        setState(() => _error = tr("과일·간식 선물을 불러오지 못했어요."));
    }
  }

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    if (_error != null)
      return TextButton(
        onPressed: _load,
        child: Text(tr("{0} 다시 시도", [_error])),
      );
    if (_gifts == null) return const LinearProgressIndicator();
    if (_owner != _currentOwner) return const SizedBox.shrink();
    if (widget.compact && _gifts!.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!widget.compact)
          Text(
            tr('과일·간식 선물 · 최근 30개'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        if (!widget.compact)
          Text(tr('과일·간식은 자동 보관돼요.'), style: const TextStyle(fontSize: 12)),
        if (!widget.compact && _gifts!.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(tr('아직 받은 과일·간식이 없어요.')),
          ),
        for (final gift in _gifts!)
          NeighborGiftRow(
            title: tr('{0} · {1} {2}개', [
              gift['senderName'] ?? tr('이웃'),
              tr(OrchardKind.byId(gift['kind'] as String).fruit),
              gift['quantity'],
            ]),
            completed: true,
            art: NeighborGiftArt(kind: gift['kind'] as String),
            onDetails: () => _openStorage(),
            action: TextButton(
              onPressed: _openStorage,
              child: Text(tr('보관 완료')),
            ),
          ),
      ],
    );
  }

  void _openStorage() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const OrchardScreen(initialTab: 1)),
  );
}
