import '../models/reply_style.dart';
import '../widgets/reply_style_picker.dart';
import '../services/draft_service.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/shadow_cat.dart';
import '../providers/app_state_provider.dart';
import '../providers/cat_care_provider.dart';
import '../services/storage_service.dart';
import '../theme.dart';
import '../widgets/animated_cat_art.dart';
import '../widgets/journal_box.dart';
import '../widgets/mood_picker.dart';
import '../widgets/meditation_picker.dart';
import '../widgets/garden_path_card.dart';
import '../widgets/share_cat_card.dart';
import '../data/solutions_data.dart';
import '../services/cat_care_service.dart';
import '../utils/meditation_care_mapping.dart';
import 'onboarding_flow_screen.dart';
import 'meditation_category_screen.dart';

/// 고양이 선택 이후의 전체 플로우: 사연 → 편지(보내는 즉시 저장+온도 +1도)
/// → 명상(완전히 선택사항, 실천하면 온도 +1도 추가) → 완료
class MeditationFlowScreen extends StatefulWidget {
  const MeditationFlowScreen({super.key});

  @override
  State<MeditationFlowScreen> createState() => _MeditationFlowScreenState();
}

class _MeditationFlowScreenState extends State<MeditationFlowScreen> {
  late final DraftTextController _letterController;
  @override
  void initState() {
    super.initState();
    _letterController = DraftTextController('letter_${context.read<AppStateProvider>().selectedCat!.id}');
  }
  String? _moodEmoji;
  FlowStage? _lastStage;

  @override
  void dispose() {
    _letterController.dispose();
    super.dispose();
  }

  /// 홈 셸이 SingleChildScrollView로 감싸져 있어, 긴 편지 화면 하단에서
  /// 보내기를 누르면 스크롤 위치가 남아 다음 단계가 "안 보이는" 것처럼
  /// 느껴질 수 있습니다. 단계가 바뀔 때 맨 위로 올립니다.
  void _scrollToTopIfNeeded(FlowStage stage) {
    if (_lastStage == stage) return;
    final shouldReset =
        stage == FlowStage.meditation ||
        stage == FlowStage.done ||
        stage == FlowStage.letter ||
        stage == FlowStage.story;
    _lastStage = stage;
    if (!shouldReset) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final controller = PrimaryScrollController.maybeOf(context);
      if (controller != null && controller.hasClients) {
        controller.jumpTo(0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppStateProvider>();
    final cat = app.selectedCat!;
    _scrollToTopIfNeeded(app.flowStage);

    switch (app.flowStage) {
      case FlowStage.selecting:
        return const SizedBox.shrink(); // 상위에서 처리
      case FlowStage.story:
        return _StoryStage(cat: cat);
      case FlowStage.letter:
        return _LetterStage(
          cat: cat,
          controller: _letterController,
          moodEmoji: _moodEmoji,
          onMoodChanged: (v) => setState(() => _moodEmoji = v),
        );
      case FlowStage.meditation:
        return _MeditationStage(cat: cat, moodEmoji: _moodEmoji);
      case FlowStage.done:
        return const _DoneStage();
    }
  }
}

class _StoryStage extends StatelessWidget {
  final ShadowCat cat;
  const _StoryStage({required this.cat});

  Future<void> _onWriteLetterPressed(BuildContext context) async {
    // 이 기기에서 아직 온보딩을 마치지 않았다면, 감정 몰입 순간에
    // 온보딩(편지→기기 계속→알림)으로 이어갑니다. 온보딩 완료 시
    // 의도적으로 홈으로 보내므로, 여기서 goToLetter()로 이어가지 않습니다.
    final onboardingDone = await StorageService.isOnboardingCompleted();
    if (!context.mounted) return;
    if (!onboardingDone) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => OnboardingFlowScreen(cat: cat)),
      );
      return;
    }
    context.read<AppStateProvider>().goToLetter();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          AnimatedCatArt(imageAsset: cat.imageAsset, size: 150),
          const SizedBox(height: 14),
          Text(cat.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(
            cat.nameKr,
            style: titleFont(fontSize: 22, color: AppColors.ink),
          ),
          Text(
            cat.nameEn,
            style: bodyFont(
              fontSize: 12,
              color: AppColors.inkSoft,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 20),
          GlassBlob(
            accent: AppColors.blobLavenderAccent,
            background: AppColors.blobLavender,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '이 고양이의 이야기',
                  style: pathLabelFont(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.blobLavenderAccent,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  cat.story,
                  style: bodyFont(
                    fontSize: 14.5,
                    color: AppColors.moon,
                    height: 1.75,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _onWriteLetterPressed(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blobPeachAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                elevation: 0,
              ),
              child: Text(
                '${cat.nameKr}에게 편지쓰기',
                style: pathLabelFont(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LetterStage extends StatefulWidget {
  final ShadowCat cat;
  final TextEditingController controller;
  final String? moodEmoji;
  final ValueChanged<String?> onMoodChanged;
  const _LetterStage({
    required this.cat,
    required this.controller,
    required this.moodEmoji,
    required this.onMoodChanged,
  });

  @override
  State<_LetterStage> createState() => _LetterStageState();
}

class _LetterStageState extends State<_LetterStage> {
  ReplyStyle _replyStyle = ReplyStyle.listen;
  bool _sending = false;

  Future<void> _onSend(BuildContext context) async {
    if (_sending) return;
    setState(() => _sending = true);
    final appState = context.read<AppStateProvider>();
    final care = context.read<CatCareProvider>();
    try {
      // 편지 저장이 완료되면 전송 성공. 보상 처리는 따로 진행합니다.
      // 사용자가 온도 값을 따로 입력하는 절차는 없습니다.
      await appState.sendLetter(
        widget.controller.text.trim(),
        moodEmoji: widget.moodEmoji,
        replyStyle: _replyStyle,
        onTemperatureBonus: () async {
          try {
            await care.applyLetterSentBonus();
          } finally {
            // 화면이 다음 단계로 넘어가도 기록 임무 처리는 이어갑니다.
            await care.journaling();
          }
        },
      );
      if (widget.controller is DraftTextController) {
        try { await (widget.controller as DraftTextController).discard(); }
        catch (_) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:Text('편지는 저장됐어요. 초안을 정리하지 못했지만 다시 보낼 필요는 없어요.')));
        }
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content:Text('저장 완료를 확인하지 못했어요. 내용은 유지돼요. 다시 눌러 저장을 확인해 주세요.')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  widget.cat.imageAsset,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.cat.nameKr,
                      style: pathLabelFont(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      '#${widget.cat.keyword}',
                      style: bodyFont(fontSize: 11.5, color: AppColors.inkSoft),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          JournalBox(
            question: '${widget.cat.nameKr}에게, 하고 싶은 말이 있나요?',
            hint: '짧아도 괜찮아요. 이건 나를 들여다보는 기록이에요.',
            controller: widget.controller,
          ),
          const SizedBox(height: 14),
          ReplyStylePicker(value:_replyStyle, enabled:!_sending, onChanged:(value)=>setState(()=>_replyStyle=value)),
          const SizedBox(height:14),
          MoodPicker(
            selectedEmoji: widget.moodEmoji,
            onChanged: widget.onMoodChanged,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _sending ? null : () => _onSend(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blobLavenderAccent,
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
                      style: pathLabelFont(fontSize: 16, color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 편지를 보낸 뒤 이어지는, 완전히 선택사항인 명상 단계.
/// 편지는 이미 저장되었고 답장도 예약되었으므로, 여기서는 아무것도
/// 하지 않고 건너뛰어도 전혀 문제가 없습니다. 실천하면 마음 온도가
/// 추가로 +1도 더 오릅니다.
class _MeditationStage extends StatefulWidget {
  final ShadowCat cat;
  final String? moodEmoji;
  const _MeditationStage({required this.cat, this.moodEmoji});

  @override
  State<_MeditationStage> createState() => _MeditationStageState();
}

class _MeditationStageState extends State<_MeditationStage> {
  String? _selectedKey;
  bool _busy = false;

  Future<void> _onDone(BuildContext context) async {
    if (_busy) return;
    setState(() => _busy = true);
    final appState = context.read<AppStateProvider>();
    final care = context.read<CatCareProvider>();
    try {
      await appState.completeMeditation(
        _selectedKey,
        onTemperatureBonus: care.applyMeditationBonus,
      );
      final careTask = careTaskForMeditationKey(_selectedKey);
      if (careTask == CareTask.breathing) {
        unawaited(() async {
          try {
            await care.breathing();
          } catch (_) {}
        }());
      } else if (careTask == CareTask.walking) {
        unawaited(() async {
          try {
            await care.walking();
          } catch (_) {}
        }());
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _onSkip(BuildContext context) {
    context.read<AppStateProvider>().skipMeditation();
  }

  @override
  Widget build(BuildContext context) {
    final categoryKey = widget.moodEmoji == null
        ? null
        : solutionCategoryKeyForMood(widget.moodEmoji!);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('💌', style: TextStyle(fontSize: 30)),
          const SizedBox(height: 6),
          Center(
            child: Text(
              '편지가 무사히 전달됐어요',
              style: pathLabelFont(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.blobPeachAccent,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              '마음 온도가 1도 올랐어요 · 아래는 선택사항이에요',
              style: bodyFont(fontSize: 12, color: AppColors.inkSoft),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 18),
          Center(child: AnimatedCatArt(imageAsset: widget.cat.imageAsset, size: 88)),
          const SizedBox(height: 8),
          Center(
            child: Text(
              '괜찮다면, ${widget.cat.nameKr}과 함께 잠시 마음을 다스려볼까요?',
              textAlign: TextAlign.center,
              style: pathLabelFont(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
          if (categoryKey != null) ...[
            const SizedBox(height: 16),
            _MoodMeditationCard(
              moodEmoji: widget.moodEmoji!,
              categoryKey: categoryKey,
            ),
          ],
          const SizedBox(height: 16),
          MeditationPicker(
            guideKeys: widget.cat.meditationKeys,
            onSelected: (key) => setState(() => _selectedKey = key),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_busy || _selectedKey == null)
                  ? null
                  : () => _onDone(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blobButterAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                elevation: 0,
              ),
              child: Text(
                _selectedKey == null
                    ? '실천할 명상을 골라주세요'
                    : '실천했어요, 마음 온도 1도 더 올리기',
                style: pathLabelFont(fontSize: 15, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: _busy ? null : () => _onSkip(context),
              child: Text(
                '괜찮아요, 여기까지 할게요',
                style: bodyFont(
                  fontSize: 13,
                  color: AppColors.inkSoft,
                ).copyWith(decoration: TextDecoration.underline),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 편지를 쓸 때 고른 오늘의 감정([MoodPicker])에 맞춰, 명상 카테고리로 바로
/// 이동할 수 있는 추천 카드. 고양이별 고정 명상(MeditationPicker)과 달리,
/// 그날그날 다른 감정에 맞춰 다른 카테고리를 추천해줍니다.
class _MoodMeditationCard extends StatelessWidget {
  final String moodEmoji;
  final String categoryKey;
  const _MoodMeditationCard({
    required this.moodEmoji,
    required this.categoryKey,
  });

  @override
  Widget build(BuildContext context) {
    final category = solutionCategoryByKey(categoryKey);
    if (category == null) return const SizedBox.shrink();
    return GlassBlob(
      accent: AppColors.blobRoseAccent,
      background: AppColors.blobRose,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          Text(moodEmoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '오늘 고른 감정에 맞는 명상',
                  style: pathLabelFont(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${category.icon} ${category.label} 카테고리를 추천해요',
                  style: bodyFont(fontSize: 11.5, color: AppColors.inkSoft),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MeditationCategoryScreen(
                    categoryKey: categoryKey,
                    moodEmoji: moodEmoji,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blobRoseAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              elevation: 0,
            ),
            child: Text(
              '보러가기',
              style: pathLabelFont(fontSize: 13, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoneStage extends StatelessWidget {
  const _DoneStage();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppStateProvider>();
    final care = context.watch<CatCareProvider>();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 50),
      child: Column(
        children: [
          const Text('🌙', style: TextStyle(fontSize: 46)),
          const SizedBox(height: 18),
          Text(
            '오늘의 편지가 조용히 기록되었어요',
            style: titleFont(fontSize: 19, color: AppColors.ink),
          ),
          const SizedBox(height: 8),
          Text(
            '고양이가 당신의 마음을 소중히 담아두었답니다',
            style: bodyFont(fontSize: 13, color: AppColors.inkSoft),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            '마음 온도 ${care.state.temperature} / 100°  ·  ${care.state.growthStageLabel}',
            style: bodyFont(
              fontSize: 12,
              color: AppColors.blobPeachAccent,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () {
              final cat = app.selectedCat;
              if (cat == null) return;
              showShareCatCard(
                context,
                cat: cat,
                meetingCount: app.meetingCountFor(cat.id),
                metCount: app.metCatCount,
              );
            },
            icon: Icon(
              Icons.ios_share_rounded,
              size: 16,
              color: AppColors.blobPeachAccent,
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.blobPeachAccent,
              side: BorderSide(
                color: AppColors.blobPeachAccent.withValues(alpha: 0.5),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            label: Text(
              '오늘 만난 고양이 공유하기',
              style: pathLabelFont(
                fontSize: 13,
                color: AppColors.blobPeachAccent,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => context.read<AppStateProvider>().restartFlow(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blobMintAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  '다른 고양이 만나기',
                  style: pathLabelFont(fontSize: 14, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
