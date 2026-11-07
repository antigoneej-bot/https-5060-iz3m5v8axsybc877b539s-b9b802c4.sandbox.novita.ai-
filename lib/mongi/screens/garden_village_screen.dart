import '../../l10n/app_language.dart';
import 'cat_visit_inbox_screen.dart';
import '../../widgets/neighbor_design.dart';
import '../../widgets/neighbor_news_bubble.dart';
import 'garden_discovery_screen.dart';
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../services/garden_village_service.dart';
import '../../services/request_stage.dart';
import '../../services/diagnostics_service.dart';
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
  @override
  bool get wantKeepAlive => true;

  bool? _tickerActive;
  Future<void>? _pendingLoad;
  String? _loadingOwner;
  late GardenVillageService _service;
  late SharedTreeService _sharedTrees;
  bool _hasTreeActivity = false;
  StreamSubscription<String?>? _accountSubscription;
  GardenVillageProfile? _profile;
  GardenNeighborLists? _neighbors;
  bool _loading = true, _needsAccount = false, _busy = false;
  String? _error, _owner;
  int _request = 0, _tab = 0;
  bool _sentRequests = false;

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
      _pendingLoad = null;
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
    if (active && wasActive == false && _profile != null && _tab != 2) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _tickerActive == true) _load(silent: true);
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _tickerActive != false &&
        _tab != 2) {
      _load(silent: true);
    }
  }

  Future<void> _load({bool silent = false, bool afterMutation = false}) async {
    if (!mounted) return;
    final owner = _currentOwner;
    final pending = _pendingLoad;
    if (pending != null && owner == _loadingOwner) {
      await pending;
      // A read started before a mutation cannot confirm its new server state.
      if (afterMutation && mounted && owner == _currentOwner) {
        await _load(silent: silent);
      }
      return;
    }
    _loadingOwner = owner;
    final task = _performLoad(silent: silent);
    _pendingLoad = task;
    try {
      await task;
    } finally {
      if (identical(_pendingLoad, task)) _pendingLoad = null;
    }
  }

  Future<void> _performLoad({required bool silent}) async {
    final entryClock = Stopwatch()..start();
    silent =
        silent &&
        _profile != null &&
        _neighbors != null &&
        _owner == _currentOwner;
    final request = ++_request;
    final owner = _currentOwner;
    setState(() {
      _loading = !silent;
      _needsAccount = false;
      _error = null;
      if (!silent) {
        _profile = null;
        _neighbors = null;
        _hasTreeActivity = false;
      }
    });
    try {
      final ready = await awaitRequestStage(
        widget.accountReady?.call() ?? SocialAuthService.isAccountReady(),
        'authentication-timeout',
      );
      if (!mounted || request != _request || owner != _currentOwner) return;
      if (!ready) {
        setState(() {
          _loading = false;
          _needsAccount = true;
          _profile = null;
          _neighbors = null;
          _hasTreeActivity = false;
        });
        return;
      }
      if (owner != _owner) {
        _owner = owner;
        _service = widget.service ?? GardenVillageService();
        _sharedTrees = widget.sharedTreeService ?? SharedTreeService();
      }
      final service = _service;
      final entry = await service.loadEntry();
      final profile = entry.profile;
      final neighbors = entry.neighbors;
      if (!mounted || request != _request || owner != _currentOwner) return;
      setState(() {
        _profile = profile;
        _neighbors = neighbors;
        _needsAccount = false;
        _loading = false;
      });
      // This optional badge cannot block the existing directory on an older server.
      unawaited(_loadTreeBadge(request, owner));
    } catch (error, stack) {
      unawaited(DiagnosticsService.record(error, stack, 'neighbor_entry'));
      if (!mounted || request != _request || owner != _currentOwner) return;
      if (silent) {
        _message(tr("새 소식을 가져오지 못했어요. 이전 목록을 표시하고 있어요. 아래로 당겨 다시 시도해 주세요."));
        return;
      }
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    } finally {
      entryClock.stop();
      unawaited(
        DiagnosticsService.recordDuration(
          'neighbor_entry',
          entryClock.elapsedMilliseconds,
        ),
      );
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
      await _load(afterMutation: true);
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
          title: Text(tr('{0}님에게 이웃 신청', [_name(person.nickname)])),
          content: Text(
            tr("상대가 수락하면 서로 내 이웃 목록에서 찾아갈 수 있어요. 편지와 감정 기록은 공유되지 않아요."),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(tr("취소")),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(tr("이웃 신청")),
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
      _message(tr("이웃 신청을 보냈어요. 상대가 수락하면 연결돼요."));
      setState(() => _busy = false);
      await _load(afterMutation: true);
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
        title: Text(block ? tr("이 이웃을 차단할까요?") : tr("이웃 연결을 해제할까요?")),
        content: Text(
          block
              ? tr("서로 정원 방문과 응원·선물을 할 수 없게 돼요.")
              : tr("다시 연결하려면 이웃 신청과 수락이 필요해요."),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr("취소")),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(block ? tr("차단") : tr("연결 해제")),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || request != _request) return;
    await _action(
      () => block
          ? _service.blockNeighbor(person.gardenId)
          : _service.removeNeighbor(person.gardenId),
      block ? tr("이웃을 차단했어요.") : tr("이웃 연결을 해제했어요."),
    );
  }

  Future<void> _settings() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => PublicGardenSettingsScreen()),
    );
    if (mounted) _load(afterMutation: true);
  }

  String _name(String? name) =>
      name?.trim().isNotEmpty == true ? name!.trim() : tr("이웃");

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    super.build(context);
    return NeighborTheme(
      child: Scaffold(
        backgroundColor: neighborCream,
        appBar: AppBar(
          toolbarHeight: 46,
          titleSpacing: 18,
          title: Row(
            children: [
              const Icon(Icons.pets, size: 22, color: neighborInk),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  tr('마음냥 정원'),
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: neighborInk,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: neighborCream,
          surfaceTintColor: Colors.transparent,
          actions: [
            IconButton(
              tooltip: tr("응원 메시지"),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PublicGardenInboxScreen(
                    initialFilter: 1,
                    service: widget.service,
                    accountReady: widget.accountReady,
                    currentAccount: widget.currentAccount,
                    accountChanges: widget.accountChanges,
                  ),
                ),
              ),
              icon: const Icon(Icons.notifications_none, color: neighborInk),
            ),
            IconButton(
              tooltip: tr("정원 공개와 받기 설정"),
              onPressed: _settings,
              icon: Icon(Icons.settings_outlined),
            ),
          ],
        ),
        body: Column(
          children: [
            NeighborHeader(
              gifts: _tab == 2,
              title: [tr("내 이웃"), tr("이웃 찾기"), tr("선물함"), tr("신청 관리")][_tab],
              icon: [
                Icons.people_outline,
                Icons.search,
                Icons.card_giftcard,
                Icons.person_add_alt,
              ][_tab],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: NeighborTabs(
                labels: [tr("내 이웃"), tr("신청"), tr("선물함"), tr("찾기")],
                selected: [0, 3, 2, 1].indexOf(_tab),
                onSelect: (index) {
                  setState(() => _tab = [0, 3, 2, 1][index]);
                  if (_tab != 2) _load(silent: true);
                },
              ),
            ),
            Expanded(
              child: _tab == 2
                  ? PublicGardenInboxScreen(
                      key: ValueKey('inbox:$_owner'),
                      embedded: true,
                      initialFilter: widget.inboxFilter,
                      service: widget.service,
                      accountReady: widget.accountReady,
                      currentAccount: widget.currentAccount,
                      accountChanges: widget.accountChanges,
                    )
                  : RefreshIndicator(onRefresh: _load, child: _body()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) return Center(child: CircularProgressIndicator());
    if (_needsAccount) {
      return ListView(
        padding: EdgeInsets.all(20),
        children: [
          Text(tr("로그인하면 내 이웃과 받은 마음을 다른 휴대폰에서도 이어갈 수 있어요.")),
          SizedBox(height: 16),
          AccountEntryCard(
            onChanged: () async {
              _service = widget.service ?? GardenVillageService();
              _sharedTrees = widget.sharedTreeService ?? SharedTreeService();
              await _load(afterMutation: true);
            },
          ),
        ],
      );
    }
    if (_error != null) {
      return ListView(
        padding: EdgeInsets.all(24),
        children: [
          Icon(Icons.cloud_off_outlined, size: 40),
          SizedBox(height: 16),
          Text(_error!, textAlign: TextAlign.center),
          SizedBox(height: 16),
          OutlinedButton(onPressed: _load, child: Text(tr("다시 연결하기"))),
        ],
      );
    }
    final profile = _profile!;
    final people = _neighbors!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 2, 14, 24),
      children: [
        if (_tab == 0)
          NeighborNewsBubble(
            neighbors: people,
            expanded: true,
            service: widget.service,
            currentAccount: widget.currentAccount,
          ),
        if (_tab == 1) ...[
          Text(
            tr("정원을 오가며 작은 마음을 나눠요."),
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 6),
          Text(
            tr("응원에 꼭 답례하지 않아도 괜찮아요. 편지와 감정 통계는 나만 볼 수 있어요."),
            style: TextStyle(color: AppColors.inkSoft, height: 1.5),
          ),
          SizedBox(height: 16),
          FilledButton.icon(
            key: Key('village-random-browse'),
            onPressed: () => Navigator.push<void>(
              context,
              MaterialPageRoute(
                builder: (_) => GardenDiscoveryScreen(
                  service: _service,
                  accountReady: widget.accountReady,
                ),
              ),
            ),
            icon: Icon(Icons.explore_outlined),
            label: Text(tr("이웃 정원 둘러보기")),
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
            icon: Icon(Icons.star_border),
            label: Text(tr("즐겨찾는 정원")),
          ),
          SizedBox(height: 8),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    tr("내 코드 공유"),
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 6),
                  SelectableText(
                    profile.inviteCode,
                    style: TextStyle(fontSize: 24, letterSpacing: 2),
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: profile.inviteCode),
                          );
                          _message(tr("친구 코드를 복사했어요."));
                        },
                        icon: Icon(Icons.copy, size: 18),
                        label: Text(tr("복사")),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          try {
                            await SharePlus.instance.share(
                              ShareParams(
                                text: tr(
                                  '마음냥 정원에서 이웃이 되어 주세요.\n친구 코드: {0}\n이웃 → 찾기 → 친구 코드로 찾기에 입력해 주세요.',
                                  [profile.inviteCode],
                                ),
                              ),
                            );
                          } catch (_) {
                            _message(tr("공유 창을 열지 못했어요. 친구 코드를 복사해 주세요."));
                          }
                        },
                        icon: Icon(Icons.share_outlined, size: 18),
                        label: Text(tr("코드 공유")),
                      ),
                    ],
                  ),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _invite,
                    icon: Icon(Icons.person_add_alt_1),
                    label: Text(tr("친구 코드로 찾기")),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (_tab == 0)
          Card(
            child: ListTile(
              leading: Icon(Icons.park_outlined, color: AppColors.catSage),
              title: Text(tr("함께 가꾸는 나무")),
              subtitle: Text(tr("이웃과 기념일을 남겨요 · 받은 초대는 무료 참여")),
              trailing: Badge(
                isLabelVisible: _hasTreeActivity,
                label: Text(tr("새 소식")),
                child: Icon(Icons.chevron_right),
              ),
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => SharedTreesScreen(service: _sharedTrees),
                  ),
                );
                if (mounted) await _load(afterMutation: true);
              },
            ),
          ),
        if (_tab == 0 && profile.visibility == GardenVisibility.private) ...[
          SizedBox(height: 10),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.lock_outline),
            title: Text(tr("내 정원은 나만 볼 수 있어요")),
            subtitle: Text(tr("이웃이 방문할 수 있도록 공개 범위를 정해 주세요.")),
            trailing: TextButton(onPressed: _settings, child: Text(tr("설정"))),
          ),
        ],
        if (_tab == 3) ...[
          NeighborTabs(
            labels: [
              tr('받은 신청 {0}', [people.incoming.length]),
              tr('보낸 신청 {0}', [people.outgoing.length]),
            ],
            selected: _sentRequests ? 1 : 0,
            onSelect: (i) => setState(() => _sentRequests = i == 1),
          ),
          SizedBox(height: 16),
          if (!_sentRequests)
            ...people.incoming.map(
              (p) => NeighborRequestCard(
                coat: p.publicCoat,
                name: _name(p.nickname),
                onAccept: _busy
                    ? null
                    : () => _action(
                        () =>
                            _service.respondNeighbor(p.gardenId, accept: true),
                        tr("이웃으로 연결됐어요."),
                      ),
                onDecline: _busy
                    ? null
                    : () => _action(
                        () =>
                            _service.respondNeighbor(p.gardenId, accept: false),
                        tr("신청을 정리했어요."),
                      ),
              ),
            ),
          if (!_sentRequests && people.incoming.isNotEmpty)
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFFF0EFDF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                tr("ⓘ  수락하면 내 이웃에 추가돼요"),
                textAlign: TextAlign.center,
              ),
            ),
        ],
        if (_tab == 0)
          Card(
            child: ListTile(
              leading: Icon(Icons.pets),
              title: Text(tr("고양이 초대와 방문")),
              subtitle: Text(tr("우리 고양이와 이웃 정원에 놀러 가요")),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => CatVisitInboxScreen(service: _service),
                ),
              ),
            ),
          ),
        if (_tab == 0) ...[
          _heading(tr("내 이웃")),
          if (people.neighbors.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                tr("아직 연결된 이웃이 없어요.\n친구 코드를 입력하거나 둘러보기에서 정원을 만나 보세요."),
                style: TextStyle(height: 1.6, color: AppColors.inkSoft),
              ),
            ),
          ...people.neighbors.map(
            (p) => Card(
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    'assets/neighbor_ui/cat-portrait.png',
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    semanticLabel: tr("이웃 고양이 공통 일러스트"),
                  ),
                ),
                title: Text(_name(p.nickname)),
                subtitle: Text(
                  p.canVisit == false
                      ? tr("이웃이 정원을 비공개로 두고 있어요")
                      : tr("정원 방문하기"),
                ),
                trailing: PopupMenuButton<String>(
                  enabled: !_busy,
                  tooltip: tr("이웃 관리"),
                  onSelected: (action) => _manageNeighbor(p, action),
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'remove', child: Text(tr("이웃 연결 해제"))),
                    PopupMenuItem(value: 'block', child: Text(tr("차단"))),
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
                        if (mounted) _load(afterMutation: true);
                      },
              ),
            ),
          ),
        ],
        if (_tab == 3) ...[
          SizedBox(height: 8),

          if (!_sentRequests && people.incoming.isEmpty)
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(tr("받은 신청이 없어요.")),
            ),
        ],
        if (_tab == 3 && _sentRequests && people.outgoing.isEmpty)
          Padding(padding: EdgeInsets.all(20), child: Text(tr("보낸 신청이 없어요."))),
        if (_tab == 3 && _sentRequests && people.outgoing.isNotEmpty) ...[
          _heading(tr("수락을 기다리는 이웃")),
          ...people.outgoing.map(
            (p) => NeighborRequestCard(
              coat: p.publicCoat,
              name: _name(p.nickname),
              sent: true,
              onAccept: null,
              onDecline: _busy
                  ? null
                  : () => _action(
                      () => _service.removeNeighbor(p.gardenId),
                      tr("이웃 신청을 취소했어요."),
                    ),
            ),
          ),
        ],
        if (_tab == 0 && people.blocked.isNotEmpty)
          ExpansionTile(
            title: Text(tr("차단한 이웃 관리")),
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
                              tr("차단을 해제했어요. 이웃 연결은 다시 신청해 주세요."),
                            ),
                      child: Text(tr("해제")),
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  Widget _heading(String text) => Padding(
    padding: EdgeInsets.only(top: 20, bottom: 8),
    child: Text(
      text,
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
    title: Text(tr("친구 코드로 이웃 찾기")),
    content: TextField(
      key: Key('village-friend-code'),
      controller: _controller,
      autofocus: true,
      textCapitalization: TextCapitalization.characters,
      maxLength: 32,
      decoration: InputDecoration(
        labelText: tr("친구 코드"),
        hintText: tr("예: ABCD12345678"),
      ),
      onSubmitted: (value) => Navigator.pop(context, value.trim()),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(tr("취소")),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, _controller.text.trim()),
        child: Text(tr("찾기")),
      ),
    ],
  );
}
