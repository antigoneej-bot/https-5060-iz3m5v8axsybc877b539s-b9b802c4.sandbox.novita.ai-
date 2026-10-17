import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/garden_village_service.dart';
import '../../services/social_auth_service.dart';
import '../../theme.dart' show AppColors;
import '../../widgets/account_entry_card.dart';
import '../models/public_garden.dart';
import '../widgets/public_garden_card.dart';

class PublicGardenBrowseScreen extends StatefulWidget {
  const PublicGardenBrowseScreen({
    super.key,
    this.embedded = false,
    this.service,
    this.accountReady,
    this.currentAccount,
    this.accountChanges,
  });
  final bool embedded;
  final GardenVillageService? service;
  final Future<bool> Function()? accountReady;
  final String? Function()? currentAccount;
  final Stream<String?>? accountChanges;
  @override
  State<PublicGardenBrowseScreen> createState() =>
      _PublicGardenBrowseScreenState();
}

class _PublicGardenBrowseScreenState extends State<PublicGardenBrowseScreen> {
  late GardenVillageService _service;
  StreamSubscription<String?>? _auth;
  bool _loading = true, _needsAccount = false, _loadingMore = false;
  String? _error, _pageError, _owner, _nextCursor;
  int _request = 0;
  List<PublicGarden> _gardens = const [];

  String? get _currentOwner => widget.currentAccount != null
      ? widget.currentAccount!()
      : widget.service?.accountOwner ?? SocialAuthService.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? GardenVillageService();
    _owner = _currentOwner;
    final changes =
        widget.accountChanges ??
        (SocialAuthService.firebaseReady
            ? FirebaseAuth.instance.authStateChanges().map((user) => user?.uid)
            : null);
    _auth = changes?.listen((owner) {
      if (!mounted || owner == _owner) return;
      _owner = owner;
      _request++;
      _service = widget.service ?? GardenVillageService();
      setState(() {
        _gardens = const [];
        _nextCursor = null;
        _pageError = null;
      });
      _load();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _request++;
    _auth?.cancel();
    super.dispose();
  }

  bool _isCurrent(int request, String? owner) =>
      mounted && request == _request && owner == _currentOwner;

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
          _gardens = const [];
          _nextCursor = null;
        });
        return;
      }
      final page = await _service.listPublicGardensPage();
      if (!_isCurrent(request, owner)) return;
      setState(() {
        _gardens = {
          for (final garden in page.gardens) garden.gardenId: garden,
        }.values.toList();
        _nextCursor = page.nextCursor;
        _loading = false;
      });
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
      final page = await _service.listPublicGardensPage(cursor: cursor);
      if (!_isCurrent(request, owner)) return;
      if (page.nextCursor == cursor) {
        throw const FormatException('다음 정원을 불러오지 못했어요. 다시 시도해 주세요.');
      }
      setState(() {
        _gardens = {
          for (final garden in _gardens) garden.gardenId: garden,
          for (final garden in page.gardens) garden.gardenId: garden,
        }.values.toList();
        _nextCursor = page.nextCursor;
      });
    } catch (error) {
      if (_isCurrent(request, owner)) {
        setState(() => _pageError = error.toString());
      }
    } finally {
      if (_isCurrent(request, owner)) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = RefreshIndicator(onRefresh: _load, child: _body());
    return widget.embedded
        ? content
        : Scaffold(
            backgroundColor: AppColors.bg0,
            appBar: AppBar(
              title: const Text('정원 둘러보기'),
              backgroundColor: AppColors.bg0,
            ),
            body: content,
          );
  }

  Widget _body() {
    if (_loading && _gardens.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_needsAccount) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('로그인하면 이웃의 정원에 방문하고 응원을 남길 수 있어요.'),
          const SizedBox(height: 12),
          AccountEntryCard(
            onChanged: () async {
              _service = widget.service ?? GardenVillageService();
              await _load();
            },
          ),
        ],
      );
    }
    if (_error != null && _gardens.isEmpty) {
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
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        if (_loading) const LinearProgressIndicator(),
        if (_error != null) ...[
          Text(_error!),
          TextButton(onPressed: _load, child: const Text('새로고침 다시 시도')),
        ],
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '둘러보기에 동의한 정원만 보여요. 마음에 드는 정원에 방문해 응원을 남기거나 이웃을 신청해 보세요. 인기 순위는 없어요.',
              style: TextStyle(height: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_gardens.isEmpty && _nextCursor == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Text(
              '지금 둘러볼 수 있는 정원이 없어요.\n내 이웃에서 친구 코드로 연결할 수도 있어요.',
              textAlign: TextAlign.center,
              style: TextStyle(height: 1.6),
            ),
          ),
        if (_gardens.isEmpty && _nextCursor != null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text('이 구간에는 방문할 수 있는 정원이 없어요. 다음 정원도 둘러보세요.'),
          ),
        ..._gardens.map(
          (garden) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: PublicGardenCard(garden: garden, alreadyCheeredToday: false),
          ),
        ),
        if (_pageError != null) Text(_pageError!),
        if (_nextCursor != null)
          OutlinedButton.icon(
            key: const Key('public-gardens-more'),
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
                  ? '정원을 불러오고 있어요…'
                  : _pageError != null
                  ? '다음 정원 다시 불러오기'
                  : '다른 정원 더 보기',
            ),
          ),
      ],
    );
  }
}
