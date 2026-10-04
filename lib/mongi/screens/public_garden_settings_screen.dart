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

class _PublicGardenSettingsScreenState
    extends State<PublicGardenSettingsScreen> {
  late final TextEditingController _nicknameController;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final garden = context.read<GardenProvider>();
    _nicknameController = TextEditingController(
      text: garden.gardenPublicNickname ?? '',
    );
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    setState(() => _busy = true);
    final l10n = AppLocalizations.of(context);
    try {
      final garden = context.read<GardenProvider>();
      final ok = await garden.publishGarden(
        nickname: _nicknameController.text,
      );
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.publicGardenServerUnavailable)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _unpublish() async {
    setState(() => _busy = true);
    try {
      await context.read<GardenProvider>().unpublishGarden();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
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
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      published ? Icons.visibility : Icons.visibility_off,
                      size: 18,
                      color: published
                          ? const Color(0xFF7FB37A)
                          : AppColors.inkSoft,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        published
                            ? l10n.publicGardenPublishedNotice
                            : l10n.publicGardenNotPublishedNotice,
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
                    onPressed: _busy || !CloudService.enabled
                        ? null
                        : (published ? _unpublish : _publish),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: published
                          ? const Color(0xFFD8D2C8)
                          : const Color(0xFF7FB37A),
                      foregroundColor: published
                          ? AppColors.ink
                          : Colors.white,
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
            const Icon(
              Icons.chevron_right,
              color: AppColors.inkSoft,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
