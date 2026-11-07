import '../../l10n/app_language.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/garden_village_service.dart';
import '../../services/social_auth_service.dart';
import '../../theme.dart' show AppColors;
import '../../widgets/account_entry_card.dart';
import '../models/public_garden.dart';
import 'garden_visit_screen.dart';

/// Discovery and favorites never create neighbor links or shared records.
class GardenDiscoveryScreen extends StatefulWidget {
  const GardenDiscoveryScreen({
    super.key,
    this.service,
    this.accountReady,
    this.favorites = false,
  });
  final GardenVillageService? service;
  final Future<bool> Function()? accountReady;
  final bool favorites;
  @override
  State<GardenDiscoveryScreen> createState() => _GardenDiscoveryScreenState();
}

class _GardenDiscoveryScreenState extends State<GardenDiscoveryScreen> {
  late GardenVillageService _service;
  StreamSubscription<User?>? _auth;
  PublicGarden? _garden;
  List<PublicGarden> _favorites = [];
  List<String> _unavailable = [];
  String? _cursor, _error, _last, _owner;
  bool _loading = true, _needsAccount = false;
  int _request = 0;
  @override
  void initState() {
    super.initState();
    _service = widget.service ?? GardenVillageService();
    _owner = _service.accountOwner;
    if (SocialAuthService.firebaseReady) {
      _auth = FirebaseAuth.instance.authStateChanges().listen((user) {
        if (!mounted || user?.uid == _owner) return;
        _request++;
        _owner = user?.uid;
        _service = widget.service ?? GardenVillageService();
        _last = null;
        _garden = null;
        _favorites = [];
        _load();
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _request++;
    _auth?.cancel();
    super.dispose();
  }

  Future<void> _load({bool more = false}) async {
    if (!mounted) return;
    final request = ++_request;
    final owner = _service.accountOwner;
    setState(() {
      _loading = true;
      _error = null;
      _needsAccount = false;
      if (!more) {
        _garden = null;
        _favorites = [];
        _unavailable = [];
        _cursor = null;
      }
    });
    try {
      final ready =
          await (widget.accountReady?.call() ??
              SocialAuthService.isAccountReady());
      if (!mounted || request != _request || owner != _service.accountOwner)
        return;
      if (!ready) {
        setState(() {
          _needsAccount = true;
          _loading = false;
        });
        return;
      }
      if (widget.favorites) {
        final page = await _service.favoriteGardens(
          cursor: more ? _cursor : null,
        );
        if (!mounted || request != _request || owner != _service.accountOwner)
          return;
        if (more && page.nextCursor != null && page.nextCursor == _cursor)
          throw const FormatException('다음 목록을 확인하지 못했어요.');
        setState(() {
          _favorites = {
            for (final g in _favorites) g.gardenId: g,
            for (final g in page.gardens) g.gardenId: g,
          }.values.toList();
          _unavailable = {..._unavailable, ...page.unavailableIds}.toList();
          _cursor = page.nextCursor;
        });
      } else {
        final garden = await _service.randomGarden();
        if (!mounted || request != _request || owner != _service.accountOwner)
          return;
        // Defense against a stale/old response; the server owns the real history.
        setState(() {
          _garden = garden?.gardenId == _last ? null : garden;
          if (_garden != null) _last = _garden!.gardenId;
        });
      }
    } catch (error) {
      if (mounted && request == _request && owner == _service.accountOwner)
        setState(() => _error = error.toString());
    } finally {
      if (mounted && request == _request && owner == _service.accountOwner)
        setState(() => _loading = false);
    }
  }

  Future<void> _visit(PublicGarden garden) async {
    final request = _request;
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => GardenVisitScreen(
          gardenId: garden.gardenId,
          service: _service,
          accountReady: widget.accountReady,
          publicDiscovery: true,
        ),
      ),
    );
    if (mounted && request == _request) await _load();
  }

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    if (!_loading && !_needsAccount && _error == null && _garden != null) {
      return GardenVisitScreen(
        key: ValueKey('${_service.accountOwner}:${_garden!.gardenId}'),
        gardenId: _garden!.gardenId,
        service: _service,
        accountReady: widget.accountReady,
        publicDiscovery: true,
        onNextGarden: () => _load(),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        title: Text(widget.favorites ? tr("즐겨찾는 정원") : tr("이웃 정원 둘러보기")),
        backgroundColor: AppColors.bg0,
      ),
      body: _loading && _favorites.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (_needsAccount) AccountEntryCard(onChanged: () => _load()),
                if (!_needsAccount) ...[
                  const Text(
                    '방문을 허용한 공개 정원만 만나요. 방문하거나 즐겨찾아도 이웃 연결이나 기록 공유는 생기지 않아요.',
                    style: TextStyle(height: 1.5),
                  ),
                  const SizedBox(height: 18),
                  if (_error != null)
                    Text(_error!, textAlign: TextAlign.center),
                  if (_error == null && _favorites.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      child: Text(
                        widget.favorites
                            ? '지금 방문할 수 있는 즐겨찾기 정원이 없어요.\n비공개로 전환하거나 차단된 정원은 보여드리지 않아요.'
                            : '지금 새로 둘러볼 정원을 찾지 못했어요.\n정원이 하나뿐이면 같은 정원을 연속해서 보여드리지 않아요.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(height: 1.7),
                      ),
                    ),
                  for (final garden in _favorites)
                    Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.park_outlined,
                          color: AppColors.catSage,
                        ),
                        title: Text(garden.nickname ?? '이름 없는 정원사'),
                        onTap: _loading ? null : () => _visit(garden),
                        trailing: IconButton(
                          tooltip: tr("즐겨찾기 해제"),
                          icon: const Icon(Icons.star),
                          onPressed: _loading
                              ? null
                              : () async {
                                  final request = _request;
                                  try {
                                    await _service.setFavorite(
                                      garden.gardenId,
                                      false,
                                    );
                                    if (mounted && request == _request)
                                      await _load();
                                  } catch (error) {
                                    if (mounted && request == _request)
                                      setState(() => _error = error.toString());
                                  }
                                },
                        ),
                      ),
                    ),
                  for (final id in _unavailable)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.lock_outline),
                        title: const Text('지금 방문할 수 없는 정원'),
                        subtitle: const Text('공개 해제·차단·삭제된 정원의 정보는 표시하지 않아요.'),
                        trailing: IconButton(
                          tooltip: '방문 불가 정원 즐겨찾기 해제',
                          icon: const Icon(Icons.star_border),
                          onPressed: _loading
                              ? null
                              : () async {
                                  final request = _request;
                                  try {
                                    await _service.setFavorite(id, false);
                                    if (mounted && request == _request)
                                      await _load();
                                  } catch (error) {
                                    if (mounted && request == _request)
                                      setState(() => _error = error.toString());
                                  }
                                },
                        ),
                      ),
                    ),
                  if (_loading) const LinearProgressIndicator(),
                  if (_cursor != null)
                    OutlinedButton(
                      onPressed: _loading ? null : () => _load(more: true),
                      child: const Text('다음 즐겨찾기'),
                    ),
                  FilledButton.icon(
                    onPressed: _loading ? null : () => _load(),
                    icon: const Icon(Icons.refresh),
                    label: Text(widget.favorites ? '다시 확인하기' : '다른 정원 찾기'),
                  ),
                ],
              ],
            ),
    );
  }
}
