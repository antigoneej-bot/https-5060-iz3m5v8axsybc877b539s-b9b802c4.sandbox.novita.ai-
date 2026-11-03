import 'cat_visit_inbox_screen.dart';
import 'garden_discovery_screen.dart';
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../services/garden_village_service.dart';
import '../../services/shared_tree_service.dart';
import '../../services/social_auth_service.dart';
import '../../theme.dart' show AppColors;
import '../../widgets/account_entry_card.dart';
import '../models/garden_village.dart';
import 'garden_visit_screen.dart';
import 'public_garden_inbox_screen.dart';
import 'public_garden_settings_screen.dart';
import 'shared_trees_screen.dart';

/// A small directory of real neighbors, rather than a second, simulated garden.
class GardenVillageScreen extends StatefulWidget {
  const GardenVillageScreen({
    super.key,
    this.service,
    this.accountReady,
    this.currentAccount,
    this.accountChanges,
    this.initialTab = 0,
    this.inboxFilter = 0,
    this.sharedTreeService,
  });
  final GardenVillageService? service;
  final SharedTreeService? sharedTreeService;
  final Future<bool> Function()? accountReady;
  final String? Function()? currentAccount;
  final Stream<String?>? accountChanges;
  final int initialTab, inboxFilter;

  @override
  State<GardenVillageScreen> createState() => _GardenVillageScreenState();
}

class _GardenVillageScreenState extends State<GardenVillageScreen>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  // Keeps this screen's State (and its cached _profile/_neighbors) alive
  // while the parent PageView scrolls this tab off-screen, instead of
  // disposing it on every tab switch and forcing a full reload on return.
  @override
  bool get wantKeepAlive => true;

  late GardenVillageService _service;
  late SharedTreeService _sharedTrees;
  bool _hasTreeActivity = false;
  StreamSubscription<String?>? _accountSubscription;
  GardenVillageProfile? _profile;
  GardenNeighborLists? _neighbors;
  bool _loading = true, _needsAccount = false, _busy = false;
  String? _error, _owner;
  int _request = 0, _tab = 0;
  // Tracks TickerMode transitions so a return visit (inactive -> active)
  // with cached data already present can refresh quietly in the background
  // instead of showing a loading spinner again.
  bool? _tickerActive;

  String? get _currentOwner => widget.currentAccount != null
      ? widget.currentAccount!()
      : SocialAuthService.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? GardenVillageService();
    _sharedTrees = widget.sharedTreeService ?? SharedTreeService();
    _tab = widget.initialTab.clamp(0, 3);
    _owner = _currentOwner;
    WidgetsBinding.instance.addObserver(this);
    final changes =
        widget.accountChanges ??
        (SocialAuthService.firebaseReady
            ? FirebaseAuth.instance.authStateChanges().map((u) => u?.uid)
            : null);
    _accountSubscription = changes?.listen((owner) {
      if (!mounted || owner == _owner) return;
      _owner = owner;
      _request++;
      _service = widget.service ?? GardenVillageService();
      _sharedTrees = widget.sharedTreeService ?? SharedTreeService();
      setState(() {
        _profile = null;
        _neighbors = null;
        _hasTreeActivity = false;
        _error = null;
        _busy = false;
        _tab = 0;
      });
      _load();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_tab == 0 || _tab == 3) _load();
    });
  }

  @override
  void dispose() {
    _request++;
    _accountSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final active = TickerMode.of(context);
    final wasActive = _tickerActive;
    _tickerActive = active;
    // Only react to an inactive -> active transition (tab re-entry), and
    // only when we already have cached data to show while refreshing.
    if (active && wasActive == false && _profile != null && _tab != 2) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _load(silent: true));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _tab != 2) {
      _load(silent: _profile != null);
    }
  }

  // [silent]: when true and cached data already exists, refresh in the
  // background without clearing _profile/_neighbors or showing the
  // full-screen spinner (stale-while-revalidate), so re-entering an
  // already-loaded tab doesn't flash a reload every time.
  Future<void> _load({bool silent = false}) async {
    if (!mounted) return;
    final hadData = _profile != null;
    silent = silent && hadData;
    final request = ++_request;
    final owner = _currentOwner;
    if (silent) {
      setState(() => _error = null);
    } else {
      setState(() {
        _loading = true;
        _needsAccount = false;
        _error = null;
        _profile = null;
        _neighbors = null;
        _hasTreeActivity = false;
      });
    }
    try {
      final ready =
          await (widget.accountReady?.call() ??
              SocialAuthService.isAccountReady());
      if (!mounted || request != _request) return;
      if (!ready) {
        setState(() {
          _loading = false;
          _needsAccount = true;
        });
        return;
      }
      if (owner != _owner) {
        _owner = owner;
        _service = widget.service ?? GardenVillageService();
        _sharedTrees = widget.sharedTreeService ?? SharedTreeService();
      }
      // Independent reads: run concurrently instead of waiting on getProfile()
      // before starting listNeighbors(), which halved this screen's network
      // latency in practice.
      final results = await Future.wait([
        _service.getProfile(),
        _service.listNeighbors(),
      ]);
      final profile = results[0] as GardenVillageProfile;
      final neighbors = results[1] as GardenNeighborLists;
      if (!mounted || request != _request || owner != _currentOwner) return;
      setState(() {
        _profile = profile;
        _neighbors = neighbors;
        _needsAccount = false;
        _loading = false;
      });
      // This optional badge cannot block the existing directory on an older server.
      unawaited(_loadTreeBadge(request, owner));
    } catch (error) {
      if (!mounted || request != _request || owner != _currentOwner) return;
      if (silent) {
        // Keep showing the already-loaded (stale) content rather than
        // replacing it with an error screen over a failed background
        // refresh; the next pull-to-refresh or foreground event can retry.
        return;
      }
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadTreeBadge(int request, String? owner) async {
    try {
      final unread = await _sharedTrees.hasUnreadActivity();
      if (mounted && request == _request && owner == _currentOwner) {
        setState(() => _hasTreeActivity = unread);
      }
    } catch (_) {
      // No invented activity or error wall when only the optional summary fails.
    }
  }

  void _message(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _action(Future<void> Function() action, String success) async {
    if (_busy) return;
    final owner = _currentOwner;
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted || owner != _currentOwner) return;
      _message(success);
      await _load();
    } catch (error) {
      if (mounted && owner == _currentOwner) _message(error.toString());
    } finally {
      if (mounted && owner == _currentOwner) setState(() => _busy = false);
    }
  }

  Future<void> _invite() async {
    final request = _request;
    final code = await showDialog<String>(
      context: context,
      builder: (_) => const _FriendCodeDialog(),
    );
    if (code == null ||
        code.isEmpty ||
        !mounted ||
        _busy ||
        request != _request) {
      return;
    }
    final owner = _currentOwner;
    setState(() => _busy = true);
    try {
      final person = await _service.lookupInvite(code);
      if (!mounted || owner != _currentOwner || request != _request) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('${_name(person.nickname)}님에게 이웃 신청'),
          content: const Text(
            '상대가 수락하면 서로 내 이웃 목록에서 찾아갈 수 있어요. 편지와 감정 기록은 공유되지 않아요.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('이웃 신청'),
            ),
          ],
        ),
      );
      if (confirmed != true ||
          !mounted ||
          owner != _currentOwner ||
          request != _request) {
        return;
      }
      await _service.requestNeighbor(inviteCode: code);
      if (!mounted || owner != _currentOwner || request != _request) return;
      _message('이웃 신청을 보냈어요. 상대가 수락하면 연결돼요.');
      setState(() => _busy = false);
      await _load();
    } catch (error) {
      if (mounted && owner == _currentOwner && request == _request) {
        _message(error.toString());
      }
    } finally {
      if (mounted && owner == _currentOwner && request == _request) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _manageNeighbor(GardenNeighbor person, String action) async {
    if (_busy) return;
    final request = _request;
    final block = action == 'block';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(block ? '이 이웃을 차단할까요?' : '이웃 연결을 해제할까요?'),
        content: Text(
          block ? '서로 정원 방문과 응원·선물을 할 수 없게 돼요.' : '다시 연결하려면 이웃 신청과 수락이 필요해요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(block ? '차단' : '연결 해제'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || request != _request) return;
    await _action(
      () => block
          ? _service.blockNeighbor(person.gardenId)
          : _service.removeNeighbor(person.gardenId),
      block ? '이웃을 차단했어요.' : '이웃 연결을 해제했어요.',
    );
  }

  Future<void> _settings() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const PublicGardenSettingsScreen(),
      ),
    );
    if (mounted) _load();
  }

  String _name(String? name) =>
      name?.trim().isNotEmpty == true ? name!.trim() : '이웃';

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        title: const Text('이웃'),
        backgroundColor: AppColors.bg0,
        actions: [
          IconButton(
            tooltip: '정원 공개와 받기 설정',
            onPressed: _settings,
            icon: const Icon(Icons.tune),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: SizedBox(
              width: double.infinity,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('내 이웃')),
                    ButtonSegment(value: 3, label: Text('신청')),
                    ButtonSegment(value: 2, label: Text('선물함')),
                    ButtonSegment(value: 1, label: Text('찾기')),
                  ],
                  selected: {_tab},
                  showSelectedIcon: false,
                  onSelectionChanged: (value) {
                    setState(() => _tab = value.first);
                    if (_tab == 0 || _tab == 3 || _tab == 1) _load();
                  },
                ),
              ),
            ),
          ),
        ),
      ),
      body: _tab == 2
          ? PublicGardenInboxScreen(
              key: ValueKey('inbox:$_owner'),
              embedded: true,
              initialFilter: widget.inboxFilter,
              service: widget.service,
              accountReady: widget.accountReady,
              currentAccount: widget.currentAccount,
            )
          : RefreshIndicator(onRefresh: _load, child: _body()),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_needsAccount) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('로그인하면 내 이웃과 받은 마음을 다른 휴대폰에서도 이어갈 수 있어요.'),
          const SizedBox(height: 16),
          AccountEntryCard(
            onChanged: () async {
              _service = widget.service ?? GardenVillageService();
              _sharedTrees = widget.sharedTreeService ?? SharedTreeService();
              await _load();
            },
          ),
        ],
      );
    }
    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.cloud_off_outlined, size: 40),
          const SizedBox(height: 16),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: _load, child: const Text('다시 연결하기')),
        ],
      );
    }
    final profile = _profile!;
    final people = _neighbors!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Wrap(
          spacing: 8,
          children: [
            ActionChip(
              label: Text('받은 신청 ${people.incoming.length}'),
              onPressed: () => setState(() => _tab = 3),
            ),
            ActionChip(
              label: const Text('받은 선물·응원'),
              onPressed: () => setState(() => _tab = 2),
            ),
          ],
        ),
        if (_tab == 1) ...[
          const Text(
            '정원을 오가며 작은 마음을 나눠요.',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            '응원에 꼭 답례하지 않아도 괜찮아요. 편지와 감정 통계는 나만 볼 수 있어요.',
            style: TextStyle(color: AppColors.inkSoft, height: 1.5),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const Key('village-random-browse'),
            onPressed: () => Navigator.push<void>(
              context,
              MaterialPageRoute(
                builder: (_) => GardenDiscoveryScreen(
                  service: _service,
                  accountReady: widget.accountReady,
                ),
              ),
            ),
            icon: const Icon(Icons.explore_outlined),
            label: const Text('이웃 정원 둘러보기'),
          ),
          OutlinedButton.icon(
            onPressed: () => Navigator.push<void>(
              context,
              MaterialPageRoute(
                builder: (_) => GardenDiscoveryScreen(
                  service: _service,
                  accountReady: widget.accountReady,
                  favorites: true,
                ),
              ),
            ),
            icon: const Icon(Icons.star_border),
            label: const Text('즐겨찾는 정원'),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '내 코드 공유',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  SelectableText(
                    profile.inviteCode,
                    style: const TextStyle(fontSize: 24, letterSpacing: 2),
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: profile.inviteCode),
                          );
                          _message('친구 코드를 복사했어요.');
                        },
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text('복사'),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          try {
                            await SharePlus.instance.share(
                              ShareParams(
                                text:
                                    '마음냥 정원에서 이웃이 되어 주세요.\n친구 코드: ${profile.inviteCode}\n이웃 → 찾기 → 친구 코드로 찾기에 입력해 주세요.',
                              ),
                            );
                          } catch (_) {
                            _message('공유 창을 열지 못했어요. 친구 코드를 복사해 주세요.');
                          }
                        },
                        icon: const Icon(Icons.share_outlined, size: 18),
                        label: const Text('코드 공유'),
                      ),
                    ],
                  ),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _invite,
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('친구 코드로 찾기'),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (_tab == 0)
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.park_outlined,
                color: AppColors.catSage,
              ),
              title: const Text('함께 가꾸는 나무'),
              subtitle: const Text('이웃과 기념일을 남겨요 · 받은 초대는 무료 참여'),
              trailing: Badge(
                isLabelVisible: _hasTreeActivity,
                label: const Text('새 소식'),
                child: const Icon(Icons.chevron_right),
              ),
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => SharedTreesScreen(service: _sharedTrees),
                  ),
                );
                if (mounted) await _load();
              },
            ),
          ),
        if (profile.visibility == GardenVisibility.private) ...[
          const SizedBox(height: 10),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.lock_outline),
            title: const Text('내 정원은 나만 볼 수 있어요'),
            subtitle: const Text('이웃이 방문할 수 있도록 공개 범위를 정해 주세요.'),
            trailing: TextButton(onPressed: _settings, child: const Text('설정')),
          ),
        ],
        if (_tab == 3 && people.incoming.isNotEmpty) ...[
          _heading('도착한 이웃 신청'),
          ...people.incoming.map(
            (p) => Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _name(p.nickname),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        FilledButton(
                          onPressed: _busy
                              ? null
                              : () => _action(
                                  () => _service.respondNeighbor(
                                    p.gardenId,
                                    accept: true,
                                  ),
                                  '이웃으로 연결됐어요.',
                                ),
                          child: const Text('수락'),
                        ),
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () => _action(
                                  () => _service.respondNeighbor(
                                    p.gardenId,
                                    accept: false,
                                  ),
                                  '신청을 정리했어요.',
                                ),
                          child: const Text('거절'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        if (_tab == 0)
          Card(
            child: ListTile(
              leading: const Icon(Icons.pets),
              title: const Text('고양이 초대와 방문'),
              subtitle: const Text('우리 고양이와 이웃 정원에 놀러 가요'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => CatVisitInboxScreen(service: _service),
                ),
              ),
            ),
          ),
        if (_tab == 0) ...[
          _heading('내 이웃'),
          if (people.neighbors.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                '아직 연결된 이웃이 없어요.\n친구 코드를 입력하거나 둘러보기에서 정원을 만나 보세요.',
                style: TextStyle(height: 1.6, color: AppColors.inkSoft),
              ),
            ),
          ...people.neighbors.map(
            (p) => Card(
              child: ListTile(
                leading: const CircleAvatar(child: Text('🌿')),
                title: Text(_name(p.nickname)),
                subtitle: Text(
                  p.canVisit == false ? '이웃이 정원을 비공개로 두고 있어요' : '정원 방문하기',
                ),
                trailing: PopupMenuButton<String>(
                  enabled: !_busy,
                  tooltip: '이웃 관리',
                  onSelected: (action) => _manageNeighbor(p, action),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'remove', child: Text('이웃 연결 해제')),
                    PopupMenuItem(value: 'block', child: Text('차단')),
                  ],
                ),
                onTap: p.canVisit == false
                    ? null
                    : () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => GardenVisitScreen(
                              gardenId: p.gardenId,
                              nickname: p.nickname,
                            ),
                          ),
                        );
                        if (mounted) _load();
                      },
              ),
            ),
          ),
        ],
        if (_tab == 3) ...[
          _heading('신청 관리'),
          Text(
            '받은 신청 ${people.incoming.length} · 보낸 신청 ${people.outgoing.length}',
          ),
          if (people.incoming.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('받은 신청이 없어요.'),
            ),
        ],
        if (_tab == 3 && people.outgoing.isNotEmpty) ...[
          _heading('수락을 기다리는 이웃'),
          ...people.outgoing.map(
            (p) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_name(p.nickname)),
              subtitle: const Text('이웃 신청을 보냈어요'),
              trailing: TextButton(
                onPressed: _busy
                    ? null
                    : () => _action(
                        () => _service.removeNeighbor(p.gardenId),
                        '이웃 신청을 취소했어요.',
                      ),
                child: const Text('취소'),
              ),
            ),
          ),
        ],
        if (_tab == 0 && people.blocked.isNotEmpty)
          ExpansionTile(
            title: const Text('차단한 이웃 관리'),
            children: people.blocked
                .map(
                  (p) => ListTile(
                    title: Text(_name(p.nickname)),
                    trailing: TextButton(
                      onPressed: _busy
                          ? null
                          : () => _action(
                              () => _service.blockNeighbor(
                                p.gardenId,
                                blocked: false,
                              ),
                              '차단을 해제했어요. 이웃 연결은 다시 신청해 주세요.',
                            ),
                      child: const Text('해제'),
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  Widget _heading(String text) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 8),
    child: Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    ),
  );
}

class _FriendCodeDialog extends StatefulWidget {
  const _FriendCodeDialog();
  @override
  State<_FriendCodeDialog> createState() => _FriendCodeDialogState();
}

class _FriendCodeDialogState extends State<_FriendCodeDialog> {
  final _controller = TextEditingController();
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('친구 코드로 이웃 찾기'),
    content: TextField(
      key: const Key('village-friend-code'),
      controller: _controller,
      autofocus: true,
      textCapitalization: TextCapitalization.characters,
      maxLength: 32,
      decoration: const InputDecoration(
        labelText: '친구 코드',
        hintText: '예: ABCD12345678',
      ),
      onSubmitted: (value) => Navigator.pop(context, value.trim()),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('취소'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, _controller.text.trim()),
        child: const Text('찾기'),
      ),
    ],
  );
}
