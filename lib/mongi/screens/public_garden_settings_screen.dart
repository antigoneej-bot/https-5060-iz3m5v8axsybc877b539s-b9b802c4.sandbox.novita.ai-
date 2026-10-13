import '../models/seed.dart';
import '../models/garden_decoration.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/cloud_service.dart';
import '../../theme.dart' show AppColors;
import '../l10n/gen/app_localizations.dart';
import '../providers/garden_provider.dart';
import 'public_garden_browse_screen.dart';
import 'public_garden_inbox_screen.dart';

/// "정원 공개하기" 설정 화면 - 내 정원을 다른 사람에게 보여줄지 직접
/// 선택하는(opt-in) 화면.
///
/// [설계 원칙] 기본값은 항상 비공개다. 공개를 켜도 전송되는 정보는 심은
/// 씨앗 수/장착 장식/나무 단계뿐이고, 일기·기록 내용은 이 화면에서 다루는
/// 데이터 자체에 포함되지 않는다(서버 스키마에도 없음). 언제든 "공개
/// 그만하기"로 즉시 내릴 수 있다.
class PublicGardenSettingsScreen extends StatefulWidget {
  const PublicGardenSettingsScreen({super.key});

  @override
  State<PublicGardenSettingsScreen> createState() =>
      _PublicGardenSettingsScreenState();
}

class _PublicGardenSettingsScreenState extends State<PublicGardenSettingsScreen>
    with WidgetsBindingObserver {
  late final TextEditingController _nicknameController;
  bool _busy = false;
  bool _nicknameDirty = false;
  String? _editingAccount;
  late final GardenProvider _garden;

  void _publicationChanged() {
    if (!mounted) return;
    final account = _garden.publicGardenAccount;
    if (_editingAccount != account) {
      _editingAccount = account;
      _nicknameDirty = false;
      _nicknameController.text = _garden.gardenPublicNickname ?? '';
    } else if (!_nicknameDirty) {
      final nickname = _garden.gardenPublicNickname ?? '';
      if (_nicknameController.text != nickname)
        _nicknameController.text = nickname;
    }
  }

  Future<void> _refreshStatus() async {
    if (_busy || !mounted) return;
    setState(() => _busy = true);
    try {
      await _garden.refreshPublicGardenStatus();
    } catch (_) {
      // Unknown remains visible; failure never means the garden is private.
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshStatus();
  }

  @override
  void initState() {
    super.initState();
    _garden = context.read<GardenProvider>();
    _editingAccount = _garden.publicGardenAccount;
    _nicknameController = TextEditingController(
      text: _garden.gardenPublicNickname ?? '',
    );
    _garden.addListener(_publicationChanged);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshStatus());
  }

  @override
  void dispose() {
    _garden.removeListener(_publicationChanged);
    WidgetsBinding.instance.removeObserver(this);
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    if (_busy) return;
    setState(() => _busy = true);
    final l10n = AppLocalizations.of(context);
    try {
      final garden = context.read<GardenProvider>();
      final confirmingAccount = garden.publicGardenAccount;
      final yes = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('이 내용으로 정원을 공개할까요?'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '이웃에게 보이는 이름: ${_nicknameController.text.trim().isEmpty ? '이름 없는 정원사' : _nicknameController.text.trim()}',
                ),
                const SizedBox(height: 12),
                const Text('공개: 정원 배치·식물 종류와 성장 단계·장식·응원 꽃'),
                const SizedBox(height: 8),
                Text(
                  '심은 식물: ${SeedType.all.where((seed) => (garden.seedCounts[seed.id] ?? 0) > 0).map((seed) => seed.label).join(', ')}',
                ),
                Text(
                  '장식: ${garden.equippedDecorationIds.map((id) => GardenDecoration.byId(id).label).join(', ')}',
                ),
                const SizedBox(height: 16),
                const Text('비공개: 편지·감정 점수·돌봄 후기·식물의 개인 이름과 메모·심은 날짜와 기념일'),
                const SizedBox(height: 8),
                const Text(
                  '정원의 성장 모습은 보이지만 마음 상태를 공개하지 않아요. 언제든 공개를 그만할 수 있어요.',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('이 내용 공개하기'),
            ),
          ],
        ),
      );
      if (yes != true || !mounted) return;
      if (confirmingAccount != garden.publicGardenAccount) {
        throw const CloudException('account-changed');
      }
      final ok = await garden.publishGarden(nickname: _nicknameController.text);
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.publicGardenServerUnavailable)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('정원 공개 상태를 바꾸지 못했어요. 연결을 확인하고 다시 시도해 주세요.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _unpublish() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await context.read<GardenProvider>().unpublishGarden();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('서버에서 정원 공개를 중단했어요.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('정원 공개 상태를 바꾸지 못했어요. 연결을 확인하고 다시 시도해 주세요.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final garden = context.watch<GardenProvider>();
    final published = garden.isGardenPublished;
    final known = garden.isGardenPublicationKnown;
    final signedIn = garden.publicGardenAccount != null;
    final canChange = !_busy && CloudService.enabled && signedIn;
    final statusMessage = !CloudService.enabled
        ? '온라인 정원 연결을 준비 중이에요.'
        : !signedIn
        ? '로그인하면 내 정원의 공개 상태를 확인할 수 있어요.'
        : garden.isGardenPublicationLoading
        ? '서버의 공개 상태를 확인하고 있어요.'
        : !known
        ? '공개 상태를 확인하지 못했어요. 정원이 공개 중일 수 있어요.'
        : published
        ? l10n.publicGardenPublishedNotice
        : l10n.publicGardenNotPublishedNotice;

    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        backgroundColor: AppColors.bg0,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l10n.publicGardenSettingsTitle,
          style: const TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.publicGardenSettingsDesc,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.inkSoft,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '🔒 편지·감정 점수·돌봄 후기·식물의 이름·메모·기념일은 나만 볼 수 있어요.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      !known
                          ? Icons.help_outline
                          : published
                          ? Icons.visibility
                          : Icons.visibility_off,
                      size: 18,
                      color: published
                          ? const Color(0xFF7FB37A)
                          : AppColors.inkSoft,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        statusMessage,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: published
                              ? const Color(0xFF4C7A44)
                              : AppColors.inkSoft,
                        ),
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: _busy || !CloudService.enabled || !signedIn
                      ? null
                      : _refreshStatus,
                  icon: const Icon(Icons.refresh),
                  label: const Text('서버 공개 상태 다시 확인'),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.publicGardenNicknameLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _nicknameController,
                  onChanged: (_) => _nicknameDirty = true,
                  enabled: !_busy,
                  maxLength: 20,
                  decoration: InputDecoration(
                    hintText: l10n.publicGardenNicknameHint,
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (!CloudService.enabled)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      l10n.publicGardenServerUnavailable,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: canChange
                        ? (published ? _unpublish : _publish)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: published
                          ? const Color(0xFFD8D2C8)
                          : const Color(0xFF7FB37A),
                      foregroundColor: published ? AppColors.ink : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            published
                                ? l10n.publicGardenUnpublishButton
                                : l10n.publicGardenPublishButton,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                  ),
                ),
              ],
            ),
          ),
          if (!published) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: const ValueKey('stop-publication'),
              onPressed: canChange ? _unpublish : null,
              icon: const Icon(Icons.visibility_off_outlined),
              label: const Text('공개 상태와 관계없이 공개 중단'),
            ),
            if (!known && signedIn)
              const Text('상태 조회가 실패해도 위 버튼으로 서버의 정원 공개를 중단할 수 있어요.'),
          ],
          if (published) ...[
            const SizedBox(height: 8),
            const Text(
              '정원을 바꾼 뒤 아래 버튼을 누르면 이웃에게도 새 배치를 보여줘요. 편지와 식물에 남긴 추억은 공개되지 않아요.',
            ),
            OutlinedButton.icon(
              onPressed: canChange ? _publish : null,
              icon: const Icon(Icons.refresh),
              label: const Text('지금 정원 모습으로 공개 갱신'),
            ),
          ],
          const SizedBox(height: 16),
          _buildNavRow(
            context,
            emoji: '🌍',
            label: l10n.publicGardenBrowseTitle,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const PublicGardenBrowseScreen(),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _buildNavRow(
            context,
            emoji: '💌',
            label: l10n.publicGardenInboxTitle,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const PublicGardenInboxScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavRow(
    BuildContext context, {
    required String emoji,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.ink,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.inkSoft, size: 20),
          ],
        ),
      ),
    );
  }
}
