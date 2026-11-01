import '../widgets/premium_test_access.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/orchard.dart';
import '../models/companion_behavior.dart';
import '../services/orchard_service.dart';
import '../services/cloud_service.dart';
import '../services/social_auth_service.dart';
import '../widgets/account_entry_card.dart';
import '../widgets/companion_presence.dart';
import '../widgets/orchard_tree_art.dart';

class OrchardScreen extends StatefulWidget {
  final OrchardService? service;
  final Stream<String?>? accountChanges;
  const OrchardScreen({super.key, this.service, this.accountChanges});
  @override
  State<OrchardScreen> createState() => _OrchardScreenState();
}

class _OrchardScreenState extends State<OrchardScreen>
    with WidgetsBindingObserver {
  late OrchardService service;
  OrchardState? state;
  bool loading = true, busy = false, needsAccount = false;
  String? error;
  int epoch = 0, tab = 0, page = 0;
  StreamSubscription<String?>? auth;
  @override
  void initState() {
    super.initState();
    service = widget.service ?? OrchardService();
    WidgetsBinding.instance.addObserver(this);
    final changes =
        widget.accountChanges ??
        (SocialAuthService.firebaseReady
            ? FirebaseAuth.instance.authStateChanges().map((u) => u?.uid)
            : null);
    var owner = service.village.accountOwner;
    auth = changes?.listen((next) {
      if (next == owner) return;
      owner = next;
      epoch++;
      service = widget.service ?? OrchardService();
      setState(() {
        state = null;
        busy = false;
        error = null;
      });
      _load();
    });
    _load();
  }

  @override
  void dispose() {
    epoch++;
    auth?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed && !busy && !loading) _load();
  }

  Future<void> _load() async {
    final token = ++epoch;
    setState(() {
      loading = true;
      error = null;
      needsAccount = false;
    });
    try {
      final next = await service.load();
      if (mounted && token == epoch) setState(() => state = next);
    } catch (e) {
      if (mounted && token == epoch)
        setState(() {
          state = null;
          error = e.toString();
          needsAccount =
              e is CloudException && e.code == 'authentication-required';
        });
    } finally {
      if (mounted && token == epoch) setState(() => loading = false);
    }
  }

  void note(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _act(
    String op,
    OrchardKind kind, {
    int quantity = 1,
    String? target,
  }) async {
    if (busy || loading) return;
    final token = epoch;
    setState(() => busy = true);
    try {
      final result = await service.act(
        op,
        kind.id,
        quantity: quantity,
        gardenId: target,
      );
      if (!mounted || token != epoch) return;
      setState(
        () => state = OrchardState.fromJson(
          Map<String, dynamic>.from(result['orchard']),
        ),
      );
      final count = (result['result'] as Map)['quantity'];
      if (op == 'feed') {
        await showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('냠냠, 고마워요!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(seconds: 3),
                  builder: (_, value, __) => SizedBox(
                    width: 180,
                    height: 180,
                    child: CompanionPresence(
                      interaction: CompanionInteraction.eating,
                      interactionProgress: value,
                    ),
                  ),
                ),
                Text('${kind.fruit} 1개를 맛있게 먹었어요.'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('쓰담쓰담'),
              ),
            ],
          ),
        );
      } else {
        note(switch (op) {
          'harvest' => '${kind.fruit} $count개를 창고에 담았어요!',
          'water' => '물을 주었어요. 열매가 쑥쑥 자라요.',
          'buy' => '${kind.name}를 심었어요.',
          'gift' => '${kind.fruit} $count개를 선물했어요.',
          'sell' => '정원 코인 ${(result['result'] as Map)['coins']}개를 모았어요.',
          _ => '완료했어요.',
        });
      }
    } catch (e) {
      if (mounted && token == epoch) {
        setState(() => error = e.toString());
        note(e.toString());
      }
    } finally {
      if (mounted && token == epoch) setState(() => busy = false);
    }
  }

  Future<void> _stockAction(String op, OrchardKind kind) async {
    if (busy || loading) return;
    final stock = state?.stock[kind.id] ?? 0;
    if (stock < 1) return;
    final token = epoch;
    String? target;
    String? name;
    if (op == 'gift') {
      setState(() => busy = true);
      try {
        final people = await service.village.listNeighbors();
        if (!mounted || token != epoch) return;
        if (people.neighbors.isEmpty) {
          note('먼저 냥이 마을에서 이웃을 맺어 주세요.');
          return;
        }
        final chosen = await showModalBottomSheet<String>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (c) => SizedBox(
            height: MediaQuery.sizeOf(c).height * .6,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('선물할 이웃을 골라 주세요'),
                ),
                Expanded(
                  child: ListView(
                    children: [
                      for (final p in people.neighbors)
                        ListTile(
                          title: Text(p.nickname ?? '이웃'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.pop(c, p.gardenId),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
        if (chosen == null || !mounted || token != epoch) return;
        target = chosen;
        name =
            people.neighbors.firstWhere((p) => p.gardenId == chosen).nickname ??
            '이웃';
      } catch (e) {
        if (mounted && token == epoch) note(e.toString());
        return;
      } finally {
        if (mounted && token == epoch) setState(() => busy = false);
      }
    }
    if (!mounted || token != epoch) return;
    var quantity = 1;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, update) => AlertDialog(
          title: Text(op == 'sell' ? '${kind.fruit} 판매' : '$name님에게 선물'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('창고에 $stock개 있어요.'),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      tooltip: '수량 줄이기',
                      onPressed: quantity > 1
                          ? () => update(() => quantity--)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text('$quantity개', key: const Key('orchard-quantity')),
                    IconButton(
                      tooltip: '수량 늘리기',
                      onPressed: quantity < math.min(stock, 999)
                          ? () => update(() => quantity++)
                          : null,
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () =>
                      update(() => quantity = math.min(stock, 999)),
                  child: const Text('가능한 만큼'),
                ),
                Text(
                  op == 'sell'
                      ? '정원 코인 ${quantity * kind.sale}개를 받아요.'
                      : '내 창고에서 차감되어 이웃 창고에 들어가요.',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('취소'),
            ),
            FilledButton(
              key: const Key('orchard-confirm'),
              onPressed: () => Navigator.pop(c, true),
              child: Text(op == 'sell' ? '판매하기' : '선물 보내기'),
            ),
          ],
        ),
      ),
    );
    if (accepted == true && mounted && token == epoch)
      await _act(op, kind, quantity: quantity, target: target);
  }

  @override
  Widget build(BuildContext context) {
    final owned = OrchardKind.all
        .where((k) => state?.trees.containsKey(k.id) ?? false)
        .toList();
    return Scaffold(
      backgroundColor: const Color(0xfffffaf2),
      appBar: AppBar(
        title: const Text('열매 정원 · 창고'),
        actions: [
          IconButton(
            tooltip: '새로고침 · 이전 요청 확인',
            onPressed: busy || loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (busy || loading) const LinearProgressIndicator(),
            const PremiumFeatureLabel('열매 나무 5종'),
            if (state != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: Row(
                  children: [
                    const Icon(Icons.toll, color: Color(0xffb58c45)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '정원 코인 ${state!.coins}개',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 8,
                children: [
                  for (var i = 0; i < 3; i++)
                    ChoiceChip(
                      label: Text(['나무 돌보기', '수확 창고', '묘목 상점'][i]),
                      selected: tab == i,
                      onSelected: busy ? null : (_) => setState(() => tab = i),
                    ),
                ],
              ),
            ),
            Expanded(
              child: state == null
                  ? Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (needsAccount) ...[
                              const Text('나무와 수확물을 계정에 안전하게 보관해요.'),
                              const SizedBox(height: 16),
                              AccountEntryCard(onChanged: _load),
                            ] else if (error != null) ...[
                              Text(error!),
                              TextButton(
                                onPressed: loading ? null : _load,
                                child: const Text('다시 확인하기'),
                              ),
                            ] else
                              const Text('우리 나무를 불러오고 있어요…'),
                          ],
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                      children: [
                        if (error != null)
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                children: [
                                  Text(error!),
                                  TextButton(
                                    onPressed: busy || loading ? null : _load,
                                    child: const Text('새로고침 · 이전 요청 확인'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (tab == 0) ...[
                          const Text(
                            '좌우로 넘겨 우리 나무를 만나세요',
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(
                            height:
                                MediaQuery.textScalerOf(context).scale(14) > 20
                                ? 680
                                : 510,
                            child: PageView.builder(
                              itemCount: owned.length,
                              onPageChanged: (n) => setState(() => page = n),
                              itemBuilder: (c, i) {
                                final kind = owned[i],
                                    tree = state!.trees[kind.id]!;
                                return Card(
                                  color: const Color(0xffedf4e8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(32),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      children: [
                                        Text(
                                          kind.name,
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Expanded(
                                          child: Center(
                                            child: AspectRatio(
                                              aspectRatio: 300 / 270,
                                              child: OrchardTreeArt(
                                                kind: kind,
                                                stage: tree.stage,
                                                fruitCount: tree.yieldCount,
                                                ripe: tree.ready,
                                                grown: tree.cycle > 0,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Text(
                                          tree.ready
                                              ? '열매 ${tree.yieldCount}개가 익었어요!'
                                              : tree.stageLabel,
                                        ),
                                        const SizedBox(height: 12),
                                        LinearProgressIndicator(
                                          value: tree.progress,
                                          minHeight: 8,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          '예상 수확 ${tree.yieldCount}개 · 돌봄 ${tree.care}/5',
                                        ),
                                        const SizedBox(height: 12),
                                        Wrap(
                                          spacing: 8,
                                          children: [
                                            OutlinedButton.icon(
                                              key: ValueKey('water-${kind.id}'),
                                              onPressed:
                                                  busy ||
                                                      loading ||
                                                      !tree.canWater
                                                  ? null
                                                  : () => _act('water', kind),
                                              icon: const Icon(
                                                Icons.water_drop_outlined,
                                              ),
                                              label: const Text('물주기'),
                                            ),
                                            FilledButton.icon(
                                              key: ValueKey(
                                                'harvest-${kind.id}',
                                              ),
                                              onPressed:
                                                  busy || loading || !tree.ready
                                                  ? null
                                                  : () => _act('harvest', kind),
                                              icon: const Icon(
                                                Icons.shopping_basket_outlined,
                                              ),
                                              label: const Text('수확하기'),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          Text(
                            '${math.min(page + 1, owned.length)} / ${owned.length}',
                            textAlign: TextAlign.center,
                          ),
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              '열매 나무는 구독 기능이며, 테스트에서는 사과나무 한 그루로 시작해요.\n기본 7일이면 익고, 물을 주면 12시간 더 빨리 자라요. 한국 시간 기준 하루 한 번, 최대 5번 돌보면 10개에서 30개까지 수확해요.\n접속하지 않아도 시들지 않고, 익은 열매는 사라지지 않아요.',
                            ),
                          ),
                        ] else if (tab == 1) ...[
                          const Text(
                            '수확물은 여기에 차곡차곡 쌓여요.',
                            style: TextStyle(fontSize: 18),
                          ),
                          for (final kind in OrchardKind.all)
                            Card(
                              color: Colors.white,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${kind.fruit}  ${state!.stock[kind.id] ?? 0}개',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text('1개 판매 → 정원 코인 ${kind.sale}개'),
                                    Wrap(
                                      spacing: 8,
                                      children: [
                                        TextButton(
                                          onPressed:
                                              busy ||
                                                  loading ||
                                                  (state!.stock[kind.id] ??
                                                          0) ==
                                                      0
                                              ? null
                                              : () =>
                                                    _stockAction('sell', kind),
                                          child: const Text('판매'),
                                        ),
                                        TextButton(
                                          onPressed:
                                              busy ||
                                                  loading ||
                                                  (state!.stock[kind.id] ??
                                                          0) ==
                                                      0
                                              ? null
                                              : () =>
                                                    _stockAction('gift', kind),
                                          child: const Text('이웃 선물'),
                                        ),
                                        if (kind.edible)
                                          TextButton(
                                            onPressed:
                                                busy ||
                                                    loading ||
                                                    (state!.stock[kind.id] ??
                                                            0) ==
                                                        0
                                                ? null
                                                : () => _act('feed', kind),
                                            child: const Text('고양이에게 1개 주기'),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                          const Text(
                            '이웃에게 받은 선물 · 최근 30개',
                            style: TextStyle(fontSize: 20),
                          ),
                          if (state!.gifts.isEmpty)
                            const Text('이웃이 보내준 열매도 이 창고로 들어와요.'),
                          for (final gift in state!.gifts)
                            ListTile(
                              leading: const Icon(Icons.card_giftcard),
                              title: Text('${gift['senderName']}님이 보내준 선물'),
                              subtitle: Text(
                                '${OrchardKind.byId(gift['kind']).fruit} ${gift['quantity']}개',
                              ),
                            ),
                        ] else ...[
                          const Text(
                            '열매를 판매한 코인으로 새 묘목을 심어요.\n정원 코인은 묘목용이며 빛의 정수와 별도로 모아요. 현금 구매는 없어요.',
                          ),
                          for (final kind in OrchardKind.all)
                            Card(
                              color: const Color(0xfff5eef8),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    SizedBox(
                                      height: 145,
                                      width: 165,
                                      child: OrchardTreeArt(kind: kind),
                                    ),
                                    Text(
                                      kind.name,
                                      style: const TextStyle(fontSize: 22),
                                    ),
                                    Text('${kind.fruit} 10~30개 · 한 종류당 한 그루'),
                                    const SizedBox(height: 8),
                                    FilledButton(
                                      onPressed:
                                          busy ||
                                              loading ||
                                              state!.trees.containsKey(
                                                kind.id,
                                              ) ||
                                              state!.coins < kind.price
                                          ? null
                                          : () => _act('buy', kind),
                                      child: Text(
                                        state!.trees.containsKey(kind.id)
                                            ? '우리 정원에서 자라는 중'
                                            : '${kind.price}코인으로 심기',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
