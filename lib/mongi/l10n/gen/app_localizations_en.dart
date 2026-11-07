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
      "Something on your mind today?\nLet's spend a little time together.";

  @override
  String get onboardingPage2Title => "Mongi runs\non their own";

  @override
  String get onboardingPage2Desc =>
      "No need to steer!\nJust time your jumps and punches.";

  @override
  String get onboardingPage3Title =>
      'Left ✊ Punch button\nRight 🦘 Jump button';

  @override
  String get onboardingPage3Desc =>
      'Punch small rocks right on time!\nBig rocks must be dodged with the jump button.';

  @override
  String get onboardingPage4Title =>
      "Mongi welcomes each\nfeeling you come across";

  @override
  String get onboardingPage4Desc =>
      "The feelings you collect\nbecome flowers in your garden 🌷";

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingFinish => 'Go meet Mongi 🐾';

  @override
  String get homeHeadline =>
      "What's on\nyour mind today?";

  @override
  String get homeSubCaption =>
      "Left ✊ Punch / Right 🦘 Jump\nRun with Mongi and collect the feeling creatures along the way!";

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
    return "Garden growth $percent%";
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
      "Could you use a little support?";

  @override
  String get homeSupportAlertBody =>
      "You don't have to handle everything alone. You can reach out to someone you trust.";

  @override
  String get homeComebackCareTitleShort => 'Good to see you again!';

  @override
  String homeComebackCareBodyShort(int days) {
    return "Welcome back after $days days. Mongi is happy to see you. Pick up wherever you'd like 🌱";
  }

  @override
  String get homeComebackCareTitleLong =>
      'It\'s been a while - how have you been?';

  @override
  String homeComebackCareBodyLong(int days) {
    return "It's been $days days. Mongi has been resting here, and your progress is still yours. Take your time settling in 💛";
  }

  @override
  String get homeChargeButton => 'Top up';

  @override
  String get homeMindBoxChip => "Costume box";

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
    return "Season $season · Mongi's Journey · Lv. $level";
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
    return "Rewards to claim: $count";
  }

  @override
  String get homeMindReportButton => "Mood report";

  @override
  String get homeBreathingButton => 'Breathe';

  @override
  String get homeNameFieldHint =>
      "Want to tell Mongi what's on your mind? (Optional)";

  @override
  String get homeHowToTitle => '👇 How to play';

  @override
  String get homeHowToStep1 => 'Pick your\nemotions below\n(up to 3)';

  @override
  String get homeHowToStep2 => 'Start running\nwith Mongi!';

  @override
  String get homeHowToStep3 => "Run into a feeling\nto collect it";

  @override
  String get homeHowToStep4 => "Plant it as a seed\nin your garden";

  @override
  String get homeMaxSelectSnackbar => "Choose up to 3 feelings";

  @override
  String get homeIntensityLabel =>
      "How strong is this feeling right now?";

  @override
  String get homeFriendlyCaption =>
      "Whatever you're feeling, you're welcome here 🐾";

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
  String get homeQuietModeButton => "🌙 Take a quiet moment";

  @override
  String get homeMonetizationSectionLabel => 'Shop & currency below';

  @override
  String get quietModeAppBarTitle => 'Quiet Mode';

  @override
  String get quietModeGreetTitle => "Let's take a moment to notice how you feel";

  @override
  String get quietModeGreetSubtitle =>
      'No need to rush. Mongi is right here with you.';

  @override
  String get quietModeGreetNextButton => 'Next';

  @override
  String get quietModeBreatheTitle => "Let's take a slow breath";

  @override
  String get quietModeBreatheStartButton => 'Start';

  @override
  String get quietModeBreatheSkipButton => 'Skip';

  @override
  String get quietModeReflectTitle => 'Want to jot a short note? (optional)';

  @override
  String get quietModeReflectHint => 'Write a short note about how you feel';

  @override
  String get quietModePlantButton => "Plant in the garden";

  @override
  String get quietModePlantingMessage =>
      "Planting a flower for this feeling…";

  @override
  String get quietModeDoneTitle => "A new flower in your garden";

  @override
  String quietModeDoneBody(int count) {
    return "Flowers planted for your feelings: $count. You can visit them anytime.";
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
  String get shopMindBoxTitle => "Costume box";

  @override
  String get shopMindBoxSubtitle =>
      "Collect costumes for Mongi with Light Essence. Each costume is guaranteed, with no random odds.";

  @override
  String get shopPowerCharmTitle => 'Power Charm';

  @override
  String shopPowerCharmSubtitle(int count) {
    return "Use one for 10 seconds of invincibility during a run. You have $count.";
  }

  @override
  String get shopMongiCareTitle => 'Mongi Care Set';

  @override
  String get shopMongiCareSubtitle =>
      "Food, treats, and cozy gifts for Mongi";

  @override
  String get shopGardenDecoTitle => 'Decorate Garden';

  @override
  String get shopGardenDecoSubtitle =>
      'Free decorations like benches & fountains + premium decor packs';

  @override
  String get shopSectionSeason => '🌟 Season & Membership';

  @override
  String get shopSeasonPassTitle =>
      "Mongi's Journey (Season Pass)";

  @override
  String get shopSeasonPassSubtitle =>
      "Unlock this season's premium reward track";

  @override
  String get settingsHeader => '⚙️ Settings';

  @override
  String get settingsNotifTitle => 'Daily Mongi Reminder';

  @override
  String get settingsNotifPermissionDenied =>
      'Notification permission is required. Please allow it in device settings.';

  @override
  String get settingsNotifDesc =>
      "Choose a time for one daily reminder\nto check in with Mongi and your feelings.";

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
  String get settingsDataNoticeTitle => "📱 Where your data is stored";

  @override
  String get settingsDataNoticeBody =>
      'Mongi requires no login and stores your garden, diary, and progress only on this device. If you delete the app or switch devices, this record will be lost.\nPurchased items can be restored via your Google account, but the garden itself cannot be restored.';

  @override
  String get settingsMentalHealthTitle => 'When things feel hard';

  @override
  String get settingsMentalHealthSubtitle =>
      "Support is available · View 24/7 resources";

  @override
  String get settingsPrivacyPolicy => 'Privacy Policy';

  @override
  String get settingsResetTitle => "Reset all progress";

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
      "Jump over rocks. Run into feeling creatures to collect them!";

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
    return "Now showing: $label";
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
  String get endlessHintTitle => "See how far you and Mongi can go!";

  @override
  String get endlessHintGoal =>
      'Collect as many as you can before you run out of lives';

  @override
  String endlessHudBestRecord(int count) {
    return '👑 Best $count';
  }

  @override
  String get homeMongiMoodWaiting =>
      "Mongi is ready to spend a little time with you.";

  @override
  String get homeMongiMoodJoyful =>
      "You've recorded some brighter feelings lately. Mongi has a spring in their step 🐾";

  @override
  String get homeMongiMoodHeavy =>
      "You've recorded some difficult feelings lately. Mongi is here to keep you company.";

  @override
  String get homeMongiMoodCalm =>
      "Mongi is settled in beside you. There's no rush.";

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
  String get gardenHeaderTitle => "🌷 My garden";

  @override
  String get gardenTooltipCollection => "Mood collection";

  @override
  String get gardenTooltipMilestone => "Growth milestones";

  @override
  String get gardenTooltipShare => 'Share Garden';

  @override
  String get gardenTooltipCalendar => "Mood calendar";

  @override
  String get gardenTooltipDiary => 'Diary';

  @override
  String gardenSummaryFlowersPlanted(int count) {
    return "Flowers grown in your garden: $count";
  }

  @override
  String get gardenStatRecoveryLabel => "Growth";

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
      "Your growth tree is resting. A visit today will perk it up 🌤️";

  @override
  String gardenTreeMaxStageHint(String label) {
    return "Mongi's tree has reached its final stage: $label!";
  }

  @override
  String gardenTreeGrowthHint(String label, int remaining) {
    return "Mongi's tree: $label · $remaining points to the next stage";
  }

  @override
  String get gardenEmptyTitle => 'No flowers planted yet';

  @override
  String get gardenEmptyBody =>
      "As you record your feelings,\nflowers will bloom here.";

  @override
  String gardenFlowerBedTitle(String emotionLabel) {
    return "$emotionLabel garden";
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
    return "You haven't planted $seedLabel yet";
  }

  @override
  String get gardenTreeWiltedSnackbar =>
      "Your growth tree is resting. A visit today will perk it up 🌤️";

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
      "Summer sunshine fills Mongi's garden";

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
    return "You and Mongi collected\n$count feeling creatures: $nameLabel";
  }

  @override
  String choiceAskingHeadlineNoCount(String nameLabel) {
    return "Today, you took a moment\nto notice $nameLabel";
  }

  @override
  String get choiceAskingPrompt => "Ready to plant\na seed for this feeling?";

  @override
  String get choiceAskingNotYetButton => 'Not just yet';

  @override
  String get choiceAskingPlantButton => 'Yes, let\'s plant';

  @override
  String choiceEarlyStopWithRemaining(int count, int remaining) {
    return "Feeling creatures collected: $count.\n$remaining got away. You can try again whenever you'd like 🤍";
  }

  @override
  String choiceEarlyStopNoRemaining(int count) {
    return "Feeling creatures collected: $count.\nTime for a rest. Thanks for playing 🤍";
  }

  @override
  String choiceComboLow(int count) {
    return "You kept a combo going $count times!";
  }

  @override
  String choiceComboMid(int count) {
    return "$count in a row—nice timing!";
  }

  @override
  String choiceComboHigh(int count) {
    return "$count in a row! You and Mongi are on a roll 💪";
  }

  @override
  String choiceInsightFrequentPositive(int count) {
    return "You've recorded this feeling $count times this week.\nIs there a moment you'd like to remember? ☺️";
  }

  @override
  String choiceInsightFrequentNegative(int count) {
    return "You've recorded this feeling $count times this week.\nMongi is here if you'd like to take a moment with it.";
  }

  @override
  String get choiceInsightAllPositive =>
      "You chose some happy feelings today.\nTake a moment to enjoy them, if you'd like ✨";

  @override
  String choiceInsightLongAbsence(String emotionLabel, int days) {
    return "You recorded $emotionLabel again\nafter $days days. How does it feel today?";
  }

  @override
  String choiceInsightFirstEncounter(String emotionLabel) {
    return "This is your first diary entry for $emotionLabel.\nThanks for sharing a little of your day with Mongi.";
  }

  @override
  String choiceNextGoalAlmostCollected(int count) {
    return 'Meet just $count more feelings and your collection will be complete!\nWhat feeling will it be next? 🔍';
  }

  @override
  String choiceNextGoalTreeAlmost(int points) {
    return "Mongi's tree needs $points more points for its next stage.\nCome back to it whenever you'd like 🌳";
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
    return "Mongi's tree has reached\nthe $label stage!";
  }

  @override
  String get choiceTreeGrowthHint =>
      "Your tree grows as you spend time\nrecording your feelings 🌱";

  @override
  String choiceTreeGrowthBonus(int bonus) {
    return "Your tree grew! Light Essence +$bonus";
  }

  @override
  String get choiceTreeGrowthShareButton => 'Share this moment';

  @override
  String get choiceResultTitleBloomed => 'The garden has burst into bloom! 🌸';

  @override
  String choiceResultTitleSeedPlanted(String seedLabel) {
    return "A seed of $seedLabel is planted in your garden";
  }

  @override
  String get choiceResultTitlePlanted => "A seed for your feeling";

  @override
  String get choiceResultTitleGentle => 'It\'s okay, take your time';

  @override
  String get choiceResultMessageLove =>
      "A little light\nin your garden today ✨";

  @override
  String get choiceResultMessageNoLove =>
      "Thanks for spending time\nwith your feelings today.\nCome back whenever you'd like 🤍";

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
      "You found a rare frame!\nSee it in your mood collection.";

  @override
  String choiceResultSeedGrown(String seedLabel) {
    return 'The $seedLabel garden grew a little more';
  }

  @override
  String get choiceResultGardenButton => "Visit my garden";

  @override
  String get choiceResultNoteLabel =>
      "Want to write a line about this feeling? (Optional)";

  @override
  String get choiceResultNoteHint => 'e.g. I feel a bit lighter today';

  @override
  String get choiceResultShareButton => "Share mood card";

  @override
  String get choiceResultHomeButton => 'Home';

  @override
  String get choiceIntensityLabel =>
      'How strongly did you feel this emotion today?';

  @override
  String get choiceIntensityVeryWeak => "Very mild";

  @override
  String get choiceIntensityWeak => "Mild";

  @override
  String get choiceIntensityNormal => "Moderate";

  @override
  String get choiceIntensityStrong => 'Strong';

  @override
  String get choiceIntensityVeryStrong => 'Very strong';

  @override
  String get choiceTriggerLabel =>
      "What brought this feeling on? (Optional · Choose any that apply)";

  @override
  String get choiceTranscendenceBadge => 'You discovered a hidden moment';

  @override
  String choiceTranscendenceTitle(String emotionLabel) {
    return "A new milestone for “$emotionLabel”";
  }

  @override
  String get choiceTranscendenceDesc =>
      "You've recorded this feeling 100 times.\nHere's a surprise to mark the moment.";

  @override
  String get choiceSeasonMilestoneBadge => "Journey milestone";

  @override
  String get seasonMilestoneLevel5 =>
      "Level 5! All those small steps have added up 🌱";

  @override
  String get seasonMilestoneLevel10 =>
      "You're halfway there. Look how far you've come 🌿";

  @override
  String get seasonMilestoneLevel15 =>
      "Level 15! Just a few more levels to go 🌳";

  @override
  String get seasonMilestoneLevel20 =>
      "You've completed this season's journey. Thanks for sharing it with Mongi 🌟";

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
  String get mentalHealthHeaderTitle => "🤍 Find support";

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
      "Mongi gives you a place to notice and record your feelings.\nWhen you need more support,\na qualified counselor can help you work through what's going on.";

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
      "Prefer to talk in person? Find a center near you.";

  @override
  String get mentalHealthSafetyPlanTitle => 'Create your own safety plan';

  @override
  String get mentalHealthSafetyPlanSubtitle =>
      "Plan ahead for times when you might need extra support";

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
  String get shareImageConvertError => "Couldn't create the image.";

  @override
  String shareTextBody(String nameLabel, int count) {
    return "Time with Mongi today: $nameLabel · Feeling creatures collected: $count 🐱🌿 #Mongi #EmotionDiary";
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
  String get notificationChannelName => "Daily mood check-in";

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
      "Feel like spending some time in the garden with Mongi? 🌱";

  @override
  String get notificationReminderMessage4 =>
      'Got a moment? Tell Mongi how you\'re feeling today 🌸';

  @override
  String get notificationReminderMessage5 =>
      'Mongi is waiting for you in the little garden 🌷';

  @override
  String get shareTitle => "Today's mood card";

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
    return "Time with Mongi: $nameLabel\nFeeling creatures collected: $count";
  }

  @override
  String shareCardHeadlineNoCount(String nameLabel) {
    return "Today, I took a moment\nto notice $nameLabel";
  }

  @override
  String shareCardComboBadge(int count) {
    return '🔥 Best combo x$count';
  }

  @override
  String get shareCardNoLoveMessage =>
      "A little time with my feelings today.\nNo need to have everything figured out 🤍";

  @override
  String get shareCardPreviewBadge => 'Preview';

  @override
  String reviveFreeOfferCountLabel(int count, String total) {
    return 'Free continue ($count/$total)';
  }

  @override
  String get reviveOfferHeadline => "Want to keep going?";

  @override
  String get reviveFreeOfferBody =>
      'Refill your lives now\nand keep going right where you left off';

  @override
  String get reviveContinueButton => 'Continue 💪';

  @override
  String get reviveDeclineButton => 'I\'ll stop here';

  @override
  String get reviveAdOfferSubtitleSecondTime =>
      "One more chance to continue";

  @override
  String get reviveAdOfferSubtitleFirstTime => "Keep your run going";

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
      "With a few more entries, you'll be able to see patterns by day of the week 🌱";

  @override
  String weekdayObservationHasPattern(String bestDay, String toughestDay) {
    return "Your entries suggest brighter feelings on ${bestDay} and more difficult ones on ${toughestDay}.\nThese are patterns in your entries, not a picture of every moment 🤍";
  }

  @override
  String get weekdayObservationNoClearPattern =>
      "There's no clear pattern by day of the week yet.\nWhatever today brings, there's room for it here 🤍";

  @override
  String get weeklyObservationNoData =>
      'No entries yet this week.\nThat\'s okay - share even a small feeling whenever you\'re ready 🌱';

  @override
  String weeklyObservationImprovedFromLastWeek(int deltaPercent) {
    return "Brighter feelings made up ${deltaPercent} more percentage points of your entries than last week.\nDoes that match how the week felt to you? ✨";
  }

  @override
  String get weeklyObservationDeclinedFromLastWeek =>
      "You recorded more difficult feelings this week than last week.\nIf you'd like, take a moment to think about what you need now 🤍";

  @override
  String weeklyObservationDominantPositive(String emotion) {
    return "“$emotion” appeared most often in this week's entries.\nIs there a moment you'd like to remember? 😊";
  }

  @override
  String weeklyObservationDominantNegative(String emotion) {
    return "“$emotion” appeared most often in this week's entries.\nYou can write more about it whenever you feel ready.";
  }

  @override
  String get weeklyObservationManyNotes =>
      "You wrote several notes this week.\nThey're here for you to read again whenever you'd like 📔";

  @override
  String get weeklyObservationMostlyHeavy =>
      "Many of this week's entries describe difficult feelings.\nYou don't have to make sense of them all right now 🤍";

  @override
  String weeklyObservationDefaultTopEmotion(String emotion, int count) {
    return "Your most recorded feeling this week was\n“$emotion” ($count times). Every feeling has a place here.";
  }

  @override
  String get weeklyObservationDefaultThanks =>
      'Thanks for spending this week with Mongi too.';

  @override
  String get calendarHeaderTitle => "🗓️ Mood calendar";

  @override
  String calendarMonthLabel(int year, int month) {
    return '$month/$year';
  }

  @override
  String get calendarInsightNotEnoughData =>
      "A few more entries will help show\nthis month's mood patterns 🌱";

  @override
  String calendarInsightTitleWithTop(String label) {
    return "Most recorded this month: “$label”";
  }

  @override
  String get calendarInsightTitleFallback => "Explore this month's feelings";

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
  String get calendarWeeklyTrendTitle => "Feelings by week";

  @override
  String get calendarLegendPositive => 'Positive';

  @override
  String get calendarLegendNegative => 'Negative';

  @override
  String get calendarWeekdayTrendTitle => "Feelings by day of the week";

  @override
  String calendarWeekLabel(int week) {
    return 'Wk $week';
  }

  @override
  String get calendarEmptyMonth =>
      "No entries this month yet.\nRecord a feeling whenever you'd like 🌱";

  @override
  String get calendarMonthSummaryTitle => 'This month\'s mood summary';

  @override
  String calendarMonthSummaryTopEmotion(String emotion, String icon) {
    return "Most recorded feeling: “$emotion” $icon";
  }

  @override
  String calendarMonthSummaryTotal(int count) {
    return "You made $count entries this month.\nWhatever you wrote, Mongi is here to keep you company.";
  }

  @override
  String get calendarMonthDistributionTitle => 'This month\'s emotion stats';

  @override
  String calendarMonthDistributionPercent(int percent) {
    return '$percent%';
  }

  @override
  String get calendarMonthAnalysisTitle => "A look back at this month";

  @override
  String get monthlyObservationNoData =>
      "There aren't enough entries for a monthly summary yet.\nWrite whenever it feels right 🌱";

  @override
  String monthlyObservationImprovedFromLastMonth(int deltaPercent) {
    return "Brighter feelings made up $deltaPercent more percentage points of your entries than last month.\nHow does that compare with your own experience? ✨";
  }

  @override
  String get monthlyObservationDeclinedFromLastMonth =>
      "You recorded more difficult feelings this month than last month.\nTake your time looking back, if you'd like 🤍";

  @override
  String monthlyObservationDominantPositive(String emotion, int percent) {
    return "“$emotion” was your most recorded feeling this month ($percent%).\nIs there a moment you'd like to keep? 😊";
  }

  @override
  String monthlyObservationDominantNegative(String emotion, int percent) {
    return "“$emotion” was your most recorded feeling this month ($percent%).\nYou can write more about it whenever you're ready.";
  }

  @override
  String monthlyObservationDiverseEmotions(int count) {
    return "You recorded $count different feelings this month.\nThere's room here for every one of them 🎨";
  }

  @override
  String get monthlyObservationMostlyHeavy =>
      "Many of this month's entries describe difficult feelings.\nIt's okay to take your time with them 🤍";

  @override
  String monthlyObservationDefaultTopEmotion(String emotion, int count) {
    return "Your most recorded feeling this month was\n“$emotion” ($count times). Every feeling has a place here.";
  }

  @override
  String get monthlyObservationDefaultThanks =>
      'Thanks for spending this month with Mongi.';

  @override
  String calendarDayDetailTitle(int day) {
    return "Entries for day $day";
  }

  @override
  String calendarIntensityLabel(String dots) {
    return 'Intensity $dots';
  }

  @override
  String seasonPassAppBarTitle(int seasonNumber) {
    return "Season $seasonNumber · Mongi's Journey";
  }

  @override
  String get seasonPassSubHeadline =>
      "Checking in or writing a gratitude entry also adds to your season progress.\nYou don't have to play every time 🌿";

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
      "Purchase history checked. Any restored purchases will appear shortly.";

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
  String get seasonPassMaxLevelReached => "You've reached the final level!";

  @override
  String seasonPassXpProgress(int xpInto, int span) {
    return '$xpInto / $span xp';
  }

  @override
  String get seasonPassMindMilestoneBadge => "🌿 Journey milestone";

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
      "Would you rather talk in person?\nChoose the type of support you're looking for,\nand we'll open a map to help you find it nearby.";

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
  String get mindReportHeaderTitle => "💗 Mood report";

  @override
  String get mindReportIntroText =>
      "Look back at what you've recorded with Mongi.\nThese numbers are a starting point for reflection, not a score for how you're doing.";

  @override
  String get mindReportSupportAlertTitle =>
      "Could you use some support?";

  @override
  String get mindReportSupportAlertBody =>
      "You don't have to work through everything on your own. You can reach out for support.";

  @override
  String get mindReportSupportEntryLabel =>
      "Find counseling & support";

  @override
  String get mindReportWeeklyTitle => "A look at your week";

  @override
  String mindReportWeeklyPositiveLabel(int percent) {
    return 'Positive $percent%';
  }

  @override
  String mindReportWeeklySessionsLabel(int count) {
    return "· $count sessions together";
  }

  @override
  String get mindReportWeeklyNotEnoughData =>
      "There aren't enough entries for a summary yet. Write whenever you'd like 🌱";

  @override
  String get mindReportMonthlyTitle => "This month's feelings";

  @override
  String mindReportMonthlyTopEmotion(String emotion) {
    return "Most recorded feeling: “$emotion”";
  }

  @override
  String get mindReportMonthlyNoTopEmotion =>
      "Explore this month's entries";

  @override
  String mindReportMonthlyStreak(int days) {
    return '🔥 $days days';
  }

  @override
  String get mindReportMonthlyNotEnoughData =>
      "With a few more entries, you'll be able to see this month's mood patterns 🌱";

  @override
  String get mindReportWeekdayTitle => "Feelings by day of the week";

  @override
  String get mindReportTriggerTitle => "What brought these feelings on?";

  @override
  String get mindReportTriggerNotEnoughData =>
      "Add what brought a feeling on when you make an entry. With a few more answers, patterns can appear here 🌱";

  @override
  String triggerInsightDominantNegativeCause(String trigger, int count) {
    return "You chose “$trigger” alongside difficult feelings $count times.\nIs there anything about that you'd like to reflect on? 🤍";
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
  String get mindReportCollectionTitle => "Mood collection";

  @override
  String get mindReportDiaryTitle => "Garden journal";

  @override
  String mindReportDiaryCount(int count) {
    return '$count stories';
  }

  @override
  String get collectionHeaderTitle => "📖 Mood collection";

  @override
  String get collectionNegativeSectionTitle =>
      "🌧️ Difficult feelings (10 types)";

  @override
  String get collectionPositiveSectionTitle =>
      "🌟 Brighter feelings (5 types)";

  @override
  String get collectionProgressCompleteText =>
      'You\'ve met all 15 feelings! Amazing 🎉';

  @override
  String collectionProgressPartialText(int count) {
    return 'You\'ve met $count feelings so far';
  }

  @override
  String get collectionProgressHint =>
      "Each creature evolves as you meet it again (5 · 20 · 50 times)";

  @override
  String collectionGoldenFrameCount(int count) {
    return "Golden frames collected: $count";
  }

  @override
  String get collectionGoldenFrameEarned => '🏆 Golden Frame Earned!';

  @override
  String get collectionTranscendedBadge => "🌌 Beyond Master";

  @override
  String get collectionTranscendedRank => "Beyond Master rank";

  @override
  String get collectionMasteredRank => 'Master Rank';

  @override
  String collectionStageRank(int stage) {
    return 'Stage $stage';
  }

  @override
  String collectionMetCountLabel(int count) {
    return "Times you've met: $count";
  }

  @override
  String collectionNextEvolutionHint(int remaining, String nextName) {
    return "Meet it $remaining more times to unlock “$nextName”";
  }

  @override
  String get collectionTranscendedMessage =>
      "After 100 encounters, you've discovered a new form.\nA little surprise for you and Mongi 🌌";

  @override
  String get collectionMasteredMessage =>
      'It has fully evolved! From now on, every time you meet it,\nthere\'s a very small chance to earn a golden frame ✨';

  @override
  String get commonCloseButton => 'Close';

  @override
  String gardenShareShareText(String label) {
    return "Mongi's tree has reached the $label stage 🌳 A little time for myself, a little growth in my garden #Mongi #MindGarden";
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
      "Taking time for myself\nand watching my garden grow 🌱";

  @override
  String get milestoneHeaderTitle => "🌳 Mongi's growth story";

  @override
  String get milestoneIntroTitle => 'Mongi\'s tree has finally\nborne fruit 🍎';

  @override
  String get milestoneIntroBody =>
      "Your tree started as a seed. Look at it now!\nEach check-in helped it grow.\nWant to look back on the journey?";

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
    return "You recorded $label often at first,\nand less often lately. How does that compare with how you've been feeling?";
  }

  @override
  String milestoneUncollectedText(int count) {
    return 'There are still $count feelings you haven\'t met yet.\nShall we meet them with the next tree? 🌳';
  }

  @override
  String get milestoneEmptyTimelineText =>
      "No written notes here yet,\nbut the feelings you've recorded helped this tree grow 🌳";

  @override
  String get milestoneClosingQuote =>
      "“Thanks for sharing this time with me.\nWhatever you're feeling next time,\nthere's a place for you here.”";

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
      "My week with Mongi, through the feelings I recorded 🌱 #Mongi #MindGarden";

  @override
  String get weeklyReportShareButton => 'Share this week\'s report';

  @override
  String get weeklyReportNotEnoughTitle => "Not enough entries yet";

  @override
  String get weeklyReportNotEnoughBody =>
      "This week's summary will appear\nwhen there are a few more entries.";

  @override
  String weeklyReportSessionsLabel(int count) {
    return "$count sessions together";
  }

  @override
  String get weeklyReportEmotionsSectionTitle => "Feelings recorded this week";

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
      "Tap an unlocked item to place it or put it away";

  @override
  String get gardenDecoFreeSectionLabel =>
      'Free Items · Unlocked by reaching milestones';

  @override
  String get gardenDecoPremiumSectionLabel =>
      'Premium Items · Garden Decoration Pack';

  @override
  String get gardenDecoRestoreButton => "Restore purchases";

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
    return "Garden growth $percent% (unlocks at 100%)";
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
      "A seed for letting go at your own pace";

  @override
  String get gardenSeedDescLove => "A seed for love";

  @override
  String get gardenSeedDescPeace => "A seed for a moment of calm";

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
      "Unlocks after flowers bloom 10 times";

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
  String get mindBoxHeaderTitle => "🎁 Costume box";

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
  String get mindBoxResultTitleNormal => "🎁 You opened a costume box";

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
  String get endlessResultCardTitle => "Today's run";

  @override
  String get endlessResultEatenCountLabel => "Feeling creatures collected";

  @override
  String endlessResultEatenCountValue(int count) {
    return '$count';
  }

  @override
  String get endlessResultSurvivedTimeLabel => "Time running";

  @override
  String get endlessResultBestRecordLabel => '👑 My Best Record';

  @override
  String endlessResultBestRecordValue(int count, String time) {
    return '$count · $time';
  }

  @override
  String get endlessResultRankingFooter =>
      "Thanks for spending a little time with Mongi today. The score is just part of the game 🤍";

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
    return "Collect $target feeling creatures";
  }

  @override
  String dailyMissionLabelCompleteStage(int target) {
    return "Stage completions: $target";
  }

  @override
  String dailyMissionLabelPlantLove(int target) {
    return "Planting goal: $target";
  }

  @override
  String get dailyMissionSheetTitle => "Today's activities";

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
      "When you have a quiet moment, write a plan\nyou can turn to when things feel difficult.";

  @override
  String get safetyPlanIntroLine2 =>
      "It can be hard to know where to start when you're struggling.\nCome back here to find the ideas and contacts you saved.\nYour answers stay on this device and aren't visible to us.";

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
      "What thoughts, feelings, or situations tell you that you may need extra support?";

  @override
  String get safetyPlanSectionWarningSignsPlaceholder =>
      'e.g. When I haven\'t slept for days, when I think \"nothing matters anymore\"...';

  @override
  String get safetyPlanSectionCopingStrategiesTitle =>
      "Things I can try on my own";

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
      "For example: a friend's name and phone number, a family member, or my counselor";

  @override
  String get safetyPlanSectionSafePlaceTitle => 'A place that feels calming';

  @override
  String get safetyPlanSectionSafePlaceHint =>
      "Where could you go to feel a little more at ease?";

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
  String get breathingMomentTitle => "You found a breathing orb";

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
      "A breath before we begin?";

  @override
  String breathingSuggestionSubtitle(String emoji, String name) {
    return "Take a moment to try $emoji $name before the game.";
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
      "Mongi tucked into the tuna. Just listen to that purr! 🐟";

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
      "Mongi snuggled under the blanket and drifted off. A cozy new spot in the garden 🧣";

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
  String get lightEssenceShopTitle => "Top up Light Essence";

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
      "Write about one good thing from today, however small.";

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
    return "Your longest streak: $best days · Start again whenever you'd like";
  }

  @override
  String get dailyCheckInSkipButton => 'Maybe later';

  @override
  String get mongiLetterHeaderTitle => '💌 Mongi\'s Letter';

  @override
  String get mongiLetterNotEnoughMessage =>
      "Mongi needs a few more entries\nto put a letter together.\nKeep sharing whenever you'd like,\nand check back next week 🐾";

  @override
  String get mongiLetterArrivedTitle => 'A letter has arrived from Mongi';

  @override
  String get mongiLetterTapToOpenHint => 'Tap to open it';

  @override
  String get mongiLetterGreeting =>
      "Hi, it's Mongi 🐱\nThanks for sharing some of your week with me.";

  @override
  String mongiLetterBodyTopTarget(String target) {
    return "You mentioned “$target” a few times this week.\nWould you like to look back at those moments?\nWe can take our time.";
  }

  @override
  String mongiLetterBodyTopEmotion(String emotion) {
    return "“$emotion” came up often in your entries this week.\nIf there's more you'd like to say,\nI'm here to listen.";
  }

  @override
  String get mongiLetterBodyManyNotes =>
      "You left quite a few notes this week.\nLong or short, they're yours to come back to.\nThanks for sharing them with me.";

  @override
  String get mongiLetterBodyMostlyPositive =>
      "There were some brighter feelings in your entries this week.\nIs there a moment you'd like to enjoy again?\nI'd be happy to sit with you while you remember it.";

  @override
  String get mongiLetterBodyMostlyHeavy =>
      "Some of your entries sound like difficult moments.\nYou don't have to explain them all.\nWe can sit here quietly for a while.";

  @override
  String get mongiLetterBodyDefaultThanks =>
      "Thanks for telling me how you've been feeling.\nBig feelings, small feelings—\nthere's room for all of them here.";

  @override
  String mongiLetterStreakLong(int streak) {
    return "We've checked in together for $streak days in a row.\nI hope some of that time felt good to you.\nYou can always take a break when you need one.";
  }

  @override
  String mongiLetterStreakShort(int streak) {
    return "$streak days of checking in together!\nIt's nice to have these small moments\nto look back on.";
  }

  @override
  String get mongiLetterStreakNone =>
      "No need to catch up on days you missed.\nWe can start with today, whenever you're ready.";

  @override
  String get mongiLetterClosing =>
      "Take care of yourself this week.\nDrop by whenever you'd like.\n\nYour friend, Mongi 🐾";

  @override
  String get diaryHeaderTitle => "📔 Garden journal";

  @override
  String get diaryEmptyTitle => 'No entries yet';

  @override
  String get diaryEmptySubtitle =>
      'Reflect in quiet mode and leave a note.\nYou can return to it here.';

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
  String get emotionLabelGrievance => "Feeling wronged";

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
      "Here's a Hate Bean. Want to talk about what's been bothering you?";

  @override
  String get emotionCatQuestionAnger =>
      "There's Blaze. Feeling angry today? We can take a moment with it.";

  @override
  String get emotionCatQuestionWorry =>
      "A Worry Cloud has drifted in. What's on your mind?";

  @override
  String get emotionCatQuestionSadness =>
      "A Sadness Droplet. You don't have to explain if you'd rather sit quietly.";

  @override
  String get emotionCatQuestionLoneliness =>
      "Feeling lonely? I'll keep you company for a while.";

  @override
  String get emotionCatQuestionAnxiety =>
      "Here comes Anxiety Jitters. Is there something you're worried about?";

  @override
  String get emotionCatQuestionShame =>
      "Here's Shy One. It's okay to take your time finding the words.";

  @override
  String get emotionCatQuestionIrritation =>
      "Prickly One has their spikes up. Has something been getting on your nerves?";

  @override
  String get emotionCatQuestionGrievance =>
      "A knot of hurt feelings. Want to tell me what felt unfair?";

  @override
  String get emotionCatQuestionFear =>
      "Darkling is hiding. If you're feeling scared, what might help you feel safer?";

  @override
  String get emotionCatQuestionJoy =>
      "A Joy Star! What's bringing you a little happiness today?";

  @override
  String get emotionCatQuestionGratitude =>
      "A Gratitude Heart. Is there something you're thankful for today?";

  @override
  String get emotionCatQuestionExcitement =>
      "An Excitement Cloud! What are you looking forward to?";

  @override
  String get emotionCatQuestionCalm =>
      "A Calm Wave. Let's enjoy a quiet moment here.";

  @override
  String get emotionCatQuestionConfidence =>
      "A Confidence Badge! What are you feeling good about today?";

  @override
  String get emotionCatQuestionTired =>
      "Drowsy One is yawning. Could you use a little rest, too?";

  @override
  String get emotionCatQuestionBoredom =>
      "A Boredom Swirl. Feel like trying something different?";

  @override
  String get emotionCatQuestionCourage =>
      "A Courage Shield! Was there a moment when you tried something brave?";

  @override
  String get emotionCatQuestionThrill =>
      "A Thrill Spark! What's got you excited?";

  @override
  String get emotionCatQuestionHappiness =>
      "A little sunshine. What feels good about this moment?";

  @override
  String get emotionHealMessageHate =>
      "A flower for this feeling.\nYou can let it rest here for now 🌸";

  @override
  String get emotionHealMessageAnger =>
      "You don't have to work it all out now.\nTake a moment before your next step ✨";

  @override
  String get emotionHealMessageWorry =>
      "One moment at a time.\nYou don't need every answer today 🌤️";

  @override
  String get emotionHealMessageSadness =>
      "It's okay if you're still sad.\nWe can sit here a little longer 💧";

  @override
  String get emotionHealMessageLoneliness =>
      "A quiet moment together.\nI'm glad you stopped by 🤍";

  @override
  String get emotionHealMessageAnxiety =>
      "No need to rush.\nLet's take this moment slowly 🌊";

  @override
  String get emotionHealMessageShame =>
      "You don't have to hide here.\nThere's room for you, just as you are 😊";

  @override
  String get emotionHealMessageIrritation =>
      "A little breathing room.\nYou can pause before carrying on 🍃";

  @override
  String get emotionHealMessageGrievance =>
      "What you wanted to say matters.\nYou can leave those words here 🎈";

  @override
  String get emotionHealMessageFear =>
      "Take your time.\nIt's okay to look for comfort and support ⭐";

  @override
  String get emotionHealMessageJoy =>
      "That was a happy moment.\nLet's enjoy it a little longer 🌟";

  @override
  String get emotionHealMessageGratitude =>
      "Thanks for sharing that with me.\nIt's a lovely thing to remember 💛";

  @override
  String get emotionHealMessageExcitement =>
      "Something to look forward to!\nI'm happy to share this moment with you 🎈";

  @override
  String get emotionHealMessageCalm =>
      "Nothing to hurry toward.\nLet's enjoy the quiet 🌊";

  @override
  String get emotionHealMessageConfidence =>
      "Give yourself some credit.\nThat effort was yours 💪";

  @override
  String get emotionHealMessageTired =>
      "You can stop here for now.\nRest doesn't need to be earned 🌙";

  @override
  String get emotionHealMessageBoredom =>
      "There's no need to fill every moment.\nMaybe something will catch your interest 🌀";

  @override
  String get emotionHealMessageCourage =>
      "You gave it a try.\nThat counts, even if it felt scary 🔥";

  @override
  String get emotionHealMessageThrill =>
      "What a burst of excitement!\nLet yourself enjoy it 🎊";

  @override
  String get emotionHealMessageHappiness =>
      "A good moment, just as it is.\nNo need to make it anything more ☀️";

  @override
  String get emotionStoryTextHate =>
      "Hate Bean carries a feeling that's hard to admit sometimes. You don't have to act on it or make it disappear. You can start by noticing what upset you and what you need now.";

  @override
  String get emotionStoryTextAnger =>
      "Blaze flares up when something feels unfair or a boundary has been crossed. Anger isn't a bad feeling. Take a little time before deciding what you want to do with it.";

  @override
  String get emotionStoryTextWorry =>
      "Worry Cloud drifts from one 'what if' to another. Planning can help, but you don't need to solve every possibility today. Is there one small thing you can deal with now?";

  @override
  String get emotionStoryTextSadness =>
      "Sadness Droplet holds the feeling of missing something or being hurt. You don't have to force a smile or find the right words. It's okay to let yourself feel sad for a while.";

  @override
  String get emotionStoryTextLoneliness =>
      "Loneliness Shadow wishes someone would sit nearby. Feeling lonely can happen even around other people. If you'd like some company, you could send a small hello to someone you trust.";

  @override
  String get emotionStoryTextAnxiety =>
      "Anxiety Jitters finds it hard not to know what's next. Uncertainty can be uncomfortable. You don't need to figure it all out at once; start with what you need in this moment.";

  @override
  String get emotionStoryTextShame =>
      "Shy One worries about what others might think. A mistake or an awkward moment can feel bigger than it is. Try speaking to yourself the way you'd speak to a friend.";

  @override
  String get emotionStoryTextIrritation =>
      "Prickly One gets spiky when everything feels like too much. Sometimes a little space or rest helps. You can pause and check what you need before responding.";

  @override
  String get emotionStoryTextGrievance =>
      "Grievance Knot feels tangled up after being misunderstood or treated unfairly. The words can be hard to find. Try writing what you wish someone understood, just for yourself.";

  @override
  String get emotionStoryTextFear =>
      "Darkling keeps close to the shadows when something feels frightening. You don't have to prove you're brave. Your safety comes first, and it's okay to ask for support.";

  @override
  String get emotionStoryTextJoy =>
      "Joy Star lights up at small happy moments. A kind message, a good song, something that made you laugh. You can enjoy it without needing a reason or a plan.";

  @override
  String get emotionStoryTextGratitude =>
      "Gratitude Heart notices the little kindnesses in a day. Is there one you'd like to remember? A few words are enough, whether you keep them or say thank you to someone.";

  @override
  String get emotionStoryTextExcitement =>
      "Excitement Cloud bobs around at the thought of something ahead. You don't know how it will turn out yet, but you can enjoy looking forward to it.";

  @override
  String get emotionStoryTextCalm =>
      "Calm Wave settles into a quiet moment. Nothing needs fixing right now. If this feels good, you can stay with it for a little while.";

  @override
  String get emotionStoryTextConfidence =>
      "Confidence Badge shines when you give something a try. It doesn't have to go perfectly. Take a moment to give yourself credit for the effort you made.";

  @override
  String get emotionStoryTextTired =>
      "Drowsy One is ready for a break. You don't need to have had a busy day to feel tired. Rest in whatever way feels comfortable, without asking yourself to do more.";

  @override
  String get emotionStoryTextBoredom =>
      "Boredom Swirl can't find anything that holds their attention. Maybe a change of pace would feel good, or maybe a quiet moment is enough. You don't have to make every moment useful.";

  @override
  String get emotionStoryTextCourage =>
      "Courage Shield can feel scared and still try something new. Being brave doesn't have to look impressive. Sometimes it's a small step, a question, or asking for help.";

  @override
  String get emotionStoryTextThrill =>
      "Thrill Spark is full of energy right now. Maybe something made you laugh or got you moving. Enjoy the moment in your own way.";

  @override
  String get emotionStoryTextHappiness =>
      "Happiness Sunshine enjoys the ordinary things: a familiar place, good company, a quiet afternoon. Nothing special has to happen for this moment to feel good.";

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
  String get evolutionNameLoneliness3 => "Shared Light";

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
  String get evolutionNameGrievance3 => "Free Spirit";

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
  String get evolutionNameHappiness0 => "Little Sunshine";

  @override
  String get evolutionNameHappiness1 => 'Warm Sunshine';

  @override
  String get evolutionNameHappiness2 => "Sunshine Everywhere";

  @override
  String get evolutionNameHappiness3 => 'Eternal Sunshine';

  @override
  String gameEatenLineSingle(String label) {
    return "Collected $label!";
  }

  @override
  String gameEatenLineStreak(String label, int streak) {
    return '$label x$streak in a row!';
  }

  @override
  String gameReceivedLineSingle(String label) {
    return "A little $label for your garden!";
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
    return "Time's up! Feeling creatures collected: $count ⏰";
  }

  @override
  String gameEarlyStopShortEndless(int count) {
    return 'Today\'s run: made it to $count! 🤍';
  }

  @override
  String gameEarlyStopShortNormal(int count) {
    return "Feeling creatures collected today: $count 🤍";
  }

  @override
  String get gameStageClearPurrLabel => 'Purr~ 😽';

  @override
  String get gameBreathingLifeRestoredLabel => "Breathing break complete 💗";

  @override
  String get gameBreathingBonusLabel => "A moment to breathe ✨";

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
      "🌿 Start a self-care challenge";

  @override
  String get mindChallengeHomeBannerSubtitleActive =>
      "Check in to complete today's step";

  @override
  String get mindChallengeHomeBannerSubtitleInactive =>
      "Choose a theme for seven days of self-care";

  @override
  String get mindChallengeListAppBarTitle => "Self-care challenges";

  @override
  String get mindChallengeListHeadline =>
      'Pick a theme and spend 7 days together';

  @override
  String get mindChallengeListSubtitle =>
      "Each daily mood check-in completes one step of your challenge";

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
  String get mindChallengeDetailAppBarTitle => "Self-care challenge";

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
      "Check in with your feelings to complete today's step";

  @override
  String get mindChallengeDetailCompleteReadyTitle =>
      'Congrats! You completed the challenge';

  @override
  String get mindChallengeDetailCompleteButton => 'Claim completion reward';

  @override
  String get mindChallengeDetailCompletedSnackbar =>
      'Challenge completed! Reward claimed';

  @override
  String get mindChallengeDetailAbandonButton => "Stop challenge";

  @override
  String get mindChallengeDetailAbandonConfirmTitle =>
      "Stop this challenge?";

  @override
  String get mindChallengeDetailAbandonConfirmBody =>
      "This challenge's progress will be lost. Do you want to stop?";

  @override
  String get mindChallengeDetailAbandonConfirmButton => "Stop";

  @override
  String mindChallengeDetailDayRewardLabel(int reward) {
    return '💡+$reward per day completed';
  }

  @override
  String mindChallengeDetailCompletionRewardLabel(int light, int shard) {
    return 'Completion reward 💡+$light ⭐+$shard';
  }

  @override
  String get mindChallengeTitleSelfEsteem => "Being kinder to myself";

  @override
  String get mindChallengeDescSelfEsteem =>
      "Seven days of small ways to be kinder to yourself.";

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
      "Day 4: Notice a comparison, then bring your attention back to your own needs.";

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
  String get mindChallengeTitleAnxietyCalm => "Making room for calm";

  @override
  String get mindChallengeDescAnxietyCalm =>
      "Seven days of short pauses to notice your worries and take a breath.";

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
      "Day 6: Name three things you know for sure right now.";

  @override
  String get mindChallengeDayAnxietyCalm7 =>
      'Day 7: Look back on how your anxiety changed this week.';

  @override
  String get mindChallengeTitleBurnoutRecovery => "Making time to rest";

  @override
  String get mindChallengeDescBurnoutRecovery =>
      "Seven days of finding small ways to rest when you feel worn out.";

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
      "Seven days of noticing small things you appreciate.";

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
  String get mindReportMoodTrendTitle => "Mood over time";

  @override
  String get mindReportMoodTrendNotEnoughData =>
      "There aren't enough entries to show a trend yet 🌱";

  @override
  String get moodTrendHeaderTitle => "Mood over time";

  @override
  String get moodTrendIntroText =>
      "This chart is based on the feelings you recorded. Higher points reflect brighter feelings in those entries; lower points reflect more difficult ones. It doesn't describe every moment of your day.";

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
  String get moodTrendLegendPositive => "Brighter feelings";

  @override
  String get moodTrendLegendNegative => "Difficult feelings";

  @override
  String get moodTrendDirectionNotEnoughData =>
      'There isn\'t quite enough data yet to tell a trend.';

  @override
  String get moodTrendDirectionImproving =>
      "Brighter feelings appear more often in your recent entries 🌤️";

  @override
  String get moodTrendDirectionSteady =>
      "Your recent entries show a fairly steady pattern 🤍";

  @override
  String get moodTrendDirectionDeclining =>
      "Your recent entries show more difficult feelings. Take your time looking back 🫂";

  @override
  String get homeCheerBannerTitle => "💌 Mongi's kind words";

  @override
  String get homeCheerBannerSubtitleBothDone =>
      "You've chosen and read today's kind words";

  @override
  String get homeCheerBannerSubtitleHasNew => "A few kind words for you today";

  @override
  String get homeCheerBannerSubtitleDefault => 'Share a little kindness';

  @override
  String get homeCheerBannerNewBadge => 'Open';

  @override
  String get cheerScreenAppBarTitle => "Mongi's kind words";

  @override
  String get cheerScreenHonestyNotice =>
      "This activity doesn't send messages to other people. These are prepared words of encouragement from Mongi 🐱";

  @override
  String get cheerSendSectionTitle => "Choose some kind words";

  @override
  String get cheerSendSectionSubtitle =>
      "Pick a message you'd like to leave with Mongi";

  @override
  String get cheerSendDoneTitle => "Today's kind words are saved";

  @override
  String get cheerSendDoneSubtitle => "You can choose another message tomorrow";

  @override
  String get cheerSendConfirmSnackbar => "Mongi has saved your kind words 💌";

  @override
  String get cheerReceiveSectionTitle => "A few words for you";

  @override
  String get cheerReceiveButtonLabel => "Read today's kind words";

  @override
  String get cheerReceiveCardLabel => "A note from Mongi";

  @override
  String cheerRewardEarned(int amount) {
    return '+$amount Light Essence';
  }

  @override
  String get cheerSendOption0 =>
      "Give yourself a little credit for today.";

  @override
  String get cheerSendOption1 => 'You\'re already enough, just as you are.';

  @override
  String get cheerSendOption2 => 'Your day, your feelings, they all matter.';

  @override
  String get cheerSendOption3 => 'It\'s okay to rest for a moment.';

  @override
  String get cheerSendOption4 => "Small steps count, even when they're hard to see.";

  @override
  String get cheerSendOption5 =>
      "You can put things down for a while. It's okay to rest.";

  @override
  String get cheerReceiveMessage0 => "Thanks for stopping by. Take a moment for yourself.";

  @override
  String get cheerReceiveMessage1 =>
      "I'm rooting for you today.";

  @override
  String get cheerReceiveMessage2 =>
      "The time and care you've put in still count.";

  @override
  String get cheerReceiveMessage3 => 'You are not alone.';

  @override
  String get cheerReceiveMessage4 =>
      'Small steps are still steps. You\'re doing fine.';

  @override
  String get cheerReceiveMessage5 =>
      'It\'s okay not to be perfect. That\'s just being human.';

  @override
  String get cheerReceiveMessage6 => "Here's a little cheer for you 👏";

  @override
  String get cheerReceiveMessage7 =>
      'On hard days, it\'s okay to pause for a while.';

  @override
  String get cheerReceiveMessage8 => "Your effort matters, even when it goes unnoticed.";

  @override
  String get cheerReceiveMessage9 =>
      'Be a little kinder to yourself today too.';

  @override
  String get cheerReceiveMessage10 => "You don't have to see progress every day.";

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
  String get cheerReceiveMessage15 => "Wishing you a little ease today.";

  @override
  String mindReflectionEmotionWeekdayLink(
    String emotion,
    String weekday,
    int count,
  ) {
    return "You recorded $emotion on ${weekday} more often than on other days: $count recent entries.";
  }

  @override
  String mindReflectionTriggerNegativeLink(String trigger, int count) {
    return '\'$trigger\' often shows up together with hard feelings - about $count times recently.';
  }

  @override
  String mindReflectionGrowthSignal(String emotion) {
    return "You recorded $emotion less often recently. Does that match how you've been feeling?";
  }

  @override
  String get mindReflectionGratitudeMoodLink =>
      "Your mood entries showed less variation on days when you also wrote a gratitude entry.";

  @override
  String mindReflectionConsistencySignal(int streak) {
    return "You've checked in for $streak days in a row. That's time you've made for yourself.";
  }

  @override
  String get mindReflectionDefaultObservation =>
      "There's no clear pattern yet. More entries may help show one over time.";

  @override
  String get settingsAiReflectionTitle => "🌿 Patterns in my entries";

  @override
  String get settingsAiReflectionDesc =>
      "Mongi looks for patterns across your entries. Everything is calculated on this device, and nothing is sent to a server. You can turn this off anytime.";

  @override
  String get mindReportReflectionTitle => "Patterns in your entries";

  @override
  String get mindReportReflectionOptInPrompt =>
      "Want to see patterns across your entries? You can turn this on in Settings.";

  @override
  String get mindReportReflectionOptInButton => 'Turn on in Settings';

  @override
  String get mindReportReflectionNotEnoughData =>
      'A few more records would help - try adding at least 5 diary entries.';

  @override
  String get publicGardenSettingsTitle => '🌍 Share Your Garden';

  @override
  String get publicGardenSettingsDesc =>
      'Let others see your garden (seeds, decorations, tree growth). Your diary and records are never shared. Visitors can only look - they can\'t rearrange or take anything from your garden.';

  @override
  String get publicGardenServerUnavailable =>
      'Server connection isn\'t ready yet, so your garden can\'t be shared right now.';

  @override
  String get publicGardenNicknameLabel => 'Garden nickname (optional)';

  @override
  String get publicGardenNicknameHint =>
      'Leave blank to show as \'An anonymous gardener\'';

  @override
  String get publicGardenPublishButton => 'Share my garden';

  @override
  String get publicGardenUnpublishButton => 'Stop sharing';

  @override
  String get publicGardenPublishedNotice => 'Your garden is currently shared.';

  @override
  String get publicGardenNotPublishedNotice =>
      'Your garden is private right now - only you can see it.';

  @override
  String get publicGardenBrowseTitle => 'Browse other gardens';

  @override
  String get publicGardenBrowseNotice =>
      'These are gardens others chose to share. You can only look - they\'re shown in random order, never ranked by popularity.';

  @override
  String get publicGardenBrowseEmpty =>
      'No gardens are shared yet. Please check back later.';

  @override
  String get publicGardenAnonymousNickname => 'An anonymous gardener';

  @override
  String get publicGardenCheerButton => "Send encouragement";

  @override
  String get publicGardenCheerAlreadySentToday => "Encouragement sent today";

  @override
  String get publicGardenCheerDialogTitle => 'What would you like to say?';

  @override
  String get publicGardenCheerSentSnackbar => 'Your message was sent 🌿';

  @override
  String get publicGardenInboxTitle => "Encouragement received";

  @override
  String get publicGardenInboxEmpty => "No encouragement received yet.";

  @override
  String get publicGardenInboxClaimButton => 'Claim';

  @override
  String publicGardenInboxGiftReceived(int amount) {
    return 'You received $amount Light Essence';
  }

  @override
  String get publicCheerOption0 => 'You\'re doing great 🌱';

  @override
  String get publicCheerOption1 => 'Your garden is lovely';

  @override
  String get publicCheerOption2 => 'It\'s okay to go slowly';

  @override
  String get publicCheerOption3 => 'I\'m rooting for you';

  @override
  String get publicCheerOption4 => "Sending a little kindness your way";

  @override
  String get publicCheerOption5 => "It's lovely to have you here";
}
