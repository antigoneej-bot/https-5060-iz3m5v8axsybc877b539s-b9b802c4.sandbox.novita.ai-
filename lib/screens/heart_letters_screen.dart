import '../l10n/app_language.dart';
import '../widgets/calm_letter_receipt.dart';
import '../widgets/letter_care_closing_card.dart';
import '../mongi/screens/garden_world_screen.dart';
import '../widgets/reply_support_actions.dart';
import '../models/reply_style.dart';
import '../services/draft_service.dart';
import 'package:flutter/material.dart';
import '../models/special_letter_entry.dart';
import '../services/special_letter_service.dart';
import '../theme.dart';
import 'heart_letter_history_screen.dart';

/// "마음편지" — 감사·용서·미안함·사랑, 네 가지 짧은 마음편지를 쓰는 화면.
///
/// 상대에게 전송하지 않는 개인 기록입니다. 자동 답장을 기다리지 않고
/// 사용자가 원하는 시점에 편지를 마무리할 수 있습니다.
class HeartLettersScreen extends StatelessWidget {
  const HeartLettersScreen({super.key});

  Future<void> _openHistory(BuildContext context) async {
    final type = await showModalBottomSheet<SpecialLetterType>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                tr("지난 마음편지"),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            for (final type in SpecialLetterType.values)
              ListTile(
                leading: Text(type.emoji),
                title: Text(type.label),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pop(sheetContext, type),
              ),
          ],
        ),
      ),
    );
    if (type == null || !context.mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => HeartLetterHistoryScreen(type: type),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          tr("오늘, 어떤 마음을\n편지로 전해볼까요?"),
          textAlign: TextAlign.center,
          style: titleFont(fontSize: 21, color: AppColors.ink, height: 1.4),
        ),
        const SizedBox(height: 8),
        Text(
          tr("누구에게도 보내지 않는 편지예요. 지금 마음을 그대로 남겨요."),
          textAlign: TextAlign.center,
          style: bodyFont(fontSize: 12.5, color: AppColors.inkSoft),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _openHistory(context),
          icon: const Icon(Icons.mail_outline),
          label: Text(tr("지난 마음편지")),
        ),
        const SizedBox(height: 24),
        _HeartLetterGrid(),
      ],
    );
  }
}

class _HeartLetterGrid extends StatelessWidget {
  static const _cards = [
    (
      type: SpecialLetterType.gratitude,
      accent: AppColors.blobButterAccent,
      background: AppColors.blobButter,
    ),
    (
      type: SpecialLetterType.forgiveness,
      accent: AppColors.blobPeriwinkleAccent,
      background: AppColors.blobPeriwinkle,
    ),
    (
      type: SpecialLetterType.apology,
      accent: AppColors.blobLavenderAccent,
      background: AppColors.blobLavender,
    ),
    (
      type: SpecialLetterType.love,
      accent: AppColors.blobRoseAccent,
      background: AppColors.blobRose,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final c in _cards)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _HeartLetterTile(
              type: c.type,
              accent: c.accent,
              background: c.background,
            ),
          ),
      ],
    );
  }
}

/// 짧은(short) 알약형 박스 - 긴 설명 없이 이모지 + 이름 + 한 줄 안내만
/// 담아, '리듬'보다 '가벼움'을 강조합니다.
class _HeartLetterTile extends StatefulWidget {
  final SpecialLetterType type;
  final Color accent;
  final Color background;
  const _HeartLetterTile({
    required this.type,
    required this.accent,
    required this.background,
  });

  @override
  State<_HeartLetterTile> createState() => _HeartLetterTileState();
}

class _HeartLetterTileState extends State<_HeartLetterTile> {
  bool _pressed = false;

  void _open(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WriteHeartLetterSheet(
        type: widget.type,
        accent: widget.accent,
        background: widget.background,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.type;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: () => _open(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        transform: Matrix4.identity()
          ..scaleByDouble(
            _pressed ? 0.98 : 1.0,
            _pressed ? 0.98 : 1.0,
            1.0,
            1.0,
          ),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              widget.background.withValues(alpha: 0.88),
              widget.background.withValues(alpha: 0.55),
            ],
          ),
          border: Border.all(color: widget.accent.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: widget.accent.withValues(alpha: 0.14),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.65),
                border: Border.all(
                  color: widget.accent.withValues(alpha: 0.35),
                ),
              ),
              child: Text(type.emoji, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type.label,
                    style: pathLabelFont(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    type.shortPrompt,
                    style: bodyFont(fontSize: 11.5, color: AppColors.inkSoft),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_rounded, color: widget.accent, size: 18),
          ],
        ),
      ),
    );
  }
}

/// 편지를 저장한 뒤 바로 마무리하거나, 원할 때만 돌아볼 수 있습니다.
/// 상대에게 전송하거나 자동 답장을 예약하지 않습니다.
class _WriteHeartLetterSheet extends StatefulWidget {
  final SpecialLetterType type;
  final Color accent;
  final Color background;
  const _WriteHeartLetterSheet({
    required this.type,
    required this.accent,
    required this.background,
  });

  @override
  State<_WriteHeartLetterSheet> createState() => _WriteHeartLetterSheetState();
}

class _WriteHeartLetterSheetState extends State<_WriteHeartLetterSheet> {
  late final DraftTextController _controller;
  @override
  void initState() {
    super.initState();
    _controller = DraftTextController('heart_${widget.type.storageKey}');
  }

  final ReplyStyle _replyStyle = ReplyStyle.listen;
  bool _sending = false;
  SpecialLetterEntry? _result;
  String? _submissionId;
  String? _attemptText;
  ReplyStyle? _attemptStyle;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      if (_submissionId == null ||
          _attemptText != text ||
          _attemptStyle != _replyStyle) {
        _submissionId =
            '${DateTime.now().microsecondsSinceEpoch}_${widget.type.storageKey}';
        _attemptText = text;
        _attemptStyle = _replyStyle;
      }
      final entry = await SpecialLetterService.sendLetter(
        type: widget.type,
        submissionId: _submissionId,
        letterText: text,
        replyStyle: _replyStyle,
      );
      try {
        await _controller.discard();
      } catch (_) {
        /* Source is already saved. */
      }
      if (!mounted) return;
      setState(() => _result = entry);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr("편지를 보내지 못했어요. 잠시 후 다시 시도해 주세요"))),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.type;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                widget.background.withValues(alpha: 0.98),
                AppColors.bg0,
              ],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: widget.accent.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(type.emoji, style: const TextStyle(fontSize: 30)),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    type.label,
                    style: titleFont(fontSize: 19, color: AppColors.ink),
                  ),
                ),
                const SizedBox(height: 18),
                if (_result == null) ...[
                  Text(
                    type.question,
                    style: pathLabelFont(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    child: TextField(
                      controller: _controller,
                      minLines: 3,
                      maxLines: 6,
                      autofocus: true,
                      style: bodyFont(fontSize: 13.5, color: AppColors.moon),
                      decoration: InputDecoration(
                        filled: false,
                        hintText: type.hint,
                        hintStyle: bodyFont(
                          fontSize: 12.5,
                          color: AppColors.inkSoft,
                        ),
                        contentPadding: const EdgeInsets.all(14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _controller,
                    builder: (_, value, __) =>
                        ReplySupportActions(letterText: value.text),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _sending ? null : _send,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        elevation: 0,
                      ),
                      child: _sending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              tr("편지 남기기"),
                              style: pathLabelFont(
                                fontSize: 15,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ] else
                  _SentConfirmationView(
                    type: type,
                    accent: widget.accent,
                    entry: _result!,
                    onClose: () => Navigator.of(context).pop(),
                    onHistory: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => HeartLetterHistoryScreen(type: type),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A saved letter can end here without any further question or purchase.
class _SentConfirmationView extends StatelessWidget {
  final SpecialLetterType type;
  final Color accent;
  final SpecialLetterEntry entry;
  final VoidCallback onClose;
  final VoidCallback onHistory;
  const _SentConfirmationView({
    required this.type,
    required this.accent,
    required this.entry,
    required this.onClose,
    required this.onHistory,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ReplySupportActions(letterText: entry.letterText),
      const CalmLetterReceipt(),
      const SizedBox(height: 20),
      FilledButton(onPressed: onClose, child: Text(tr("오늘은 여기까지"))),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const GardenWorldScreen.owned(),
          ),
        ),
        icon: const Icon(Icons.park_outlined),
        label: Text(tr("정원에서 잠깐 쉬기")),
      ),
      const SizedBox(height: 12),
      LetterCareClosingCard.heart(letter: entry),
      TextButton(onPressed: onHistory, child: Text(tr("지난 마음편지 보기"))),
    ],
  );
}
