import '../../l10n/garden_copy.dart';
import '../../l10n/app_language.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import '../../models/cat_visit.dart';
import 'dart:async';
import 'package:flutter/services.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/garden_village_service.dart';
import '../../services/cloud_service.dart';
import '../../services/social_auth_service.dart';
import '../../theme.dart' show AppColors;
import '../../widgets/account_entry_card.dart';
import '../integration/cheer_flower_store.dart';
import '../models/garden_gifts.dart';
import '../models/public_garden.dart';
import '../providers/garden_provider.dart';
import '../widgets/garden_cheer_composer.dart';
import '../widgets/garden_gift_art.dart';
import '../widgets/garden_world_view.dart';

class GardenVisitScreen extends StatefulWidget {
  const GardenVisitScreen({
    super.key,
    required this.gardenId,
    this.nickname,
    this.service,
    this.accountReady,
    this.visitId,
    this.publicDiscovery = false,
    this.onNextGarden,
  });
  final String gardenId;
  final bool publicDiscovery;
  final Future<void> Function()? onNextGarden;
  final String? visitId;
  final String? nickname;
  final GardenVillageService? service;
  final Future<bool> Function()? accountReady;
  @override
  State<GardenVisitScreen> createState() => _GardenVisitScreenState();
}

class _GardenVisitScreenState extends State<GardenVisitScreen>
    with WidgetsBindingObserver {
  late GardenVillageService _service;
  StreamSubscription<User?>? _auth;
  PublicGarden? _garden;
  CatVisit? _visit;
  Timer? _visitTimer;
  Timer? _publicTimer;
  bool _favorite = false,
      _overview = false,
      _publicChecking = false,
      _orientationSet = false;
  int _favoriteRevision = 0;
  String _visitActivity = 'greet';
  final _photoKey = GlobalKey();
  bool _loading = true, _busy = false, _needsAccount = false;
  bool _neighbor = false, _outgoing = false, _incoming = false;
  bool _cheered = false, _gifted = false;
  String? _error, _owner;
  int _request = 0;
  final Map<String, String> _giftRequests = {};

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? GardenVillageService();
    _owner = _service.accountOwner;
    if (widget.publicDiscovery) {
      WidgetsBinding.instance.addObserver(this);
      _publicTimer = Timer.periodic(
        const Duration(seconds: 15),
        (_) => _revalidatePublic(),
      );
    }
    if (widget.visitId != null) {
      _visitTimer = Timer.periodic(
        const Duration(seconds: 30),
        (_) => _checkVisit(),
      );
    }
    if (SocialAuthService.firebaseReady) {
      _auth = FirebaseAuth.instance.authStateChanges().listen((user) {
        if (!mounted || user?.uid == _owner) return;
        _owner = user?.uid;
        _request++;
        _service = widget.service ?? GardenVillageService();
        setState(() {
          _garden = null;
          _visit = null;
          _cheered = false;
          _gifted = false;
          _giftRequests.clear();
        });
        _load();
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _request++;
    _auth?.cancel();
    _visitTimer?.cancel();
    _publicTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    if (_orientationSet) unawaited(SystemChrome.setPreferredOrientations([]));
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    final request = ++_request;
    setState(() {
      _loading = true;
      _needsAccount = false;
      _garden = null;
      _visit = null;
      _error = null;
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
      final visit = widget.visitId == null
          ? null
          : await _service.getCatVisit(widget.visitId!);
      if (visit != null &&
          (visit.hostId != widget.gardenId || visit.guestCat == null)) {
        throw FormatException(tr('초대받은 정원을 확인하지 못했어요.'));
      }
      final garden = widget.publicDiscovery
          ? await _service.getPublicVisitGarden(widget.gardenId)
          : await _service.getGarden(widget.gardenId);
      final people = widget.publicDiscovery
          ? null
          : await _service.listNeighbors();
      if (!mounted || request != _request) return;
      setState(() {
        _garden = garden;
        _visit = visit;
        _favorite = garden.isFavorite;
        _neighbor =
            people?.neighbors.any((p) => p.gardenId == widget.gardenId) ??
            garden.neighborStatus == 'accepted';
        _outgoing =
            people?.outgoing.any((p) => p.gardenId == widget.gardenId) ??
            garden.neighborStatus == 'outgoing';
        _incoming =
            people?.incoming.any((p) => p.gardenId == widget.gardenId) ??
            garden.neighborStatus == 'incoming';
        _loading = false;
        _needsAccount = false;
      });
    } catch (error) {
      if (mounted && request == _request) {
        setState(() {
          _error = error.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _checkVisit() async {
    if (!mounted ||
        _loading ||
        _busy ||
        widget.visitId == null ||
        _visit == null)
      return;
    final request = _request;
    try {
      await _service.getCatVisit(widget.visitId!);
    } catch (_) {
      if (mounted && request == _request)
        setState(() {
          _visit = null;
          _garden = null;
          _error = tr('방문이 끝났어요. 우리 고양이와 돌아가요.');
        });
    }
  }

  Future<void> _photo() async {
    if (_visit == null) return;
    await _perform(() async {
      final request = _request;
      await _service.getCatVisit(widget.visitId!);
      if (!mounted || request != _request || _visit == null) return;
      await WidgetsBinding.instance.endOfFrame;
      final boundary =
          _photoKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) throw StateError(tr('사진을 다시 찍어 주세요.'));
      final image = await boundary.toImage(pixelRatio: 2);
      try {
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        if (bytes == null) throw StateError(tr('사진을 만들지 못했어요.'));
        if (!mounted || request != _request) return;
        await Gal.putImageBytes(
          bytes.buffer.asUint8List(),
          name: 'mindnyang_visit_${DateTime.now().millisecondsSinceEpoch}',
        );
      } finally {
        image.dispose();
      }
    }, tr('함께 찍은 사진을 휴대폰 사진첩에 저장했어요.'));
  }

  void _message(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _perform(
    Future<void> Function() action,
    String message, {
    bool reload = false,
  }) async {
    if (_busy) return;
    final request = _request;
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted || request != _request) return;
      _message(message);
      if (reload) await _load();
    } catch (error) {
      if (mounted && request == _request) {
        if (widget.publicDiscovery &&
            error is CloudException &&
            error.code == 'garden-not-found')
          setState(() {
            _garden = null;
            _error = tr('공개가 해제되었거나 지금 방문할 수 없는 정원이에요.');
          });
        _message(error.toString());
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cheer({bool gift = false}) async {
    if (_busy) return;
    final request = _request;
    final picked = await composeGardenCheer(context, includeFlower: gift);
    if (picked == null || !mounted || request != _request) return;
    await _perform(
      () async {
        await _service.sendCheer(
          gardenId: widget.gardenId,
          messageIndex: picked.message,
          flowerKind: picked.flower,
          reaction: picked.reaction,
          deliveryKind: gift ? 'gift' : 'cheer',
        );
        if (mounted && request == _request) {
          setState(() {
            if (gift) {
              _gifted = true;
            } else {
              _cheered = true;
            }
          });
        }
      },
      gift
          ? tr('꽃 선물을 보냈어요. 이웃이 원하는 때 심을 수 있어요.')
          : tr('응원을 보냈어요. 정원에 24시간 머물러요.'),
    );
  }

  Future<void> _gifts() async {
    if (_busy) return;
    final request = _request;
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                tr('이웃에게 꽃 선물하기'),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Text(tr('받은 꽃은 이웃이 원하는 때 정원에 심어요. 선물을 꼭 돌려주지 않아도 괜찮아요.')),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _gifted
                    ? null
                    : () {
                        Navigator.pop(sheetContext);
                        if (mounted && request == _request) _cheer(gift: true);
                      },
                icon: const Icon(Icons.local_florist_outlined),
                label: Text(_gifted ? tr('오늘의 꽃을 보냈어요') : tr('오늘의 꽃 보내기 · 무료')),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  if (mounted && request == _request) _storedGift();
                },
                icon: const Icon(Icons.inventory_2_outlined),
                label: Text(tr('보관한 꽃 선물하기')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _storedGift() async {
    if (_busy) return;
    final request = _request;
    setState(() => _busy = true);
    ReceivedCheer? picked;
    try {
      picked = await showModalBottomSheet<ReceivedCheer>(
        context: context,
        isScrollControlled: true,
        builder: (_) => _StoredGiftPicker(
          service: _service,
          isCurrent: () => mounted && request == _request,
        ),
      );
    } finally {
      if (mounted && request == _request) setState(() => _busy = false);
    }
    if (picked == null || !mounted || request != _request) return;
    final selected = picked;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('이 꽃을 선물할까요?')),
        content: Text(
          gardenCopy('giftTransfer', [
            tr(gardenFlowerNames[selected.flowerKind] ?? '응원 꽃'),
          ]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr("취소")),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr('선물 보내기')),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted || request != _request) return;
    final id = _giftRequests.putIfAbsent(
      selected.id,
      GardenVillageService.createGiftRequestId,
    );
    await _transferGift(selected.id, id);
  }

  Future<void> _transferGift(String sourceId, String requestId) async {
    if (_busy) return;
    final request = _request;
    setState(() => _busy = true);
    try {
      await context.read<GardenProvider>().sendGardenGift(
        gardenId: widget.gardenId,
        sourceCheerId: sourceId,
        requestId: requestId,
      );
      if (!mounted || request != _request) return;
      _giftRequests.remove(sourceId);
      _message(tr('꽃 선물을 보냈어요. 내 보관함에서도 반영했어요.'));
    } catch (error) {
      if (!mounted || request != _request) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(gardenCopy('deliveryCheck', [error.toString()])),
          duration: const Duration(seconds: 10),
          action: SnackBarAction(
            label: tr('전송 확인'),
            onPressed: () {
              if (mounted && request == _request) {
                _transferGift(sourceId, requestId);
              }
            },
          ),
        ),
      );
    } finally {
      if (mounted && request == _request) setState(() => _busy = false);
    }
  }

  Future<void> _manage(String action) async {
    if (_busy) return;
    final request = _request;
    if (action == 'report') {
      final reasons = {
        'inappropriate_name': tr('부적절한 이름'),
        'harassment': tr('괴롭힘'),
        'spam': tr('반복적인 원치 않는 활동'),
        'other': tr('기타'),
      };
      final reason = await showDialog<String>(
        context: context,
        builder: (context) => SimpleDialog(
          title: Text(tr('신고 사유')),
          children: reasons.entries
              .map(
                (r) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, r.key),
                  child: Text(r.value),
                ),
              )
              .toList(),
        ),
      );
      if (reason != null && mounted && request == _request) {
        await _perform(
          () => _service.reportGarden(widget.gardenId, reason: reason),
          tr('신고를 접수했어요.'),
        );
      }
      return;
    }
    final block = action == 'block';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(block ? tr("이 이웃을 차단할까요?") : tr("이웃 연결을 해제할까요?")),
        content: Text(
          block
              ? tr('이웃 연결이 해제되고 서로 정원 방문과 응원·선물을 할 수 없게 돼요.')
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
    if (confirm != true || !mounted || request != _request) return;
    await _perform(() async {
      if (block) {
        await _service.blockNeighbor(widget.gardenId);
      } else {
        await _service.removeNeighbor(widget.gardenId);
      }
      if (mounted && widget.publicDiscovery && widget.onNextGarden != null) {
        await widget.onNextGarden!();
      } else if (mounted)
        Navigator.pop(context);
    }, block ? tr("이웃을 차단했어요.") : tr("이웃 연결을 해제했어요."));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (widget.publicDiscovery && state == AppLifecycleState.resumed)
      unawaited(_revalidatePublic());
  }

  Future<void> _revalidatePublic() async {
    if (!mounted ||
        !widget.publicDiscovery ||
        _loading ||
        _busy ||
        _publicChecking ||
        _garden == null ||
        ModalRoute.of(context)?.isCurrent == false)
      return;
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.paused)
      return;
    final request = _request, favoriteRevision = _favoriteRevision;
    _publicChecking = true;
    try {
      final garden = await _service.getPublicVisitGarden(widget.gardenId);
      if (mounted &&
          request == _request &&
          favoriteRevision == _favoriteRevision)
        setState(() {
          _garden = garden;
          _favorite = garden.isFavorite;
        });
    } catch (error) {
      if (mounted && request == _request)
        setState(() {
          _garden = null;
          _error = error is CloudException && error.code == 'garden-not-found'
              ? tr('공개가 해제되었거나 지금 방문할 수 없는 정원이에요.')
              : tr('정원 상태를 확인하지 못했어요. 연결을 확인하고 다시 시도해 주세요.');
        });
    } finally {
      _publicChecking = false;
    }
  }

  Future<void> _toggleFavorite() async {
    if (_busy || _garden == null) return;
    final next = !_favorite;
    _favoriteRevision++;
    await _perform(() async {
      await _service.setFavorite(widget.gardenId, next);
      if (mounted) setState(() => _favorite = next);
    }, next ? tr('즐겨찾기에 담았어요. 이웃 연결이나 기록 공유는 생기지 않아요.') : tr('즐겨찾기를 해제했어요.'));
  }

  Future<void> _rotatePublic() async {
    _orientationSet = true;
    final landscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    try {
      await SystemChrome.setPreferredOrientations(
        landscape
            ? [DeviceOrientation.portraitUp]
            : [
                DeviceOrientation.landscapeLeft,
                DeviceOrientation.landscapeRight,
              ],
      );
    } catch (_) {
      if (mounted) _message(tr('기기의 화면 회전 설정을 확인해 주세요.'));
    }
  }

  Widget _publicView() {
    final garden = _garden;
    final name = garden?.nickname ?? tr("이웃");
    final cat = garden?.publicCoat == null
        ? null
        : VisitingCat(
            coat: garden!.publicCoat!,
            stage: garden.publicCatStage,
            name: tr('이웃 고양이'),
          );
    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        backgroundColor: AppColors.bg0,
        title: Text(
          garden == null ? tr("이웃 정원") : gardenCopy('neighborGarden', [name]),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            key: const Key('public-garden-favorite'),
            tooltip: _favorite ? tr("즐겨찾기 해제") : tr("즐겨찾기"),
            onPressed: _busy || garden == null ? null : _toggleFavorite,
            icon: Icon(_favorite ? Icons.star : Icons.star_border),
          ),
          PopupMenuButton<String>(
            tooltip: tr('신고와 차단'),
            enabled: !_busy && garden != null,
            onSelected: _manage,
            itemBuilder: (_) => [
              PopupMenuItem(value: 'block', child: Text(tr("차단"))),
              PopupMenuItem(value: 'report', child: Text(tr('신고'))),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _needsAccount
                ? Padding(
                    padding: const EdgeInsets.all(20),
                    child: AccountEntryCard(onChanged: _load),
                  )
                : garden == null
                ? Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _error ?? tr('지금 방문할 수 없는 정원이에요.'),
                            textAlign: TextAlign.center,
                          ),
                          OutlinedButton(
                            onPressed: _load,
                            child: Text(tr('다시 확인하기')),
                          ),
                          if (widget.onNextGarden != null)
                            FilledButton(
                              onPressed: widget.onNextGarden,
                              child: Text(tr('다른 정원으로')),
                            ),
                        ],
                      ),
                    ),
                  )
                : garden.layout == null
                ? Center(child: Text(tr('이웃이 정원 모습을 아직 갱신하지 않았어요.')))
                : GardenWorldView(
                    key: ValueKey(
                      'public-world:${_service.accountOwner}:${widget.gardenId}',
                    ),
                    readOnly: true,
                    fillViewport: true,
                    immersive: true,
                    overviewRequested: _overview,
                    visitingHost: cat,
                    companionName: cat?.name ?? tr('이웃 고양이'),
                    companionScale: cat?.scale ?? 1,
                    companionBondStage: cat?.stage ?? 0,
                    publicMemoryStage: garden.memoryTreeStage,
                    publicCheerBed: garden.hasCheerFlowers,
                    reactions: garden.reactions,
                    flowerKinds: garden.flowerKinds,
                    layout: garden.layout!,
                    seeds: garden.seedCounts,
                    decorations: garden.equippedDecorationIds,
                    onMove: (_, _) async {},
                    onMemory: (_) {},
                    onPlant: () {},
                    onDecorate: () {},
                  ),
          ),
          if (garden != null && !_loading)
            Positioned(
              left: 8,
              right: 8,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Card(
                  color: AppColors.bg0.withValues(alpha: .96),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          key: const Key('public-garden-overview'),
                          tooltip: tr("전체 보기"),
                          onPressed: () =>
                              setState(() => _overview = !_overview),
                          icon: const Icon(Icons.zoom_out_map),
                        ),
                        IconButton(
                          key: const Key('public-garden-rotate'),
                          tooltip: tr("가로·세로 전환"),
                          onPressed: _rotatePublic,
                          icon: const Icon(Icons.screen_rotation_outlined),
                        ),
                        IconButton(
                          key: const Key('public-garden-cheer'),
                          tooltip: _cheered ? tr('응원 보냈어요') : tr('응원꽃 보내기'),
                          onPressed: _busy || _cheered ? null : () => _cheer(),
                          icon: Icon(
                            _cheered ? Icons.favorite : Icons.favorite_border,
                            color: AppColors.catSage,
                          ),
                        ),
                        const Spacer(),
                        if (widget.onNextGarden != null)
                          Flexible(
                            flex: 5,
                            child: FilledButton(
                              key: const Key('public-garden-next'),
                              onPressed: _busy ? null : widget.onNextGarden,
                              child: Text(tr('다른 정원으로'), maxLines: 1),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (_busy)
            const Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    if (widget.publicDiscovery) return _publicView();
    final name = _garden?.nickname ?? widget.nickname ?? tr("이웃");
    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        title: Text(gardenCopy('neighborGarden', [name])),
        backgroundColor: AppColors.bg0,
        actions: [
          PopupMenuButton<String>(
            enabled: !_busy && _garden != null,
            tooltip: tr("이웃 관리"),
            onSelected: _manage,
            itemBuilder: (_) => [
              if (_neighbor)
                PopupMenuItem(value: 'remove', child: Text(tr("이웃 연결 해제"))),
              PopupMenuItem(value: 'block', child: Text(tr("차단"))),
              PopupMenuItem(value: 'report', child: Text(tr('신고'))),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _needsAccount
          ? ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(tr('로그인하면 이웃 정원에 방문할 수 있어요.')),
                AccountEntryCard(
                  onChanged: () async {
                    _service = widget.service ?? GardenVillageService();
                    await _load();
                  },
                ),
              ],
            )
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _load,
                      child: Text(tr('다시 확인하기')),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: _garden!.layout == null
                      ? Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(tr('이웃이 정원 모습을 아직 갱신하지 않았어요.')),
                          ),
                        )
                      : RepaintBoundary(
                          key: _photoKey,
                          child: ColoredBox(
                            color: AppColors.bg0,
                            child: GardenWorldView(
                              key: ValueKey(
                                '${_service.accountOwner}:${widget.gardenId}',
                              ),
                              readOnly: true,
                              fillViewport: _visit != null,
                              visitingHost: _visit?.hostCat,
                              visitingGuest: _visit?.guestCat,
                              visitActivity: _visitActivity,
                              companionName:
                                  _visit?.hostCat.name ?? tr('이웃 고양이'),
                              companionScale: _visit?.hostCat.scale ?? 1,
                              companionBondStage: _visit?.hostCat.stage ?? 0,
                              publicMemoryStage: _garden!.memoryTreeStage,
                              publicCheerBed: _garden!.hasCheerFlowers,
                              reactions: _garden!.reactions,
                              flowerKinds: _garden!.flowerKinds,
                              layout: _garden!.layout!,
                              seeds: _garden!.seedCounts,
                              decorations: _garden!.equippedDecorationIds,
                              onMove: (_, _) async {},
                              onMemory: (_) {},
                              onPlant: () {},
                              onDecorate: () {},
                            ),
                          ),
                        ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_visit != null) ...[
                          Text(
                            gardenCopy('guestSnapshot', [
                              _visit!.guestCat!.name,
                            ]),
                          ),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              for (final activity in {
                                'greet': tr('인사하기'),
                                'walk': tr('함께 산책'),
                                'rest': tr('함께 쉬기'),
                              }.entries)
                                ChoiceChip(
                                  label: Text(activity.value),
                                  selected: _visitActivity == activity.key,
                                  onSelected: _busy
                                      ? null
                                      : (_) => setState(
                                          () => _visitActivity = activity.key,
                                        ),
                                ),
                              IconButton(
                                key: const Key('visit-photo'),
                                tooltip: tr('함께 사진 찍기'),
                                onPressed: _busy ? null : _photo,
                                icon: const Icon(Icons.camera_alt_outlined),
                              ),
                              TextButton(
                                onPressed: _busy
                                    ? null
                                    : () => Navigator.pop(context),
                                child: Text(tr('방문 마치기')),
                              ),
                            ],
                          ),
                        ],
                        if (!_neighbor)
                          OutlinedButton.icon(
                            onPressed: _busy || _outgoing
                                ? null
                                : () => _perform(
                                    () => _incoming
                                        ? _service.respondNeighbor(
                                            widget.gardenId,
                                            accept: true,
                                          )
                                        : _service.requestNeighbor(
                                            gardenId: widget.gardenId,
                                          ),
                                    _incoming
                                        ? tr("이웃으로 연결됐어요.")
                                        : tr('이웃 신청을 보냈어요.'),
                                    reload: true,
                                  ),
                            icon: const Icon(Icons.person_add_alt_1),
                            label: Text(
                              _outgoing
                                  ? tr('이웃 신청을 기다리고 있어요')
                                  : _incoming
                                  ? tr('이웃 신청 수락')
                                  : tr("이웃 신청"),
                            ),
                          ),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: _busy || _cheered
                                    ? null
                                    : () => _cheer(),
                                icon: const Text('💛'),
                                label: Text(
                                  _cheered ? tr('응원 보냈어요') : tr('응원'),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                key: const Key('village-send-gift'),
                                onPressed:
                                    _busy ||
                                        !_neighbor ||
                                        _garden!.receiveGifts == false
                                    ? null
                                    : _gifts,
                                icon: const Icon(Icons.card_giftcard, size: 18),
                                label: Text(tr("선물")),
                              ),
                            ),
                          ],
                        ),
                        if (_garden!.receiveGifts == false)
                          Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              tr('이웃이 지금은 꽃 선물을 쉬고 있어요.'),
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.inkSoft,
                              ),
                            ),
                          ),
                        if (!_neighbor)
                          Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              tr('선물은 이웃 신청을 서로 수락한 뒤 보낼 수 있어요.'),
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.inkSoft,
                              ),
                            ),
                          ),
                        if (_busy) const LinearProgressIndicator(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/// Reads old inventory on demand instead of treating the newest inbox page as
/// the entire collection. Only server-confirmed gifts can enter the picker.
class _StoredGiftPicker extends StatefulWidget {
  const _StoredGiftPicker({required this.service, required this.isCurrent});
  final GardenVillageService service;
  final bool Function() isCurrent;

  @override
  State<_StoredGiftPicker> createState() => _StoredGiftPickerState();
}

class _StoredGiftPickerState extends State<_StoredGiftPicker> {
  late final String? _owner;
  StreamSubscription<User?>? _auth;
  bool _loading = true;
  String? _cursor, _error;
  List<ReceivedCheer> _gifts = const [];

  bool get _active =>
      mounted && widget.isCurrent() && widget.service.accountOwner == _owner;

  @override
  void initState() {
    super.initState();
    _owner = widget.service.accountOwner;
    if (SocialAuthService.firebaseReady) {
      _auth = FirebaseAuth.instance.authStateChanges().listen((user) {
        if (mounted && user?.uid != _owner) Navigator.pop(context);
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _auth?.cancel();
    super.dispose();
  }

  Future<void> _load({bool more = false}) async {
    if (!_active || (more && (_loading || _cursor == null))) return;
    final cursor = more ? _cursor : null;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final owner = _owner;
      if (owner == null) throw StateError(tr("로그인 상태를 다시 확인해 주세요."));
      final batch = await widget.service.listReceivedCheers(
        cursor: cursor,
        pageSize: 30,
      );
      if (!_active) return;
      if (cursor != null && cursor == batch.nextCursor) {
        throw FormatException(tr('이전 꽃을 불러오지 못했어요. 다시 시도해 주세요.'));
      }
      await CheerFlowerStore.instance.remember(
        owner,
        batch.cheers,
        retiredIds: batch.retiredIds,
      );
      if (!_active) return;
      final planted = CheerFlowerStore.instance
          .forOwner(_owner)
          .where((flower) => flower.planted)
          .map((flower) => flower.id)
          .toSet();
      setState(() {
        _gifts = {
          for (final gift in [
            ...(more ? _gifts : <ReceivedCheer>[]),
            ...batch.cheers,
          ])
            if (gift.canGift &&
                !planted.contains(gift.id) &&
                !batch.retiredIds.contains(gift.id))
              gift.id: gift,
        }.values.toList();
        _cursor = batch.nextCursor;
      });
    } catch (error) {
      if (_active) setState(() => _error = error.toString());
    } finally {
      if (_active) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .7,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              tr('보관한 꽃 선물하기'),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(tr('아직 심지 않은 꽃만 보낼 수 있어요. 보내면 내 보관함에서 빠지고 상대에게 옮겨져요.')),
            if (_loading) const LinearProgressIndicator(),
            if (!_loading && _error == null && _gifts.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  _cursor == null
                      ? tr('보낼 수 있는 꽃이 아직 없어요. 오늘의 꽃은 무료로 선물할 수 있어요.')
                      : tr('이 구간에는 보낼 수 있는 꽃이 없어요. 이전에 받은 꽃도 확인해 보세요.'),
                ),
              ),
            ..._gifts.map(
              (gift) => ListTile(
                leading: SizedBox(
                  width: 48,
                  height: 48,
                  child: GardenFlowerArt(kind: gift.flowerKind),
                ),
                title: Text(tr(gardenFlowerNames[gift.flowerKind] ?? '응원 꽃')),
                subtitle: Text(
                  gardenCopy('flowerFrom', [gift.senderNickname ?? tr('이웃')]),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: _loading
                    ? null
                    : () {
                        if (_active) Navigator.pop(context, gift);
                      },
              ),
            ),
            if (_error != null) Text(_error!),
            if (_cursor != null || _error != null)
              OutlinedButton.icon(
                key: const Key('stored-gifts-more'),
                onPressed: _loading ? null : () => _load(more: _cursor != null),
                icon: const Icon(Icons.expand_more),
                label: Text(
                  _error != null ? tr("다시 불러오기") : tr('이전에 받은 꽃 더 보기'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
