import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/shadow_cats_data.dart';
import '../models/shadow_bubble.dart';
import '../models/shadow_cat.dart';
import '../providers/app_state_provider.dart';
import '../providers/bubble_garden_provider.dart';
import '../services/bubble_memo_service.dart';
import '../theme.dart';
import '../utils/cat_palette.dart';
import '../widgets/garden_path_card.dart';

/// '오늘의 그림자 방울 터뜨리기' - 오늘 감정체크(편지쓰기)를 마친 뒤에만
/// 열리는 작은 의식(ritual) 화면.
///
/// 승부욕을 자극하는 요소(랭킹·타이머·정답/오답)는 전혀 없고, 방울을 하나씩
/// 천천히 터뜨리며 오늘 마주한 감정을 가만히 들여다보고 놓아주는 시간을
/// 보여줍니다. 포인트는 코스메틱 상점(옷·장식·가구)에서만 쓸 수 있습니다.
///
/// v2부터는 오늘 가장 무거웠던 감정 방울 하나에 한해, 터뜨리는 대신
/// 정원 땅으로 드래그해 '묻어둘' 수 있는 선택지가 조용히 나타납니다. 그림자
/// 작업의 핵심 개념(억압된 감정은 사라지지 않고 나중에 다시 떠오른다)을
/// 게임 메커니즘으로 표현한 것으로, 며칠 뒤 정원에 작은 새싹으로 다시
/// 떠오릅니다. 강제도 아니고, 하지 않아도 아무 페널티가 없습니다.
class BubbleGardenScreen extends StatefulWidget {
  const BubbleGardenScreen({super.key});

  @override
  State<BubbleGardenScreen> createState() => _BubbleGardenScreenState();
}

class _BubbleGardenScreenState extends State<BubbleGardenScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final app = context.read<AppStateProvider>();
      context.read<BubbleGardenProvider>().load(app.todaysLetters);
    });
  }

  /// 오늘 기록한 감정들 중, 해당 catId의 편지 내용을 짧게 잘라 반환합니다.
  /// (묻어두기 기록에 남길 '그때 남긴 마음' 조각)
  String _snippetFor(String catId) {
    final app = context.read<AppStateProvider>();
    final match = app.todaysLetters.where((e) => e.catId == catId);
    if (match.isEmpty) return '';
    final text = match.first.letterText.trim();
    if (text.length <= 60) return text;
    return '${text.substring(0, 60)}...';
  }

  @override
  Widget build(BuildContext context) {
    final garden = context.watch<BubbleGardenProvider>();

    if (garden.isLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: 80),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.blobLavenderAccent),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '오늘의 그림자\n방울 터뜨리기',
          textAlign: TextAlign.center,
          style: titleFont(fontSize: 24, color: AppColors.ink, height: 1.4),
        ),
        const SizedBox(height: 10),
        Text(
          '오늘 마주한 감정을 하나씩 가만히 들여다보고, 톡 터뜨려 놓아주세요',
          textAlign: TextAlign.center,
          style: bodyFont(
            fontSize: 12.5,
            color: AppColors.inkSoft,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 26),
        switch (garden.stage) {
          BubbleGardenStage.locked => const _LockedGuidance(),
          BubbleGardenStage.ready => _BubbleField(
            bubbles: garden.bubbles,
            heaviestIndex: garden.heaviestBubbleIndex,
            canBury: garden.canOfferBury,
            snippetFor: _snippetFor,
          ),
          BubbleGardenStage.allPopped => _CompletionCelebration(
            pointsEarned: garden.pointsEarnedThisSession,
            hasBuried: garden.bubbles.any((b) => b.buried),
            recalledMemoCatId: garden.recalledMemoCatId,
            recalledMemoLine: garden.recalledMemoLine,
          ),
        },
      ],
    );
  }
}

/// 오늘 아직 감정체크(편지쓰기)를 하지 않았을 때 보여주는 안내.
/// 이 기능이 감정체크를 대체하지 않는다는 것을 분명히 알리는 문구입니다.
class _LockedGuidance extends StatelessWidget {
  const _LockedGuidance();

  @override
  Widget build(BuildContext context) {
    return GlassBlob(
      accent: AppColors.blobLavenderAccent,
      background: AppColors.blobLavender,
      floatSeed: 41,
      child: Column(
        children: [
          const Text('🌫️', style: TextStyle(fontSize: 28)),
          const SizedBox(height: 12),
          Text(
            '오늘의 감정을 먼저 기록해주세요',
            textAlign: TextAlign.center,
            style: pathLabelFont(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '그림자 고양이에게 오늘의 마음을 들려주고 나면,\n그 감정이 담긴 방울들이 여기 조용히 피어나요',
            textAlign: TextAlign.center,
            style: bodyFont(
              fontSize: 12,
              color: AppColors.inkSoft,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}

/// 오늘 다 터뜨리지 못한 방울도 다음날로 이어지지 않는다는 걸 은근히
/// 암시하면서, 동시에 지금 이 방울밭이 오늘 하루만 존재한다는 걸 보여주는
/// 방울 필드.
class _BubbleField extends StatelessWidget {
  final List<ShadowBubble> bubbles;
  final int? heaviestIndex;
  final bool canBury;
  final String Function(String catId) snippetFor;
  const _BubbleField({
    required this.bubbles,
    required this.heaviestIndex,
    required this.canBury,
    required this.snippetFor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 18,
          runSpacing: 22,
          children: bubbles
              .map(
                (b) => _Bubble(
                  key: ValueKey(b.index),
                  bubble: b,
                  canBury: canBury && heaviestIndex == b.index,
                  letterSnippet: b.catId.isEmpty ? '' : snippetFor(b.catId),
                ),
              )
              .toList(),
        ),
        if (canBury) ...[const SizedBox(height: 30), const _BuryGround()],
      ],
    );
  }
}

/// 방울 하나. 항상 아주 천천히 위아래로 떠다니고, 터뜨리면 반짝이는 조각이
/// 흩어지며 그 감정의 그림자 고양이가 남기는 한마디가 잠깐 떠오릅니다.
///
/// [canBury]가 true인 방울(오늘 가장 무거웠던 감정, 다른 방울을 모두
/// 처리한 뒤에만 해당)은 평소처럼 탭해서 터뜨릴 수도 있고, 정원 땅으로
/// 드래그해 '묻어둘' 수도 있습니다. 어느 쪽도 강요되지 않습니다.
class _Bubble extends StatefulWidget {
  final ShadowBubble bubble;
  final bool canBury;
  final String letterSnippet;
  const _Bubble({
    super.key,
    required this.bubble,
    this.canBury = false,
    this.letterSnippet = '',
  });

  @override
  State<_Bubble> createState() => _BubbleState();
}

class _BubbleState extends State<_Bubble> with TickerProviderStateMixin {
  late final AnimationController _floatController;
  AnimationController? _popController;
  AnimationController? _buryController;
  bool _popped = false;
  bool _burying = false;
  bool _showLine = false;
  bool _showBuryLine = false;

  @override
  void initState() {
    super.initState();
    _popped = widget.bubble.popped;
    final rng = Random(widget.bubble.index * 13 + 5);
    _floatController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2600 + rng.nextInt(1800)),
    )..repeat(reverse: true, min: rng.nextDouble(), max: 1);
  }

  @override
  void dispose() {
    _floatController.dispose();
    _popController?.dispose();
    _buryController?.dispose();
    super.dispose();
  }

  Future<void> _onTap() async {
    if (_popped || _burying) return;
    final cat = widget.bubble.catId.isEmpty
        ? null
        : shadowCatById(widget.bubble.catId);
    setState(() {
      _popped = true;
      _showLine = true;
    });
    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    await context.read<BubbleGardenProvider>().popBubble(
      widget.bubble.index,
      reactionLineFor: cat?.comfortMessage,
    );
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _showLine = false);
    });
    if (mounted && cat != null) {
      // 방울이 터지는 순간의 여운이 지나간 뒤, 원한다면 이 고양이에게
      // 아주 짧은 한마디를 남길 수 있는 선택적 입력을 조용히 제안합니다.
      // (장문 편지를 쓰기엔 부담스러운 순간이므로 가볍게, 건너뛰기도 쉽게)
      await Future.delayed(const Duration(milliseconds: 550));
      if (mounted) _offerMemoSheet(cat);
    }
  }

  void _offerMemoSheet(ShadowCat cat) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BubbleMemoSheet(cat: cat),
    );
  }

  /// 방울이 정원 땅에 성공적으로 놓였을 때(=드래그가 완료되었을 때) 호출됩니다.
  /// 터뜨리는 대신, 작은 씨앗/빛 알갱이로 변하는 조용한 애니메이션을 보여준
  /// 뒤 실제로 묻어둡니다.
  Future<void> _onBuried() async {
    if (_popped || _burying) return;
    setState(() {
      _burying = true;
      _showBuryLine = true;
    });
    _buryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    await context.read<BubbleGardenProvider>().buryHeaviestBubble(
      letterSnippet: widget.letterSnippet,
    );
    Future.delayed(const Duration(milliseconds: 3200), () {
      if (mounted) setState(() => _showBuryLine = false);
    });
  }

  Widget _bubbleVisual({required Color accent, required Color background}) {
    final cat = widget.bubble.catId.isEmpty
        ? null
        : shadowCatById(widget.bubble.catId);
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.85),
            background.withValues(alpha: 0.75),
          ],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.4), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(cat?.emoji ?? '🫧', style: const TextStyle(fontSize: 24)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cat = widget.bubble.catId.isEmpty
        ? null
        : shadowCatById(widget.bubble.catId);
    final accent = widget.bubble.catId.isEmpty
        ? CatPalette.emptyDay
        : CatPalette.accentFor(widget.bubble.catId);
    final background = widget.bubble.catId.isEmpty
        ? CatPalette.emptyDay
        : CatPalette.backgroundFor(widget.bubble.catId);
    final hidden = _popped || widget.bubble.buried;

    Widget bubbleCore = GestureDetector(
      onTap: _onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutBack,
        scale: hidden || _burying ? 0.0 : 1.0,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 400),
          opacity: hidden || _burying ? 0.0 : 1.0,
          child: _bubbleVisual(accent: accent, background: background),
        ),
      ),
    );

    if (widget.canBury && !hidden) {
      bubbleCore = Draggable<int>(
        data: widget.bubble.index,
        onDragCompleted: _onBuried,
        feedback: Material(
          color: Colors.transparent,
          child: Opacity(
            opacity: 0.9,
            child: _bubbleVisual(accent: accent, background: background),
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.25,
          child: _bubbleVisual(accent: accent, background: background),
        ),
        child: bubbleCore,
      );
    }

    return SizedBox(
      width: 84,
      height: 108,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          AnimatedBuilder(
            animation: _floatController,
            builder: (context, child) {
              final t = _floatController.value;
              final dy = sin(t * pi) * 5;
              return Transform.translate(offset: Offset(0, dy), child: child);
            },
            child: bubbleCore,
          ),
          if (_popController != null)
            AnimatedBuilder(
              animation: _popController!,
              builder: (context, _) {
                final t = _popController!.value;
                if (t >= 1) return const SizedBox.shrink();
                return _SparkleBurst(progress: t, color: accent);
              },
            ),
          if (_buryController != null)
            AnimatedBuilder(
              animation: _buryController!,
              builder: (context, _) {
                final t = _buryController!.value;
                if (t >= 1) return const SizedBox.shrink();
                return _SeedTransform(progress: t, color: accent);
              },
            ),
          if (_showLine && cat != null)
            Positioned(
              top: -8,
              child: _ReactionBubble(text: cat.comfortMessage, accent: accent),
            ),
          if (_showBuryLine)
            Positioned(
              top: -8,
              child: _ReactionBubble(
                text: '이 마음은 지금 당장 다루지 않아도 괜찮아요',
                accent: accent,
                width: 168,
              ),
            ),
        ],
      ),
    );
  }
}

/// 방울을 터뜨린 뒤, 그 감정 고양이에게 아주 짧은 한마디를 남길 수 있는
/// 선택적 입력 시트.
///
/// 정식 "편지 쓰기" 기능과는 완전히 별개의 가벼운 기록입니다 - 지금은
/// 장문의 편지를 쓰기엔 부담스러운 순간일 수 있으므로, 20~50자 정도의
/// 짧은 한마디만 남기고 바로 닫을 수 있게 합니다. 남기지 않아도 전혀
/// 문제가 되지 않습니다.
class _BubbleMemoSheet extends StatefulWidget {
  final ShadowCat cat;
  const _BubbleMemoSheet({required this.cat});

  @override
  State<_BubbleMemoSheet> createState() => _BubbleMemoSheetState();
}

class _BubbleMemoSheetState extends State<_BubbleMemoSheet> {
  final _controller = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _saving) return;
    setState(() => _saving = true);
    await context.read<BubbleGardenProvider>().leaveBubbleMemo(
      catId: widget.cat.id,
      message: text,
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final accent = CatPalette.accentFor(widget.cat.id);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.all(14),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          decoration: BoxDecoration(
            color: AppColors.bg0.withValues(alpha: 0.98),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: accent.withValues(alpha: 0.28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(widget.cat.emoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${widget.cat.nameKr}에게 한마디 남기기',
                      style: pathLabelFont(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(
                      Icons.close,
                      color: AppColors.inkSoft,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '편지처럼 길게 쓰지 않아도 괜찮아요 · 짧은 한마디만 남겨보세요 (선택)',
                style: bodyFont(
                  fontSize: 11,
                  color: AppColors.inkSoft,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: Colors.white.withValues(alpha: 0.75),
                  border: Border.all(color: accent.withValues(alpha: 0.3)),
                ),
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  maxLength: BubbleMemoService.maxMessageLength,
                  maxLines: 2,
                  minLines: 1,
                  style: bodyFont(
                    fontSize: 13,
                    color: AppColors.ink,
                    height: 1.5,
                  ),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.all(14),
                    border: InputBorder.none,
                    counterStyle: bodyFont(
                      fontSize: 10,
                      color: AppColors.inkSoft,
                    ),
                    hintText: '예) 오늘은 유난히 힘들었어',
                    hintStyle: bodyFont(
                      fontSize: 12.5,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: Colors.white.withValues(alpha: 0.55),
                            border: Border.all(
                              color: AppColors.inkSoft.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            '남기지 않기',
                            style: pathLabelFont(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.inkSoft,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: _saving ? null : _save,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: accent.withValues(alpha: 0.88),
                          ),
                          child: Text(
                            '한마디 남기기',
                            style: pathLabelFont(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 방울 위에 잠깐 떠오르는 말풍선(고양이의 한마디 / 묻어두기 안내 공용).
class _ReactionBubble extends StatelessWidget {
  final String text;
  final Color accent;
  final double width;
  const _ReactionBubble({
    required this.text,
    required this.accent,
    this.width = 150,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: 1,
      duration: const Duration(milliseconds: 250),
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: bodyFont(fontSize: 10.5, color: AppColors.ink, height: 1.4),
        ),
      ),
    );
  }
}

/// 방울이 터질 때 흩어지는 작은 반짝임 조각들.
class _SparkleBurst extends StatelessWidget {
  final double progress; // 0..1
  final Color color;
  const _SparkleBurst({required this.progress, required this.color});

  @override
  Widget build(BuildContext context) {
    const count = 6;
    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: List.generate(count, (i) {
          final angle = (2 * pi / count) * i;
          final dist = progress * 34;
          final dx = cos(angle) * dist;
          final dy = sin(angle) * dist;
          return Transform.translate(
            offset: Offset(dx, dy),
            child: Opacity(
              opacity: (1 - progress).clamp(0.0, 1.0),
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.8),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// 방울을 정원 땅에 묻을 때, 터뜨림과는 다르게 조용히 작은 씨앗/빛 알갱이로
/// 변해가는 연출. 흩어지지 않고 한 점으로 모여들어 아래로 가만히 가라앉듯
/// 사라집니다.
class _SeedTransform extends StatelessWidget {
  final double progress; // 0..1
  final Color color;
  const _SeedTransform({required this.progress, required this.color});

  @override
  Widget build(BuildContext context) {
    final shrink = 1.0 - progress * 0.7;
    final sink = progress * 20;
    final glowOpacity = (sin(progress * pi)).clamp(0.0, 1.0);
    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.translate(
            offset: Offset(0, sink),
            child: Transform.scale(
              scale: shrink,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: glowOpacity),
                      color.withValues(alpha: glowOpacity * 0.7),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: glowOpacity * 0.35),
                      blurRadius: 12,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Opacity(
                  opacity: glowOpacity,
                  child: const Text('✨', style: TextStyle(fontSize: 12)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 오늘 가장 무거웠던 감정 방울에 한해서만 나타나는, 정원 땅으로 방울을
/// 옮겨두는 드롭 영역. 강요가 아니라 "그래도 된다"는 조용한 선택지입니다.
class _BuryGround extends StatelessWidget {
  const _BuryGround();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '이 마음만은, 터뜨리지 않고\n잠시 땅에 묻어두어도 괜찮아요',
          textAlign: TextAlign.center,
          style: bodyFont(
            fontSize: 11.5,
            color: AppColors.inkSoft,
            height: 1.7,
          ),
        ),
        const SizedBox(height: 14),
        DragTarget<int>(
          onWillAcceptWithDetails: (details) => true,
          onAcceptWithDetails: (details) {
            // 실제 묻어두기 처리는 방울(Draggable)의 onDragCompleted에서
            // 이루어집니다. 여기서는 드롭이 이 영역에 닿았음만 인정합니다.
          },
          builder: (context, candidateData, rejectedData) {
            final hovering = candidateData.isNotEmpty;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 140,
              height: 70,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: AppColors.blobMint.withValues(
                  alpha: hovering ? 0.85 : 0.55,
                ),
                border: Border.all(
                  color: AppColors.blobMintAccent.withValues(
                    alpha: hovering ? 0.6 : 0.32,
                  ),
                  width: hovering ? 1.6 : 1.2,
                ),
              ),
              child: Text(
                hovering ? '여기에 놓아주세요 🌱' : '🌿  방울을 여기로',
                textAlign: TextAlign.center,
                style: bodyFont(
                  fontSize: 11.5,
                  color: AppColors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        Text(
          '길게 눌러 드래그하면 묻어둘 수 있어요 · 하고 싶지 않다면 그냥 톡 터뜨려도 괜찮아요',
          textAlign: TextAlign.center,
          style: bodyFont(
            fontSize: 10.5,
            color: AppColors.inkSoft,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

/// 오늘의 방울을 모두 터뜨렸을 때 보여주는, 느리고 다정한 완료 연출.
/// "오늘의 그림자 정원이 정돈되었다"는 느낌을 전합니다.
class _CompletionCelebration extends StatefulWidget {
  final int pointsEarned;
  final bool hasBuried;
  final String? recalledMemoCatId;
  final String? recalledMemoLine;
  const _CompletionCelebration({
    required this.pointsEarned,
    this.hasBuried = false,
    this.recalledMemoCatId,
    this.recalledMemoLine,
  });

  @override
  State<_CompletionCelebration> createState() => _CompletionCelebrationState();
}

class _CompletionCelebrationState extends State<_CompletionCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: ScaleTransition(
        scale: Tween(begin: 0.9, end: 1.0).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
        ),
        child: GlassBlob(
          accent: AppColors.blobMintAccent,
          background: AppColors.blobMint,
          floatSeed: 51,
          child: Column(
            children: [
              const Text('🌿', style: TextStyle(fontSize: 30)),
              const SizedBox(height: 12),
              Text(
                '오늘의 그림자 정원이\n조용히 정돈되었어요',
                textAlign: TextAlign.center,
                style: pathLabelFont(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.pointsEarned > 0
                    ? '오늘 ${widget.pointsEarned}개의 방울을 놓아주며\n포인트를 조금 모았어요 · 상점에서 꾸미기에 써보세요'
                    : '오늘 방울들을 모두 놓아주었어요',
                textAlign: TextAlign.center,
                style: bodyFont(
                  fontSize: 11.5,
                  color: AppColors.inkSoft,
                  height: 1.7,
                ),
              ),
              if (widget.hasBuried) ...[
                const SizedBox(height: 12),
                Text(
                  '땅에 묻어둔 마음 하나는 며칠 뒤,\n정원 어딘가에 작은 새싹으로 조용히 다시 찾아올 거예요',
                  textAlign: TextAlign.center,
                  style: bodyFont(
                    fontSize: 11,
                    color: AppColors.inkSoft,
                    height: 1.7,
                  ),
                ),
              ],
              if (widget.recalledMemoLine != null) ...[
                const SizedBox(height: 16),
                _RecalledMemoLine(
                  catId: widget.recalledMemoCatId,
                  line: widget.recalledMemoLine!,
                ),
              ],
              const SizedBox(height: 12),
              Text(
                '내일 새로운 감정을 기록하면,\n다시 새로운 방울들이 피어날 거예요',
                textAlign: TextAlign.center,
                style: bodyFont(
                  fontSize: 11,
                  color: AppColors.inkSoft,
                  height: 1.7,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 오늘의 방울을 모두 놓아준 뒤, 그림자 고양이가 예전에 남긴 한마디를
/// 조용히 회상하며 건네는 대사창. 팝업이 아니라 완료 화면 안에 자연스럽게
/// 놓이는 대사 상자 형태로, "이 앱이 나를 기억하고 있다"는 인상을 줍니다.
///
/// 남긴 말이 부정적이었더라도, 이 대사창의 어조는 항상 따뜻하고 수용적인
/// 틀([BubbleMemoService.buildRecallLine])을 그대로 씁니다 - 내용은 있는
/// 그대로 인용하지만, 그 감정을 다시 부추기거나 판단하지 않습니다.
class _RecalledMemoLine extends StatelessWidget {
  final String? catId;
  final String line;
  const _RecalledMemoLine({required this.catId, required this.line});

  @override
  Widget build(BuildContext context) {
    final cat = catId == null || catId!.isEmpty ? null : shadowCatById(catId!);
    final accent = catId == null || catId!.isEmpty
        ? CatPalette.emptyDay
        : CatPalette.accentFor(catId!);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(cat?.emoji ?? '🐾', style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              line,
              style: bodyFont(fontSize: 12, color: AppColors.ink, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }
}
