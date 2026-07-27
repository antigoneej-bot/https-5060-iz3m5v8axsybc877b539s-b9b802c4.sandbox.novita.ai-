import 'package:flutter/material.dart';
import '../models/special_letter_entry.dart';
import '../services/special_letter_service.dart';
import '../theme.dart';
import 'heart_letter_history_screen.dart';

/// "마음편지" — 감사·용서·미안함·사랑, 네 가지 짧은 마음편지를 쓰는 화면.
///
/// 그림자 고양이에게 쓰는 편지와 동일한 컨셉으로, 답장은 그 자리에서
/// 바로 오지 않고 다음날 아침에 도착합니다. 네 가지 편지 종류를 짧고
/// 예쁜 카드 형태로 나열해 보여줍니다.
class HeartLettersScreen extends StatelessWidget {
  const HeartLettersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '오늘, 어떤 마음을\n편지로 전해볼까요?',
          textAlign: TextAlign.center,
          style: titleFont(fontSize: 21, color: AppColors.ink, height: 1.4),
        ),
        const SizedBox(height: 8),
        Text(
          '짧게 적어보세요. 답장은 내일 아침에 도착해요',
          textAlign: TextAlign.center,
          style: bodyFont(fontSize: 12.5, color: AppColors.inkSoft),
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
                border: Border.all(color: widget.accent.withValues(alpha: 0.35)),
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

/// 편지 쓰기 → 전송 완료 안내를 하나의 짧은 바텀시트로 보여줍니다.
/// 답장은 다음날 아침에 도착하므로, 전송 즉시 답장을 보여주지 않고
/// "내일 아침에 도착해요"라는 안내만 표시합니다. 긴 화면 전환 없이,
/// 가볍게 열고 닫을 수 있도록 바텀시트 형태를 사용했습니다.
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
  State<_WriteHeartLetterSheet> createState() =>
      _WriteHeartLetterSheetState();
}

class _WriteHeartLetterSheetState extends State<_WriteHeartLetterSheet> {
  final _controller = TextEditingController();
  bool _sending = false;
  SpecialLetterEntry? _result;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    final entry = await SpecialLetterService.sendLetter(
      type: widget.type,
      letterText: text,
    );
    if (!mounted) return;
    setState(() {
      _result = entry;
      _sending = false;
    });
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
                        hintStyle: bodyFont(fontSize: 12.5, color: AppColors.inkSoft),
                        contentPadding: const EdgeInsets.all(14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
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
                              '편지 보내기',
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

/// 편지를 보낸 뒤, 답장은 내일 아침에 온다는 것을 알려주는 안내 카드.
/// 편지가 접혀 봉투에 담기는 듯한 느낌을 주기 위해 살짝 스케일
/// 애니메이션을 넣었습니다.
class _SentConfirmationView extends StatefulWidget {
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
  State<_SentConfirmationView> createState() => _SentConfirmationViewState();
}

class _SentConfirmationViewState extends State<_SentConfirmationView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
      child: FadeTransition(
        opacity: _controller,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: Colors.white.withValues(alpha: 0.75),
                border: Border.all(color: widget.accent.withValues(alpha: 0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('🌙', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(
                        '편지가 전해졌어요',
                        style: pathLabelFont(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: widget.accent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '답장은 내일 아침에 도착해요.\n"지난 편지 보기"에서 답장이 오면 열어볼 수 있어요.',
                    style: bodyFont(
                      fontSize: 13.5,
                      color: AppColors.moon,
                      height: 1.7,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onHistory,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: widget.accent,
                      side: BorderSide(color: widget.accent.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: Text(
                      '지난 편지 보기',
                      style: pathLabelFont(fontSize: 13, color: widget.accent),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: widget.onClose,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      '닫기',
                      style: pathLabelFont(fontSize: 13, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
