import '../../theme.dart' show AppColors;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../l10n/emotion_insight_l10n.dart';
import '../l10n/emotion_l10n.dart';
import '../l10n/gen/app_localizations.dart';
import '../l10n/mind_challenge_l10n.dart';
import '../models/daily_mission.dart';
import '../models/emotion.dart';
import '../providers/garden_provider.dart';
import '../services/ad_service.dart';
import '../services/emotion_breathing_service.dart';
import '../services/emotion_insight_service.dart';
import '../services/mongi_mood_service.dart';
import '../services/sound_manager.dart';
import '../widgets/banner_ad_slot.dart';
import '../widgets/breathing_interstitial.dart';
import '../widgets/breathing_suggestion_sheet.dart';
import '../widgets/daily_checkin_sheet.dart';
import '../widgets/daily_mission_sheet.dart';
import '../widgets/floating_bob.dart';
import '../widgets/light_essence_shop_sheet.dart';
import '../widgets/mongi_care_sheet.dart';
import '../widgets/mongi_greeting_animation.dart';
import '../widgets/power_charm_shop_sheet.dart';
import 'breathing_library_screen.dart';
import 'endless_mode_screen.dart';
import 'garden_screen.dart';
import 'mental_health_support_screen.dart';
import 'mind_box_screen.dart';
import 'mind_challenge_detail_screen.dart';
import 'mind_challenge_list_screen.dart';
import 'mind_report_screen.dart';
import 'mongi_cheer_screen.dart';
import 'mongi_letter_screen.dart';
import 'onboarding_screen.dart';
import 'quiet_mode_screen.dart';
import 'runner_game_screen.dart';
import 'season_pass_screen.dart';
import 'settings_screen.dart';
import 'shop_screen.dart';
import 'weekly_report_screen.dart';

/// 첫 화면: "오늘 어떤 마음이 있었나요?"
/// - 이름(선택) 입력 + 감정 5개 중 1개 선택 -> 시작하기
/// 단순함을 위해 딱 이 한 화면에서 모든 준비가 끝난다.
class EmotionInputScreen extends StatefulWidget {
  const EmotionInputScreen({super.key});

  @override
  State<EmotionInputScreen> createState() => _EmotionInputScreenState();
}

class _EmotionInputScreenState extends State<EmotionInputScreen> {
  static const int _maxSelectable = 3;
  final TextEditingController _nameController = TextEditingController();
  final List<Emotion> _selected = [];

  // 1번(벤치마킹 제안: 감정 강도-게임 난이도 매칭) - 감정을 하나 이상
  // 고르면 나타나는 강도 슬라이더(1~5, 기본값 3=보통). 게임이 끝난 뒤
  // choice_screen.dart에서 남기는 "회고용" 강도와는 별개로, 이 값은 이번
  // 판을 시작하기도 전에 "지금 게임을 어떻게 진행할지"를 정하는 실시간
  // 난이도 조정 신호로 RunnerGame에 곧바로 전달된다.
  double _intensity = 3;

  @override
  void initState() {
    super.initState();
    // 화면에 처음 들어왔을 때(하루에 한 번), 몽이가 먼저 "오늘 기분은 어때?"를 묻는다.
    // 이미 오늘 체크인했다면 DailyCheckInSheet.showIfNeeded가 조용히 아무것도 하지 않는다.
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowCheckIn());
    // "몽이의 하루" - 오늘의 이스터에그 대사를 준비한다(하루 한 번만 새로 뽑힘).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<GardenProvider>().ensureTodayEasterEgg();
    });
    // 시즌 패스 카운트다운을 최신화하고(끝났으면 새 시즌으로 자동 전환).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<GardenProvider>().refreshSeasonPass();
    });
    // 일일 미션을 최신화한다(날짜가 바뀌었으면 오늘의 미션을 새로 시작).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<GardenProvider>().refreshDailyMissions();
    });
    // "몽이의 주간 편지" - 일주일에 한 번, 데이터가 충분히 쌓였다면 새 편지
    // 배지를 켠다(자동으로 화면을 열지는 않는다 - 유저가 직접 열어보게 함).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<GardenProvider>().maybeIssueMongiLetter();
    });
    // 홈 화면 하단 배너 광고를 위해 SDK를 미리 초기화해둔다(Android만, 웹은 no-op).
    AdService.instance.init();
    // 첫 화면에 들어온 순간부터 새소리+물소리가 은은하게 깔리기 시작한다.
    // 게임 플레이 중에도 계속 이어지고, "숨쉬기" 인터스티셜에서 BGM만 잠깐
    // 꺼졌다가도 이 앰비언트는 끊기지 않는다.
    SoundManager.instance.startAmbientNature();
  }

  Future<void> _maybeShowCheckIn() async {
    if (!mounted) return;
    final picked = await DailyCheckInSheet.showIfNeeded(context);
    if (picked != null && mounted) {
      setState(() {
        if (!_selected.any((s) => s.type == picked.type)) {
          _selected.add(picked);
        }
      });
    }
    // "1번 개선": 체크인 경험치로 방금 시즌 패스 "마음 마일스톤"에 도달했다면
    // 조용히 스낵바로 알려준다(게임 결과 화면과 달리 여기선 축하 카드를 낼
    // 만한 지점이 따로 없으므로, 부담 없는 톤으로만 짧게 전달).
    if (mounted) {
      final message = context.read<GardenProvider>().lastSeasonMilestoneMessage;
      if (message != null) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.seasonMilestoneSnackbar(message)),
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
    // 체크인 흐름이 끝난 뒤, 일주일에 한 번은 "이번 주 몽이의 관찰"을 조용히
    // 제안한다 (감정 데이터 되돌려주기 2단계). 데이터가 부족하면 표시하지 않는다.
    _maybeShowWeeklyReport();
  }

  void _maybeShowWeeklyReport() {
    if (!mounted) return;
    final garden = context.read<GardenProvider>();
    if (garden.hasShownWeeklyReportRecently) return;
    final report = EmotionInsightService.buildWeeklyReport(
      diaryEntries: garden.diaryEntries,
    );
    if (!report.hasEnoughData) return;
    garden.markWeeklyReportShown();
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const WeeklyReportScreen()));
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _start({bool practice = false}) async {
    if (_selected.isEmpty) return;
    if (!mounted) return;
    if (!practice) await _maybeOfferBreathing();
    if (!mounted) return;
    final name = _nameController.text.trim();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RunnerGameScreen(
          practice: practice,
          emotions: List<Emotion>.of(_selected),
          targetName: name.isEmpty ? null : name,
          emotionIntensity: _intensity.round(),
        ),
      ),
    );
    // 게임에서 돌아오면 선택 초기화 (다음 판을 위해)
    if (mounted) {
      setState(() {
        _selected.clear();
        _nameController.clear();
        _intensity = 3;
      });
    }
    // 종료 버튼으로 나온 경우 SoundManager.stopEverything()이 새소리/
    // 물소리 앰비언트까지 꺼놨을 수 있으니, 홈 화면으로 돌아온 시점에
    // 다시 살려준다(이미 재생 중이면 내부 가드로 조용히 무시됨).
    SoundManager.instance.startAmbientNature();
  }

  /// 2번(벤치마킹 제안: 감정 선택 -> 맞춤 호흡 자동 제안 흐름 연결) - 게임
  /// 화면으로 넘어가기 직전에, 방금 고른 감정에 어울리는 호흡 기법을 잠깐
  /// 제안한다. "바로 시작할게요"를 고르거나 시트를 닫으면(뒤로가기 포함)
  /// 아무 일도 없었던 것처럼 곧바로 게임으로 넘어가고, "숨 고르고 시작하기"를
  /// 고르면 기존 [BreathingInterstitial]을 그대로 재생한 뒤 게임으로 이어진다.
  /// 매판 강제로 뜨는 게 아니라 첫 화면에서 한 번만 제안하는 가벼운 흐름이라,
  /// 힐링 앱다운 "권유"의 톤을 지키려 했다.
  Future<void> _maybeOfferBreathing() async {
    if (!EmotionBreathingService.shouldSuggest(_selected)) return;
    final technique = EmotionBreathingService.suggestFor(_selected);
    final wantsBreathing = await BreathingSuggestionSheet.show(
      context,
      technique: technique,
    );
    if (!wantsBreathing || !mounted) return;
    final completed = await BreathingInterstitial.show(
      context,
      technique: technique,
    );
    if (!completed || !mounted) return;
    await context.read<GardenProvider>().completeBreathingTechnique(technique);
  }

  /// "무한의 계단"식 엔드리스 도전 모드로 진입한다. 목표 개수 없이 목숨이
  /// 다할 때까지 계속되며, "오늘 내 최고 기록"에 도전한다.
  /// 3번(정체성 재정렬): 입장에 "기력"을 요구하는 에너지 시스템을 제거해
  /// 언제든 무료로 바로 입장할 수 있다.
  Future<void> _startEndless() async {
    if (_selected.isEmpty) return;
    if (!mounted) return;
    await _maybeOfferBreathing();
    if (!mounted) return;
    final name = _nameController.text.trim();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EndlessModeScreen(
          emotions: List<Emotion>.of(_selected),
          targetName: name.isEmpty ? null : name,
          emotionIntensity: _intensity.round(),
        ),
      ),
    );
    // 종료 버튼으로 나온 경우 대비 - 스테이지 모드와 동일하게 앰비언트를
    // 다시 살려준다.
    SoundManager.instance.startAmbientNature();
    if (mounted) {
      setState(() {
        _selected.clear();
        _nameController.clear();
        _intensity = 3;
      });
    }
  }

  /// 3번(벤치마킹 제안: "고요 모드/활동 모드" 이원화) - 러너 게임을 전혀
  /// 거치지 않고, 감정을 고르는 것만으로 곧바로 [QuietModeScreen]의 저자극
  /// 흐름(보여주기 -> 숨 고르기 -> 한 줄 기록 -> 마음에 심기)으로 들어간다.
  /// 호흡 제안은 QuietModeScreen 안에서 자체적으로 다시 다루므로, 여기서는
  /// [_maybeOfferBreathing]을 호출하지 않는다(중복 제안 방지).
  Future<void> _startQuiet() async {
    if (_selected.isEmpty) return;
    if (!mounted) return;
    final name = _nameController.text.trim();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuietModeScreen(
          emotions: List<Emotion>.of(_selected),
          targetName: name.isEmpty ? null : name,
        ),
      ),
    );
    if (mounted) {
      setState(() {
        _selected.clear();
        _nameController.clear();
        _intensity = 3;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final garden = context.watch<GardenProvider>();
    final l10n = AppLocalizations.of(context);
    // 9번: 최근 2주간 무거운 마음이 유독 꾸준히 기록됐는지를 데이터로만
    // 조심스럽게 판단한다. 진단이 아니라 "필요하면 도움받을 곳이 있다"는
    // 사실을 놓치지 않게 하기 위한 신호일 뿐이라, 평소엔 절대 뜨지 않는다.
    final suggestSupport = EmotionInsightService.shouldSuggestSupport(
      diaryEntries: garden.diaryEntries,
    );
    // "복귀 케어" - 스트릭이 끊길 정도로 며칠 못 왔다가 다시 돌아왔을 때,
    // 벌점이나 다그침 없이 "그래도 반갑다"는 톤으로 맞아준다. 새 저장
    // 스키마 없이 기존 daysSinceLastFeed(GardenStorage)만으로 판단하고,
    // 오늘 한 번이라도 정원에 감정을 먹이면 곧바로 이 카드도 사라진다.
    final comebackCare = EmotionInsightService.buildComebackCareKind(
      daysSinceLastFeed: garden.daysSinceLastFeed,
    );

    // 홈 화면(앱의 뿌리 화면)에서 안드로이드 시스템 뒤로가기(백버튼/스와이프
    // 제스처)를 누르면 별다른 확인 없이 곧바로 앱이 완전히 종료된다 - 그런데
    // 이 경로는 게임 화면들의 _confirmExit()과 달리 SoundManager를 전혀
    // 건드리지 않아서, 앱이 화면에서 사라진 뒤에도 새소리/물소리 앰비언트가
    // 계속 재생되는 버그로 이어졌다(첫 화면 진입 시 항상 startAmbientNature가
    // 켜져 있으므로 특히 눈에 띔). 게임 화면과 동일한 패턴 - canPop: false로
    // 시스템 pop을 먼저 막고, 항상 확인 다이얼로그(_confirmAppExit)를 거쳐
    // "종료"를 고른 경우에만 소리를 완전히 멈추고 앱을 내려가게 통일한다.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _confirmAppExit();
      },
      child: Scaffold(
        body: Stack(
          children: [
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.bg0, AppColors.catSageBg],
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 64, 24, 96),
                child: Column(
                  children: [
                    // 9번: 데이터 패턴상 마음이 많이 무거워 보일 때만(아주
                    // 보수적인 기준) 조용히 뜨는 안내 카드. 홈 화면 맨 위에
                    // 놓아서 - 감정 선택보다도 먼저 - 놓치지 않게 한다.
                    if (suggestSupport) ...[
                      _buildSupportAlertCard(),
                      const SizedBox(height: 14),
                    ],
                    if (comebackCare != null) ...[
                      _buildComebackCareCard(comebackCare),
                      const SizedBox(height: 14),
                    ],
                    // Row 대신 Wrap을 써서, 뱃지 텍스트가 길어지는 상황(회복도가
                    // 두 자리·세 자리가 되거나 연속일수가 늘어날 때)에도 아이콘이
                    // 옆으로 밀려 겹쳐 보이거나 화면 밖으로 가려지지 않고, 자리가
                    // 부족하면 자연스럽게 다음 줄로 내려간다. 자주 쓰는 미션/편지
                    // 버튼은 아래 하단 네비게이션 바로 옮겨서 위쪽은 한결 여유 있게.
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildGardenBadge(garden),
                        _buildWeeklyReportButton(garden),
                        _buildBreathingButton(),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildTodayGoalBadge(garden),
                    const SizedBox(height: 12),
                    _buildMongiOfTheDay(garden),
                    const SizedBox(height: 8),
                    Text(
                      l10n.homeHeadline,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildNameField(),
                    const SizedBox(height: 18),
                    _buildHowToUseCard(),
                    const SizedBox(height: 18),
                    _buildEmotionGrid(),
                    if (_selected.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _buildIntensitySlider(),
                    ],
                    const SizedBox(height: 10),
                    _buildFriendlyCaption(),
                    const SizedBox(height: 18),
                    _buildStartButton(),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _selected.isEmpty
                          ? null
                          : () => _start(practice: true),
                      icon: const Icon(Icons.spa_outlined),
                      label: const Text('편안한 연습 · 천천히 달리기'),
                    ),
                    const Text(
                      '연습은 목숨·시간 부담 없이 즐겨요. 아이템을 쓰거나 단계·재화 보상을 받지 않아요.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11),
                    ),
                    const SizedBox(height: 10),
                    _buildEndlessButton(garden),
                    const SizedBox(height: 10),
                    _buildQuietModeButton(),
                    const SizedBox(height: 12),
                    Text(
                      l10n.homeSubCaption,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.inkSoft,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    // --- 여기까지가 "오늘의 감정 마주하기"라는 웰링 핵심 목적
                    // (체크인/호흡/마음성찰/정원성장)이다. 마음 챌린지와 응원
                    // 우편함도 재화/구매와 무관한 습관형 웰니스 기능이라 이
                    // 구분선 위, 감정 선택과 같은 영역에 둔다.
                    const SizedBox(height: 10),
                    _buildMindChallengeBanner(garden),
                    _buildCheerBanner(garden),
                    // 5번(벤치마킹 제안: 웰니스 핵심기능과 게임 수익모델 분리) -
                    // 여기서부터는 완전히 별개 영역인 "게임화·재화·상점"이다.
                    // 힐링 앱의 첫인상이 상점처럼 보이지 않도록, 화면을 열자마자
                    // 보이는 건 감정 선택/웰니스여야 한다는 원칙에 따라 이 모든
                    // 화폐·가챠·시즌패스·미션 요소는 라벨과 함께 맨 아래로
                    // 명확히 분리해 배치한다(우연히 섞이지 않도록 시각적 구분선
                    // + 소제목까지 명시).
                    const SizedBox(height: 24),
                    _buildDivider(),
                    const SizedBox(height: 14),
                    _buildMonetizationSectionLabel(),
                    const SizedBox(height: 12),
                    _buildCurrencyBar(garden),
                    const SizedBox(height: 14),
                    _buildSeasonPassBanner(garden),
                    _buildDailyMissionBanner(garden),
                    const SizedBox(height: 8),
                    const BannerAdSlot(),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
            _buildHelpButton(),
            _buildLanguageToggle(garden),
            _buildBottomNavBar(garden),
          ],
        ),
      ),
    );
  }

  /// 홈 화면(앱의 뿌리 화면)에서 시스템 뒤로가기를 눌렀을 때 뜨는 종료 확인
  /// 다이얼로그. "종료"를 고르면 게임 화면의 _confirmExit()과 동일하게
  /// [SoundManager.stopEverything]으로 새소리·물소리·BGM·발소리를 전부 멈춘
  /// 뒤에 [SystemNavigator.pop]으로 앱 자체를 완전히 내려간다(다음 화면으로
  /// 돌아가는 Navigator.pop이 아니라 - 여기가 이미 뿌리 화면이므로 앱을
  /// 통째로 종료해야 한다). "취소"를 고르거나 다이얼로그 밖을 눌러 닫으면
  /// 아무 일도 일어나지 않는다.
  Future<void> _confirmAppExit() async {
    final l10n = AppLocalizations.of(context);
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('마음냥 정원으로 돌아갈까요?'),
        content: const Text('몽이의 기록은 그대로 보관돼요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              '돌아가기',
              style: const TextStyle(
                color: Color(0xFFFF5A5A),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (shouldExit != true) return;
    // 새소리·물소리(자연 앰비언트)가 화면이 사라진 뒤에도 계속 재생되던
    // 버그의 핵심 수정 - 앱을 내려가기 전에 반드시 모든 소리를 멈춘다.
    await SoundManager.instance.stopEverything();
    // 웹 프리뷰에서는 SystemNavigator.pop()이 아무 효과가 없을 수 있으니
    // (탭을 닫을 수 없음) 예외를 그냥 무시한다 - 실제 안드로이드 기기에서는
    // 태스크에서 앱을 정상적으로 제거한다.
    if (mounted) Navigator.of(context, rootNavigator: true).pop();
  }

  /// 화면 어디서든(설정에 들어가지 않고도) 바로 눈에 보이는 언어 전환 버튼.
  /// 첫 화면 좌상단에 상시 노출되며, 탭할 때마다 한국어 <-> 영어를 즉시
  /// 전환한다(다른 언어를 고른 적이 없다면 기기 시스템 언어를 기준으로 판단).
  Widget _buildLanguageToggle(GardenProvider garden) {
    final isKorean = Localizations.localeOf(context).languageCode != 'en';
    return SafeArea(
      child: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.only(left: 12, top: 8),
          child: Material(
            color: Colors.white.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => garden.setLanguageCode(isKorean ? 'en' : 'ko'),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isKorean ? '🇺🇸' : '🇰🇷',
                      style: const TextStyle(fontSize: 15),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isKorean ? 'English' : '한국어',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 화면 맨 아래 고정된 "빠른 이동" 네비게이션 바.
  ///
  /// 이전에는 정원/미션/편지/리포트 버튼이 상단에 한 줄로 몰려 있어서, 뱃지
  /// 글자가 길어지면 버튼들이 서로 밀리며 가려지는 문제가 있었다. 자주 찾는
  /// 이동(정원·상점·편지·미션)은 항상 같은 자리에 있는 하단 바로 옮기고,
  /// 홈은 지금 있는 화면이라는 걸 강조 표시만 해준다(별도 이동 없음).
  /// 새 알림(미션 받기/편지 도착)이 있으면 작은 빨간 점으로 계속 보여준다.
  Widget _buildBottomNavBar(GardenProvider garden) {
    final l10n = AppLocalizations.of(context);
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          decoration: BoxDecoration(
            color: AppColors.bg1,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _navItem(
                emoji: '🏠',
                label: l10n.navHome,
                isActive: true,
                onTap: null,
              ),
              _navItem(
                emoji: '🌷',
                label: l10n.navGarden,
                onTap: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const GardenScreen())),
              ),
              _navItem(
                emoji: '🎁',
                label: l10n.navShop,
                onTap: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const ShopScreen())),
              ),
              _navItem(
                emoji: '💌',
                label: l10n.navLetter,
                showDot: garden.hasUnreadMongiLetter,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MongiLetterScreen()),
                ),
              ),
              _navItem(
                emoji: '📋',
                label: l10n.navMission,
                showDot: garden.hasClaimableDailyMission,
                onTap: () => showDailyMissionSheet(context),
              ),
              _navItem(
                emoji: '⚙️',
                label: l10n.navSettings,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required String emoji,
    required String label,
    VoidCallback? onTap,
    bool isActive = false,
    bool showDot = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.catSageBg : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Text(emoji, style: const TextStyle(fontSize: 18)),
                ),
                if (showDot)
                  Positioned(
                    top: -1,
                    right: -1,
                    child: Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        color: AppColors.roseStrong,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                color: isActive
                    ? AppColors.titlePastelGreen
                    : AppColors.inkSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// "몽이의 하루" - 다마고치 요소. 최근 3일간의 감정 데이터에 따라 몽이가
  /// 다른 표정(idle/jump/cry)으로 나타나고, 그 아래 말풍선에 오늘의 상태
  /// 설명 + 하루 한 번 뽑히는 랜덤 이스터에그 대사를 함께 보여준다.
  /// 새 이미지를 그리지 않고 기존 표정 에셋만 재사용한다.
  Widget _buildMongiOfTheDay(GardenProvider garden) {
    final l10n = AppLocalizations.of(context);
    final mood = garden.todayMood;
    final description = switch (mood.mood) {
      MongiMoodKind.waiting => l10n.homeMongiMoodWaiting,
      MongiMoodKind.joyful => l10n.homeMongiMoodJoyful,
      MongiMoodKind.heavy => l10n.homeMongiMoodHeavy,
      MongiMoodKind.calm => l10n.homeMongiMoodCalm,
    };
    final easterEggIndex = garden.todayEasterEggIndex;
    final easterEgg = easterEggIndex == null
        ? null
        : _easterEggText(l10n, easterEggIndex);
    return Column(
      children: [
        MongiGreetingAnimation(imageAsset: mood.imageAsset, height: 150),
        const SizedBox(height: 10),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🐱', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.inkSoft,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
              if (easterEgg != null) ...[
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('✨', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        easterEgg,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.inkSoft,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// [MongiMoodService.randomEasterEggIndex]가 고른 인덱스(0 ~
  /// [MongiMoodService.easterEggCount] - 1)를 실제 번역 문구로 바꾼다.
  String _easterEggText(AppLocalizations l10n, int index) {
    switch (index) {
      case 0:
        return l10n.homeEasterEgg0;
      case 1:
        return l10n.homeEasterEgg1;
      case 2:
        return l10n.homeEasterEgg2;
      case 3:
        return l10n.homeEasterEgg3;
      case 4:
        return l10n.homeEasterEgg4;
      case 5:
        return l10n.homeEasterEgg5;
      case 6:
        return l10n.homeEasterEgg6;
      case 7:
        return l10n.homeEasterEgg7;
      case 8:
        return l10n.homeEasterEgg8;
      case 9:
        return l10n.homeEasterEgg9;
      case 10:
        return l10n.homeEasterEgg10;
      default:
        return l10n.homeEasterEgg11;
    }
  }

  /// 9번: "요즘 마음이 많이 무거웠나 봐요" - 마음 리포트에서만 보이던
  /// 정신건강 안내 진입점을, 데이터 패턴이 감지될 때는 홈 화면에도 똑같이
  /// 조용히 노출한다. 굳이 리포트까지 들어가야만 발견되는 안내라면 정작
  /// 필요한 순간에 놓칠 수 있기 때문이다. 절대 팝업이나 강제 이동 없이,
  /// 스크롤하다 보이는 카드 한 장으로만 존재한다.
  Widget _buildSupportAlertCard() {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7A6C8C), Color(0xFF5B9BD5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const MentalHealthSupportScreen(),
            ),
          );
        },
        child: Row(
          children: [
            const Text('🤍', style: TextStyle(fontSize: 26)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.homeSupportAlertTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    l10n.homeSupportAlertBody,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    );
  }

  /// "복귀 케어" - 스트릭이 끊길 만큼 며칠 못 왔다가 다시 돌아온 순간을
  /// 조용히 반겨주는 카드. 정신건강 안내 카드(_buildSupportAlertCard)와
  /// 같은 위치(최상단)에 노출되지만, 톤/색은 완전히 다정한 쪽으로 - 몽이의
  /// 성장나무가 "시들었다"는 카드와 겹쳐 보이지 않도록 초록 계열 대신
  /// 따뜻한 살구색 그라데이션을 쓴다. 탭 동작은 없다(그냥 읽고 지나가는
  /// 인사말 - 굳이 어디로 이동시킬 필요가 없다).
  Widget _buildComebackCareCard(ComebackCareResult result) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFE0B2), Color(0xFFFFC98B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text('🐾', style: TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comebackCareTitle(l10n, result),
                  style: const TextStyle(
                    color: Color(0xFF6B4A1F),
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  comebackCareBody(l10n, result),
                  style: const TextStyle(
                    color: Color(0xFF6B4A1F),
                    fontSize: 11.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpButton() {
    return SafeArea(
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.only(right: 12, top: 8),
          child: Material(
            color: Colors.white.withValues(alpha: 0.82),
            shape: const CircleBorder(),
            child: IconButton(
              icon: const Icon(Icons.help_outline, color: AppColors.inkSoft),
              tooltip: AppLocalizations.of(context).homeHelpTooltip,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const OnboardingScreen(isReplay: true),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGardenBadge(GardenProvider garden) {
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const GardenScreen()));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🌱', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              l10n.homeGardenBadgeProgress((garden.progress * 100).round()),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              l10n.homeGardenBadgeStage(garden.stage),
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.inkSoft,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (garden.streakDays > 0) ...[
              const SizedBox(width: 10),
              Text(
                l10n.homeGardenBadgeStreak(garden.streakDays),
                style: const TextStyle(fontSize: 13, color: AppColors.inkSoft),
              ),
            ],
            // 감정 체크인 연속일수(checkInStreak)는 하루에 한 번뿐인 체크인
            // 팝업이 닫히고 나면 다시는 볼 수 없었다. 스트릭 가시성 강화를 위해
            // 홈 배지에도 항상 보이도록 함께 노출한다(벤치마킹 제안 #4).
            if (garden.checkInStreak > 0) ...[
              const SizedBox(width: 10),
              Text(
                l10n.homeGardenBadgeCheckInStreak(garden.checkInStreak),
                style: const TextStyle(fontSize: 13, color: AppColors.inkSoft),
              ),
            ],
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, size: 16, color: AppColors.inkSoft),
          ],
        ),
      ),
    );
  }

  /// 이중 화폐(빛의 정수/별조각)를 한 줄로 보여주는 상태 바.
  /// 5번(웰니스/게임 수익모델 분리) - 충전·가챠·파워부적·돌봄 등 결제/재화
  /// 관련 진입점을 전부 모아 놓은 이 바는 이제 "게임 수익모델" 영역
  /// (구분선 아래, _buildMonetizationSectionLabel 다음)에서만 노출된다.
  /// 감정 선택 위쪽에서는 더 이상 보이지 않는다.
  Widget _buildCurrencyBar(GardenProvider garden) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 6,
        children: [
          _currencyChip(
            emoji: '💡',
            label: '${garden.lightEssence}',
            background: const Color(0xFFFFF3D6),
            textColor: const Color(0xFF8A6D1F),
          ),
          GestureDetector(
            onTap: () => LightEssenceShopSheet.show(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE9A3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFC93C), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, size: 13, color: Color(0xFF8A6D1F)),
                  const SizedBox(width: 2),
                  Text(
                    l10n.homeChargeButton,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                      color: Color(0xFF8A6D1F),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _currencyChip(
            emoji: '⭐',
            label: '${garden.starShard}',
            background: const Color(0xFFEAF0FF),
            textColor: const Color(0xFF3A5BA0),
          ),
          GestureDetector(
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const MindBoxScreen()));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE0A3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🎁', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 5),
                  Text(
                    l10n.homeMindBoxChip,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                      color: Color(0xFF8A5A1F),
                    ),
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: () => PowerCharmShopSheet.show(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFC93C),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('⚡', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 5),
                  Text(
                    l10n.homePowerCharmChip(garden.powerCharmCount),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: () => MongiCareSheet.show(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFB8E0C0),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🍚', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 5),
                  Text(
                    l10n.homeMongiCareChip,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                      color: Color(0xFF3D5A3D),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _currencyChip({
    required String emoji,
    required String label,
    required Color background,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  /// 5번(웰니스 핵심기능과 게임 수익모델 분리) - 위쪽 웰니스 영역(체크인/
  /// 호흡/마음성찰/정원성장/마음챌린지/응원우편함)과 아래쪽 게임 수익모델
  /// 영역(화폐/가챠/시즌패스/미션 배너)을 시각적으로 분리해주는 구분선.
  /// 이 선 아래는 첫눈에 다 보이지 않아도 괜찮은 "덤"이라는 걸 은근히
  /// 알려준다.
  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: const Color(0xFFE4D9CF))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            '🌱',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.inkSoft.withValues(alpha: 0.6),
            ),
          ),
        ),
        Expanded(child: Container(height: 1, color: const Color(0xFFE4D9CF))),
      ],
    );
  }

  /// 5번(웰니스 핵심기능과 게임 수익모델 분리) - 구분선 아래부터는
  /// "재화·상점·시즌패스" 영역이라는 걸 문구로도 명확히 알려주는 작은 소제목.
  /// 위쪽(체크인/호흡/마음성찰/정원성장/마음챌린지/응원우편함)과 섞여
  /// 보이지 않도록, 여기서부터 톤이 바뀐다는 걸 시각적으로도 분명히 한다.
  Widget _buildMonetizationSectionLabel() {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎁', style: TextStyle(fontSize: 13)),
          const SizedBox(width: 6),
          Text(
            l10n.homeMonetizationSectionLabel,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.inkSoft,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  /// 가든 배지 아래에 붙는 "오늘의 목표" 한 줄 배지. 매 판이 완결로 느껴지는
  /// 대신, 홈 화면에서부터 "아직 안 끝난 것"을 살짝 보여줘서 재방문 욕구를
  /// 자극한다(오픈 루프). 보여줄 만한 게 없으면 아무 것도 렌더링하지 않는다.
  Widget _buildTodayGoalBadge(GardenProvider garden) {
    final hint = EmotionInsightService.buildTodayGoalBadge(
      diaryEntries: garden.diaryEntries,
      pointsToNextTreeStage: garden.pointsToNextTreeStage,
    );
    if (hint == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3D6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          AppLocalizations.of(context).homeTodayGoalBadge(hint),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF8A6D1F),
          ),
        ),
      ),
    );
  }

  /// 시즌 패스("몽이의 마음여정") 진입 배너. 항상 노출되며, 지금 수령할 수
  /// 있는 보상이 있으면 빨간 뱃지로 알려준다(오픈 루프 유도). 5번(웰니스/
  /// 게임 수익모델 분리): 게임화·재화 성격이 뚜렷한 기능이라 구분선 아래
  /// "게임 수익모델" 영역에서만 노출된다.
  Widget _buildSeasonPassBanner(GardenProvider garden) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: GestureDetector(
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const SeasonPassScreen()));
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE6D6FF), Color(0xFFD3B8FF)],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              const Text('🌱', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.homeSeasonBannerTitle(
                        garden.seasonNumber,
                        garden.seasonLevel,
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                        color: Color(0xFF5A3E8C),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.homeSeasonBannerSubtitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF7B5CB8),
                      ),
                    ),
                  ],
                ),
              ),
              if (garden.hasClaimableSeasonReward)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.roseStrong,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    l10n.commonClaim,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 10.5,
                    ),
                  ),
                ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF7B5CB8),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 일일 미션 진입 배너. 항상 노출되며, 지금 수령할 수 있는 보상이 있으면
  /// 빨간 뱃지로 알려준다(시즌 패스 배너와 동일한 톤/구조). 5번(웰니스/
  /// 게임 수익모델 분리): 시즌 패스 배너와 함께 구분선 아래 "게임
  /// 수익모델" 영역에서만 노출된다.
  Widget _buildDailyMissionBanner(GardenProvider garden) {
    final l10n = AppLocalizations.of(context);
    final claimableCount = DailyMission.all
        .where(
          (m) =>
              garden.isDailyMissionAchieved(m) &&
              !garden.isDailyMissionClaimed(m),
        )
        .length;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: GestureDetector(
        onTap: () => showDailyMissionSheet(context),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFD9E4), Color(0xFFFFC0D6)],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              const Text('📋', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.homeDailyMissionTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                        color: Color(0xFF9A3A5C),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.homeDailyMissionSubtitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFB1466E),
                      ),
                    ),
                  ],
                ),
              ),
              if (claimableCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.roseStrong,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    l10n.homeDailyMissionClaimCount(claimableCount),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 10.5,
                    ),
                  ),
                ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFFB1466E),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// "마음 챌린지" 진입 배너 - Finch "Goal Journeys" 벤치마킹. 진행 중인
  /// 챌린지가 있으면 며칠차인지 보여주고, 없으면 새로 시작하자는 안내를
  /// 보여준다. 탭하면 진행 중이면 상세 화면으로, 없으면 목록 화면으로 간다.
  /// 5번(웰니스/게임 수익모델 분리): 재화·구매와 무관한 습관형 웰니스
  /// 기능이라 시즌패스/미션 배너와 분리해 구분선 위(웰니스 영역)에 둔다.
  Widget _buildMindChallengeBanner(GardenProvider garden) {
    final l10n = AppLocalizations.of(context);
    final activeDef = garden.activeMindChallenge;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => activeDef != null
                  ? const MindChallengeDetailScreen()
                  : const MindChallengeListScreen(),
            ),
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFDCEFD2), Color(0xFFC3E4B4)],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Text(
                activeDef?.emoji ?? '🌿',
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activeDef != null
                          ? l10n.mindChallengeHomeBannerTitleActive(
                              activeDef.emoji,
                              mindChallengeTitle(l10n, activeDef),
                              garden.mindChallengeDaysDone.clamp(
                                0,
                                activeDef.durationDays,
                              ),
                              activeDef.durationDays,
                            )
                          : l10n.mindChallengeHomeBannerTitleInactive,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                        color: Color(0xFF3A5A34),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      activeDef != null
                          ? l10n.mindChallengeHomeBannerSubtitleActive
                          : l10n.mindChallengeHomeBannerSubtitleInactive,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4C7A44),
                      ),
                    ),
                  ],
                ),
              ),
              if (activeDef != null && garden.canCompleteMindChallenge)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.roseStrong,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    l10n.commonClaim,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 10.5,
                    ),
                  ),
                ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF4C7A44),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// "몽이의 응원 우편함" 진입 배너 - Finch "Good Vibes"를 벤치마킹한 경량
  /// 소셜 기능(완전 로컬판). 오늘 아직 받지 않은 응원이 있으면 "받기" 뱃지를
  /// 보여준다. 5번(웰니스/게임 수익모델 분리): 결제와 무관한 웰니스
  /// 기능이라 구분선 위(웰니스 영역)에 둔다.
  Widget _buildCheerBanner(GardenProvider garden) {
    final l10n = AppLocalizations.of(context);
    final hasNew = !garden.hasReceivedCheerToday;
    final bothDone = garden.hasSentCheerToday && garden.hasReceivedCheerToday;
    final subtitle = bothDone
        ? l10n.homeCheerBannerSubtitleBothDone
        : hasNew
        ? l10n.homeCheerBannerSubtitleHasNew
        : l10n.homeCheerBannerSubtitleDefault;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: GestureDetector(
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const MongiCheerScreen()));
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFE3EC), Color(0xFFFFC9DB)],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              const Text('💌', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.homeCheerBannerTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                        color: Color(0xFF9A3A5C),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFB1466E),
                      ),
                    ),
                  ],
                ),
              ),
              if (hasNew)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.roseStrong,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    l10n.homeCheerBannerNewBadge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 10.5,
                    ),
                  ),
                ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFFB1466E),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// "마음 리포트"(주간/월간/도감/다이어리 통합 대시보드)를 언제든 다시 볼
  /// 수 있는 작은 배지 버튼. 자동 노출(주간 리포트 자동 팝업)과 별개로,
  /// 원할 때마다 눌러서 "내 감정을 어떻게 써왔는지" 한 번에 볼 수 있게 열어둔다.
  Widget _buildWeeklyReportButton(GardenProvider garden) {
    return GestureDetector(
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const MindReportScreen()));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('💗', style: TextStyle(fontSize: 15)),
            const SizedBox(width: 4),
            Text(
              AppLocalizations.of(context).homeMindReportButton,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// "즉시 적용" 개선안 - 원래는 게임 종료 후에만 자동으로 뜨던 심호흡을
  /// 홈 배지 줄에서 바로 시작할 수 있게 한 버튼이었다. 5번(벤치마킹 제안):
  /// 이제는 기본 호흡 하나만 바로 재생하는 대신, "몽이의 숨결 도감"(여러
  /// 호흡 기법을 골라 재생하는 라이브러리 화면)으로 이동한다.
  Widget _buildBreathingButton() {
    return GestureDetector(
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const BreathingLibraryScreen())),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🌬️', style: TextStyle(fontSize: 15)),
            const SizedBox(width: 4),
            Text(
              AppLocalizations.of(context).homeBreathingButton,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return TextField(
      controller: _nameController,
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        hintText: AppLocalizations.of(context).homeNameFieldHint,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.85),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  /// "감정 캐릭터를 어떻게 쓰는지 모르겠다"는 혼란을 줄이기 위한 짧은 사용법 카드.
  /// 아래 감정 몬스터 카드를 탭해서 고르면 -> 시작 버튼으로 게임에 들어가고 ->
  /// 몽이가 화면 속에서 그 감정 몬스터에 닿으면 자동으로 먹는다는 흐름을 한눈에 보여준다.
  Widget _buildHowToUseCard() {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            l10n.homeHowToTitle,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _howToStep('1', '👇', l10n.homeHowToStep1),
              _howToArrow(),
              _howToStep('2', '🐾', l10n.homeHowToStep2),
              _howToArrow(),
              _howToStep('3', '😋', l10n.homeHowToStep3),
              _howToArrow(),
              _howToStep('4', '🌱', l10n.homeHowToStep4),
            ],
          ),
        ],
      ),
    );
  }

  Widget _howToStep(String number, String emoji, String text) {
    return Expanded(
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E9),
                  shape: BoxShape.circle,
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 18)),
              ),
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  width: 16,
                  height: 16,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.roseStrong,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    number,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 9.5,
              color: AppColors.inkSoft,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  Widget _howToArrow() => const Padding(
    padding: EdgeInsets.only(bottom: 24),
    child: Icon(Icons.chevron_right, size: 16, color: Color(0xFFD9CFC4)),
  );

  /// 감정 선택 그리드 - Emotion.all에 등록된 모든 감정을 처음부터
  /// 자유롭게 고를 수 있다 (최대 3개).
  /// (어떤 감정이든 잠금 없이 있는 그대로 마주하는 것이 이 앱의 핵심 가치)
  Widget _buildEmotionGrid() {
    final emotions = Emotion.all;
    return Wrap(
      spacing: 16,
      runSpacing: 22,
      alignment: WrapAlignment.center,
      children: List.generate(emotions.length, (index) {
        final e = emotions[index];
        final isSelected = _selected.any((s) => s.type == e.type);
        // 카드마다 위상을 다르게 줘서 다 같이 딱딱 맞춰 움직이지 않고
        // 물결치듯 제각각 둥둥 떠다니게 한다. 선택된 카드는 살짝 더 크게
        // 떠다녀서 "지금 이 감정을 골랐어요"가 눈에 더 잘 띈다.
        final phase = (index * 0.37) % 1.0;
        return FloatingBob(
          phase: phase,
          amplitude: isSelected ? 8 : 5,
          duration: Duration(milliseconds: 2400 + (index % 5) * 220),
          child: _buildEmotionCard(e, isSelected),
        );
      }),
    );
  }

  /// 이미 고른 감정을 다시 탭하면 선택이 해제되고, 아직 안 골랐다면 최대 3개까지 더할 수 있다.
  void _toggleEmotion(Emotion e) {
    setState(() {
      final idx = _selected.indexWhere((s) => s.type == e.type);
      if (idx >= 0) {
        _selected.removeAt(idx);
        return;
      }
      if (_selected.length >= _maxSelectable) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).homeMaxSelectSnackbar),
            duration: const Duration(seconds: 1),
          ),
        );
        return;
      }
      _selected.add(e);
    });
  }

  /// 화사하고 귀여운 감정 카드 한 장.
  /// - 감정 색상이 은은하게 번지는 그라데이션 배경
  /// - 선택 시 살짝 커지며 반짝이는 테두리/그림자
  /// - 모서리에 몽이가 살짝 고개를 내미는 스티커 장식
  Widget _buildEmotionCard(Emotion e, bool isSelected) {
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      onTap: () => _toggleEmotion(e),
      child: AnimatedScale(
        scale: isSelected ? 1.06 : 1.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutBack,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 100,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isSelected
                      ? [
                          e.color.withValues(alpha: 0.32),
                          e.color.withValues(alpha: 0.14),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.95),
                          e.color.withValues(alpha: 0.10),
                        ],
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isSelected ? e.color : Colors.white,
                  width: isSelected ? 2.5 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: e.color.withValues(alpha: isSelected ? 0.40 : 0.16),
                    blurRadius: isSelected ? 16 : 8,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                    alignment: Alignment.center,
                    child: Image.asset(e.monsterAsset, height: 46),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? e.color
                          : Colors.white.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      emotionLabel(l10n, e.type),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                        color: isSelected ? Colors.white : AppColors.inkSoft,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: -10,
              right: -8,
              child: Transform.rotate(
                angle: 0.25,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: isSelected ? 1.0 : 0.65,
                  child: Image.asset(
                    'assets/mongi/images/cat_peek_sticker.png',
                    width: isSelected ? 32 : 26,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 1번(벤치마킹 제안: 감정 강도-게임 난이도 매칭) - 감정을 하나 이상
  /// 고르면 나타나는 강도 슬라이더. "이 마음, 지금 얼마나 강한가요?"를
  /// 미리 물어서, 격한 부정 감정일 땐 게임을 부드럽게(속도/장애물 완화),
  /// 잔잔한 지루함/피곤함일 땐 오히려 살짝 활기차게 진행하도록 [RunnerGame]에
  /// 미리 알려준다. choice_screen.dart의 슬라이더와 톤/색을 맞췄다.
  Widget _buildIntensitySlider() {
    final l10n = AppLocalizations.of(context);
    final labels = [
      l10n.choiceIntensityVeryWeak,
      l10n.choiceIntensityWeak,
      l10n.choiceIntensityNormal,
      l10n.choiceIntensityStrong,
      l10n.choiceIntensityVeryStrong,
    ];
    final index = _intensity.round().clamp(1, 5) - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.homeIntensityLabel,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.inkSoft,
            ),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.roseStrong,
              inactiveTrackColor: const Color(0xFFF0E6DF),
              thumbColor: AppColors.roseStrong,
              overlayColor: const Color(0x22FF8FAB),
              trackHeight: 4,
            ),
            child: Slider(
              value: _intensity,
              min: 1,
              max: 5,
              divisions: 4,
              label: labels[index],
              onChanged: (v) => setState(() => _intensity = v),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                labels[index],
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.inkSoft,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 잠금 대신, 어떤 감정이든 괜찮다고 말해주는 다정한 한 줄.
  Widget _buildFriendlyCaption() {
    return Text(
      AppLocalizations.of(context).homeFriendlyCaption,
      style: const TextStyle(
        color: AppColors.inkSoft,
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  /// "무한의 계단"식 도전 모드로 진입하는 보조 버튼. 감정을 골라야 활성화되며,
  /// 최고기록이 있으면 함께 보여줘서 "오늘 넘어보자"는 가벼운 동기를 준다.
  Widget _buildEndlessButton(GardenProvider garden) {
    final l10n = AppLocalizations.of(context);
    final enabled = _selected.isNotEmpty;
    final hasRecord = garden.bestEndlessCount > 0;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: enabled ? _startEndless : null,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 13),
          foregroundColor: AppColors.inkSoft,
          disabledForegroundColor: Colors.grey.shade400,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          side: BorderSide(
            color: enabled ? const Color(0xFFBBB0A6) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          hasRecord
              ? l10n.homeEndlessButtonRecord(garden.bestEndlessCount)
              : l10n.homeEndlessButtonNoRecord,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  /// 3번(고요 모드/활동 모드 이원화) - 러너 게임(활동 모드)의 대안으로,
  /// 반응속도/점수 없이 감정을 조용히 마주하고 정원에 심는 저자극 트랙으로
  /// 안내하는 보조 버튼. 위의 "달리기 시작"/"무한 도전"과 같은 감정 선택을
  /// 그대로 이어받아 쓰되, 시각적으로는 차분한 보라 계열 텍스트 버튼으로
  /// 구분해 "이건 게임이 아니다"는 톤을 준다.
  Widget _buildQuietModeButton() {
    final l10n = AppLocalizations.of(context);
    final enabled = _selected.isNotEmpty;
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: enabled ? _startQuiet : null,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          foregroundColor: const Color(0xFF9B8FE0),
          disabledForegroundColor: Colors.grey.shade400,
        ),
        child: Text(
          l10n.homeQuietModeButton,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _buildStartButton() {
    final l10n = AppLocalizations.of(context);
    final enabled = _selected.isNotEmpty;
    final label = enabled
        ? l10n.homeStartButtonEnabled(_selected.length, _maxSelectable)
        : l10n.homeStartButtonDisabled(_maxSelectable);
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: enabled ? _start : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled
              ? AppColors.roseStrong
              : Colors.grey.shade300,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: enabled ? 4 : 0,
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
