// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Mongi';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingPage1Title => 'Hi, I\'m Mongi 🐾';

  @override
  String get onboardingPage1Desc =>
      'If there\'s a feeling still lingering in your heart today,\nlet\'s play together and let it go!';

  @override
  String get onboardingPage2Title => 'Mongi runs\nforward automatically';

  @override
  String get onboardingPage2Desc =>
      'Movement is automatic!\nJust focus on your button timing!';

  @override
  String get onboardingPage3Title =>
      'Left ✊ Punch button\nRight 🦘 Jump button';

  @override
  String get onboardingPage3Desc =>
      'Punch small rocks right on time!\nBig rocks must be dodged with the jump button.';

  @override
  String get onboardingPage4Title =>
      'When you touch an emotion monster,\nMongi welcomes it into your heart';

  @override
  String get onboardingPage4Desc =>
      'Emotions you\'ve faced bloom\ninto pretty flowers in your garden 🌷';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingFinish => 'Go meet Mongi 🐾';

  @override
  String get homeHeadline =>
      'Is there a feeling\nstill lingering in your heart today?';

  @override
  String get homeSubCaption =>
      'Left ✊ Punch button / Right 🦘 Jump button!\nMongi will meet the emotion monsters for you and take them in!';

  @override
  String get navHome => 'Home';

  @override
  String get navGarden => 'Garden';

  @override
  String get navShop => 'Shop';

  @override
  String get navLetter => 'Letter';

  @override
  String get navMission => 'Mission';

  @override
  String get navSettings => 'Settings';

  @override
  String get homeHelpTooltip => 'Replay tutorial';

  @override
  String homeGardenBadgeProgress(int percent) {
    return 'Garden recovery $percent%';
  }

  @override
  String homeGardenBadgeStage(int stage) {
    return '🐾 Mongi stage $stage';
  }

  @override
  String homeGardenBadgeStreak(int days) {
    return '🔥 Day $days';
  }

  @override
  String homeGardenBadgeCheckInStreak(int days) {
    return '✅ Check-in day $days';
  }

  @override
  String get homeSupportAlertTitle =>
      'It looks like things have been heavy lately';

  @override
  String get homeSupportAlertBody =>
      'You don\'t have to carry it alone. There\'s always someone to talk to.';

  @override
  String get homeComebackCareTitleShort => 'Good to see you again!';

  @override
  String homeComebackCareBodyShort(int days) {
    return 'It\'s been $days days. Even after a short break, Mongi was always here waiting for you 🌱';
  }

  @override
  String get homeComebackCareTitleLong =>
      'It\'s been a while - how have you been?';

  @override
  String homeComebackCareBodyLong(int days) {
    return 'It\'s been $days days since your last visit. That\'s okay - Mongi was doing just fine here the whole time. Let\'s start again slowly, from today 💛';
  }

  @override
  String get homeChargeButton => 'Top up';

  @override
  String get homeMindBoxChip => 'Mind Box';

  @override
  String homePowerCharmChip(int count) {
    return 'Power Charm $count';
  }

  @override
  String get homeMongiCareChip => 'Mongi Care';

  @override
  String homeTodayGoalBadge(String hint) {
    return '🎯 Today\'s goal: $hint';
  }

  @override
  String homeSeasonBannerTitle(int season, int level) {
    return 'Season $season · Mongi\'s Journey of the Heart · Lv.$level';
  }

  @override
  String get homeSeasonBannerSubtitle => 'Tap to check season rewards';

  @override
  String get commonClaim => 'Claim!';

  @override
  String get homeDailyMissionTitle => 'Mongi\'s Daily Mission';

  @override
  String get homeDailyMissionSubtitle => 'Tap to check today\'s rewards';

  @override
  String homeDailyMissionClaimCount(int count) {
    return 'Claim! $count';
  }

  @override
  String get homeMindReportButton => 'Mind Report';

  @override
  String get homeBreathingButton => 'Breathe';

  @override
  String get homeNameFieldHint =>
      'Want to tell only Mongi why you feel this way today? (optional)';

  @override
  String get homeHowToTitle => '👇 How to play';

  @override
  String get homeHowToStep1 => 'Pick your\nemotions below\n(up to 3)';

  @override
  String get homeHowToStep2 => 'Start running\nwith Mongi!';

  @override
  String get homeHowToStep3 => 'On contact, Mongi\ntakes it into its heart';

  @override
  String get homeHowToStep4 => 'It stays in your garden\nas a seed';

  @override
  String get homeMaxSelectSnackbar => 'You can select up to 3';

  @override
  String get homeIntensityLabel =>
      'How strong does this feeling feel right now?';

  @override
  String get homeFriendlyCaption =>
      'Whatever you\'re feeling today, Mongi loves it all 🐾';

  @override
  String homeEndlessButtonRecord(int count) {
    return '♾️ Endless Challenge! (Best: $count)';
  }

  @override
  String get homeEndlessButtonNoRecord =>
      '♾️ Set today\'s best in Endless Challenge';

  @override
  String homeStartButtonEnabled(int selected, int max) {
    return 'Start running with Mongi! 🐾 ($selected/$max)';
  }

  @override
  String homeStartButtonDisabled(int max) {
    return 'Please select an emotion (up to $max)';
  }

  @override
  String get homeQuietModeButton => '🌙 Face it quietly';

  @override
  String get homeMonetizationSectionLabel => 'Shop & currency below';

  @override
  String get quietModeAppBarTitle => 'Quiet Mode';

  @override
  String get quietModeGreetTitle => 'Shall we gently face this feeling today?';

  @override
  String get quietModeGreetSubtitle =>
      'No need to rush. Mongi is right here with you.';

  @override
  String get quietModeGreetNextButton => 'Next';

  @override
  String get quietModeBreatheTitle => 'Let\'s take a breath for a moment';

  @override
  String get quietModeBreatheStartButton => 'Start';

  @override
  String get quietModeBreatheSkipButton => 'Skip';

  @override
  String get quietModeReflectTitle => 'Want to jot a short note? (optional)';

  @override
  String get quietModeReflectHint => 'Write a short note about how you feel';

  @override
  String get quietModePlantButton => 'Plant in your heart';

  @override
  String get quietModePlantingMessage =>
      'Your feeling is quietly settling into the garden...';

  @override
  String get quietModeDoneTitle => 'You\'ve planted it well';

  @override
  String quietModeDoneBody(int count) {
    return '$count feeling(s) have bloomed into flowers in your garden. You can revisit them anytime.';
  }

  @override
  String get quietModeDoneHomeButton => 'Home';

  @override
  String get quietModeDoneGardenButton => 'View Garden';

  @override
  String get shopTitle => '🛍️ Shop';

  @override
  String get shopSectionCurrency => '💰 Top Up Currency';

  @override
  String get shopLightEssenceTitle => 'Top Up Light Essence';

  @override
  String get shopLightEssenceSubtitle =>
      'Refill Light Essence instantly with a purchase (100 for \$3.99 · 1,000 for \$7.99)';

  @override
  String get shopSectionConsumables => '🎁 Consumables & Decor';

  @override
  String get shopMindBoxTitle => 'Mind Box';

  @override
  String get shopMindBoxSubtitle =>
      'Collect Mongi costumes with Light Essence (guaranteed, no random odds)';

  @override
  String get shopPowerCharmTitle => 'Power Charm';

  @override
  String shopPowerCharmSubtitle(int count) {
    return 'A consumable that makes you invincible for 10 seconds in-game (you have $count)';
  }

  @override
  String get shopMongiCareTitle => 'Mongi Care Set';

  @override
  String get shopMongiCareSubtitle =>
      'From tuna cans and food to special gifts like a cozy blanket';

  @override
  String get shopGardenDecoTitle => 'Decorate Garden';

  @override
  String get shopGardenDecoSubtitle =>
      'Free decorations like benches & fountains + premium decor packs';

  @override
  String get shopSectionSeason => '🌟 Season & Membership';

  @override
  String get shopSeasonPassTitle =>
      'Mongi\'s Journey of the Heart (Season Pass)';

  @override
  String get shopSeasonPassSubtitle =>
      'Get richer rewards on this season\'s limited premium track';

  @override
  String get settingsHeader => '⚙️ Settings';

  @override
  String get settingsNotifTitle => 'Daily Mongi Reminder';

  @override
  String get settingsNotifPermissionDenied =>
      'Notification permission is required. Please allow it in device settings.';

  @override
  String get settingsNotifDesc =>
      'Mongi will ask about your feelings once at a set time every day.\nJust a single, gentle nudge - never intrusive.';

  @override
  String get settingsNotifTimeLabel => 'Reminder time';

  @override
  String get settingsLanguageTitle => 'Language';

  @override
  String get settingsLanguageSystem => 'System default';

  @override
  String get settingsLanguageKorean => '한국어';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsDataNoticeTitle => '📱 Data Storage Notice';

  @override
  String get settingsDataNoticeBody =>
      'Mongi requires no login and stores your garden, diary, and progress only on this device. If you delete the app or switch devices, this record will be lost.\nPurchased items can be restored via your Google account, but the garden itself cannot be restored.';

  @override
  String get settingsMentalHealthTitle => 'When things feel hard';

  @override
  String get settingsMentalHealthSubtitle =>
      'You don\'t have to endure it alone · View 24/7 support resources';

  @override
  String get settingsPrivacyPolicy => 'Privacy Policy';

  @override
  String get settingsResetTitle => 'Start Over From Scratch';

  @override
  String get settingsResetDesc =>
      'Erase all stages, currency, costumes, and garden progress so far\nand start fresh from stage 1. Useful for testing or reliving the first-time experience.';

  @override
  String get settingsResetButton => 'Reset progress and start from stage 1';

  @override
  String get settingsResetConfirmTitle => 'Are you sure you want to reset?';

  @override
  String get settingsResetConfirmBody =>
      'All stages, currency, costumes, and garden progress will be erased\nand you\'ll start over from stage 1. This cannot be undone.';

  @override
  String get settingsResetConfirmButton => 'Reset';

  @override
  String get settingsWebNotice =>
      '💡 Notifications are only available on the Android app.';

  @override
  String get gamePunchLabel => 'Punch';

  @override
  String get gameJumpLabel => 'Jump';

  @override
  String get gameLoadErrorTitle =>
      'There was a problem loading the stage.\nPlease try again.';

  @override
  String get gameLoadErrorButton => 'Go back';

  @override
  String get gameHintAutoRun => 'Mongi runs forward automatically';

  @override
  String gameHintTimeLimit(int seconds) {
    return '⏰ Reach the goal within ${seconds}s!';
  }

  @override
  String get gameHintControlsStage1 =>
      'Tap the right 🦘 Jump button to jump right away!';

  @override
  String get gameHintControlsStage2Plus =>
      'Tap the left ✊ Punch button / right 🦘 Jump button!';

  @override
  String get gameHintDodgeStage1 =>
      'Dodge rocks with a jump, and just pass by emotion monsters to welcome them in!';

  @override
  String get gameHintDodgeStage2Plus =>
      'Time your punch for small rocks! Always jump over big rocks';

  @override
  String gameHudStage(int stage) {
    return 'Stage $stage';
  }

  @override
  String get gameTimeOfDayDawn => 'Dawn Garden';

  @override
  String get gameTimeOfDayNight => 'Night Garden';

  @override
  String gameTimeOfDayBadge(String label) {
    return 'It\'s $label right now';
  }

  @override
  String gamePowerModeBadge(int seconds) {
    return '⚡ Invincible! ${seconds}s';
  }

  @override
  String gameTimeBadge(int seconds) {
    return '⏰ ${seconds}s';
  }

  @override
  String gameComboBadge(int combo) {
    return '🔥 Combo x$combo';
  }

  @override
  String get gameExitConfirmTitle => 'End the game?';

  @override
  String get gameExitConfirmBody =>
      'Your progress so far won\'t be saved, and you\'ll return to the start screen.';

  @override
  String get gameExitConfirmButton => 'End';

  @override
  String get appExitConfirmTitle => 'Wrap up your time with Mongi?';

  @override
  String get appExitConfirmBody =>
      'Everything you\'ve recorded so far is safely saved. See you again soon 🌱';

  @override
  String get appExitConfirmButton => 'Exit';

  @override
  String get endlessHintTitle => 'Challenge Mongi\'s best record today!';

  @override
  String get endlessHintGoal =>
      'Collect as many as you can before you run out of lives';

  @override
  String endlessHudBestRecord(int count) {
    return '👑 Best $count';
  }

  @override
  String get homeMongiMoodWaiting =>
      'Mongi is waiting to see what feelings today will bring.';

  @override
  String get homeMongiMoodJoyful =>
      'Things have felt light lately! Mongi is happily hopping around 🐾';

  @override
  String get homeMongiMoodHeavy =>
      'Things have felt a bit heavy these past few days. Mongi is curled up beside you.';

  @override
  String get homeMongiMoodCalm =>
      'Mongi is calmly keeping you company, just like always.';

  @override
  String get homeEasterEgg0 =>
      'Mongi made a strange sound today... \"Grrrr meow meow?\" 🐱';

  @override
  String get homeEasterEgg1 =>
      'Mongi suddenly high-fived the wall. Only Mongi knows why.';

  @override
  String get homeEasterEgg2 =>
      'Mongi chased its own tail for 30 seconds. It finally caught it.';

  @override
  String get homeEasterEgg3 =>
      'Mongi took three naps today. Maybe it met a fish in its dreams.';

  @override
  String get homeEasterEgg4 =>
      'Mongi stared out the window lost in thought. What could it be thinking about?';

  @override
  String get homeEasterEgg5 =>
      'Mongi gave itself a round of applause today. The reason is a secret.';

  @override
  String get homeEasterEgg6 =>
      'Mongi suddenly let out a big \"Meow!\" It just felt good.';

  @override
  String get homeEasterEgg7 => 'Mongi proudly showed off its paw pads.';

  @override
  String get homeEasterEgg8 =>
      'Mongi wrote \"be cute\" on today\'s to-do list and checked it off.';

  @override
  String get homeEasterEgg9 =>
      'Mongi got startled by its own shadow and jumped. It\'s okay now.';

  @override
  String get homeEasterEgg10 =>
      'Mongi had a long chat with itself in the mirror this morning.';

  @override
  String get homeEasterEgg11 =>
      'Mongi walked in circles around the room three times for no reason, then sat back down.';

  @override
  String get gardenTapHint =>
      'Tap a seed to see how much it has grown · Use \"Decorate\" in the top right to place items';

  @override
  String get gardenHeaderTitle => '🌷 My Mind Garden';

  @override
  String get gardenTooltipCollection => 'Emotion Collection';

  @override
  String get gardenTooltipMilestone => 'Growth Documentary';

  @override
  String get gardenTooltipShare => 'Share Garden';

  @override
  String get gardenTooltipCalendar => 'Emotion Calendar';

  @override
  String get gardenTooltipDiary => 'Diary';

  @override
  String gardenSummaryFlowersPlanted(int count) {
    return 'You\'ve bloomed $count flowers of the heart so far';
  }

  @override
  String get gardenStatRecoveryLabel => 'Recovery';

  @override
  String get gardenStatMongiLabel => 'Mongi';

  @override
  String get gardenStatStreakLabel => 'Streak';

  @override
  String get gardenStatScoreLabel => 'Score';

  @override
  String gardenStatPercentValue(int percent) {
    return '$percent%';
  }

  @override
  String gardenStatStageValue(int stage) {
    return 'Stage $stage';
  }

  @override
  String gardenStatStreakValue(int days) {
    return '$days days';
  }

  @override
  String gardenStatScoreValue(int score) {
    return '$score pts';
  }

  @override
  String get gardenTreeWiltedHint =>
      'Mongi\'s growth tree looks a bit bored · Visit today and it\'ll perk right back up 🌤️';

  @override
  String gardenTreeMaxStageHint(String label) {
    return 'Mongi\'s growth tree has fully bloomed into a $label!';
  }

  @override
  String gardenTreeGrowthHint(String label, int remaining) {
    return 'Mongi\'s growth tree right now: $label · $remaining pts to next growth';
  }

  @override
  String get gardenEmptyTitle => 'No flowers planted yet';

  @override
  String get gardenEmptyBody =>
      'As you face your feelings one by one,\na flower will bloom right here';

  @override
  String gardenFlowerBedTitle(String emotionLabel) {
    return '$emotionLabel\'s Garden';
  }

  @override
  String get gardenTreeStageSeed => 'Seed';

  @override
  String get gardenTreeStageSprout => 'Sprout';

  @override
  String get gardenTreeStageTree => 'Tree';

  @override
  String get gardenTreeStageFlower => 'Flower';

  @override
  String get gardenTreeStageFruit => 'Fruit';

  @override
  String get gardenSceneTitle => '🌿 My Garden';

  @override
  String get gardenSceneCareButton => 'Care';

  @override
  String get gardenSceneDecorateButton => 'Decorate';

  @override
  String gardenSeedPotWatered(String seedLabel, int count) {
    return '$seedLabel · Watered $count times so far';
  }

  @override
  String gardenSeedPotNotPlanted(String seedLabel) {
    return '$seedLabel seed hasn\'t been planted yet';
  }

  @override
  String get gardenTreeWiltedSnackbar =>
      'Mongi\'s growth tree looks a bit bored · Visit again today and it\'ll perk right back up 🌤️';

  @override
  String gardenTreeStageSnackbar(String label) {
    return 'Mongi\'s growth tree · Currently at the $label stage';
  }

  @override
  String get gardenSeasonSpring => 'Spring';

  @override
  String get gardenSeasonSummer => 'Summer';

  @override
  String get gardenSeasonAutumn => 'Autumn';

  @override
  String get gardenSeasonWinter => 'Winter';

  @override
  String get gardenSeasonGreetingSpring =>
      'Cherry blossoms are drifting through Mongi\'s garden';

  @override
  String get gardenSeasonGreetingSummer =>
      'Mongi\'s garden is sparkling with lush summer light';

  @override
  String get gardenSeasonGreetingAutumn =>
      'Fallen leaves are gently drifting through Mongi\'s garden';

  @override
  String get gardenSeasonGreetingWinter =>
      'Snow is quietly piling up in Mongi\'s garden';

  @override
  String choiceStageClearBody(int currentStage, int nextStage) {
    return 'You completed stage $currentStage!\nReady to move on to stage $nextStage?';
  }

  @override
  String get choiceStageClearHint =>
      'The next stage\'s rocks are a bit bigger and faster,\nbut Mongi will be a little braver too 🌟';

  @override
  String get choiceStageClearStayButton => 'I\'ll stay here';

  @override
  String get choiceStageClearAdvanceButton => 'Next stage! 🚀';

  @override
  String choiceAskingTargetLabel(String targetName, String emotionsLabel) {
    return '$emotionsLabel about $targetName';
  }

  @override
  String choiceAskingHeadlineWithCount(String nameLabel, int count) {
    return 'Today, Mongi took in\n$count of $nameLabel!';
  }

  @override
  String choiceAskingHeadlineNoCount(String nameLabel) {
    return 'Today you briefly faced\n$nameLabel in your heart';
  }

  @override
  String get choiceAskingPrompt => 'Shall we plant\na feeling there now?';

  @override
  String get choiceAskingNotYetButton => 'Not just yet';

  @override
  String get choiceAskingPlantButton => 'Yes, let\'s plant';

  @override
  String choiceEarlyStopWithRemaining(int count, int remaining) {
    return 'You met $count feelings today.\n$remaining more got away — will you catch them next time? 🤍';
  }

  @override
  String choiceEarlyStopNoRemaining(int count) {
    return 'You met $count feelings today.\nThat\'s more than enough — will you come back again? 🤍';
  }

  @override
  String choiceComboLow(int count) {
    return 'Even at a wobbly moment, you held on $count times';
  }

  @override
  String choiceComboMid(int count) {
    return '$count in a row without wavering — you kept your heart steady!';
  }

  @override
  String choiceComboHigh(int count) {
    return '$count in a row! Mongi is unusually sturdy today 💪';
  }

  @override
  String choiceInsightFrequentPositive(int count) {
    return 'This feeling has already come up $count times this week.\nSeems like a good feeling that\'s visiting often lately ☺️';
  }

  @override
  String choiceInsightFrequentNegative(int count) {
    return 'This feeling has already come up $count times this week.\nIt seems to be visiting often lately. Mongi will keep watching over you.';
  }

  @override
  String get choiceInsightAllPositive =>
      'Today was filled with only good energy.\nA day like that is a precious gift for Mongi too ✨';

  @override
  String choiceInsightLongAbsence(String emotionLabel, int days) {
    return 'Long time no see! You met $emotionLabel\nagain after $days days. Have you been okay?';
  }

  @override
  String choiceInsightFirstEncounter(String emotionLabel) {
    return 'You recorded $emotionLabel in your diary for the first time.\nThank you for showing courage. Mongi will remember it for a long time.';
  }

  @override
  String choiceNextGoalAlmostCollected(int count) {
    return 'Meet just $count more feelings and your collection will be complete!\nWhat feeling will it be next? 🔍';
  }

  @override
  String choiceNextGoalTreeAlmost(int points) {
    return 'Mongi\'s tree is only $points points away from the next stage.\nWill you stay with it a little longer? 🌳';
  }

  @override
  String choiceNextGoalManyUncollected(int count) {
    return 'There are still $count feelings you haven\'t met yet.\nWhich feeling will you meet next?';
  }

  @override
  String get choiceSeedSelectTitle => 'Which feeling shall we plant?';

  @override
  String get choiceSeedSelectSubtitle =>
      'Pick one, and it will grow\nin Mongi\'s little garden';

  @override
  String choiceSeedWateredCount(int count) {
    return 'You\'ve watered it $count times so far';
  }

  @override
  String get choiceBackButton => 'Back';

  @override
  String choicePlantingTitle(String seedLabel) {
    return 'Watering the seed\nof $seedLabel';
  }

  @override
  String choicePlantingSubtitle(String seedLabel) {
    return '$seedLabel is growing in Mongi\'s garden 🌱';
  }

  @override
  String choiceTreeGrowthTitle(String label) {
    return 'Mongi\'s growth tree has grown\ninto a $label!';
  }

  @override
  String get choiceTreeGrowthHint =>
      'The more steadily you face your feelings,\nthe bigger the tree grows 🌱';

  @override
  String choiceTreeGrowthBonus(int bonus) {
    return 'A special gift for the tree\'s growth, Light Essence +$bonus';
  }

  @override
  String get choiceTreeGrowthShareButton => 'Share this moment';

  @override
  String get choiceResultTitleBloomed => 'The garden has burst into bloom! 🌸';

  @override
  String choiceResultTitleSeedPlanted(String seedLabel) {
    return 'A seed of $seedLabel was planted in your heart';
  }

  @override
  String get choiceResultTitlePlanted => 'A feeling was planted';

  @override
  String get choiceResultTitleGentle => 'It\'s okay, take your time';

  @override
  String get choiceResultMessageLove =>
      'Warm light has seeped\ninto that once-dark spot ✨';

  @override
  String get choiceResultMessageNoLove =>
      'Your heart is already a little lighter\nfor the feelings you faced together today\nCome back whenever you\'re ready 🤍';

  @override
  String get choiceResultLevelUpStage2 =>
      '\n\nMongi can now reach out and break small rocks! 💪';

  @override
  String choiceResultLevelUpOther(int stage) {
    return '\n\nMongi grew to stage $stage! The rocks got a bit bigger, but Mongi got braver too 🌟';
  }

  @override
  String choiceResultLightEarned(int earned, int total) {
    return '💡 +$earned (you have $total)';
  }

  @override
  String choiceResultGoldenFrameTitle(String emotionLabel) {
    return 'Got the \"$emotionLabel\" golden frame!';
  }

  @override
  String get choiceResultGoldenFrameDesc =>
      'A rare mark you can only get with an extremely low chance.\nShow it off in your emotion collection!';

  @override
  String choiceResultSeedGrown(String seedLabel) {
    return 'The $seedLabel garden grew a little more';
  }

  @override
  String get choiceResultGardenButton => 'Visit my heart garden';

  @override
  String get choiceResultNoteLabel =>
      'Want to leave this feeling as a sentence today? (optional)';

  @override
  String get choiceResultNoteHint => 'e.g. I feel a bit lighter today';

  @override
  String get choiceResultShareButton => 'Share emotion card';

  @override
  String get choiceResultHomeButton => 'Home';

  @override
  String get choiceIntensityLabel =>
      'How strongly did you feel this emotion today?';

  @override
  String get choiceIntensityVeryWeak => 'Very weak';

  @override
  String get choiceIntensityWeak => 'Weak';

  @override
  String get choiceIntensityNormal => 'Normal';

  @override
  String get choiceIntensityStrong => 'Strong';

  @override
  String get choiceIntensityVeryStrong => 'Very strong';

  @override
  String get choiceTriggerLabel =>
      'What was it because of? (optional, multiple choice)';

  @override
  String get choiceTranscendenceBadge => 'You discovered a hidden moment';

  @override
  String choiceTranscendenceTitle(String emotionLabel) {
    return '\"$emotionLabel\" has transcended';
  }

  @override
  String get choiceTranscendenceDesc =>
      'A feeling that stayed with you a hundred times over.\nNo one told you in advance, but you did it.';

  @override
  String get choiceSeasonMilestoneBadge => 'Heart Journey Milestone';

  @override
  String get seasonMilestoneLevel5 =>
      'Level 5 already! Proof you\'ve been caring for your heart little by little every day 🌱';

  @override
  String get seasonMilestoneLevel10 =>
      'You\'re past halfway. Every day you\'ve built up so far is truly precious 🌿';

  @override
  String get seasonMilestoneLevel15 =>
      'Level 15, not much left now. Your consistency is amazing 🌳';

  @override
  String get seasonMilestoneLevel20 =>
      'You completed this season\'s heart journey! This is the moment Mongi is proudest of 🌟';

  @override
  String get privacyHeaderTitle => '🔒 Privacy Policy';

  @override
  String get privacyIntro =>
      'Mongi is an app with no login. This policy explains, in plain language, what information Mongi handles and how it\'s protected.';

  @override
  String get privacySection1Title => '1. No login or sign-up';

  @override
  String get privacySection1Body =>
      'Mongi has no login or sign-up process at all. We don\'t request or collect account information like your name, email, or phone number. Even if you enter a nickname on the emotion input screen, that information is stored only on this device.';

  @override
  String get privacySection2Title => '2. Data is stored only on this device';

  @override
  String get privacySection2Body =>
      'All records you build up with Mongi — emotion diary entries, garden growth state, stage progress, owned costumes, and more — are never sent to a server and are kept only in this device\'s local storage (Hive). We (the developers) can\'t see this content either.\n\n⚠️ Because of this, if you delete the app or switch devices, the garden, diary, and progress you\'ve built up will be lost together (purchased items are linked to your Google account and can be recovered via \"Restore Purchases\", but the garden itself cannot be restored). If your records are precious to you, we recommend occasionally taking screenshots to keep them.';

  @override
  String get privacySection3Title => '3. Advertising service (Google AdMob)';

  @override
  String get privacySection3Body =>
      'To provide more features for free, we show Google AdMob ads. In the process of displaying ads and providing personalized ads, Google may collect and process your advertising identifier (Advertising ID), device information, IP address, and more, according to its own policies. This information is processed by Google, not by us; you can find more details in Google\'s privacy policy.\n\nYou can turn on \"Opt out of Ads Personalization\" in your device settings to use the app without personalized ads.';

  @override
  String get privacySection4Title =>
      '4. In-app purchases (Google Play Billing)';

  @override
  String get privacySection4Body =>
      'Purchases of cosmetic items (card frames, garden decorations, costumes, etc.) are processed through the Google Play billing system. Payment information (such as card numbers) is never shared with us and is handled directly by Google. We only check \"which item was purchased\" in order to grant that item to you.';

  @override
  String get privacySection5Title => '5. Notification permission';

  @override
  String get privacySection5Body =>
      'We may request notification permission in order to send you a reminder at a set time each day. This permission is used only for sending local notifications, and you can turn it off anytime from the settings screen or your device settings.';

  @override
  String get privacySection6Title => '6. Use by children under 14';

  @override
  String get privacySection6Body =>
      'Mongi doesn\'t collect account-based data, but we recommend that children under 14 use it under a guardian\'s supervision. Since payment features are included, guardians should check device settings related to in-app purchases (such as requiring a password for purchases).';

  @override
  String get privacySection7Title => '7. Contact';

  @override
  String privacySection7Body(String email) {
    return 'If you have any questions about how your information is handled, feel free to contact us anytime at the email below.\n\n$email';
  }

  @override
  String get privacySection8Title => '8. Policy changes';

  @override
  String get privacySection8Body =>
      'This privacy policy may be revised due to changes in law or our services. If there are any important changes, we\'ll let you know through an in-app notice.';

  @override
  String get privacyAdConsentTitle => '🍪 Ad Privacy Options';

  @override
  String get privacyAdConsentBody =>
      'In the EEA, UK, and some other regions, you can revisit and change your consent for personalized ads at any time.';

  @override
  String get privacyAdConsentButton => 'Manage ad privacy options';

  @override
  String get privacyAdConsentNotAvailable =>
      'Ad privacy options can\'t be changed right now. Please try again later.';

  @override
  String get privacyTermsOfServiceButton => 'View Terms of Service';

  @override
  String get privacyLastUpdatedDate => 'August 25, 2026';

  @override
  String privacyLastUpdatedLabel(String date) {
    return 'Last updated: $date';
  }

  @override
  String get mentalHealthHeaderTitle => '🤍 When it\'s hard';

  @override
  String mentalHealthCallFailedSnackbar(String number) {
    return 'Couldn\'t connect the call. Please dial $number directly.';
  }

  @override
  String mentalHealthActionFailedSnackbar(String action) {
    return 'Couldn\'t connect. Please try $action directly.';
  }

  @override
  String get mentalHealthOpenButtonLabel => 'Open';

  @override
  String mentalHealthSmsFailedSnackbar(String number) {
    return 'Couldn\'t open messaging app. Please text $number directly.';
  }

  @override
  String get mentalHealthSendSmsButtonLabel => 'Send text';

  @override
  String get mentalHealthIntroBody1 =>
      'Mongi is a friend who helps you gently face and record your feelings.\nBut if things feel too heavy to bear right now,\nit\'s better to talk to a professional counselor who can support you far more than Mongi can.';

  @override
  String get mentalHealthIntroBody2 =>
      'It\'s okay if calling feels hard. The numbers below are available 24/7, anonymously,\nand completely free to listen to you. You don\'t have to go through this alone.';

  @override
  String get mentalHealthCallSectionTitle => '📞 Places you can reach anytime';

  @override
  String get mentalHealthHelpline1Name => 'Suicide Prevention Counseling';

  @override
  String get mentalHealthHelpline1Desc =>
      '24/7 · Dial 109 nationwide, no area code needed\nFor when you\'re having thoughts of suicide, or worried about someone struggling';

  @override
  String get mentalHealthHelpline2Name => 'Mental Health Crisis Counseling';

  @override
  String get mentalHealthHelpline2Desc =>
      '24/7 · For any moment your heart feels heavy — depression, anxiety, and more';

  @override
  String get mentalHealthHelpline3Name => 'Youth Helpline 1388';

  @override
  String get mentalHealthHelpline3Desc =>
      '24/7 · Counseling for youth concerns (school, relationships, family, and more)';

  @override
  String get mentalHealthHelpline4Name => 'Emergency Report';

  @override
  String get mentalHealthHelpline4Desc =>
      'If your life or someone else\'s is in danger right now';

  @override
  String get mentalHealthGlobalIntroNote =>
      'Outside Korea, please use the country-specific helplines below. We\'ll start\nwith a global directory that covers helplines in 130+ countries.';

  @override
  String get mentalHealthGlobalHelpline1Name => 'Find A Helpline';

  @override
  String get mentalHealthGlobalHelpline1Desc =>
      'A global directory that helps you find helplines in 130+ countries.\nSelect your country to get connected to local support.';

  @override
  String get mentalHealthGlobalHelpline2Name =>
      '988 Suicide & Crisis Lifeline (US)';

  @override
  String get mentalHealthGlobalHelpline2Desc =>
      '24/7 · Call or text 988 in the US\nIf you\'re in the US, you can connect directly with this number';

  @override
  String get mentalHealthGlobalHelpline3Name => 'Crisis Text Line (US)';

  @override
  String get mentalHealthGlobalHelpline3Desc =>
      '24/7 · Text HOME to 741741 in the US\nIf calling feels hard, you can get support by text instead';

  @override
  String get mentalHealthGlobalHelpline4Name => 'SAMHSA National Helpline (US)';

  @override
  String get mentalHealthGlobalHelpline4Desc =>
      '24/7 · Call 1-800-662-4357 in the US\nCounseling and local resource referrals for mental health and substance use';

  @override
  String get mentalHealthGlobalFooterNote =>
      '※ 988, 741741, and SAMHSA above are US-specific examples and may not connect\noutside the US. If you\'re elsewhere, please use Find A Helpline to select your\ncountry and find local support.';

  @override
  String get mentalHealthNearbyCounselingTitle =>
      'Find a counseling center near me';

  @override
  String get mentalHealthNearbyCounselingSubtitle =>
      'If calling feels hard, you can visit a nearby center in person';

  @override
  String get mentalHealthSafetyPlanTitle => 'Create your own safety plan';

  @override
  String get mentalHealthSafetyPlanSubtitle =>
      'Preparing it while you\'re feeling calm can give you strength later';

  @override
  String get mentalHealthSignsTitle => '💡 Please reach out for help when...';

  @override
  String get mentalHealthSign1 =>
      'You\'ve felt low or sad for more than 2 weeks';

  @override
  String get mentalHealthSign2 =>
      'Thoughts like \"I want to disappear\" or \"I want to end it\" keep coming back';

  @override
  String get mentalHealthSign3 =>
      'Someone around you seems unusually withdrawn or struggling';

  @override
  String get mentalHealthSign4 =>
      'You want to talk to someone but don\'t know how to say it';

  @override
  String get mentalHealthSignsFooter =>
      'If even one of these applies to you, it\'s not because you\'re weak —\nit just means you need a bit more support right now.';

  @override
  String get mentalHealthFooterNote =>
      '※ The numbers listed are official counseling channels operated by South Korea\'s Ministry of Health and Welfare, run independently with no direct affiliation to the Mongi app. Numbers may change,\nso if you can\'t connect, search \"suicide prevention counseling (자살예방상담전화)\" in a search engine for the latest number.';

  @override
  String get shareFrameLabelDefault => 'Default';

  @override
  String get shareFrameLabelCherry => 'Cherry Blossom';

  @override
  String get shareFrameLabelGold => 'Gold Starlight';

  @override
  String shareNameLabelWithTarget(String targetName, String emotionLabel) {
    return '$emotionLabel about $targetName';
  }

  @override
  String get shareCardNotFoundError => 'Couldn\'t find the card.';

  @override
  String get shareImageConvertError => 'Failed to convert the image.';

  @override
  String shareTextBody(String nameLabel, int count) {
    return 'Today, faced $nameLabel with Mongi $count times 🐱🌿 #Mongi #EmotionDiary';
  }

  @override
  String get shareErrorSnackbar =>
      'Something went wrong while sharing. Please try again in a moment.';

  @override
  String get sharePremiumDialogTitle => 'Premium Card Frame Pack 🔓';

  @override
  String get sharePremiumDialogBody =>
      'Get permanent access to the Cherry Blossom and Gold Starlight frames.\nA one-time purchase — no need to pay again.';

  @override
  String get sharePremiumDialogLater => 'Later';

  @override
  String get sharePremiumDialogBuy => 'Buy';

  @override
  String get sharePurchaseProcessingSnackbar => 'Processing your purchase...';

  @override
  String get purchaseMessageWebNotSupported =>
      'In-app purchases can\'t be tested in the web preview. Please use the Android app.';

  @override
  String get purchaseMessageWebRestoreNotSupported =>
      'Restoring purchases isn\'t supported in the web preview.';

  @override
  String get purchaseMessageServiceUnavailable =>
      'Purchases aren\'t available right now. Please try again in a moment.';

  @override
  String get purchaseMessageProductNotFound =>
      'Couldn\'t load product info. Please check the store listing.';

  @override
  String get purchaseMessageRequestFailed =>
      'Something went wrong with the purchase request.';

  @override
  String get purchaseMessageStoreError =>
      'Something went wrong with the purchase.';

  @override
  String get notificationTitle => 'Mongi 🐱';

  @override
  String get notificationChannelName => 'Daily Heart Reminder';

  @override
  String get notificationChannelDescription =>
      'Mongi lets you know it\'s time to share your feelings, once a day.';

  @override
  String get notificationReminderMessage1 =>
      'Mongi is wondering how your day went 🐾';

  @override
  String get notificationReminderMessage2 =>
      'If feelings are piling up inside, share them with Mongi 🐱';

  @override
  String get notificationReminderMessage3 =>
      'Want to tend the Garden of the Heart with Mongi today? 🌱';

  @override
  String get notificationReminderMessage4 =>
      'Got a moment? Tell Mongi how you\'re feeling today 🌸';

  @override
  String get notificationReminderMessage5 =>
      'Mongi is waiting for you in the little garden 🌷';

  @override
  String get shareTitle => 'Today\'s Emotion Card';

  @override
  String get shareSubtitle => 'Share today\'s feelings with a friend';

  @override
  String get sharePurchaseConfirming => 'Confirming purchase...';

  @override
  String get sharePurchasePremiumButton => 'Buy premium frames';

  @override
  String get shareCreatingCard => 'Creating card...';

  @override
  String get shareCardButton => 'Share card';

  @override
  String get shareRestorePurchaseButton =>
      'Already purchased? Restore purchase';

  @override
  String get shareCardBrand => 'Mongi';

  @override
  String shareCardHeadlineWithCount(String nameLabel, int count) {
    return 'Today, faced $nameLabel\n$count times with Mongi';
  }

  @override
  String shareCardHeadlineNoCount(String nameLabel) {
    return 'Today, briefly faced\n$nameLabel in your heart';
  }

  @override
  String shareCardComboBadge(int count) {
    return '🔥 Best combo x$count';
  }

  @override
  String get shareCardNoLoveMessage =>
      'For every feeling you faced together today,\nyour heart already feels a little lighter 🤍';

  @override
  String get shareCardPreviewBadge => 'Preview';

  @override
  String reviveFreeOfferCountLabel(int count, String total) {
    return 'Free continue ($count/$total)';
  }

  @override
  String get reviveOfferHeadline => 'Not ready to stop yet!';

  @override
  String get reviveFreeOfferBody =>
      'Refill your lives now\nand keep going right where you left off';

  @override
  String get reviveContinueButton => 'Continue 💪';

  @override
  String get reviveDeclineButton => 'I\'ll stop here';

  @override
  String get reviveAdOfferSubtitleSecondTime =>
      'Mongi has one more favor to ask';

  @override
  String get reviveAdOfferSubtitleFirstTime => 'Give Mongi a second chance';

  @override
  String get reviveAdOfferBody =>
      'Watch an ad or drink the Water of Life\nto refill your lives and keep going';

  @override
  String reviveBuyWithLightEssenceButton(int cost) {
    return 'Continue now with Water of Life (Light Essence $cost)';
  }

  @override
  String reviveInsufficientFunds(int lightEssence, int cost) {
    return 'Not enough Light Essence (have $lightEssence / need $cost) · you can watch an ad below instead';
  }

  @override
  String get reviveWatchAdButton => 'Watch an ad to continue 🎬';

  @override
  String get reviveWatchingAdTitle => 'Playing ad...';

  @override
  String get reviveWatchingAdSubtitle => 'Please wait a moment';

  @override
  String get weekdaySun => 'Sun';

  @override
  String get weekdayMon => 'Mon';

  @override
  String get weekdayTue => 'Tue';

  @override
  String get weekdayWed => 'Wed';

  @override
  String get weekdayThu => 'Thu';

  @override
  String get weekdayFri => 'Fri';

  @override
  String get weekdaySat => 'Sat';

  @override
  String get weekdayObservationNotEnoughData =>
      'As more entries pile up, I\'ll show you how your mood flows by day of the week too 🌱';

  @override
  String weekdayObservationHasPattern(String bestDay, String toughestDay) {
    return 'Your heart felt especially at ease on ${bestDay}days,\nand a bit tougher on ${toughestDay}days. On days like that, it\'s okay to be a little gentler with yourself 🤍';
  }

  @override
  String get weekdayObservationNoClearPattern =>
      'Your feelings flow a little differently every day.\nWhatever day it is, Mongi is always right here with the same heart 🤍';

  @override
  String get weeklyObservationNoData =>
      'No entries yet this week.\nThat\'s okay - share even a small feeling whenever you\'re ready 🌱';

  @override
  String weeklyObservationImprovedFromLastWeek(int deltaPercent) {
    return 'Your brighter moods rose by ${deltaPercent}pp compared to last week.\nIf you felt that change yourself, that\'s entirely something you made happen ✨';
  }

  @override
  String get weeklyObservationDeclinedFromLastWeek =>
      'This week may have been a bit tougher than last week.\nYou don\'t have to push yourself - Mongi will keep staying by your side 🤍';

  @override
  String weeklyObservationDominantPositive(String emotion) {
    return 'This week was especially full of \"$emotion\".\nMongi felt that good energy right along with you 😊';
  }

  @override
  String weeklyObservationDominantNegative(String emotion) {
    return 'This week \"$emotion\" loomed especially large.\nMongi is curious what happened - feel free to share slowly, whenever you\'re ready.';
  }

  @override
  String get weeklyObservationManyNotes =>
      'You shared a lot of stories this week.\nOpening up your heart is never easy. Mongi remembers every single one 📔';

  @override
  String get weeklyObservationMostlyHeavy =>
      'This may have been a week when your heart felt a little heavy.\nEven on days like that, just showing up for Mongi every day is already something to be proud of 🤍';

  @override
  String weeklyObservationDefaultTopEmotion(String emotion, int count) {
    return 'The feeling you met most often this week was\n\"$emotion\" ($count times). Whatever the feeling, it all matters to Mongi.';
  }

  @override
  String get weeklyObservationDefaultThanks =>
      'Thanks for spending this week with Mongi too.';

  @override
  String get calendarHeaderTitle => '🗓️ Emotion Calendar';

  @override
  String calendarMonthLabel(int year, int month) {
    return '$month/$year';
  }

  @override
  String get calendarInsightNotEnoughData =>
      'As a few more entries pile up this month,\nI\'ll show you how your heart has been flowing 🌱';

  @override
  String calendarInsightTitleWithTop(String label) {
    return 'This month\'s Mongi diary title: \"$label\"';
  }

  @override
  String get calendarInsightTitleFallback => 'See this month\'s mood flow';

  @override
  String get calendarStatDiversityLabel => 'Emotion variety';

  @override
  String calendarStatDiversityValue(int count) {
    return '$count / 15 types';
  }

  @override
  String get calendarStatStreakLabel => 'Longest streak';

  @override
  String calendarStatStreakValue(int days) {
    return '$days days';
  }

  @override
  String get calendarWeeklyTrendTitle => 'Weekly mood flow';

  @override
  String get calendarLegendPositive => 'Positive';

  @override
  String get calendarLegendNegative => 'Negative';

  @override
  String get calendarWeekdayTrendTitle => 'Mood flow by day of week';

  @override
  String calendarWeekLabel(int week) {
    return 'Wk $week';
  }

  @override
  String get calendarEmptyMonth =>
      'No entries yet this month.\nThey\'ll pile up here once you face a feeling 🌱';

  @override
  String get calendarMonthSummaryTitle => 'This month\'s mood summary';

  @override
  String calendarMonthSummaryTopEmotion(String emotion, String icon) {
    return 'The feeling you faced most was \"$emotion\" $icon';
  }

  @override
  String calendarMonthSummaryTotal(int count) {
    return 'You opened up your heart $count times this month.\nHowever you feel, it\'s okay - Mongi is always by your side.';
  }

  @override
  String get calendarMonthDistributionTitle => 'This month\'s emotion stats';

  @override
  String calendarMonthDistributionPercent(int percent) {
    return '$percent%';
  }

  @override
  String get calendarMonthAnalysisTitle => 'A light look at this month';

  @override
  String get monthlyObservationNoData =>
      'This month still needs a few more entries.\nThat\'s okay, let\'s fill it in slowly 🌱';

  @override
  String monthlyObservationImprovedFromLastMonth(int deltaPercent) {
    return 'Brighter feelings grew by $deltaPercent%p compared to last month.\nMongi noticed that change too, built up over the whole month ✨';
  }

  @override
  String get monthlyObservationDeclinedFromLastMonth =>
      'This month may have felt a bit heavier than last month.\nNo need to push yourself - Mongi will stay right here 🤍';

  @override
  String monthlyObservationDominantPositive(String emotion, int percent) {
    return 'This month was full of \"$emotion\" ($percent%).\nMongi felt that good energy too 😊';
  }

  @override
  String monthlyObservationDominantNegative(String emotion, int percent) {
    return 'This month, \"$emotion\" showed up a lot ($percent%).\nMongi is curious what happened - feel free to share it slowly.';
  }

  @override
  String monthlyObservationDiverseEmotions(int count) {
    return 'You met as many as $count different feelings this month.\nNot staying in just one emotion shows how flexible your heart was 🎨';
  }

  @override
  String get monthlyObservationMostlyHeavy =>
      'This may have been a heavier month.\nStill showing up for Mongi every day is something to be proud of 🤍';

  @override
  String monthlyObservationDefaultTopEmotion(String emotion, int count) {
    return 'The feeling you met most this month was\n\"$emotion\" ($count times). Every feeling matters to Mongi.';
  }

  @override
  String get monthlyObservationDefaultThanks =>
      'Thanks for spending this month with Mongi.';

  @override
  String calendarDayDetailTitle(int day) {
    return 'Entries for the $day';
  }

  @override
  String calendarIntensityLabel(String dots) {
    return 'Intensity $dots';
  }

  @override
  String seasonPassAppBarTitle(int seasonNumber) {
    return 'Season $seasonNumber · Mongi\'s Heart Journey';
  }

  @override
  String get seasonPassSubHeadline =>
      'Even without playing, checking in daily or leaving a gratitude entry\nmoves your heart journey forward, little by little 🌿';

  @override
  String seasonPassCountdownDays(int days, int hours) {
    return '${days}d ${hours}h left';
  }

  @override
  String seasonPassCountdownHours(int hours, int minutes) {
    return '${hours}h ${minutes}m left';
  }

  @override
  String seasonPassCountdownMinutes(int minutes) {
    return '${minutes}m left';
  }

  @override
  String get seasonPassPurchaseDialogTitle => 'Season Pass Premium 🌟';

  @override
  String get seasonPassPurchaseDialogBody =>
      'Get much richer rewards at every level for this whole season.\nYou\'ll instantly receive the premium rewards for levels you\'ve already reached, too.';

  @override
  String get seasonPassRestoreConfirmedSnackbar =>
      'We checked your purchase history. If you\'ve already purchased, it\'ll be reflected shortly.';

  @override
  String seasonPassFreeRewardClaimedSnackbar(int level) {
    return 'You claimed the free reward for level $level!';
  }

  @override
  String seasonPassPremiumRewardClaimedSnackbar(int level) {
    return 'You claimed the premium reward for level $level!';
  }

  @override
  String seasonPassLevelLabel(int level) {
    return 'Level $level';
  }

  @override
  String seasonPassLevelLabelMax(int level) {
    return 'Level $level (Max)';
  }

  @override
  String get seasonPassFreeTierBadge => 'Free';

  @override
  String get seasonPassPremiumTierBadge => '💎 Premium';

  @override
  String get seasonPassMaxLevelReached => 'You\'ve filled every level!';

  @override
  String seasonPassXpProgress(int xpInto, int span) {
    return '$xpInto / $span xp';
  }

  @override
  String get seasonPassMindMilestoneBadge => '🌿 Heart Milestone';

  @override
  String seasonPassTierLevelLabel(int level) {
    return 'Lv.$level';
  }

  @override
  String get seasonPassClaimButton => 'Claim →';

  @override
  String get seasonPassOwnedBanner => '✅ Premium pass owned';

  @override
  String get seasonPassUpgradeButton => '💎 Upgrade to Premium Pass';

  @override
  String seasonRewardFinaleLabel(
    int lightEssence,
    int starShard,
    String costumeName,
  ) {
    return '$lightEssence Light Essence + $starShard Star Shards + guaranteed costume \"$costumeName\"';
  }

  @override
  String seasonRewardWithShardLabel(int lightEssence, int starShard) {
    return '$lightEssence Light Essence + $starShard Star Shards';
  }

  @override
  String seasonRewardLightOnlyLabel(int lightEssence) {
    return '$lightEssence Light Essence';
  }

  @override
  String get nearbyHeaderTitle => '📍 Counseling Centers Near Me';

  @override
  String get nearbySectionTitle => '🗺️ What are you looking for?';

  @override
  String get nearbyIntroCardBody =>
      'If calling still feels intimidating, visiting somewhere nearby to talk\nin person can be a great option too. Pick the type of place you want\nbelow, and we\'ll open a map to find one near you.';

  @override
  String get nearbyOfficialPortalTitle =>
      'See the full list on the National Mental Health Portal';

  @override
  String get nearbyOfficialPortalSubtitle =>
      'Opens the official facility finder run by the Ministry of Health and Welfare';

  @override
  String get nearbyGlobalOfficialPortalTitle =>
      'Find local support on Find A Helpline';

  @override
  String get nearbyGlobalOfficialPortalSubtitle =>
      'Opens a global directory covering helplines in 130+ countries';

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
      '※ Map search results are provided by Google Maps. Please confirm actual\noperating hours and conditions directly with each facility before visiting.';

  @override
  String get nearbyMapOpenFailedSnackbar => 'Couldn\'t open the map app.';

  @override
  String get nearbyPortalOpenFailedSnackbar => 'Couldn\'t open the page.';

  @override
  String get nearbyCenterMentalHealthName => 'Mental Health Welfare Center';

  @override
  String get nearbyCenterMentalHealthDesc =>
      'A local counseling center anyone can use for free. Get support and\ncounseling for depression, anxiety, and other mental health concerns.';

  @override
  String get nearbyCenterYouthName => 'Youth Counseling Welfare Center';

  @override
  String get nearbyCenterYouthDesc =>
      'A free counseling center for youth ages 9-24.\nGet comfortable support for school, relationship, or family issues.';

  @override
  String get nearbyCenterSuicidePreventionName => 'Suicide Prevention Center';

  @override
  String get nearbyCenterSuicidePreventionDesc =>
      'A dedicated local suicide prevention agency offering professional\ncrisis intervention and follow-up care.';

  @override
  String get nearbyCenterPsychiatricName => 'Psychiatric Clinic';

  @override
  String get nearbyCenterPsychiatricDesc =>
      'If you feel you might need medication or a professional diagnosis,\nyou can look for a nearby clinic first.';

  @override
  String get nearbyCenterMentalHealthMapQuery => 'mental health welfare center';

  @override
  String get nearbyCenterYouthMapQuery => 'youth counseling welfare center';

  @override
  String get nearbyCenterSuicidePreventionMapQuery =>
      'suicide prevention center';

  @override
  String get nearbyCenterPsychiatricMapQuery => 'psychiatric clinic';

  @override
  String get mindReportHeaderTitle => '💗 Mind Report';

  @override
  String get mindReportIntroText =>
      'Here\'s everything you and Mongi have faced together, at a glance.\nMore than the numbers, you\'re the amazing one for noticing those feelings.';

  @override
  String get mindReportSupportAlertTitle =>
      'It seems like things have felt heavy lately';

  @override
  String get mindReportSupportAlertBody =>
      'You don\'t have to carry it alone. There\'s always somewhere to talk.';

  @override
  String get mindReportSupportEntryLabel =>
      'When it\'s hard - see counseling guide';

  @override
  String get mindReportWeeklyTitle => 'Mongi\'s observations this week';

  @override
  String mindReportWeeklyPositiveLabel(int percent) {
    return 'Positive $percent%';
  }

  @override
  String mindReportWeeklySessionsLabel(int count) {
    return '· Together $count times';
  }

  @override
  String get mindReportWeeklyNotEnoughData =>
      'Still gathering data. Stick with it a little longer 🌱';

  @override
  String get mindReportMonthlyTitle => 'This month\'s mood flow';

  @override
  String mindReportMonthlyTopEmotion(String emotion) {
    return 'The feeling you met most was \"$emotion\"';
  }

  @override
  String get mindReportMonthlyNoTopEmotion =>
      'I\'ll show you this month\'s mood flow';

  @override
  String mindReportMonthlyStreak(int days) {
    return '🔥 $days days';
  }

  @override
  String get mindReportMonthlyNotEnoughData =>
      'As this month\'s entries build up a bit more, I\'ll show you the flow of your heart 🌱';

  @override
  String get mindReportWeekdayTitle => 'Mood flow by day of the week';

  @override
  String get mindReportTriggerTitle => 'What\'s behind it';

  @override
  String get mindReportTriggerNotEnoughData =>
      'Answer \"What was it because of?\" a few more times when logging your feelings, and we\'ll show you patterns here too 🌱';

  @override
  String triggerInsightDominantNegativeCause(String trigger, int count) {
    return 'Lately, \"$trigger\" may have been weighing on your heart.\nIt came up $count times. Just noticing it is already a big step 🤍';
  }

  @override
  String triggerInsightTopTrigger(String trigger, int count) {
    return '\"$trigger\" has come up most often lately ($count times).\nMaybe you\'ve spotted a pattern you didn\'t notice before.';
  }

  @override
  String get emotionTriggerWorkStudy => 'Work/Study';

  @override
  String get emotionTriggerRelationship => 'Relationships';

  @override
  String get emotionTriggerFamily => 'Family';

  @override
  String get emotionTriggerHealth => 'Health';

  @override
  String get emotionTriggerMoney => 'Money';

  @override
  String get emotionTriggerSleep => 'Sleep/Fatigue';

  @override
  String get emotionTriggerAlone => 'Being alone';

  @override
  String get emotionTriggerSns => 'Social media';

  @override
  String get emotionTriggerWeather => 'Weather';

  @override
  String get emotionTriggerFuture => 'Future worries';

  @override
  String get emotionTriggerAchievement => 'Small win';

  @override
  String get emotionTriggerEtc => 'Other';

  @override
  String get mindReportGratitudeTitle => 'Gratitude & small wins';

  @override
  String get mindReportGratitudeEmpty => 'No entries yet';

  @override
  String mindReportGratitudeCount(int count) {
    return '$count entries';
  }

  @override
  String get mindReportGratitudeDoneToday => 'Logged today ✓';

  @override
  String get mindReportCollectionTitle => 'Emotion Collection';

  @override
  String get mindReportDiaryTitle => 'Emotion Diary';

  @override
  String mindReportDiaryCount(int count) {
    return '$count stories';
  }

  @override
  String get collectionHeaderTitle => '📖 Emotion Collection';

  @override
  String get collectionNegativeSectionTitle =>
      '🌧️ Feelings you\'ve faced (10 types)';

  @override
  String get collectionPositiveSectionTitle =>
      '🌟 Feelings you\'ve embraced (5 types)';

  @override
  String get collectionProgressCompleteText =>
      'You\'ve met all 15 feelings! Amazing 🎉';

  @override
  String collectionProgressPartialText(int count) {
    return 'You\'ve met $count feelings so far';
  }

  @override
  String get collectionProgressHint =>
      'The monster evolves the more you meet it (5x · 20x · 50x)';

  @override
  String collectionGoldenFrameCount(int count) {
    return 'You have $count golden frame(s)!';
  }

  @override
  String get collectionGoldenFrameEarned => '🏆 Golden Frame Earned!';

  @override
  String get collectionTranscendedBadge => '🌌 Transcended Feeling';

  @override
  String get collectionTranscendedRank => 'Transcended Rank';

  @override
  String get collectionMasteredRank => 'Master Rank';

  @override
  String collectionStageRank(int stage) {
    return 'Stage $stage';
  }

  @override
  String collectionMetCountLabel(int count) {
    return 'You\'ve faced it $count times so far';
  }

  @override
  String collectionNextEvolutionHint(int remaining, String nextName) {
    return 'Face it $remaining more times to evolve into \"$nextName\"';
  }

  @override
  String get collectionTranscendedMessage =>
      'After a hundred encounters, it became something entirely different.\nNo one warned you - this discovery is entirely your own 🌌';

  @override
  String get collectionMasteredMessage =>
      'It has fully evolved! From now on, every time you meet it,\nthere\'s a very small chance to earn a golden frame ✨';

  @override
  String get commonCloseButton => 'Close';

  @override
  String gardenShareShareText(String label) {
    return 'Mongi\'s growth tree is now at the $label stage 🌳 We\'re growing together as I care for my heart every day #Mongi #MindGarden';
  }

  @override
  String get gardenShareSheetTitle => 'Mongi\'s Garden Share Card 🌳';

  @override
  String get gardenShareSheetSubtitle =>
      'Show off the garden you\'ve grown together so far';

  @override
  String get gardenShareCardMakingButton => 'Making card...';

  @override
  String get gardenShareCardButton => 'Share Card';

  @override
  String get gardenShareCardName => 'Mongi\'s Garden';

  @override
  String gardenShareCardGrownLabel(String label) {
    return 'Now grown to the $label stage';
  }

  @override
  String get gardenShareCardNotGrownLabel => 'Not planted yet';

  @override
  String gardenShareCardStreakStat(int days) {
    return '${days}d';
  }

  @override
  String get gardenShareCardStreakLabel => 'Streak';

  @override
  String gardenShareCardFlowersStat(int count) {
    return '$count';
  }

  @override
  String get gardenShareCardFlowersLabel => 'Flowers';

  @override
  String gardenShareCardScoreStat(int score) {
    return '${score}pt';
  }

  @override
  String get gardenShareCardScoreLabel => 'Score';

  @override
  String get gardenShareCardFooter =>
      'Caring for my heart every day\nand growing little by little 🌱';

  @override
  String get milestoneHeaderTitle => '🎬 Mongi\'s Growth Documentary';

  @override
  String get milestoneIntroTitle => 'Mongi\'s tree has finally\nborne fruit 🍎';

  @override
  String get milestoneIntroBody =>
      'The little seed that was Mongi has grown this much\nthanks to all the feelings you\'ve faced together.\nShall we take a moment to look back on the journey?';

  @override
  String get milestoneTimelineTitle => 'Stories shared with Mongi';

  @override
  String get milestoneStreakLabel => 'Recent Streak';

  @override
  String get milestoneScoreLabel => 'Total Score';

  @override
  String get milestoneDiaryCountLabel => 'Stories Shared';

  @override
  String milestoneDiaryCountStat(int count) {
    return '$count';
  }

  @override
  String get milestoneInsightTitle => 'Feelings shared with this tree';

  @override
  String milestoneEmotionCountLabel(String label, int count) {
    return '$label $count times';
  }

  @override
  String milestoneImprovedText(String label) {
    return 'You used to meet $label often at first,\nbut it\'s become much less frequent lately. Your heart may have grown a little lighter.';
  }

  @override
  String milestoneUncollectedText(int count) {
    return 'There are still $count feelings you haven\'t met yet.\nShall we meet them with the next tree? 🌳';
  }

  @override
  String get milestoneEmptyTimelineText =>
      'There are no one-line stories left yet,\nbut every feeling you\'ve sat with together grew this tree 🌳';

  @override
  String get milestoneClosingQuote =>
      '\"Thank you for bringing me this far.\nWhatever feeling comes next,\nI\'ll be right here watching over you.\"';

  @override
  String get milestoneShareButtonLabel => 'Share this moment as a card';

  @override
  String milestoneTimelineDateCount(String date, int count) {
    return '$date · $count';
  }

  @override
  String milestoneTimelineNoteQuote(String note) {
    return '\"$note\"';
  }

  @override
  String get breathingPromptText =>
      'Take a moment to breathe slowly with Mongi';

  @override
  String get breathingInhaleLabel => 'Breathe in...';

  @override
  String get breathingExhaleLabel => 'Breathe out...';

  @override
  String get breathingHoldLabel => 'Hold...';

  @override
  String get weeklyReportShareText =>
      'Here\'s my emotion report with Mongi this week 🌱 #Mongi #MindGarden';

  @override
  String get weeklyReportShareButton => 'Share this week\'s report';

  @override
  String get weeklyReportNotEnoughTitle => 'Still gathering data';

  @override
  String get weeklyReportNotEnoughBody =>
      'Spend a little more time with Mongi\nand we\'ll share this week\'s story with you';

  @override
  String weeklyReportSessionsLabel(int count) {
    return 'Together $count times';
  }

  @override
  String get weeklyReportEmotionsSectionTitle => 'Feelings met this week';

  @override
  String weeklyReportEmotionTag(String icon, String label, int count) {
    return '$icon $label $count';
  }

  @override
  String weeklyReportNegativeLabel(int percent) {
    return 'Negative $percent%';
  }

  @override
  String weeklyReportPreviousRatioLabel(int percent) {
    return 'Last week\'s positive ratio: $percent%';
  }

  @override
  String get gardenDecoSheetTitle => '🎨 Decorate Garden';

  @override
  String get gardenDecoSheetSubtitle =>
      'Tap an unlocked item to equip or unequip it';

  @override
  String get gardenDecoFreeSectionLabel =>
      'Free Items · Unlocked by reaching milestones';

  @override
  String get gardenDecoPremiumSectionLabel =>
      'Premium Items · Garden Decoration Pack';

  @override
  String get gardenDecoRestoreButton => 'Restore Previous Purchase';

  @override
  String get gardenDecoProBadge => 'PRO';

  @override
  String get gardenDecoEquippedStatus => 'Currently placed in your garden';

  @override
  String get gardenDecoTapToPlaceStatus => 'Tap to place it in your garden';

  @override
  String gardenDecoProgressBadge(String progress) {
    return '📍 $progress';
  }

  @override
  String gardenDecoProgressBench(int days) {
    return 'Day $days of 3 in a row';
  }

  @override
  String gardenDecoProgressPath(int percent) {
    return 'Garden recovery $percent% (unlocks at 100%)';
  }

  @override
  String gardenDecoProgressFountainPlanted(int planted) {
    return '$planted/3 seeds planted';
  }

  @override
  String gardenDecoProgressFountainWithMissing(int planted, String missing) {
    return '$planted/3 seeds planted · Remaining: $missing';
  }

  @override
  String get gardenSeedNameForgiveness => 'Forgiveness';

  @override
  String get gardenSeedNameLove => 'Love';

  @override
  String get gardenSeedNamePeace => 'Peace';

  @override
  String get gardenSeedDescForgiveness =>
      'A seed that lets go of what weighs on your heart';

  @override
  String get gardenSeedDescLove => 'A seed that shares warmth';

  @override
  String get gardenSeedDescPeace => 'A seed of quiet, calm peace';

  @override
  String get gardenDecoLabelBench => 'Wooden Bench';

  @override
  String get gardenDecoUnlockHintBench =>
      'Unlocks after meeting Mongi 3 days in a row';

  @override
  String get gardenDecoLabelPath => 'Pebble Path';

  @override
  String get gardenDecoUnlockHintPath =>
      'Unlocks the first time your garden fully blooms';

  @override
  String get gardenDecoLabelFountain => 'Small Fountain';

  @override
  String get gardenDecoUnlockHintFountain =>
      'Unlocks once you\'ve planted Forgiveness, Love, and Peace seeds';

  @override
  String get gardenDecoLabelLantern => 'Paper Lantern';

  @override
  String get gardenDecoLabelRainbowFence => 'Rainbow Fence';

  @override
  String get gardenDecoLabelStarLight => 'Sparkling Starlight';

  @override
  String get gardenDecoUnlockHintPremiumPack =>
      'Available after purchasing the Garden Decoration Pack';

  @override
  String get gardenDecoLabelWindChime => 'Wind Chime';

  @override
  String get gardenDecoUnlockHintWindChime =>
      'Unlocks after meeting Mongi 7 days in a row';

  @override
  String get gardenDecoLabelButterflyGarden => 'Butterfly Garden';

  @override
  String get gardenDecoUnlockHintButterflyGarden =>
      'Unlocks once you\'ve raised 3 or more emotions to Master rank';

  @override
  String get gardenDecoLabelGazebo => 'Cozy Gazebo';

  @override
  String get gardenDecoLabelLotusPond => 'Lotus Pond';

  @override
  String get gardenDecoLabelJangdokdae => 'Jangdokdae (Earthenware Pots)';

  @override
  String get gardenDecoUnlockHintJangdokdae =>
      'Unlocks after blooming flowers 10 or more times';

  @override
  String get gardenDecoLabelGinkgoPath => 'Ginkgo Path';

  @override
  String get gardenDecoUnlockHintGinkgoPath =>
      'Unlocks after meeting Mongi 14 days in a row';

  @override
  String get gardenDecoLabelHanokLantern => 'Hanok Eaves Lantern';

  @override
  String gardenDecoUnlockHintWithProgress(String hint, String progress) {
    return '$hint\n(Current: $progress)';
  }

  @override
  String get gardenDecoPurchaseDialogTitle => 'Purchase Garden Decoration Pack';

  @override
  String get gardenDecoPurchaseDialogBody =>
      'Paper Lantern 🏮 · Rainbow Fence 🌈 · Sparkling Starlight ✨\nUnlock all 3 decorations at once to make Mongi\'s garden even prettier.\n\nA one-time purchase — no need to pay again.';

  @override
  String get gardenDecoPurchaseFailedSnackbar =>
      'Couldn\'t start the purchase. Please try again in a moment.';

  @override
  String get mindBoxAllCollectedSnackbar =>
      '🎉 You\'ve already collected all of Mongi\'s gifts!';

  @override
  String get mindBoxNotEnoughEssenceSnackbar =>
      '💡 Not enough Light Essence. Want to collect more in Endless Mode?';

  @override
  String get mindBoxHeaderTitle => '🎁 Mind Box';

  @override
  String get mindBoxAllCollectedTitle =>
      '🎉 You\'ve collected all of Mongi\'s gifts!';

  @override
  String get mindBoxOpenHintTitle =>
      'Every box you open reveals a brand-new gift';

  @override
  String mindBoxCollectionProgressLabel(int owned, int total, int totalPulls) {
    return 'Collection $owned / $total · Boxes opened so far: $totalPulls';
  }

  @override
  String get mindBoxOpenOneButton => 'Open 1 Box';

  @override
  String mindBoxOpenBulkButtonCount(int count) {
    return 'Open $count Boxes';
  }

  @override
  String get mindBoxOpenBulkButtonGeneric => 'Open Multiple Boxes';

  @override
  String get mindBoxCollectionSectionTitle => '🐾 Mongi\'s Costume Collection';

  @override
  String get mindBoxEquippedBadge => 'Equipped';

  @override
  String get mindBoxResultTitleLegendary => '🌟 A truly special gift arrived!';

  @override
  String get mindBoxResultTitleNormal => '🎁 You opened a Mind Box';

  @override
  String get mindBoxConfirmButton => 'OK';

  @override
  String get mindBoxNewItemLabel => '✨ NEW! You got a new outfit';

  @override
  String get mindBoxRarityCommon => 'Common';

  @override
  String get mindBoxRarityRare => 'Rare';

  @override
  String get mindBoxRarityEpic => 'Epic';

  @override
  String get mindBoxRarityLegendary => 'Legendary';

  @override
  String get mongiCostumeNameRibbon => 'Pink Ribbon';

  @override
  String get mongiCostumeNameStarBand => 'Starlight Headband';

  @override
  String get mongiCostumeNameScarf => 'Rainbow Scarf';

  @override
  String get mongiCostumeNameBunnyEars => 'Bunny Ears Headband';

  @override
  String get mongiCostumeNameFlowerCrown => 'Daisy Flower Crown';

  @override
  String get mongiCostumeNameWizardHat => 'Starlight Wizard Hat';

  @override
  String get mongiCostumeNameGoldenCrown => 'Golden Crown';

  @override
  String get mongiCostumeNameCloudBand => 'Fluffy Cloud Headband';

  @override
  String get mongiCostumeNameSunflowerBand => 'Sunflower Headband';

  @override
  String get mongiCostumeNameAngelWings => 'Angel Wings';

  @override
  String get mongiCostumeNamePirateHat => 'Little Pirate Hat';

  @override
  String get mongiCostumeNameGalaxyCape => 'Galaxy Cape';

  @override
  String get mongiCostumeNamePhoenixCrown => 'Phoenix Crown';

  @override
  String get mongiCostumeNameSaekdongRibbon => 'Saekdong Ribbon';

  @override
  String get mongiCostumeNameBokjumeoni => 'Lucky Pouch Headband';

  @override
  String get mongiCostumeNameSproutHat => 'Sprout Headband';

  @override
  String endlessResultTimeMinSec(int minutes, int seconds) {
    return '${minutes}m ${seconds}s';
  }

  @override
  String endlessResultTimeSecOnly(int seconds) {
    return '${seconds}s';
  }

  @override
  String get endlessResultNewRecordBadge => '🏆 New personal best today!';

  @override
  String get endlessResultCardTitle => 'Today\'s Challenge Result';

  @override
  String get endlessResultEatenCountLabel => 'Emotions Faced';

  @override
  String endlessResultEatenCountValue(int count) {
    return '$count';
  }

  @override
  String get endlessResultSurvivedTimeLabel => 'Survival Time';

  @override
  String get endlessResultBestRecordLabel => '👑 My Best Record';

  @override
  String endlessResultBestRecordValue(int count, String time) {
    return '$count · $time';
  }

  @override
  String get endlessResultRankingFooter =>
      'More precious than any ranking is the time you spent facing your feelings with Mongi today 🤍';

  @override
  String get endlessResultRetryButton => 'Try Again 🐾';

  @override
  String dailyMissionClaimedSnackbar(String emoji, int amount) {
    return '$emoji +$amount Light Essence received!';
  }

  @override
  String get dailyMissionAllClearSnackbar => '🎉 You got the All-Clear bonus!';

  @override
  String get dailyMissionSheetLabel => 'Mongi\'s Missions Today';

  @override
  String dailyMissionLabelEatEmotions(int target) {
    return 'Face $target emotion monsters together';
  }

  @override
  String dailyMissionLabelCompleteStage(int target) {
    return 'Complete a stage $target time(s)';
  }

  @override
  String dailyMissionLabelPlantLove(int target) {
    return 'Plant your heart $target time(s)';
  }

  @override
  String get dailyMissionSheetTitle => 'Just a little more together today';

  @override
  String dailyMissionProgressWithReward(int progress, int target, int reward) {
    return '$progress / $target  ·  💡+$reward';
  }

  @override
  String get dailyMissionClaimButton => 'Claim';

  @override
  String get dailyMissionAllClearCardTitle => 'All-Clear Bonus';

  @override
  String get dailyMissionAllClearAlreadyClaimed =>
      'You\'ve already claimed this today, see you tomorrow!';

  @override
  String dailyMissionAllClearProgress(
    int claimed,
    int total,
    int lightEssence,
    int starShard,
  ) {
    return '$claimed/$total missions done · 💡+$lightEssence ⭐+$starShard';
  }

  @override
  String get safetyPlanSavedSnackbar => 'Saved 🤍';

  @override
  String get safetyPlanCallFailedSnackbar =>
      'Couldn\'t connect the call. Please dial 109 directly.';

  @override
  String get safetyPlanHeaderTitle => '🧭 My Safety Plan';

  @override
  String get safetyPlanIntroLine1 =>
      'While your mind feels calm, this is a space to leave\na short note for your future self.';

  @override
  String get safetyPlanIntroLine2 =>
      'Later, when things feel hard, there may be moments when it\'s\nhard to remember where to start. Open this page then and see the\nanswers you wrote for yourself. What you write stays only on this\ndevice — not even Mongi can see it.';

  @override
  String get safetyPlanSaveButton => 'Save';

  @override
  String safetyPlanTapToWriteHint(String placeholder) {
    return '$placeholder\n(Tap to write)';
  }

  @override
  String get safetyPlanEmergencyTitle => 'If things feel too hard right now';

  @override
  String get safetyPlanEmergencySubtitle =>
      'We\'ll connect you directly to 109 (Suicide Prevention Hotline)';

  @override
  String get safetyPlanGlobalEmergencySubtitle =>
      'We\'ll open Find A Helpline to locate support in your country';

  @override
  String get safetyPlanGlobalButtonLabel => 'Open';

  @override
  String get safetyPlanGlobalOpenFailedSnackbar =>
      'Couldn\'t open the page. Please visit findahelpline.com directly.';

  @override
  String get safetyPlanSectionWarningSignsTitle => 'My warning signs';

  @override
  String get safetyPlanSectionWarningSignsHint =>
      'When these thoughts, feelings, or situations show up, it means \"I need to be careful right now.\"';

  @override
  String get safetyPlanSectionWarningSignsPlaceholder =>
      'e.g. When I haven\'t slept for days, when I think \"nothing matters anymore\"...';

  @override
  String get safetyPlanSectionCopingStrategiesTitle =>
      'My own ways to calm down alone';

  @override
  String get safetyPlanSectionCopingStrategiesHint =>
      'Things you can try on your own, without anyone else\'s help.';

  @override
  String get safetyPlanSectionCopingStrategiesPlaceholder =>
      'e.g. Listening to a favorite song, taking a walk, sorting out feelings with Mongi...';

  @override
  String get safetyPlanSectionSupportPeopleTitle => 'People I can ask for help';

  @override
  String get safetyPlanSectionSupportPeopleHint =>
      'Writing down names and numbers makes it easier to find them in a hard moment.';

  @override
  String get safetyPlanSectionSupportPeoplePlaceholder =>
      'e.g. Friend John (010-xxxx-xxxx), my sister, my counselor...';

  @override
  String get safetyPlanSectionSafePlaceTitle => 'A place that feels calming';

  @override
  String get safetyPlanSectionSafePlaceHint =>
      'Is there a place where even a short stay eases your mind a little?';

  @override
  String get safetyPlanSectionSafePlacePlaceholder =>
      'e.g. A neighborhood cafe, home with family, a nearby park bench...';

  @override
  String get safetyPlanSectionReasonsToLiveTitle =>
      'What matters to me / reasons to live';

  @override
  String get safetyPlanSectionReasonsToLiveHint =>
      'Write down the things that truly matter to you — easy to forget in hard moments.';

  @override
  String get safetyPlanSectionReasonsToLivePlaceholder =>
      'e.g. My dog, a trip I want to take next year, my beloved family...';

  @override
  String get powerCharmBoughtOneSnackbar => '⚡ Got 1 Power Charm!';

  @override
  String powerCharmBoughtBulkSnackbar(int count) {
    return '⚡ Got $count Power Charms!';
  }

  @override
  String get powerCharmNotEnoughSnackbar => '💡 Not enough Light Essence.';

  @override
  String get powerCharmTitle => 'Power Charm';

  @override
  String powerCharmDescription(int count) {
    return 'Use anytime during the game for 10 seconds of invincibility\nOwned: $count';
  }

  @override
  String get powerCharmBuyOneLabel => '1 Charm';

  @override
  String powerCharmBuyBulkLabel(int count) {
    return '$count Charms';
  }

  @override
  String get breathingMomentTitle => 'You\'ve met a Breath Orb';

  @override
  String get breathingMomentInhaleLabel => 'Breathe in and hold';

  @override
  String get breathingMomentExhaleLabel => 'Breathe out and release';

  @override
  String get breathingLibraryHeaderTitle => '🌬️ Mongi\'s Breathing Library';

  @override
  String get breathingLibrarySubtitle =>
      'Pick the breathing exercise that fits how you feel right now, and follow along with Mongi.';

  @override
  String breathingLibraryDurationLabel(int seconds) {
    return 'About ${seconds}s';
  }

  @override
  String get breathingLibraryStartButton => 'Start';

  @override
  String get breathingLibraryCompletedTodayBadge => 'Done today ✓';

  @override
  String breathingLibraryRewardHint(int reward) {
    return 'Finish it for the first time today to earn 💡$reward';
  }

  @override
  String breathingLibraryRewardSnackbar(int reward) {
    return 'Well done 🌿 You earned 💡$reward for today\'s first breathing session!';
  }

  @override
  String get breathingLibraryNoRewardSnackbar =>
      'Nicely done 🌿 (the reward can only be earned once per day)';

  @override
  String get breathingTechniqueNameCalmBreath => 'Calm Breath';

  @override
  String get breathingTechniqueDescCalmBreath =>
      'A simple breath in and breath out, repeated. Start whenever feels comfortable.';

  @override
  String get breathingTechniqueNameAnxietyRelief => 'Anxiety-Easing Breath';

  @override
  String get breathingTechniqueDescAnxietyRelief =>
      'Breathe in for 4s, hold for 7s, and exhale slowly for 8s. Especially helpful when your mind feels rushed.';

  @override
  String get breathingTechniqueNameBoxBreathing => 'Box Breathing for Focus';

  @override
  String get breathingTechniqueDescBoxBreathing =>
      'Inhale, hold, exhale, and hold again, each for the same length. Helps pull scattered focus back together.';

  @override
  String get breathingTechniqueNameSleepWindDown => 'Wind-Down Breath';

  @override
  String get breathingTechniqueDescSleepWindDown =>
      'Breathe in slowly and exhale for a long, slow stretch, letting the day\'s tension melt away.';

  @override
  String get breathingTechniqueNameEnergizingBreath => 'Energizing Breath';

  @override
  String get breathingTechniqueDescEnergizingBreath =>
      'Inhale, hold just briefly, then exhale crisply in a slightly quicker rhythm. Wakes up a tired or sluggish body and mind.';

  @override
  String get breathingSuggestionTitle =>
      'Want to start this feeling with a breath?';

  @override
  String breathingSuggestionSubtitle(String emoji, String name) {
    return 'Try $emoji $name for a moment - it can make the game feel a little gentler.';
  }

  @override
  String get breathingSuggestionStartButton => 'Breathe, then start';

  @override
  String get breathingSuggestionSkipButton => 'Skip and start now';

  @override
  String get mongiCareNotEnoughSnackbar =>
      'Not enough Light Essence. Want to play a bit more to collect some?';

  @override
  String mongiCareKeepsakePlacedSuffix(String reaction) {
    return '$reaction\nPermanently placed in the garden!';
  }

  @override
  String get mongiCareSheetTitle => '🍚 Mongi Care Set';

  @override
  String get mongiCareItemNameTunaCan => 'Tuna Can';

  @override
  String get mongiCareItemNameKibble => 'Mongi Kibble';

  @override
  String get mongiCareItemNameCleanWater => 'Clean Water';

  @override
  String get mongiCareItemNameInjeolmi => 'Injeolmi Rice Cake';

  @override
  String get mongiCareItemNameBlanket => 'Cozy Blanket';

  @override
  String get mongiCareItemNameMongiHouse => 'Mongi\'s House';

  @override
  String get mongiCareItemReactionTunaCan =>
      'Mongi munched on the tuna can! Such a happy face 🐟';

  @override
  String get mongiCareItemReactionKibble =>
      'Mongi crunched on the kibble happily 🍚';

  @override
  String get mongiCareItemReactionCleanWater =>
      'Mongi drank the cool water and felt refreshed 💧';

  @override
  String get mongiCareItemReactionInjeolmi =>
      'Mongi munched on the soft rice cake dusted with bean powder! So chewy and delicious 🍡';

  @override
  String get mongiCareItemReactionBlanket =>
      'Mongi snuggled under the blanket and fell into a warm sleep. The garden corner feels cozier now 🧣';

  @override
  String get mongiCareItemReactionMongiHouse =>
      'Mongi loves the new house! Now there\'s a cozy home just for Mongi in the garden 🏠';

  @override
  String mongiCareLightEssenceLabel(int amount) {
    return 'Light Essence $amount';
  }

  @override
  String get mongiCareConsumableSectionLabel =>
      'Food · Can be given again anytime';

  @override
  String get mongiCareKeepsakeSectionLabel =>
      'Special Gifts · Stays in the garden forever once given';

  @override
  String get mongiCareKeepsakePlacedStatus => 'Now placed in the garden';

  @override
  String get mongiCareKeepsakeHint =>
      'Gift it once and it stays in the garden forever';

  @override
  String mongiCareGivenCountStatus(int count) {
    return 'Given $count times so far';
  }

  @override
  String get mongiCareNeverGivenStatus => 'Not given yet';

  @override
  String get lightEssenceShopTitle => 'Recharge Light Essence';

  @override
  String get lightEssencePackLabelSmall => 'Small Light Pouch';

  @override
  String get lightEssencePackLabelLarge => 'Large Light Jar';

  @override
  String lightEssenceShopDescription(int count) {
    return 'You can keep collecting just by playing\nOwned: $count';
  }

  @override
  String get lightEssenceShopBestValueBadge => 'Best Value';

  @override
  String lightEssenceShopPackAmountPrice(int amount, String pricePer100) {
    return '💡 $amount · ₩$pricePer100 per 100';
  }

  @override
  String get gratitudeLogHeaderTitle => '🌻 Gratitude & Small Wins';

  @override
  String get gratitudeLogIntro =>
      'Even the smallest things count.\nLeave one line a day about a good moment 🌿';

  @override
  String get gratitudeLogSubmitButton => 'Save Entry';

  @override
  String get gratitudeLogEmptyTitle => 'No entries yet';

  @override
  String get gratitudeLogEmptySubtitle =>
      'Leave a small good thing that happened today';

  @override
  String gratitudeLogSubmittedSnackbar(String emoji) {
    return '$emoji Today\'s entry has been saved';
  }

  @override
  String seasonMilestoneSnackbar(String message) {
    return '🌿 $message';
  }

  @override
  String get gratitudeLogDeleteTooltip => 'Delete';

  @override
  String get gratitudeEntryTypeLabelGratitude => 'Grateful for';

  @override
  String get gratitudeEntryTypeLabelAchievement => 'Small win';

  @override
  String get gratitudeEntryTypeHintGratitude =>
      'What are you grateful for today?';

  @override
  String get gratitudeEntryTypeHintAchievement =>
      'Did you accomplish something small today?';

  @override
  String get gratitudeEntryTypePlaceholderGratitude =>
      'e.g. The sunshine felt so warm today';

  @override
  String get gratitudeEntryTypePlaceholderAchievement =>
      'e.g. I woke up on time today';

  @override
  String get dailyCheckInCuriousLabel => 'Mongi is curious';

  @override
  String get dailyCheckInQuestion => 'How are you feeling today?';

  @override
  String dailyCheckInStreakBadge(int streak, int streakAfter) {
    return '🔥 $streak-day check-in streak · $streakAfter days if you check in today!';
  }

  @override
  String get dailyCheckInBestStreakNewRecord =>
      '🏆 Checking in today sets a new personal best!';

  @override
  String dailyCheckInBestStreakCompare(int best) {
    return 'Personal best: $best days';
  }

  @override
  String dailyCheckInBestStreakRestart(int best) {
    return 'Your best streak was $best days · give it another shot!';
  }

  @override
  String get dailyCheckInSkipButton => 'Maybe later';

  @override
  String get mongiLetterHeaderTitle => '💌 Mongi\'s Letter';

  @override
  String get mongiLetterNotEnoughMessage =>
      'Mongi doesn\'t have quite enough\nstories to write a letter yet.\nSpend a little more time together and\nnext week Mongi will send one for sure 🐾';

  @override
  String get mongiLetterArrivedTitle => 'A letter has arrived from Mongi';

  @override
  String get mongiLetterTapToOpenHint => 'Tap to open it';

  @override
  String get mongiLetterGreeting =>
      'Hi, it\'s Mongi 🐱\nI\'ve been watching over your heart closely this week too.';

  @override
  String mongiLetterBodyTopTarget(String target) {
    return 'This week you talked about \"$target\" quite a lot.\nIt must have been taking up a big place in your heart.\nMongi kept thinking about what that story might be.';
  }

  @override
  String mongiLetterBodyTopEmotion(String emotion) {
    return 'This week was a week when you met \"$emotion\" quite a lot.\nMongi was curious about what happened,\nbut just stayed by your side without pushing.';
  }

  @override
  String get mongiLetterBodyManyNotes =>
      'This week you shared a lot of your stories.\nMongi treasured every single little word,\neven the shortest ones.';

  @override
  String get mongiLetterBodyMostlyPositive =>
      'It feels like your heart has been lighter lately,\nand Mongi got excited right along with you.\nHope there are more days like these.';

  @override
  String get mongiLetterBodyMostlyHeavy =>
      'There were some heavy days too.\nBut thank you for coming to Mongi\nwhenever it was hard. You don\'t have to bear it alone.';

  @override
  String get mongiLetterBodyDefaultThanks =>
      'Thank you for sharing your big and small feelings\nwith Mongi this week too.\nMongi always believes any feeling is okay.';

  @override
  String mongiLetterStreakLong(int streak) {
    return 'You came to see Mongi every day for $streak days.\nYou might not realize how amazing that is,\nbut Mongi felt it every single day.';
  }

  @override
  String mongiLetterStreakShort(int streak) {
    return 'You came $streak days in a row!\nWatching a small habit build up like this\nis a great joy for Mongi.';
  }

  @override
  String get mongiLetterStreakNone =>
      'It\'s okay if you couldn\'t come by often this week.\nWhenever you want to, Mongi will always be right here.';

  @override
  String get mongiLetterClosing =>
      'I\'ll always be by your side.\nTalk to me again next week.\n\nYour Mongi 🐾';

  @override
  String get diaryHeaderTitle => '📔 Emotion Diary';

  @override
  String get diaryEmptyTitle => 'No entries yet';

  @override
  String get diaryEmptySubtitle =>
      'Sit with an emotion monster,\nand today\'s story will be added here';

  @override
  String get diaryShareTooltip => 'Share as a card';

  @override
  String diaryNameLabel(String target, String emotion) {
    return '$emotion about $target';
  }

  @override
  String scorePopupGainedLabel(int score) {
    return '+$score pts';
  }

  @override
  String scorePopupTotalLabel(int totalScore) {
    return 'Total $totalScore pts';
  }

  @override
  String get emotionLabelHate => 'Hate';

  @override
  String get emotionLabelAnger => 'Anger';

  @override
  String get emotionLabelWorry => 'Worry';

  @override
  String get emotionLabelSadness => 'Sadness';

  @override
  String get emotionLabelLoneliness => 'Loneliness';

  @override
  String get emotionLabelAnxiety => 'Anxiety';

  @override
  String get emotionLabelShame => 'Shame';

  @override
  String get emotionLabelIrritation => 'Irritation';

  @override
  String get emotionLabelGrievance => 'Grievance';

  @override
  String get emotionLabelFear => 'Fear';

  @override
  String get emotionLabelJoy => 'Joy';

  @override
  String get emotionLabelGratitude => 'Gratitude';

  @override
  String get emotionLabelExcitement => 'Excitement';

  @override
  String get emotionLabelCalm => 'Calm';

  @override
  String get emotionLabelConfidence => 'Confidence';

  @override
  String get emotionLabelTired => 'Tired';

  @override
  String get emotionLabelBoredom => 'Boredom';

  @override
  String get emotionLabelCourage => 'Courage';

  @override
  String get emotionLabelThrill => 'Thrill';

  @override
  String get emotionLabelHappiness => 'Happiness';

  @override
  String get emotionCatQuestionHate =>
      'This is... a Hate Bean. You\'ve been holding onto it for a while, huh.';

  @override
  String get emotionCatQuestionAnger =>
      'A Blaze popped out. You must\'ve been really upset.';

  @override
  String get emotionCatQuestionWorry =>
      'A Worry Cloud rolled in, thick and heavy.';

  @override
  String get emotionCatQuestionSadness =>
      'A Sadness Droplet. That must\'ve been really hard.';

  @override
  String get emotionCatQuestionLoneliness =>
      'You were curled up all alone. I\'ll stay right here with you.';

  @override
  String get emotionCatQuestionAnxiety =>
      'Anxiety Jitters kept trembling. You must\'ve had a lot of worried thoughts.';

  @override
  String get emotionCatQuestionShame =>
      'A little Shy One. Your cheeks must\'ve turned pink.';

  @override
  String get emotionCatQuestionIrritation =>
      'Prickly One\'s spikes were all standing up. You must\'ve been on edge.';

  @override
  String get emotionCatQuestionGrievance =>
      'A tightly knotted Grievance. It must\'ve felt so stifling.';

  @override
  String get emotionCatQuestionFear =>
      'Fear was hiding in the dark. It\'s okay now, I\'m right here.';

  @override
  String get emotionCatQuestionJoy =>
      'A sparkling Joy Star! Something good must\'ve happened today.';

  @override
  String get emotionCatQuestionGratitude =>
      'A warm Gratitude Heart. You must be feeling thankful toward someone.';

  @override
  String get emotionCatQuestionExcitement =>
      'A fluttering Excitement Cloud! What good thing are you looking forward to?';

  @override
  String get emotionCatQuestionCalm =>
      'A gentle Calm Wave. Your heart must feel quiet and at ease.';

  @override
  String get emotionCatQuestionConfidence =>
      'A brave Confidence Badge! You must\'ve accomplished something today - amazing.';

  @override
  String get emotionCatQuestionTired =>
      'A drowsy Tiredness. You worked so hard today.';

  @override
  String get emotionCatQuestionBoredom =>
      'A yawning Boredom. You must\'ve needed something fun.';

  @override
  String get emotionCatQuestionCourage =>
      'A brave Courage Shield! You faced something scary and still stepped forward.';

  @override
  String get emotionCatQuestionThrill =>
      'A bursting Thrill! Something exciting must\'ve happened!';

  @override
  String get emotionCatQuestionHappiness =>
      'A cozy Happiness Sunshine. Your heart must feel full and warm.';

  @override
  String get emotionHealMessageHate =>
      'Where the hate disappeared,\na little flower has bloomed 🌸';

  @override
  String get emotionHealMessageAnger =>
      'The burning heart has cooled,\nand a warm light remains ✨';

  @override
  String get emotionHealMessageWorry =>
      'The dark clouds have cleared,\nand the blue sky is peeking through 🌤️';

  @override
  String get emotionHealMessageSadness =>
      'The tears have dried,\nand stars now shimmer in a small pond 💧';

  @override
  String get emotionHealMessageLoneliness =>
      'The shadow has faded,\nand a warmth stays close by 🤍';

  @override
  String get emotionHealMessageAnxiety =>
      'The trembling has settled,\nand gentle ripples spread across your heart 🌊';

  @override
  String get emotionHealMessageShame =>
      'The hunched shoulders have relaxed,\nand a warm smile spreads 😊';

  @override
  String get emotionHealMessageIrritation =>
      'The spikes have softened gently,\nand a breeze drifts in 🍃';

  @override
  String get emotionHealMessageGrievance =>
      'The tangled heart has unraveled,\nand breathing feels easy again 🎈';

  @override
  String get emotionHealMessageFear =>
      'The darkness has lifted,\nand a small starlight shines on your heart ⭐';

  @override
  String get emotionHealMessageJoy =>
      'Joy has filled your heart,\nand stayed behind as a bright light 🌟';

  @override
  String get emotionHealMessageGratitude =>
      'That grateful feeling has\nwarmly seeped into Mongi\'s heart too 💛';

  @override
  String get emotionHealMessageExcitement =>
      'The flutter reached Mongi too,\nand my heart floated up a little 🎈';

  @override
  String get emotionHealMessageCalm =>
      'That quiet feeling has spread through the garden too,\nand gentle ripples appear 🌊';

  @override
  String get emotionHealMessageConfidence =>
      'That brave feeling passed on to Mongi too,\nand my shoulders straightened up 💪';

  @override
  String get emotionHealMessageTired =>
      'The heavy eyelids have slowly closed,\nand cozy sleep is settling in 🌙';

  @override
  String get emotionHealMessageBoredom =>
      'A little curiosity blooms\nin that blank feeling, swirling into shape 🌀';

  @override
  String get emotionHealMessageCourage =>
      'The pounding heart has grown steady,\nand a burning strength fills Mongi\'s chest too 🔥';

  @override
  String get emotionHealMessageThrill =>
      'That bouncy energy passed on to Mongi too,\nand my whole body is bursting with excitement 🎊';

  @override
  String get emotionHealMessageHappiness =>
      'The warm sunshine has seeped\ninto every corner of the heart, lingering softly ☀️';

  @override
  String get emotionStoryTextHate =>
      'A Hate Bean grows harder the longer you keep it inside. Disliking someone is sometimes proof of how much you once cared. Bring it out into the open, and a flower can bloom in its place.';

  @override
  String get emotionStoryTextAnger =>
      'A Blaze flares up when your heart wasn\'t respected. It\'s not a bad thing - it\'s a signal saying \"please respect me.\" Once it cools down for a moment, only a warm light remains.';

  @override
  String get emotionStoryTextWorry =>
      'A Worry Cloud forms from trying to prepare for things that haven\'t even happened yet. It was, in its own way, an effort to protect yourself. Clouds are made to drift away, so it\'s okay to just watch it for a while.';

  @override
  String get emotionStoryTextSadness =>
      'A Sadness Droplet forms when you\'ve lost something precious or your heart has been hurt. If you let it flow instead of holding it back, those tears pool into a small pond, and one day starlight will shine on it.';

  @override
  String get emotionStoryTextLoneliness =>
      'A Loneliness Shadow grows darker the more you long to connect with someone. Feeling alone means you want to be together with someone that much more. Mongi will stay right by your side.';

  @override
  String get emotionStoryTextAnxiety =>
      'Anxiety Jitters trembles nonstop when you don\'t know what\'s coming. Enduring uncertainty is hard for anyone. If you breathe slowly, the trembling will settle little by little.';

  @override
  String get emotionStoryTextShame =>
      'The Shy One blushes when you\'re worried about how others see you. That really just means you truly wanted to do well. It\'s okay to make mistakes - Mongi loves that side of you too.';

  @override
  String get emotionStoryTextIrritation =>
      'Prickly One raises its spikes when your body and mind are worn out with no room to spare. Feeling irritated can be a sign that it\'s time to rest. Once you set the spikes down, a gentle breeze drifts in.';

  @override
  String get emotionStoryTextGrievance =>
      'The Grievance Knot ties itself tight when you feel your true feelings weren\'t properly understood. It was probably a heart wanting to shout out and be heard. Untangle it bit by bit, and breathing gets easier.';

  @override
  String get emotionStoryTextFear =>
      'Fear is a very old instinct meant to protect you from danger. Having something to be afraid of means there\'s something you deeply want to protect. Even in the dark, Mongi will be right there with you.';

  @override
  String get emotionStoryTextJoy =>
      'A Joy Star sparkles when you notice even the smallest happiness without letting it slip by. If you practice holding onto joyful moments a little longer, the starlight shines brighter and lasts longer.';

  @override
  String get emotionStoryTextGratitude =>
      'A Gratitude Heart grows warm and bigger when you notice someone\'s kindness. A single word of thanks plants one more heart in the other person\'s mind too.';

  @override
  String get emotionStoryTextExcitement =>
      'An Excitement Cloud floats up gently when you look forward to something coming your way. Whatever the outcome, the time spent waiting is already a gift in itself.';

  @override
  String get emotionStoryTextCalm =>
      'A Calm Wave doesn\'t only appear when nothing is happening. When you accept yourself just as you are, it spreads gently outward from deep within your heart.';

  @override
  String get emotionStoryTextConfidence =>
      'A Confidence Badge lights up whenever you manage even a small attempt on your own. Recognizing the moment you tried, more than the result, is the secret to collecting more badges.';

  @override
  String get emotionStoryTextTired =>
      'Tiredness is proof that your body and mind worked hard to get through the day. Instead of pushing yourself further, close your eyes and rest for a moment - and you\'ll find the energy to bounce back the next day.';

  @override
  String get emotionStoryTextBoredom =>
      'Boredom shows up when you have nothing particular to do and your heart feels empty. But boredom is actually a sign that you want to try something new. Sit still for a while, and a surprisingly fun idea might just pop into your head.';

  @override
  String get emotionStoryTextCourage =>
      'A Courage Shield doesn\'t shine because you weren\'t scared - it shines because you stepped forward even while scared. The moment you carried a trembling heart and still did it is the bravest moment of all.';

  @override
  String get emotionStoryTextThrill =>
      'Thrill bursts out when this very moment is so fun that your body moves before you even think. If Excitement is the flutter of anticipating what\'s to come, Thrill is the burst of exciting energy happening right now.';

  @override
  String get emotionStoryTextHappiness =>
      'Unlike Joy, which sparkles and fades quickly, Happiness Sunshine warms your heart gently and for a long time. Even without anything special happening, when each day just feels okay, this sunshine quietly shines through.';

  @override
  String get evolutionNameHate0 => 'Hate Bean';

  @override
  String get evolutionNameHate1 => 'Fondness Bean';

  @override
  String get evolutionNameHate2 => 'Warmth Bean';

  @override
  String get evolutionNameHate3 => 'Tender Sprout';

  @override
  String get evolutionNameAnger0 => 'Blaze';

  @override
  String get evolutionNameAnger1 => 'Embers';

  @override
  String get evolutionNameAnger2 => 'Warmth';

  @override
  String get evolutionNameAnger3 => 'Radiant Warmth';

  @override
  String get evolutionNameWorry0 => 'Worry Cloud';

  @override
  String get evolutionNameWorry1 => 'Faint Cloud';

  @override
  String get evolutionNameWorry2 => 'Clear Skies';

  @override
  String get evolutionNameWorry3 => 'Clear Star';

  @override
  String get evolutionNameSadness0 => 'Sadness Droplet';

  @override
  String get evolutionNameSadness1 => 'Gentle Ripple';

  @override
  String get evolutionNameSadness2 => 'Starlit Pond';

  @override
  String get evolutionNameSadness3 => 'Starlit Galaxy';

  @override
  String get evolutionNameLoneliness0 => 'Loneliness Shadow';

  @override
  String get evolutionNameLoneliness1 => 'Faint Shadow';

  @override
  String get evolutionNameLoneliness2 => 'Warm Shadow';

  @override
  String get evolutionNameLoneliness3 => 'Together Light';

  @override
  String get evolutionNameAnxiety0 => 'Anxiety Jitters';

  @override
  String get evolutionNameAnxiety1 => 'Calmer Jitters';

  @override
  String get evolutionNameAnxiety2 => 'Peaceful One';

  @override
  String get evolutionNameAnxiety3 => 'Peace Keeper';

  @override
  String get evolutionNameShame0 => 'Shy One';

  @override
  String get evolutionNameShame1 => 'Blushing One';

  @override
  String get evolutionNameShame2 => 'Smiling One';

  @override
  String get evolutionNameShame3 => 'Confident One';

  @override
  String get evolutionNameIrritation0 => 'Prickly One';

  @override
  String get evolutionNameIrritation1 => 'Breezy One';

  @override
  String get evolutionNameIrritation2 => 'Softie';

  @override
  String get evolutionNameIrritation3 => 'Cozy Softie';

  @override
  String get evolutionNameGrievance0 => 'Grievance Knot';

  @override
  String get evolutionNameGrievance1 => 'Loosening Knot';

  @override
  String get evolutionNameGrievance2 => 'Untied Knot';

  @override
  String get evolutionNameGrievance3 => 'Free Knot';

  @override
  String get evolutionNameFear0 => 'Darkling';

  @override
  String get evolutionNameFear1 => 'Dawnling';

  @override
  String get evolutionNameFear2 => 'Starlight';

  @override
  String get evolutionNameFear3 => 'Morning Star';

  @override
  String get evolutionNameJoy0 => 'Joy Star';

  @override
  String get evolutionNameJoy1 => 'Twinkling Star';

  @override
  String get evolutionNameJoy2 => 'Shining Star';

  @override
  String get evolutionNameJoy3 => 'Star Cluster';

  @override
  String get evolutionNameGratitude0 => 'Gratitude Heart';

  @override
  String get evolutionNameGratitude1 => 'Warm Heart';

  @override
  String get evolutionNameGratitude2 => 'Glowing Heart';

  @override
  String get evolutionNameGratitude3 => 'Galaxy Heart';

  @override
  String get evolutionNameExcitement0 => 'Excitement Cloud';

  @override
  String get evolutionNameExcitement1 => 'Fluttering Cloud';

  @override
  String get evolutionNameExcitement2 => 'Sparkling Cloud';

  @override
  String get evolutionNameExcitement3 => 'Rainbow Cloud';

  @override
  String get evolutionNameCalm0 => 'Calm Wave';

  @override
  String get evolutionNameCalm1 => 'Gentle Sea';

  @override
  String get evolutionNameCalm2 => 'Quiet Sea';

  @override
  String get evolutionNameCalm3 => 'Silver Sea';

  @override
  String get evolutionNameConfidence0 => 'Confidence Badge';

  @override
  String get evolutionNameConfidence1 => 'Shining Badge';

  @override
  String get evolutionNameConfidence2 => 'Golden Badge';

  @override
  String get evolutionNameConfidence3 => 'Legendary Badge';

  @override
  String get evolutionNameTired0 => 'Drowsy One';

  @override
  String get evolutionNameTired1 => 'Sleepy One';

  @override
  String get evolutionNameTired2 => 'Cozy One';

  @override
  String get evolutionNameTired3 => 'Cozy Moonlight';

  @override
  String get evolutionNameBoredom0 => 'Boredom Swirl';

  @override
  String get evolutionNameBoredom1 => 'Wiggly Swirl';

  @override
  String get evolutionNameBoredom2 => 'Sparkling Swirl';

  @override
  String get evolutionNameBoredom3 => 'Starlit Swirl';

  @override
  String get evolutionNameCourage0 => 'Courage Shield';

  @override
  String get evolutionNameCourage1 => 'Sturdy Shield';

  @override
  String get evolutionNameCourage2 => 'Shining Shield';

  @override
  String get evolutionNameCourage3 => 'Guardian Shield';

  @override
  String get evolutionNameThrill0 => 'Thrill Spark';

  @override
  String get evolutionNameThrill1 => 'Bouncy Spark';

  @override
  String get evolutionNameThrill2 => 'Bursting Spark';

  @override
  String get evolutionNameThrill3 => 'Galaxy Spark';

  @override
  String get evolutionNameHappiness0 => 'Happiness Sunshine';

  @override
  String get evolutionNameHappiness1 => 'Warm Sunshine';

  @override
  String get evolutionNameHappiness2 => 'World Sunshine';

  @override
  String get evolutionNameHappiness3 => 'Eternal Sunshine';

  @override
  String gameEatenLineSingle(String label) {
    return 'There! $label settled into your heart';
  }

  @override
  String gameEatenLineStreak(String label, int streak) {
    return '$label x$streak in a row!';
  }

  @override
  String gameReceivedLineSingle(String label) {
    return 'Cozy! $label warmed your heart';
  }

  @override
  String gameReceivedLineStreak(String label, int streak) {
    return '$label shines x$streak in a row ✨';
  }

  @override
  String get gameFirstMeetCaption => '🏷️ First time meeting this feeling';

  @override
  String get gamePerfectTimingLabel => 'Perfect timing! ✨';

  @override
  String get gameRockHitLabel => 'Ouch! 😳';

  @override
  String get gameReviveEncouragementLabel => 'Let\'s try again! 💪';

  @override
  String gameTimeUpLabel(int count) {
    return 'Time\'s up! You met $count feelings ⏰';
  }

  @override
  String gameEarlyStopShortEndless(int count) {
    return 'Today\'s run: made it to $count! 🤍';
  }

  @override
  String gameEarlyStopShortNormal(int count) {
    return 'You met $count feelings today 🤍';
  }

  @override
  String get gameStageClearPurrLabel => 'Purr~ 😽';

  @override
  String get gameBreathingLifeRestoredLabel => 'Nice breathing! 💗';

  @override
  String get gameBreathingBonusLabel => 'Nice breathing! ✨';

  @override
  String get gameBreathingSkippedLabel => 'Took a little break 🌿';

  @override
  String get gamePowerModeActivatedLabel => 'Invincible mode! 💥⚡';

  @override
  String get gamePowerSmashLabel => 'Bam! 💥';

  @override
  String get gameTreatBonusLabel => 'Sparkle bonus! ✨ +2';

  @override
  String get gameHeartRestoredLabel => 'Life restored! 💗';

  @override
  String get settingsTermsOfService => 'Terms of Service';

  @override
  String get termsHeaderTitle => '📜 Terms of Service';

  @override
  String get termsIntro =>
      'Thank you for using Mongi\'s Healing Garden. These terms describe the rights and responsibilities between Mongi (the provider) and you as a user of the service.';

  @override
  String get termsSection1Title => '1. Provision of Service';

  @override
  String get termsSection1Body =>
      'Mongi\'s Healing Garden is a mobile app providing healing content such as emotion journaling, garden building, and mini-games. All or part of the service may change or be discontinued without prior notice.';

  @override
  String get termsSection2Title => '2. In-App Purchases and Payments';

  @override
  String get termsSection2Body =>
      'Paid items in the app (premium frames, garden decorations, season pass, light essence, etc.) are purchased through Google Play\'s billing system, and digital content is delivered immediately upon payment. The right of withdrawal may be limited as permitted by applicable law, and refunds follow Google Play\'s policies.';

  @override
  String get termsSection3Title => '3. Advertising';

  @override
  String get termsSection3Body =>
      'Ads (banner/interstitial/rewarded) served via Google AdMob may appear to support the operation of the service. Watching rewarded ads is optional, and core features remain available regardless of whether you choose to watch them.';

  @override
  String get termsSection4Title => '4. User Obligations';

  @override
  String get termsSection4Body =>
      'Users must not manipulate or tamper with the service through improper means, or interfere with other users\' use of the service. Violations may result in restricted access to the service.';

  @override
  String get termsSection5Title =>
      '5. Disclaimer and Mental Health Content Notice';

  @override
  String get termsSection5Body =>
      'The mental health support information within Mongi (hotline numbers, text lines, etc.) is provided for reference only and does not replace professional medical or psychological care. In an urgent crisis, please contact your local emergency services or a professional organization immediately.';

  @override
  String get termsSection6Title => '6. Changes to These Terms';

  @override
  String get termsSection6Body =>
      'These terms may be revised due to changes in applicable law or the service. We will notify you of important changes through an in-app notice. If you do not agree to the revised terms, you may discontinue using the service.';

  @override
  String get termsLastUpdatedDate => 'August 25, 2026';

  @override
  String termsLastUpdatedLabel(String date) {
    return 'Last updated: $date';
  }

  @override
  String mindChallengeHomeBannerTitleActive(
    String emoji,
    String title,
    int day,
    int total,
  ) {
    return '$emoji $title · Day $day/$total';
  }

  @override
  String get mindChallengeHomeBannerTitleInactive =>
      '🌿 Start a Mind Challenge';

  @override
  String get mindChallengeHomeBannerSubtitleActive =>
      'Check in today to fill today\'s step';

  @override
  String get mindChallengeHomeBannerSubtitleInactive =>
      'Care for your mind with a 7-day theme journey';

  @override
  String get mindChallengeListAppBarTitle => 'Mind Challenges';

  @override
  String get mindChallengeListHeadline =>
      'Pick a theme and spend 7 days together';

  @override
  String get mindChallengeListSubtitle =>
      'Do today\'s emotion check-in each day and the challenge moves forward naturally';

  @override
  String mindChallengeCardDurationLabel(int days) {
    return '$days-day journey';
  }

  @override
  String get mindChallengeCardStartButton => 'Start';

  @override
  String get mindChallengeCardContinueButton => 'Continue';

  @override
  String get mindChallengeCardInProgressBadge => 'In progress';

  @override
  String get mindChallengeCardCompletedBadge => 'Completed';

  @override
  String get mindChallengeStartConfirmTitle => 'Start this challenge?';

  @override
  String mindChallengeStartConfirmBody(int days) {
    return 'Each daily emotion check-in moves this forward by one day. Complete all $days days for a special reward.';
  }

  @override
  String get mindChallengeStartConfirmReplaceBody =>
      'Another challenge is already in progress. Starting a new one will erase its progress. Continue anyway?';

  @override
  String get mindChallengeStartConfirmButton => 'Start';

  @override
  String mindChallengeStartedSnackbar(String title) {
    return 'Started the $title challenge!';
  }

  @override
  String get mindChallengeDetailAppBarTitle => 'Mind Challenge';

  @override
  String mindChallengeDetailDayLabel(int day, int total) {
    return 'Day $day / $total';
  }

  @override
  String mindChallengeDetailProgressLabel(int done, int total) {
    return '$done / $total days completed so far';
  }

  @override
  String get mindChallengeDetailCheckedInToday =>
      'Checked in today! See you tomorrow';

  @override
  String get mindChallengeDetailNotCheckedInYet =>
      'Do today\'s emotion check-in to fill today\'s step';

  @override
  String get mindChallengeDetailCompleteReadyTitle =>
      'Congrats! You completed the challenge';

  @override
  String get mindChallengeDetailCompleteButton => 'Claim completion reward';

  @override
  String get mindChallengeDetailCompletedSnackbar =>
      'Challenge completed! Reward claimed';

  @override
  String get mindChallengeDetailAbandonButton => 'Give up challenge';

  @override
  String get mindChallengeDetailAbandonConfirmTitle =>
      'Give up this challenge?';

  @override
  String get mindChallengeDetailAbandonConfirmBody =>
      'Your progress so far will be lost. Give up anyway?';

  @override
  String get mindChallengeDetailAbandonConfirmButton => 'Give up';

  @override
  String mindChallengeDetailDayRewardLabel(int reward) {
    return '💡+$reward per day completed';
  }

  @override
  String mindChallengeDetailCompletionRewardLabel(int light, int shard) {
    return 'Completion reward 💡+$light ⭐+$shard';
  }

  @override
  String get mindChallengeTitleSelfEsteem => 'Nurturing Self-Esteem';

  @override
  String get mindChallengeDescSelfEsteem =>
      'For 7 days, speak kindly to yourself and slowly rebuild your self-esteem.';

  @override
  String get mindChallengeDaySelfEsteem1 =>
      'Day 1: Think of one thing you did well today.';

  @override
  String get mindChallengeDaySelfEsteem2 =>
      'Day 2: Tell yourself in the mirror, \"You did great.\"';

  @override
  String get mindChallengeDaySelfEsteem3 =>
      'Day 3: Write down one of your strengths.';

  @override
  String get mindChallengeDaySelfEsteem4 =>
      'Day 4: Make today a day without comparing yourself to others.';

  @override
  String get mindChallengeDaySelfEsteem5 =>
      'Day 5: Praise yourself for even a small achievement.';

  @override
  String get mindChallengeDaySelfEsteem6 =>
      'Day 6: Look at one hard thought from a slightly different angle.';

  @override
  String get mindChallengeDaySelfEsteem7 =>
      'Day 7: Look back on the past 6 days and write yourself a letter.';

  @override
  String get mindChallengeTitleAnxietyCalm => 'Calming Anxiety';

  @override
  String get mindChallengeDescAnxietyCalm =>
      'For 7 days, pause and breathe each day to ease an anxious mind.';

  @override
  String get mindChallengeDayAnxietyCalm1 =>
      'Day 1: Give a name to the anxiety you feel right now.';

  @override
  String get mindChallengeDayAnxietyCalm2 =>
      'Day 2: Slowly breathe in and out four times.';

  @override
  String get mindChallengeDayAnxietyCalm3 =>
      'Day 3: Do just one very small thing you can do right now.';

  @override
  String get mindChallengeDayAnxietyCalm4 =>
      'Day 4: Remind yourself, \"This moment will pass.\"';

  @override
  String get mindChallengeDayAnxietyCalm5 =>
      'Day 5: Write your worries down on paper to see them clearly.';

  @override
  String get mindChallengeDayAnxietyCalm6 =>
      'Day 6: Find three things that are certain today.';

  @override
  String get mindChallengeDayAnxietyCalm7 =>
      'Day 7: Look back on how your anxiety changed this week.';

  @override
  String get mindChallengeTitleBurnoutRecovery => 'Recovering from Burnout';

  @override
  String get mindChallengeDescBurnoutRecovery =>
      'For 7 days, rest a little each day to recover a tired mind.';

  @override
  String get mindChallengeDayBurnoutRecovery1 =>
      'Day 1: Let go of one thing today that you don\'t have to do.';

  @override
  String get mindChallengeDayBurnoutRecovery2 =>
      'Day 2: Take even a moment to do absolutely nothing.';

  @override
  String get mindChallengeDayBurnoutRecovery3 =>
      'Day 3: Notice one thing that\'s been draining you.';

  @override
  String get mindChallengeDayBurnoutRecovery4 =>
      'Day 4: Do something you love for just 5 minutes.';

  @override
  String get mindChallengeDayBurnoutRecovery5 =>
      'Day 5: Tell yourself, \"I\'ve done enough.\"';

  @override
  String get mindChallengeDayBurnoutRecovery6 =>
      'Day 6: Rest a little earlier than usual today.';

  @override
  String get mindChallengeDayBurnoutRecovery7 =>
      'Day 7: Write down the ways you cared for yourself this week.';

  @override
  String get mindChallengeTitleGratitudeHabit => 'Building a Gratitude Habit';

  @override
  String get mindChallengeDescGratitudeHabit =>
      'For 7 days, find a moment of gratitude each day and grow a more positive outlook.';

  @override
  String get mindChallengeDayGratitudeHabit1 =>
      'Day 1: Think of one moment today you were grateful for.';

  @override
  String get mindChallengeDayGratitudeHabit2 =>
      'Day 2: Think of one person who has helped you.';

  @override
  String get mindChallengeDayGratitudeHabit3 =>
      'Day 3: Be grateful for one thing you usually take for granted.';

  @override
  String get mindChallengeDayGratitudeHabit4 =>
      'Day 4: Find something good in today\'s weather or scenery.';

  @override
  String get mindChallengeDayGratitudeHabit5 =>
      'Day 5: Write down one thing you own that you\'re grateful for.';

  @override
  String get mindChallengeDayGratitudeHabit6 =>
      'Day 6: Find a small bit of luck you had today.';

  @override
  String get mindChallengeDayGratitudeHabit7 =>
      'Day 7: Look back on the grateful moments you found this week.';

  @override
  String get mindReportMoodTrendTitle => 'Mood Trend Graph';

  @override
  String get mindReportMoodTrendNotEnoughData =>
      'Still gathering data. Keep coming back for a bit longer 🌱';

  @override
  String get moodTrendHeaderTitle => 'Mood Trend Graph';

  @override
  String get moodTrendIntroText =>
      'Based on the emotions you\'ve logged each day, here\'s how your mood has been trending recently. Higher points mean more comfortable days, lower points mean tougher days.';

  @override
  String get moodTrendWindow7Days => '7 days';

  @override
  String get moodTrendWindow14Days => '14 days';

  @override
  String get moodTrendWindow30Days => '30 days';

  @override
  String get moodTrendNotEnoughTitle => 'Not quite enough data yet';

  @override
  String get moodTrendNotEnoughBody =>
      'Log your emotions for at least 4 days\nto see your mood trend as a graph';

  @override
  String get moodTrendChartTitle => 'Mood Trend';

  @override
  String moodTrendSessionsLabel(int count) {
    return '· $count check-ins';
  }

  @override
  String get moodTrendLegendPositive => 'Comfortable days';

  @override
  String get moodTrendLegendNegative => 'Tough days';

  @override
  String get moodTrendDirectionNotEnoughData =>
      'There isn\'t quite enough data yet to tell a trend.';

  @override
  String get moodTrendDirectionImproving =>
      'Your mood has been gradually getting lighter lately 🌤️';

  @override
  String get moodTrendDirectionSteady =>
      'Your mood has been flowing steadily. Keep logging just like this 🤍';

  @override
  String get moodTrendDirectionDeclining =>
      'There have been some heavier days lately. It\'s okay to rest for a while 🫂';

  @override
  String get homeCheerBannerTitle => '💌 Mongi\'s Cheer Mailbox';

  @override
  String get homeCheerBannerSubtitleBothDone =>
      'You\'ve sent and received today\'s cheer';

  @override
  String get homeCheerBannerSubtitleHasNew => 'A cheer arrived for you today';

  @override
  String get homeCheerBannerSubtitleDefault => 'Share a little kindness';

  @override
  String get homeCheerBannerNewBadge => 'Open';

  @override
  String get cheerScreenAppBarTitle => 'Mongi\'s Cheer Mailbox';

  @override
  String get cheerScreenHonestyNotice =>
      'This app doesn\'t connect you directly with others yet. Mongi carries your heart in its place 🐱';

  @override
  String get cheerSendSectionTitle => 'Send a Heart';

  @override
  String get cheerSendSectionSubtitle =>
      'Pick one, and Mongi will pass it on to the world';

  @override
  String get cheerSendDoneTitle => 'You\'ve entrusted today\'s heart to Mongi';

  @override
  String get cheerSendDoneSubtitle => 'You can send another one tomorrow';

  @override
  String get cheerSendConfirmSnackbar => 'Mongi delivered your heart safely 💌';

  @override
  String get cheerReceiveSectionTitle => 'Receive a Heart';

  @override
  String get cheerReceiveButtonLabel => 'Open today\'s cheer';

  @override
  String get cheerReceiveCardLabel => 'Someone\'s heart';

  @override
  String cheerRewardEarned(int amount) {
    return '+$amount Light Essence';
  }

  @override
  String get cheerSendOption0 =>
      'You\'ve worked hard today. You\'re doing your part well.';

  @override
  String get cheerSendOption1 => 'You\'re already enough, just as you are.';

  @override
  String get cheerSendOption2 => 'Your day, your feelings, they all matter.';

  @override
  String get cheerSendOption3 => 'It\'s okay to rest for a moment.';

  @override
  String get cheerSendOption4 => 'You\'re doing so much better than you think.';

  @override
  String get cheerSendOption5 =>
      'Another day has quietly passed. That\'s enough.';

  @override
  String get cheerReceiveMessage0 => 'You made it through today. Well done.';

  @override
  String get cheerReceiveMessage1 =>
      'Someone out there is rooting for you today.';

  @override
  String get cheerReceiveMessage2 =>
      'The path you\'ve walked so far wasn\'t in vain.';

  @override
  String get cheerReceiveMessage3 => 'You are not alone.';

  @override
  String get cheerReceiveMessage4 =>
      'Small steps are still steps. You\'re doing fine.';

  @override
  String get cheerReceiveMessage5 =>
      'It\'s okay not to be perfect. That\'s just being human.';

  @override
  String get cheerReceiveMessage6 => 'Applause for you today 👏';

  @override
  String get cheerReceiveMessage7 =>
      'On hard days, it\'s okay to pause for a while.';

  @override
  String get cheerReceiveMessage8 => 'Someone notices your effort.';

  @override
  String get cheerReceiveMessage9 =>
      'Be a little kinder to yourself today too.';

  @override
  String get cheerReceiveMessage10 => 'Even right now, you are growing.';

  @override
  String get cheerReceiveMessage11 =>
      'It\'s okay to not be okay. Some days are just like that.';

  @override
  String get cheerReceiveMessage12 => 'I\'m glad you\'re here.';

  @override
  String get cheerReceiveMessage13 => 'Tell yourself you did well today.';

  @override
  String get cheerReceiveMessage14 => 'Going at your own pace is enough.';

  @override
  String get cheerReceiveMessage15 => 'Someone truly wishes you well.';

  @override
  String mindReflectionEmotionWeekdayLink(
    String emotion,
    String weekday,
    int count,
  ) {
    return 'You\'ve felt $emotion especially often on ${weekday}s - $count times recently.';
  }

  @override
  String mindReflectionTriggerNegativeLink(String trigger, int count) {
    return '\'$trigger\' often shows up together with hard feelings - about $count times recently.';
  }

  @override
  String mindReflectionGrowthSignal(String emotion) {
    return '$emotion has clearly eased up compared to before. It seems things are getting a little lighter.';
  }

  @override
  String get mindReflectionGratitudeMoodLink =>
      'On days you logged something you\'re grateful for, your mood tended to be steadier.';

  @override
  String mindReflectionConsistencySignal(int streak) {
    return 'You\'ve checked in for $streak days in a row. That consistency itself is powerful.';
  }

  @override
  String get mindReflectionDefaultObservation =>
      'No clear pattern yet, but Mongi will notice more the longer you keep journaling.';

  @override
  String get settingsAiReflectionTitle => '🌿 Mind Reflection';

  @override
  String get settingsAiReflectionDesc =>
      'Mongi combines your records to point out patterns in your mind. Nothing is sent to a server - it\'s all calculated on this device. You can turn it off anytime.';

  @override
  String get mindReportReflectionTitle => 'Mongi\'s Mind Reflection';

  @override
  String get mindReportReflectionOptInPrompt =>
      'We can show deeper insights by combining your records. Want to turn this on in Settings?';

  @override
  String get mindReportReflectionOptInButton => 'Turn on in Settings';

  @override
  String get mindReportReflectionNotEnoughData =>
      'A few more records would help - try adding at least 5 diary entries.';
}
