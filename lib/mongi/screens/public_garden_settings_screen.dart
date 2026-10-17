import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/garden_village_service.dart';
import '../../services/social_auth_service.dart';
import '../../theme.dart' show AppColors;
import '../../widgets/account_entry_card.dart';
import '../models/garden_village.dart';
import '../providers/garden_provider.dart';

/// Visibility and discovery are separate, explicitly saved choices.
class PublicGardenSettingsScreen extends StatefulWidget {
  const PublicGardenSettingsScreen({
    super.key,
    this.service,
    this.accountReady,
    this.accountChanges,
    this.currentAccount,
  });
  final GardenVillageService? service;
  final Future<bool> Function()? accountReady;
  final Stream<String?>? accountChanges;
  final String? Function()? currentAccount;
  @override
  State<PublicGardenSettingsScreen> createState() =>
      _PublicGardenSettingsScreenState();
}

class _PublicGardenSettingsScreenState
    extends State<PublicGardenSettingsScreen> {
  late GardenVillageService _service;
  final _nickname = TextEditingController();
  StreamSubscription<String?>? _auth;
  GardenVisibility _visibility = GardenVisibility.private;
  bool _discovery = false, _receiveGifts = true;
  bool _loading = true, _busy = false, _needsAccount = false;
  String? _error, _owner;
  String? _appearanceError;
  GardenVillageProfile? _savedProfile;
  int _request = 0;
  String? get _currentOwner => widget.currentAccount != null
      ? widget.currentAccount!()
      : SocialAuthService.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? GardenVillageService();
    _owner = _service.accountOwner;
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
      _nickname.clear();
      setState(() {
        _visibility = GardenVisibility.private;
        _discovery = false;
        _receiveGifts = true;
        _busy = false;
        _savedProfile = null;
        _appearanceError = null;
      });
      _load();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _request++;
    _auth?.cancel();
    _nickname.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    final request = ++_request;
    final owner = _currentOwner;
    bool current() => mounted && request == _request && owner == _currentOwner;
    setState(() {
      _loading = true;
      _needsAccount = false;
      _error = null;
    });
    try {
      final ready =
          await (widget.accountReady?.call() ??
              SocialAuthService.isAccountReady());
      if (!current()) return;
      if (!ready) {
        setState(() {
          _needsAccount = true;
          _loading = false;
        });
        return;
      }
      final profile = await _service.getProfile();
      if (!current()) return;
      String? appearanceError;
      try {
        await context.read<GardenProvider>().refreshPublicGardenAppearance();
      } catch (_) {
        appearanceError = '마지막으로 저장한 정원 모습을 확인하지 못했어요.';
      }
      if (!current()) return;
      setState(() {
        _savedProfile = profile;
        _appearanceError = appearanceError;
        _nickname.text = profile.nickname ?? '';
        _visibility = profile.visibility;
        _discovery = profile.discoveryOptIn;
        _receiveGifts = profile.receiveGifts;
        _loading = false;
        _needsAccount = false;
      });
    } catch (error) {
      if (current()) {
        setState(() {
          _error = error.toString();
          _loading = false;
        });
      }
    }
  }

  void _message(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  bool get _settingsChanged {
    final saved = _savedProfile;
    return saved != null &&
        (_nickname.text.trim() != (saved.nickname ?? '') ||
            _visibility != saved.visibility ||
            _discovery != saved.discoveryOptIn ||
            _receiveGifts != saved.receiveGifts);
  }

  Future<void> _updateAppearance() async {
    if (_busy || _settingsChanged) return;
    final request = _request;
    final owner = _currentOwner;
    setState(() => _busy = true);
    try {
      final garden = context.read<GardenProvider>();
      final saved = await garden.updatePublishedGardenAppearance();
      if (!mounted || request != _request || owner != _currentOwner) return;
      if (!saved) {
        _message('서버에 저장하지 못했어요. 연결을 확인하고 다시 시도해 주세요.');
        return;
      }
      _message(
        garden.gardenPublication == false
            ? '정원 모습을 저장했어요. 서버의 나만 보기 설정은 그대로 유지했어요.'
            : '이웃에게 보이는 정원 모습을 업데이트했어요.',
      );
      await _load();
    } catch (error) {
      if (mounted && request == _request && owner == _currentOwner) {
        _message(error.toString());
      }
    } finally {
      if (mounted && owner == _currentOwner) setState(() => _busy = false);
    }
  }

  Widget _appearanceStatus() {
    final garden = context.watch<GardenProvider>();
    final changed = garden.hasUnpublishedGardenChanges;
    final published = garden.gardenPublication;
    final updated = garden.gardenPublishedAt?.toLocal();
    final canUpdate = garden.canUpdatePublishedGardenAppearance;
    final status =
        _appearanceError ??
        (published == false
            ? '지금은 나만 보는 정원이에요.'
            : published == null || changed == null
            ? '저장된 정원 모습과의 차이는 아직 확인하지 못했어요.'
            : changed
            ? '새로 가꾼 모습이 아직 이웃에게 보이지 않아요.'
            : '지금 정원 모습이 이웃에게도 보이고 있어요.');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '이웃에게 보이는 정원',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(status),
            if (updated != null) ...[
              const SizedBox(height: 6),
              Text(
                '마지막 모습 저장 · ${updated.year}.${updated.month.toString().padLeft(2, '0')}.${updated.day.toString().padLeft(2, '0')} ${updated.hour.toString().padLeft(2, '0')}:${updated.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
              ),
            ],
            if (_savedProfile?.visibility != GardenVisibility.private) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const Key('public-garden-update-now'),
                onPressed: _busy || _settingsChanged || !canUpdate
                    ? null
                    : _updateAppearance,
                icon: const Icon(Icons.cloud_upload_outlined),
                label: const Text('지금 정원 모습 업데이트'),
              ),
              Text(
                !canUpdate
                    ? '저장된 모습을 다시 확인해 주세요. 계속 확인되지 않으면 서버 업데이트가 필요할 수 있어요.'
                    : _settingsChanged
                    ? '바꾼 설정도 적용하려면 아래의 저장 버튼을 눌러 주세요.'
                    : '현재 공개 범위와 받기 설정은 그대로 유지해요.',
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: AppColors.inkSoft,
                ),
              ),
            ],
            if (_appearanceError != null ||
                published == null ||
                changed == null)
              TextButton(
                onPressed: _busy ? null : _load,
                child: const Text('정원 모습 다시 확인'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_busy) return;
    final request = _request;
    final owner = _currentOwner;
    setState(() => _busy = true);
    try {
      final saved = await context.read<GardenProvider>().publishGarden(
        nickname: _nickname.text.trim(),
        visibility: _visibility,
        discoveryOptIn: _visibility == GardenVisibility.public && _discovery,
        receiveGifts: _receiveGifts,
      );
      if (!mounted || request != _request || owner != _currentOwner) return;
      if (!saved) {
        _message('서버에 저장하지 못했어요. 연결을 확인하고 다시 시도해 주세요.');
        return;
      }
      _message('정원 공개 범위와 받기 설정을 저장했어요.');
      await _load();
    } catch (error) {
      if (mounted && request == _request && owner == _currentOwner) {
        _message(error.toString());
      }
    } finally {
      if (mounted && owner == _currentOwner) setState(() => _busy = false);
    }
  }

  Future<void> _makePrivate() async {
    if (_busy) return;
    final request = _request;
    final owner = _currentOwner;
    setState(() => _busy = true);
    try {
      // This works even if the earlier status read failed; never claim privacy
      // until the server has acknowledged the write.
      await _service.updateProfile(
        visibility: GardenVisibility.private,
        discoveryOptIn: false,
        receiveGifts: false,
      );
      if (!mounted || request != _request || owner != _currentOwner) return;
      _message('정원을 나만 보기로 바꿨어요.');
      await _load();
    } catch (error) {
      if (mounted && request == _request && owner == _currentOwner) {
        _message(error.toString());
      }
    } finally {
      if (mounted && owner == _currentOwner) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bg0,
    appBar: AppBar(
      title: const Text('정원 공개와 받기 설정'),
      backgroundColor: AppColors.bg0,
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              AccountEntryCard(
                onChanged: () async {
                  _service = widget.service ?? GardenVillageService();
                  await _load();
                },
              ),
              const SizedBox(height: 16),
              if (_needsAccount)
                const Text('로그인하면 내 정원의 공개 범위와 선물 받기를 정할 수 있어요.')
              else if (_error != null) ...[
                Text(_error!),
                const SizedBox(height: 8),
                const Text('현재 서버의 공개 범위를 확인하지 못했어요. 정원이 공개 중일 수 있어요.'),
                OutlinedButton(
                  onPressed: _busy ? null : _load,
                  child: const Text('다시 확인하기'),
                ),
                TextButton.icon(
                  onPressed: _busy ? null : _makePrivate,
                  icon: const Icon(Icons.visibility_off_outlined),
                  label: const Text('공개 상태 확인 없이 나만 보기로 변경'),
                ),
              ] else ...[
                const Text(
                  '공개되는 것은 내가 가꾼 정원 모습과 정원사 이름이에요. 편지, 감정 통계, 식물에 남긴 개인적인 추억은 공개되지 않아요.',
                  style: TextStyle(height: 1.6, color: AppColors.inkSoft),
                ),
                const SizedBox(height: 20),
                _appearanceStatus(),
                const SizedBox(height: 20),
                TextField(
                  controller: _nickname,
                  enabled: !_busy,
                  maxLength: 20,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: '정원사 이름',
                    hintText: '이웃에게 보여줄 이름',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '누가 내 정원에 방문할 수 있나요?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                RadioGroup<GardenVisibility>(
                  groupValue: _visibility,
                  onChanged: (value) {
                    if (_busy || value == null) return;
                    setState(() {
                      _visibility = value;
                      if (_visibility != GardenVisibility.public) {
                        _discovery = false;
                      }
                    });
                  },
                  child: Column(
                    children:
                        [
                              (
                                GardenVisibility.private,
                                '나만 보기',
                                '다른 사람은 내 정원에 방문할 수 없어요.',
                              ),
                              (
                                GardenVisibility.neighbors,
                                '이웃에게 공개',
                                '서로 수락한 이웃만 내 정원에 방문해요.',
                              ),
                              (
                                GardenVisibility.public,
                                '모두에게 공개',
                                '로그인한 정원사들이 내 정원에 방문할 수 있어요.',
                              ),
                            ]
                            .map(
                              (option) => RadioListTile<GardenVisibility>(
                                contentPadding: EdgeInsets.zero,
                                value: option.$1,
                                enabled: !_busy,
                                title: Text(option.$2),
                                subtitle: Text(option.$3),
                              ),
                            )
                            .toList(),
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('둘러보기에 내 정원 소개'),
                  subtitle: Text(
                    _visibility == GardenVisibility.public
                        ? '처음 만나는 정원사도 내 정원을 발견할 수 있어요.'
                        : '모두에게 공개할 때만 선택할 수 있어요.',
                  ),
                  value: _visibility == GardenVisibility.public && _discovery,
                  onChanged: _busy || _visibility != GardenVisibility.public
                      ? null
                      : (value) => setState(() => _discovery = value),
                ),
                const Divider(height: 28),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('이웃의 꽃 선물 받기'),
                  subtitle: const Text(
                    '새 꽃 선물을 받을지 정해요. 이미 받은 꽃은 그대로 남아요. 원치 않는 이웃은 방문 화면에서 차단할 수 있어요.',
                  ),
                  value: _receiveGifts,
                  onChanged: _busy
                      ? null
                      : (value) => setState(() => _receiveGifts = value),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _busy ? null : _save,
                  child: Text(_busy ? '저장하고 있어요…' : '설정과 지금 정원 모습 저장'),
                ),
                const SizedBox(height: 8),
                const Text(
                  '정원을 가꾼 뒤 다시 저장하면 이웃에게 새 배치를 보여줄 수 있어요.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
            ],
          ),
  );
}
