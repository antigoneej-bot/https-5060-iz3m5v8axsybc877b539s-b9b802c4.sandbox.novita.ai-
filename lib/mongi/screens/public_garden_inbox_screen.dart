import '../../l10n/app_language.dart';
import '../../widgets/orchard_gift_inbox.dart';
import '../../widgets/neighbor_design.dart';
import '../../widgets/sent_gift_inbox.dart';
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/social_auth_service.dart';
import '../../services/care_journal_store.dart';
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
import '../widgets/garden_keepsake_sheets.dart'
    show currentGardenOwner, showCheerFlowers;
import 'garden_bloom_news_screen.dart';
import 'garden_visit_screen.dart';

class PublicGardenInboxScreen extends StatefulWidget {
  const PublicGardenInboxScreen({
    super.key,
    this.embedded = false,
    this.initialFilter = 0,
    this.accountReady,
    this.service,
    this.currentAccount,
    this.accountChanges,
  });
  final bool embedded;
  final int initialFilter;
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
  int _filter = 0, _accountEpoch = 0;
  bool _sentGifts = false, _bulkClaiming = false;
  // UI acknowledgements only: the existing server/provider owns all rewards.
  // Keep successful claims out of a retry even when the following list fails.
  final Set<String> _confirmedClaims = {};
  bool _claimed(ReceivedCheer c) =>
      c.claimed || _confirmedClaims.contains(c.id);
  bool _matches(ReceivedCheer c) => _filter == 3
      ? false
      : _filter == 0
      ? c.deliveryKind != 'cheer' && !_claimed(c) && !c.bloomConfirmed
      : _filter == 1
      ? c.deliveryKind == 'cheer'
      : c.deliveryKind != 'cheer' && (_claimed(c) || c.bloomConfirmed);
  List<ReceivedCheer> _cheers = [];
  final Set<String> _claiming = {},
      _planting = {},
      _savingCare = {},
      _savedCare = {};
  StreamSubscription<String?>? _auth;

  String? get _currentOwner => widget.currentAccount != null
      ? widget.currentAccount!()
      : widget.service?.accountOwner ?? SocialAuthService.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter.clamp(0, 3);
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
      _accountEpoch++;
      _request++;
      setState(() {
        _cheers = [];
        _nextCursor = null;
        _pageError = null;
        _bulkClaiming = false;
        _confirmedClaims.clear();
        _claiming.clear();
        _planting.clear();
        _savingCare.clear();
        _savedCare.clear();
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
    if (owner != _currentOwner) throw StateError(tr("로그인 상태가 바뀌었어요."));
    if (owner != null) {
      await CheerFlowerStore.instance.remember(
        owner,
        page.cheers,
        retiredIds: page.retiredIds,
      );
      if (owner != _currentOwner) throw StateError(tr("로그인 상태가 바뀌었어요."));
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
          page.cheers
              .where((c) => _filter == 1 && c.deliveryKind == 'cheer')
              .map((c) => c.id),
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
          _cheers = [];
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
        throw FormatException(tr("이전 마음을 불러오지 못했어요. 다시 시도해 주세요."));
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

  Future<void> _claimAll() async {
    if (_bulkClaiming || _claiming.isNotEmpty || _planting.isNotEmpty) return;
    final owner = _currentOwner;
    final accountEpoch = _accountEpoch;
    final pending = _cheers
        .where(
          (c) => c.deliveryKind != 'cheer' && !_claimed(c) && !c.bloomConfirmed,
        )
        .toList();
    if (pending.isEmpty) return;
    setState(() => _bulkClaiming = true);
    var count = 0;
    var failed = false;
    try {
      final garden = context.read<GardenProvider>();
      for (final item in pending) {
        if (!mounted ||
            (owner != _currentOwner || accountEpoch != _accountEpoch))
          return;
        await garden.claimPublicCheer(item.id);
        if (!mounted ||
            (owner != _currentOwner || accountEpoch != _accountEpoch))
          return;
        count++;
        setState(() => _confirmedClaims.add(item.id));
      }
    } catch (_) {
      failed = true;
    } finally {
      if (mounted && owner == _currentOwner && accountEpoch == _accountEpoch)
        setState(() => _bulkClaiming = false);
    }
    if (!mounted || (owner != _currentOwner || accountEpoch != _accountEpoch))
      return;
    await _load();
    if (!mounted || (owner != _currentOwner || accountEpoch != _accountEpoch))
      return;
    _message(
      failed
          ? tr('{0}개를 보관했어요. 잠시 뒤 남은 선물을 다시 받아 주세요.', [count])
          : tr('{0}개의 선물을 보관했어요.', [count]),
    );
  }

  Future<void> _claim(ReceivedCheer cheer) async {
    if (_bulkClaiming || _claiming.contains(cheer.id)) return;
    final request = _request;
    setState(() => _claiming.add(cheer.id));
    try {
      final amount = await context.read<GardenProvider>().claimPublicCheer(
        cheer.id,
      );
      if (!mounted || request != _request) return;
      setState(() => _confirmedClaims.add(cheer.id));
      _message(
        amount > 0
            ? tr('선물로 빛의 정수 {0}개를 받았어요.', [amount])
            : tr("받은 마음을 확인했어요. 나중에 다시 볼 수 있어요."),
      );
      await _load();
    } catch (error) {
      if (mounted && request == _request) _message(error.toString());
    } finally {
      if (mounted) setState(() => _claiming.remove(cheer.id));
    }
  }

  Future<void> _keepForCare(
    ReceivedCheer cheer,
    String message,
    String author,
  ) async {
    final request = _request;
    final owner = _currentOwner;
    if (owner == null ||
        _savingCare.contains(cheer.id) ||
        !_isCurrent(request, owner))
      return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr("이 응원을 간직할까요?")),
        content: Text(
          tr(
            "나를 돌보는 방법에서 다시 볼 수 있도록 이 기기에 저장해요. 로그아웃해도 내 돌봄 기록에는 남고, 언제든 직접 지울 수 있어요.",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr("취소")),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr("간직하기")),
          ),
        ],
      ),
    );
    if (confirmed != true || !_isCurrent(request, owner)) return;
    setState(() => _savingCare.add(cheer.id));
    try {
      await CareJournalStore.instance.saveReceivedEncouragement(
        sourceId: '$owner:${cheer.id}',
        text: message,
        author: author,
        stillCurrent: () => _isCurrent(request, owner),
      );
      if (!mounted || !_isCurrent(request, owner)) return;
      setState(() => _savedCare.add(cheer.id));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tr("나를 돌보는 방법에 응원을 간직했어요."))));
    } catch (_) {
      if (mounted && _isCurrent(request, owner))
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr("응원을 저장하지 못했어요. 다시 시도해 주세요."))),
        );
    } finally {
      if (_isCurrent(request, owner))
        setState(() => _savingCare.remove(cheer.id));
    }
  }

  Future<void> _plant(ReceivedCheer cheer) async {
    if (_bulkClaiming || _planting.contains(cheer.id)) return;
    final owner = currentGardenOwner();
    if (owner == null) {
      _message(tr("로그인 상태를 다시 확인해 주세요."));
      return;
    }
    final request = _request;
    setState(() => _planting.add(cheer.id));
    try {
      await plantGardenFlower(owner, cheer.id);
      if (!mounted || request != _request) return;
      _message(tr("받은 꽃을 내 정원에 심었어요. 보내준 이웃과 날짜도 함께 남아요."));
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
    Localizations.localeOf(context);
    final body = RefreshIndicator(onRefresh: _load, child: _body());
    return widget.embedded
        ? body
        : Scaffold(
            backgroundColor: AppColors.bg0,
            appBar: AppBar(
              title: Text(tr("받은 마음")),
              backgroundColor: AppColors.bg0,
            ),
            body: body,
          );
  }

  void _details(ReceivedCheer cheer) {
    final sender = cheer.senderNickname?.trim().isNotEmpty == true
        ? cheer.senderNickname!
        : tr('이웃');
    final message = publicCheerOptionText(
      AppLocalizations.of(context),
      cheer.messageIndex,
    );
    final planted =
        cheer.bloomConfirmed ||
        CheerFlowerStore.instance
            .forOwner(_currentOwner)
            .any((f) => f.id == cheer.id && f.planted);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: neighborCream,
      builder: (sheet) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  NeighborPortrait(coat: cheer.senderCoat),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      sender,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: tr('닫기'),
                    onPressed: () => Navigator.pop(sheet),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              if (cheer.createdAt != null) Text(_date(cheer.createdAt)),
              const SizedBox(height: 16),
              Text(message, style: const TextStyle(fontSize: 18, height: 1.6)),
              const SizedBox(height: 16),
              if (cheer.hasFlower)
                OutlinedButton.icon(
                  onPressed:
                      _bulkClaiming || planted || _planting.contains(cheer.id)
                      ? null
                      : () {
                          Navigator.pop(sheet);
                          _plant(cheer);
                        },
                  icon: const Icon(Icons.local_florist_outlined),
                  label: Text(planted ? tr('내 정원에 심은 꽃') : tr('내 정원에 심기')),
                ),
              if (!_claimed(cheer))
                FilledButton(
                  onPressed: _bulkClaiming || _claiming.contains(cheer.id)
                      ? null
                      : () {
                          Navigator.pop(sheet);
                          _claim(cheer);
                        },
                  child: Text(cheer.hasFlower ? tr('선물 받기·보관') : tr('응원 확인')),
                ),
              TextButton.icon(
                onPressed:
                    _savingCare.contains(cheer.id) ||
                        _savedCare.contains(cheer.id)
                    ? null
                    : () {
                        Navigator.pop(sheet);
                        _keepForCare(cheer, message, sender);
                      },
                icon: const Icon(Icons.bookmark_border),
                label: Text(
                  _savedCare.contains(cheer.id)
                      ? tr('돌봄 모음에 간직했어요')
                      : tr('돌봄 모음에 간직하기'),
                ),
              ),
              if (cheer.senderGardenId != null)
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(sheet);
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => GardenVisitScreen(
                          gardenId: cheer.senderGardenId!,
                          nickname: cheer.senderNickname,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.landscape_outlined),
                  label: Text(tr('보내준 이웃 방문')),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _giftRow(ReceivedCheer cheer, {bool history = false}) {
    final planted =
        cheer.bloomConfirmed ||
        CheerFlowerStore.instance
            .forOwner(_currentOwner)
            .any((f) => f.id == cheer.id && f.planted);
    final sender = cheer.senderNickname?.trim().isNotEmpty == true
        ? cheer.senderNickname!
        : tr('이웃');
    final title =
        '$sender · ${cheer.hasFlower ? tr(gardenFlowerNames[cheer.flowerKind] ?? '꽃') : tr('응원')}';
    final action = FilledButton(
      key: ValueKey('receive-${cheer.id}'),
      onPressed:
          _bulkClaiming ||
              _claiming.contains(cheer.id) ||
              _planting.contains(cheer.id) ||
              planted ||
              (!cheer.hasFlower && _claimed(cheer))
          ? null
          : cheer.hasFlower && _claimed(cheer)
          ? () => _plant(cheer)
          : () => _claim(cheer),
      child: Text(
        !cheer.hasFlower
            ? (_claimed(cheer) ? tr('확인 완료') : tr('확인'))
            : planted
            ? tr('심음')
            : _claimed(cheer)
            ? tr('심기')
            : tr('받기'),
      ),
    );
    return NeighborGiftRow(
      title: title,
      coat: cheer.senderCoat,
      onDetails: () => _details(cheer),
      completed: history,
      art: cheer.hasFlower
          ? NeighborGiftArt(kind: cheer.flowerKind)
          : const Icon(Icons.favorite, color: Color(0xFFE69C95)),
      action: action,
    );
  }

  Widget _body() {
    if (_loading && _cheers.isEmpty)
      return const Center(child: CircularProgressIndicator());
    if (_needsAccount)
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(tr('로그인하면 나에게 도착한 응원과 선물을 볼 수 있어요.')),
          const SizedBox(height: 12),
          AccountEntryCard(onChanged: _load),
        ],
      );
    if (_error != null && _cheers.isEmpty)
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.cloud_off_outlined, size: 40),
          Text(_error!, textAlign: TextAlign.center),
          OutlinedButton(onPressed: _load, child: Text(tr('다시 연결하기'))),
        ],
      );
    final pending = _cheers
        .where(
          (c) => c.deliveryKind != 'cheer' && !_claimed(c) && !c.bloomConfirmed,
        )
        .toList();
    final history = _cheers
        .where(
          (c) => c.deliveryKind != 'cheer' && (_claimed(c) || c.bloomConfirmed),
        )
        .toList();
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(14, 2, 14, 24),
      children: [
        if (_loading) const LinearProgressIndicator(),
        if (_error != null) ...[
          Text(_error!),
          TextButton(onPressed: _load, child: Text(tr('새로고침 다시 시도'))),
        ],
        NeighborTabs(
          labels: [tr('받은 선물'), tr('보낸 선물')],
          selected: _sentGifts ? 1 : 0,
          onSelect: (i) => setState(() => _sentGifts = i == 1),
        ),
        if (_sentGifts)
          SentGiftInbox(
            key: ValueKey('sent-gifts-$_accountEpoch-$_request'),
            service: widget.service ?? GardenVillageService(),
            currentAccount: () => _currentOwner,
          ),
        if (!_sentGifts) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE9DF),
              borderRadius: BorderRadius.circular(17),
            ),
            child: LayoutBuilder(
              builder: (context, box) {
                final label = Text(
                  tr('받을 선물 {0}개', [pending.length]) +
                      (_nextCursor != null ? '+' : ''),
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                );
                final action = FilledButton(
                  onPressed:
                      _bulkClaiming ||
                          _claiming.isNotEmpty ||
                          _planting.isNotEmpty ||
                          pending.isEmpty
                      ? null
                      : _claimAll,
                  child: Text(_bulkClaiming ? tr('받는 중…') : tr('모두 받기')),
                );
                final art = SizedBox(
                  width: 44,
                  height: 46,
                  child: NeighborReferenceArt(
                    region: const Rect.fromLTWH(919, 369, 65, 69),
                  ),
                );
                if (MediaQuery.textScalerOf(context).scale(16) > 24 ||
                    box.maxWidth < 290)
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [art, label, action],
                  );
                return Row(
                  children: [
                    art,
                    const SizedBox(width: 9),
                    Expanded(child: label),
                    action,
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          if (_filter == 0) ...[
            ...pending.map((c) => _giftRow(c)),
            if (pending.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(tr('새 선물을 모두 확인했어요.'), textAlign: TextAlign.center),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.history, size: 23),
                const SizedBox(width: 8),
                Text(
                  tr('받은 내역'),
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...history.map((c) => _giftRow(c, history: true)),
            OrchardGiftInbox(
              key: ValueKey('orchard-$_accountEpoch-$_request'),
              service: widget.service,
              currentAccount: () => _currentOwner,
              compact: true,
            ),
          ] else if (_filter == 3)
            OrchardGiftInbox(
              key: ValueKey('orchard-$_accountEpoch-$_request'),
              service: widget.service,
              currentAccount: () => _currentOwner,
            )
          else
            ..._cheers
                .where(_matches)
                .map((c) => _giftRow(c, history: _filter == 2)),
          if (_filter != 0 && _filter != 3 && !_cheers.any(_matches))
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(tr('이 항목의 소식이 없어요. 이전 소식도 확인할 수 있어요.')),
            ),
          if (_pageError != null) Text(_pageError!),
          if (_nextCursor != null)
            OutlinedButton.icon(
              key: const Key('received-cheers-more'),
              onPressed: _loadingMore || _loading ? null : _loadMore,
              icon: const Icon(Icons.expand_more),
              label: Text(
                _loadingMore
                    ? tr('이전 마음을 불러오고 있어요…')
                    : _pageError != null
                    ? tr('이전 마음 다시 불러오기')
                    : tr('이전 마음 더 보기'),
              ),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final entry in {
                0: tr('전체 선물'),
                1: tr('응원 메시지'),
                2: tr('받은 꽃 내역'),
                3: tr('과일·간식'),
              }.entries)
                ChoiceChip(
                  label: Text(entry.value),
                  selected: _filter == entry.key,
                  onSelected: (_) {
                    setState(() => _filter = entry.key);
                    if (_filter == 1 && _currentOwner != null)
                      unawaited(
                        GardenReturnStore.instance
                            .markSeen(
                              _currentOwner!,
                              _cheers
                                  .where((c) => c.deliveryKind == 'cheer')
                                  .map((c) => c.id),
                            )
                            .catchError((Object _) {}),
                      );
                  },
                ),
            ],
          ),
          Wrap(
            spacing: 8,
            children: [
              TextButton.icon(
                onPressed: () => showCheerFlowers(context),
                icon: const Icon(Icons.local_florist_outlined, size: 18),
                label: Text(tr('꽃 보관함')),
              ),
              TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const GardenBloomNewsScreen(),
                  ),
                ),
                icon: const Icon(Icons.mark_email_read_outlined, size: 18),
                label: Text(tr('내가 건넨 꽃 소식')),
              ),
            ],
          ),
          Text(
            tr('과일·간식은 자동 보관돼요. 모두 받기는 불러온 꽃 선물을 보관해요.'),
            style: const TextStyle(fontSize: 12, color: neighborInk),
          ),
        ],
      ],
    );
  }
}
