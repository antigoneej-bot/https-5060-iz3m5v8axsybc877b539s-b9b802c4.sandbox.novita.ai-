// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '몽이';

  @override
  String get commonCancel => '취소';

  @override
  String get onboardingSkip => '건너뛰기';

  @override
  String get onboardingPage1Title => '안녕, 나는 몽이야 🐾';

  @override
  String get onboardingPage1Desc => '오늘 마음속에 남은 감정이 있다면\n나랑 같이 놀면서 흘려보내자!';

  @override
  String get onboardingPage2Title => '몽이는 저절로\n앞으로 달려가요';

  @override
  String get onboardingPage2Desc => '이동은 자동이에요!\n버튼 타이밍에만 집중해보세요!';

  @override
  String get onboardingPage3Title => '왼쪽 ✊ 주먹 버튼\n오른쪽 🦘 점프 버튼';

  @override
  String get onboardingPage3Desc =>
      '작은 돌멩이는 타이밍 맞춰 주먹으로!\n큰 돌멩이는 꼭 점프 버튼으로 피해야 해요.';

  @override
  String get onboardingPage4Title => '감정 몬스터에게 닿으면\n몽이가 마음으로 마주해줘요';

  @override
  String get onboardingPage4Desc => '마주한 감정은 마음정원에\n예쁜 꽃으로 피어나요 🌷';

  @override
  String get onboardingNext => '다음';

  @override
  String get onboardingFinish => '몽이 만나러 가기 🐾';

  @override
  String get homeHeadline => '오늘 마음속에\n남아있는 감정이 있나요?';

  @override
  String get homeSubCaption =>
      '왼쪽 ✊ 주먹 버튼 / 오른쪽 🦘 점프 버튼!\n감정 몬스터는 몽이가 알아서 마주해줘요!';

  @override
  String get navHome => '홈';

  @override
  String get navGarden => '정원';

  @override
  String get navShop => '상점';

  @override
  String get navLetter => '편지';

  @override
  String get navMission => '미션';

  @override
  String get navSettings => '설정';

  @override
  String get homeHelpTooltip => '사용법 다시보기';

  @override
  String homeGardenBadgeProgress(int percent) {
    return '마음정원 회복도 $percent%';
  }

  @override
  String homeGardenBadgeStage(int stage) {
    return '🐾 몽이 $stage단계';
  }

  @override
  String homeGardenBadgeStreak(int days) {
    return '🔥 $days일째';
  }

  @override
  String homeGardenBadgeCheckInStreak(int days) {
    return '✅ 체크인 $days일째';
  }

  @override
  String get homeSupportAlertTitle => '요즘 마음이 많이 무거웠나 봐요';

  @override
  String get homeSupportAlertBody => '혼자 견디지 않아도 괜찮아요. 언제든 이야기 나눌 곳이 있어요.';

  @override
  String get homeComebackCareTitleShort => '다시 만나서 반가워요!';

  @override
  String homeComebackCareBodyShort(int days) {
    return '$days일 만이네요. 잠깐 쉬어가도 몽이는 늘 여기서 기다리고 있었어요 🌱';
  }

  @override
  String get homeComebackCareTitleLong => '오랜만이에요, 잘 지냈어요?';

  @override
  String homeComebackCareBodyLong(int days) {
    return '$days일 동안 못 봤네요. 그래도 괜찮아요 - 몽이는 그 사이에도 여기서 잘 지내고 있었어요. 오늘부터 다시 천천히 시작해봐요 💛';
  }

  @override
  String get homeChargeButton => '충전';

  @override
  String get homeMindBoxChip => '마음 상자';

  @override
  String homePowerCharmChip(int count) {
    return '파워 부적 $count';
  }

  @override
  String get homeMongiCareChip => '몽이 돌봄';

  @override
  String homeTodayGoalBadge(String hint) {
    return '🎯 오늘의 목표: $hint';
  }

  @override
  String homeSeasonBannerTitle(int season, int level) {
    return '시즌 $season · 몽이의 마음여정 · Lv.$level';
  }

  @override
  String get homeSeasonBannerSubtitle => '눌러서 시즌 보상 확인하기';

  @override
  String get commonClaim => '받기!';

  @override
  String get homeDailyMissionTitle => '몽이의 오늘 미션';

  @override
  String get homeDailyMissionSubtitle => '눌러서 오늘의 보상 확인하기';

  @override
  String homeDailyMissionClaimCount(int count) {
    return '받기! $count';
  }

  @override
  String get homeMindReportButton => '마음 리포트';

  @override
  String get homeBreathingButton => '숨쉬기';

  @override
  String get homeNameFieldHint => '오늘 감정, 왜 생겼는지 몽이한테만 알려줄래? (선택)';

  @override
  String get homeHowToTitle => '👇 이렇게 사용해요';

  @override
  String get homeHowToStep1 => '아래에서\n감정을 골라요\n(최대 3개)';

  @override
  String get homeHowToStep2 => '몽이와\n달리기 시작!';

  @override
  String get homeHowToStep3 => '몽이가 닿으면\n마음으로 마주해요';

  @override
  String get homeHowToStep4 => '정원에\n씨앗으로 남아요';

  @override
  String get homeMaxSelectSnackbar => '최대 3개까지 선택할 수 있어요';

  @override
  String get homeIntensityLabel => '이 마음, 지금 얼마나 강한가요?';

  @override
  String get homeFriendlyCaption => '오늘 어떤 마음이든, 몽이는 다 좋아요 🐾';

  @override
  String homeEndlessButtonRecord(int count) {
    return '♾️ 무한 도전! (최고기록 $count개)';
  }

  @override
  String get homeEndlessButtonNoRecord => '♾️ 무한 도전으로 오늘의 최고기록 세우기';

  @override
  String homeStartButtonEnabled(int selected, int max) {
    return '몽이와 달리기 시작! 🐾 ($selected/$max)';
  }

  @override
  String homeStartButtonDisabled(int max) {
    return '감정을 선택해주세요 (최대 $max개)';
  }

  @override
  String get homeQuietModeButton => '🌙 고요 모드로 마주하기';

  @override
  String get homeMonetizationSectionLabel => '여기서부터는 재화·상점이에요';

  @override
  String get quietModeAppBarTitle => '고요 모드';

  @override
  String get quietModeGreetTitle => '오늘 이 마음을 그대로 마주해볼까요?';

  @override
  String get quietModeGreetSubtitle => '서두르지 않아도 괜찮아요. 몽이가 곁에 있어요.';

  @override
  String get quietModeGreetNextButton => '다음';

  @override
  String get quietModeBreatheTitle => '잠깐, 숨을 골라볼까요?';

  @override
  String get quietModeBreatheStartButton => '시작하기';

  @override
  String get quietModeBreatheSkipButton => '건너뛰기';

  @override
  String get quietModeReflectTitle => '한 줄로 남겨볼까요? (선택)';

  @override
  String get quietModeReflectHint => '지금 마음을 짧게 적어보세요';

  @override
  String get quietModePlantButton => '마음에 심기';

  @override
  String get quietModePlantingMessage => '마음이 정원에 조용히 스며들고 있어요...';

  @override
  String get quietModeDoneTitle => '마음을 잘 심었어요';

  @override
  String quietModeDoneBody(int count) {
    return '$count개의 마음이 정원에 꽃으로 피어났어요. 언제든 다시 들여다볼 수 있어요.';
  }

  @override
  String get quietModeDoneHomeButton => '홈으로';

  @override
  String get quietModeDoneGardenButton => '정원 보기';

  @override
  String get shopTitle => '🛍️ 상점';

  @override
  String get shopSectionCurrency => '💰 재화 충전';

  @override
  String get shopLightEssenceTitle => '빛의 정수 충전';

  @override
  String get shopLightEssenceSubtitle =>
      '결제로 빛의 정수를 바로 채워요 (100개 ₩5,000 · 1,000개 ₩10,000)';

  @override
  String get shopSectionConsumables => '🎁 소모품 & 꾸미기';

  @override
  String get shopMindBoxTitle => '마음 상자';

  @override
  String get shopMindBoxSubtitle => '빛의 정수로 몽이 코스튬을 모아보세요 (확률 없이 순차 지급)';

  @override
  String get shopPowerCharmTitle => '파워 부적';

  @override
  String shopPowerCharmSubtitle(int count) {
    return '게임 중 10초간 무적이 되는 소모템 (지금 보유 $count개)';
  }

  @override
  String get shopMongiCareTitle => '몽이 돌봄 세트';

  @override
  String get shopMongiCareSubtitle => '참치캔·사료 같은 소모품부터 담요 같은 특별한 선물까지';

  @override
  String get shopGardenDecoTitle => '정원 꾸미기';

  @override
  String get shopGardenDecoSubtitle => '벤치·분수대 등 무료 장식 + 프리미엄 장식팩';

  @override
  String get shopSectionSeason => '🌟 시즌 & 멤버십';

  @override
  String get shopSeasonPassTitle => '몽이의 마음여정 (시즌 패스)';

  @override
  String get shopSeasonPassSubtitle => '이번 시즌 한정 프리미엄 트랙으로 더 풍성한 보상을 받아요';

  @override
  String get settingsHeader => '⚙️ 설정';

  @override
  String get settingsNotifTitle => '매일 몽이 알림';

  @override
  String get settingsNotifPermissionDenied => '알림 권한이 필요해요. 기기 설정에서 허용해주세요.';

  @override
  String get settingsNotifDesc =>
      '매일 정해진 시각에 몽이가 오늘의 마음을 물어봐요.\n부담스럽지 않게 딱 한 번만 알려드려요.';

  @override
  String get settingsNotifTimeLabel => '알림 시각';

  @override
  String get settingsLanguageTitle => '언어';

  @override
  String get settingsLanguageSystem => '시스템 기본';

  @override
  String get settingsLanguageKorean => '한국어';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsDataNoticeTitle => '📱 데이터 보관 안내';

  @override
  String get settingsDataNoticeBody =>
      '몽이는 로그인 없이 이 기기에만 정원·일기·진행도를 저장해요. 앱을 지우거나 기기를 바꾸면 이 기록은 함께 사라져요.\n구매한 아이템은 구글 계정으로 \"구매 복원\"이 가능하지만, 정원 자체는 복원되지 않으니 참고해주세요.';

  @override
  String get settingsMentalHealthTitle => '마음이 힘들 때';

  @override
  String get settingsMentalHealthSubtitle => '혼자 견디지 않아도 돼요 · 24시간 상담 안내 보기';

  @override
  String get settingsPrivacyPolicy => '개인정보처리방침';

  @override
  String get settingsResetTitle => '처음부터 다시 시작';

  @override
  String get settingsResetDesc =>
      '지금까지의 스테이지, 재화, 코스튬, 정원 진행도를 모두 지우고\n1단계부터 새로 시작해요. 테스트나 처음 경험을 다시 보고 싶을 때 써요.';

  @override
  String get settingsResetButton => '진행도 초기화하고 1단계부터 시작';

  @override
  String get settingsResetConfirmTitle => '정말 초기화할까요?';

  @override
  String get settingsResetConfirmBody =>
      '스테이지, 재화, 코스튬, 정원 진행도가 모두 사라지고\n1단계부터 다시 시작해요. 되돌릴 수 없어요.';

  @override
  String get settingsResetConfirmButton => '초기화';

  @override
  String get settingsWebNotice => '💡 알림 기능은 안드로이드 앱에서만 사용할 수 있어요.';

  @override
  String get gamePunchLabel => '주먹';

  @override
  String get gameJumpLabel => '점프';

  @override
  String get gameLoadErrorTitle => '스테이지를 불러오는 중 문제가 생겼어요.\n다시 시도해주세요.';

  @override
  String get gameLoadErrorButton => '돌아가기';

  @override
  String get gameHintAutoRun => '몽이가 저절로 앞으로 달려가요';

  @override
  String gameHintTimeLimit(int seconds) {
    return '⏰ $seconds초 안에 목표를 채워봐요!';
  }

  @override
  String get gameHintControlsStage1 => '오른쪽 🦘 점프 버튼을 누르면 바로 점프해요!';

  @override
  String get gameHintControlsStage2Plus => '왼쪽 ✊ 주먹 버튼 / 오른쪽 🦘 점프 버튼을 눌러요!';

  @override
  String get gameHintDodgeStage1 => '돌멩이는 점프로 피하고, 감정 몬스터는 그냥 지나가면 마주하게 돼요!';

  @override
  String get gameHintDodgeStage2Plus => '작은 돌멩이는 타이밍 맞춰 주먹으로! 큰 돌멩이는 꼭 점프로 피해요';

  @override
  String gameHudStage(int stage) {
    return '$stage단계';
  }

  @override
  String get gameTimeOfDayDawn => '아침 정원';

  @override
  String get gameTimeOfDayNight => '밤 정원';

  @override
  String gameTimeOfDayBadge(String label) {
    return '지금은 $label이에요';
  }

  @override
  String gamePowerModeBadge(int seconds) {
    return '⚡ 무적 모드! $seconds초';
  }

  @override
  String gameTimeBadge(int seconds) {
    return '⏰ $seconds초';
  }

  @override
  String gameComboBadge(int combo) {
    return '🔥 콤보 x$combo';
  }

  @override
  String get gameExitConfirmTitle => '게임을 종료할까요?';

  @override
  String get gameExitConfirmBody => '지금까지의 진행은 저장되지 않고, 처음 화면으로 돌아가요.';

  @override
  String get gameExitConfirmButton => '종료';

  @override
  String get appExitConfirmTitle => '몽이와의 시간을 마칠까요?';

  @override
  String get appExitConfirmBody => '지금까지 기록한 마음은 그대로 저장돼 있어요. 다음에 또 만나요 🌱';

  @override
  String get appExitConfirmButton => '종료';

  @override
  String get endlessHintTitle => '오늘 몽이의 최고 기록에 도전해요!';

  @override
  String get endlessHintGoal => '목숨이 다할 때까지 최대한 많이 모아보세요';

  @override
  String endlessHudBestRecord(int count) {
    return '👑 최고 $count';
  }

  @override
  String get homeMongiMoodWaiting => '몽이가 오늘은 어떤 마음을 만나게 될지 기다리고 있어요.';

  @override
  String get homeMongiMoodJoyful => '요즘 마음이 가벼웠나 봐요! 몽이가 신나서 폴짝폴짝 뛰어다녀요 🐾';

  @override
  String get homeMongiMoodHeavy => '요 며칠 마음이 조금 무거웠나 봐요. 몽이가 옆에 웅크리고 있어요.';

  @override
  String get homeMongiMoodCalm => '몽이가 평소처럼 편안하게 곁을 지키고 있어요.';

  @override
  String get homeEasterEgg0 => '오늘 몽이가 이상한 소리를 냈어요... \"그르릉냥냥?\" 🐱';

  @override
  String get homeEasterEgg1 => '몽이가 갑자기 벽을 보고 하이파이브를 했어요. 왜 그런지는 몽이만 알아요.';

  @override
  String get homeEasterEgg2 => '몽이가 자기 꼬리를 30초 동안 쫓아다녔어요. 결국 잡았대요.';

  @override
  String get homeEasterEgg3 => '몽이가 오늘따라 낮잠을 세 번이나 잤어요. 꿈에서 생선을 만났나 봐요.';

  @override
  String get homeEasterEgg4 => '몽이가 창밖을 보며 한참 생각에 잠겼어요. 무슨 생각을 했을까요?';

  @override
  String get homeEasterEgg5 => '몽이가 오늘 스스로에게 박수를 쳐줬어요. 이유는 비밀이래요.';

  @override
  String get homeEasterEgg6 => '몽이가 갑자기 \"야옹!\" 하고 크게 울었어요. 그냥 기분이 좋았대요.';

  @override
  String get homeEasterEgg7 => '몽이가 발바닥 젤리를 자랑스럽게 보여줬어요.';

  @override
  String get homeEasterEgg8 => '몽이가 오늘 할 일 목록에 \"귀여워지기\"를 적어놓고 완료 체크했어요.';

  @override
  String get homeEasterEgg9 => '몽이가 자기 그림자를 보고 놀라서 폴짝 뛰었어요. 지금은 괜찮대요.';

  @override
  String get homeEasterEgg10 => '몽이가 오늘 아침 거울을 보고 한참 인사를 나눴어요.';

  @override
  String get homeEasterEgg11 => '몽이가 이유 없이 방을 세 바퀴 돌고 다시 자리에 앉았어요.';

  @override
  String get gardenTapHint =>
      '씨앗을 탭하면 얼마나 자랐는지 볼 수 있어요 · 우측 상단 \"꾸미기\"로 아이템을 놓아보세요';

  @override
  String get gardenHeaderTitle => '🌷 내 마음정원';

  @override
  String get gardenTooltipCollection => '감정 도감';

  @override
  String get gardenTooltipMilestone => '성장 다큐멘터리';

  @override
  String get gardenTooltipShare => '정원 공유하기';

  @override
  String get gardenTooltipCalendar => '감정 캘린더';

  @override
  String get gardenTooltipDiary => '다이어리';

  @override
  String gardenSummaryFlowersPlanted(int count) {
    return '지금까지 $count송이의 마음을 피워냈어요';
  }

  @override
  String get gardenStatRecoveryLabel => '회복도';

  @override
  String get gardenStatMongiLabel => '몽이';

  @override
  String get gardenStatStreakLabel => '연속';

  @override
  String get gardenStatScoreLabel => '점수';

  @override
  String gardenStatPercentValue(int percent) {
    return '$percent%';
  }

  @override
  String gardenStatStageValue(int stage) {
    return '$stage단계';
  }

  @override
  String gardenStatStreakValue(int days) {
    return '$days일';
  }

  @override
  String gardenStatScoreValue(int score) {
    return '$score점';
  }

  @override
  String get gardenTreeWiltedHint =>
      '몽이의 성장나무가 조금 심심해 보여요 · 오늘 찾아오면 금방 다시 생기를 되찾아요 🌤️';

  @override
  String gardenTreeMaxStageHint(String label) {
    return '몽이의 성장나무가 $label로 활짝 자랐어요!';
  }

  @override
  String gardenTreeGrowthHint(String label, int remaining) {
    return '지금 몽이의 성장나무: $label · 다음 성장까지 $remaining점';
  }

  @override
  String get gardenEmptyTitle => '아직 심어진 꽃이 없어요';

  @override
  String get gardenEmptyBody => '마음속 감정을 하나씩 마주하고 나면\n이 자리에 꽃이 피어날 거예요';

  @override
  String gardenFlowerBedTitle(String emotionLabel) {
    return '$emotionLabel의 정원';
  }

  @override
  String get gardenTreeStageSeed => '씨앗';

  @override
  String get gardenTreeStageSprout => '새싹';

  @override
  String get gardenTreeStageTree => '나무';

  @override
  String get gardenTreeStageFlower => '꽃';

  @override
  String get gardenTreeStageFruit => '열매';

  @override
  String get gardenSceneTitle => '🌿 내 정원';

  @override
  String get gardenSceneCareButton => '돌봄';

  @override
  String get gardenSceneDecorateButton => '꾸미기';

  @override
  String gardenSeedPotWatered(String seedLabel, int count) {
    return '$seedLabel · 지금까지 $count번 물을 줬어요';
  }

  @override
  String gardenSeedPotNotPlanted(String seedLabel) {
    return '$seedLabel 씨앗은 아직 심지 않았어요';
  }

  @override
  String get gardenTreeWiltedSnackbar =>
      '몽이의 성장나무가 조금 심심해 보여요 · 오늘 다시 찾아오면 금방 생기를 되찾아요 🌤️';

  @override
  String gardenTreeStageSnackbar(String label) {
    return '몽이의 성장나무 · 지금은 $label 단계예요';
  }

  @override
  String get gardenSeasonSpring => '봄';

  @override
  String get gardenSeasonSummer => '여름';

  @override
  String get gardenSeasonAutumn => '가을';

  @override
  String get gardenSeasonWinter => '겨울';

  @override
  String get gardenSeasonGreetingSpring => '몽이의 정원에 벚꽃이 흩날리고 있어요';

  @override
  String get gardenSeasonGreetingSummer => '몽이의 정원이 싱그러운 여름빛으로 반짝여요';

  @override
  String get gardenSeasonGreetingAutumn => '몽이의 정원에 낙엽이 살랑살랑 내려요';

  @override
  String get gardenSeasonGreetingWinter => '몽이의 정원에 눈이 소복하게 쌓이고 있어요';

  @override
  String choiceStageClearBody(int currentStage, int nextStage) {
    return '$currentStage단계를 완주했어요!\n다음 단계($nextStage단계)로 넘어가볼까요?';
  }

  @override
  String get choiceStageClearHint =>
      '다음 단계는 돌멩이가 조금 더 크고 빨라지지만,\n몽이도 그만큼 더 씩씩해져 있을 거예요 🌟';

  @override
  String get choiceStageClearStayButton => '여기 머물게요';

  @override
  String get choiceStageClearAdvanceButton => '다음 단계로! 🚀';

  @override
  String choiceAskingTargetLabel(String targetName, String emotionsLabel) {
    return '$targetName에 대한 $emotionsLabel';
  }

  @override
  String choiceAskingHeadlineWithCount(String nameLabel, int count) {
    return '오늘 $nameLabel\n$count개를 몽이가 마주했어요!';
  }

  @override
  String choiceAskingHeadlineNoCount(String nameLabel) {
    return '오늘 $nameLabel를\n마음속에서 잠시 마주했어요';
  }

  @override
  String get choiceAskingPrompt => '이제 그 자리에\n마음을 심어볼까요?';

  @override
  String get choiceAskingNotYetButton => '아직은 아니에요';

  @override
  String get choiceAskingPlantButton => '네, 심을래요';

  @override
  String choiceEarlyStopWithRemaining(int count, int remaining) {
    return '오늘은 $count개의 마음을 만났어요.\n아직 $remaining개가 도망쳤어요, 다음에 마저 잡아줄래요? 🤍';
  }

  @override
  String choiceEarlyStopNoRemaining(int count) {
    return '오늘은 $count개의 마음을 만났어요.\n그만큼도 충분해요, 다음에 또 와줄래요? 🤍';
  }

  @override
  String choiceComboLow(int count) {
    return '흔들릴 뻔한 순간에도 $count번이나 씩씩하게 버텼어요';
  }

  @override
  String choiceComboMid(int count) {
    return '$count번 연속으로 흔들리지 않고 마음을 지켜냈어요!';
  }

  @override
  String choiceComboHigh(int count) {
    return '$count번이나 연속으로 버텨냈어요! 몽이가 오늘 유난히 단단해요 💪';
  }

  @override
  String choiceInsightFrequentPositive(int count) {
    return '이 마음, 이번 주에만 벌써 $count번째예요.\n요즘 자주 찾아오는 좋은 마음이네요 ☺️';
  }

  @override
  String choiceInsightFrequentNegative(int count) {
    return '이 마음, 이번 주에만 벌써 $count번째예요.\n요즘 자주 찾아오는 마음인가 봐요. 몽이가 계속 지켜보고 있을게요.';
  }

  @override
  String get choiceInsightAllPositive =>
      '오늘은 마음에 좋은 기운만 가득했네요.\n그런 하루도 몽이에게 소중한 선물이에요 ✨';

  @override
  String choiceInsightLongAbsence(String emotionLabel, int days) {
    return '오랜만이에요! $emotionLabel은(는)\n$days일 만에 다시 만났어요. 그동안 잘 지냈나요?';
  }

  @override
  String choiceInsightFirstEncounter(String emotionLabel) {
    return '$emotionLabel을(를) 처음 일기에 남겼어요.\n용기 내 보여줘서 고마워요. 몽이가 오래오래 기억해둘게요.';
  }

  @override
  String choiceNextGoalAlmostCollected(int count) {
    return '이제 $count가지 마음만 더 만나면 도감이 완성돼요!\n다음엔 어떤 마음일까요? 🔍';
  }

  @override
  String choiceNextGoalTreeAlmost(int points) {
    return '몽이의 나무가 다음 단계까지 $points점 남았어요.\n조금만 더 함께해줄래요? 🌳';
  }

  @override
  String choiceNextGoalManyUncollected(int count) {
    return '아직 만나지 못한 마음이 $count가지 있어요.\n다음엔 어떤 마음을 만나게 될까요?';
  }

  @override
  String get choiceSeedSelectTitle => '어떤 마음을 심어볼까요?';

  @override
  String get choiceSeedSelectSubtitle => '하나를 고르면 몽이의 작은 정원에\n그 마음이 자라나요';

  @override
  String choiceSeedWateredCount(int count) {
    return '지금까지 $count번 물을 줬어요';
  }

  @override
  String get choiceBackButton => '뒤로';

  @override
  String choicePlantingTitle(String seedLabel) {
    return '$seedLabel의 씨앗에\n물을 주고 있어요';
  }

  @override
  String choicePlantingSubtitle(String seedLabel) {
    return '몽이의 정원에 $seedLabel이(가) 자라나고 있어요 🌱';
  }

  @override
  String choiceTreeGrowthTitle(String label) {
    return '몽이의 성장나무가\n$label로 자라났어요!';
  }

  @override
  String get choiceTreeGrowthHint => '꾸준히 마음을 마주할수록\n나무가 더 크게 자라나요 🌱';

  @override
  String choiceTreeGrowthBonus(int bonus) {
    return '나무가 자란 특별 선물, 빛의 정수 +$bonus';
  }

  @override
  String get choiceTreeGrowthShareButton => '이 순간 자랑하기';

  @override
  String get choiceResultTitleBloomed => '정원이 활짝 피었어요! 🌸';

  @override
  String choiceResultTitleSeedPlanted(String seedLabel) {
    return '$seedLabel의 씨앗이 마음에 심어졌어요';
  }

  @override
  String get choiceResultTitlePlanted => '마음이 심어졌어요';

  @override
  String get choiceResultTitleGentle => '괜찮아요, 천천히 해도 돼요';

  @override
  String get choiceResultMessageLove => '어두웠던 자리에\n따뜻한 빛이 스며들었어요 ✨';

  @override
  String get choiceResultMessageNoLove =>
      '오늘 마주한 감정만큼\n마음은 이미 조금 가벼워졌어요\n준비되면 다시 올게요 🤍';

  @override
  String get choiceResultLevelUpStage2 =>
      '\n\n몽이가 이제 손을 뻗어 작은 돌멩이를 부술 수 있게 됐어요! 💪';

  @override
  String choiceResultLevelUpOther(int stage) {
    return '\n\n몽이가 $stage단계로 성장했어요! 돌멩이는 조금 더 커졌지만 몽이는 더 씩씩해졌답니다 🌟';
  }

  @override
  String choiceResultLightEarned(int earned, int total) {
    return '💡 +$earned (보유 $total)';
  }

  @override
  String choiceResultGoldenFrameTitle(String emotionLabel) {
    return '\"$emotionLabel\" 황금 프레임 획득!';
  }

  @override
  String get choiceResultGoldenFrameDesc =>
      '극히 낮은 확률로만 얻을 수 있는 희귀 표식이에요.\n감정 도감에서 자랑해보세요!';

  @override
  String choiceResultSeedGrown(String seedLabel) {
    return '$seedLabel 정원이 조금 더 자랐어요';
  }

  @override
  String get choiceResultGardenButton => '내 마음정원 보러가기';

  @override
  String get choiceResultNoteLabel => '오늘 이 감정, 한 문장으로 남겨볼까요? (선택)';

  @override
  String get choiceResultNoteHint => '예: 오늘은 조금 마음이 편해졌어요';

  @override
  String get choiceResultShareButton => '감정 카드 공유하기';

  @override
  String get choiceResultHomeButton => '처음으로';

  @override
  String get choiceIntensityLabel => '이 감정, 오늘은 얼마나 강하게 느꼈나요?';

  @override
  String get choiceIntensityVeryWeak => '아주 약하게';

  @override
  String get choiceIntensityWeak => '약하게';

  @override
  String get choiceIntensityNormal => '보통';

  @override
  String get choiceIntensityStrong => '강하게';

  @override
  String get choiceIntensityVeryStrong => '아주 강하게';

  @override
  String get choiceTriggerLabel => '무엇 때문이었을까요? (선택, 여러 개 가능)';

  @override
  String get choiceTranscendenceBadge => '숨겨진 순간을 발견했어요';

  @override
  String choiceTranscendenceTitle(String emotionLabel) {
    return '\"$emotionLabel\"이(가) 초월했어요';
  }

  @override
  String get choiceTranscendenceDesc =>
      '백 번을 마주할 만큼 함께해준 마음이에요.\n아무도 예고해주지 않았지만, 당신은 해냈어요.';

  @override
  String get choiceSeasonMilestoneBadge => '마음여정의 마일스톤';

  @override
  String get seasonMilestoneLevel5 => '벌써 5레벨! 매일 조금씩 마음을 돌보고 있다는 증거예요 🌱';

  @override
  String get seasonMilestoneLevel10 => '절반을 지났어요. 그동안 쌓아온 하루하루가 정말 소중해요 🌿';

  @override
  String get seasonMilestoneLevel15 => '15레벨, 이제 얼마 남지 않았어요. 꾸준함이 참 대단해요 🌳';

  @override
  String get seasonMilestoneLevel20 =>
      '이번 시즌의 마음여정을 완주했어요! 몽이가 가장 자랑스러워하는 순간이에요 🌟';

  @override
  String get privacyHeaderTitle => '🔒 개인정보처리방침';

  @override
  String get privacyIntro =>
      '몽이는 로그인이 없는 앱이에요. 이 방침은 몽이가 어떤 정보를 다루고, 어떻게 지키는지 쉬운 말로 알려드려요.';

  @override
  String get privacySection1Title => '1. 로그인/회원가입이 없어요';

  @override
  String get privacySection1Body =>
      '몽이는 로그인이나 회원가입 절차가 전혀 없는 앱이에요. 이름, 이메일, 전화번호 같은 계정 정보를 요구하거나 수집하지 않아요. 감정 입력 화면에서 별명을 적더라도, 이 정보는 오직 이 기기 안에만 저장돼요.';

  @override
  String get privacySection2Title => '2. 데이터는 이 기기에만 저장돼요';

  @override
  String get privacySection2Body =>
      '감정 일기, 정원 성장 상태, 스테이지 진행도, 보유 코스튬 등 몽이와 함께한 모든 기록은 서버로 전송되지 않고 오직 이 기기의 로컬 저장소(Hive)에만 보관돼요. 저희(개발자)도 이 내용을 볼 수 없어요.\n\n⚠️ 다만 이 때문에 앱을 지우거나 기기를 바꾸면 그동안 쌓은 정원/일기/진행도가 함께 사라져요(구매한 아이템은 구글 계정에 연동되어 \"구매 복원\"으로 되찾을 수 있지만, 정원 자체는 복원되지 않아요). 소중한 기록이라면 가끔 화면을 캡처해 보관하는 걸 추천해요.';

  @override
  String get privacySection3Title => '3. 광고 서비스(Google AdMob)';

  @override
  String get privacySection3Body =>
      '무료로 더 많은 기능을 제공하기 위해 Google AdMob 광고를 보여드려요. 광고를 표시하고 맞춤 광고를 제공하는 과정에서 Google이 광고 식별자(Advertising ID), 기기 정보, IP 주소 등을 자체 정책에 따라 수집·처리할 수 있어요. 이는 저희가 아니라 Google이 처리하는 정보이며, 자세한 내용은 Google의 개인정보처리방침에서 확인할 수 있어요.\n\n기기 설정에서 \"광고 개인 최적화 선택 해제\"를 켜면 맞춤 광고 없이도 앱을 이용할 수 있어요.';

  @override
  String get privacySection4Title => '4. 인앱 결제(Google Play 결제)';

  @override
  String get privacySection4Body =>
      '코스메틱 아이템(카드 프레임, 정원 장식, 코스튬 등) 구매는 Google Play 결제 시스템을 통해 처리돼요. 결제 정보(카드 번호 등)는 저희에게 전달되지 않고 Google이 직접 처리해요. 저희는 \"어떤 상품을 구매했는지\"만 확인해 해당 아이템을 지급하는 데 사용해요.';

  @override
  String get privacySection5Title => '5. 알림 권한';

  @override
  String get privacySection5Body =>
      '매일 정해진 시각에 알림을 보내드리기 위해 알림 권한을 요청할 수 있어요. 이 권한은 오직 로컬 알림 발송에만 쓰이고, 언제든 설정 화면이나 기기 설정에서 꺼둘 수 있어요.';

  @override
  String get privacySection6Title => '6. 만 14세 미만 이용';

  @override
  String get privacySection6Body =>
      '몽이는 계정 기반 수집이 없는 앱이지만, 만 14세 미만 아동은 보호자의 지도 아래 이용하는 것을 권장해요. 결제 기능이 포함되어 있으니 보호자께서 인앱 결제 관련 기기 설정(구매 시 비밀번호 확인 등)을 확인해주세요.';

  @override
  String get privacySection7Title => '7. 문의';

  @override
  String privacySection7Body(String email) {
    return '개인정보 처리와 관련해 궁금한 점이 있다면 아래 이메일로 언제든 문의해주세요.\n\n$email';
  }

  @override
  String get privacySection8Title => '8. 방침 변경';

  @override
  String get privacySection8Body =>
      '이 개인정보처리방침은 법령이나 서비스 변경에 따라 수정될 수 있어요. 중요한 변경이 있을 경우 앱 내 공지를 통해 알려드릴게요.';

  @override
  String get privacyAdConsentTitle => '🍪 광고 개인정보 선택';

  @override
  String get privacyAdConsentBody =>
      '유럽경제지역(EEA)·영국 등 일부 지역에서는 맞춤 광고에 대한 동의 여부를 언제든지 다시 선택할 수 있어요.';

  @override
  String get privacyAdConsentButton => '광고 개인정보 선택 관리';

  @override
  String get privacyAdConsentNotAvailable =>
      '지금은 광고 개인정보 선택을 변경할 수 없어요. 잠시 후 다시 시도해주세요.';

  @override
  String get privacyTermsOfServiceButton => '이용약관 보기';

  @override
  String get privacyLastUpdatedDate => '2026년 8월 25일';

  @override
  String privacyLastUpdatedLabel(String date) {
    return '마지막 개정일: $date';
  }

  @override
  String get mentalHealthHeaderTitle => '🤍 마음이 힘들 때';

  @override
  String mentalHealthCallFailedSnackbar(String number) {
    return '전화 연결에 실패했어요. 직접 $number로 걸어주세요.';
  }

  @override
  String mentalHealthActionFailedSnackbar(String action) {
    return '연결에 실패했어요. 직접 $action로 시도해주세요.';
  }

  @override
  String get mentalHealthOpenButtonLabel => '열기';

  @override
  String mentalHealthSmsFailedSnackbar(String number) {
    return '문자 앱 연결에 실패했어요. 직접 $number로 문자를 보내주세요.';
  }

  @override
  String get mentalHealthSendSmsButtonLabel => '문자 보내기';

  @override
  String get mentalHealthIntroBody1 =>
      '몽이는 마음을 가볍게 마주하고 기록하는 걸 도와주는 친구예요.\n그런데 만약 지금 견디기 힘들 만큼 마음이 무겁다면,\n몽이보다 훨씬 든든한 전문 상담 선생님과 이야기해보는 게 좋아요.';

  @override
  String get mentalHealthIntroBody2 =>
      '전화하는 게 망설여져도 괜찮아요. 아래 번호들은 24시간, 익명으로,\n완전히 무료로 이야기를 들어주는 곳이에요. 혼자 견디지 않아도 돼요.';

  @override
  String get mentalHealthCallSectionTitle => '📞 언제든 연결할 수 있는 곳';

  @override
  String get mentalHealthHelpline1Name => '자살예방상담전화';

  @override
  String get mentalHealthHelpline1Desc =>
      '24시간 · 전국 어디서나 국번 없이 109\n자살을 생각하고 있거나, 힘들어하는 주변 사람이 걱정될 때';

  @override
  String get mentalHealthHelpline2Name => '정신건강 위기상담전화';

  @override
  String get mentalHealthHelpline2Desc => '24시간 · 우울, 불안 등 마음이 힘든 모든 순간';

  @override
  String get mentalHealthHelpline3Name => '청소년전화 1388';

  @override
  String get mentalHealthHelpline3Desc => '24시간 · 청소년 고민 상담(학업, 관계, 가정 등 전반)';

  @override
  String get mentalHealthHelpline4Name => '긴급 신고';

  @override
  String get mentalHealthHelpline4Desc => '지금 당장 나 또는 다른 사람의 생명이 위험한 상황이라면';

  @override
  String get mentalHealthGlobalIntroNote =>
      '한국 이외 지역에서는 아래 국가별 상담 채널을 이용해주세요. 전세계 130개국 이상의\n상담 전화를 찾을 수 있는 글로벌 디렉토리부터 안내해요.';

  @override
  String get mentalHealthGlobalHelpline1Name => 'Find A Helpline';

  @override
  String get mentalHealthGlobalHelpline1Desc =>
      '130개국 이상의 상담 전화를 찾아주는 글로벌 디렉토리\n내가 있는 국가를 선택하면 그 나라의 상담 채널로 연결돼요';

  @override
  String get mentalHealthGlobalHelpline2Name =>
      '988 Suicide & Crisis Lifeline (US)';

  @override
  String get mentalHealthGlobalHelpline2Desc =>
      '24시간 · 미국 전화/문자 988\n미국에 있다면 이 번호로 바로 연결할 수 있어요';

  @override
  String get mentalHealthGlobalHelpline3Name => 'Crisis Text Line (US)';

  @override
  String get mentalHealthGlobalHelpline3Desc =>
      '24시간 · 미국 문자 741741로 HOME 전송\n전화가 어렵다면 문자로도 상담받을 수 있어요';

  @override
  String get mentalHealthGlobalHelpline4Name => 'SAMHSA National Helpline (US)';

  @override
  String get mentalHealthGlobalHelpline4Desc =>
      '24시간 · 미국 전화 1-800-662-4357\n약물·정신건강 관련 상담 및 지역 자원 연결';

  @override
  String get mentalHealthGlobalFooterNote =>
      '※ 위 번호 중 988/741741/SAMHSA는 미국 기준 예시이며, 다른 국가에서는 연결되지\n않을 수 있어요. 미국 외 지역이라면 Find A Helpline에서 내 국가를 선택해 현지\n상담 채널을 확인해주세요.';

  @override
  String get mentalHealthNearbyCounselingTitle => '내 주변 상담센터 찾기';

  @override
  String get mentalHealthNearbyCounselingSubtitle =>
      '전화가 망설여진다면, 가까운 곳에 직접 찾아가봐요';

  @override
  String get mentalHealthSafetyPlanTitle => '나만의 안전 계획 만들어두기';

  @override
  String get mentalHealthSafetyPlanSubtitle => '마음이 편안할 때 미리 준비해두면 힘이 돼요';

  @override
  String get mentalHealthSignsTitle => '💡 이럴 때는 꼭 도움을 요청해주세요';

  @override
  String get mentalHealthSign1 => '무기력하거나 슬픈 마음이 2주 이상 계속될 때';

  @override
  String get mentalHealthSign2 => '\"사라지고 싶다\", \"끝내고 싶다\"는 생각이 자꾸 들 때';

  @override
  String get mentalHealthSign3 => '주변 사람이 평소와 다르게 위축되거나 힘들어 보일 때';

  @override
  String get mentalHealthSign4 => '누군가에게 이야기하고 싶은데 어떻게 말해야 할지 모를 때';

  @override
  String get mentalHealthSignsFooter =>
      '이 중 하나라도 해당한다면, 그건 당신이 약해서가 아니라\n지금 조금 더 많은 도움이 필요한 순간일 뿐이에요.';

  @override
  String get mentalHealthFooterNote =>
      '※ 안내된 번호는 대한민국 보건복지부가 운영하는 공식 상담 채널이며,\n몽이 앱과 직접적인 연계 없이 독립적으로 운영됩니다. 번호가 변경될 수 있으니\n연결이 되지 않으면 포털에서 \"자살예방상담전화\"를 검색해 최신 번호를 확인해주세요.';

  @override
  String get shareFrameLabelDefault => '기본';

  @override
  String get shareFrameLabelCherry => '벚꽃';

  @override
  String get shareFrameLabelGold => '골드 별빛';

  @override
  String shareNameLabelWithTarget(String targetName, String emotionLabel) {
    return '$targetName에 대한 $emotionLabel';
  }

  @override
  String get shareCardNotFoundError => '카드를 찾을 수 없어요.';

  @override
  String get shareImageConvertError => '이미지 변환에 실패했어요.';

  @override
  String shareTextBody(String nameLabel, int count) {
    return '오늘 마음속 $nameLabel, 몽이와 함께 $count개 마주했어요 🐱🌿 #몽이 #감정일기';
  }

  @override
  String get shareErrorSnackbar => '공유 중 문제가 생겼어요. 잠시 후 다시 시도해주세요.';

  @override
  String get sharePremiumDialogTitle => '프리미엄 카드 프레임 팩 🔓';

  @override
  String get sharePremiumDialogBody =>
      '벚꽃 · 골드 별빛 프레임을 영구적으로 사용할 수 있어요.\n한 번만 구매하면 다시 결제할 필요가 없어요.';

  @override
  String get sharePremiumDialogLater => '다음에';

  @override
  String get sharePremiumDialogBuy => '구매하기';

  @override
  String get sharePurchaseProcessingSnackbar => '결제를 처리하고 있어요...';

  @override
  String get purchaseMessageWebNotSupported =>
      '웹 프리뷰에서는 인앱 결제를 테스트할 수 없어요. 안드로이드 앱에서 이용해주세요.';

  @override
  String get purchaseMessageWebRestoreNotSupported =>
      '웹 프리뷰에서는 구매 복원을 지원하지 않아요.';

  @override
  String get purchaseMessageServiceUnavailable =>
      '지금은 결제를 이용할 수 없어요. 잠시 후 다시 시도해주세요.';

  @override
  String get purchaseMessageProductNotFound =>
      '상품 정보를 불러올 수 없어요. 스토어 등록 상태를 확인해주세요.';

  @override
  String get purchaseMessageRequestFailed => '구매 요청 중 문제가 발생했어요.';

  @override
  String get purchaseMessageStoreError => '구매 중 문제가 발생했어요.';

  @override
  String get notificationTitle => '몽이 🐱';

  @override
  String get notificationChannelName => '오늘의 마음 리마인더';

  @override
  String get notificationChannelDescription => '매일 정해진 시각에 몽이가 마음을 나누자고 알려줘요.';

  @override
  String get notificationReminderMessage1 => '몽이가 오늘 하루는 어땠는지 궁금해하고 있어요 🐾';

  @override
  String get notificationReminderMessage2 => '마음속에 쌓인 감정이 있다면, 몽이에게 나눠주세요 🐱';

  @override
  String get notificationReminderMessage3 => '오늘도 몽이와 함께 마음정원을 가꿔볼까요? 🌱';

  @override
  String get notificationReminderMessage4 => '잠깐, 오늘의 감정을 몽이에게 들려주지 않을래요? 🌸';

  @override
  String get notificationReminderMessage5 => '몽이가 작은 정원에서 당신을 기다리고 있어요 🌷';

  @override
  String get shareTitle => '오늘의 감정 카드';

  @override
  String get shareSubtitle => '친구에게 오늘의 마음을 나눠보세요';

  @override
  String get sharePurchaseConfirming => '결제 확인 중...';

  @override
  String get sharePurchasePremiumButton => '프리미엄 프레임 구매하기';

  @override
  String get shareCreatingCard => '카드 만드는 중...';

  @override
  String get shareCardButton => '카드 공유하기';

  @override
  String get shareRestorePurchaseButton => '이미 구매하셨나요? 구매 복원하기';

  @override
  String get shareCardBrand => '몽이';

  @override
  String shareCardHeadlineWithCount(String nameLabel, int count) {
    return '오늘 $nameLabel\n$count개를 몽이와 함께 마주했어요';
  }

  @override
  String shareCardHeadlineNoCount(String nameLabel) {
    return '오늘 $nameLabel를\n마음속에서 잠시 마주했어요';
  }

  @override
  String shareCardComboBadge(int count) {
    return '🔥 최고 콤보 x$count';
  }

  @override
  String get shareCardNoLoveMessage => '오늘 마주한 감정만큼\n마음은 이미 조금 가벼워졌어요 🤍';

  @override
  String get shareCardPreviewBadge => '미리보기';

  @override
  String reviveFreeOfferCountLabel(int count, String total) {
    return '무료 이어하기 ($count/$total)';
  }

  @override
  String get reviveOfferHeadline => '아직 끝내기 아쉬워요!';

  @override
  String get reviveFreeOfferBody => '지금 이 판을 목숨을 가득 채워\n그대로 이어갈 수 있어요';

  @override
  String get reviveContinueButton => '이어하기 💪';

  @override
  String get reviveDeclineButton => '여기서 마칠게요';

  @override
  String get reviveAdOfferSubtitleSecondTime => '몽이가 한 번 더 부탁해요';

  @override
  String get reviveAdOfferSubtitleFirstTime => '몽이에게 두 번째 기회를 선물하기';

  @override
  String get reviveAdOfferBody =>
      '광고를 보거나, 생명의 물을 마시면\n목숨을 가득 채워 그대로 이어갈 수 있어요';

  @override
  String reviveBuyWithLightEssenceButton(int cost) {
    return '생명의 물로 바로 이어하기 (빛의 정수 $cost)';
  }

  @override
  String reviveInsufficientFunds(int lightEssence, int cost) {
    return '빛의 정수가 모자라요 (보유 $lightEssence / 필요 $cost) · 아래에서 광고를 봐도 돼요';
  }

  @override
  String get reviveWatchAdButton => '광고 보고 이어하기 🎬';

  @override
  String get reviveWatchingAdTitle => '광고를 보는 중이에요...';

  @override
  String get reviveWatchingAdSubtitle => '잠시만 기다려주세요';

  @override
  String get weekdaySun => '일';

  @override
  String get weekdayMon => '월';

  @override
  String get weekdayTue => '화';

  @override
  String get weekdayWed => '수';

  @override
  String get weekdayThu => '목';

  @override
  String get weekdayFri => '금';

  @override
  String get weekdaySat => '토';

  @override
  String get weekdayObservationNotEnoughData =>
      '기록이 조금 더 쌓이면 요일별 마음 흐름도 보여드릴게요 🌱';

  @override
  String weekdayObservationHasPattern(String bestDay, String toughestDay) {
    return '$bestDay요일엔 마음이 유독 편안했고,\n$toughestDay요일엔 조금 더 힘들었을 수 있어요. 그런 요일엔 스스로에게 조금 더 다정해도 괜찮아요 🤍';
  }

  @override
  String get weekdayObservationNoClearPattern =>
      '요일마다 마음은 조금씩 다르게 흘러가요.\n어떤 요일이든, 몽이는 늘 같은 마음으로 곁에 있어요 🤍';

  @override
  String get weeklyObservationNoData =>
      '이번 주는 아직 기록이 없어요.\n괜찮아요, 준비되면 작은 마음이라도 들려주세요 🌱';

  @override
  String weeklyObservationImprovedFromLastWeek(int deltaPercent) {
    return '지난주보다 밝은 마음이 $deltaPercent%p 늘었어요.\n스스로도 느껴지는 변화였다면, 그건 온전히 당신이 만든 거예요 ✨';
  }

  @override
  String get weeklyObservationDeclinedFromLastWeek =>
      '지난주보다 마음이 조금 더 힘든 한 주였을 수 있어요.\n애쓰지 않아도 괜찮아요, 몽이는 계속 곁에 있을게요 🤍';

  @override
  String weeklyObservationDominantPositive(String emotion) {
    return '이번 주는 유독 \"$emotion\"이(가) 가득했던 한 주였네요.\n그 좋은 기운, 몽이도 함께 느꼈어요 😊';
  }

  @override
  String weeklyObservationDominantNegative(String emotion) {
    return '이번 주는 유독 \"$emotion\"이(가) 컸던 한 주였네요.\n무슨 일이 있었는지 몽이는 궁금해요. 천천히 얘기해줘도 돼요.';
  }

  @override
  String get weeklyObservationManyNotes =>
      '이번 주는 이야기를 많이 들려줬어요.\n마음을 꺼내 보여주는 건 결코 쉬운 일이 아니에요. 몽이가 하나하나 다 기억하고 있어요 📔';

  @override
  String get weeklyObservationMostlyHeavy =>
      '마음이 조금 무거운 주였을 수도 있어요.\n그런 날에도 매일 몽이에게 와준 것, 그 자체로 참 잘한 거예요 🤍';

  @override
  String weeklyObservationDefaultTopEmotion(String emotion, int count) {
    return '이번 주 가장 자주 만난 마음은\n\"$emotion\"이었어요 ($count번). 어떤 마음이든 몽이에게는 다 소중해요.';
  }

  @override
  String get weeklyObservationDefaultThanks => '이번 주도 몽이와 함께해줘서 고마워요.';

  @override
  String get calendarHeaderTitle => '🗓️ 감정 캘린더';

  @override
  String calendarMonthLabel(int year, int month) {
    return '$year년 $month월';
  }

  @override
  String get calendarInsightNotEnoughData =>
      '이 달의 기록이 조금 더 쌓이면\n마음의 흐름을 보여드릴게요 🌱';

  @override
  String calendarInsightTitleWithTop(String label) {
    return '이달의 몽이 일기 제목: \"$label\"';
  }

  @override
  String get calendarInsightTitleFallback => '이 달의 마음 흐름 보기';

  @override
  String get calendarStatDiversityLabel => '감정 다양성';

  @override
  String calendarStatDiversityValue(int count) {
    return '$count / 15종';
  }

  @override
  String get calendarStatStreakLabel => '최장 연속 방문';

  @override
  String calendarStatStreakValue(int days) {
    return '$days일';
  }

  @override
  String get calendarWeeklyTrendTitle => '주차별 마음 흐름';

  @override
  String get calendarLegendPositive => '긍정';

  @override
  String get calendarLegendNegative => '부정';

  @override
  String get calendarWeekdayTrendTitle => '요일별 마음 흐름';

  @override
  String calendarWeekLabel(int week) {
    return '$week주';
  }

  @override
  String get calendarEmptyMonth => '이번 달엔 아직 기록이 없어요.\n감정을 마주하고 나면 여기에 쌓여요 🌱';

  @override
  String get calendarMonthSummaryTitle => '이번 달의 마음 요약';

  @override
  String calendarMonthSummaryTopEmotion(String emotion, String icon) {
    return '가장 많이 마주한 감정은 \"$emotion\"이에요 $icon';
  }

  @override
  String calendarMonthSummaryTotal(int count) {
    return '이번 달 총 $count번, 마음을 꺼내 보여줬어요.\n어떤 마음이든 다 괜찮아요, 몽이는 늘 곁에 있어요.';
  }

  @override
  String get calendarMonthDistributionTitle => '이 달의 감정 수치';

  @override
  String calendarMonthDistributionPercent(int percent) {
    return '$percent%';
  }

  @override
  String get calendarMonthAnalysisTitle => '이 달의 가벼운 분석';

  @override
  String get monthlyObservationNoData =>
      '이 달은 아직 기록이 조금 더 필요해요.\n괜찮아요, 천천히 채워가요 🌱';

  @override
  String monthlyObservationImprovedFromLastMonth(int deltaPercent) {
    return '지난달보다 밝은 마음이 $deltaPercent%p 늘었어요.\n한 달 동안 쌓인 그 변화, 몽이도 함께 지켜봤어요 ✨';
  }

  @override
  String get monthlyObservationDeclinedFromLastMonth =>
      '지난달보다 마음이 조금 더 힘들었던 한 달일 수 있어요.\n애쓰지 않아도 괜찮아요, 몽이는 계속 곁에 있을게요 🤍';

  @override
  String monthlyObservationDominantPositive(String emotion, int percent) {
    return '이 달은 유독 \"$emotion\"이(가) 가득했던 한 달이었어요 ($percent%).\n그 좋은 기운, 몽이도 함께 느꼈어요 😊';
  }

  @override
  String monthlyObservationDominantNegative(String emotion, int percent) {
    return '이 달은 유독 \"$emotion\"이(가) 컸던 한 달이었어요 ($percent%).\n무슨 일이 있었는지 몽이는 궁금해요. 천천히 얘기해줘도 돼요.';
  }

  @override
  String monthlyObservationDiverseEmotions(int count) {
    return '이 달은 $count가지나 되는 다양한 마음을 만났어요.\n하나의 감정에 머무르지 않았다는 것, 그 자체로 마음이 유연했다는 뜻이에요 🎨';
  }

  @override
  String get monthlyObservationMostlyHeavy =>
      '마음이 조금 무거운 한 달이었을 수도 있어요.\n그런 날에도 매일 몽이에게 와준 것, 그 자체로 참 잘한 거예요 🤍';

  @override
  String monthlyObservationDefaultTopEmotion(String emotion, int count) {
    return '이 달 가장 자주 만난 마음은\n\"$emotion\"이었어요 ($count번). 어떤 마음이든 몽이에게는 다 소중해요.';
  }

  @override
  String get monthlyObservationDefaultThanks => '이 달도 몽이와 함께해줘서 고마워요.';

  @override
  String calendarDayDetailTitle(int day) {
    return '$day일의 기록';
  }

  @override
  String calendarIntensityLabel(String dots) {
    return '강도 $dots';
  }

  @override
  String seasonPassAppBarTitle(int seasonNumber) {
    return '시즌 $seasonNumber · 몽이의 마음여정';
  }

  @override
  String get seasonPassSubHeadline =>
      '게임을 하지 않아도, 매일 체크인하거나 감사 기록을 남기는 것만으로도\n마음여정이 조금씩 앞으로 나아가요 🌿';

  @override
  String seasonPassCountdownDays(int days, int hours) {
    return '$days일 $hours시간 남음';
  }

  @override
  String seasonPassCountdownHours(int hours, int minutes) {
    return '$hours시간 $minutes분 남음';
  }

  @override
  String seasonPassCountdownMinutes(int minutes) {
    return '$minutes분 남음';
  }

  @override
  String get seasonPassPurchaseDialogTitle => '시즌 패스 프리미엄 🌟';

  @override
  String get seasonPassPurchaseDialogBody =>
      '이번 시즌 동안 모든 레벨에서 훨씬 풍성한 보상을 받을 수 있어요.\n지금까지 쌓은 레벨의 프리미엄 보상도 곧바로 모두 받을 수 있어요.';

  @override
  String get seasonPassRestoreConfirmedSnackbar =>
      '구매 내역을 확인했어요. 이미 구매하셨다면 잠시 후 반영돼요.';

  @override
  String seasonPassFreeRewardClaimedSnackbar(int level) {
    return '레벨 $level 무료 보상을 받았어요!';
  }

  @override
  String seasonPassPremiumRewardClaimedSnackbar(int level) {
    return '레벨 $level 프리미엄 보상을 받았어요!';
  }

  @override
  String seasonPassLevelLabel(int level) {
    return '레벨 $level';
  }

  @override
  String seasonPassLevelLabelMax(int level) {
    return '레벨 $level (최고 레벨)';
  }

  @override
  String get seasonPassFreeTierBadge => '무료';

  @override
  String get seasonPassPremiumTierBadge => '💎 프리미엄';

  @override
  String get seasonPassMaxLevelReached => '모든 레벨을 다 채웠어요!';

  @override
  String seasonPassXpProgress(int xpInto, int span) {
    return '$xpInto / $span xp';
  }

  @override
  String get seasonPassMindMilestoneBadge => '🌿 마음 마일스톤';

  @override
  String seasonPassTierLevelLabel(int level) {
    return 'Lv.$level';
  }

  @override
  String get seasonPassClaimButton => '받기 →';

  @override
  String get seasonPassOwnedBanner => '✅ 프리미엄 패스 보유 중';

  @override
  String get seasonPassUpgradeButton => '💎 프리미엄 패스로 업그레이드';

  @override
  String seasonRewardFinaleLabel(
    int lightEssence,
    int starShard,
    String costumeName,
  ) {
    return '빛의 정수 $lightEssence개 + 별조각 $starShard개 + 확정 코스튬 \"$costumeName\"';
  }

  @override
  String seasonRewardWithShardLabel(int lightEssence, int starShard) {
    return '빛의 정수 $lightEssence개 + 별조각 $starShard개';
  }

  @override
  String seasonRewardLightOnlyLabel(int lightEssence) {
    return '빛의 정수 $lightEssence개';
  }

  @override
  String get nearbyHeaderTitle => '📍 내 주변 상담센터';

  @override
  String get nearbySectionTitle => '🗺️ 어떤 곳을 찾고 있나요?';

  @override
  String get nearbyIntroCardBody =>
      '전화가 아직 망설여진다면, 가까운 곳에 직접 찾아가 이야기를\n나눠보는 것도 좋은 방법이에요. 아래에서 원하는 기관을 고르면\n지도 앱으로 내 주변에 있는 곳을 바로 찾아드려요.';

  @override
  String get nearbyOfficialPortalTitle => '국가정신건강정보포털에서 전체 목록 보기';

  @override
  String get nearbyOfficialPortalSubtitle => '보건복지부 공식 기관 찾기 서비스로 이동해요';

  @override
  String get nearbyGlobalOfficialPortalTitle =>
      'Find A Helpline에서 내 국가의 상담 채널 보기';

  @override
  String get nearbyGlobalOfficialPortalSubtitle =>
      '130개국 이상의 상담 채널을 찾을 수 있는 글로벌 디렉토리로 이동해요';

  @override
  String get nearbyCenterMentalHealthMapQueryGlobal => 'mental health clinic';

  @override
  String get nearbyCenterYouthMapQueryGlobal => 'youth counseling center';

  @override
  String get nearbyCenterSuicidePreventionMapQueryGlobal => 'crisis center';

  @override
  String get nearbyCenterPsychiatricMapQueryGlobal => 'psychiatrist';

  @override
  String get nearbyFooterNote =>
      '※ 지도 검색 결과는 Google 지도가 제공하며, 실제 운영시간/이용조건은\n방문 전 각 기관에 직접 확인하는 것을 권장해요.';

  @override
  String get nearbyMapOpenFailedSnackbar => '지도 앱을 여는 데 실패했어요.';

  @override
  String get nearbyPortalOpenFailedSnackbar => '페이지를 여는 데 실패했어요.';

  @override
  String get nearbyCenterMentalHealthName => '정신건강복지센터';

  @override
  String get nearbyCenterMentalHealthDesc =>
      '누구나 무료로 이용할 수 있는 지역 상담기관. 우울/불안 등\n마음 어려움 전반에 대한 상담과 지원을 받을 수 있어요.';

  @override
  String get nearbyCenterYouthName => '청소년상담복지센터';

  @override
  String get nearbyCenterYouthDesc =>
      '만 9~24세 청소년을 위한 무료 상담기관.\n학업, 관계, 가정 문제 등을 편하게 상담할 수 있어요.';

  @override
  String get nearbyCenterSuicidePreventionName => '자살예방센터';

  @override
  String get nearbyCenterSuicidePreventionDesc =>
      '위기 상황에 대한 전문적인 개입과 사후관리를 지원하는\n지역 자살예방 전담기관.';

  @override
  String get nearbyCenterPsychiatricName => '정신건강의학과 의원';

  @override
  String get nearbyCenterPsychiatricDesc =>
      '약물치료나 전문적인 진단이 필요할 수 있다고 느껴질 때,\n가까운 병원을 먼저 찾아볼 수 있어요.';

  @override
  String get nearbyCenterMentalHealthMapQuery => '정신건강복지센터';

  @override
  String get nearbyCenterYouthMapQuery => '청소년상담복지센터';

  @override
  String get nearbyCenterSuicidePreventionMapQuery => '자살예방센터';

  @override
  String get nearbyCenterPsychiatricMapQuery => '정신건강의학과';

  @override
  String get mindReportHeaderTitle => '💗 마음 리포트';

  @override
  String get mindReportIntroText =>
      '몽이와 함께 마주한 마음들을 한눈에 모아봤어요.\n숫자보다, 그 마음들을 알아채준 당신이 더 대단해요.';

  @override
  String get mindReportSupportAlertTitle => '요즘 마음이 많이 무거웠나 봐요';

  @override
  String get mindReportSupportAlertBody =>
      '혼자 견디지 않아도 괜찮아요. 언제든 이야기 나눌 곳이 있어요.';

  @override
  String get mindReportSupportEntryLabel => '마음이 힘들 때 - 상담 안내 보기';

  @override
  String get mindReportWeeklyTitle => '이번 주 몽이의 관찰';

  @override
  String mindReportWeeklyPositiveLabel(int percent) {
    return '긍정 $percent%';
  }

  @override
  String mindReportWeeklySessionsLabel(int count) {
    return '· 함께한 $count번';
  }

  @override
  String get mindReportWeeklyNotEnoughData => '아직 데이터가 모이고 있어요. 조금 더 함께해주세요 🌱';

  @override
  String get mindReportMonthlyTitle => '이번 달 마음 흐름';

  @override
  String mindReportMonthlyTopEmotion(String emotion) {
    return '가장 많이 만난 마음은 \"$emotion\"이에요';
  }

  @override
  String get mindReportMonthlyNoTopEmotion => '이 달의 마음 흐름을 보여드릴게요';

  @override
  String mindReportMonthlyStreak(int days) {
    return '🔥 $days일';
  }

  @override
  String get mindReportMonthlyNotEnoughData =>
      '이 달의 기록이 조금 더 쌓이면 마음의 흐름을 보여드릴게요 🌱';

  @override
  String get mindReportWeekdayTitle => '요일별 마음 흐름';

  @override
  String get mindReportTriggerTitle => '마음의 원인';

  @override
  String get mindReportTriggerNotEnoughData =>
      '감정을 기록할 때 \"무엇 때문이었을까요?\"에 몇 번 더 답해주시면, 마음의 원인 패턴도 보여드릴게요 🌱';

  @override
  String triggerInsightDominantNegativeCause(String trigger, int count) {
    return '최근엔 유독 \"$trigger\" 때문에 마음이 힘들었을 수 있어요.\n$count번이나 그 마음의 곁에 있었네요. 알아챈 것만으로도 이미 잘하고 있는 거예요 🤍';
  }

  @override
  String triggerInsightTopTrigger(String trigger, int count) {
    return '최근 마음에 가장 자주 영향을 준 건 \"$trigger\"였어요 ($count번).\n스스로도 몰랐던 패턴을 알아챈 걸지도 몰라요.';
  }

  @override
  String get emotionTriggerWorkStudy => '일/학업';

  @override
  String get emotionTriggerRelationship => '관계';

  @override
  String get emotionTriggerFamily => '가족';

  @override
  String get emotionTriggerHealth => '건강';

  @override
  String get emotionTriggerMoney => '돈';

  @override
  String get emotionTriggerSleep => '잠/피로';

  @override
  String get emotionTriggerAlone => '혼자 있음';

  @override
  String get emotionTriggerSns => 'SNS';

  @override
  String get emotionTriggerWeather => '날씨';

  @override
  String get emotionTriggerFuture => '미래 걱정';

  @override
  String get emotionTriggerAchievement => '작은 성취';

  @override
  String get emotionTriggerEtc => '그 외';

  @override
  String get mindReportGratitudeTitle => '감사 & 작은 성취';

  @override
  String get mindReportGratitudeEmpty => '아직 기록이 없어요';

  @override
  String mindReportGratitudeCount(int count) {
    return '$count개의 기록';
  }

  @override
  String get mindReportGratitudeDoneToday => '오늘 남겼어요 ✓';

  @override
  String get mindReportCollectionTitle => '감정 도감';

  @override
  String get mindReportDiaryTitle => '감정 다이어리';

  @override
  String mindReportDiaryCount(int count) {
    return '$count개의 이야기';
  }

  @override
  String get collectionHeaderTitle => '📖 감정 도감';

  @override
  String get collectionNegativeSectionTitle => '🌧️ 마주한 마음들 (10종)';

  @override
  String get collectionPositiveSectionTitle => '🌟 품은 마음들 (5종)';

  @override
  String get collectionProgressCompleteText => '15가지 마음을 모두 만났어요! 대단해요 🎉';

  @override
  String collectionProgressPartialText(int count) {
    return '지금까지 $count가지 마음을 만났어요';
  }

  @override
  String get collectionProgressHint => '자주 마주할수록 몬스터가 진화해요 (5번·20번·50번)';

  @override
  String collectionGoldenFrameCount(int count) {
    return '황금 프레임 $count개 보유중!';
  }

  @override
  String get collectionGoldenFrameEarned => '🏆 황금 프레임 획득!';

  @override
  String get collectionTranscendedBadge => '🌌 초월한 마음';

  @override
  String get collectionTranscendedRank => '초월 등급';

  @override
  String get collectionMasteredRank => '마스터 등급';

  @override
  String collectionStageRank(int stage) {
    return '$stage단계';
  }

  @override
  String collectionMetCountLabel(int count) {
    return '지금까지 $count번 마주했어요';
  }

  @override
  String collectionNextEvolutionHint(int remaining, String nextName) {
    return '$remaining번 더 마주하면 \"$nextName\"(으)로 진화해요';
  }

  @override
  String get collectionTranscendedMessage =>
      '백 번의 마주침 끝에 완전히 다른 존재가 됐어요.\n아무도 예고해주지 않았던, 오직 당신만의 발견이에요 🌌';

  @override
  String get collectionMasteredMessage =>
      '완전히 진화했어요! 이제부터 마주할 때마다\n아주 낮은 확률로 황금 프레임을 얻을 수 있어요 ✨';

  @override
  String get commonCloseButton => '닫기';

  @override
  String gardenShareShareText(String label) {
    return '몽이의 성장나무가 지금 $label 단계예요 🌳 매일 마음을 돌보며 함께 자라고 있어요 #몽이 #마음정원';
  }

  @override
  String get gardenShareSheetTitle => '몽이의 정원 공유 카드 🌳';

  @override
  String get gardenShareSheetSubtitle => '지금까지 함께 가꾼 정원을 자랑해보세요';

  @override
  String get gardenShareCardMakingButton => '카드 만드는 중...';

  @override
  String get gardenShareCardButton => '카드 공유하기';

  @override
  String get gardenShareCardName => '몽이의 정원';

  @override
  String gardenShareCardGrownLabel(String label) {
    return '지금 $label 단계로 자라났어요';
  }

  @override
  String get gardenShareCardNotGrownLabel => '아직 씨앗을 심기 전이에요';

  @override
  String gardenShareCardStreakStat(int days) {
    return '$days일';
  }

  @override
  String get gardenShareCardStreakLabel => '연속';

  @override
  String gardenShareCardFlowersStat(int count) {
    return '$count송이';
  }

  @override
  String get gardenShareCardFlowersLabel => '피운 꽃';

  @override
  String gardenShareCardScoreStat(int score) {
    return '$score점';
  }

  @override
  String get gardenShareCardScoreLabel => '점수';

  @override
  String get gardenShareCardFooter => '매일 마음을 돌보며\n조금씩 자라나는 중이에요 🌱';

  @override
  String get milestoneHeaderTitle => '🎬 몽이의 성장 다큐멘터리';

  @override
  String get milestoneIntroTitle => '몽이의 나무가 마침내\n열매를 맺었어요 🍎';

  @override
  String get milestoneIntroBody =>
      '작은 씨앗이었던 몽이가\n그동안 마주한 마음들 덕분에 이렇게 자랐어요.\n함께 걸어온 길을 잠시 돌아볼까요?';

  @override
  String get milestoneTimelineTitle => '몽이와 함께한 이야기';

  @override
  String get milestoneStreakLabel => '최근 연속';

  @override
  String get milestoneScoreLabel => '누적 점수';

  @override
  String get milestoneDiaryCountLabel => '남긴 이야기';

  @override
  String milestoneDiaryCountStat(int count) {
    return '$count개';
  }

  @override
  String get milestoneInsightTitle => '이 나무와 함께한 마음들';

  @override
  String milestoneEmotionCountLabel(String label, int count) {
    return '$label $count번';
  }

  @override
  String milestoneImprovedText(String label) {
    return '처음엔 $label을(를) 자주 만났는데,\n최근엔 훨씬 줄었어요. 마음이 조금 편해졌나 봐요.';
  }

  @override
  String milestoneUncollectedText(int count) {
    return '아직 만나지 못한 마음이 $count가지 있어요.\n다음 나무에서 만나볼까요? 🌳';
  }

  @override
  String get milestoneEmptyTimelineText =>
      '아직 남겨진 한 줄 이야기는 없지만,\n마주한 감정들이 모여 이 나무를 키워냈어요 🌳';

  @override
  String get milestoneClosingQuote =>
      '\"고마워, 나를 여기까지 데려와줘서.\n앞으로도 어떤 마음이든\n네 옆에서 함께 지켜볼게.\"';

  @override
  String get milestoneShareButtonLabel => '이 순간을 카드로 공유하기';

  @override
  String milestoneTimelineDateCount(String date, int count) {
    return '$date · $count개';
  }

  @override
  String milestoneTimelineNoteQuote(String note) {
    return '\"$note\"';
  }

  @override
  String get breathingPromptText => '잠깐, 몽이와 함께 숨을 천천히 골라볼까요?';

  @override
  String get breathingInhaleLabel => '들이쉬고...';

  @override
  String get breathingExhaleLabel => '내쉬고...';

  @override
  String get breathingHoldLabel => '멈추고...';

  @override
  String get weeklyReportShareText => '이번 주 몽이와 함께한 감정 리포트예요 🌱 #몽이 #마음정원';

  @override
  String get weeklyReportShareButton => '이번 주 리포트 공유하기';

  @override
  String get weeklyReportNotEnoughTitle => '아직 데이터가 모이고 있어요';

  @override
  String get weeklyReportNotEnoughBody => '몽이와 조금 더 함께해주면\n이번 주 이야기를 들려드릴게요';

  @override
  String weeklyReportSessionsLabel(int count) {
    return '함께한 $count번';
  }

  @override
  String get weeklyReportEmotionsSectionTitle => '이번 주 만난 마음들';

  @override
  String weeklyReportEmotionTag(String icon, String label, int count) {
    return '$icon $label $count';
  }

  @override
  String weeklyReportNegativeLabel(int percent) {
    return '부정 $percent%';
  }

  @override
  String weeklyReportPreviousRatioLabel(int percent) {
    return '지난주 긍정 비율: $percent%';
  }

  @override
  String get gardenDecoSheetTitle => '🎨 정원 꾸미기';

  @override
  String get gardenDecoSheetSubtitle => '잠금 해제된 아이템을 탭해서 장착/해제할 수 있어요';

  @override
  String get gardenDecoFreeSectionLabel => '무료 아이템 · 마일스톤 달성으로 잠금 해제';

  @override
  String get gardenDecoPremiumSectionLabel => '프리미엄 아이템 · 정원 장식팩';

  @override
  String get gardenDecoRestoreButton => '이전 구매 복원하기';

  @override
  String get gardenDecoProBadge => 'PRO';

  @override
  String get gardenDecoEquippedStatus => '지금 정원에 놓여 있어요';

  @override
  String get gardenDecoTapToPlaceStatus => '탭해서 정원에 놓아보세요';

  @override
  String gardenDecoProgressBadge(String progress) {
    return '📍 $progress';
  }

  @override
  String gardenDecoProgressBench(int days) {
    return '3일 연속 중 $days일째';
  }

  @override
  String gardenDecoProgressPath(int percent) {
    return '마음정원 회복도 $percent% (100%가 되면 해제)';
  }

  @override
  String gardenDecoProgressFountainPlanted(int planted) {
    return '$planted/3종 심음';
  }

  @override
  String gardenDecoProgressFountainWithMissing(int planted, String missing) {
    return '$planted/3종 심음 · 남은 씨앗: $missing';
  }

  @override
  String get gardenSeedNameForgiveness => '용서';

  @override
  String get gardenSeedNameLove => '사랑';

  @override
  String get gardenSeedNamePeace => '평안';

  @override
  String get gardenSeedDescForgiveness => '마음에 맺힌 것을 놓아주는 씨앗';

  @override
  String get gardenSeedDescLove => '따뜻함을 나누는 씨앗';

  @override
  String get gardenSeedDescPeace => '고요하고 잔잔한 마음의 씨앗';

  @override
  String get gardenDecoLabelBench => '나무 벤치';

  @override
  String get gardenDecoUnlockHintBench => '3일 연속 몽이를 만나면 잠금 해제돼요';

  @override
  String get gardenDecoLabelPath => '조약돌 오솔길';

  @override
  String get gardenDecoUnlockHintPath => '정원을 처음 만개시키면 잠금 해제돼요';

  @override
  String get gardenDecoLabelFountain => '작은 분수대';

  @override
  String get gardenDecoUnlockHintFountain => '용서·사랑·평안 씨앗을 모두 심으면 잠금 해제돼요';

  @override
  String get gardenDecoLabelLantern => '종이등';

  @override
  String get gardenDecoLabelRainbowFence => '무지개 울타리';

  @override
  String get gardenDecoLabelStarLight => '반짝이는 별빛';

  @override
  String get gardenDecoUnlockHintPremiumPack => '정원 장식팩을 구매하면 사용할 수 있어요';

  @override
  String get gardenDecoLabelWindChime => '풍경 윈드차임';

  @override
  String get gardenDecoUnlockHintWindChime => '7일 연속 몽이를 만나면 잠금 해제돼요';

  @override
  String get gardenDecoLabelButterflyGarden => '나비 정원';

  @override
  String get gardenDecoUnlockHintButterflyGarden =>
      '감정을 3개 이상 마스터 등급으로 키우면 잠금 해제돼요';

  @override
  String get gardenDecoLabelGazebo => '아늑한 정자';

  @override
  String get gardenDecoLabelLotusPond => '연꽃 연못';

  @override
  String get gardenDecoLabelJangdokdae => '장독대';

  @override
  String get gardenDecoUnlockHintJangdokdae => '꽃을 10번 이상 피우면 잠금 해제돼요';

  @override
  String get gardenDecoLabelGinkgoPath => '은행나무길';

  @override
  String get gardenDecoUnlockHintGinkgoPath => '14일 연속 몽이를 만나면 잠금 해제돼요';

  @override
  String get gardenDecoLabelHanokLantern => '한옥 처마등';

  @override
  String gardenDecoUnlockHintWithProgress(String hint, String progress) {
    return '$hint\n(현재: $progress)';
  }

  @override
  String get gardenDecoPurchaseDialogTitle => '정원 장식팩 구매';

  @override
  String get gardenDecoPurchaseDialogBody =>
      '종이등 🏮 · 무지개 울타리 🌈 · 반짝이는 별빛 ✨\n3가지 장식을 한 번에 잠금 해제해서 몽이의 정원을 더 예쁘게 꾸며보세요.\n\n한 번 구매하면 계속 사용할 수 있어요.';

  @override
  String get gardenDecoPurchaseFailedSnackbar =>
      '결제를 시작할 수 없어요. 잠시 후 다시 시도해주세요.';

  @override
  String get mindBoxAllCollectedSnackbar => '🎉 몽이의 선물을 이미 모두 모았어요!';

  @override
  String get mindBoxNotEnoughEssenceSnackbar =>
      '💡 빛의 정수가 부족해요. 엔드리스 모드로 더 모아볼까요?';

  @override
  String get mindBoxHeaderTitle => '🎁 마음 상자';

  @override
  String get mindBoxAllCollectedTitle => '🎉 몽이의 선물을 모두 모았어요!';

  @override
  String get mindBoxOpenHintTitle => '상자를 열면 항상 새로운 선물을 만나요';

  @override
  String mindBoxCollectionProgressLabel(int owned, int total, int totalPulls) {
    return '도감 $owned / $total · 지금까지 연 상자 $totalPulls개';
  }

  @override
  String get mindBoxOpenOneButton => '상자 1개 열기';

  @override
  String mindBoxOpenBulkButtonCount(int count) {
    return '상자 $count개 열기';
  }

  @override
  String get mindBoxOpenBulkButtonGeneric => '상자 여러 개 열기';

  @override
  String get mindBoxCollectionSectionTitle => '🐾 몽이 코스튬 도감';

  @override
  String get mindBoxEquippedBadge => '장착중';

  @override
  String get mindBoxResultTitleLegendary => '🌟 정말 특별한 선물이 왔어요!';

  @override
  String get mindBoxResultTitleNormal => '🎁 마음 상자를 열었어요';

  @override
  String get mindBoxConfirmButton => '확인';

  @override
  String get mindBoxNewItemLabel => '✨ NEW! 새로운 옷을 얻었어요';

  @override
  String get mindBoxRarityCommon => '일반';

  @override
  String get mindBoxRarityRare => '레어';

  @override
  String get mindBoxRarityEpic => '에픽';

  @override
  String get mindBoxRarityLegendary => '레전더리';

  @override
  String get mongiCostumeNameRibbon => '핑크 리본';

  @override
  String get mongiCostumeNameStarBand => '별빛 머리띠';

  @override
  String get mongiCostumeNameScarf => '무지개 목도리';

  @override
  String get mongiCostumeNameBunnyEars => '토끼 귀 머리띠';

  @override
  String get mongiCostumeNameFlowerCrown => '데이지 화관';

  @override
  String get mongiCostumeNameWizardHat => '별빛 마법사 모자';

  @override
  String get mongiCostumeNameGoldenCrown => '황금 왕관';

  @override
  String get mongiCostumeNameCloudBand => '뭉게구름 머리띠';

  @override
  String get mongiCostumeNameSunflowerBand => '해바라기 머리띠';

  @override
  String get mongiCostumeNameAngelWings => '천사의 날개';

  @override
  String get mongiCostumeNamePirateHat => '꼬마 해적 모자';

  @override
  String get mongiCostumeNameGalaxyCape => '은하수 망토';

  @override
  String get mongiCostumeNamePhoenixCrown => '불사조의 왕관';

  @override
  String get mongiCostumeNameSaekdongRibbon => '색동 리본';

  @override
  String get mongiCostumeNameBokjumeoni => '복주머니 머리띠';

  @override
  String get mongiCostumeNameSproutHat => '새싹 머리띠';

  @override
  String endlessResultTimeMinSec(int minutes, int seconds) {
    return '$minutes분 $seconds초';
  }

  @override
  String endlessResultTimeSecOnly(int seconds) {
    return '$seconds초';
  }

  @override
  String get endlessResultNewRecordBadge => '🏆 오늘 새로운 최고 기록!';

  @override
  String get endlessResultCardTitle => '오늘의 도전 결과';

  @override
  String get endlessResultEatenCountLabel => '마주한 감정';

  @override
  String endlessResultEatenCountValue(int count) {
    return '$count개';
  }

  @override
  String get endlessResultSurvivedTimeLabel => '생존 시간';

  @override
  String get endlessResultBestRecordLabel => '👑 내 최고기록';

  @override
  String endlessResultBestRecordValue(int count, String time) {
    return '$count개 · $time';
  }

  @override
  String get endlessResultRankingFooter =>
      '순위보다 소중한 건, 오늘도\n몽이와 함께 마음을 마주한 시간이에요 🤍';

  @override
  String get endlessResultRetryButton => '다시 도전하기 🐾';

  @override
  String dailyMissionClaimedSnackbar(String emoji, int amount) {
    return '$emoji 빛의 정수 +$amount 받았어요!';
  }

  @override
  String get dailyMissionAllClearSnackbar => '🎉 올클리어 보너스를 받았어요!';

  @override
  String get dailyMissionSheetLabel => '몽이의 오늘 미션';

  @override
  String dailyMissionLabelEatEmotions(int target) {
    return '감정 몬스터 $target개 마주하기';
  }

  @override
  String dailyMissionLabelCompleteStage(int target) {
    return '스테이지 $target번 끝까지 완료하기';
  }

  @override
  String dailyMissionLabelPlantLove(int target) {
    return '마음 $target번 심기';
  }

  @override
  String get dailyMissionSheetTitle => '오늘 하루, 이만큼만 더 함께해요';

  @override
  String dailyMissionProgressWithReward(int progress, int target, int reward) {
    return '$progress / $target  ·  💡+$reward';
  }

  @override
  String get dailyMissionClaimButton => '받기';

  @override
  String get dailyMissionAllClearCardTitle => '올클리어 보너스';

  @override
  String get dailyMissionAllClearAlreadyClaimed => '오늘 이미 받았어요, 내일 또 만나요!';

  @override
  String dailyMissionAllClearProgress(
    int claimed,
    int total,
    int lightEssence,
    int starShard,
  ) {
    return '미션 $claimed/$total 완료 · 💡+$lightEssence ⭐+$starShard';
  }

  @override
  String get safetyPlanSavedSnackbar => '저장했어요 🤍';

  @override
  String get safetyPlanCallFailedSnackbar => '전화 연결에 실패했어요. 109로 직접 걸어주세요.';

  @override
  String get safetyPlanHeaderTitle => '🧭 나만의 안전 계획';

  @override
  String get safetyPlanIntroLine1 =>
      '마음이 편안한 지금, 미래의 나를 위해\n짧은 메모를 미리 남겨두는 공간이에요.';

  @override
  String get safetyPlanIntroLine2 =>
      '나중에 마음이 힘들어졌을 때, 무엇부터 해야 할지 떠올리기 어려운 순간이\n있어요. 그럴 때 이 페이지를 펼쳐보면 스스로 적어둔 답을 바로 볼 수 있어요.\n작성한 내용은 이 기기에만 저장되고, 몽이도 다른 누구도 보지 않아요.';

  @override
  String get safetyPlanSaveButton => '저장';

  @override
  String safetyPlanTapToWriteHint(String placeholder) {
    return '$placeholder\n(눌러서 작성하기)';
  }

  @override
  String get safetyPlanEmergencyTitle => '지금 당장 힘들다면';

  @override
  String get safetyPlanEmergencySubtitle => '109(자살예방상담전화)로 바로 연결할게요';

  @override
  String get safetyPlanGlobalEmergencySubtitle =>
      'Find A Helpline에서 내 국가의 상담 채널을 바로 찾아드릴게요';

  @override
  String get safetyPlanGlobalButtonLabel => '열기';

  @override
  String get safetyPlanGlobalOpenFailedSnackbar =>
      '페이지를 여는 데 실패했어요. findahelpline.com으로 직접 방문해주세요.';

  @override
  String get safetyPlanSectionWarningSignsTitle => '나에게 위험 신호가 되는 것들';

  @override
  String get safetyPlanSectionWarningSignsHint =>
      '이런 생각·기분·상황이 나타나면 \"지금 조심해야 할 때\"라는 뜻이에요.';

  @override
  String get safetyPlanSectionWarningSignsPlaceholder =>
      '예) 며칠째 잠을 못 잘 때, \"다 소용없다\"는 생각이 들 때...';

  @override
  String get safetyPlanSectionCopingStrategiesTitle => '혼자서 마음을 가라앉히는 나만의 방법';

  @override
  String get safetyPlanSectionCopingStrategiesHint =>
      '다른 사람 도움 없이도 스스로 해볼 수 있는 것들이에요.';

  @override
  String get safetyPlanSectionCopingStrategiesPlaceholder =>
      '예) 좋아하는 노래 듣기, 산책하기, 몽이랑 감정 정리하기...';

  @override
  String get safetyPlanSectionSupportPeopleTitle => '도움을 요청할 수 있는 사람들';

  @override
  String get safetyPlanSectionSupportPeopleHint =>
      '이름과 연락처를 적어두면, 힘든 순간에 찾아보기 쉬워져요.';

  @override
  String get safetyPlanSectionSupportPeoplePlaceholder =>
      '예) 친구 OOO (010-xxxx-xxxx), 언니, 상담 선생님...';

  @override
  String get safetyPlanSectionSafePlaceTitle => '마음이 편안해지는 장소';

  @override
  String get safetyPlanSectionSafePlaceHint => '잠깐이라도 머물면 마음이 조금 놓이는 곳이 있나요?';

  @override
  String get safetyPlanSectionSafePlacePlaceholder =>
      '예) 동네 카페, 가족이 있는 집, 근처 공원 벤치...';

  @override
  String get safetyPlanSectionReasonsToLiveTitle => '나에게 소중한 것들 / 살아야 할 이유';

  @override
  String get safetyPlanSectionReasonsToLiveHint =>
      '힘든 순간일수록 잊기 쉬운, 나에게 정말 소중한 것들을 적어두세요.';

  @override
  String get safetyPlanSectionReasonsToLivePlaceholder =>
      '예) 우리 강아지, 내년에 가고 싶은 여행, 사랑하는 가족...';

  @override
  String get powerCharmBoughtOneSnackbar => '⚡ 파워 부적 1개를 얻었어요!';

  @override
  String powerCharmBoughtBulkSnackbar(int count) {
    return '⚡ 파워 부적 $count개를 얻었어요!';
  }

  @override
  String get powerCharmNotEnoughSnackbar => '💡 빛의 정수가 부족해요.';

  @override
  String get powerCharmTitle => '파워 부적';

  @override
  String powerCharmDescription(int count) {
    return '게임 중 언제든 써서 10초간 무적이 돼요\n지금 보유: $count개';
  }

  @override
  String get powerCharmBuyOneLabel => '부적 1개';

  @override
  String powerCharmBuyBulkLabel(int count) {
    return '부적 $count개';
  }

  @override
  String get breathingMomentTitle => '숨결 구슬을 만났어요';

  @override
  String get breathingMomentInhaleLabel => '들이쉬며 꾹 눌러요';

  @override
  String get breathingMomentExhaleLabel => '내쉬며 손을 떼요';

  @override
  String get breathingLibraryHeaderTitle => '🌬️ 몽이의 숨결 도감';

  @override
  String get breathingLibrarySubtitle => '지금 마음에 맞는 호흡을 골라 몽이와 천천히 따라해보세요.';

  @override
  String breathingLibraryDurationLabel(int seconds) {
    return '약 $seconds초';
  }

  @override
  String get breathingLibraryStartButton => '시작하기';

  @override
  String get breathingLibraryCompletedTodayBadge => '오늘 완료 ✓';

  @override
  String breathingLibraryRewardHint(int reward) {
    return '오늘 처음 끝까지 마치면 💡$reward 지급';
  }

  @override
  String breathingLibraryRewardSnackbar(int reward) {
    return '잘했어요 🌿 오늘의 첫 호흡 보상으로 💡$reward를 받았어요!';
  }

  @override
  String get breathingLibraryNoRewardSnackbar =>
      '천천히 잘 따라했어요 🌿 (보상은 하루에 한 번만 받을 수 있어요)';

  @override
  String get breathingTechniqueNameCalmBreath => '차분한 숨';

  @override
  String get breathingTechniqueDescCalmBreath =>
      '들이쉬고 내쉬기만 반복하는 가장 기본적인 호흡이에요. 언제든 편하게 시작해보세요.';

  @override
  String get breathingTechniqueNameAnxietyRelief => '불안을 가라앉히는 숨';

  @override
  String get breathingTechniqueDescAnxietyRelief =>
      '4초 들이쉬고, 7초 멈추고, 8초 길게 내쉬어요. 마음이 조급할 때 특히 도움이 돼요.';

  @override
  String get breathingTechniqueNameBoxBreathing => '집중을 위한 박스 호흡';

  @override
  String get breathingTechniqueDescBoxBreathing =>
      '들이쉬고, 멈추고, 내쉬고, 멈추기를 똑같은 길이로 반복해요. 흐트러진 집중을 다잡아줘요.';

  @override
  String get breathingTechniqueNameSleepWindDown => '잠들기 전 숨결';

  @override
  String get breathingTechniqueDescSleepWindDown =>
      '천천히 들이쉬고 아주 길게 내쉬며, 하루의 긴장을 몸에서 스르르 내려놓아요.';

  @override
  String get breathingTechniqueNameEnergizingBreath => '생기를 깨우는 숨';

  @override
  String get breathingTechniqueDescEnergizingBreath =>
      '들이쉬고 살짝 멈춘 뒤, 산뜻하게 내쉬기를 조금 빠른 리듬으로 반복해요. 몸과 마음이 나른할 때 기운을 깨워줘요.';

  @override
  String get breathingSuggestionTitle => '지금 이 마음, 숨결과 함께 시작해볼까요?';

  @override
  String breathingSuggestionSubtitle(String emoji, String name) {
    return '$emoji $name을 잠깐 함께 해보면, 게임이 조금 더 편안하게 느껴질 거예요.';
  }

  @override
  String get breathingSuggestionStartButton => '숨 고르고 시작하기';

  @override
  String get breathingSuggestionSkipButton => '바로 시작할게요';

  @override
  String get mongiCareNotEnoughSnackbar => '빛의 정수가 모자라요. 게임을 플레이해서 조금 더 모아볼까요?';

  @override
  String mongiCareKeepsakePlacedSuffix(String reaction) {
    return '$reaction\n정원에 영구히 놓였어요!';
  }

  @override
  String get mongiCareSheetTitle => '🍚 몽이 돌봄 세트';

  @override
  String get mongiCareItemNameTunaCan => '참치캔';

  @override
  String get mongiCareItemNameKibble => '몽이 사료';

  @override
  String get mongiCareItemNameCleanWater => '맑은 물';

  @override
  String get mongiCareItemNameInjeolmi => '인절미';

  @override
  String get mongiCareItemNameBlanket => '포근한 담요';

  @override
  String get mongiCareItemNameMongiHouse => '몽이의 집';

  @override
  String get mongiCareItemReactionTunaCan =>
      '몽이가 참치캔을 냠냠 먹었어요! 세상 행복한 표정이에요 🐟';

  @override
  String get mongiCareItemReactionKibble => '몽이가 사료를 오독오독 씹어 먹었어요 🍚';

  @override
  String get mongiCareItemReactionCleanWater => '몽이가 시원한 물을 마시고 개운해했어요 💧';

  @override
  String get mongiCareItemReactionInjeolmi =>
      '몽이가 콩고물 인절미를 오물오물 먹었어요! 쫀득쫀득 맛있대요 🍡';

  @override
  String get mongiCareItemReactionBlanket =>
      '몽이가 담요를 덮고 따뜻하게 잠들었어요. 이제 정원 한켠이 더 아늑해졌어요 🧣';

  @override
  String get mongiCareItemReactionMongiHouse =>
      '몽이가 새 집을 마음에 들어해요! 이제 정원에 몽이만의 아늑한 집이 생겼어요 🏠';

  @override
  String mongiCareLightEssenceLabel(int amount) {
    return '빛의 정수 $amount';
  }

  @override
  String get mongiCareConsumableSectionLabel => '먹이 · 언제든 다시 줄 수 있어요';

  @override
  String get mongiCareKeepsakeSectionLabel => '특별한 선물 · 한 번 주면 정원에 계속 남아요';

  @override
  String get mongiCareKeepsakePlacedStatus => '지금 정원에 놓여 있어요';

  @override
  String get mongiCareKeepsakeHint => '한 번 선물하면 정원에 영구히 남아요';

  @override
  String mongiCareGivenCountStatus(int count) {
    return '지금까지 $count번 줬어요';
  }

  @override
  String get mongiCareNeverGivenStatus => '아직 준 적 없어요';

  @override
  String get lightEssenceShopTitle => '빛의 정수 충전';

  @override
  String get lightEssencePackLabelSmall => '작은 빛 주머니';

  @override
  String get lightEssencePackLabelLarge => '커다란 빛 항아리';

  @override
  String lightEssenceShopDescription(int count) {
    return '플레이만 해도 계속 모을 수 있어요\n지금 보유: $count개';
  }

  @override
  String get lightEssenceShopBestValueBadge => '더 이득';

  @override
  String lightEssenceShopPackAmountPrice(int amount, String pricePer100) {
    return '💡 $amount개 · 100개당 $pricePer100원';
  }

  @override
  String get gratitudeLogHeaderTitle => '🌻 감사 & 작은 성취';

  @override
  String get gratitudeLogIntro => '아주 사소한 것도 괜찮아요.\n매일 한 줄씩, 좋았던 순간을 남겨보세요 🌿';

  @override
  String get gratitudeLogSubmitButton => '기록 남기기';

  @override
  String get gratitudeLogEmptyTitle => '아직 남긴 기록이 없어요';

  @override
  String get gratitudeLogEmptySubtitle => '오늘 있었던 작은 좋은 일을 남겨보세요';

  @override
  String gratitudeLogSubmittedSnackbar(String emoji) {
    return '$emoji 오늘의 기록을 남겼어요';
  }

  @override
  String seasonMilestoneSnackbar(String message) {
    return '🌿 $message';
  }

  @override
  String get gratitudeLogDeleteTooltip => '삭제';

  @override
  String get gratitudeEntryTypeLabelGratitude => '감사한 일';

  @override
  String get gratitudeEntryTypeLabelAchievement => '작은 성취';

  @override
  String get gratitudeEntryTypeHintGratitude => '오늘, 어떤 것에 감사했나요?';

  @override
  String get gratitudeEntryTypeHintAchievement => '오늘, 스스로 해낸 작은 일이 있나요?';

  @override
  String get gratitudeEntryTypePlaceholderGratitude => '예: 오늘 햇살이 참 따뜻했어요';

  @override
  String get gratitudeEntryTypePlaceholderAchievement => '예: 오늘은 늦지 않고 일어났어요';

  @override
  String get dailyCheckInCuriousLabel => '몽이가 궁금해해요';

  @override
  String get dailyCheckInQuestion => '오늘 기분은 어때요?';

  @override
  String dailyCheckInStreakBadge(int streak, int streakAfter) {
    return '🔥 연속 체크인 $streak일째 · 오늘 하면 $streakAfter일!';
  }

  @override
  String get dailyCheckInBestStreakNewRecord => '🏆 지금 체크인하면 개인 최고 기록 경신!';

  @override
  String dailyCheckInBestStreakCompare(int best) {
    return '개인 최고 기록 $best일';
  }

  @override
  String dailyCheckInBestStreakRestart(int best) {
    return '이전 최고 기록은 $best일이에요 · 다시 도전해봐요!';
  }

  @override
  String get dailyCheckInSkipButton => '나중에 할게요';

  @override
  String get mongiLetterHeaderTitle => '💌 몽이의 편지';

  @override
  String get mongiLetterNotEnoughMessage =>
      '아직 몽이가 편지를 쓸 만큼\n이야기가 모이지 않았어요.\n조금 더 함께해주면 다음 주엔\n꼭 편지를 써서 보내줄게요 🐾';

  @override
  String get mongiLetterArrivedTitle => '몽이에게서 편지가 도착했어요';

  @override
  String get mongiLetterTapToOpenHint => '톡 눌러서 열어보기';

  @override
  String get mongiLetterGreeting => '안녕, 나 몽이야 🐱\n이번 주도 네 마음을 가까이서 지켜봤어.';

  @override
  String mongiLetterBodyTopTarget(String target) {
    return '이번 주엔 \"$target\" 이야기를 유독 많이 들려줬어.\n그만큼 네 마음에 크게 자리하고 있었나 봐.\n어떤 이야기였는지 몽이는 계속 생각하고 있었어.';
  }

  @override
  String mongiLetterBodyTopEmotion(String emotion) {
    return '이번 주는 \"$emotion\"을 유독 많이 만난 한 주였어.\n무슨 일이 있었는지 몽이는 궁금했지만,\n다그치지 않고 그냥 곁에서 지켜봤어.';
  }

  @override
  String get mongiLetterBodyManyNotes =>
      '이번 주는 너의 이야기를 유독 많이 들려줬어.\n짧은 한마디까지도 몽이는 하나하나\n다 소중하게 담아뒀어.';

  @override
  String get mongiLetterBodyMostlyPositive =>
      '요즘 마음이 한층 가벼워진 것 같아서\n몽이도 옆에서 덩달아 신났어.\n이런 날들이 더 많아지면 좋겠다.';

  @override
  String get mongiLetterBodyMostlyHeavy =>
      '마음이 조금 무거웠던 날들도 있었지.\n그래도 힘들 때마다 몽이에게 와줘서\n고마웠어. 혼자 견디지 않아도 괜찮아.';

  @override
  String get mongiLetterBodyDefaultThanks =>
      '이번 주도 크고 작은 마음들을\n몽이에게 나눠줘서 고마웠어.\n어떤 마음이든 괜찮다고, 몽이는 늘 그렇게 생각해.';

  @override
  String mongiLetterStreakLong(int streak) {
    return '$streak일째 매일 몽이를 찾아와줬어.\n그게 얼마나 대단한 일인지 너는 잘 모를 수도 있지만,\n몽이는 매일 그걸 느끼고 있었어.';
  }

  @override
  String mongiLetterStreakShort(int streak) {
    return '$streak일 연속으로 와줬네!\n작은 습관이 쌓이는 걸 보는 게\n몽이에겐 큰 기쁨이야.';
  }

  @override
  String get mongiLetterStreakNone =>
      '자주 오지 못한 주였어도 괜찮아.\n네가 오고 싶을 때, 몽이는 늘 같은 자리에 있을게.';

  @override
  String get mongiLetterClosing =>
      '언제나 네 곁에 있을게.\n다음 주에도 또 이야기해줘.\n\n너의 몽이가 🐾';

  @override
  String get diaryHeaderTitle => '📔 감정 다이어리';

  @override
  String get diaryEmptyTitle => '아직 남긴 기록이 없어요';

  @override
  String get diaryEmptySubtitle => '감정 몬스터를 마주하고 나면\n이 곳에 오늘의 이야기가 쌓여요';

  @override
  String get diaryShareTooltip => '카드로 공유하기';

  @override
  String diaryNameLabel(String target, String emotion) {
    return '$target에 대한 $emotion';
  }

  @override
  String scorePopupGainedLabel(int score) {
    return '+$score점';
  }

  @override
  String scorePopupTotalLabel(int totalScore) {
    return '누적 $totalScore점';
  }

  @override
  String get emotionLabelHate => '미움';

  @override
  String get emotionLabelAnger => '화';

  @override
  String get emotionLabelWorry => '걱정';

  @override
  String get emotionLabelSadness => '슬픔';

  @override
  String get emotionLabelLoneliness => '외로움';

  @override
  String get emotionLabelAnxiety => '불안';

  @override
  String get emotionLabelShame => '부끄러움';

  @override
  String get emotionLabelIrritation => '짜증';

  @override
  String get emotionLabelGrievance => '억울함';

  @override
  String get emotionLabelFear => '두려움';

  @override
  String get emotionLabelJoy => '기쁨';

  @override
  String get emotionLabelGratitude => '감사';

  @override
  String get emotionLabelExcitement => '설렘';

  @override
  String get emotionLabelCalm => '평온';

  @override
  String get emotionLabelConfidence => '자신감';

  @override
  String get emotionLabelTired => '피곤';

  @override
  String get emotionLabelBoredom => '심심함';

  @override
  String get emotionLabelCourage => '용기';

  @override
  String get emotionLabelThrill => '신남';

  @override
  String get emotionLabelHappiness => '행복';

  @override
  String get emotionCatQuestionHate => '이건... 미움콩이네. 오래 가지고 있었구나.';

  @override
  String get emotionCatQuestionAnger => '화르르가 나왔네. 많이 속상했지.';

  @override
  String get emotionCatQuestionWorry => '걱정구름이 잔뜩 끼어있었네.';

  @override
  String get emotionCatQuestionSadness => '슬픔물방울이구나. 많이 힘들었겠다.';

  @override
  String get emotionCatQuestionLoneliness => '혼자 웅크리고 있었구나. 내가 옆에 있을게.';

  @override
  String get emotionCatQuestionAnxiety => '불안돌이가 자꾸 떨고 있었네. 나쁜 생각이 많았구나.';

  @override
  String get emotionCatQuestionShame => '부끄럼쟁이구나. 얼굴이 발그레했겠다.';

  @override
  String get emotionCatQuestionIrritation => '까칠이가 잔뜩 곤두서 있었네. 예민했었구나.';

  @override
  String get emotionCatQuestionGrievance => '꽁꽁 묶인 억울함이었구나. 얼마나 답답했을까.';

  @override
  String get emotionCatQuestionFear => '어둠 속에 숨어있던 두려움이네. 이제 괜찮아, 내가 있잖아.';

  @override
  String get emotionCatQuestionJoy => '반짝반짝 기쁨별이네! 오늘 좋은 일이 있었나 보다.';

  @override
  String get emotionCatQuestionGratitude => '따뜻한 감사하트구나. 누군가에게 고마운 마음이 있었나 봐.';

  @override
  String get emotionCatQuestionExcitement => '두근두근 설렘구름이네! 무슨 좋은 일을 기다리는 거야?';

  @override
  String get emotionCatQuestionCalm => '잔잔한 평온물결이구나. 마음이 고요하고 편안했나 봐.';

  @override
  String get emotionCatQuestionConfidence => '씩씩한 자신감뱃지네! 오늘 뭔가 해냈구나, 대단해.';

  @override
  String get emotionCatQuestionTired => '나른한 피곤이네. 오늘 많이 애썼구나.';

  @override
  String get emotionCatQuestionBoredom => '하품 나는 심심함이구나. 뭔가 재미있는 게 필요했나 봐.';

  @override
  String get emotionCatQuestionCourage => '씩씩한 용기 방패네! 무서운 걸 마주하고도 한 발 나아갔구나.';

  @override
  String get emotionCatQuestionThrill => '팡팡 튀는 신남이네! 신나는 일이 생겼구나!';

  @override
  String get emotionCatQuestionHappiness => '포근한 행복 햇살이네. 마음 가득 따뜻했나 보다.';

  @override
  String get emotionHealMessageHate => '미움이 사라진 자리에\n작은 꽃 한 송이가 피었어요 🌸';

  @override
  String get emotionHealMessageAnger => '뜨거운 마음이 가라앉고\n따뜻한 빛이 남았어요 ✨';

  @override
  String get emotionHealMessageWorry => '먹구름이 걷히고\n맑은 하늘이 보이기 시작해요 🌤️';

  @override
  String get emotionHealMessageSadness => '눈물이 마르고\n작은 연못에 별이 비쳐요 💧';

  @override
  String get emotionHealMessageLoneliness => '그림자가 옅어지고\n곁을 지키는 온기가 남았어요 🤍';

  @override
  String get emotionHealMessageAnxiety => '떨림이 잦아들고\n마음에 잔잔한 물결이 일어요 🌊';

  @override
  String get emotionHealMessageShame => '움츠렸던 어깨가 펴지고\n따뜻한 미소가 번져요 😊';

  @override
  String get emotionHealMessageIrritation => '가시가 살랑살랑 부드러워지고\n산들바람이 불어와요 🍃';

  @override
  String get emotionHealMessageGrievance => '엉킨 마음이 스르륵 풀리고\n숨쉬기가 편해졌어요 🎈';

  @override
  String get emotionHealMessageFear => '어둠이 걷히고\n작은 별빛이 마음을 비춰요 ⭐';

  @override
  String get emotionHealMessageJoy => '기쁨이 마음 가득 채워지고\n환한 빛으로 남았어요 🌟';

  @override
  String get emotionHealMessageGratitude => '고마운 마음이 몽이 품에도\n따뜻하게 스며들었어요 💛';

  @override
  String get emotionHealMessageExcitement =>
      '두근거림이 몽이에게도 전해져서\n마음이 살짝 붕 떠올랐어요 🎈';

  @override
  String get emotionHealMessageCalm => '고요한 마음이 정원에도 번져서\n잔잔한 물결이 일어요 🌊';

  @override
  String get emotionHealMessageConfidence =>
      '씩씩한 마음이 몽이에게도 옮아서\n어깨가 활짝 펴졌어요 💪';

  @override
  String get emotionHealMessageTired => '무거웠던 눈꺼풀이 스르륵 감기고\n포근한 잠이 찾아와요 🌙';

  @override
  String get emotionHealMessageBoredom => '멍하던 마음에 작은 호기심이\n동그라미를 그리며 피어나요 🌀';

  @override
  String get emotionHealMessageCourage =>
      '두근거리던 마음이 단단해지고\n몽이 가슴에도 뜨거운 힘이 차올라요 🔥';

  @override
  String get emotionHealMessageThrill => '통통 튀는 기운이 몽이에게도 옮아서\n온몸이 들썩들썩해졌어요 🎊';

  @override
  String get emotionHealMessageHappiness =>
      '따스한 볕이 마음 구석구석까지 스며들어\n은은하게 오래 남아요 ☀️';

  @override
  String get emotionStoryTextHate =>
      '미움콩은 마음에 오래 담아두면 점점 딱딱해져요. 누군가를 미워하는 마음은 사실 그만큼 소중히 여겼다는 증거이기도 해요. 꺼내서 보여주면, 그 자리에 꽃이 필 수 있어요.';

  @override
  String get emotionStoryTextAnger =>
      '화르르는 마음이 지켜지지 않았을 때 확 타오르는 감정이에요. 나쁜 게 아니라, \"나를 존중해줘\"라는 신호랍니다. 잠깐 열을 식히고 나면 따뜻한 빛만 남아요.';

  @override
  String get emotionStoryTextWorry =>
      '걱정구름은 아직 일어나지 않은 일까지 미리 대비하려는 마음이 만들어내요. 조금은 나를 지키려는 노력이었어요. 구름은 흘러가는 게 원래 하는 일이니, 잠시 지켜봐 줘도 괜찮아요.';

  @override
  String get emotionStoryTextSadness =>
      '슬픔물방울은 소중한 걸 잃었거나 마음이 다쳤을 때 맺혀요. 참지 않고 흘려보내면, 그 눈물이 고여 작은 연못이 되고 언젠가 별빛이 비치는 날이 와요.';

  @override
  String get emotionStoryTextLoneliness =>
      '외로움그림자는 누군가와 연결되고 싶은 마음이 클수록 짙어져요. 혼자라는 느낌이 들 땐, 그만큼 함께하고 싶은 마음이 크다는 뜻이에요. 몽이가 옆에 있을게요.';

  @override
  String get emotionStoryTextAnxiety =>
      '불안돌이는 앞일이 어떻게 될지 모를 때 자꾸만 떨려요. 확실하지 않은 걸 견디는 건 누구에게나 힘든 일이에요. 숨을 천천히 쉬면, 떨림도 조금씩 잦아들어요.';

  @override
  String get emotionStoryTextShame =>
      '부끄럼쟁이는 남들 눈에 어떻게 보일지 신경 쓸 때 얼굴을 붉혀요. 사실 그만큼 진심으로 잘 해내고 싶었다는 뜻이에요. 실수해도 괜찮아요, 몽이는 그런 모습도 좋아해요.';

  @override
  String get emotionStoryTextIrritation =>
      '까칠이는 몸과 마음이 지쳐 여유가 없을 때 가시를 세워요. 짜증이 났다는 건 쉬어야 할 때가 됐다는 신호일 수 있어요. 가시를 내려놓으면 산들바람이 불어와요.';

  @override
  String get emotionStoryTextGrievance =>
      '억울함 매듭은 내 진심이 제대로 전해지지 않았다고 느낄 때 꽁꽁 묶여요. 누군가에게 알아달라고 소리치고 싶었던 마음이었을 거예요. 하나씩 풀다 보면 숨쉬기가 편해져요.';

  @override
  String get emotionStoryTextFear =>
      '두려움은 나를 위험으로부터 지키려는 아주 오래된 본능이에요. 무서운 게 있다는 건 그만큼 소중히 지키고 싶은 게 있다는 뜻이죠. 어둠 속에서도 몽이가 함께 있을게요.';

  @override
  String get emotionStoryTextJoy =>
      '기쁨별은 작은 행복도 놓치지 않고 알아챘을 때 반짝여요. 기쁜 순간을 마음에 오래 담아두는 연습을 하면, 별빛이 더 환하게 오래 빛난답니다.';

  @override
  String get emotionStoryTextGratitude =>
      '감사하트는 누군가의 다정함을 알아챘을 때 따뜻하게 커져요. 고맙다는 말 한마디가 상대의 마음에도 하트를 하나 더 심어준답니다.';

  @override
  String get emotionStoryTextExcitement =>
      '설렘구름은 앞으로 다가올 무언가를 기대할 때 두둥실 떠올라요. 결과가 어떻든, 기다리는 그 시간 자체가 이미 선물 같은 순간이에요.';

  @override
  String get emotionStoryTextCalm =>
      '평온물결은 아무 일도 없어야만 생기는 게 아니에요. 있는 그대로의 나를 받아들일 때 마음 깊은 곳에서부터 잔잔하게 퍼져 나가요.';

  @override
  String get emotionStoryTextConfidence =>
      '자신감뱃지는 작은 시도라도 스스로 해냈을 때 반짝 달려요. 결과보다 시도한 그 순간을 인정해주는 게, 뱃지를 더 많이 모으는 비결이에요.';

  @override
  String get emotionStoryTextTired =>
      '피곤이는 몸과 마음이 열심히 하루를 살아냈다는 증거예요. 애쓴 나를 다그치기보다 잠깐 눈을 감고 쉬어주면, 다음 날 다시 통통 튀어 오를 힘이 생겨요.';

  @override
  String get emotionStoryTextBoredom =>
      '심심이는 딱히 할 일이 없을 때 마음이 텅 빈 것처럼 느껴져서 찾아와요. 사실 심심함은 새로운 걸 하고 싶다는 신호이기도 해요. 가만히 있다 보면 뜻밖의 재미난 생각이 떠오르기도 한답니다.';

  @override
  String get emotionStoryTextCourage =>
      '용기 방패는 무섭지 않아서가 아니라, 무서워도 한 걸음 내딛었을 때 반짝 빛나요. 떨리는 마음을 안고도 해낸 그 순간이 가장 용감한 순간이에요.';

  @override
  String get emotionStoryTextThrill =>
      '신남이는 지금 이 순간이 너무 즐거워서 몸이 먼저 들썩일 때 튀어나와요. 설렘이 앞으로 올 일을 기대하는 두근거림이라면, 신남이는 지금 당장 터지는 신나는 에너지예요.';

  @override
  String get emotionStoryTextHappiness =>
      '행복 햇살은 반짝하고 사라지는 기쁨과 달리, 잔잔하고 오래도록 마음을 데워줘요. 특별한 일이 없어도 하루하루가 괜찮다고 느껴질 때, 이 햇살이 은은하게 비춘답니다.';

  @override
  String get evolutionNameHate0 => '미움콩';

  @override
  String get evolutionNameHate1 => '애틋콩';

  @override
  String get evolutionNameHate2 => '온정콩';

  @override
  String get evolutionNameHate3 => '다정콩순';

  @override
  String get evolutionNameAnger0 => '화르르';

  @override
  String get evolutionNameAnger1 => '잔불이';

  @override
  String get evolutionNameAnger2 => '온기';

  @override
  String get evolutionNameAnger3 => '온기누리';

  @override
  String get evolutionNameWorry0 => '걱정구름';

  @override
  String get evolutionNameWorry1 => '옅은구름';

  @override
  String get evolutionNameWorry2 => '맑음이';

  @override
  String get evolutionNameWorry3 => '맑음별';

  @override
  String get evolutionNameSadness0 => '슬픔물방울';

  @override
  String get evolutionNameSadness1 => '잔잔물결';

  @override
  String get evolutionNameSadness2 => '별빛연못';

  @override
  String get evolutionNameSadness3 => '별빛은하';

  @override
  String get evolutionNameLoneliness0 => '외로움그림자';

  @override
  String get evolutionNameLoneliness1 => '옅은그림자';

  @override
  String get evolutionNameLoneliness2 => '온기그림자';

  @override
  String get evolutionNameLoneliness3 => '함께빛';

  @override
  String get evolutionNameAnxiety0 => '불안돌이';

  @override
  String get evolutionNameAnxiety1 => '잔잔돌이';

  @override
  String get evolutionNameAnxiety2 => '평온돌이';

  @override
  String get evolutionNameAnxiety3 => '평온지기';

  @override
  String get evolutionNameShame0 => '부끄럼쟁이';

  @override
  String get evolutionNameShame1 => '발그레쟁이';

  @override
  String get evolutionNameShame2 => '미소쟁이';

  @override
  String get evolutionNameShame3 => '당당이';

  @override
  String get evolutionNameIrritation0 => '까칠이';

  @override
  String get evolutionNameIrritation1 => '산들이';

  @override
  String get evolutionNameIrritation2 => '보드리';

  @override
  String get evolutionNameIrritation3 => '포근보드리';

  @override
  String get evolutionNameGrievance0 => '억울매듭';

  @override
  String get evolutionNameGrievance1 => '느슨매듭';

  @override
  String get evolutionNameGrievance2 => '풀림매듭';

  @override
  String get evolutionNameGrievance3 => '자유매듭';

  @override
  String get evolutionNameFear0 => '어둠이';

  @override
  String get evolutionNameFear1 => '여명이';

  @override
  String get evolutionNameFear2 => '별빛이';

  @override
  String get evolutionNameFear3 => '새벽별';

  @override
  String get evolutionNameJoy0 => '기쁨별';

  @override
  String get evolutionNameJoy1 => '반짝별';

  @override
  String get evolutionNameJoy2 => '빛나는별';

  @override
  String get evolutionNameJoy3 => '별무리';

  @override
  String get evolutionNameGratitude0 => '감사하트';

  @override
  String get evolutionNameGratitude1 => '따뜻하트';

  @override
  String get evolutionNameGratitude2 => '빛나하트';

  @override
  String get evolutionNameGratitude3 => '은하하트';

  @override
  String get evolutionNameExcitement0 => '설렘구름';

  @override
  String get evolutionNameExcitement1 => '두근구름';

  @override
  String get evolutionNameExcitement2 => '반짝구름';

  @override
  String get evolutionNameExcitement3 => '무지개구름';

  @override
  String get evolutionNameCalm0 => '평온물결';

  @override
  String get evolutionNameCalm1 => '잔잔바다';

  @override
  String get evolutionNameCalm2 => '고요한바다';

  @override
  String get evolutionNameCalm3 => '은빛바다';

  @override
  String get evolutionNameConfidence0 => '자신감뱃지';

  @override
  String get evolutionNameConfidence1 => '빛나는뱃지';

  @override
  String get evolutionNameConfidence2 => '황금뱃지';

  @override
  String get evolutionNameConfidence3 => '전설뱃지';

  @override
  String get evolutionNameTired0 => '꾸벅이';

  @override
  String get evolutionNameTired1 => '나른이';

  @override
  String get evolutionNameTired2 => '포근이';

  @override
  String get evolutionNameTired3 => '포근달빛';

  @override
  String get evolutionNameBoredom0 => '심심소용돌이';

  @override
  String get evolutionNameBoredom1 => '꼬물소용돌이';

  @override
  String get evolutionNameBoredom2 => '반짝소용돌이';

  @override
  String get evolutionNameBoredom3 => '별빛소용돌이';

  @override
  String get evolutionNameCourage0 => '용기방패';

  @override
  String get evolutionNameCourage1 => '단단방패';

  @override
  String get evolutionNameCourage2 => '빛나는방패';

  @override
  String get evolutionNameCourage3 => '수호방패';

  @override
  String get evolutionNameThrill0 => '신남스파크';

  @override
  String get evolutionNameThrill1 => '통통스파크';

  @override
  String get evolutionNameThrill2 => '팡팡스파크';

  @override
  String get evolutionNameThrill3 => '은하스파크';

  @override
  String get evolutionNameHappiness0 => '행복햇살';

  @override
  String get evolutionNameHappiness1 => '따뜻햇살';

  @override
  String get evolutionNameHappiness2 => '온누리햇살';

  @override
  String get evolutionNameHappiness3 => '영원한햇살';

  @override
  String gameEatenLineSingle(String label) {
    return '냠! $label, 마음에 품었어요';
  }

  @override
  String gameEatenLineStreak(String label, int streak) {
    return '$label가 $streak번 연속!';
  }

  @override
  String gameReceivedLineSingle(String label) {
    return '포근! $label이(가) 가슴에 스며들었어요';
  }

  @override
  String gameReceivedLineStreak(String label, int streak) {
    return '$label가 $streak번 연속으로 빛나요 ✨';
  }

  @override
  String get gameFirstMeetCaption => '🏷️ 처음 만난 마음이에요';

  @override
  String get gamePerfectTimingLabel => '완벽 타이밍! ✨';

  @override
  String get gameRockHitLabel => '아얏! 😳';

  @override
  String get gameReviveEncouragementLabel => '다시 힘내볼게요! 💪';

  @override
  String gameTimeUpLabel(int count) {
    return '시간이 다 됐어요! $count개 만났어요 ⏰';
  }

  @override
  String gameEarlyStopShortEndless(int count) {
    return '오늘의 도전, $count개까지 왔어요! 🤍';
  }

  @override
  String gameEarlyStopShortNormal(int count) {
    return '오늘은 $count개 만나고 여기까지 왔어요 🤍';
  }

  @override
  String get gameStageClearPurrLabel => '골골~ 😽';

  @override
  String get gameBreathingLifeRestoredLabel => '숨을 잘 골랐어요! 💗';

  @override
  String get gameBreathingBonusLabel => '숨을 잘 골랐어요! ✨';

  @override
  String get gameBreathingSkippedLabel => '잠깐 쉬어갔어요 🌿';

  @override
  String get gamePowerModeActivatedLabel => '무적 모드! 💥⚡';

  @override
  String get gamePowerSmashLabel => '펑! 💥';

  @override
  String get gameTreatBonusLabel => '반짝 보너스! ✨ +2';

  @override
  String get gameHeartRestoredLabel => '생명 회복! 💗';

  @override
  String get settingsTermsOfService => '이용약관';

  @override
  String get termsHeaderTitle => '📜 이용약관';

  @override
  String get termsIntro =>
      '몽이 힐링가든 서비스를 이용해주셔서 감사해요. 이 약관은 서비스 이용과 관련한 몽이(사업자)와 이용자 간의 권리·의무를 안내해요.';

  @override
  String get termsSection1Title => '1. 서비스의 제공';

  @override
  String get termsSection1Body =>
      '몽이 힐링가든은 감정 기록, 마음정원 가꾸기, 미니게임 등 힐링 콘텐츠를 제공하는 모바일 애플리케이션이에요. 서비스의 일부 또는 전체는 사전 고지 없이 변경·중단될 수 있어요.';

  @override
  String get termsSection2Title => '2. 인앱 구매 및 결제';

  @override
  String get termsSection2Body =>
      '앱 내 유료 아이템(프리미엄 프레임, 정원 장식, 시즌 패스, 빛의 정수 등)은 Google Play 결제 시스템을 통해 구매하며, 결제 즉시 디지털 콘텐츠가 제공돼요. 관련 법령이 정하는 바에 따라 청약 철회가 제한될 수 있고, 환불은 Google Play 정책을 따라요.';

  @override
  String get termsSection3Title => '3. 광고';

  @override
  String get termsSection3Body =>
      '서비스 운영을 위해 Google AdMob을 통한 광고(배너/전면/리워드)가 표시될 수 있어요. 리워드 광고 시청은 선택 사항이며, 시청 여부와 관계없이 핵심 기능은 계속 이용할 수 있어요.';

  @override
  String get termsSection4Title => '4. 이용자의 의무';

  @override
  String get termsSection4Body =>
      '이용자는 서비스를 부정한 방법으로 조작·변조하거나 타인의 이용을 방해하는 행위를 해서는 안 돼요. 이를 위반할 경우 서비스 이용이 제한될 수 있어요.';

  @override
  String get termsSection5Title => '5. 면책 및 정신건강 콘텐츠 안내';

  @override
  String get termsSection5Body =>
      '몽이 안의 정신건강 지원 정보(상담 전화·문자 등)는 참고용 안내이며, 전문적인 의료·심리 상담을 대체하지 않아요. 긴급한 위기 상황에서는 반드시 각국의 응급 서비스나 전문기관에 즉시 연락해주세요.';

  @override
  String get termsSection6Title => '6. 약관의 변경';

  @override
  String get termsSection6Body =>
      '이 약관은 관련 법령 및 서비스 변경에 따라 수정될 수 있으며, 중요한 변경 시 앱 내 공지를 통해 알려드려요. 변경된 약관에 동의하지 않는 경우 서비스 이용을 중단할 수 있어요.';

  @override
  String get termsLastUpdatedDate => '2026년 8월 25일';

  @override
  String termsLastUpdatedLabel(String date) {
    return '마지막 개정일: $date';
  }

  @override
  String mindChallengeHomeBannerTitleActive(
    String emoji,
    String title,
    int day,
    int total,
  ) {
    return '$emoji $title · $day/$total일차';
  }

  @override
  String get mindChallengeHomeBannerTitleInactive => '🌿 마음 챌린지 시작하기';

  @override
  String get mindChallengeHomeBannerSubtitleActive => '오늘의 체크인으로 오늘 몫을 채워요';

  @override
  String get mindChallengeHomeBannerSubtitleInactive => '7일 테마 여정으로 마음을 돌봐요';

  @override
  String get mindChallengeListAppBarTitle => '마음 챌린지';

  @override
  String get mindChallengeListHeadline => '테마를 하나 골라, 7일 동안 함께해요';

  @override
  String get mindChallengeListSubtitle => '매일 오늘의 감정 체크인을 하면 챌린지가 자연스럽게 진행돼요';

  @override
  String mindChallengeCardDurationLabel(int days) {
    return '$days일 여정';
  }

  @override
  String get mindChallengeCardStartButton => '시작하기';

  @override
  String get mindChallengeCardContinueButton => '이어서 보기';

  @override
  String get mindChallengeCardInProgressBadge => '진행 중';

  @override
  String get mindChallengeCardCompletedBadge => '완주함';

  @override
  String get mindChallengeStartConfirmTitle => '이 챌린지를 시작할까요?';

  @override
  String mindChallengeStartConfirmBody(int days) {
    return '매일 감정 체크인을 하면 하루씩 진행돼요. $days일을 모두 채우면 특별한 보상을 받을 수 있어요.';
  }

  @override
  String get mindChallengeStartConfirmReplaceBody =>
      '다른 챌린지가 진행 중이에요. 새 챌린지를 시작하면 지금까지의 진행도는 사라져요. 계속할까요?';

  @override
  String get mindChallengeStartConfirmButton => '시작하기';

  @override
  String mindChallengeStartedSnackbar(String title) {
    return '$title 챌린지를 시작했어요!';
  }

  @override
  String get mindChallengeDetailAppBarTitle => '마음 챌린지';

  @override
  String mindChallengeDetailDayLabel(int day, int total) {
    return '$day / $total일차';
  }

  @override
  String mindChallengeDetailProgressLabel(int done, int total) {
    return '지금까지 $done / $total일 완료';
  }

  @override
  String get mindChallengeDetailCheckedInToday => '오늘 체크인 완료! 내일 또 만나요';

  @override
  String get mindChallengeDetailNotCheckedInYet => '오늘의 감정 체크인을 하면 오늘 몫이 채워져요';

  @override
  String get mindChallengeDetailCompleteReadyTitle => '축하해요! 챌린지를 모두 완료했어요';

  @override
  String get mindChallengeDetailCompleteButton => '완주 보상 받기';

  @override
  String get mindChallengeDetailCompletedSnackbar => '챌린지를 완주했어요! 보상을 받았어요';

  @override
  String get mindChallengeDetailAbandonButton => '챌린지 그만두기';

  @override
  String get mindChallengeDetailAbandonConfirmTitle => '챌린지를 그만둘까요?';

  @override
  String get mindChallengeDetailAbandonConfirmBody =>
      '지금까지의 진행도가 사라져요. 그래도 그만둘까요?';

  @override
  String get mindChallengeDetailAbandonConfirmButton => '그만두기';

  @override
  String mindChallengeDetailDayRewardLabel(int reward) {
    return '하루 완료마다 💡+$reward';
  }

  @override
  String mindChallengeDetailCompletionRewardLabel(int light, int shard) {
    return '완주 보상 💡+$light ⭐+$shard';
  }

  @override
  String get mindChallengeTitleSelfEsteem => '자존감 돌보기';

  @override
  String get mindChallengeDescSelfEsteem =>
      '7일 동안 매일 나에게 다정한 말을 건네며 자존감을 천천히 채워가요.';

  @override
  String get mindChallengeDaySelfEsteem1 => '1일차: 오늘 나에게 잘한 일 한 가지를 떠올려보세요.';

  @override
  String get mindChallengeDaySelfEsteem2 => '2일차: 거울 속 나에게 \"고생했어\"라고 말해보세요.';

  @override
  String get mindChallengeDaySelfEsteem3 => '3일차: 나의 장점 하나를 적어보세요.';

  @override
  String get mindChallengeDaySelfEsteem4 => '4일차: 오늘은 나를 비교하지 않는 날로 정해보세요.';

  @override
  String get mindChallengeDaySelfEsteem5 => '5일차: 작은 성취 하나에도 스스로를 칭찬해주세요.';

  @override
  String get mindChallengeDaySelfEsteem6 =>
      '6일차: 나를 힘들게 하는 생각 하나를 조금 다르게 바라봐요.';

  @override
  String get mindChallengeDaySelfEsteem7 => '7일차: 지난 6일을 돌아보며 나에게 편지를 써보세요.';

  @override
  String get mindChallengeTitleAnxietyCalm => '불안 다스리기';

  @override
  String get mindChallengeDescAnxietyCalm =>
      '7일 동안 매일 잠시 멈춰 숨을 고르며 불안한 마음을 가라앉혀요.';

  @override
  String get mindChallengeDayAnxietyCalm1 => '1일차: 지금 느끼는 불안에 이름을 붙여보세요.';

  @override
  String get mindChallengeDayAnxietyCalm2 => '2일차: 천천히 숨을 4번 들이쉬고 내쉬어 보세요.';

  @override
  String get mindChallengeDayAnxietyCalm3 =>
      '3일차: 지금 당장 할 수 있는 아주 작은 일 하나만 해보세요.';

  @override
  String get mindChallengeDayAnxietyCalm4 => '4일차: \"이 순간은 지나간다\"는 것을 떠올려보세요.';

  @override
  String get mindChallengeDayAnxietyCalm5 => '5일차: 걱정을 종이에 적어 눈에 보이게 꺼내보세요.';

  @override
  String get mindChallengeDayAnxietyCalm6 => '6일차: 오늘 하루, 확실한 것 세 가지를 찾아보세요.';

  @override
  String get mindChallengeDayAnxietyCalm7 => '7일차: 일주일간 불안이 어떻게 변했는지 돌아보세요.';

  @override
  String get mindChallengeTitleBurnoutRecovery => '번아웃 회복';

  @override
  String get mindChallengeDescBurnoutRecovery =>
      '7일 동안 매일 조금씩 쉬어가며 지친 마음을 회복해요.';

  @override
  String get mindChallengeDayBurnoutRecovery1 =>
      '1일차: 오늘 하루, 꼭 하지 않아도 되는 일 하나를 내려놓아 보세요.';

  @override
  String get mindChallengeDayBurnoutRecovery2 =>
      '2일차: 잠깐이라도 아무것도 하지 않는 시간을 가져보세요.';

  @override
  String get mindChallengeDayBurnoutRecovery3 =>
      '3일차: 나를 지치게 하는 것 하나를 알아차려 보세요.';

  @override
  String get mindChallengeDayBurnoutRecovery4 => '4일차: 좋아하는 것을 5분만 해보세요.';

  @override
  String get mindChallengeDayBurnoutRecovery5 =>
      '5일차: \"충분히 했다\"고 스스로에게 말해주세요.';

  @override
  String get mindChallengeDayBurnoutRecovery6 => '6일차: 오늘은 평소보다 조금 일찍 쉬어보세요.';

  @override
  String get mindChallengeDayBurnoutRecovery7 => '7일차: 이번 주 나를 돌본 방법들을 적어보세요.';

  @override
  String get mindChallengeTitleGratitudeHabit => '감사 습관 만들기';

  @override
  String get mindChallengeDescGratitudeHabit =>
      '7일 동안 매일 감사한 순간을 찾아보며 긍정적인 시선을 길러요.';

  @override
  String get mindChallengeDayGratitudeHabit1 => '1일차: 오늘 감사했던 순간 하나를 떠올려보세요.';

  @override
  String get mindChallengeDayGratitudeHabit2 => '2일차: 나를 도와준 사람 한 명을 생각해보세요.';

  @override
  String get mindChallengeDayGratitudeHabit3 => '3일차: 당연하게 여겼던 것 하나에 감사해보세요.';

  @override
  String get mindChallengeDayGratitudeHabit4 =>
      '4일차: 오늘의 날씨나 풍경에서 좋은 점을 찾아보세요.';

  @override
  String get mindChallengeDayGratitudeHabit5 =>
      '5일차: 내가 가진 것 중 감사한 것 하나를 적어보세요.';

  @override
  String get mindChallengeDayGratitudeHabit6 => '6일차: 오늘 나에게 있었던 작은 행운을 찾아보세요.';

  @override
  String get mindChallengeDayGratitudeHabit7 => '7일차: 일주일간 발견한 감사한 순간들을 돌아보세요.';

  @override
  String get mindReportMoodTrendTitle => '마음 흐름 그래프';

  @override
  String get mindReportMoodTrendNotEnoughData =>
      '아직 데이터가 모이고 있어요. 조금 더 함께해주세요 🌱';

  @override
  String get moodTrendHeaderTitle => '마음 흐름 그래프';

  @override
  String get moodTrendIntroText =>
      '매일 남긴 감정 기록을 바탕으로, 최근 마음의 흐름을 그래프로 보여드려요. 점이 위에 있을수록 편안한 날, 아래에 있을수록 힘든 날이었어요.';

  @override
  String get moodTrendWindow7Days => '7일';

  @override
  String get moodTrendWindow14Days => '14일';

  @override
  String get moodTrendWindow30Days => '30일';

  @override
  String get moodTrendNotEnoughTitle => '아직 그래프를 그리기엔 일러요';

  @override
  String get moodTrendNotEnoughBody =>
      '최소 4일 이상 감정을 기록하면\n마음의 흐름을 그래프로 볼 수 있어요';

  @override
  String get moodTrendChartTitle => '마음 흐름';

  @override
  String moodTrendSessionsLabel(int count) {
    return '· 함께한 $count번';
  }

  @override
  String get moodTrendLegendPositive => '편안한 날';

  @override
  String get moodTrendLegendNegative => '힘들었던 날';

  @override
  String get moodTrendDirectionNotEnoughData => '아직 흐름을 판단하기엔 데이터가 조금 부족해요.';

  @override
  String get moodTrendDirectionImproving => '최근 마음이 조금씩 편안해지고 있는 흐름이에요 🌤️';

  @override
  String get moodTrendDirectionSteady => '마음이 잔잔하게 흐르고 있어요. 지금처럼 꾸준히 기록해봐요 🤍';

  @override
  String get moodTrendDirectionDeclining =>
      '요즘 마음이 조금 무거운 날들이 이어지고 있어요. 잠시 쉬어가도 괜찮아요 🫂';

  @override
  String get homeCheerBannerTitle => '💌 몽이의 응원 우편함';

  @override
  String get homeCheerBannerSubtitleBothDone => '오늘의 응원을 모두 주고받았어요';

  @override
  String get homeCheerBannerSubtitleHasNew => '오늘 도착한 응원이 있어요';

  @override
  String get homeCheerBannerSubtitleDefault => '작은 마음을 주고받아요';

  @override
  String get homeCheerBannerNewBadge => '받기';

  @override
  String get cheerScreenAppBarTitle => '몽이의 응원 우편함';

  @override
  String get cheerScreenHonestyNotice =>
      '이 앱은 아직 다른 사람과 직접 연결되지 않아요. 대신 몽이가 마음을 이어줘요 🐱';

  @override
  String get cheerSendSectionTitle => '마음 보내기';

  @override
  String get cheerSendSectionSubtitle => '골라두면 몽이가 대신 세상에 전해줘요';

  @override
  String get cheerSendDoneTitle => '오늘의 마음을 몽이에게 맡겼어요';

  @override
  String get cheerSendDoneSubtitle => '내일 또 다른 마음을 보낼 수 있어요';

  @override
  String get cheerSendConfirmSnackbar => '몽이가 마음을 잘 전달했어요 💌';

  @override
  String get cheerReceiveSectionTitle => '마음 받기';

  @override
  String get cheerReceiveButtonLabel => '오늘의 응원 열어보기';

  @override
  String get cheerReceiveCardLabel => '누군가의 마음';

  @override
  String cheerRewardEarned(int amount) {
    return '+$amount 빛의 정수';
  }

  @override
  String get cheerSendOption0 => '오늘도 애썼어요. 당신 몫을 잘 해내고 있어요.';

  @override
  String get cheerSendOption1 => '지금 이대로도 충분해요.';

  @override
  String get cheerSendOption2 => '당신의 하루도, 마음도 소중해요.';

  @override
  String get cheerSendOption3 => '잠깐 쉬어가도 괜찮아요.';

  @override
  String get cheerSendOption4 => '당신은 생각보다 훨씬 잘하고 있어요.';

  @override
  String get cheerSendOption5 => '오늘 하루도 무사히 지나갔어요. 그거면 충분해요.';

  @override
  String get cheerReceiveMessage0 => '오늘 하루도 버텨낸 당신, 정말 잘했어요.';

  @override
  String get cheerReceiveMessage1 => '누군가 오늘 당신을 응원하고 있어요.';

  @override
  String get cheerReceiveMessage2 => '지금까지 걸어온 길, 절대 헛되지 않았어요.';

  @override
  String get cheerReceiveMessage3 => '당신은 혼자가 아니에요.';

  @override
  String get cheerReceiveMessage4 => '작은 걸음도 걸음이에요. 잘 가고 있어요.';

  @override
  String get cheerReceiveMessage5 => '완벽하지 않아도 괜찮아요. 그게 사람이에요.';

  @override
  String get cheerReceiveMessage6 => '오늘의 당신에게 박수를 보내요 👏';

  @override
  String get cheerReceiveMessage7 => '힘든 날엔 잠시 멈춰도 괜찮아요.';

  @override
  String get cheerReceiveMessage8 => '당신의 노력을 알아주는 사람이 있어요.';

  @override
  String get cheerReceiveMessage9 => '오늘도 스스로를 조금 더 다정하게 대해줘요.';

  @override
  String get cheerReceiveMessage10 => '지금 이 순간에도 당신은 자라고 있어요.';

  @override
  String get cheerReceiveMessage11 => '괜찮지 않아도 괜찮아요. 그런 날도 있는 거예요.';

  @override
  String get cheerReceiveMessage12 => '당신이 여기 있어줘서 다행이에요.';

  @override
  String get cheerReceiveMessage13 => '오늘 하루, 스스로에게 참 잘했다고 말해줘요.';

  @override
  String get cheerReceiveMessage14 => '당신의 속도로 가도 충분해요.';

  @override
  String get cheerReceiveMessage15 => '누군가 당신의 안녕을 진심으로 바라고 있어요.';

  @override
  String mindReflectionEmotionWeekdayLink(
    String emotion,
    String weekday,
    int count,
  ) {
    return '$weekday마다 $emotion 감정이 유독 자주 떠올랐어요. 최근에 $count번이나 나타났답니다.';
  }

  @override
  String mindReflectionTriggerNegativeLink(String trigger, int count) {
    return '\'$trigger\'이(가) 힘든 감정과 자주 함께 나타났어요. 최근 $count번 정도요.';
  }

  @override
  String mindReflectionGrowthSignal(String emotion) {
    return '예전보다 $emotion 감정이 눈에 띄게 줄었어요. 조금씩 마음이 편해지고 있는 것 같아요.';
  }

  @override
  String get mindReflectionGratitudeMoodLink =>
      '감사한 일을 기록한 날은 다른 날보다 마음이 더 편안했어요.';

  @override
  String mindReflectionConsistencySignal(int streak) {
    return '$streak일 연속으로 마음을 들여다봤어요. 꾸준함 자체가 큰 힘이에요.';
  }

  @override
  String get mindReflectionDefaultObservation =>
      '아직 뚜렷한 패턴은 안 보이지만, 계속 기록하다 보면 몽이가 더 많은 걸 발견해줄 거예요.';

  @override
  String get settingsAiReflectionTitle => '🌿 마음 성찰';

  @override
  String get settingsAiReflectionDesc =>
      '여러 기록을 모아 몽이가 마음의 패턴을 짚어드려요. 서버로 전송되지 않고, 이 기기 안에서만 계산돼요. 원하실 때 언제든 끌 수 있어요.';

  @override
  String get mindReportReflectionTitle => '몽이의 마음 성찰';

  @override
  String get mindReportReflectionOptInPrompt =>
      '여러 기록을 모아 더 깊은 통찰을 보여드릴 수 있어요. 설정에서 켜보시겠어요?';

  @override
  String get mindReportReflectionOptInButton => '설정에서 켜기';

  @override
  String get mindReportReflectionNotEnoughData =>
      '아직 기록이 조금 더 필요해요. 일기를 5개 이상 남겨주세요.';
}
