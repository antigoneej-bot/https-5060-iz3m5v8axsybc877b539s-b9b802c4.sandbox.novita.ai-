import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/shadow_cat.dart';
import '../providers/app_state_provider.dart';
import '../services/storage_service.dart';
import '../theme.dart';
import '../widgets/animated_cat_art.dart';
import '../widgets/temp_box.dart';
import '../widgets/journal_box.dart';
import '../widgets/meditation_picker.dart';
import 'onboarding_flow_screen.dart';

/// 고양이 선택 이후의 전체 플로우: 사연 → 편지 → 명상 → 온도체크 → 완료
class MeditationFlowScreen extends StatefulWidget {
  const MeditationFlowScreen({super.key});

  @override
  State<MeditationFlowScreen> createState() => _MeditationFlowScreenState();
}

class _MeditationFlowScreenState extends State<MeditationFlowScreen> {
  final TextEditingController _letterController = TextEditingController();

  @override
  void dispose() {
    _letterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppStateProvider>();
    final cat = app.selectedCat!;

    switch (app.flowStage) {
      case FlowStage.selecting:
        return const SizedBox.shrink(); // 상위에서 처리
      case FlowStage.story:
        return _StoryStage(cat: cat);
      case FlowStage.letter:
        return _LetterStage(cat: cat, controller: _letterController);
      case FlowStage.meditation:
        return _MeditationStage(cat: cat, letterText: _letterController.text);
      case FlowStage.tempCheck:
        return _TempCheckStage(cat: cat, letterText: _letterController.text);
      case FlowStage.done:
        return const _DoneStage();
    }
  }
}

class _StoryStage extends StatelessWidget {
  final ShadowCat cat;
  const _StoryStage({required this.cat});

  Future<void> _onWriteLetterPressed(BuildContext context) async {
    // 이 기기에서 아직 온보딩(편지쓰기→가입유도→알림동의)을 마치지 않았다면,
    // 회원가입을 앞세우지 않고 감정적으로 몰입한 이 순간에 온보딩 플로우로 이어갑니다.
    final onboardingDone = await StorageService.isOnboardingCompleted();
    if (!context.mounted) return;
    if (!onboardingDone) {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => OnboardingFlowScreen(cat: cat)));
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
            style: serifFont(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: AppColors.ink,
            ),
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.bg1,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '이 고양이의 이야기',
                  style: serifFont(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.goldSoft,
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
          const SizedBox(height: 20),
          _TempBeforeSection(),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _onWriteLetterPressed(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                elevation: 0,
              ),
              child: Text(
                '${cat.nameKr}에게 편지쓰기',
                style: serifFont(fontSize: 15, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TempBeforeSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppStateProvider>();
    return TempBox(
      title: '지금 내 마음의 온도는? (편지 쓰기 전)',
      value: app.tempBefore,
      onChanged: (v) => context.read<AppStateProvider>().setTempBefore(v),
    );
  }
}

class _LetterStage extends StatelessWidget {
  final ShadowCat cat;
  final TextEditingController controller;
  const _LetterStage({required this.cat, required this.controller});

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
                  cat.imageAsset,
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
                      cat.nameKr,
                      style: serifFont(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      '#${cat.keyword}',
                      style: bodyFont(fontSize: 11.5, color: AppColors.inkSoft),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          JournalBox(
            question: '${cat.nameKr}에게 편지를 써보세요',
            hint: '이 고양이의 마음을 알아주고, 위로와 해결 방법을 함께 적어주세요',
            controller: controller,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () =>
                  context.read<AppStateProvider>().goToMeditation(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                elevation: 0,
              ),
              child: Text(
                '편지 다 썼어요, 명상하러 가기',
                style: serifFont(fontSize: 15, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MeditationStage extends StatelessWidget {
  final ShadowCat cat;
  final String letterText;
  const _MeditationStage({required this.cat, required this.letterText});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: AnimatedCatArt(imageAsset: cat.imageAsset, size: 92)),
          const SizedBox(height: 8),
          Center(
            child: Text(
              '${cat.nameKr}을(를) 위한 마음 다스리기',
              style: serifFont(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.ink,
              ),
            ),
          ),
          const SizedBox(height: 16),
          MeditationPicker(
            guideKeys: cat.meditationKeys,
            onSelected: (key) =>
                context.read<AppStateProvider>().setSelectedMeditationKey(key),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.read<AppStateProvider>().goToTempCheck(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                elevation: 0,
              ),
              child: Text(
                '실천했어요, 마음 온도 체크하기',
                style: serifFont(fontSize: 15, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TempCheckStage extends StatelessWidget {
  final ShadowCat cat;
  final String letterText;
  const _TempCheckStage({required this.cat, required this.letterText});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppStateProvider>();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '명상 · 움직임을 실천한 지금,\n마음의 온도는 어떻게 변했나요?',
            textAlign: TextAlign.center,
            style: serifFont(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.ink,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          TempBox(
            title: '지금 내 마음의 온도는? (실천 후)',
            value: app.tempAfter,
            onChanged: (v) => context.read<AppStateProvider>().setTempAfter(v),
          ),
          TempCompareBox(before: app.tempBefore, after: app.tempAfter),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                context.read<AppStateProvider>().saveLetterAndFinish(
                  letterText.trim(),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                elevation: 0,
              ),
              child: Text(
                '오늘의 편지 저장하기',
                style: serifFont(fontSize: 15, color: Colors.white),
              ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 50),
      child: Column(
        children: [
          Text(
            app.justLeveledUp ? '🎉' : '🌙',
            style: const TextStyle(fontSize: 46),
          ),
          const SizedBox(height: 18),
          if (app.justLeveledUp) ...[
            Text(
              '축하해요! 성장 ${app.growthLevel}단계로 올라갔어요',
              style: serifFont(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.ink,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '14일 안에 마음 온도 10도를 모두 채웠어요, 정말 대단해요',
              style: bodyFont(fontSize: 13, color: AppColors.inkSoft),
              textAlign: TextAlign.center,
            ),
          ] else ...[
            Text(
              '오늘의 편지가 조용히 기록되었어요',
              style: serifFont(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '고양이가 당신의 마음을 소중히 담아두었답니다',
              style: bodyFont(fontSize: 13, color: AppColors.inkSoft),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              '마음 온도 ${app.growthPoints} / ${AppStateProvider.growthGoalPoints}°  ·  도전 ${app.growthElapsedDays}일째',
              style: bodyFont(
                fontSize: 12,
                color: AppColors.goldSoft,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => context.read<AppStateProvider>().restartFlow(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
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
                  style: serifFont(fontSize: 13, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
