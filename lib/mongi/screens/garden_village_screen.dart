import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../services/garden_village_service.dart';
import '../../services/social_auth_service.dart';
import '../../theme.dart' show AppColors;
import '../../widgets/account_entry_card.dart';
import '../models/garden_village.dart';
import 'garden_visit_screen.dart';
import 'public_garden_browse_screen.dart';
import 'public_garden_inbox_screen.dart';
import 'public_garden_settings_screen.dart';

/// A small directory of real neighbors, rather than a second, simulated garden.
class GardenVillageScreen extends StatefulWidget {
  const GardenVillageScreen({
    super.key,
    this.service,
    this.accountReady,
    this.currentAccount,
    this.accountChanges,
    this.initialTab = 0,
  });
  final GardenVillageService? service;
  final Future<bool> Function()? accountReady;
  final String? Function()? currentAccount;
  final Stream<String?>? accountChanges;
  final int initialTab;

  @override
  State<GardenVillageScreen> createState() => _GardenVillageScreenState();
}

class _GardenVillageScreenState extends State<GardenVillageScreen>
    with WidgetsBindingObserver {
  late GardenVillageService _service;
  StreamSubscription<String?>? _accountSubscription;
  GardenVillageProfile? _profile;
  GardenNeighborLists? _neighbors;
  bool _loading = true, _needsAccount = false, _busy = false;
  String? _error, _owner;
  int _request = 0, _tab = 0;

  String? get _currentOwner => widget.currentAccount != null
      ? widget.currentAccount!()
      : SocialAuthService.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? GardenVillageService();
    _tab = widget.initialTab.clamp(0, 2);
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
      setState(() {
        _profile = null;
        _neighbors = null;
        _error = null;
        _busy = false;
        _tab = 0;
      });
      _load();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_tab == 0) _load();
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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _tab == 0) _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    final request = ++_request;
    final owner = _currentOwner;
    setState(() {
      _loading = true;
      _needsAccount = false;
      _error = null;
      _profile = null;
      _neighbors = null;
    });
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
      }
      final profile = await _service.getProfile();
      final neighbors = await _service.listNeighbors();
      if (!mounted || request != _request || owner != _currentOwner) return;
      setState(() {
        _profile = profile;
        _neighbors = neighbors;
        _needsAccount = false;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || request != _request || owner != _currentOwner) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
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
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bg0,
    appBar: AppBar(
      title: const Text('냥이 마을'),
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
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('내 이웃')),
                ButtonSegment(value: 1, label: Text('둘러보기')),
                ButtonSegment(value: 2, label: Text('받은 마음')),
              ],
              selected: {_tab},
              showSelectedIcon: false,
              onSelectionChanged: (value) {
                setState(() => _tab = value.first);
                if (_tab == 0) _load();
              },
            ),
          ),
        ),
      ),
    ),
    body: _tab == 1
        ? PublicGardenBrowseScreen(
            key: ValueKey('browse:$_owner'),
            embedded: true,
            service: widget.service,
            accountReady: widget.accountReady,
            currentAccount: widget.currentAccount,
          )
        : _tab == 2
        ? PublicGardenInboxScreen(
            key: ValueKey('inbox:$_owner'),
            embedded: true,
            service: widget.service,
            accountReady: widget.accountReady,
            currentAccount: widget.currentAccount,
          )
        : RefreshIndicator(onRefresh: _load, child: _body()),
  );

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
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '내 친구 코드',
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
                                  '마음냥 정원에서 이웃이 되어 주세요.\n친구 코드: ${profile.inviteCode}\n냥이 마을 → 내 이웃 → 친구 코드로 찾기에 입력해 주세요.',
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
                FilledButton.icon(
                  onPressed: _busy ? null : _invite,
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('친구 코드로 찾기'),
                ),
              ],
            ),
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
        if (people.incoming.isNotEmpty) ...[
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
        if (people.outgoing.isNotEmpty) ...[
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
        if (people.blocked.isNotEmpty)
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
