import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/promise_provider.dart';
import '../providers/cat_care_provider.dart';
import '../models/promise_entry.dart';
import '../theme.dart';
import '../widgets/garden_path_card.dart';

/// "오늘의 약속" - 오늘 나를 위해 지켜주고 싶은 일을 짧게 남기고,
/// 지킨 만큼 조용히 체크해나가는 화면.
/// 절대 '할 일 목록'처럼 보이지 않도록, 진행률·완료율 같은 표현 대신
/// '약속', '지키다', '곁', '웅크리다' 같은 정서적 어휘만 사용합니다.
/// 아침 감정 체크 직후 자연스럽게 이어지는 화면으로 쓰이며, 홈 산책로에서도
/// 언제든 다시 들를 수 있습니다.
class TodaysPromiseScreen extends StatefulWidget {
  const TodaysPromiseScreen({super.key});

  @override
  State<TodaysPromiseScreen> createState() => _TodaysPromiseScreenState();
}

class _TodaysPromiseScreenState extends State<TodaysPromiseScreen> {
  final _controller = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<PromiseProvider>().load();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    final ok = await context.read<PromiseProvider>().addPromise(text);
    if (ok) {
      _controller.clear();
    }
    if (mounted) setState(() => _submitting = false);
  }

  Future<void> _toggle(String id) async {
    final grantsBonus = await context.read<PromiseProvider>().toggleKept(id);
    if (grantsBonus && mounted) {
      await context.read<CatCareProvider>().applyPromiseBonus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final promise = context.watch<PromiseProvider>();

    if (promise.isLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: 80),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.blobMintAccent),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '오늘, 나를 위해\n지켜주고 싶은 약속이 있다면?',
          textAlign: TextAlign.center,
          style: titleFont(fontSize: 22, color: AppColors.ink, height: 1.4),
        ),
        const SizedBox(height: 10),
        Text(
          '거창하지 않아도 괜찮아요. 작은 약속 하나면 충분해요',
          textAlign: TextAlign.center,
          style: bodyFont(fontSize: 12.5, color: AppColors.inkSoft),
        ),
        const SizedBox(height: 26),
        if (promise.canAddMore)
          _PromiseInputBlob(
            controller: _controller,
            submitting: _submitting,
            onSubmit: _submit,
            remaining: 3 - promise.entries.length,
          )
        else
          _LimitReachedBlob(),
        const SizedBox(height: 22),
        if (promise.entries.isEmpty)
          _EmptyHintBlob()
        else
          ...promise.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PromiseTile(entry: e, onToggle: () => _toggle(e.id)),
            ),
          ),
        if (promise.lastReaction != null) ...[
          const SizedBox(height: 14),
          _ReactionBlob(text: promise.lastReaction!),
        ],
      ],
    );
  }
}

class _PromiseInputBlob extends StatelessWidget {
  final TextEditingController controller;
  final bool submitting;
  final VoidCallback onSubmit;
  final int remaining;
  const _PromiseInputBlob({
    required this.controller,
    required this.submitting,
    required this.onSubmit,
    required this.remaining,
  });

  @override
  Widget build(BuildContext context) {
    return GlassBlob(
      accent: AppColors.blobPeachAccent,
      background: AppColors.blobPeach,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            maxLength: 40,
            style: bodyFont(fontSize: 14, color: AppColors.moon),
            decoration: InputDecoration(
              hintText: '예: 아침 산책하기',
              hintStyle: bodyFont(fontSize: 13, color: AppColors.inkSoft),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.55),
              counterText: '',
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: (_) => onSubmit(),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  remaining <= 1
                      ? '오늘은 세 가지면 충분해요 · $remaining개 더 남았어요'
                      : '오늘은 세 가지면 충분해요',
                  style: bodyFont(fontSize: 11, color: AppColors.inkSoft),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: submitting ? null : onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blobPeachAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  '약속하기',
                  style: pathLabelFont(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LimitReachedBlob extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GlassBlob(
      accent: AppColors.blobButterAccent,
      background: AppColors.blobButter,
      child: Row(
        children: [
          const Text('🌷', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '오늘은 세 가지면 충분해요. 내일 또 새로운 약속을 남겨보세요',
              style: bodyFont(fontSize: 12.5, color: AppColors.inkSoft),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHintBlob extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Text(
          '아직 남긴 약속이 없어요\n위에 짧게 하나 적어볼까요?',
          textAlign: TextAlign.center,
          style: bodyFont(
            fontSize: 12.5,
            color: AppColors.inkSoft,
            height: 1.7,
          ),
        ),
      ),
    );
  }
}

class _PromiseTile extends StatelessWidget {
  final PromiseEntry entry;
  final VoidCallback onToggle;
  const _PromiseTile({required this.entry, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final kept = entry.kept;
    final accent = kept
        ? AppColors.blobMintAccent
        : AppColors.blobLavenderAccent;
    final background = kept ? AppColors.blobMint : AppColors.blobLavender;
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              background.withValues(alpha: kept ? 0.82 : 0.6),
              background.withValues(alpha: kept ? 0.55 : 0.36),
            ],
          ),
          border: Border.all(color: accent.withValues(alpha: 0.3), width: 1.1),
        ),
        child: Row(
          children: [
            Icon(
              kept
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: accent,
              size: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                entry.text,
                style:
                    pathLabelFont(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                      height: 1.3,
                    ).copyWith(
                      decoration: kept ? TextDecoration.lineThrough : null,
                      decorationColor: accent.withValues(alpha: 0.5),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReactionBlob extends StatelessWidget {
  final String text;
  const _ReactionBlob({required this.text});

  @override
  Widget build(BuildContext context) {
    return GlassBlob(
      accent: AppColors.blobMintAccent,
      background: AppColors.blobMint,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: pathLabelFont(
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
      ),
    );
  }
}
