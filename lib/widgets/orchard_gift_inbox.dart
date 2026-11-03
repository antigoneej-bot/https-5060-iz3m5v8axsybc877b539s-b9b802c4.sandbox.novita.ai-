import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/orchard.dart';
import '../services/garden_village_service.dart';
import '../services/social_auth_service.dart';
import '../screens/orchard_screen.dart';

class OrchardGiftInbox extends StatefulWidget {
  const OrchardGiftInbox({super.key});
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

  Future<void> _load() async {
    final owner = SocialAuthService.currentUser?.uid;
    if (owner == null) return;
    try {
      final raw = await GardenVillageService().orchardState();
      final data = OrchardState.fromJson(
        Map<String, dynamic>.from(raw['orchard'] as Map),
      );
      if (!mounted || owner != SocialAuthService.currentUser?.uid) return;
      setState(() {
        _gifts = data.gifts;
        _owner = owner;
        _error = null;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted ||
            owner != SocialAuthService.currentUser?.uid ||
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
      if (mounted) setState(() => _error = '과일·간식 선물을 불러오지 못했어요.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null)
      return TextButton(onPressed: _load, child: Text('$_error 다시 시도'));
    if (_gifts == null) return const LinearProgressIndicator();
    if (_owner != SocialAuthService.currentUser?.uid)
      return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '과일·간식 선물 · 최근 30개',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const Text('창고에 자동으로 받았어요. 간식은 고양이에게 줄 수 있어요.'),
        if (_gifts!.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('아직 받은 과일·간식이 없어요.'),
          ),
        for (final gift in _gifts!)
          Card(
            child: ListTile(
              leading: const Icon(Icons.card_giftcard),
              title: Text(
                '${gift['senderName'] ?? '이웃'} · ${OrchardKind.byId(gift['kind'] as String).fruit} ${gift['quantity']}개',
              ),
              subtitle: const Text('창고 보관 완료'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const OrchardScreen(initialTab: 1),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
