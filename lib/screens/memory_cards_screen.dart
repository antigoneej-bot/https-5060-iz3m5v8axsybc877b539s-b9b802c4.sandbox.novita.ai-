import '../l10n/app_language.dart';
import 'package:flutter/material.dart';
import '../services/memory_card_service.dart';
import '../services/cloud_service.dart';
import '../widgets/memory_card_art.dart';
import '../models/companion_coat.dart';
import '../mongi/models/garden_village.dart';

class MemoryCardsScreen extends StatefulWidget {
  final MemoryCardService? service;
  const MemoryCardsScreen({super.key, this.service});
  @override
  State<MemoryCardsScreen> createState() => _MemoryCardsScreenState();
}

class _MemoryCardsScreenState extends State<MemoryCardsScreen>
    with WidgetsBindingObserver {
  late final service = widget.service ?? MemoryCardService();
  Map<String, dynamic>? data;
  String? error;
  bool busy = false;
  int tab = 0;
  Map<String, dynamic> get cards =>
      Map<String, dynamic>.from(data?['cards'] ?? {});
  Map<String, dynamic> get stock =>
      Map<String, dynamic>.from(cards['stock'] ?? {});
  List<String> get display => List<String>.from(cards['display'] ?? []);
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed && !busy) load();
  }

  void message(String s) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  }

  Future<void> load() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final d = await service.load();
      if (mounted)
        setState(() {
          data = d;
          error = null;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          data = null;
          error = e is CloudException
              ? e.toString()
              : tr("카드를 불러오지 못했어요. 다시 시도해주세요.");
        });
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> act(String action, Map<String, dynamic> body) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final r = await service.village.memoryCards(action, body);
      if (action == 'claimMemoryCard')
        message(
          r['already'] == true
              ? tr("오늘의 카드는 이미 받았어요. 내일 다시 만나요.")
              : tr("새로운 추억 카드를 만났어요!"),
        );
      final d = await service.load();
      if (mounted)
        setState(() {
          data = d;
          error = null;
        });
    } catch (e) {
      message(e is CloudException ? e.toString() : tr("처리 결과를 새로고침해서 확인해주세요."));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<bool> confirm(String title, String body) async =>
      await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(tr("돌아가기")),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(tr("확인")),
            ),
          ],
        ),
      ) ??
      false;
  String title(String id) {
    final p = id.split('.');
    final coat = CompanionCoat.parse(p[1]);
    return '${memoryThemes[p[0]]} · ${coat?.label ?? ''} · ${[tr("햇살"), tr("물빛"), tr("별빛")][int.parse(p[2])]}';
  }

  Future<void> neighbors() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final list = await service.village.listNeighbors();
      if (!mounted) return;
      if (list.neighbors.isEmpty) {
        message(tr("냥이 마을에서 서로 이웃이 되면 진열장을 구경하고 교환할 수 있어요."));
        return;
      }
      final n = await showModalBottomSheet<GardenNeighbor>(
        context: context,
        useSafeArea: true,
        builder: (ctx) => ListView(
          shrinkWrap: true,
          children: [
            ListTile(title: Text(tr("이웃 진열장"))),
            for (final n in list.neighbors)
              ListTile(
                title: Text(n.displayName),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pop(ctx, n),
              ),
          ],
        ),
      );
      if (n == null || !mounted) return;
      final r = await service.village.memoryCards('getCardShowcase', {
        'gardenId': n.gardenId,
      });
      if (!mounted) return;
      final theirs = List<String>.from(r['duplicates'] ?? []),
          mine = stock.keys.where((k) => (stock[k] as num) > 1).toList();
      final wanted = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (ctx) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: .8,
          builder: (ctx, scroll) => ListView(
            controller: scroll,
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                tr("{0}의 진열장", [n.displayName]),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(tr("응원 {0}개", [r['hearts'] ?? 0])),
              for (final id in List<String>.from(r['display'] ?? []))
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: SizedBox(height: 270, child: MemoryCardArt(id)),
                ),
              if ((r['display'] as List? ?? []).isEmpty)
                Text(tr("아직 진열한 카드가 없어요.")),
              FilledButton.tonal(
                onPressed: () async {
                  try {
                    await service.village.memoryCards('cheerCardShowcase', {
                      'gardenId': n.gardenId,
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                    message(tr("오늘의 응원을 남겼어요."));
                  } catch (e) {
                    message(e.toString());
                  }
                },
                child: Text(tr("예뻐요 ♡ · 하루 한 번")),
              ),
              const SizedBox(height: 16),
              Text(tr("이웃의 교환 가능한 중복 카드")),
              for (final want in theirs)
                ListTile(
                  title: Text(title(want)),
                  leading: const Icon(Icons.style),
                  trailing: const Icon(Icons.swap_horiz),
                  onTap: mine.where((x) => x != want).isEmpty
                      ? null
                      : () => Navigator.pop(ctx, want),
                ),
              if (theirs.isEmpty) Text(tr("아직 교환 가능한 카드가 없어요.")),
              if (mine.isEmpty) Text(tr("내 중복 카드가 생기면 교환을 제안할 수 있어요.")),
            ],
          ),
        ),
      );
      if (wanted != null && mounted)
        await offer(n, wanted, mine.where((x) => x != wanted).toList());
    } catch (e) {
      message(e is CloudException ? e.toString() : tr("이웃 진열장을 열지 못했어요."));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> offer(GardenNeighbor n, String want, List<String> mine) async {
    final give = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      builder: (ctx) => ListView(
        shrinkWrap: true,
        children: [
          ListTile(title: Text(tr("내가 보낼 중복 카드"))),
          for (final id in mine)
            ListTile(
              title: Text(title(id)),
              subtitle: Text(tr("{0}장 보유", [stock[id]])),
              onTap: () => Navigator.pop(ctx, id),
            ),
        ],
      ),
    );
    if (give == null || !mounted) return;
    if (!await confirm(
      tr("교환 제안"),
      tr(
        "{0}에게\n보낼 카드: {1}\n받을 카드: {2}\n\n보낼 한 장은 교환함에 보관해요. 상대가 수락해야 교환되고, 취소하면 돌려받아요.",
        [n.displayName, title(give), title(want)],
      ),
    ))
      return;
    try {
      await service.offer(n.gardenId, give, want);
      message(tr("교환을 제안했어요. 교환함에서 확인해주세요."));
      final d = await service.load();
      if (mounted) setState(() => data = d);
    } catch (e) {
      message(e.toString());
    }
  }

  Future<void> detail(String id) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 370, child: MemoryCardArt(id)),
            Text(tr("{0}장 보유", [stock[id]])),
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      final next = display;
                      if (next.contains(id)) {
                        next.remove(id);
                      } else {
                        if (next.length >= 3) {
                          message(tr("진열은 3장까지예요. 먼저 다른 카드를 내려주세요."));
                          return;
                        }
                        next.add(id);
                      }
                      Navigator.pop(ctx);
                      await act('setCardDisplay', {'cards': next});
                    },
              child: Text(
                display.contains(id) ? tr("진열장에서 내리기") : tr("대표 카드로 진열하기"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    final ids = stock.keys.where((id) => (stock[id] as num) > 0).toList();
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7F0),
      appBar: AppBar(
        title: Text(tr("마음냥 추억 카드")),
        actions: [
          IconButton(
            onPressed: busy ? null : load,
            tooltip: tr("새로고침"),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              tr("고양이와 만나는 작은 선물"),
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
            ),
            Text(tr("장면·고양이·테두리가 다른 카드를 모아요. 감정을 모두 채우지 않아도 괜찮아요.")),
            if (busy) const LinearProgressIndicator(),
            if (error != null) ...[
              Text(error!),
              Text(tr("서버 업데이트와 로그인이 필요해요. 기존 감정 기록은 그대로 보존돼요.")),
              TextButton(
                onPressed: busy ? null : load,
                child: Text(tr("다시 불러오기")),
              ),
            ],
            if (data != null) ...[
              Wrap(
                spacing: 8,
                children: [
                  for (var i = 0; i < 3; i++)
                    ChoiceChip(
                      label: Text(
                        [
                          tr("내 카드 {0}종", [ids.length]),
                          tr("교환함"),
                          tr("내 진열장"),
                        ][i],
                      ),
                      selected: tab == i,
                      onSelected: (_) => setState(() => tab = i),
                    ),
                ],
              ),
              if (tab == 0) ...[
                FilledButton.icon(
                  onPressed: busy
                      ? null
                      : () => act('claimMemoryCard', {'source': 'daily'}),
                  icon: const Icon(Icons.card_giftcard),
                  label: Text(tr("오늘의 추억 카드 받기")),
                ),
                Text(tr("무료 · 하루 한 장")),
                const SizedBox(height: 12),
                if (ids.isEmpty) Text(tr("첫 번째 카드를 만나보세요.")),
                LayoutBuilder(
                  builder: (ctx, c) => Wrap(
                    spacing: 12,
                    runSpacing: 16,
                    children: [
                      for (final id in ids)
                        SizedBox(
                          width: (c.maxWidth - 12) / 2,
                          child: InkWell(
                            onTap: () => detail(id),
                            child: Column(
                              children: [
                                MemoryCardArt(id),
                                Text(
                                  tr("{0}장{1}", [
                                    stock[id],
                                    display.contains(id) ? tr(" · 진열 중") : '',
                                  ]),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              if (tab == 1) ...[
                Text(
                  tr(
                    "중복 카드 한 장씩 교환해요. 제안은 7일간 유효해요. 만료된 제안은 취소·거절하면 보관한 카드를 돌려받아요.",
                  ),
                ),
                FilledButton.tonal(
                  onPressed: busy ? null : neighbors,
                  child: Text(tr("이웃 카드 구경 · 교환 제안")),
                ),
                for (final raw in (data!['trades'] as List))
                  Builder(
                    builder: (ctx) {
                      final t = Map<String, dynamic>.from(raw),
                          sender = t['sender'] == data!['owner'];
                      final pending = t['status'] == 'pending';
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sender ? tr("보낸 제안") : tr("받은 제안"),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                tr("보내는 카드: {0}", [
                                  title(t[sender ? 'give' : 'want']),
                                ]),
                              ),
                              Text(
                                tr("받는 카드: {0}", [
                                  title(t[sender ? 'want' : 'give']),
                                ]),
                              ),
                              Text(
                                {
                                      'pending': tr("수락 대기"),
                                      'accepted': tr("교환 완료"),
                                      'cancelled': tr("취소 · 반환 완료"),
                                      'declined': tr("거절 · 반환 완료"),
                                    }[t['status']] ??
                                    t['status'],
                              ),
                              if (pending)
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    if (!sender)
                                      FilledButton(
                                        onPressed: busy
                                            ? null
                                            : () async {
                                                if (await confirm(
                                                  tr("교환 수락"),
                                                  tr(
                                                    "표시된 카드 한 장씩을 서로 바꿀까요? 수락하면 동시에 교환돼요.",
                                                  ),
                                                ))
                                                  await act(
                                                    'respondCardTrade',
                                                    {
                                                      'id': t['id'],
                                                      'response': 'accept',
                                                    },
                                                  );
                                              },
                                        child: Text(tr("수락")),
                                      ),
                                    TextButton(
                                      onPressed: busy
                                          ? null
                                          : () => act('respondCardTrade', {
                                              'id': t['id'],
                                              'response': sender
                                                  ? 'cancel'
                                                  : 'decline',
                                            }),
                                      child: Text(
                                        sender ? tr("취소하고 돌려받기") : tr("거절"),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                if ((data!['trades'] as List).isEmpty)
                  Text(tr("아직 교환 제안이 없어요.")),
              ],
              if (tab == 2) ...[
                Text(tr("이웃에게 보여주는 대표 카드 · {0}/3", [display.length])),
                Text(tr("받은 응원 {0}개", [cards['hearts'] ?? 0])),
                Text(tr("내 카드에서 마음에 드는 카드를 눌러 진열하세요. 서로 이웃인 사람만 볼 수 있어요.")),
                for (final id in display)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: SizedBox(
                      height: 310,
                      child: InkWell(
                        onTap: () => detail(id),
                        child: MemoryCardArt(id),
                      ),
                    ),
                  ),
                FilledButton.tonal(
                  onPressed: busy ? null : neighbors,
                  child: Text(tr("이웃 진열장 구경하기")),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
