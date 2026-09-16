import '../../widgets/subscription_gate.dart';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/emotion_l10n.dart';
import '../l10n/gen/app_localizations.dart';
import '../l10n/purchase_l10n.dart';
import '../l10n/share_frame_l10n.dart';
import '../models/emotion.dart';
import '../providers/garden_provider.dart';
import '../services/purchase_service.dart';

/// 감정 공유 카드의 배경 프레임 스타일.
/// [isPremium]이 true인 프레임(벚꽃/골드 별빛)은 [kPremiumFramesProductId] 인앱 상품을
/// 구매해야 실제로 사용할 수 있다. 구매 전에는 미리보기만 가능하다.
/// (코어 게임 루프는 절대 유료화하지 않는다는 원칙 - 이 프레임은 순수 코스메틱 항목)
class _CardFrame {
  final String id;
  final bool isPremium;
  final List<Color> Function(Color emotionColor) colors;
  final String cornerEmoji;

  const _CardFrame({
    required this.id,
    required this.isPremium,
    required this.colors,
    required this.cornerEmoji,
  });
}

List<Color> _defaultFrameColors(Color emotionColor) => [
  emotionColor.withValues(alpha: 0.92),
  emotionColor.withValues(alpha: 0.62),
];

List<Color> _cherryFrameColors(Color _) => const [
  Color(0xFFE85D8B),
  Color(0xFFF7A8C4),
];

List<Color> _goldFrameColors(Color _) => const [
  Color(0xFF232B5D),
  Color(0xFF4A3B78),
];

const List<_CardFrame> _frames = [
  _CardFrame(
    id: 'default',
    isPremium: false,
    colors: _defaultFrameColors,
    cornerEmoji: '',
  ),
  _CardFrame(
    id: 'cherry',
    isPremium: true,
    colors: _cherryFrameColors,
    cornerEmoji: '🌸',
  ),
  _CardFrame(
    id: 'gold',
    isPremium: true,
    colors: _goldFrameColors,
    cornerEmoji: '⭐',
  ),
];

/// 오늘 마주한 감정을 이미지 카드로 만들어 공유할 수 있는 바텀시트.
///
/// [RepaintBoundary]로 감싼 카드 위젯을 스크린샷(PNG)으로 캡처한 뒤
/// [SharePlus]를 통해 시스템 공유 시트(안드로이드 Intent.ACTION_SEND / 웹 Web Share API)로 전달한다.
/// 프리미엄 프레임(벚꽃/골드 별빛)은 [kPremiumFramesProductId] 인앱 상품을 구매하면
/// 영구적으로 사용할 수 있다(비소모성 - 1회 구매로 계속 이용).
class EmotionShareSheet extends StatefulWidget {
  final Emotion emotion;
  final String? targetName;
  final int eatenCount;
  final int maxCombo;
  final bool choseLove;
  final String note;

  const EmotionShareSheet({
    super.key,
    required this.emotion,
    required this.targetName,
    required this.eatenCount,
    required this.maxCombo,
    required this.choseLove,
    required this.note,
  });

  /// 바텀시트 형태로 공유 카드를 보여준다.
  static Future<void> show(
    BuildContext context, {
    required Emotion emotion,
    required String? targetName,
    required int eatenCount,
    required int maxCombo,
    required bool choseLove,
    required String note,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EmotionShareSheet(
        emotion: emotion,
        targetName: targetName,
        eatenCount: eatenCount,
        maxCombo: maxCombo,
        choseLove: choseLove,
        note: note,
      ),
    );
  }

  @override
  State<EmotionShareSheet> createState() => _EmotionShareSheetState();
}

class _EmotionShareSheetState extends State<EmotionShareSheet> {
  final GlobalKey _cardKey = GlobalKey();
  bool _sharing = false;
  bool _purchasing = false;
  int _selectedFrameIndex = 0;

  _CardFrame get _selectedFrame => _frames[_selectedFrameIndex];

  String _nameLabel(AppLocalizations l10n) =>
      (widget.targetName != null && widget.targetName!.isNotEmpty)
      ? l10n.shareNameLabelWithTarget(
          widget.targetName!,
          emotionLabel(l10n, widget.emotion.type),
        )
      : emotionLabel(l10n, widget.emotion.type);

  Future<void> _share() async {
    if (_sharing) return;
    final garden = context.read<GardenProvider>();
    await garden.refreshSubscription();
    if (!mounted) return;
    if (_selectedFrame.isPremium && !garden.premiumFramesUnlocked) {
      await _showPurchaseSheet();
      return;
    }
    final l10n = AppLocalizations.of(context);
    setState(() => _sharing = true);
    try {
      // 카드가 그려질 시간을 한 프레임 확보한다 (바텀시트 오픈 애니메이션 직후 캡처 시 빈 이미지 방지).
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final boundary =
          _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw StateError(l10n.shareCardNotFoundError);
      }
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw StateError(l10n.shareImageConvertError);
      }
      final bytes = byteData.buffer.asUint8List();

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              bytes,
              name: 'mongi_garden_card.png',
              mimeType: 'image/png',
            ),
          ],
          text: l10n.shareTextBody(_nameLabel(l10n), widget.eatenCount),
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('share error: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.shareErrorSnackbar)));
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  /// 프리미엄 프레임 팩 구매 확인 다이얼로그를 띄우고, 동의하면 실제 결제를 시작한다.
  /// 구매 성공/복원 여부는 [GardenProvider.premiumFramesUnlocked]가 콜백을 통해
  /// 비동기로 갱신되며, 이 위젯은 [context.watch]로 그 값을 구독하고 있어 자동으로 반영된다.
  Future<void> _showPurchaseSheet() async {
    await requestSubscription(context);
    if (!mounted) return;
    await context.read<GardenProvider>().refreshSubscription();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final unlocked = context.watch<GardenProvider>().premiumFramesUnlocked;
    final now = DateTime.now();
    final dateLabel =
        '${now.year}.${now.month.toString().padLeft(2, '0')}.${now.day.toString().padLeft(2, '0')}';
    final frame = _selectedFrame;
    final isLocked = frame.isPremium && !unlocked;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              l10n.shareTitle,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.shareSubtitle,
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            _buildFrameSelector(l10n, unlocked),
            const SizedBox(height: 16),
            RepaintBoundary(
              key: _cardKey,
              child: _buildCard(l10n, dateLabel, frame, isLocked),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (_sharing || _purchasing)
                    ? null
                    : (isLocked ? _showPurchaseSheet : _share),
                icon: (_sharing || _purchasing)
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(isLocked ? Icons.lock_outline : Icons.ios_share),
                label: Text(
                  isLocked
                      ? (_purchasing
                            ? l10n.sharePurchaseConfirming
                            : '마음냥 구독 알아보기')
                      : (_sharing
                            ? l10n.shareCreatingCard
                            : l10n.shareCardButton),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLocked
                      ? Colors.grey.shade700
                      : widget.emotion.color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            if (isLocked) ...[
              const SizedBox(height: 6),
              TextButton(
                onPressed: _purchasing
                    ? null
                    : () => context
                          .read<GardenProvider>()
                          .restorePremiumFramesPurchase(),
                child: Text(
                  l10n.shareRestorePurchaseButton,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFrameSelector(AppLocalizations l10n, bool unlocked) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _frames.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final frame = _frames[index];
          final selected = index == _selectedFrameIndex;
          return ChoiceChip(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (frame.isPremium && !unlocked) ...[
                  const Icon(Icons.lock, size: 12),
                  const SizedBox(width: 4),
                ] else if (frame.isPremium) ...[
                  const Icon(Icons.star, size: 12),
                  const SizedBox(width: 4),
                ],
                Text(shareFrameLabel(l10n, frame.id)),
              ],
            ),
            selected: selected,
            onSelected: (_) => setState(() => _selectedFrameIndex = index),
            selectedColor: widget.emotion.color.withValues(alpha: 0.22),
            labelStyle: TextStyle(
              fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
              fontSize: 12.5,
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard(
    AppLocalizations l10n,
    String dateLabel,
    _CardFrame frame,
    bool isLocked,
  ) {
    final colors = frame.colors(widget.emotion.color);
    return Stack(
      children: [
        Container(
          width: 300,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text('🐱', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 6),
                  Text(
                    l10n.shareCardBrand,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  if (frame.cornerEmoji.isNotEmpty) ...[
                    Text(
                      frame.cornerEmoji,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    dateLabel,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(widget.emotion.emoji, style: const TextStyle(fontSize: 40)),
              const SizedBox(height: 8),
              Text(
                widget.eatenCount > 0
                    ? l10n.shareCardHeadlineWithCount(
                        _nameLabel(l10n),
                        widget.eatenCount,
                      )
                    : l10n.shareCardHeadlineNoCount(_nameLabel(l10n)),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
              if (widget.note.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '"${widget.note.trim()}"',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
              if (widget.maxCombo >= 3) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    l10n.shareCardComboBadge(widget.maxCombo),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                widget.choseLove
                    ? emotionHealMessage(l10n, widget.emotion.type)
                    : l10n.shareCardNoLoveMessage,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        if (isLocked)
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock, size: 11, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    l10n.shareCardPreviewBadge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
