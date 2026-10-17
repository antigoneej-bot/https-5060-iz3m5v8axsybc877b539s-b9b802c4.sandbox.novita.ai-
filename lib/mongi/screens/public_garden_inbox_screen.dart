import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/social_auth_service.dart';
import '../../services/garden_village_service.dart';
import '../../services/garden_return_store.dart';
import '../../theme.dart' show AppColors;
import '../../widgets/account_entry_card.dart';
import '../integration/cheer_flower_store.dart';
import '../integration/garden_bloom_sync.dart';
import '../l10n/gen/app_localizations.dart';
import '../l10n/public_cheer_l10n.dart';
import '../models/garden_gifts.dart';
import '../models/public_garden.dart';
import '../models/garden_village.dart';
import '../providers/garden_provider.dart';
import '../widgets/garden_gift_art.dart';
import '../widgets/garden_keepsake_sheets.dart'
    show currentGardenOwner, showCheerFlowers;
import 'garden_bloom_news_screen.dart';
import 'garden_visit_screen.dart';

class PublicGardenInboxScreen extends StatefulWidget {
  const PublicGardenInboxScreen({
    super.key,
    this.embedded = false,
    this.accountReady,
    this.service,
    this.currentAccount,
    this.accountChanges,
  });
  final bool embedded;
  final Future<bool> Function()? accountReady;
  final GardenVillageService? service;
  final String? Function()? currentAccount;
  final Stream<String?>? accountChanges;
  @override
  State<PublicGardenInboxScreen> createState() =>
      _PublicGardenInboxScreenState();
}

class _PublicGardenInboxScreenState extends State<PublicGardenInboxScreen>
    with WidgetsBindingObserver {
  bool _loading = true, _needsAccount = false, _loadingMore = false;
  String? _error, _pageError, _owner, _nextCursor;
  int _request = 0;
  List<ReceivedCheer> _cheers = const [];
  final Set<String> _claiming = {}, _planting = {};
  StreamSubscription<String?>? _auth;

  String? get _currentOwner => widget.currentAccount != null
      ? widget.currentAccount!()
      : widget.service?.accountOwner ?? SocialAuthService.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _owner = _currentOwner;
    WidgetsBinding.instance.addObserver(this);
    final changes =
        widget.accountChanges ??
        (SocialAuthService.firebaseReady
            ? FirebaseAuth.instance.authStateChanges().map((user) => user?.uid)
            : null);
    _auth = changes?.listen((owner) {
      if (!mounted || owner == _owner) return;
      _owner = owner;
      _request++;
      setState(() {
        _cheers = const [];
        _nextCursor = null;
        _pageError = null;
        _claiming.clear();
        _planting.clear();
      });
      _load();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _request++;
    _auth?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  bool _isCurrent(int request, String? owner) =>
      mounted && request == _request && owner == _currentOwner;

  Future<ReceivedCheerBatch> _fetchPage(String? cursor) async {
    if (widget.service == null) {
      return context.read<GardenProvider>().loadMyPublicCheersPage(
        cursor: cursor,
      );
    }
    final owner = _currentOwner;
    final page = await widget.service!.listReceivedCheers(
      cursor: cursor,
      pageSize: 30,
    );
    if (owner != _currentOwner) throw StateError('로그인 상태가 바뀌었어요.');
    if (owner != null) {
      await CheerFlowerStore.instance.remember(
        owner,
        page.cheers,
        retiredIds: page.retiredIds,
      );
      if (owner != _currentOwner) throw StateError('로그인 상태가 바뀌었어요.');
      try {
        await GardenReturnStore.instance.observe(
          owner,
          page.cheers,
          retiredIds: page.retiredIds,
        );
      } catch (_) {
        // Read markers are optional; the delivered inbox page remains usable.
      }
    }
    return page;
  }

  void _seenAfterDisplay(int request, String? owner, ReceivedCheerBatch page) {
    if (owner == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final lifecycle = WidgetsBinding.instance.lifecycleState;
      if (!_isCurrent(request, owner) ||
          (lifecycle != null && lifecycle != AppLifecycleState.resumed) ||
          ModalRoute.of(context)?.isCurrent == false) {
        return;
      }
      try {
        await GardenReturnStore.instance.markSeen(
          owner,
          page.cheers.map((c) => c.id),
        );
      } catch (_) {
        // An unread-marker write failure must not hide a delivered message.
      }
    });
  }

  Future<void> _load() async {
    if (!mounted) return;
    final request = ++_request;
    final owner = _currentOwner;
    setState(() {
      _loading = true;
      _loadingMore = false;
      _needsAccount = false;
      _error = null;
      _pageError = null;
    });
    try {
      final ready =
          await (widget.accountReady?.call() ??
              SocialAuthService.isAccountReady());
      if (!_isCurrent(request, owner)) return;
      if (!ready) {
        setState(() {
          _needsAccount = true;
          _loading = false;
          _cheers = const [];
          _nextCursor = null;
        });
        return;
      }
      final page = await _fetchPage(null);
      if (!_isCurrent(request, owner)) return;
      setState(() {
        _cheers = {
          for (final cheer in page.cheers)
            if (!page.retiredIds.contains(cheer.id)) cheer.id: cheer,
        }.values.toList();
        _nextCursor = page.nextCursor;
        _loading = false;
      });
      _seenAfterDisplay(request, owner, page);
      if (owner != null && widget.service == null) {
        try {
          await GardenBloomSync.flush(owner);
          if (_isCurrent(request, owner)) setState(() {});
        } catch (_) {
          // A pending bloom sync must not hide an already received gift.
        }
      }
    } catch (error) {
      if (_isCurrent(request, owner)) {
        setState(() {
          _error = error.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    final cursor = _nextCursor;
    if (_loading || _loadingMore || cursor == null) return;
    final request = _request;
    final owner = _currentOwner;
    setState(() {
      _loadingMore = true;
      _pageError = null;
    });
    try {
      final page = await _fetchPage(cursor);
      if (!_isCurrent(request, owner)) return;
      if (page.nextCursor == cursor) {
        throw const FormatException('이전 마음을 불러오지 못했어요. 다시 시도해 주세요.');
      }
      setState(() {
        _cheers = {
          for (final cheer in [..._cheers, ...page.cheers])
            if (!page.retiredIds.contains(cheer.id)) cheer.id: cheer,
        }.values.toList();
        _nextCursor = page.nextCursor;
      });
      _seenAfterDisplay(request, owner, page);
    } catch (error) {
      if (_isCurrent(request, owner))
        setState(() => _pageError = error.toString());
    } finally {
      if (_isCurrent(request, owner)) setState(() => _loadingMore = false);
    }
  }

  void _message(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _claim(ReceivedCheer cheer) async {
    if (_claiming.contains(cheer.id)) return;
    final request = _request;
    setState(() => _claiming.add(cheer.id));
    try {
      final amount = await context.read<GardenProvider>().claimPublicCheer(
        cheer.id,
      );
      if (!mounted || request != _request) return;
      _message(
        amount > 0
            ? '선물로 빛의 정수 $amount개를 받았어요.'
            : '받은 마음을 확인했어요. 나중에 다시 볼 수 있어요.',
      );
      await _load();
    } catch (error) {
      if (mounted && request == _request) _message(error.toString());
    } finally {
      if (mounted) setState(() => _claiming.remove(cheer.id));
    }
  }

  Future<void> _plant(ReceivedCheer cheer) async {
    if (_planting.contains(cheer.id)) return;
    final owner = currentGardenOwner();
    if (owner == null) {
      _message('로그인 상태를 다시 확인해 주세요.');
      return;
    }
    final request = _request;
    setState(() => _planting.add(cheer.id));
    try {
      await plantGardenFlower(owner, cheer.id);
      if (!mounted || request != _request) return;
      _message('받은 꽃을 내 정원에 심었어요. 보내준 이웃과 날짜도 함께 남아요.');
      setState(() {});
    } catch (error) {
      if (mounted && request == _request) _message(error.toString());
    } finally {
      if (mounted) setState(() => _planting.remove(cheer.id));
    }
  }

  String _date(DateTime? date) {
    if (date == null) return '';
    final local = date.toLocal();
    return '${local.year}.${local.month.toString().padLeft(2, '0')}.${local.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final body = RefreshIndicator(onRefresh: _load, child: _body());
    return widget.embedded
        ? body
        : Scaffold(
            backgroundColor: AppColors.bg0,
            appBar: AppBar(
              title: const Text('받은 마음'),
              backgroundColor: AppColors.bg0,
            ),
            body: body,
          );
  }

  Widget _body() {
    if (_loading && _cheers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_needsAccount) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('로그인하면 나에게 도착한 응원과 선물을 볼 수 있어요.'),
          const SizedBox(height: 12),
          AccountEntryCard(onChanged: _load),
        ],
      );
    }
    if (_error != null && _cheers.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.cloud_off_outlined, size: 40),
          const SizedBox(height: 16),
          Text(_error!, textAlign: TextAlign.center),
          OutlinedButton(onPressed: _load, child: const Text('다시 연결하기')),
        ],
      );
    }
    final l10n = AppLocalizations.of(context);
    final planted = CheerFlowerStore.instance
        .forOwner(_currentOwner)
        .where((f) => f.planted)
        .map((f) => f.id)
        .toSet();
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        if (_loading) const LinearProgressIndicator(),
        if (_error != null) ...[
          Text(_error!),
          TextButton(onPressed: _load, child: const Text('새로고침 다시 시도')),
        ],
        const Text(
          '나에게 도착한 마음',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        const SizedBox(height: 6),
        const Text(
          '응원 이모티콘은 정원에 24시간 머물고, 받은 마음은 여기서 다시 볼 수 있어요. 꽃은 원하는 때 직접 심어요.',
          style: TextStyle(color: AppColors.inkSoft, height: 1.5),
        ),
        Wrap(
          spacing: 8,
          children: [
            TextButton.icon(
              onPressed: () => showCheerFlowers(context),
              icon: const Icon(Icons.local_florist_outlined, size: 18),
              label: const Text('꽃 보관함'),
            ),
            TextButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const GardenBloomNewsScreen(),
                ),
              ),
              icon: const Icon(Icons.mark_email_read_outlined, size: 18),
              label: const Text('내가 건넨 꽃 소식'),
            ),
          ],
        ),
        if (_cheers.isEmpty && _nextCursor == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Text(
              '아직 도착한 마음이 없어요.\n이웃 정원에 먼저 작은 응원을 남겨 보세요.',
              textAlign: TextAlign.center,
              style: TextStyle(height: 1.6),
            ),
          ),
        ..._cheers.map((cheer) {
          final isPlanted = planted.contains(cheer.id) || cheer.bloomConfirmed;
          final sender = cheer.senderNickname?.trim().isNotEmpty == true
              ? cheer.senderNickname!
              : '이웃';
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (cheer.hasFlower)
                        SizedBox(
                          width: 52,
                          height: 52,
                          child: GardenFlowerArt(kind: cheer.flowerKind),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            gardenReactionEmoji[cheer.reaction?.kind] ?? '💛',
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$sender님이 ${cheer.hasFlower ? '꽃을 선물했어요' : '응원을 보냈어요'}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (cheer.createdAt != null)
                              Text(
                                _date(cheer.createdAt),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.inkSoft,
                                ),
                              ),
                            const SizedBox(height: 6),
                            Text(
                              publicCheerOptionText(l10n, cheer.messageIndex),
                              style: const TextStyle(height: 1.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (cheer.hasFlower)
                    OutlinedButton.icon(
                      onPressed: isPlanted || _planting.contains(cheer.id)
                          ? null
                          : () => _plant(cheer),
                      icon: const Icon(Icons.local_florist_outlined, size: 18),
                      label: Text(
                        isPlanted
                            ? '내 정원에 심은 꽃'
                            : _planting.contains(cheer.id)
                            ? '심고 있어요…'
                            : '${gardenFlowerNames[cheer.flowerKind] ?? '받은 꽃'} 심기',
                      ),
                    ),
                  Wrap(
                    spacing: 8,
                    children: [
                      if (!cheer.claimed)
                        TextButton(
                          onPressed: _claiming.contains(cheer.id)
                              ? null
                              : () => _claim(cheer),
                          child: Text(
                            _claiming.contains(cheer.id) ? '확인 중…' : '마음 확인하기',
                          ),
                        ),
                      if (cheer.senderGardenId != null)
                        TextButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => GardenVisitScreen(
                                gardenId: cheer.senderGardenId!,
                                nickname: cheer.senderNickname,
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.landscape_outlined, size: 18),
                          label: const Text('보내준 이웃 방문'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
        if (_pageError != null) Text(_pageError!),
        if (_nextCursor != null)
          OutlinedButton.icon(
            key: const Key('received-cheers-more'),
            onPressed: _loadingMore || _loading ? null : _loadMore,
            icon: _loadingMore
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.expand_more),
            label: Text(
              _loadingMore
                  ? '이전 마음을 불러오고 있어요…'
                  : _pageError != null
                  ? '이전 마음 다시 불러오기'
                  : '이전 마음 더 보기',
            ),
          ),
      ],
    );
  }
}
