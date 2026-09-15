import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
  ];

  /// 앱 이름(브랜드명)
  ///
  /// In ko, this message translates to:
  /// **'몽이'**
  String get appTitle;

  /// 공통: 취소 버튼
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get commonCancel;

  /// 온보딩: 건너뛰기 버튼
  ///
  /// In ko, this message translates to:
  /// **'건너뛰기'**
  String get onboardingSkip;

  /// 온보딩 1페이지 제목
  ///
  /// In ko, this message translates to:
  /// **'안녕, 나는 몽이야 🐾'**
  String get onboardingPage1Title;

  /// 온보딩 1페이지 설명
  ///
  /// In ko, this message translates to:
  /// **'오늘 마음속에 남은 감정이 있다면\n나랑 같이 놀면서 흘려보내자!'**
  String get onboardingPage1Desc;

  /// 온보딩 2페이지 제목
  ///
  /// In ko, this message translates to:
  /// **'몽이는 저절로\n앞으로 달려가요'**
  String get onboardingPage2Title;

  /// 온보딩 2페이지 설명
  ///
  /// In ko, this message translates to:
  /// **'이동은 자동이에요!\n버튼 타이밍에만 집중해보세요!'**
  String get onboardingPage2Desc;

  /// 온보딩 3페이지 제목
  ///
  /// In ko, this message translates to:
  /// **'왼쪽 ✊ 주먹 버튼\n오른쪽 🦘 점프 버튼'**
  String get onboardingPage3Title;

  /// 온보딩 3페이지 설명
  ///
  /// In ko, this message translates to:
  /// **'작은 돌멩이는 타이밍 맞춰 주먹으로!\n큰 돌멩이는 꼭 점프 버튼으로 피해야 해요.'**
  String get onboardingPage3Desc;

  /// 온보딩 4페이지 제목
  ///
  /// In ko, this message translates to:
  /// **'감정 몬스터에게 닿으면\n몽이가 마음으로 마주해줘요'**
  String get onboardingPage4Title;

  /// 온보딩 4페이지 설명
  ///
  /// In ko, this message translates to:
  /// **'마주한 감정은 마음정원에\n예쁜 꽃으로 피어나요 🌷'**
  String get onboardingPage4Desc;

  /// 온보딩: 다음 버튼
  ///
  /// In ko, this message translates to:
  /// **'다음'**
  String get onboardingNext;

  /// 온보딩: 마지막 페이지의 시작 버튼
  ///
  /// In ko, this message translates to:
  /// **'몽이 만나러 가기 🐾'**
  String get onboardingFinish;

  /// 홈 화면 메인 헤드라인
  ///
  /// In ko, this message translates to:
  /// **'오늘 마음속에\n남아있는 감정이 있나요?'**
  String get homeHeadline;

  /// 홈 화면 조작법 안내 캡션
  ///
  /// In ko, this message translates to:
  /// **'왼쪽 ✊ 주먹 버튼 / 오른쪽 🦘 점프 버튼!\n감정 몬스터는 몽이가 알아서 마주해줘요!'**
  String get homeSubCaption;

  /// 하단 네비게이션: 홈
  ///
  /// In ko, this message translates to:
  /// **'홈'**
  String get navHome;

  /// 하단 네비게이션: 정원
  ///
  /// In ko, this message translates to:
  /// **'정원'**
  String get navGarden;

  /// 하단 네비게이션: 상점
  ///
  /// In ko, this message translates to:
  /// **'상점'**
  String get navShop;

  /// 하단 네비게이션: 편지
  ///
  /// In ko, this message translates to:
  /// **'편지'**
  String get navLetter;

  /// 하단 네비게이션: 미션
  ///
  /// In ko, this message translates to:
  /// **'미션'**
  String get navMission;

  /// 하단 네비게이션: 설정
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get navSettings;

  /// 홈 화면 우상단 도움말 버튼 툴팁
  ///
  /// In ko, this message translates to:
  /// **'사용법 다시보기'**
  String get homeHelpTooltip;

  /// 홈 화면 정원 뱃지 - 회복도 퍼센트
  ///
  /// In ko, this message translates to:
  /// **'마음정원 회복도 {percent}%'**
  String homeGardenBadgeProgress(int percent);

  /// 홈 화면 정원 뱃지 - 몽이 성장 단계
  ///
  /// In ko, this message translates to:
  /// **'🐾 몽이 {stage}단계'**
  String homeGardenBadgeStage(int stage);

  /// 홈 화면 정원 뱃지 - 연속 방문일
  ///
  /// In ko, this message translates to:
  /// **'🔥 {days}일째'**
  String homeGardenBadgeStreak(int days);

  /// 홈 화면 정원 뱃지 - 연속 감정 체크인일 (스트릭 가시성 강화: 체크인 팝업이 닫힌 뒤에도 계속 보이도록)
  ///
  /// In ko, this message translates to:
  /// **'✅ 체크인 {days}일째'**
  String homeGardenBadgeCheckInStreak(int days);

  /// 정신건강 지원 안내 카드 제목
  ///
  /// In ko, this message translates to:
  /// **'요즘 마음이 많이 무거웠나 봐요'**
  String get homeSupportAlertTitle;

  /// 정신건강 지원 안내 카드 본문
  ///
  /// In ko, this message translates to:
  /// **'혼자 견디지 않아도 괜찮아요. 언제든 이야기 나눌 곳이 있어요.'**
  String get homeSupportAlertBody;

  /// 복귀 케어 카드 제목 - 2~6일 만에 돌아왔을 때
  ///
  /// In ko, this message translates to:
  /// **'다시 만나서 반가워요!'**
  String get homeComebackCareTitleShort;

  /// 복귀 케어 카드 본문 - 2~6일 만에 돌아왔을 때
  ///
  /// In ko, this message translates to:
  /// **'{days}일 만이네요. 잠깐 쉬어가도 몽이는 늘 여기서 기다리고 있었어요 🌱'**
  String homeComebackCareBodyShort(int days);

  /// 복귀 케어 카드 제목 - 7일 이상 만에 돌아왔을 때
  ///
  /// In ko, this message translates to:
  /// **'오랜만이에요, 잘 지냈어요?'**
  String get homeComebackCareTitleLong;

  /// 복귀 케어 카드 본문 - 7일 이상 만에 돌아왔을 때
  ///
  /// In ko, this message translates to:
  /// **'{days}일 동안 못 봤네요. 그래도 괜찮아요 - 몽이는 그 사이에도 여기서 잘 지내고 있었어요. 오늘부터 다시 천천히 시작해봐요 💛'**
  String homeComebackCareBodyLong(int days);

  /// 홈 화면 화폐 바 - 빛의 정수 충전 버튼
  ///
  /// In ko, this message translates to:
  /// **'충전'**
  String get homeChargeButton;

  /// 홈 화면 화폐 바 - 마음 상자 칩
  ///
  /// In ko, this message translates to:
  /// **'마음 상자'**
  String get homeMindBoxChip;

  /// 홈 화면 화폐 바 - 파워 부적 보유 개수 칩
  ///
  /// In ko, this message translates to:
  /// **'파워 부적 {count}'**
  String homePowerCharmChip(int count);

  /// 홈 화면 화폐 바 - 몽이 돌봄 세트 칩
  ///
  /// In ko, this message translates to:
  /// **'몽이 돌봄'**
  String get homeMongiCareChip;

  /// 홈 화면 오늘의 목표 뱃지
  ///
  /// In ko, this message translates to:
  /// **'🎯 오늘의 목표: {hint}'**
  String homeTodayGoalBadge(String hint);

  /// 시즌 패스 배너 제목
  ///
  /// In ko, this message translates to:
  /// **'시즌 {season} · 몽이의 마음여정 · Lv.{level}'**
  String homeSeasonBannerTitle(int season, int level);

  /// 시즌 패스 배너 부제목
  ///
  /// In ko, this message translates to:
  /// **'눌러서 시즌 보상 확인하기'**
  String get homeSeasonBannerSubtitle;

  /// 공통: 보상 받기 뱃지
  ///
  /// In ko, this message translates to:
  /// **'받기!'**
  String get commonClaim;

  /// 일일 미션 배너 제목
  ///
  /// In ko, this message translates to:
  /// **'몽이의 오늘 미션'**
  String get homeDailyMissionTitle;

  /// 일일 미션 배너 부제목
  ///
  /// In ko, this message translates to:
  /// **'눌러서 오늘의 보상 확인하기'**
  String get homeDailyMissionSubtitle;

  /// 일일 미션 배너 - 수령 가능 개수 뱃지
  ///
  /// In ko, this message translates to:
  /// **'받기! {count}'**
  String homeDailyMissionClaimCount(int count);

  /// 마음 리포트 진입 버튼
  ///
  /// In ko, this message translates to:
  /// **'마음 리포트'**
  String get homeMindReportButton;

  /// 홈 화면 - 게임과 무관하게 언제든 직접 숨쉬기 연습을 시작하는 버튼
  ///
  /// In ko, this message translates to:
  /// **'숨쉬기'**
  String get homeBreathingButton;

  /// 이름/메모 입력 필드 힌트
  ///
  /// In ko, this message translates to:
  /// **'오늘 감정, 왜 생겼는지 몽이한테만 알려줄래? (선택)'**
  String get homeNameFieldHint;

  /// 사용법 카드 제목
  ///
  /// In ko, this message translates to:
  /// **'👇 이렇게 사용해요'**
  String get homeHowToTitle;

  /// 사용법 카드 1단계
  ///
  /// In ko, this message translates to:
  /// **'아래에서\n감정을 골라요\n(최대 3개)'**
  String get homeHowToStep1;

  /// 사용법 카드 2단계
  ///
  /// In ko, this message translates to:
  /// **'몽이와\n달리기 시작!'**
  String get homeHowToStep2;

  /// 사용법 카드 3단계
  ///
  /// In ko, this message translates to:
  /// **'몽이가 닿으면\n마음으로 마주해요'**
  String get homeHowToStep3;

  /// 사용법 카드 4단계
  ///
  /// In ko, this message translates to:
  /// **'정원에\n씨앗으로 남아요'**
  String get homeHowToStep4;

  /// 감정 최대 선택 개수 초과 시 스낵바 메시지
  ///
  /// In ko, this message translates to:
  /// **'최대 3개까지 선택할 수 있어요'**
  String get homeMaxSelectSnackbar;

  /// 홈 화면 - 게임 시작 전 감정 강도 슬라이더 라벨(1번 개선: 강도-난이도 매칭)
  ///
  /// In ko, this message translates to:
  /// **'이 마음, 지금 얼마나 강한가요?'**
  String get homeIntensityLabel;

  /// 감정 그리드 아래 다정한 한 줄 캡션
  ///
  /// In ko, this message translates to:
  /// **'오늘 어떤 마음이든, 몽이는 다 좋아요 🐾'**
  String get homeFriendlyCaption;

  /// 무한 도전 버튼 - 최고기록 있을 때
  ///
  /// In ko, this message translates to:
  /// **'♾️ 무한 도전! (최고기록 {count}개)'**
  String homeEndlessButtonRecord(int count);

  /// 무한 도전 버튼 - 최고기록 없을 때
  ///
  /// In ko, this message translates to:
  /// **'♾️ 무한 도전으로 오늘의 최고기록 세우기'**
  String get homeEndlessButtonNoRecord;

  /// 시작 버튼 - 감정을 선택했을 때
  ///
  /// In ko, this message translates to:
  /// **'몽이와 달리기 시작! 🐾 ({selected}/{max})'**
  String homeStartButtonEnabled(int selected, int max);

  /// 시작 버튼 - 아직 감정을 선택하지 않았을 때
  ///
  /// In ko, this message translates to:
  /// **'감정을 선택해주세요 (최대 {max}개)'**
  String homeStartButtonDisabled(int max);

  /// 3번 개선: 활동 모드(러너) 대신 저자극 고요 모드로 진입하는 버튼
  ///
  /// In ko, this message translates to:
  /// **'🌙 고요 모드로 마주하기'**
  String get homeQuietModeButton;

  /// 5번 개선: 웰니스 핵심기능과 게임 수익모델을 분리하기 위해, 구분선 아래 재화/상점 영역 시작을 알리는 소제목
  ///
  /// In ko, this message translates to:
  /// **'여기서부터는 재화·상점이에요'**
  String get homeMonetizationSectionLabel;

  /// 고요 모드 화면 상단 타이틀
  ///
  /// In ko, this message translates to:
  /// **'고요 모드'**
  String get quietModeAppBarTitle;

  /// 고요 모드 1단계(감정 보여주기) 제목
  ///
  /// In ko, this message translates to:
  /// **'오늘 이 마음을 그대로 마주해볼까요?'**
  String get quietModeGreetTitle;

  /// 고요 모드 1단계 보조 문구
  ///
  /// In ko, this message translates to:
  /// **'서두르지 않아도 괜찮아요. 몽이가 곁에 있어요.'**
  String get quietModeGreetSubtitle;

  /// 고요 모드 1단계 다음 버튼
  ///
  /// In ko, this message translates to:
  /// **'다음'**
  String get quietModeGreetNextButton;

  /// 고요 모드 2단계(호흡 제안) 제목
  ///
  /// In ko, this message translates to:
  /// **'잠깐, 숨을 골라볼까요?'**
  String get quietModeBreatheTitle;

  /// 고요 모드 2단계 호흡 시작 버튼
  ///
  /// In ko, this message translates to:
  /// **'시작하기'**
  String get quietModeBreatheStartButton;

  /// 고요 모드 2단계 호흡 건너뛰기 버튼
  ///
  /// In ko, this message translates to:
  /// **'건너뛰기'**
  String get quietModeBreatheSkipButton;

  /// 고요 모드 3단계(한 줄 기록) 제목
  ///
  /// In ko, this message translates to:
  /// **'한 줄로 남겨볼까요? (선택)'**
  String get quietModeReflectTitle;

  /// 고요 모드 3단계 텍스트필드 힌트
  ///
  /// In ko, this message translates to:
  /// **'지금 마음을 짧게 적어보세요'**
  String get quietModeReflectHint;

  /// 고요 모드 3단계에서 심기 단계로 넘어가는 버튼
  ///
  /// In ko, this message translates to:
  /// **'마음에 심기'**
  String get quietModePlantButton;

  /// 고요 모드 4단계(심기 애니메이션) 메시지
  ///
  /// In ko, this message translates to:
  /// **'마음이 정원에 조용히 스며들고 있어요...'**
  String get quietModePlantingMessage;

  /// 고요 모드 5단계(완료) 제목
  ///
  /// In ko, this message translates to:
  /// **'마음을 잘 심었어요'**
  String get quietModeDoneTitle;

  /// 고요 모드 5단계 완료 본문
  ///
  /// In ko, this message translates to:
  /// **'{count}개의 마음이 정원에 꽃으로 피어났어요. 언제든 다시 들여다볼 수 있어요.'**
  String quietModeDoneBody(int count);

  /// 고요 모드 5단계 홈으로 버튼
  ///
  /// In ko, this message translates to:
  /// **'홈으로'**
  String get quietModeDoneHomeButton;

  /// 고요 모드 5단계 정원 보기 버튼
  ///
  /// In ko, this message translates to:
  /// **'정원 보기'**
  String get quietModeDoneGardenButton;

  /// 상점 화면 상단 타이틀
  ///
  /// In ko, this message translates to:
  /// **'🛍️ 상점'**
  String get shopTitle;

  /// 상점 섹션 라벨 - 재화 충전
  ///
  /// In ko, this message translates to:
  /// **'💰 재화 충전'**
  String get shopSectionCurrency;

  /// 상점 카드 - 빛의 정수 충전 제목
  ///
  /// In ko, this message translates to:
  /// **'빛의 정수 충전'**
  String get shopLightEssenceTitle;

  /// 상점 카드 - 빛의 정수 충전 설명
  ///
  /// In ko, this message translates to:
  /// **'결제로 빛의 정수를 바로 채워요 (100개 ₩5,000 · 1,000개 ₩10,000)'**
  String get shopLightEssenceSubtitle;

  /// 상점 섹션 라벨 - 소모품 & 꾸미기
  ///
  /// In ko, this message translates to:
  /// **'🎁 소모품 & 꾸미기'**
  String get shopSectionConsumables;

  /// 상점 카드 - 마음 상자 제목
  ///
  /// In ko, this message translates to:
  /// **'마음 상자'**
  String get shopMindBoxTitle;

  /// 상점 카드 - 마음 상자 설명
  ///
  /// In ko, this message translates to:
  /// **'빛의 정수로 몽이 코스튬을 모아보세요 (확률 없이 순차 지급)'**
  String get shopMindBoxSubtitle;

  /// 상점 카드 - 파워 부적 제목
  ///
  /// In ko, this message translates to:
  /// **'파워 부적'**
  String get shopPowerCharmTitle;

  /// 상점 카드 - 파워 부적 설명
  ///
  /// In ko, this message translates to:
  /// **'게임 중 10초간 무적이 되는 소모템 (지금 보유 {count}개)'**
  String shopPowerCharmSubtitle(int count);

  /// 상점 카드 - 몽이 돌봄 세트 제목
  ///
  /// In ko, this message translates to:
  /// **'몽이 돌봄 세트'**
  String get shopMongiCareTitle;

  /// 상점 카드 - 몽이 돌봄 세트 설명
  ///
  /// In ko, this message translates to:
  /// **'참치캔·사료 같은 소모품부터 담요 같은 특별한 선물까지'**
  String get shopMongiCareSubtitle;

  /// 상점 카드 - 정원 꾸미기 제목
  ///
  /// In ko, this message translates to:
  /// **'정원 꾸미기'**
  String get shopGardenDecoTitle;

  /// 상점 카드 - 정원 꾸미기 설명
  ///
  /// In ko, this message translates to:
  /// **'벤치·분수대 등 무료 장식 + 프리미엄 장식팩'**
  String get shopGardenDecoSubtitle;

  /// 상점 섹션 라벨 - 시즌 & 멤버십
  ///
  /// In ko, this message translates to:
  /// **'🌟 시즌 & 멤버십'**
  String get shopSectionSeason;

  /// 상점 카드 - 시즌 패스 제목
  ///
  /// In ko, this message translates to:
  /// **'몽이의 마음여정 (시즌 패스)'**
  String get shopSeasonPassTitle;

  /// 상점 카드 - 시즌 패스 설명
  ///
  /// In ko, this message translates to:
  /// **'이번 시즌 한정 프리미엄 트랙으로 더 풍성한 보상을 받아요'**
  String get shopSeasonPassSubtitle;

  /// 설정 화면 헤더
  ///
  /// In ko, this message translates to:
  /// **'⚙️ 설정'**
  String get settingsHeader;

  /// 설정 - 알림 카드 제목
  ///
  /// In ko, this message translates to:
  /// **'매일 몽이 알림'**
  String get settingsNotifTitle;

  /// 설정 - 알림 권한 거부 시 스낵바
  ///
  /// In ko, this message translates to:
  /// **'알림 권한이 필요해요. 기기 설정에서 허용해주세요.'**
  String get settingsNotifPermissionDenied;

  /// 설정 - 알림 카드 설명
  ///
  /// In ko, this message translates to:
  /// **'매일 정해진 시각에 몽이가 오늘의 마음을 물어봐요.\n부담스럽지 않게 딱 한 번만 알려드려요.'**
  String get settingsNotifDesc;

  /// 설정 - 알림 시각 선택 라벨
  ///
  /// In ko, this message translates to:
  /// **'알림 시각'**
  String get settingsNotifTimeLabel;

  /// 설정 - 언어 카드 제목
  ///
  /// In ko, this message translates to:
  /// **'언어'**
  String get settingsLanguageTitle;

  /// 설정 - 언어 옵션: 시스템 기본값 사용
  ///
  /// In ko, this message translates to:
  /// **'시스템 기본'**
  String get settingsLanguageSystem;

  /// 설정 - 언어 옵션: 한국어
  ///
  /// In ko, this message translates to:
  /// **'한국어'**
  String get settingsLanguageKorean;

  /// 설정 - 언어 옵션: 영어
  ///
  /// In ko, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// 설정 - 데이터 보관 안내 카드 제목
  ///
  /// In ko, this message translates to:
  /// **'📱 데이터 보관 안내'**
  String get settingsDataNoticeTitle;

  /// 설정 - 데이터 보관 안내 카드 본문
  ///
  /// In ko, this message translates to:
  /// **'몽이는 로그인 없이 이 기기에만 정원·일기·진행도를 저장해요. 앱을 지우거나 기기를 바꾸면 이 기록은 함께 사라져요.\n구매한 아이템은 구글 계정으로 \"구매 복원\"이 가능하지만, 정원 자체는 복원되지 않으니 참고해주세요.'**
  String get settingsDataNoticeBody;

  /// 설정 - 정신건강 지원 카드 제목
  ///
  /// In ko, this message translates to:
  /// **'마음이 힘들 때'**
  String get settingsMentalHealthTitle;

  /// 설정 - 정신건강 지원 카드 부제목
  ///
  /// In ko, this message translates to:
  /// **'혼자 견디지 않아도 돼요 · 24시간 상담 안내 보기'**
  String get settingsMentalHealthSubtitle;

  /// 설정 - 개인정보처리방침 카드 제목
  ///
  /// In ko, this message translates to:
  /// **'개인정보처리방침'**
  String get settingsPrivacyPolicy;

  /// 설정 - 진행도 초기화 카드 제목
  ///
  /// In ko, this message translates to:
  /// **'처음부터 다시 시작'**
  String get settingsResetTitle;

  /// 설정 - 진행도 초기화 카드 설명
  ///
  /// In ko, this message translates to:
  /// **'지금까지의 스테이지, 재화, 코스튬, 정원 진행도를 모두 지우고\n1단계부터 새로 시작해요. 테스트나 처음 경험을 다시 보고 싶을 때 써요.'**
  String get settingsResetDesc;

  /// 설정 - 진행도 초기화 버튼
  ///
  /// In ko, this message translates to:
  /// **'진행도 초기화하고 1단계부터 시작'**
  String get settingsResetButton;

  /// 설정 - 초기화 확인 다이얼로그 제목
  ///
  /// In ko, this message translates to:
  /// **'정말 초기화할까요?'**
  String get settingsResetConfirmTitle;

  /// 설정 - 초기화 확인 다이얼로그 본문
  ///
  /// In ko, this message translates to:
  /// **'스테이지, 재화, 코스튬, 정원 진행도가 모두 사라지고\n1단계부터 다시 시작해요. 되돌릴 수 없어요.'**
  String get settingsResetConfirmBody;

  /// 설정 - 초기화 확인 다이얼로그의 확인 버튼
  ///
  /// In ko, this message translates to:
  /// **'초기화'**
  String get settingsResetConfirmButton;

  /// 설정 - 웹 플랫폼 알림 미지원 안내
  ///
  /// In ko, this message translates to:
  /// **'💡 알림 기능은 안드로이드 앱에서만 사용할 수 있어요.'**
  String get settingsWebNotice;

  /// 게임 화면 - 주먹 버튼 라벨
  ///
  /// In ko, this message translates to:
  /// **'주먹'**
  String get gamePunchLabel;

  /// 게임 화면 - 점프 버튼 라벨
  ///
  /// In ko, this message translates to:
  /// **'점프'**
  String get gameJumpLabel;

  /// 게임 화면 - 로드 실패 안내 문구
  ///
  /// In ko, this message translates to:
  /// **'스테이지를 불러오는 중 문제가 생겼어요.\n다시 시도해주세요.'**
  String get gameLoadErrorTitle;

  /// 게임 화면 - 로드 실패 시 돌아가기 버튼
  ///
  /// In ko, this message translates to:
  /// **'돌아가기'**
  String get gameLoadErrorButton;

  /// 게임 화면 - 자동 달리기 안내 힌트
  ///
  /// In ko, this message translates to:
  /// **'몽이가 저절로 앞으로 달려가요'**
  String get gameHintAutoRun;

  /// 게임 화면 - 제한 시간 안내 힌트
  ///
  /// In ko, this message translates to:
  /// **'⏰ {seconds}초 안에 목표를 채워봐요!'**
  String gameHintTimeLimit(int seconds);

  /// 게임 화면 - 1단계 조작법 힌트
  ///
  /// In ko, this message translates to:
  /// **'오른쪽 🦘 점프 버튼을 누르면 바로 점프해요!'**
  String get gameHintControlsStage1;

  /// 게임 화면 - 2단계 이상 조작법 힌트 (엔드리스 모드에서도 사용)
  ///
  /// In ko, this message translates to:
  /// **'왼쪽 ✊ 주먹 버튼 / 오른쪽 🦘 점프 버튼을 눌러요!'**
  String get gameHintControlsStage2Plus;

  /// 게임 화면 - 1단계 회피 힌트
  ///
  /// In ko, this message translates to:
  /// **'돌멩이는 점프로 피하고, 감정 몬스터는 그냥 지나가면 마주하게 돼요!'**
  String get gameHintDodgeStage1;

  /// 게임 화면 - 2단계 이상 회피 힌트
  ///
  /// In ko, this message translates to:
  /// **'작은 돌멩이는 타이밍 맞춰 주먹으로! 큰 돌멩이는 꼭 점프로 피해요'**
  String get gameHintDodgeStage2Plus;

  /// 게임 화면 HUD - 현재 스테이지 표시
  ///
  /// In ko, this message translates to:
  /// **'{stage}단계'**
  String gameHudStage(int stage);

  /// 게임 화면 - 새벽 시간대 분위기 라벨
  ///
  /// In ko, this message translates to:
  /// **'아침 정원'**
  String get gameTimeOfDayDawn;

  /// 게임 화면 - 밤 시간대 분위기 라벨
  ///
  /// In ko, this message translates to:
  /// **'밤 정원'**
  String get gameTimeOfDayNight;

  /// 게임 화면 - 시간대 분위기 배지 문구
  ///
  /// In ko, this message translates to:
  /// **'지금은 {label}이에요'**
  String gameTimeOfDayBadge(String label);

  /// 게임 화면 - 무적 모드 배지
  ///
  /// In ko, this message translates to:
  /// **'⚡ 무적 모드! {seconds}초'**
  String gamePowerModeBadge(int seconds);

  /// 게임 화면 - 남은 시간 배지
  ///
  /// In ko, this message translates to:
  /// **'⏰ {seconds}초'**
  String gameTimeBadge(int seconds);

  /// 게임 화면 - 콤보 배지
  ///
  /// In ko, this message translates to:
  /// **'🔥 콤보 x{combo}'**
  String gameComboBadge(int combo);

  /// 게임 화면 - 종료 확인 다이얼로그 제목
  ///
  /// In ko, this message translates to:
  /// **'게임을 종료할까요?'**
  String get gameExitConfirmTitle;

  /// 게임 화면 - 종료 확인 다이얼로그 본문
  ///
  /// In ko, this message translates to:
  /// **'지금까지의 진행은 저장되지 않고, 처음 화면으로 돌아가요.'**
  String get gameExitConfirmBody;

  /// 게임 화면 - 종료 확인 다이얼로그의 종료 버튼
  ///
  /// In ko, this message translates to:
  /// **'종료'**
  String get gameExitConfirmButton;

  /// 홈 화면(앱 뿌리 화면) - 시스템 뒤로가기 시 뜨는 앱 종료 확인 다이얼로그 제목
  ///
  /// In ko, this message translates to:
  /// **'몽이와의 시간을 마칠까요?'**
  String get appExitConfirmTitle;

  /// 홈 화면(앱 뿌리 화면) - 앱 종료 확인 다이얼로그 본문
  ///
  /// In ko, this message translates to:
  /// **'지금까지 기록한 마음은 그대로 저장돼 있어요. 다음에 또 만나요 🌱'**
  String get appExitConfirmBody;

  /// 홈 화면(앱 뿌리 화면) - 앱 종료 확인 다이얼로그의 종료 버튼
  ///
  /// In ko, this message translates to:
  /// **'종료'**
  String get appExitConfirmButton;

  /// 엔드리스 모드 - 시작 힌트 제목
  ///
  /// In ko, this message translates to:
  /// **'오늘 몽이의 최고 기록에 도전해요!'**
  String get endlessHintTitle;

  /// 엔드리스 모드 - 시작 힌트 목표 안내
  ///
  /// In ko, this message translates to:
  /// **'목숨이 다할 때까지 최대한 많이 모아보세요'**
  String get endlessHintGoal;

  /// 엔드리스 모드 HUD - 오늘의 최고 기록
  ///
  /// In ko, this message translates to:
  /// **'👑 최고 {count}'**
  String endlessHudBestRecord(int count);

  /// 몽이의 하루 - 아직 기록이 없을 때 표시되는 문구
  ///
  /// In ko, this message translates to:
  /// **'몽이가 오늘은 어떤 마음을 만나게 될지 기다리고 있어요.'**
  String get homeMongiMoodWaiting;

  /// 몽이의 하루 - 최근 기분이 좋을 때 표시되는 문구
  ///
  /// In ko, this message translates to:
  /// **'요즘 마음이 가벼웠나 봐요! 몽이가 신나서 폴짝폴짝 뛰어다녀요 🐾'**
  String get homeMongiMoodJoyful;

  /// 몽이의 하루 - 최근 기분이 무거울 때 표시되는 문구
  ///
  /// In ko, this message translates to:
  /// **'요 며칠 마음이 조금 무거웠나 봐요. 몽이가 옆에 웅크리고 있어요.'**
  String get homeMongiMoodHeavy;

  /// 몽이의 하루 - 평온할 때 표시되는 문구
  ///
  /// In ko, this message translates to:
  /// **'몽이가 평소처럼 편안하게 곁을 지키고 있어요.'**
  String get homeMongiMoodCalm;

  /// 몽이의 하루 - 이스터에그 대사 0
  ///
  /// In ko, this message translates to:
  /// **'오늘 몽이가 이상한 소리를 냈어요... \"그르릉냥냥?\" 🐱'**
  String get homeEasterEgg0;

  /// 몽이의 하루 - 이스터에그 대사 1
  ///
  /// In ko, this message translates to:
  /// **'몽이가 갑자기 벽을 보고 하이파이브를 했어요. 왜 그런지는 몽이만 알아요.'**
  String get homeEasterEgg1;

  /// 몽이의 하루 - 이스터에그 대사 2
  ///
  /// In ko, this message translates to:
  /// **'몽이가 자기 꼬리를 30초 동안 쫓아다녔어요. 결국 잡았대요.'**
  String get homeEasterEgg2;

  /// 몽이의 하루 - 이스터에그 대사 3
  ///
  /// In ko, this message translates to:
  /// **'몽이가 오늘따라 낮잠을 세 번이나 잤어요. 꿈에서 생선을 만났나 봐요.'**
  String get homeEasterEgg3;

  /// 몽이의 하루 - 이스터에그 대사 4
  ///
  /// In ko, this message translates to:
  /// **'몽이가 창밖을 보며 한참 생각에 잠겼어요. 무슨 생각을 했을까요?'**
  String get homeEasterEgg4;

  /// 몽이의 하루 - 이스터에그 대사 5
  ///
  /// In ko, this message translates to:
  /// **'몽이가 오늘 스스로에게 박수를 쳐줬어요. 이유는 비밀이래요.'**
  String get homeEasterEgg5;

  /// 몽이의 하루 - 이스터에그 대사 6
  ///
  /// In ko, this message translates to:
  /// **'몽이가 갑자기 \"야옹!\" 하고 크게 울었어요. 그냥 기분이 좋았대요.'**
  String get homeEasterEgg6;

  /// 몽이의 하루 - 이스터에그 대사 7
  ///
  /// In ko, this message translates to:
  /// **'몽이가 발바닥 젤리를 자랑스럽게 보여줬어요.'**
  String get homeEasterEgg7;

  /// 몽이의 하루 - 이스터에그 대사 8
  ///
  /// In ko, this message translates to:
  /// **'몽이가 오늘 할 일 목록에 \"귀여워지기\"를 적어놓고 완료 체크했어요.'**
  String get homeEasterEgg8;

  /// 몽이의 하루 - 이스터에그 대사 9
  ///
  /// In ko, this message translates to:
  /// **'몽이가 자기 그림자를 보고 놀라서 폴짝 뛰었어요. 지금은 괜찮대요.'**
  String get homeEasterEgg9;

  /// 몽이의 하루 - 이스터에그 대사 10
  ///
  /// In ko, this message translates to:
  /// **'몽이가 오늘 아침 거울을 보고 한참 인사를 나눴어요.'**
  String get homeEasterEgg10;

  /// 몽이의 하루 - 이스터에그 대사 11
  ///
  /// In ko, this message translates to:
  /// **'몽이가 이유 없이 방을 세 바퀴 돌고 다시 자리에 앉았어요.'**
  String get homeEasterEgg11;

  /// 정원 화면 - 씬 아래 안내 문구
  ///
  /// In ko, this message translates to:
  /// **'씨앗을 탭하면 얼마나 자랐는지 볼 수 있어요 · 우측 상단 \"꾸미기\"로 아이템을 놓아보세요'**
  String get gardenTapHint;

  /// 정원 화면 상단 타이틀
  ///
  /// In ko, this message translates to:
  /// **'🌷 내 마음정원'**
  String get gardenHeaderTitle;

  /// 정원 화면 상단 아이콘 - 감정 도감 툴팁
  ///
  /// In ko, this message translates to:
  /// **'감정 도감'**
  String get gardenTooltipCollection;

  /// 정원 화면 상단 아이콘 - 성장 다큐멘터리 툴팁
  ///
  /// In ko, this message translates to:
  /// **'성장 다큐멘터리'**
  String get gardenTooltipMilestone;

  /// 정원 화면 상단 아이콘 - 정원 공유하기 툴팁
  ///
  /// In ko, this message translates to:
  /// **'정원 공유하기'**
  String get gardenTooltipShare;

  /// 정원 화면 상단 아이콘 - 감정 캘린더 툴팁
  ///
  /// In ko, this message translates to:
  /// **'감정 캘린더'**
  String get gardenTooltipCalendar;

  /// 정원 화면 상단 아이콘 - 다이어리 툴팁
  ///
  /// In ko, this message translates to:
  /// **'다이어리'**
  String get gardenTooltipDiary;

  /// 정원 화면 - 요약 카드 상단 문구
  ///
  /// In ko, this message translates to:
  /// **'지금까지 {count}송이의 마음을 피워냈어요'**
  String gardenSummaryFlowersPlanted(int count);

  /// 정원 화면 - 요약 통계 라벨(회복도)
  ///
  /// In ko, this message translates to:
  /// **'회복도'**
  String get gardenStatRecoveryLabel;

  /// 정원 화면 - 요약 통계 라벨(몽이 단계)
  ///
  /// In ko, this message translates to:
  /// **'몽이'**
  String get gardenStatMongiLabel;

  /// 정원 화면 - 요약 통계 라벨(연속 일수)
  ///
  /// In ko, this message translates to:
  /// **'연속'**
  String get gardenStatStreakLabel;

  /// 정원 화면 - 요약 통계 라벨(점수)
  ///
  /// In ko, this message translates to:
  /// **'점수'**
  String get gardenStatScoreLabel;

  /// 정원 화면 - 회복도 퍼센트 값
  ///
  /// In ko, this message translates to:
  /// **'{percent}%'**
  String gardenStatPercentValue(int percent);

  /// 정원 화면 - 몽이 단계 값
  ///
  /// In ko, this message translates to:
  /// **'{stage}단계'**
  String gardenStatStageValue(int stage);

  /// 정원 화면 - 연속 일수 값
  ///
  /// In ko, this message translates to:
  /// **'{days}일'**
  String gardenStatStreakValue(int days);

  /// 정원 화면 - 점수 값
  ///
  /// In ko, this message translates to:
  /// **'{score}점'**
  String gardenStatScoreValue(int score);

  /// 정원 화면 - 성장나무가 시들었을 때 안내 문구
  ///
  /// In ko, this message translates to:
  /// **'몽이의 성장나무가 조금 심심해 보여요 · 오늘 찾아오면 금방 다시 생기를 되찾아요 🌤️'**
  String get gardenTreeWiltedHint;

  /// 정원 화면 - 성장나무가 최고 단계에 도달했을 때 안내 문구
  ///
  /// In ko, this message translates to:
  /// **'몽이의 성장나무가 {label}로 활짝 자랐어요!'**
  String gardenTreeMaxStageHint(String label);

  /// 정원 화면 - 성장나무 진행 상황 안내 문구
  ///
  /// In ko, this message translates to:
  /// **'지금 몽이의 성장나무: {label} · 다음 성장까지 {remaining}점'**
  String gardenTreeGrowthHint(String label, int remaining);

  /// 정원 화면 - 심어진 꽃이 없을 때 안내 제목
  ///
  /// In ko, this message translates to:
  /// **'아직 심어진 꽃이 없어요'**
  String get gardenEmptyTitle;

  /// 정원 화면 - 심어진 꽃이 없을 때 안내 본문
  ///
  /// In ko, this message translates to:
  /// **'마음속 감정을 하나씩 마주하고 나면\n이 자리에 꽃이 피어날 거예요'**
  String get gardenEmptyBody;

  /// 정원 화면 - 꽃밭 카드 제목
  ///
  /// In ko, this message translates to:
  /// **'{emotionLabel}의 정원'**
  String gardenFlowerBedTitle(String emotionLabel);

  /// 성장나무 단계 이름 - 씨앗(아직 자라기 전)
  ///
  /// In ko, this message translates to:
  /// **'씨앗'**
  String get gardenTreeStageSeed;

  /// 성장나무 단계 이름 - 새싹
  ///
  /// In ko, this message translates to:
  /// **'새싹'**
  String get gardenTreeStageSprout;

  /// 성장나무 단계 이름 - 나무
  ///
  /// In ko, this message translates to:
  /// **'나무'**
  String get gardenTreeStageTree;

  /// 성장나무 단계 이름 - 꽃
  ///
  /// In ko, this message translates to:
  /// **'꽃'**
  String get gardenTreeStageFlower;

  /// 성장나무 단계 이름 - 열매
  ///
  /// In ko, this message translates to:
  /// **'열매'**
  String get gardenTreeStageFruit;

  /// 정원 씬 - 좌측 상단 타이틀 뱃지
  ///
  /// In ko, this message translates to:
  /// **'🌿 내 정원'**
  String get gardenSceneTitle;

  /// 정원 씬 - 몽이 돌봄 버튼
  ///
  /// In ko, this message translates to:
  /// **'돌봄'**
  String get gardenSceneCareButton;

  /// 정원 씬 - 꾸미기 버튼
  ///
  /// In ko, this message translates to:
  /// **'꾸미기'**
  String get gardenSceneDecorateButton;

  /// 정원 씬 - 씨앗 화분 탭 시 스낵바(물을 준 적 있을 때)
  ///
  /// In ko, this message translates to:
  /// **'{seedLabel} · 지금까지 {count}번 물을 줬어요'**
  String gardenSeedPotWatered(String seedLabel, int count);

  /// 정원 씬 - 씨앗 화분 탭 시 스낵바(아직 심지 않았을 때)
  ///
  /// In ko, this message translates to:
  /// **'{seedLabel} 씨앗은 아직 심지 않았어요'**
  String gardenSeedPotNotPlanted(String seedLabel);

  /// 정원 씬 - 성장나무 탭 시 스낵바(시들었을 때)
  ///
  /// In ko, this message translates to:
  /// **'몽이의 성장나무가 조금 심심해 보여요 · 오늘 다시 찾아오면 금방 생기를 되찾아요 🌤️'**
  String get gardenTreeWiltedSnackbar;

  /// 정원 씬 - 성장나무 탭 시 스낵바(정상)
  ///
  /// In ko, this message translates to:
  /// **'몽이의 성장나무 · 지금은 {label} 단계예요'**
  String gardenTreeStageSnackbar(String label);

  /// 정원 계절 이름 - 봄
  ///
  /// In ko, this message translates to:
  /// **'봄'**
  String get gardenSeasonSpring;

  /// 정원 계절 이름 - 여름
  ///
  /// In ko, this message translates to:
  /// **'여름'**
  String get gardenSeasonSummer;

  /// 정원 계절 이름 - 가을
  ///
  /// In ko, this message translates to:
  /// **'가을'**
  String get gardenSeasonAutumn;

  /// 정원 계절 이름 - 겨울
  ///
  /// In ko, this message translates to:
  /// **'겨울'**
  String get gardenSeasonWinter;

  /// 정원 계절 인사말 - 봄
  ///
  /// In ko, this message translates to:
  /// **'몽이의 정원에 벚꽃이 흩날리고 있어요'**
  String get gardenSeasonGreetingSpring;

  /// 정원 계절 인사말 - 여름
  ///
  /// In ko, this message translates to:
  /// **'몽이의 정원이 싱그러운 여름빛으로 반짝여요'**
  String get gardenSeasonGreetingSummer;

  /// 정원 계절 인사말 - 가을
  ///
  /// In ko, this message translates to:
  /// **'몽이의 정원에 낙엽이 살랑살랑 내려요'**
  String get gardenSeasonGreetingAutumn;

  /// 정원 계절 인사말 - 겨울
  ///
  /// In ko, this message translates to:
  /// **'몽이의 정원에 눈이 소복하게 쌓이고 있어요'**
  String get gardenSeasonGreetingWinter;

  /// 선택 화면 - 스테이지 클리어 안내 문구
  ///
  /// In ko, this message translates to:
  /// **'{currentStage}단계를 완주했어요!\n다음 단계({nextStage}단계)로 넘어가볼까요?'**
  String choiceStageClearBody(int currentStage, int nextStage);

  /// 선택 화면 - 스테이지 클리어 힌트 문구
  ///
  /// In ko, this message translates to:
  /// **'다음 단계는 돌멩이가 조금 더 크고 빨라지지만,\n몽이도 그만큼 더 씩씩해져 있을 거예요 🌟'**
  String get choiceStageClearHint;

  /// 선택 화면 - 스테이지 클리어 '머물기' 버튼
  ///
  /// In ko, this message translates to:
  /// **'여기 머물게요'**
  String get choiceStageClearStayButton;

  /// 선택 화면 - 스테이지 클리어 '다음 단계로' 버튼
  ///
  /// In ko, this message translates to:
  /// **'다음 단계로! 🚀'**
  String get choiceStageClearAdvanceButton;

  /// 선택 화면 - 대상 이름 + 감정 라벨 조합
  ///
  /// In ko, this message translates to:
  /// **'{targetName}에 대한 {emotionsLabel}'**
  String choiceAskingTargetLabel(String targetName, String emotionsLabel);

  /// 선택 화면 - 먹은 개수가 있을 때 헤드라인
  ///
  /// In ko, this message translates to:
  /// **'오늘 {nameLabel}\n{count}개를 몽이가 마주했어요!'**
  String choiceAskingHeadlineWithCount(String nameLabel, int count);

  /// 선택 화면 - 먹은 개수가 없을 때 헤드라인
  ///
  /// In ko, this message translates to:
  /// **'오늘 {nameLabel}를\n마음속에서 잠시 마주했어요'**
  String choiceAskingHeadlineNoCount(String nameLabel);

  /// 선택 화면 - 마음 심기 제안 문구
  ///
  /// In ko, this message translates to:
  /// **'이제 그 자리에\n마음을 심어볼까요?'**
  String get choiceAskingPrompt;

  /// 선택 화면 - '아직은 아니에요' 버튼
  ///
  /// In ko, this message translates to:
  /// **'아직은 아니에요'**
  String get choiceAskingNotYetButton;

  /// 선택 화면 - '네, 심을래요' 버튼
  ///
  /// In ko, this message translates to:
  /// **'네, 심을래요'**
  String get choiceAskingPlantButton;

  /// 선택 화면 - 조기 종료 후크(남은 목표가 있을 때)
  ///
  /// In ko, this message translates to:
  /// **'오늘은 {count}개의 마음을 만났어요.\n아직 {remaining}개가 도망쳤어요, 다음에 마저 잡아줄래요? 🤍'**
  String choiceEarlyStopWithRemaining(int count, int remaining);

  /// 선택 화면 - 조기 종료 후크(목표 없음/이미 채움)
  ///
  /// In ko, this message translates to:
  /// **'오늘은 {count}개의 마음을 만났어요.\n그만큼도 충분해요, 다음에 또 와줄래요? 🤍'**
  String choiceEarlyStopNoRemaining(int count);

  /// 선택 화면 - 콤보 서사(5 미만)
  ///
  /// In ko, this message translates to:
  /// **'흔들릴 뻔한 순간에도 {count}번이나 씩씩하게 버텼어요'**
  String choiceComboLow(int count);

  /// 선택 화면 - 콤보 서사(5~9)
  ///
  /// In ko, this message translates to:
  /// **'{count}번 연속으로 흔들리지 않고 마음을 지켜냈어요!'**
  String choiceComboMid(int count);

  /// 선택 화면 - 콤보 서사(10 이상)
  ///
  /// In ko, this message translates to:
  /// **'{count}번이나 연속으로 버텨냈어요! 몽이가 오늘 유난히 단단해요 💪'**
  String choiceComboHigh(int count);

  /// 선택 화면 - 세션 인사이트(이번 주 자주 만난 긍정 감정)
  ///
  /// In ko, this message translates to:
  /// **'이 마음, 이번 주에만 벌써 {count}번째예요.\n요즘 자주 찾아오는 좋은 마음이네요 ☺️'**
  String choiceInsightFrequentPositive(int count);

  /// 선택 화면 - 세션 인사이트(이번 주 자주 만난 부정 감정)
  ///
  /// In ko, this message translates to:
  /// **'이 마음, 이번 주에만 벌써 {count}번째예요.\n요즘 자주 찾아오는 마음인가 봐요. 몽이가 계속 지켜보고 있을게요.'**
  String choiceInsightFrequentNegative(int count);

  /// 선택 화면 - 세션 인사이트(오늘 전부 긍정 감정)
  ///
  /// In ko, this message translates to:
  /// **'오늘은 마음에 좋은 기운만 가득했네요.\n그런 하루도 몽이에게 소중한 선물이에요 ✨'**
  String get choiceInsightAllPositive;

  /// 선택 화면 - 세션 인사이트(오랜만에 재회)
  ///
  /// In ko, this message translates to:
  /// **'오랜만이에요! {emotionLabel}은(는)\n{days}일 만에 다시 만났어요. 그동안 잘 지냈나요?'**
  String choiceInsightLongAbsence(String emotionLabel, int days);

  /// 선택 화면 - 세션 인사이트(첫 만남)
  ///
  /// In ko, this message translates to:
  /// **'{emotionLabel}을(를) 처음 일기에 남겼어요.\n용기 내 보여줘서 고마워요. 몽이가 오래오래 기억해둘게요.'**
  String choiceInsightFirstEncounter(String emotionLabel);

  /// 선택 화면 - 다음 목표 힌트(도감 거의 완성)
  ///
  /// In ko, this message translates to:
  /// **'이제 {count}가지 마음만 더 만나면 도감이 완성돼요!\n다음엔 어떤 마음일까요? 🔍'**
  String choiceNextGoalAlmostCollected(int count);

  /// 선택 화면 - 다음 목표 힌트(나무 성장 임박)
  ///
  /// In ko, this message translates to:
  /// **'몽이의 나무가 다음 단계까지 {points}점 남았어요.\n조금만 더 함께해줄래요? 🌳'**
  String choiceNextGoalTreeAlmost(int points);

  /// 선택 화면 - 다음 목표 힌트(미수집 다수)
  ///
  /// In ko, this message translates to:
  /// **'아직 만나지 못한 마음이 {count}가지 있어요.\n다음엔 어떤 마음을 만나게 될까요?'**
  String choiceNextGoalManyUncollected(int count);

  /// 선택 화면 - 씨앗 선택 제목
  ///
  /// In ko, this message translates to:
  /// **'어떤 마음을 심어볼까요?'**
  String get choiceSeedSelectTitle;

  /// 선택 화면 - 씨앗 선택 부제목
  ///
  /// In ko, this message translates to:
  /// **'하나를 고르면 몽이의 작은 정원에\n그 마음이 자라나요'**
  String get choiceSeedSelectSubtitle;

  /// 선택 화면 - 씨앗에 물을 준 횟수
  ///
  /// In ko, this message translates to:
  /// **'지금까지 {count}번 물을 줬어요'**
  String choiceSeedWateredCount(int count);

  /// 선택 화면 - 뒤로 버튼
  ///
  /// In ko, this message translates to:
  /// **'뒤로'**
  String get choiceBackButton;

  /// 선택 화면 - 씨앗 심기 애니메이션 제목
  ///
  /// In ko, this message translates to:
  /// **'{seedLabel}의 씨앗에\n물을 주고 있어요'**
  String choicePlantingTitle(String seedLabel);

  /// 선택 화면 - 씨앗 심기 애니메이션 부제목
  ///
  /// In ko, this message translates to:
  /// **'몽이의 정원에 {seedLabel}이(가) 자라나고 있어요 🌱'**
  String choicePlantingSubtitle(String seedLabel);

  /// 선택 화면 - 나무 성장 제목
  ///
  /// In ko, this message translates to:
  /// **'몽이의 성장나무가\n{label}로 자라났어요!'**
  String choiceTreeGrowthTitle(String label);

  /// 선택 화면 - 나무 성장 힌트
  ///
  /// In ko, this message translates to:
  /// **'꾸준히 마음을 마주할수록\n나무가 더 크게 자라나요 🌱'**
  String get choiceTreeGrowthHint;

  /// 선택 화면 - 나무 성장 보너스 문구
  ///
  /// In ko, this message translates to:
  /// **'나무가 자란 특별 선물, 빛의 정수 +{bonus}'**
  String choiceTreeGrowthBonus(int bonus);

  /// 선택 화면 - 나무 성장 공유 버튼
  ///
  /// In ko, this message translates to:
  /// **'이 순간 자랑하기'**
  String get choiceTreeGrowthShareButton;

  /// 선택 화면 - 결과 제목(정원이 활짝 핌)
  ///
  /// In ko, this message translates to:
  /// **'정원이 활짝 피었어요! 🌸'**
  String get choiceResultTitleBloomed;

  /// 선택 화면 - 결과 제목(특정 씨앗을 심음)
  ///
  /// In ko, this message translates to:
  /// **'{seedLabel}의 씨앗이 마음에 심어졌어요'**
  String choiceResultTitleSeedPlanted(String seedLabel);

  /// 선택 화면 - 결과 제목(마음을 심음, 씨앗 정보 없음)
  ///
  /// In ko, this message translates to:
  /// **'마음이 심어졌어요'**
  String get choiceResultTitlePlanted;

  /// 선택 화면 - 결과 제목(심지 않았을 때)
  ///
  /// In ko, this message translates to:
  /// **'괜찮아요, 천천히 해도 돼요'**
  String get choiceResultTitleGentle;

  /// 선택 화면 - 결과 메시지(마음을 심었을 때)
  ///
  /// In ko, this message translates to:
  /// **'어두웠던 자리에\n따뜻한 빛이 스며들었어요 ✨'**
  String get choiceResultMessageLove;

  /// 선택 화면 - 결과 메시지(심지 않았을 때)
  ///
  /// In ko, this message translates to:
  /// **'오늘 마주한 감정만큼\n마음은 이미 조금 가벼워졌어요\n준비되면 다시 올게요 🤍'**
  String get choiceResultMessageNoLove;

  /// 선택 화면 - 결과 메시지 추가(2단계로 첫 상승)
  ///
  /// In ko, this message translates to:
  /// **'\n\n몽이가 이제 손을 뻗어 작은 돌멩이를 부술 수 있게 됐어요! 💪'**
  String get choiceResultLevelUpStage2;

  /// 선택 화면 - 결과 메시지 추가(3단계 이상 상승)
  ///
  /// In ko, this message translates to:
  /// **'\n\n몽이가 {stage}단계로 성장했어요! 돌멩이는 조금 더 커졌지만 몽이는 더 씩씩해졌답니다 🌟'**
  String choiceResultLevelUpOther(int stage);

  /// 선택 화면 - 획득한 빛의 정수 칩
  ///
  /// In ko, this message translates to:
  /// **'💡 +{earned} (보유 {total})'**
  String choiceResultLightEarned(int earned, int total);

  /// 선택 화면 - 황금 프레임 획득 제목
  ///
  /// In ko, this message translates to:
  /// **'\"{emotionLabel}\" 황금 프레임 획득!'**
  String choiceResultGoldenFrameTitle(String emotionLabel);

  /// 선택 화면 - 황금 프레임 획득 설명
  ///
  /// In ko, this message translates to:
  /// **'극히 낮은 확률로만 얻을 수 있는 희귀 표식이에요.\n감정 도감에서 자랑해보세요!'**
  String get choiceResultGoldenFrameDesc;

  /// 선택 화면 - 씨앗 정원 성장 문구
  ///
  /// In ko, this message translates to:
  /// **'{seedLabel} 정원이 조금 더 자랐어요'**
  String choiceResultSeedGrown(String seedLabel);

  /// 선택 화면 - 정원 보러가기 버튼
  ///
  /// In ko, this message translates to:
  /// **'내 마음정원 보러가기'**
  String get choiceResultGardenButton;

  /// 선택 화면 - 메모 입력 라벨
  ///
  /// In ko, this message translates to:
  /// **'오늘 이 감정, 한 문장으로 남겨볼까요? (선택)'**
  String get choiceResultNoteLabel;

  /// 선택 화면 - 메모 입력 힌트
  ///
  /// In ko, this message translates to:
  /// **'예: 오늘은 조금 마음이 편해졌어요'**
  String get choiceResultNoteHint;

  /// 선택 화면 - 감정 카드 공유 버튼
  ///
  /// In ko, this message translates to:
  /// **'감정 카드 공유하기'**
  String get choiceResultShareButton;

  /// 선택 화면 - 처음으로(홈) 버튼
  ///
  /// In ko, this message translates to:
  /// **'처음으로'**
  String get choiceResultHomeButton;

  /// 선택 화면 - 감정 강도 슬라이더 라벨
  ///
  /// In ko, this message translates to:
  /// **'이 감정, 오늘은 얼마나 강하게 느꼈나요?'**
  String get choiceIntensityLabel;

  /// 선택 화면 - 감정 강도(아주 약하게)
  ///
  /// In ko, this message translates to:
  /// **'아주 약하게'**
  String get choiceIntensityVeryWeak;

  /// 선택 화면 - 감정 강도(약하게)
  ///
  /// In ko, this message translates to:
  /// **'약하게'**
  String get choiceIntensityWeak;

  /// 선택 화면 - 감정 강도(보통)
  ///
  /// In ko, this message translates to:
  /// **'보통'**
  String get choiceIntensityNormal;

  /// 선택 화면 - 감정 강도(강하게)
  ///
  /// In ko, this message translates to:
  /// **'강하게'**
  String get choiceIntensityStrong;

  /// 선택 화면 - 감정 강도(아주 강하게)
  ///
  /// In ko, this message translates to:
  /// **'아주 강하게'**
  String get choiceIntensityVeryStrong;

  /// 선택 화면 - 트리거 태그 라벨
  ///
  /// In ko, this message translates to:
  /// **'무엇 때문이었을까요? (선택, 여러 개 가능)'**
  String get choiceTriggerLabel;

  /// 선택 화면 - 초월 카드 배지
  ///
  /// In ko, this message translates to:
  /// **'숨겨진 순간을 발견했어요'**
  String get choiceTranscendenceBadge;

  /// 선택 화면 - 초월 카드 제목
  ///
  /// In ko, this message translates to:
  /// **'\"{emotionLabel}\"이(가) 초월했어요'**
  String choiceTranscendenceTitle(String emotionLabel);

  /// 선택 화면 - 초월 카드 설명
  ///
  /// In ko, this message translates to:
  /// **'백 번을 마주할 만큼 함께해준 마음이에요.\n아무도 예고해주지 않았지만, 당신은 해냈어요.'**
  String get choiceTranscendenceDesc;

  /// 선택 화면 - 시즌 마일스톤 카드 배지
  ///
  /// In ko, this message translates to:
  /// **'마음여정의 마일스톤'**
  String get choiceSeasonMilestoneBadge;

  /// 시즌 패스 마음 마일스톤 격려 문구(5레벨)
  ///
  /// In ko, this message translates to:
  /// **'벌써 5레벨! 매일 조금씩 마음을 돌보고 있다는 증거예요 🌱'**
  String get seasonMilestoneLevel5;

  /// 시즌 패스 마음 마일스톤 격려 문구(10레벨)
  ///
  /// In ko, this message translates to:
  /// **'절반을 지났어요. 그동안 쌓아온 하루하루가 정말 소중해요 🌿'**
  String get seasonMilestoneLevel10;

  /// 시즌 패스 마음 마일스톤 격려 문구(15레벨)
  ///
  /// In ko, this message translates to:
  /// **'15레벨, 이제 얼마 남지 않았어요. 꾸준함이 참 대단해요 🌳'**
  String get seasonMilestoneLevel15;

  /// 시즌 패스 마음 마일스톤 격려 문구(20레벨)
  ///
  /// In ko, this message translates to:
  /// **'이번 시즌의 마음여정을 완주했어요! 몽이가 가장 자랑스러워하는 순간이에요 🌟'**
  String get seasonMilestoneLevel20;

  /// 개인정보처리방침 화면 - 헤더 제목
  ///
  /// In ko, this message translates to:
  /// **'🔒 개인정보처리방침'**
  String get privacyHeaderTitle;

  /// 개인정보처리방침 화면 - 인트로 카드
  ///
  /// In ko, this message translates to:
  /// **'몽이는 로그인이 없는 앱이에요. 이 방침은 몽이가 어떤 정보를 다루고, 어떻게 지키는지 쉬운 말로 알려드려요.'**
  String get privacyIntro;

  /// 개인정보처리방침 화면 - 1번 섹션 제목
  ///
  /// In ko, this message translates to:
  /// **'1. 로그인/회원가입이 없어요'**
  String get privacySection1Title;

  /// 개인정보처리방침 화면 - 1번 섹션 본문
  ///
  /// In ko, this message translates to:
  /// **'몽이는 로그인이나 회원가입 절차가 전혀 없는 앱이에요. 이름, 이메일, 전화번호 같은 계정 정보를 요구하거나 수집하지 않아요. 감정 입력 화면에서 별명을 적더라도, 이 정보는 오직 이 기기 안에만 저장돼요.'**
  String get privacySection1Body;

  /// 개인정보처리방침 화면 - 2번 섹션 제목
  ///
  /// In ko, this message translates to:
  /// **'2. 데이터는 이 기기에만 저장돼요'**
  String get privacySection2Title;

  /// 개인정보처리방침 화면 - 2번 섹션 본문
  ///
  /// In ko, this message translates to:
  /// **'감정 일기, 정원 성장 상태, 스테이지 진행도, 보유 코스튬 등 몽이와 함께한 모든 기록은 서버로 전송되지 않고 오직 이 기기의 로컬 저장소(Hive)에만 보관돼요. 저희(개발자)도 이 내용을 볼 수 없어요.\n\n⚠️ 다만 이 때문에 앱을 지우거나 기기를 바꾸면 그동안 쌓은 정원/일기/진행도가 함께 사라져요(구매한 아이템은 구글 계정에 연동되어 \"구매 복원\"으로 되찾을 수 있지만, 정원 자체는 복원되지 않아요). 소중한 기록이라면 가끔 화면을 캡처해 보관하는 걸 추천해요.'**
  String get privacySection2Body;

  /// 개인정보처리방침 화면 - 3번 섹션 제목
  ///
  /// In ko, this message translates to:
  /// **'3. 광고 서비스(Google AdMob)'**
  String get privacySection3Title;

  /// 개인정보처리방침 화면 - 3번 섹션 본문
  ///
  /// In ko, this message translates to:
  /// **'무료로 더 많은 기능을 제공하기 위해 Google AdMob 광고를 보여드려요. 광고를 표시하고 맞춤 광고를 제공하는 과정에서 Google이 광고 식별자(Advertising ID), 기기 정보, IP 주소 등을 자체 정책에 따라 수집·처리할 수 있어요. 이는 저희가 아니라 Google이 처리하는 정보이며, 자세한 내용은 Google의 개인정보처리방침에서 확인할 수 있어요.\n\n기기 설정에서 \"광고 개인 최적화 선택 해제\"를 켜면 맞춤 광고 없이도 앱을 이용할 수 있어요.'**
  String get privacySection3Body;

  /// 개인정보처리방침 화면 - 4번 섹션 제목
  ///
  /// In ko, this message translates to:
  /// **'4. 인앱 결제(Google Play 결제)'**
  String get privacySection4Title;

  /// 개인정보처리방침 화면 - 4번 섹션 본문
  ///
  /// In ko, this message translates to:
  /// **'코스메틱 아이템(카드 프레임, 정원 장식, 코스튬 등) 구매는 Google Play 결제 시스템을 통해 처리돼요. 결제 정보(카드 번호 등)는 저희에게 전달되지 않고 Google이 직접 처리해요. 저희는 \"어떤 상품을 구매했는지\"만 확인해 해당 아이템을 지급하는 데 사용해요.'**
  String get privacySection4Body;

  /// 개인정보처리방침 화면 - 5번 섹션 제목
  ///
  /// In ko, this message translates to:
  /// **'5. 알림 권한'**
  String get privacySection5Title;

  /// 개인정보처리방침 화면 - 5번 섹션 본문
  ///
  /// In ko, this message translates to:
  /// **'매일 정해진 시각에 알림을 보내드리기 위해 알림 권한을 요청할 수 있어요. 이 권한은 오직 로컬 알림 발송에만 쓰이고, 언제든 설정 화면이나 기기 설정에서 꺼둘 수 있어요.'**
  String get privacySection5Body;

  /// 개인정보처리방침 화면 - 6번 섹션 제목
  ///
  /// In ko, this message translates to:
  /// **'6. 만 14세 미만 이용'**
  String get privacySection6Title;

  /// 개인정보처리방침 화면 - 6번 섹션 본문
  ///
  /// In ko, this message translates to:
  /// **'몽이는 계정 기반 수집이 없는 앱이지만, 만 14세 미만 아동은 보호자의 지도 아래 이용하는 것을 권장해요. 결제 기능이 포함되어 있으니 보호자께서 인앱 결제 관련 기기 설정(구매 시 비밀번호 확인 등)을 확인해주세요.'**
  String get privacySection6Body;

  /// 개인정보처리방침 화면 - 7번 섹션 제목
  ///
  /// In ko, this message translates to:
  /// **'7. 문의'**
  String get privacySection7Title;

  /// 개인정보처리방침 화면 - 7번 섹션 본문
  ///
  /// In ko, this message translates to:
  /// **'개인정보 처리와 관련해 궁금한 점이 있다면 아래 이메일로 언제든 문의해주세요.\n\n{email}'**
  String privacySection7Body(String email);

  /// 개인정보처리방침 화면 - 8번 섹션 제목
  ///
  /// In ko, this message translates to:
  /// **'8. 방침 변경'**
  String get privacySection8Title;

  /// 개인정보처리방침 화면 - 8번 섹션 본문
  ///
  /// In ko, this message translates to:
  /// **'이 개인정보처리방침은 법령이나 서비스 변경에 따라 수정될 수 있어요. 중요한 변경이 있을 경우 앱 내 공지를 통해 알려드릴게요.'**
  String get privacySection8Body;

  /// 개인정보처리방침 화면 - 광고 동의 옵션 카드 제목
  ///
  /// In ko, this message translates to:
  /// **'🍪 광고 개인정보 선택'**
  String get privacyAdConsentTitle;

  /// 개인정보처리방침 화면 - 광고 동의 옵션 카드 설명
  ///
  /// In ko, this message translates to:
  /// **'유럽경제지역(EEA)·영국 등 일부 지역에서는 맞춤 광고에 대한 동의 여부를 언제든지 다시 선택할 수 있어요.'**
  String get privacyAdConsentBody;

  /// 개인정보처리방침 화면 - 광고 동의 옵션 열기 버튼
  ///
  /// In ko, this message translates to:
  /// **'광고 개인정보 선택 관리'**
  String get privacyAdConsentButton;

  /// 개인정보처리방침 화면 - 광고 동의 옵션을 열 수 없을 때 스낵바
  ///
  /// In ko, this message translates to:
  /// **'지금은 광고 개인정보 선택을 변경할 수 없어요. 잠시 후 다시 시도해주세요.'**
  String get privacyAdConsentNotAvailable;

  /// 개인정보처리방침 화면 - 이용약관 화면으로 이동하는 버튼
  ///
  /// In ko, this message translates to:
  /// **'이용약관 보기'**
  String get privacyTermsOfServiceButton;

  /// 개인정보처리방침 화면 - 마지막 개정일 값(고정된 날짜)
  ///
  /// In ko, this message translates to:
  /// **'2026년 8월 25일'**
  String get privacyLastUpdatedDate;

  /// 개인정보처리방침 화면 - 마지막 개정일 라벨
  ///
  /// In ko, this message translates to:
  /// **'마지막 개정일: {date}'**
  String privacyLastUpdatedLabel(String date);

  /// 마음이 힘들 때 화면 - 헤더 제목
  ///
  /// In ko, this message translates to:
  /// **'🤍 마음이 힘들 때'**
  String get mentalHealthHeaderTitle;

  /// No description provided for @mentalHealthCallFailedSnackbar.
  ///
  /// In ko, this message translates to:
  /// **'전화 연결에 실패했어요. 직접 {number}로 걸어주세요.'**
  String mentalHealthCallFailedSnackbar(String number);

  /// 마음이 힘들 때 화면 - 문자/링크 연결 실패 안내(전화 실패와 별도)
  ///
  /// In ko, this message translates to:
  /// **'연결에 실패했어요. 직접 {action}로 시도해주세요.'**
  String mentalHealthActionFailedSnackbar(String action);

  /// 마음이 힘들 때/안전 계획 화면 - URL을 여는 액션 버튼 라벨(전화 대신 링크 열기)
  ///
  /// In ko, this message translates to:
  /// **'열기'**
  String get mentalHealthOpenButtonLabel;

  /// 마음이 힘들 때 화면 - 문자(SMS) 상담 연결 실패 안내
  ///
  /// In ko, this message translates to:
  /// **'문자 앱 연결에 실패했어요. 직접 {number}로 문자를 보내주세요.'**
  String mentalHealthSmsFailedSnackbar(String number);

  /// 마음이 힘들 때 화면 - 전화 대신 문자(SMS)를 보내는 액션 버튼 라벨(예: 미국 741741 Crisis Text Line)
  ///
  /// In ko, this message translates to:
  /// **'문자 보내기'**
  String get mentalHealthSendSmsButtonLabel;

  /// 마음이 힘들 때 화면 - 인트로 카드 본문1
  ///
  /// In ko, this message translates to:
  /// **'몽이는 마음을 가볍게 마주하고 기록하는 걸 도와주는 친구예요.\n그런데 만약 지금 견디기 힘들 만큼 마음이 무겁다면,\n몽이보다 훨씬 든든한 전문 상담 선생님과 이야기해보는 게 좋아요.'**
  String get mentalHealthIntroBody1;

  /// 마음이 힘들 때 화면 - 인트로 카드 본문2
  ///
  /// In ko, this message translates to:
  /// **'전화하는 게 망설여져도 괜찮아요. 아래 번호들은 24시간, 익명으로,\n완전히 무료로 이야기를 들어주는 곳이에요. 혼자 견디지 않아도 돼요.'**
  String get mentalHealthIntroBody2;

  /// 마음이 힘들 때 화면 - 상담전화 섹션 제목
  ///
  /// In ko, this message translates to:
  /// **'📞 언제든 연결할 수 있는 곳'**
  String get mentalHealthCallSectionTitle;

  /// 마음이 힘들 때 화면 - 헬프라인1 이름
  ///
  /// In ko, this message translates to:
  /// **'자살예방상담전화'**
  String get mentalHealthHelpline1Name;

  /// 마음이 힘들 때 화면 - 헬프라인1 설명
  ///
  /// In ko, this message translates to:
  /// **'24시간 · 전국 어디서나 국번 없이 109\n자살을 생각하고 있거나, 힘들어하는 주변 사람이 걱정될 때'**
  String get mentalHealthHelpline1Desc;

  /// 마음이 힘들 때 화면 - 헬프라인2 이름
  ///
  /// In ko, this message translates to:
  /// **'정신건강 위기상담전화'**
  String get mentalHealthHelpline2Name;

  /// 마음이 힘들 때 화면 - 헬프라인2 설명
  ///
  /// In ko, this message translates to:
  /// **'24시간 · 우울, 불안 등 마음이 힘든 모든 순간'**
  String get mentalHealthHelpline2Desc;

  /// 마음이 힘들 때 화면 - 헬프라인3 이름
  ///
  /// In ko, this message translates to:
  /// **'청소년전화 1388'**
  String get mentalHealthHelpline3Name;

  /// 마음이 힘들 때 화면 - 헬프라인3 설명
  ///
  /// In ko, this message translates to:
  /// **'24시간 · 청소년 고민 상담(학업, 관계, 가정 등 전반)'**
  String get mentalHealthHelpline3Desc;

  /// 마음이 힘들 때 화면 - 헬프라인4 이름
  ///
  /// In ko, this message translates to:
  /// **'긴급 신고'**
  String get mentalHealthHelpline4Name;

  /// 마음이 힘들 때 화면 - 헬프라인4 설명
  ///
  /// In ko, this message translates to:
  /// **'지금 당장 나 또는 다른 사람의 생명이 위험한 상황이라면'**
  String get mentalHealthHelpline4Desc;

  /// 마음이 힘들 때 화면 - 비한국어(영어) 로케일 전용 안내문(한국 번호가 아닌 글로벌 자원을 안내함을 설명)
  ///
  /// In ko, this message translates to:
  /// **'한국 이외 지역에서는 아래 국가별 상담 채널을 이용해주세요. 전세계 130개국 이상의\n상담 전화를 찾을 수 있는 글로벌 디렉토리부터 안내해요.'**
  String get mentalHealthGlobalIntroNote;

  /// 마음이 힘들 때 화면 - 글로벌 헬프라인1(전세계 디렉토리) 이름
  ///
  /// In ko, this message translates to:
  /// **'Find A Helpline'**
  String get mentalHealthGlobalHelpline1Name;

  /// 마음이 힘들 때 화면 - 글로벌 헬프라인1 설명
  ///
  /// In ko, this message translates to:
  /// **'130개국 이상의 상담 전화를 찾아주는 글로벌 디렉토리\n내가 있는 국가를 선택하면 그 나라의 상담 채널로 연결돼요'**
  String get mentalHealthGlobalHelpline1Desc;

  /// 마음이 힘들 때 화면 - 글로벌 헬프라인2(미국 988) 이름
  ///
  /// In ko, this message translates to:
  /// **'988 Suicide & Crisis Lifeline (US)'**
  String get mentalHealthGlobalHelpline2Name;

  /// 마음이 힘들 때 화면 - 글로벌 헬프라인2 설명
  ///
  /// In ko, this message translates to:
  /// **'24시간 · 미국 전화/문자 988\n미국에 있다면 이 번호로 바로 연결할 수 있어요'**
  String get mentalHealthGlobalHelpline2Desc;

  /// 마음이 힘들 때 화면 - 글로벌 헬프라인3(미국 문자상담) 이름
  ///
  /// In ko, this message translates to:
  /// **'Crisis Text Line (US)'**
  String get mentalHealthGlobalHelpline3Name;

  /// 마음이 힘들 때 화면 - 글로벌 헬프라인3 설명
  ///
  /// In ko, this message translates to:
  /// **'24시간 · 미국 문자 741741로 HOME 전송\n전화가 어렵다면 문자로도 상담받을 수 있어요'**
  String get mentalHealthGlobalHelpline3Desc;

  /// 마음이 힘들 때 화면 - 글로벌 헬프라인4(미국 SAMHSA) 이름
  ///
  /// In ko, this message translates to:
  /// **'SAMHSA National Helpline (US)'**
  String get mentalHealthGlobalHelpline4Name;

  /// 마음이 힘들 때 화면 - 글로벌 헬프라인4 설명
  ///
  /// In ko, this message translates to:
  /// **'24시간 · 미국 전화 1-800-662-4357\n약물·정신건강 관련 상담 및 지역 자원 연결'**
  String get mentalHealthGlobalHelpline4Desc;

  /// 마음이 힘들 때 화면 - 비한국어(영어) 로케일 전용 하단 안내문
  ///
  /// In ko, this message translates to:
  /// **'※ 위 번호 중 988/741741/SAMHSA는 미국 기준 예시이며, 다른 국가에서는 연결되지\n않을 수 있어요. 미국 외 지역이라면 Find A Helpline에서 내 국가를 선택해 현지\n상담 채널을 확인해주세요.'**
  String get mentalHealthGlobalFooterNote;

  /// 마음이 힘들 때 화면 - 주변 상담센터 카드 제목
  ///
  /// In ko, this message translates to:
  /// **'내 주변 상담센터 찾기'**
  String get mentalHealthNearbyCounselingTitle;

  /// 마음이 힘들 때 화면 - 주변 상담센터 카드 부제목
  ///
  /// In ko, this message translates to:
  /// **'전화가 망설여진다면, 가까운 곳에 직접 찾아가봐요'**
  String get mentalHealthNearbyCounselingSubtitle;

  /// 마음이 힘들 때 화면 - 안전 계획 카드 제목
  ///
  /// In ko, this message translates to:
  /// **'나만의 안전 계획 만들어두기'**
  String get mentalHealthSafetyPlanTitle;

  /// 마음이 힘들 때 화면 - 안전 계획 카드 부제목
  ///
  /// In ko, this message translates to:
  /// **'마음이 편안할 때 미리 준비해두면 힘이 돼요'**
  String get mentalHealthSafetyPlanSubtitle;

  /// 마음이 힘들 때 화면 - 도움 신호 카드 제목
  ///
  /// In ko, this message translates to:
  /// **'💡 이럴 때는 꼭 도움을 요청해주세요'**
  String get mentalHealthSignsTitle;

  /// 마음이 힘들 때 화면 - 도움 신호1
  ///
  /// In ko, this message translates to:
  /// **'무기력하거나 슬픈 마음이 2주 이상 계속될 때'**
  String get mentalHealthSign1;

  /// 마음이 힘들 때 화면 - 도움 신호2
  ///
  /// In ko, this message translates to:
  /// **'\"사라지고 싶다\", \"끝내고 싶다\"는 생각이 자꾸 들 때'**
  String get mentalHealthSign2;

  /// 마음이 힘들 때 화면 - 도움 신호3
  ///
  /// In ko, this message translates to:
  /// **'주변 사람이 평소와 다르게 위축되거나 힘들어 보일 때'**
  String get mentalHealthSign3;

  /// 마음이 힘들 때 화면 - 도움 신호4
  ///
  /// In ko, this message translates to:
  /// **'누군가에게 이야기하고 싶은데 어떻게 말해야 할지 모를 때'**
  String get mentalHealthSign4;

  /// 마음이 힘들 때 화면 - 도움 신호 카드 하단 문구
  ///
  /// In ko, this message translates to:
  /// **'이 중 하나라도 해당한다면, 그건 당신이 약해서가 아니라\n지금 조금 더 많은 도움이 필요한 순간일 뿐이에요.'**
  String get mentalHealthSignsFooter;

  /// 마음이 힘들 때 화면 - 하단 안내 문구
  ///
  /// In ko, this message translates to:
  /// **'※ 안내된 번호는 대한민국 보건복지부가 운영하는 공식 상담 채널이며,\n몽이 앱과 직접적인 연계 없이 독립적으로 운영됩니다. 번호가 변경될 수 있으니\n연결이 되지 않으면 포털에서 \"자살예방상담전화\"를 검색해 최신 번호를 확인해주세요.'**
  String get mentalHealthFooterNote;

  /// 감정 공유 시트 - 기본 프레임 라벨
  ///
  /// In ko, this message translates to:
  /// **'기본'**
  String get shareFrameLabelDefault;

  /// 감정 공유 시트 - 벚꽃 프레임 라벨
  ///
  /// In ko, this message translates to:
  /// **'벚꽃'**
  String get shareFrameLabelCherry;

  /// 감정 공유 시트 - 골드 별빛 프레임 라벨
  ///
  /// In ko, this message translates to:
  /// **'골드 별빛'**
  String get shareFrameLabelGold;

  /// 감정 공유 시트 - 대상이 있을 때 이름 라벨
  ///
  /// In ko, this message translates to:
  /// **'{targetName}에 대한 {emotionLabel}'**
  String shareNameLabelWithTarget(String targetName, String emotionLabel);

  /// 감정 공유 시트 - 카드 렌더링 실패 오류
  ///
  /// In ko, this message translates to:
  /// **'카드를 찾을 수 없어요.'**
  String get shareCardNotFoundError;

  /// 감정 공유 시트 - 이미지 변환 실패 오류
  ///
  /// In ko, this message translates to:
  /// **'이미지 변환에 실패했어요.'**
  String get shareImageConvertError;

  /// 감정 공유 시트 - 공유 텍스트 본문
  ///
  /// In ko, this message translates to:
  /// **'오늘 마음속 {nameLabel}, 몽이와 함께 {count}개 마주했어요 🐱🌿 #몽이 #감정일기'**
  String shareTextBody(String nameLabel, int count);

  /// 감정 공유 시트 - 공유 실패 스낵바
  ///
  /// In ko, this message translates to:
  /// **'공유 중 문제가 생겼어요. 잠시 후 다시 시도해주세요.'**
  String get shareErrorSnackbar;

  /// 감정 공유 시트 - 프리미엄 프레임 구매 다이얼로그 제목
  ///
  /// In ko, this message translates to:
  /// **'프리미엄 카드 프레임 팩 🔓'**
  String get sharePremiumDialogTitle;

  /// 감정 공유 시트 - 프리미엄 프레임 구매 다이얼로그 본문
  ///
  /// In ko, this message translates to:
  /// **'벚꽃 · 골드 별빛 프레임을 영구적으로 사용할 수 있어요.\n한 번만 구매하면 다시 결제할 필요가 없어요.'**
  String get sharePremiumDialogBody;

  /// 감정 공유 시트 - 프리미엄 프레임 구매 다이얼로그 나중에 버튼
  ///
  /// In ko, this message translates to:
  /// **'다음에'**
  String get sharePremiumDialogLater;

  /// 감정 공유 시트 - 프리미엄 프레임 구매 다이얼로그 구매 버튼
  ///
  /// In ko, this message translates to:
  /// **'구매하기'**
  String get sharePremiumDialogBuy;

  /// 감정 공유 시트 - 결제 처리 중 스낵바
  ///
  /// In ko, this message translates to:
  /// **'결제를 처리하고 있어요...'**
  String get sharePurchaseProcessingSnackbar;

  /// PurchaseService - 웹에서는 인앱 결제를 테스트할 수 없다는 안내
  ///
  /// In ko, this message translates to:
  /// **'웹 프리뷰에서는 인앱 결제를 테스트할 수 없어요. 안드로이드 앱에서 이용해주세요.'**
  String get purchaseMessageWebNotSupported;

  /// PurchaseService - 웹에서는 구매 복원을 지원하지 않는다는 안내
  ///
  /// In ko, this message translates to:
  /// **'웹 프리뷰에서는 구매 복원을 지원하지 않아요.'**
  String get purchaseMessageWebRestoreNotSupported;

  /// PurchaseService - 결제 서비스 초기화 실패 안내
  ///
  /// In ko, this message translates to:
  /// **'지금은 결제를 이용할 수 없어요. 잠시 후 다시 시도해주세요.'**
  String get purchaseMessageServiceUnavailable;

  /// PurchaseService - 스토어에서 상품 정보를 불러오지 못했다는 안내
  ///
  /// In ko, this message translates to:
  /// **'상품 정보를 불러올 수 없어요. 스토어 등록 상태를 확인해주세요.'**
  String get purchaseMessageProductNotFound;

  /// PurchaseService - 구매 요청 자체가 실패했다는 안내
  ///
  /// In ko, this message translates to:
  /// **'구매 요청 중 문제가 발생했어요.'**
  String get purchaseMessageRequestFailed;

  /// PurchaseService - 스토어에서 전달된 구매 오류 일반 안내
  ///
  /// In ko, this message translates to:
  /// **'구매 중 문제가 발생했어요.'**
  String get purchaseMessageStoreError;

  /// NotificationService - 매일 리마인더 알림의 제목
  ///
  /// In ko, this message translates to:
  /// **'몽이 🐱'**
  String get notificationTitle;

  /// NotificationService - Android 알림 채널 이름
  ///
  /// In ko, this message translates to:
  /// **'오늘의 마음 리마인더'**
  String get notificationChannelName;

  /// NotificationService - Android 알림 채널 설명
  ///
  /// In ko, this message translates to:
  /// **'매일 정해진 시각에 몽이가 마음을 나누자고 알려줘요.'**
  String get notificationChannelDescription;

  /// NotificationService - 랜덤으로 고르는 리마인더 문구 1
  ///
  /// In ko, this message translates to:
  /// **'몽이가 오늘 하루는 어땠는지 궁금해하고 있어요 🐾'**
  String get notificationReminderMessage1;

  /// NotificationService - 랜덤으로 고르는 리마인더 문구 2
  ///
  /// In ko, this message translates to:
  /// **'마음속에 쌓인 감정이 있다면, 몽이에게 나눠주세요 🐱'**
  String get notificationReminderMessage2;

  /// NotificationService - 랜덤으로 고르는 리마인더 문구 3
  ///
  /// In ko, this message translates to:
  /// **'오늘도 몽이와 함께 마음정원을 가꿔볼까요? 🌱'**
  String get notificationReminderMessage3;

  /// NotificationService - 랜덤으로 고르는 리마인더 문구 4
  ///
  /// In ko, this message translates to:
  /// **'잠깐, 오늘의 감정을 몽이에게 들려주지 않을래요? 🌸'**
  String get notificationReminderMessage4;

  /// NotificationService - 랜덤으로 고르는 리마인더 문구 5
  ///
  /// In ko, this message translates to:
  /// **'몽이가 작은 정원에서 당신을 기다리고 있어요 🌷'**
  String get notificationReminderMessage5;

  /// 감정 공유 시트 - 시트 제목
  ///
  /// In ko, this message translates to:
  /// **'오늘의 감정 카드'**
  String get shareTitle;

  /// 감정 공유 시트 - 시트 부제목
  ///
  /// In ko, this message translates to:
  /// **'친구에게 오늘의 마음을 나눠보세요'**
  String get shareSubtitle;

  /// 감정 공유 시트 - 결제 확인 중 버튼 라벨
  ///
  /// In ko, this message translates to:
  /// **'결제 확인 중...'**
  String get sharePurchaseConfirming;

  /// 감정 공유 시트 - 프리미엄 프레임 구매 버튼
  ///
  /// In ko, this message translates to:
  /// **'프리미엄 프레임 구매하기'**
  String get sharePurchasePremiumButton;

  /// 감정 공유 시트 - 카드 생성 중 버튼 라벨
  ///
  /// In ko, this message translates to:
  /// **'카드 만드는 중...'**
  String get shareCreatingCard;

  /// 감정 공유 시트 - 카드 공유 버튼
  ///
  /// In ko, this message translates to:
  /// **'카드 공유하기'**
  String get shareCardButton;

  /// 감정 공유 시트 - 구매 복원 버튼
  ///
  /// In ko, this message translates to:
  /// **'이미 구매하셨나요? 구매 복원하기'**
  String get shareRestorePurchaseButton;

  /// 감정 공유 시트 - 카드 브랜드명(몽이)
  ///
  /// In ko, this message translates to:
  /// **'몽이'**
  String get shareCardBrand;

  /// 감정 공유 시트 - 카드 헤드라인(개수 있음)
  ///
  /// In ko, this message translates to:
  /// **'오늘 {nameLabel}\n{count}개를 몽이와 함께 마주했어요'**
  String shareCardHeadlineWithCount(String nameLabel, int count);

  /// 감정 공유 시트 - 카드 헤드라인(개수 없음)
  ///
  /// In ko, this message translates to:
  /// **'오늘 {nameLabel}를\n마음속에서 잠시 마주했어요'**
  String shareCardHeadlineNoCount(String nameLabel);

  /// 감정 공유 시트 - 카드 콤보 배지
  ///
  /// In ko, this message translates to:
  /// **'🔥 최고 콤보 x{count}'**
  String shareCardComboBadge(int count);

  /// 감정 공유 시트 - 사랑을 선택하지 않았을 때 카드 메시지
  ///
  /// In ko, this message translates to:
  /// **'오늘 마주한 감정만큼\n마음은 이미 조금 가벼워졌어요 🤍'**
  String get shareCardNoLoveMessage;

  /// 감정 공유 시트 - 잠금(미리보기) 배지
  ///
  /// In ko, this message translates to:
  /// **'미리보기'**
  String get shareCardPreviewBadge;

  /// 이어하기 제안 시트 - 무료 이어하기 사용 횟수 라벨
  ///
  /// In ko, this message translates to:
  /// **'무료 이어하기 ({count}/{total})'**
  String reviveFreeOfferCountLabel(int count, String total);

  /// 이어하기 제안 시트 - 공통 헤드라인 (무료/광고 제안 모두)
  ///
  /// In ko, this message translates to:
  /// **'아직 끝내기 아쉬워요!'**
  String get reviveOfferHeadline;

  /// 이어하기 제안 시트 - 무료 이어하기 설명 문구
  ///
  /// In ko, this message translates to:
  /// **'지금 이 판을 목숨을 가득 채워\n그대로 이어갈 수 있어요'**
  String get reviveFreeOfferBody;

  /// 이어하기 제안 시트 - 무료 이어하기 버튼
  ///
  /// In ko, this message translates to:
  /// **'이어하기 💪'**
  String get reviveContinueButton;

  /// 이어하기 제안 시트 - 거절(종료) 버튼
  ///
  /// In ko, this message translates to:
  /// **'여기서 마칠게요'**
  String get reviveDeclineButton;

  /// 이어하기 제안 시트 - 광고 제안, 이미 한 번 이상 부활한 경우 상단 문구
  ///
  /// In ko, this message translates to:
  /// **'몽이가 한 번 더 부탁해요'**
  String get reviveAdOfferSubtitleSecondTime;

  /// 이어하기 제안 시트 - 광고 제안, 처음 부활하는 경우 상단 문구
  ///
  /// In ko, this message translates to:
  /// **'몽이에게 두 번째 기회를 선물하기'**
  String get reviveAdOfferSubtitleFirstTime;

  /// 이어하기 제안 시트 - 광고/화폐 선택 설명 문구
  ///
  /// In ko, this message translates to:
  /// **'광고를 보거나, 생명의 물을 마시면\n목숨을 가득 채워 그대로 이어갈 수 있어요'**
  String get reviveAdOfferBody;

  /// 이어하기 제안 시트 - 빛의 정수로 즉시 부활 버튼
  ///
  /// In ko, this message translates to:
  /// **'생명의 물로 바로 이어하기 (빛의 정수 {cost})'**
  String reviveBuyWithLightEssenceButton(int cost);

  /// 이어하기 제안 시트 - 빛의 정수 부족 안내 문구
  ///
  /// In ko, this message translates to:
  /// **'빛의 정수가 모자라요 (보유 {lightEssence} / 필요 {cost}) · 아래에서 광고를 봐도 돼요'**
  String reviveInsufficientFunds(int lightEssence, int cost);

  /// 이어하기 제안 시트 - 광고 시청 버튼
  ///
  /// In ko, this message translates to:
  /// **'광고 보고 이어하기 🎬'**
  String get reviveWatchAdButton;

  /// 이어하기 제안 시트 - 광고 시청 중 안내 제목
  ///
  /// In ko, this message translates to:
  /// **'광고를 보는 중이에요...'**
  String get reviveWatchingAdTitle;

  /// 이어하기 제안 시트 - 광고 시청 중 안내 부제목
  ///
  /// In ko, this message translates to:
  /// **'잠시만 기다려주세요'**
  String get reviveWatchingAdSubtitle;

  /// 요일 - 일요일 (짧은 표기)
  ///
  /// In ko, this message translates to:
  /// **'일'**
  String get weekdaySun;

  /// 요일 - 월요일 (짧은 표기)
  ///
  /// In ko, this message translates to:
  /// **'월'**
  String get weekdayMon;

  /// 요일 - 화요일 (짧은 표기)
  ///
  /// In ko, this message translates to:
  /// **'화'**
  String get weekdayTue;

  /// 요일 - 수요일 (짧은 표기)
  ///
  /// In ko, this message translates to:
  /// **'수'**
  String get weekdayWed;

  /// 요일 - 목요일 (짧은 표기)
  ///
  /// In ko, this message translates to:
  /// **'목'**
  String get weekdayThu;

  /// 요일 - 금요일 (짧은 표기)
  ///
  /// In ko, this message translates to:
  /// **'금'**
  String get weekdayFri;

  /// 요일 - 토요일 (짧은 표기)
  ///
  /// In ko, this message translates to:
  /// **'토'**
  String get weekdaySat;

  /// 감정 캘린더/마음 리포트 - 요일별 관찰, 데이터 부족
  ///
  /// In ko, this message translates to:
  /// **'기록이 조금 더 쌓이면 요일별 마음 흐름도 보여드릴게요 🌱'**
  String get weekdayObservationNotEnoughData;

  /// 감정 캘린더/마음 리포트 - 요일별 관찰, 뚜렷한 패턴이 있을 때
  ///
  /// In ko, this message translates to:
  /// **'{bestDay}요일엔 마음이 유독 편안했고,\n{toughestDay}요일엔 조금 더 힘들었을 수 있어요. 그런 요일엔 스스로에게 조금 더 다정해도 괜찮아요 🤍'**
  String weekdayObservationHasPattern(String bestDay, String toughestDay);

  /// 감정 캘린더/마음 리포트 - 요일별 관찰, 뚜렷한 패턴은 없을 때
  ///
  /// In ko, this message translates to:
  /// **'요일마다 마음은 조금씩 다르게 흘러가요.\n어떤 요일이든, 몽이는 늘 같은 마음으로 곁에 있어요 🤍'**
  String get weekdayObservationNoClearPattern;

  /// 마음 리포트/주간 리포트 - 주간 관찰, 이번 주 기록 없음
  ///
  /// In ko, this message translates to:
  /// **'이번 주는 아직 기록이 없어요.\n괜찮아요, 준비되면 작은 마음이라도 들려주세요 🌱'**
  String get weeklyObservationNoData;

  /// 마음 리포트/주간 리포트 - 주간 관찰, 긍정 비율이 지난주보다 늘었을 때
  ///
  /// In ko, this message translates to:
  /// **'지난주보다 밝은 마음이 {deltaPercent}%p 늘었어요.\n스스로도 느껴지는 변화였다면, 그건 온전히 당신이 만든 거예요 ✨'**
  String weeklyObservationImprovedFromLastWeek(int deltaPercent);

  /// 마음 리포트/주간 리포트 - 주간 관찰, 긍정 비율이 지난주보다 줄었을 때
  ///
  /// In ko, this message translates to:
  /// **'지난주보다 마음이 조금 더 힘든 한 주였을 수 있어요.\n애쓰지 않아도 괜찮아요, 몽이는 계속 곁에 있을게요 🤍'**
  String get weeklyObservationDeclinedFromLastWeek;

  /// 마음 리포트/주간 리포트 - 주간 관찰, 특정 긍정 감정이 압도적으로 많을 때
  ///
  /// In ko, this message translates to:
  /// **'이번 주는 유독 \"{emotion}\"이(가) 가득했던 한 주였네요.\n그 좋은 기운, 몽이도 함께 느꼈어요 😊'**
  String weeklyObservationDominantPositive(String emotion);

  /// 마음 리포트/주간 리포트 - 주간 관찰, 특정 부정 감정이 압도적으로 많을 때
  ///
  /// In ko, this message translates to:
  /// **'이번 주는 유독 \"{emotion}\"이(가) 컸던 한 주였네요.\n무슨 일이 있었는지 몽이는 궁금해요. 천천히 얘기해줘도 돼요.'**
  String weeklyObservationDominantNegative(String emotion);

  /// 마음 리포트/주간 리포트 - 주간 관찰, 메모를 많이 남겼을 때
  ///
  /// In ko, this message translates to:
  /// **'이번 주는 이야기를 많이 들려줬어요.\n마음을 꺼내 보여주는 건 결코 쉬운 일이 아니에요. 몽이가 하나하나 다 기억하고 있어요 📔'**
  String get weeklyObservationManyNotes;

  /// 마음 리포트/주간 리포트 - 주간 관찰, 부정 감정이 대부분일 때
  ///
  /// In ko, this message translates to:
  /// **'마음이 조금 무거운 주였을 수도 있어요.\n그런 날에도 매일 몽이에게 와준 것, 그 자체로 참 잘한 거예요 🤍'**
  String get weeklyObservationMostlyHeavy;

  /// 마음 리포트/주간 리포트 - 주간 관찰, 기본값(가장 자주 만난 감정)
  ///
  /// In ko, this message translates to:
  /// **'이번 주 가장 자주 만난 마음은\n\"{emotion}\"이었어요 ({count}번). 어떤 마음이든 몽이에게는 다 소중해요.'**
  String weeklyObservationDefaultTopEmotion(String emotion, int count);

  /// 마음 리포트/주간 리포트 - 주간 관찰, 기본값(감정 기록 없음)
  ///
  /// In ko, this message translates to:
  /// **'이번 주도 몽이와 함께해줘서 고마워요.'**
  String get weeklyObservationDefaultThanks;

  /// 감정 캘린더 화면 - 헤더 타이틀
  ///
  /// In ko, this message translates to:
  /// **'🗓️ 감정 캘린더'**
  String get calendarHeaderTitle;

  /// 감정 캘린더 화면 - 월 이동 네비게이션의 '연 월' 라벨
  ///
  /// In ko, this message translates to:
  /// **'{year}년 {month}월'**
  String calendarMonthLabel(int year, int month);

  /// 감정 캘린더 화면 - 인사이트 패널, 데이터 부족 안내
  ///
  /// In ko, this message translates to:
  /// **'이 달의 기록이 조금 더 쌓이면\n마음의 흐름을 보여드릴게요 🌱'**
  String get calendarInsightNotEnoughData;

  /// 감정 캘린더 화면 - 인사이트 패널 접힌 제목(1위 감정만, 또는 1위 & 2위 조합 라벨을 그대로 포함)
  ///
  /// In ko, this message translates to:
  /// **'이달의 몽이 일기 제목: \"{label}\"'**
  String calendarInsightTitleWithTop(String label);

  /// 감정 캘린더 화면 - 인사이트 패널 접힌 제목(상위 감정 데이터가 없을 때)
  ///
  /// In ko, this message translates to:
  /// **'이 달의 마음 흐름 보기'**
  String get calendarInsightTitleFallback;

  /// 감정 캘린더 화면 - 감정 다양성 통계 칩 라벨
  ///
  /// In ko, this message translates to:
  /// **'감정 다양성'**
  String get calendarStatDiversityLabel;

  /// 감정 캘린더 화면 - 감정 다양성 통계 칩 값
  ///
  /// In ko, this message translates to:
  /// **'{count} / 15종'**
  String calendarStatDiversityValue(int count);

  /// 감정 캘린더 화면 - 최장 연속 방문 통계 칩 라벨
  ///
  /// In ko, this message translates to:
  /// **'최장 연속 방문'**
  String get calendarStatStreakLabel;

  /// 감정 캘린더 화면 - 최장 연속 방문 통계 칩 값
  ///
  /// In ko, this message translates to:
  /// **'{days}일'**
  String calendarStatStreakValue(int days);

  /// 감정 캘린더 화면 - 주차별 추이 차트 제목
  ///
  /// In ko, this message translates to:
  /// **'주차별 마음 흐름'**
  String get calendarWeeklyTrendTitle;

  /// 감정 캘린더 화면 - 주차별 추이 차트 범례, 긍정
  ///
  /// In ko, this message translates to:
  /// **'긍정'**
  String get calendarLegendPositive;

  /// 감정 캘린더 화면 - 주차별 추이 차트 범례, 부정
  ///
  /// In ko, this message translates to:
  /// **'부정'**
  String get calendarLegendNegative;

  /// 감정 캘린더 화면 - 요일별 흐름 섹션 제목
  ///
  /// In ko, this message translates to:
  /// **'요일별 마음 흐름'**
  String get calendarWeekdayTrendTitle;

  /// 감정 캘린더 화면 - 주차별 추이 차트 x축 라벨(1주, 2주...)
  ///
  /// In ko, this message translates to:
  /// **'{week}주'**
  String calendarWeekLabel(int week);

  /// 감정 캘린더 화면 - 이번 달 요약, 기록 없음 안내
  ///
  /// In ko, this message translates to:
  /// **'이번 달엔 아직 기록이 없어요.\n감정을 마주하고 나면 여기에 쌓여요 🌱'**
  String get calendarEmptyMonth;

  /// 감정 캘린더 화면 - 이번 달 요약 카드 제목
  ///
  /// In ko, this message translates to:
  /// **'이번 달의 마음 요약'**
  String get calendarMonthSummaryTitle;

  /// 감정 캘린더 화면 - 이번 달 가장 많이 마주한 감정
  ///
  /// In ko, this message translates to:
  /// **'가장 많이 마주한 감정은 \"{emotion}\"이에요 {icon}'**
  String calendarMonthSummaryTopEmotion(String emotion, String icon);

  /// 감정 캘린더 화면 - 이번 달 총 기록 횟수 안내
  ///
  /// In ko, this message translates to:
  /// **'이번 달 총 {count}번, 마음을 꺼내 보여줬어요.\n어떤 마음이든 다 괜찮아요, 몽이는 늘 곁에 있어요.'**
  String calendarMonthSummaryTotal(int count);

  /// 감정 캘린더 화면 - 이 달 전체 감정 분포(비율) 섹션 제목
  ///
  /// In ko, this message translates to:
  /// **'이 달의 감정 수치'**
  String get calendarMonthDistributionTitle;

  /// 감정 캘린더 화면 - 감정 분포 막대 옆 퍼센트 표시
  ///
  /// In ko, this message translates to:
  /// **'{percent}%'**
  String calendarMonthDistributionPercent(int percent);

  /// 감정 캘린더 화면 - 월간 관찰/분석 문구 섹션 제목
  ///
  /// In ko, this message translates to:
  /// **'이 달의 가벼운 분석'**
  String get calendarMonthAnalysisTitle;

  /// 월간 관찰 문구 - 표본 부족(3회 미만)
  ///
  /// In ko, this message translates to:
  /// **'이 달은 아직 기록이 조금 더 필요해요.\n괜찮아요, 천천히 채워가요 🌱'**
  String get monthlyObservationNoData;

  /// 월간 관찰 문구 - 전월 대비 긍정 비율 15%p 이상 개선
  ///
  /// In ko, this message translates to:
  /// **'지난달보다 밝은 마음이 {deltaPercent}%p 늘었어요.\n한 달 동안 쌓인 그 변화, 몽이도 함께 지켜봤어요 ✨'**
  String monthlyObservationImprovedFromLastMonth(int deltaPercent);

  /// 월간 관찰 문구 - 전월 대비 긍정 비율 20%p 이상 악화
  ///
  /// In ko, this message translates to:
  /// **'지난달보다 마음이 조금 더 힘들었던 한 달일 수 있어요.\n애쓰지 않아도 괜찮아요, 몽이는 계속 곁에 있을게요 🤍'**
  String get monthlyObservationDeclinedFromLastMonth;

  /// 월간 관찰 문구 - 특정 긍정 감정이 60% 이상 지배
  ///
  /// In ko, this message translates to:
  /// **'이 달은 유독 \"{emotion}\"이(가) 가득했던 한 달이었어요 ({percent}%).\n그 좋은 기운, 몽이도 함께 느꼈어요 😊'**
  String monthlyObservationDominantPositive(String emotion, int percent);

  /// 월간 관찰 문구 - 특정 부정 감정이 60% 이상 지배
  ///
  /// In ko, this message translates to:
  /// **'이 달은 유독 \"{emotion}\"이(가) 컸던 한 달이었어요 ({percent}%).\n무슨 일이 있었는지 몽이는 궁금해요. 천천히 얘기해줘도 돼요.'**
  String monthlyObservationDominantNegative(String emotion, int percent);

  /// 월간 관찰 문구 - 고유 감정 종류가 8개 이상으로 다양
  ///
  /// In ko, this message translates to:
  /// **'이 달은 {count}가지나 되는 다양한 마음을 만났어요.\n하나의 감정에 머무르지 않았다는 것, 그 자체로 마음이 유연했다는 뜻이에요 🎨'**
  String monthlyObservationDiverseEmotions(int count);

  /// 월간 관찰 문구 - 긍정 비율 25% 이하
  ///
  /// In ko, this message translates to:
  /// **'마음이 조금 무거운 한 달이었을 수도 있어요.\n그런 날에도 매일 몽이에게 와준 것, 그 자체로 참 잘한 거예요 🤍'**
  String get monthlyObservationMostlyHeavy;

  /// 월간 관찰 문구 - 뚜렷한 패턴이 없을 때의 기본값
  ///
  /// In ko, this message translates to:
  /// **'이 달 가장 자주 만난 마음은\n\"{emotion}\"이었어요 ({count}번). 어떤 마음이든 몽이에게는 다 소중해요.'**
  String monthlyObservationDefaultTopEmotion(String emotion, int count);

  /// 월간 관찰 문구 - 기록은 있으나 계산할 감정이 없을 때의 기본값
  ///
  /// In ko, this message translates to:
  /// **'이 달도 몽이와 함께해줘서 고마워요.'**
  String get monthlyObservationDefaultThanks;

  /// 감정 캘린더 화면 - 날짜 셀 탭 시 바텀시트 제목
  ///
  /// In ko, this message translates to:
  /// **'{day}일의 기록'**
  String calendarDayDetailTitle(int day);

  /// 감정 캘린더 화면 - 날짜 상세, 강도 점(●○) 라벨
  ///
  /// In ko, this message translates to:
  /// **'강도 {dots}'**
  String calendarIntensityLabel(String dots);

  /// 시즌 패스 화면 - 앱바 타이틀
  ///
  /// In ko, this message translates to:
  /// **'시즌 {seasonNumber} · 몽이의 마음여정'**
  String seasonPassAppBarTitle(int seasonNumber);

  /// 시즌 패스 화면 - 헤더 아래 부제 설명
  ///
  /// In ko, this message translates to:
  /// **'게임을 하지 않아도, 매일 체크인하거나 감사 기록을 남기는 것만으로도\n마음여정이 조금씩 앞으로 나아가요 🌿'**
  String get seasonPassSubHeadline;

  /// 시즌 패스 화면 - 남은 시간 카운트다운(일 단위)
  ///
  /// In ko, this message translates to:
  /// **'{days}일 {hours}시간 남음'**
  String seasonPassCountdownDays(int days, int hours);

  /// 시즌 패스 화면 - 남은 시간 카운트다운(시간 단위)
  ///
  /// In ko, this message translates to:
  /// **'{hours}시간 {minutes}분 남음'**
  String seasonPassCountdownHours(int hours, int minutes);

  /// 시즌 패스 화면 - 남은 시간 카운트다운(분 단위)
  ///
  /// In ko, this message translates to:
  /// **'{minutes}분 남음'**
  String seasonPassCountdownMinutes(int minutes);

  /// 시즌 패스 화면 - 프리미엄 구매 확인 다이얼로그 제목
  ///
  /// In ko, this message translates to:
  /// **'시즌 패스 프리미엄 🌟'**
  String get seasonPassPurchaseDialogTitle;

  /// 시즌 패스 화면 - 프리미엄 구매 확인 다이얼로그 본문
  ///
  /// In ko, this message translates to:
  /// **'이번 시즌 동안 모든 레벨에서 훨씬 풍성한 보상을 받을 수 있어요.\n지금까지 쌓은 레벨의 프리미엄 보상도 곧바로 모두 받을 수 있어요.'**
  String get seasonPassPurchaseDialogBody;

  /// 시즌 패스 화면 - 구매 복원 완료 안내 스낵바
  ///
  /// In ko, this message translates to:
  /// **'구매 내역을 확인했어요. 이미 구매하셨다면 잠시 후 반영돼요.'**
  String get seasonPassRestoreConfirmedSnackbar;

  /// 시즌 패스 화면 - 무료 보상 수령 완료 스낵바
  ///
  /// In ko, this message translates to:
  /// **'레벨 {level} 무료 보상을 받았어요!'**
  String seasonPassFreeRewardClaimedSnackbar(int level);

  /// 시즌 패스 화면 - 프리미엄 보상 수령 완료 스낵바
  ///
  /// In ko, this message translates to:
  /// **'레벨 {level} 프리미엄 보상을 받았어요!'**
  String seasonPassPremiumRewardClaimedSnackbar(int level);

  /// 시즌 패스 화면 - 헤더의 현재 레벨 표시
  ///
  /// In ko, this message translates to:
  /// **'레벨 {level}'**
  String seasonPassLevelLabel(int level);

  /// 시즌 패스 화면 - 헤더의 현재 레벨 표시(최고 레벨 도달 시)
  ///
  /// In ko, this message translates to:
  /// **'레벨 {level} (최고 레벨)'**
  String seasonPassLevelLabelMax(int level);

  /// 시즌 패스 화면 - 무료 트랙 배지
  ///
  /// In ko, this message translates to:
  /// **'무료'**
  String get seasonPassFreeTierBadge;

  /// 시즌 패스 화면 - 프리미엄 트랙 배지
  ///
  /// In ko, this message translates to:
  /// **'💎 프리미엄'**
  String get seasonPassPremiumTierBadge;

  /// 시즌 패스 화면 - 헤더 진행바 아래, 최고 레벨 도달 안내
  ///
  /// In ko, this message translates to:
  /// **'모든 레벨을 다 채웠어요!'**
  String get seasonPassMaxLevelReached;

  /// 시즌 패스 화면 - 헤더 진행바 아래, 현재 경험치 / 다음 레벨까지 필요 경험치
  ///
  /// In ko, this message translates to:
  /// **'{xpInto} / {span} xp'**
  String seasonPassXpProgress(int xpInto, int span);

  /// 시즌 패스 화면 - 5의 배수 레벨 카드 상단 마일스톤 배지
  ///
  /// In ko, this message translates to:
  /// **'🌿 마음 마일스톤'**
  String get seasonPassMindMilestoneBadge;

  /// 시즌 패스 화면 - 레벨 카드의 레벨 숫자 배지
  ///
  /// In ko, this message translates to:
  /// **'Lv.{level}'**
  String seasonPassTierLevelLabel(int level);

  /// 시즌 패스 화면 - 보상 수령 가능 버튼
  ///
  /// In ko, this message translates to:
  /// **'받기 →'**
  String get seasonPassClaimButton;

  /// 시즌 패스 화면 - 하단바, 이미 프리미엄 보유 중 안내
  ///
  /// In ko, this message translates to:
  /// **'✅ 프리미엄 패스 보유 중'**
  String get seasonPassOwnedBanner;

  /// 시즌 패스 화면 - 하단바, 프리미엄 업그레이드 버튼
  ///
  /// In ko, this message translates to:
  /// **'💎 프리미엄 패스로 업그레이드'**
  String get seasonPassUpgradeButton;

  /// 시즌 패스 화면 - 마지막 레벨 프리미엄 보상 라벨(코스튬 포함)
  ///
  /// In ko, this message translates to:
  /// **'빛의 정수 {lightEssence}개 + 별조각 {starShard}개 + 확정 코스튬 \"{costumeName}\"'**
  String seasonRewardFinaleLabel(
    int lightEssence,
    int starShard,
    String costumeName,
  );

  /// 시즌 패스 화면 - 별조각이 포함된 보상 라벨
  ///
  /// In ko, this message translates to:
  /// **'빛의 정수 {lightEssence}개 + 별조각 {starShard}개'**
  String seasonRewardWithShardLabel(int lightEssence, int starShard);

  /// 시즌 패스 화면 - 빛의 정수만 있는 보상 라벨
  ///
  /// In ko, this message translates to:
  /// **'빛의 정수 {lightEssence}개'**
  String seasonRewardLightOnlyLabel(int lightEssence);

  /// 내 주변 상담센터 화면 - 헤더 타이틀
  ///
  /// In ko, this message translates to:
  /// **'📍 내 주변 상담센터'**
  String get nearbyHeaderTitle;

  /// 내 주변 상담센터 화면 - 기관 유형 목록 위 섹션 제목
  ///
  /// In ko, this message translates to:
  /// **'🗺️ 어떤 곳을 찾고 있나요?'**
  String get nearbySectionTitle;

  /// 내 주변 상담센터 화면 - 상단 소개 카드 본문
  ///
  /// In ko, this message translates to:
  /// **'전화가 아직 망설여진다면, 가까운 곳에 직접 찾아가 이야기를\n나눠보는 것도 좋은 방법이에요. 아래에서 원하는 기관을 고르면\n지도 앱으로 내 주변에 있는 곳을 바로 찾아드려요.'**
  String get nearbyIntroCardBody;

  /// 내 주변 상담센터 화면 - 공식 포털 카드 제목
  ///
  /// In ko, this message translates to:
  /// **'국가정신건강정보포털에서 전체 목록 보기'**
  String get nearbyOfficialPortalTitle;

  /// 내 주변 상담센터 화면 - 공식 포털 카드 부제목
  ///
  /// In ko, this message translates to:
  /// **'보건복지부 공식 기관 찾기 서비스로 이동해요'**
  String get nearbyOfficialPortalSubtitle;

  /// 내 주변 상담센터 화면 - 비한국어 로케일 전용 공식 포털 카드 제목(한국 포털 대신 글로벌 디렉토리)
  ///
  /// In ko, this message translates to:
  /// **'Find A Helpline에서 내 국가의 상담 채널 보기'**
  String get nearbyGlobalOfficialPortalTitle;

  /// 내 주변 상담센터 화면 - 비한국어 로케일 전용 공식 포털 카드 부제목
  ///
  /// In ko, this message translates to:
  /// **'130개국 이상의 상담 채널을 찾을 수 있는 글로벌 디렉토리로 이동해요'**
  String get nearbyGlobalOfficialPortalSubtitle;

  /// 내 주변 상담센터 화면 - 비한국어 로케일 전용 정신건강 지도 검색어(한국 특화 용어 대신 범용 용어)
  ///
  /// In ko, this message translates to:
  /// **'mental health clinic'**
  String get nearbyCenterMentalHealthMapQueryGlobal;

  /// 내 주변 상담센터 화면 - 비한국어 로케일 전용 청소년상담 지도 검색어
  ///
  /// In ko, this message translates to:
  /// **'youth counseling center'**
  String get nearbyCenterYouthMapQueryGlobal;

  /// 내 주변 상담센터 화면 - 비한국어 로케일 전용 자살예방센터 지도 검색어
  ///
  /// In ko, this message translates to:
  /// **'crisis center'**
  String get nearbyCenterSuicidePreventionMapQueryGlobal;

  /// 내 주변 상담센터 화면 - 비한국어 로케일 전용 정신건강의학과 지도 검색어
  ///
  /// In ko, this message translates to:
  /// **'psychiatrist'**
  String get nearbyCenterPsychiatricMapQueryGlobal;

  /// 내 주변 상담센터 화면 - 하단 안내 문구
  ///
  /// In ko, this message translates to:
  /// **'※ 지도 검색 결과는 Google 지도가 제공하며, 실제 운영시간/이용조건은\n방문 전 각 기관에 직접 확인하는 것을 권장해요.'**
  String get nearbyFooterNote;

  /// 내 주변 상담센터 화면 - 지도 앱 실행 실패 스낵바
  ///
  /// In ko, this message translates to:
  /// **'지도 앱을 여는 데 실패했어요.'**
  String get nearbyMapOpenFailedSnackbar;

  /// 내 주변 상담센터 화면 - 공식 포털 페이지 열기 실패 스낵바
  ///
  /// In ko, this message translates to:
  /// **'페이지를 여는 데 실패했어요.'**
  String get nearbyPortalOpenFailedSnackbar;

  /// 내 주변 상담센터 화면 - 정신건강복지센터 이름
  ///
  /// In ko, this message translates to:
  /// **'정신건강복지센터'**
  String get nearbyCenterMentalHealthName;

  /// 내 주변 상담센터 화면 - 정신건강복지센터 설명
  ///
  /// In ko, this message translates to:
  /// **'누구나 무료로 이용할 수 있는 지역 상담기관. 우울/불안 등\n마음 어려움 전반에 대한 상담과 지원을 받을 수 있어요.'**
  String get nearbyCenterMentalHealthDesc;

  /// 내 주변 상담센터 화면 - 청소년상담복지센터 이름
  ///
  /// In ko, this message translates to:
  /// **'청소년상담복지센터'**
  String get nearbyCenterYouthName;

  /// 내 주변 상담센터 화면 - 청소년상담복지센터 설명
  ///
  /// In ko, this message translates to:
  /// **'만 9~24세 청소년을 위한 무료 상담기관.\n학업, 관계, 가정 문제 등을 편하게 상담할 수 있어요.'**
  String get nearbyCenterYouthDesc;

  /// 내 주변 상담센터 화면 - 자살예방센터 이름
  ///
  /// In ko, this message translates to:
  /// **'자살예방센터'**
  String get nearbyCenterSuicidePreventionName;

  /// 내 주변 상담센터 화면 - 자살예방센터 설명
  ///
  /// In ko, this message translates to:
  /// **'위기 상황에 대한 전문적인 개입과 사후관리를 지원하는\n지역 자살예방 전담기관.'**
  String get nearbyCenterSuicidePreventionDesc;

  /// 내 주변 상담센터 화면 - 정신건강의학과 의원 이름
  ///
  /// In ko, this message translates to:
  /// **'정신건강의학과 의원'**
  String get nearbyCenterPsychiatricName;

  /// 내 주변 상담센터 화면 - 정신건강의학과 의원 설명
  ///
  /// In ko, this message translates to:
  /// **'약물치료나 전문적인 진단이 필요할 수 있다고 느껴질 때,\n가까운 병원을 먼저 찾아볼 수 있어요.'**
  String get nearbyCenterPsychiatricDesc;

  /// 내 주변 상담센터 화면 - 정신건강복지센터 지도 검색어
  ///
  /// In ko, this message translates to:
  /// **'정신건강복지센터'**
  String get nearbyCenterMentalHealthMapQuery;

  /// 내 주변 상담센터 화면 - 청소년상담복지센터 지도 검색어
  ///
  /// In ko, this message translates to:
  /// **'청소년상담복지센터'**
  String get nearbyCenterYouthMapQuery;

  /// 내 주변 상담센터 화면 - 자살예방센터 지도 검색어
  ///
  /// In ko, this message translates to:
  /// **'자살예방센터'**
  String get nearbyCenterSuicidePreventionMapQuery;

  /// 내 주변 상담센터 화면 - 정신건강의학과 지도 검색어
  ///
  /// In ko, this message translates to:
  /// **'정신건강의학과'**
  String get nearbyCenterPsychiatricMapQuery;

  /// 마음 리포트 화면 - 헤더 타이틀
  ///
  /// In ko, this message translates to:
  /// **'💗 마음 리포트'**
  String get mindReportHeaderTitle;

  /// 마음 리포트 화면 - 상단 소개 문구
  ///
  /// In ko, this message translates to:
  /// **'몽이와 함께 마주한 마음들을 한눈에 모아봤어요.\n숫자보다, 그 마음들을 알아채준 당신이 더 대단해요.'**
  String get mindReportIntroText;

  /// 마음 리포트 화면 - 정신건강 안내 강조 카드 제목
  ///
  /// In ko, this message translates to:
  /// **'요즘 마음이 많이 무거웠나 봐요'**
  String get mindReportSupportAlertTitle;

  /// 마음 리포트 화면 - 정신건강 안내 강조 카드 본문
  ///
  /// In ko, this message translates to:
  /// **'혼자 견디지 않아도 괜찮아요. 언제든 이야기 나눌 곳이 있어요.'**
  String get mindReportSupportAlertBody;

  /// 마음 리포트 화면 - 정신건강 안내 진입 카드 라벨
  ///
  /// In ko, this message translates to:
  /// **'마음이 힘들 때 - 상담 안내 보기'**
  String get mindReportSupportEntryLabel;

  /// 마음 리포트 화면 - 주간 요약 카드 제목
  ///
  /// In ko, this message translates to:
  /// **'이번 주 몽이의 관찰'**
  String get mindReportWeeklyTitle;

  /// 마음 리포트 화면 - 주간 요약, 긍정 비율
  ///
  /// In ko, this message translates to:
  /// **'긍정 {percent}%'**
  String mindReportWeeklyPositiveLabel(int percent);

  /// 마음 리포트 화면 - 주간 요약, 함께한 횟수
  ///
  /// In ko, this message translates to:
  /// **'· 함께한 {count}번'**
  String mindReportWeeklySessionsLabel(int count);

  /// 마음 리포트 화면 - 주간 요약, 데이터 부족 안내
  ///
  /// In ko, this message translates to:
  /// **'아직 데이터가 모이고 있어요. 조금 더 함께해주세요 🌱'**
  String get mindReportWeeklyNotEnoughData;

  /// 마음 리포트 화면 - 월간 요약 카드 제목
  ///
  /// In ko, this message translates to:
  /// **'이번 달 마음 흐름'**
  String get mindReportMonthlyTitle;

  /// 마음 리포트 화면 - 월간 요약, 가장 많이 만난 감정
  ///
  /// In ko, this message translates to:
  /// **'가장 많이 만난 마음은 \"{emotion}\"이에요'**
  String mindReportMonthlyTopEmotion(String emotion);

  /// 마음 리포트 화면 - 월간 요약, 가장 많이 만난 감정이 없을 때
  ///
  /// In ko, this message translates to:
  /// **'이 달의 마음 흐름을 보여드릴게요'**
  String get mindReportMonthlyNoTopEmotion;

  /// 마음 리포트 화면 - 월간 요약, 최장 연속 기록일
  ///
  /// In ko, this message translates to:
  /// **'🔥 {days}일'**
  String mindReportMonthlyStreak(int days);

  /// 마음 리포트 화면 - 월간 요약, 데이터 부족 안내
  ///
  /// In ko, this message translates to:
  /// **'이 달의 기록이 조금 더 쌓이면 마음의 흐름을 보여드릴게요 🌱'**
  String get mindReportMonthlyNotEnoughData;

  /// 마음 리포트 화면 - 요일별 패턴 카드 제목
  ///
  /// In ko, this message translates to:
  /// **'요일별 마음 흐름'**
  String get mindReportWeekdayTitle;

  /// 마음 리포트 화면 - 감정 원인(트리거) 패턴 카드 제목
  ///
  /// In ko, this message translates to:
  /// **'마음의 원인'**
  String get mindReportTriggerTitle;

  /// 마음 리포트 화면 - 감정 원인 패턴, 데이터 부족 안내
  ///
  /// In ko, this message translates to:
  /// **'감정을 기록할 때 \"무엇 때문이었을까요?\"에 몇 번 더 답해주시면, 마음의 원인 패턴도 보여드릴게요 🌱'**
  String get mindReportTriggerNotEnoughData;

  /// 마음 리포트 화면 - 트리거 인사이트(특정 원인이 부정 감정과 뚜렷하게 연결될 때)
  ///
  /// In ko, this message translates to:
  /// **'최근엔 유독 \"{trigger}\" 때문에 마음이 힘들었을 수 있어요.\n{count}번이나 그 마음의 곁에 있었네요. 알아챈 것만으로도 이미 잘하고 있는 거예요 🤍'**
  String triggerInsightDominantNegativeCause(String trigger, int count);

  /// 마음 리포트 화면 - 트리거 인사이트(가장 흔한 원인, 뚜렷한 연결까지는 아닐 때)
  ///
  /// In ko, this message translates to:
  /// **'최근 마음에 가장 자주 영향을 준 건 \"{trigger}\"였어요 ({count}번).\n스스로도 몰랐던 패턴을 알아챈 걸지도 몰라요.'**
  String triggerInsightTopTrigger(String trigger, int count);

  /// 감정 원인 태그 - 일/학업
  ///
  /// In ko, this message translates to:
  /// **'일/학업'**
  String get emotionTriggerWorkStudy;

  /// 감정 원인 태그 - 관계
  ///
  /// In ko, this message translates to:
  /// **'관계'**
  String get emotionTriggerRelationship;

  /// 감정 원인 태그 - 가족
  ///
  /// In ko, this message translates to:
  /// **'가족'**
  String get emotionTriggerFamily;

  /// 감정 원인 태그 - 건강
  ///
  /// In ko, this message translates to:
  /// **'건강'**
  String get emotionTriggerHealth;

  /// 감정 원인 태그 - 돈
  ///
  /// In ko, this message translates to:
  /// **'돈'**
  String get emotionTriggerMoney;

  /// 감정 원인 태그 - 잠/피로
  ///
  /// In ko, this message translates to:
  /// **'잠/피로'**
  String get emotionTriggerSleep;

  /// 감정 원인 태그 - 혼자 있음
  ///
  /// In ko, this message translates to:
  /// **'혼자 있음'**
  String get emotionTriggerAlone;

  /// 감정 원인 태그 - SNS
  ///
  /// In ko, this message translates to:
  /// **'SNS'**
  String get emotionTriggerSns;

  /// 감정 원인 태그 - 날씨
  ///
  /// In ko, this message translates to:
  /// **'날씨'**
  String get emotionTriggerWeather;

  /// 감정 원인 태그 - 미래 걱정
  ///
  /// In ko, this message translates to:
  /// **'미래 걱정'**
  String get emotionTriggerFuture;

  /// 감정 원인 태그 - 작은 성취
  ///
  /// In ko, this message translates to:
  /// **'작은 성취'**
  String get emotionTriggerAchievement;

  /// 감정 원인 태그 - 그 외
  ///
  /// In ko, this message translates to:
  /// **'그 외'**
  String get emotionTriggerEtc;

  /// 마음 리포트 화면 - 감사 기록 카드 제목
  ///
  /// In ko, this message translates to:
  /// **'감사 & 작은 성취'**
  String get mindReportGratitudeTitle;

  /// 마음 리포트 화면 - 감사 기록이 없을 때
  ///
  /// In ko, this message translates to:
  /// **'아직 기록이 없어요'**
  String get mindReportGratitudeEmpty;

  /// 마음 리포트 화면 - 감사 기록 개수
  ///
  /// In ko, this message translates to:
  /// **'{count}개의 기록'**
  String mindReportGratitudeCount(int count);

  /// 마음 리포트 화면 - 오늘 감사 기록을 이미 남겼을 때 배지
  ///
  /// In ko, this message translates to:
  /// **'오늘 남겼어요 ✓'**
  String get mindReportGratitudeDoneToday;

  /// 마음 리포트 화면 - 감정 도감 미니 카드 제목
  ///
  /// In ko, this message translates to:
  /// **'감정 도감'**
  String get mindReportCollectionTitle;

  /// 마음 리포트 화면 - 감정 다이어리 미니 카드 제목
  ///
  /// In ko, this message translates to:
  /// **'감정 다이어리'**
  String get mindReportDiaryTitle;

  /// 마음 리포트 화면 - 감정 다이어리 이야기 개수
  ///
  /// In ko, this message translates to:
  /// **'{count}개의 이야기'**
  String mindReportDiaryCount(int count);

  /// 감정 도감 화면 - 헤더 타이틀
  ///
  /// In ko, this message translates to:
  /// **'📖 감정 도감'**
  String get collectionHeaderTitle;

  /// 감정 도감 화면 - 부정 감정 섹션 제목
  ///
  /// In ko, this message translates to:
  /// **'🌧️ 마주한 마음들 (10종)'**
  String get collectionNegativeSectionTitle;

  /// 감정 도감 화면 - 긍정 감정 섹션 제목
  ///
  /// In ko, this message translates to:
  /// **'🌟 품은 마음들 (5종)'**
  String get collectionPositiveSectionTitle;

  /// 감정 도감 화면 - 진행도 카드, 전부 수집 완료
  ///
  /// In ko, this message translates to:
  /// **'15가지 마음을 모두 만났어요! 대단해요 🎉'**
  String get collectionProgressCompleteText;

  /// 감정 도감 화면 - 진행도 카드, 일부 수집
  ///
  /// In ko, this message translates to:
  /// **'지금까지 {count}가지 마음을 만났어요'**
  String collectionProgressPartialText(int count);

  /// 감정 도감 화면 - 진행도 카드, 진화 안내
  ///
  /// In ko, this message translates to:
  /// **'자주 마주할수록 몬스터가 진화해요 (5번·20번·50번)'**
  String get collectionProgressHint;

  /// 감정 도감 화면 - 진행도 카드, 보유중인 황금 프레임 개수
  ///
  /// In ko, this message translates to:
  /// **'황금 프레임 {count}개 보유중!'**
  String collectionGoldenFrameCount(int count);

  /// 감정 도감 화면 - 상세 다이얼로그, 황금 프레임 획득 배지
  ///
  /// In ko, this message translates to:
  /// **'🏆 황금 프레임 획득!'**
  String get collectionGoldenFrameEarned;

  /// 감정 도감 화면 - 상세 다이얼로그, 초월(히든 4단계) 배지
  ///
  /// In ko, this message translates to:
  /// **'🌌 초월한 마음'**
  String get collectionTranscendedBadge;

  /// 감정 도감 화면 - 상세 다이얼로그, 등급 표시 중 초월 등급
  ///
  /// In ko, this message translates to:
  /// **'초월 등급'**
  String get collectionTranscendedRank;

  /// 감정 도감 화면 - 상세 다이얼로그, 등급 표시 중 마스터 등급
  ///
  /// In ko, this message translates to:
  /// **'마스터 등급'**
  String get collectionMasteredRank;

  /// 감정 도감 화면 - 상세 다이얼로그, 등급 표시 중 일반 단계
  ///
  /// In ko, this message translates to:
  /// **'{stage}단계'**
  String collectionStageRank(int stage);

  /// 감정 도감 화면 - 상세 다이얼로그, 지금까지 마주한 횟수
  ///
  /// In ko, this message translates to:
  /// **'지금까지 {count}번 마주했어요'**
  String collectionMetCountLabel(int count);

  /// 감정 도감 화면 - 상세 다이얼로그, 다음 진화까지 남은 횟수
  ///
  /// In ko, this message translates to:
  /// **'{remaining}번 더 마주하면 \"{nextName}\"(으)로 진화해요'**
  String collectionNextEvolutionHint(int remaining, String nextName);

  /// 감정 도감 화면 - 상세 다이얼로그, 초월 등급 안내 메시지
  ///
  /// In ko, this message translates to:
  /// **'백 번의 마주침 끝에 완전히 다른 존재가 됐어요.\n아무도 예고해주지 않았던, 오직 당신만의 발견이에요 🌌'**
  String get collectionTranscendedMessage;

  /// 감정 도감 화면 - 상세 다이얼로그, 마스터 등급 안내 메시지
  ///
  /// In ko, this message translates to:
  /// **'완전히 진화했어요! 이제부터 마주할 때마다\n아주 낮은 확률로 황금 프레임을 얻을 수 있어요 ✨'**
  String get collectionMasteredMessage;

  /// 공통 - 다이얼로그/시트 닫기 버튼
  ///
  /// In ko, this message translates to:
  /// **'닫기'**
  String get commonCloseButton;

  /// 정원 공유 카드 - SNS 공유 시 첨부되는 텍스트
  ///
  /// In ko, this message translates to:
  /// **'몽이의 성장나무가 지금 {label} 단계예요 🌳 매일 마음을 돌보며 함께 자라고 있어요 #몽이 #마음정원'**
  String gardenShareShareText(String label);

  /// 정원 공유 카드 - 바텀시트 제목
  ///
  /// In ko, this message translates to:
  /// **'몽이의 정원 공유 카드 🌳'**
  String get gardenShareSheetTitle;

  /// 정원 공유 카드 - 바텀시트 부제목
  ///
  /// In ko, this message translates to:
  /// **'지금까지 함께 가꾼 정원을 자랑해보세요'**
  String get gardenShareSheetSubtitle;

  /// 정원 공유 카드 - 카드 생성 중 버튼 라벨
  ///
  /// In ko, this message translates to:
  /// **'카드 만드는 중...'**
  String get gardenShareCardMakingButton;

  /// 정원 공유 카드 - 카드 공유 버튼 라벨
  ///
  /// In ko, this message translates to:
  /// **'카드 공유하기'**
  String get gardenShareCardButton;

  /// 정원 공유 카드 - 카드 상단 이름
  ///
  /// In ko, this message translates to:
  /// **'몽이의 정원'**
  String get gardenShareCardName;

  /// 정원 공유 카드 - 카드 본문, 나무가 자라난 단계
  ///
  /// In ko, this message translates to:
  /// **'지금 {label} 단계로 자라났어요'**
  String gardenShareCardGrownLabel(String label);

  /// 정원 공유 카드 - 카드 본문, 아직 씨앗을 심기 전
  ///
  /// In ko, this message translates to:
  /// **'아직 씨앗을 심기 전이에요'**
  String get gardenShareCardNotGrownLabel;

  /// 정원 공유 카드 - 통계, 연속 방문일 수치
  ///
  /// In ko, this message translates to:
  /// **'{days}일'**
  String gardenShareCardStreakStat(int days);

  /// 정원 공유 카드 - 통계, 연속 방문일 라벨
  ///
  /// In ko, this message translates to:
  /// **'연속'**
  String get gardenShareCardStreakLabel;

  /// 정원 공유 카드 - 통계, 피운 꽃 개수 수치
  ///
  /// In ko, this message translates to:
  /// **'{count}송이'**
  String gardenShareCardFlowersStat(int count);

  /// 정원 공유 카드 - 통계, 피운 꽃 라벨
  ///
  /// In ko, this message translates to:
  /// **'피운 꽃'**
  String get gardenShareCardFlowersLabel;

  /// 정원 공유 카드 - 통계, 점수 수치
  ///
  /// In ko, this message translates to:
  /// **'{score}점'**
  String gardenShareCardScoreStat(int score);

  /// 정원 공유 카드 - 통계, 점수 라벨
  ///
  /// In ko, this message translates to:
  /// **'점수'**
  String get gardenShareCardScoreLabel;

  /// 정원 공유 카드 - 카드 하단 문구
  ///
  /// In ko, this message translates to:
  /// **'매일 마음을 돌보며\n조금씩 자라나는 중이에요 🌱'**
  String get gardenShareCardFooter;

  /// 성장 마일스톤 화면 - 헤더 타이틀
  ///
  /// In ko, this message translates to:
  /// **'🎬 몽이의 성장 다큐멘터리'**
  String get milestoneHeaderTitle;

  /// 성장 마일스톤 화면 - 인트로 카드 제목
  ///
  /// In ko, this message translates to:
  /// **'몽이의 나무가 마침내\n열매를 맺었어요 🍎'**
  String get milestoneIntroTitle;

  /// 성장 마일스톤 화면 - 인트로 카드 본문
  ///
  /// In ko, this message translates to:
  /// **'작은 씨앗이었던 몽이가\n그동안 마주한 마음들 덕분에 이렇게 자랐어요.\n함께 걸어온 길을 잠시 돌아볼까요?'**
  String get milestoneIntroBody;

  /// 성장 마일스톤 화면 - 타임라인 목록 제목
  ///
  /// In ko, this message translates to:
  /// **'몽이와 함께한 이야기'**
  String get milestoneTimelineTitle;

  /// 성장 마일스톤 화면 - 통계, 최근 연속일 라벨
  ///
  /// In ko, this message translates to:
  /// **'최근 연속'**
  String get milestoneStreakLabel;

  /// 성장 마일스톤 화면 - 통계, 누적 점수 라벨
  ///
  /// In ko, this message translates to:
  /// **'누적 점수'**
  String get milestoneScoreLabel;

  /// 성장 마일스톤 화면 - 통계, 남긴 이야기(다이어리) 개수 라벨
  ///
  /// In ko, this message translates to:
  /// **'남긴 이야기'**
  String get milestoneDiaryCountLabel;

  /// 성장 마일스톤 화면 - 통계, 남긴 이야기 개수 수치
  ///
  /// In ko, this message translates to:
  /// **'{count}개'**
  String milestoneDiaryCountStat(int count);

  /// 성장 마일스톤 화면 - 감정 인사이트 카드 제목
  ///
  /// In ko, this message translates to:
  /// **'이 나무와 함께한 마음들'**
  String get milestoneInsightTitle;

  /// 성장 마일스톤 화면 - 감정 인사이트, 자주 만난 감정 및 횟수
  ///
  /// In ko, this message translates to:
  /// **'{label} {count}번'**
  String milestoneEmotionCountLabel(String label, int count);

  /// 성장 마일스톤 화면 - 감정 인사이트, 가장 개선된 감정 안내
  ///
  /// In ko, this message translates to:
  /// **'처음엔 {label}을(를) 자주 만났는데,\n최근엔 훨씬 줄었어요. 마음이 조금 편해졌나 봐요.'**
  String milestoneImprovedText(String label);

  /// 성장 마일스톤 화면 - 감정 인사이트, 아직 만나지 못한 감정 개수 안내
  ///
  /// In ko, this message translates to:
  /// **'아직 만나지 못한 마음이 {count}가지 있어요.\n다음 나무에서 만나볼까요? 🌳'**
  String milestoneUncollectedText(int count);

  /// 성장 마일스톤 화면 - 타임라인이 비었을 때 안내 문구
  ///
  /// In ko, this message translates to:
  /// **'아직 남겨진 한 줄 이야기는 없지만,\n마주한 감정들이 모여 이 나무를 키워냈어요 🌳'**
  String get milestoneEmptyTimelineText;

  /// 성장 마일스톤 화면 - 마무리 카드, 몽이의 인용문
  ///
  /// In ko, this message translates to:
  /// **'\"고마워, 나를 여기까지 데려와줘서.\n앞으로도 어떤 마음이든\n네 옆에서 함께 지켜볼게.\"'**
  String get milestoneClosingQuote;

  /// 성장 마일스톤 화면 - 마무리 카드, 공유 버튼 라벨
  ///
  /// In ko, this message translates to:
  /// **'이 순간을 카드로 공유하기'**
  String get milestoneShareButtonLabel;

  /// 성장 마일스톤 화면 - 타임라인 항목, 날짜와 먹은 개수
  ///
  /// In ko, this message translates to:
  /// **'{date} · {count}개'**
  String milestoneTimelineDateCount(String date, int count);

  /// 성장 마일스톤 화면 - 타임라인 항목, 한 줄 기록 인용
  ///
  /// In ko, this message translates to:
  /// **'\"{note}\"'**
  String milestoneTimelineNoteQuote(String note);

  /// 심호흡 인터스티셜 - 안내 문구
  ///
  /// In ko, this message translates to:
  /// **'잠깐, 몽이와 함께 숨을 천천히 골라볼까요?'**
  String get breathingPromptText;

  /// 심호흡 인터스티셜 - 들이쉬는 중 라벨
  ///
  /// In ko, this message translates to:
  /// **'들이쉬고...'**
  String get breathingInhaleLabel;

  /// 심호흡 인터스티셜 - 내쉬는 중 라벨
  ///
  /// In ko, this message translates to:
  /// **'내쉬고...'**
  String get breathingExhaleLabel;

  /// 심호흡 인터스티셜 - 숨을 잠깐 멈춰 유지하는 중 라벨(박스 호흡 등 holdAfterInhale/holdAfterExhale이 있는 기법에서 사용)
  ///
  /// In ko, this message translates to:
  /// **'멈추고...'**
  String get breathingHoldLabel;

  /// 주간 리포트 화면 - 공유 시 함께 보내는 문구
  ///
  /// In ko, this message translates to:
  /// **'이번 주 몽이와 함께한 감정 리포트예요 🌱 #몽이 #마음정원'**
  String get weeklyReportShareText;

  /// 주간 리포트 화면 - 리포트 공유 버튼 라벨
  ///
  /// In ko, this message translates to:
  /// **'이번 주 리포트 공유하기'**
  String get weeklyReportShareButton;

  /// 주간 리포트 화면 - 데이터 부족 카드 제목
  ///
  /// In ko, this message translates to:
  /// **'아직 데이터가 모이고 있어요'**
  String get weeklyReportNotEnoughTitle;

  /// 주간 리포트 화면 - 데이터 부족 카드 본문
  ///
  /// In ko, this message translates to:
  /// **'몽이와 조금 더 함께해주면\n이번 주 이야기를 들려드릴게요'**
  String get weeklyReportNotEnoughBody;

  /// 주간 리포트 화면 - 카드 헤더, 함께한 횟수
  ///
  /// In ko, this message translates to:
  /// **'함께한 {count}번'**
  String weeklyReportSessionsLabel(int count);

  /// 주간 리포트 화면 - 카드 내, 만난 감정 목록 제목
  ///
  /// In ko, this message translates to:
  /// **'이번 주 만난 마음들'**
  String get weeklyReportEmotionsSectionTitle;

  /// 주간 리포트 화면 - 카드 내, 감정 아이콘+이름+횟수 태그
  ///
  /// In ko, this message translates to:
  /// **'{icon} {label} {count}'**
  String weeklyReportEmotionTag(String icon, String label, int count);

  /// 주간 리포트 화면 - 긍정/부정 비율 바, 부정 비율
  ///
  /// In ko, this message translates to:
  /// **'부정 {percent}%'**
  String weeklyReportNegativeLabel(int percent);

  /// 주간 리포트 화면 - 지난주 긍정 비율 안내
  ///
  /// In ko, this message translates to:
  /// **'지난주 긍정 비율: {percent}%'**
  String weeklyReportPreviousRatioLabel(int percent);

  /// 정원 꾸미기 시트 - 헤더 타이틀
  ///
  /// In ko, this message translates to:
  /// **'🎨 정원 꾸미기'**
  String get gardenDecoSheetTitle;

  /// 정원 꾸미기 시트 - 헤더 부제목
  ///
  /// In ko, this message translates to:
  /// **'잠금 해제된 아이템을 탭해서 장착/해제할 수 있어요'**
  String get gardenDecoSheetSubtitle;

  /// 정원 꾸미기 시트 - 무료 아이템 섹션 라벨
  ///
  /// In ko, this message translates to:
  /// **'무료 아이템 · 마일스톤 달성으로 잠금 해제'**
  String get gardenDecoFreeSectionLabel;

  /// 정원 꾸미기 시트 - 프리미엄 아이템 섹션 라벨
  ///
  /// In ko, this message translates to:
  /// **'프리미엄 아이템 · 정원 장식팩'**
  String get gardenDecoPremiumSectionLabel;

  /// 정원 꾸미기 시트 - 이전 구매 복원 버튼
  ///
  /// In ko, this message translates to:
  /// **'이전 구매 복원하기'**
  String get gardenDecoRestoreButton;

  /// 정원 꾸미기 시트 - 프리미엄 아이템 뱃지
  ///
  /// In ko, this message translates to:
  /// **'PRO'**
  String get gardenDecoProBadge;

  /// 정원 꾸미기 시트 - 아이템 장착 중 상태 문구
  ///
  /// In ko, this message translates to:
  /// **'지금 정원에 놓여 있어요'**
  String get gardenDecoEquippedStatus;

  /// 정원 꾸미기 시트 - 아이템 미장착 상태(잠금 해제됨) 문구
  ///
  /// In ko, this message translates to:
  /// **'탭해서 정원에 놓아보세요'**
  String get gardenDecoTapToPlaceStatus;

  /// 정원 꾸미기 시트 - 아이템별 진행 상황 뱃지
  ///
  /// In ko, this message translates to:
  /// **'📍 {progress}'**
  String gardenDecoProgressBadge(String progress);

  /// 정원 꾸미기 시트 - 나무 벤치(bench) 잠금 해제 진행 문구
  ///
  /// In ko, this message translates to:
  /// **'3일 연속 중 {days}일째'**
  String gardenDecoProgressBench(int days);

  /// 정원 꾸미기 시트 - 조약돌 오솔길(path) 잠금 해제 진행 문구
  ///
  /// In ko, this message translates to:
  /// **'마음정원 회복도 {percent}% (100%가 되면 해제)'**
  String gardenDecoProgressPath(int percent);

  /// 정원 꾸미기 시트 - 작은 분수대(fountain) 잠금 해제 진행 문구(모든 씨앗 심음)
  ///
  /// In ko, this message translates to:
  /// **'{planted}/3종 심음'**
  String gardenDecoProgressFountainPlanted(int planted);

  /// 정원 꾸미기 시트 - 작은 분수대(fountain) 잠금 해제 진행 문구(남은 씨앗 있음)
  ///
  /// In ko, this message translates to:
  /// **'{planted}/3종 심음 · 남은 씨앗: {missing}'**
  String gardenDecoProgressFountainWithMissing(int planted, String missing);

  /// 씨앗 종류 이름 - 용서
  ///
  /// In ko, this message translates to:
  /// **'용서'**
  String get gardenSeedNameForgiveness;

  /// 씨앗 종류 이름 - 사랑
  ///
  /// In ko, this message translates to:
  /// **'사랑'**
  String get gardenSeedNameLove;

  /// 씨앗 종류 이름 - 평안
  ///
  /// In ko, this message translates to:
  /// **'평안'**
  String get gardenSeedNamePeace;

  /// 씨앗 종류 설명 - 용서
  ///
  /// In ko, this message translates to:
  /// **'마음에 맺힌 것을 놓아주는 씨앗'**
  String get gardenSeedDescForgiveness;

  /// 씨앗 종류 설명 - 사랑
  ///
  /// In ko, this message translates to:
  /// **'따뜻함을 나누는 씨앗'**
  String get gardenSeedDescLove;

  /// 씨앗 종류 설명 - 평안
  ///
  /// In ko, this message translates to:
  /// **'고요하고 잔잔한 마음의 씨앗'**
  String get gardenSeedDescPeace;

  /// 정원 장식 이름 - 나무 벤치
  ///
  /// In ko, this message translates to:
  /// **'나무 벤치'**
  String get gardenDecoLabelBench;

  /// 정원 장식 잠금 해제 안내 - 나무 벤치
  ///
  /// In ko, this message translates to:
  /// **'3일 연속 몽이를 만나면 잠금 해제돼요'**
  String get gardenDecoUnlockHintBench;

  /// 정원 장식 이름 - 조약돌 오솔길
  ///
  /// In ko, this message translates to:
  /// **'조약돌 오솔길'**
  String get gardenDecoLabelPath;

  /// 정원 장식 잠금 해제 안내 - 조약돌 오솔길
  ///
  /// In ko, this message translates to:
  /// **'정원을 처음 만개시키면 잠금 해제돼요'**
  String get gardenDecoUnlockHintPath;

  /// 정원 장식 이름 - 작은 분수대
  ///
  /// In ko, this message translates to:
  /// **'작은 분수대'**
  String get gardenDecoLabelFountain;

  /// 정원 장식 잠금 해제 안내 - 작은 분수대
  ///
  /// In ko, this message translates to:
  /// **'용서·사랑·평안 씨앗을 모두 심으면 잠금 해제돼요'**
  String get gardenDecoUnlockHintFountain;

  /// 정원 장식 이름 - 종이등
  ///
  /// In ko, this message translates to:
  /// **'종이등'**
  String get gardenDecoLabelLantern;

  /// 정원 장식 이름 - 무지개 울타리
  ///
  /// In ko, this message translates to:
  /// **'무지개 울타리'**
  String get gardenDecoLabelRainbowFence;

  /// 정원 장식 이름 - 반짝이는 별빛
  ///
  /// In ko, this message translates to:
  /// **'반짝이는 별빛'**
  String get gardenDecoLabelStarLight;

  /// 정원 장식 잠금 해제 안내 - 프리미엄 장식팩 공통 문구
  ///
  /// In ko, this message translates to:
  /// **'정원 장식팩을 구매하면 사용할 수 있어요'**
  String get gardenDecoUnlockHintPremiumPack;

  /// 정원 장식 이름 - 풍경 윈드차임
  ///
  /// In ko, this message translates to:
  /// **'풍경 윈드차임'**
  String get gardenDecoLabelWindChime;

  /// 정원 장식 잠금 해제 안내 - 풍경 윈드차임
  ///
  /// In ko, this message translates to:
  /// **'7일 연속 몽이를 만나면 잠금 해제돼요'**
  String get gardenDecoUnlockHintWindChime;

  /// 정원 장식 이름 - 나비 정원
  ///
  /// In ko, this message translates to:
  /// **'나비 정원'**
  String get gardenDecoLabelButterflyGarden;

  /// 정원 장식 잠금 해제 안내 - 나비 정원
  ///
  /// In ko, this message translates to:
  /// **'감정을 3개 이상 마스터 등급으로 키우면 잠금 해제돼요'**
  String get gardenDecoUnlockHintButterflyGarden;

  /// 정원 장식 이름 - 아늑한 정자
  ///
  /// In ko, this message translates to:
  /// **'아늑한 정자'**
  String get gardenDecoLabelGazebo;

  /// 정원 장식 이름 - 연꽃 연못
  ///
  /// In ko, this message translates to:
  /// **'연꽃 연못'**
  String get gardenDecoLabelLotusPond;

  /// 정원 장식 이름 - 장독대
  ///
  /// In ko, this message translates to:
  /// **'장독대'**
  String get gardenDecoLabelJangdokdae;

  /// 정원 장식 잠금 해제 안내 - 장독대
  ///
  /// In ko, this message translates to:
  /// **'꽃을 10번 이상 피우면 잠금 해제돼요'**
  String get gardenDecoUnlockHintJangdokdae;

  /// 정원 장식 이름 - 은행나무길
  ///
  /// In ko, this message translates to:
  /// **'은행나무길'**
  String get gardenDecoLabelGinkgoPath;

  /// 정원 장식 잠금 해제 안내 - 은행나무길
  ///
  /// In ko, this message translates to:
  /// **'14일 연속 몽이를 만나면 잠금 해제돼요'**
  String get gardenDecoUnlockHintGinkgoPath;

  /// 정원 장식 이름 - 한옥 처마등
  ///
  /// In ko, this message translates to:
  /// **'한옥 처마등'**
  String get gardenDecoLabelHanokLantern;

  /// 정원 꾸미기 시트 - 잠긴 아이템 탭 시 스낵바(진행 상황 포함)
  ///
  /// In ko, this message translates to:
  /// **'{hint}\n(현재: {progress})'**
  String gardenDecoUnlockHintWithProgress(String hint, String progress);

  /// 정원 꾸미기 시트 - 구매 확인 다이얼로그 제목
  ///
  /// In ko, this message translates to:
  /// **'정원 장식팩 구매'**
  String get gardenDecoPurchaseDialogTitle;

  /// 정원 꾸미기 시트 - 구매 확인 다이얼로그 본문
  ///
  /// In ko, this message translates to:
  /// **'종이등 🏮 · 무지개 울타리 🌈 · 반짝이는 별빛 ✨\n3가지 장식을 한 번에 잠금 해제해서 몽이의 정원을 더 예쁘게 꾸며보세요.\n\n한 번 구매하면 계속 사용할 수 있어요.'**
  String get gardenDecoPurchaseDialogBody;

  /// 정원 꾸미기 시트 - 결제 시작 실패 안내 스낵바
  ///
  /// In ko, this message translates to:
  /// **'결제를 시작할 수 없어요. 잠시 후 다시 시도해주세요.'**
  String get gardenDecoPurchaseFailedSnackbar;

  /// 마음 상자 화면 - 이미 모든 코스튬을 모았을 때 스낵바
  ///
  /// In ko, this message translates to:
  /// **'🎉 몽이의 선물을 이미 모두 모았어요!'**
  String get mindBoxAllCollectedSnackbar;

  /// 마음 상자 화면 - 빛의 정수 부족 안내 스낵바
  ///
  /// In ko, this message translates to:
  /// **'💡 빛의 정수가 부족해요. 엔드리스 모드로 더 모아볼까요?'**
  String get mindBoxNotEnoughEssenceSnackbar;

  /// 마음 상자 화면 - 헤더 타이틀
  ///
  /// In ko, this message translates to:
  /// **'🎁 마음 상자'**
  String get mindBoxHeaderTitle;

  /// 마음 상자 화면 - 수집 진행률 카드, 모두 모았을 때 타이틀
  ///
  /// In ko, this message translates to:
  /// **'🎉 몽이의 선물을 모두 모았어요!'**
  String get mindBoxAllCollectedTitle;

  /// 마음 상자 화면 - 수집 진행률 카드, 기본 안내 타이틀
  ///
  /// In ko, this message translates to:
  /// **'상자를 열면 항상 새로운 선물을 만나요'**
  String get mindBoxOpenHintTitle;

  /// 마음 상자 화면 - 수집 진행률 카드, 도감 진행 상황 텍스트
  ///
  /// In ko, this message translates to:
  /// **'도감 {owned} / {total} · 지금까지 연 상자 {totalPulls}개'**
  String mindBoxCollectionProgressLabel(int owned, int total, int totalPulls);

  /// 마음 상자 화면 - 상자 1개 열기 버튼
  ///
  /// In ko, this message translates to:
  /// **'상자 1개 열기'**
  String get mindBoxOpenOneButton;

  /// 마음 상자 화면 - 묶음 열기 버튼(개수 표시)
  ///
  /// In ko, this message translates to:
  /// **'상자 {count}개 열기'**
  String mindBoxOpenBulkButtonCount(int count);

  /// 마음 상자 화면 - 묶음 열기 버튼(개수 미표시, 남은 선물 1개 이하일 때)
  ///
  /// In ko, this message translates to:
  /// **'상자 여러 개 열기'**
  String get mindBoxOpenBulkButtonGeneric;

  /// 마음 상자 화면 - 코스튬 도감 섹션 타이틀
  ///
  /// In ko, this message translates to:
  /// **'🐾 몽이 코스튬 도감'**
  String get mindBoxCollectionSectionTitle;

  /// 마음 상자 화면 - 코스튬 타일, 장착중 뱃지
  ///
  /// In ko, this message translates to:
  /// **'장착중'**
  String get mindBoxEquippedBadge;

  /// 마음 상자 화면 - 결과 시트 타이틀(레전더리 등급 포함)
  ///
  /// In ko, this message translates to:
  /// **'🌟 정말 특별한 선물이 왔어요!'**
  String get mindBoxResultTitleLegendary;

  /// 마음 상자 화면 - 결과 시트 타이틀(일반)
  ///
  /// In ko, this message translates to:
  /// **'🎁 마음 상자를 열었어요'**
  String get mindBoxResultTitleNormal;

  /// 마음 상자 화면 - 결과 시트 확인 버튼
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get mindBoxConfirmButton;

  /// 마음 상자 화면 - 결과 카드, 새 옷 획득 안내(단일 결과)
  ///
  /// In ko, this message translates to:
  /// **'✨ NEW! 새로운 옷을 얻었어요'**
  String get mindBoxNewItemLabel;

  /// 코스튬 희귀도 - 일반
  ///
  /// In ko, this message translates to:
  /// **'일반'**
  String get mindBoxRarityCommon;

  /// 코스튬 희귀도 - 레어
  ///
  /// In ko, this message translates to:
  /// **'레어'**
  String get mindBoxRarityRare;

  /// 코스튬 희귀도 - 에픽
  ///
  /// In ko, this message translates to:
  /// **'에픽'**
  String get mindBoxRarityEpic;

  /// 코스튬 희귀도 - 레전더리
  ///
  /// In ko, this message translates to:
  /// **'레전더리'**
  String get mindBoxRarityLegendary;

  /// 몽이 코스튬 이름 - 핑크 리본
  ///
  /// In ko, this message translates to:
  /// **'핑크 리본'**
  String get mongiCostumeNameRibbon;

  /// 몽이 코스튬 이름 - 별빛 머리띠
  ///
  /// In ko, this message translates to:
  /// **'별빛 머리띠'**
  String get mongiCostumeNameStarBand;

  /// 몽이 코스튬 이름 - 무지개 목도리
  ///
  /// In ko, this message translates to:
  /// **'무지개 목도리'**
  String get mongiCostumeNameScarf;

  /// 몽이 코스튬 이름 - 토끼 귀 머리띠
  ///
  /// In ko, this message translates to:
  /// **'토끼 귀 머리띠'**
  String get mongiCostumeNameBunnyEars;

  /// 몽이 코스튬 이름 - 데이지 화관
  ///
  /// In ko, this message translates to:
  /// **'데이지 화관'**
  String get mongiCostumeNameFlowerCrown;

  /// 몽이 코스튬 이름 - 별빛 마법사 모자
  ///
  /// In ko, this message translates to:
  /// **'별빛 마법사 모자'**
  String get mongiCostumeNameWizardHat;

  /// 몽이 코스튬 이름 - 황금 왕관
  ///
  /// In ko, this message translates to:
  /// **'황금 왕관'**
  String get mongiCostumeNameGoldenCrown;

  /// 몽이 코스튬 이름 - 뭉게구름 머리띠
  ///
  /// In ko, this message translates to:
  /// **'뭉게구름 머리띠'**
  String get mongiCostumeNameCloudBand;

  /// 몽이 코스튬 이름 - 해바라기 머리띠
  ///
  /// In ko, this message translates to:
  /// **'해바라기 머리띠'**
  String get mongiCostumeNameSunflowerBand;

  /// 몽이 코스튬 이름 - 천사의 날개
  ///
  /// In ko, this message translates to:
  /// **'천사의 날개'**
  String get mongiCostumeNameAngelWings;

  /// 몽이 코스튬 이름 - 꼬마 해적 모자
  ///
  /// In ko, this message translates to:
  /// **'꼬마 해적 모자'**
  String get mongiCostumeNamePirateHat;

  /// 몽이 코스튬 이름 - 은하수 망토
  ///
  /// In ko, this message translates to:
  /// **'은하수 망토'**
  String get mongiCostumeNameGalaxyCape;

  /// 몽이 코스튬 이름 - 불사조의 왕관
  ///
  /// In ko, this message translates to:
  /// **'불사조의 왕관'**
  String get mongiCostumeNamePhoenixCrown;

  /// 몽이 코스튬 이름 - 색동 리본
  ///
  /// In ko, this message translates to:
  /// **'색동 리본'**
  String get mongiCostumeNameSaekdongRibbon;

  /// 몽이 코스튬 이름 - 복주머니 머리띠
  ///
  /// In ko, this message translates to:
  /// **'복주머니 머리띠'**
  String get mongiCostumeNameBokjumeoni;

  /// 몽이 코스튬 이름 - 새싹 머리띠
  ///
  /// In ko, this message translates to:
  /// **'새싹 머리띠'**
  String get mongiCostumeNameSproutHat;

  /// 엔드리스 결과 화면 - 생존 시간 표시(분+초)
  ///
  /// In ko, this message translates to:
  /// **'{minutes}분 {seconds}초'**
  String endlessResultTimeMinSec(int minutes, int seconds);

  /// 엔드리스 결과 화면 - 생존 시간 표시(초만)
  ///
  /// In ko, this message translates to:
  /// **'{seconds}초'**
  String endlessResultTimeSecOnly(int seconds);

  /// 엔드리스 결과 화면 - 신기록 달성 뱃지
  ///
  /// In ko, this message translates to:
  /// **'🏆 오늘 새로운 최고 기록!'**
  String get endlessResultNewRecordBadge;

  /// 엔드리스 결과 화면 - 결과 카드 타이틀
  ///
  /// In ko, this message translates to:
  /// **'오늘의 도전 결과'**
  String get endlessResultCardTitle;

  /// 엔드리스 결과 화면 - 먹은 감정 개수 통계 라벨
  ///
  /// In ko, this message translates to:
  /// **'마주한 감정'**
  String get endlessResultEatenCountLabel;

  /// 엔드리스 결과 화면 - 먹은 감정 개수 통계 값
  ///
  /// In ko, this message translates to:
  /// **'{count}개'**
  String endlessResultEatenCountValue(int count);

  /// 엔드리스 결과 화면 - 생존 시간 통계 라벨
  ///
  /// In ko, this message translates to:
  /// **'생존 시간'**
  String get endlessResultSurvivedTimeLabel;

  /// 엔드리스 결과 화면 - 최고기록 라벨
  ///
  /// In ko, this message translates to:
  /// **'👑 내 최고기록'**
  String get endlessResultBestRecordLabel;

  /// 엔드리스 결과 화면 - 최고기록 값(개수+시간)
  ///
  /// In ko, this message translates to:
  /// **'{count}개 · {time}'**
  String endlessResultBestRecordValue(int count, String time);

  /// 엔드리스 결과 화면 - 순위보다 소중한 시간 안내문
  ///
  /// In ko, this message translates to:
  /// **'순위보다 소중한 건, 오늘도\n몽이와 함께 마음을 마주한 시간이에요 🤍'**
  String get endlessResultRankingFooter;

  /// 엔드리스 결과 화면 - 다시 도전하기 버튼
  ///
  /// In ko, this message translates to:
  /// **'다시 도전하기 🐾'**
  String get endlessResultRetryButton;

  /// 일일 미션 시트 - 미션 보상 수령 스낵바
  ///
  /// In ko, this message translates to:
  /// **'{emoji} 빛의 정수 +{amount} 받았어요!'**
  String dailyMissionClaimedSnackbar(String emoji, int amount);

  /// 일일 미션 시트 - 올클리어 보너스 수령 스낵바
  ///
  /// In ko, this message translates to:
  /// **'🎉 올클리어 보너스를 받았어요!'**
  String get dailyMissionAllClearSnackbar;

  /// 일일 미션 시트 - 상단 작은 라벨
  ///
  /// In ko, this message translates to:
  /// **'몽이의 오늘 미션'**
  String get dailyMissionSheetLabel;

  /// 일일 미션 라벨 - eat_emotions
  ///
  /// In ko, this message translates to:
  /// **'감정 몬스터 {target}개 마주하기'**
  String dailyMissionLabelEatEmotions(int target);

  /// 일일 미션 라벨 - complete_stage
  ///
  /// In ko, this message translates to:
  /// **'스테이지 {target}번 끝까지 완료하기'**
  String dailyMissionLabelCompleteStage(int target);

  /// 일일 미션 라벨 - plant_love
  ///
  /// In ko, this message translates to:
  /// **'마음 {target}번 심기'**
  String dailyMissionLabelPlantLove(int target);

  /// 일일 미션 시트 - 헤더 타이틀
  ///
  /// In ko, this message translates to:
  /// **'오늘 하루, 이만큼만 더 함께해요'**
  String get dailyMissionSheetTitle;

  /// 일일 미션 시트 - 미션 카드 진행률 + 보상 표시
  ///
  /// In ko, this message translates to:
  /// **'{progress} / {target}  ·  💡+{reward}'**
  String dailyMissionProgressWithReward(int progress, int target, int reward);

  /// 일일 미션 시트 - 보상 받기 버튼
  ///
  /// In ko, this message translates to:
  /// **'받기'**
  String get dailyMissionClaimButton;

  /// 일일 미션 시트 - 올클리어 보너스 카드 타이틀
  ///
  /// In ko, this message translates to:
  /// **'올클리어 보너스'**
  String get dailyMissionAllClearCardTitle;

  /// 일일 미션 시트 - 올클리어 보너스 이미 수령했을 때 문구
  ///
  /// In ko, this message translates to:
  /// **'오늘 이미 받았어요, 내일 또 만나요!'**
  String get dailyMissionAllClearAlreadyClaimed;

  /// 일일 미션 시트 - 올클리어 보너스 진행 상황 문구
  ///
  /// In ko, this message translates to:
  /// **'미션 {claimed}/{total} 완료 · 💡+{lightEssence} ⭐+{starShard}'**
  String dailyMissionAllClearProgress(
    int claimed,
    int total,
    int lightEssence,
    int starShard,
  );

  /// 안전 계획 화면 - 섹션 저장 완료 스낵바
  ///
  /// In ko, this message translates to:
  /// **'저장했어요 🤍'**
  String get safetyPlanSavedSnackbar;

  /// 안전 계획 화면 - 109 전화 연결 실패 스낵바
  ///
  /// In ko, this message translates to:
  /// **'전화 연결에 실패했어요. 109로 직접 걸어주세요.'**
  String get safetyPlanCallFailedSnackbar;

  /// 안전 계획 화면 - 상단 헤더 타이틀
  ///
  /// In ko, this message translates to:
  /// **'🧭 나만의 안전 계획'**
  String get safetyPlanHeaderTitle;

  /// 안전 계획 화면 - 인트로 카드 첫 번째 문장
  ///
  /// In ko, this message translates to:
  /// **'마음이 편안한 지금, 미래의 나를 위해\n짧은 메모를 미리 남겨두는 공간이에요.'**
  String get safetyPlanIntroLine1;

  /// 안전 계획 화면 - 인트로 카드 두 번째 문장(안내/프라이버시)
  ///
  /// In ko, this message translates to:
  /// **'나중에 마음이 힘들어졌을 때, 무엇부터 해야 할지 떠올리기 어려운 순간이\n있어요. 그럴 때 이 페이지를 펼쳐보면 스스로 적어둔 답을 바로 볼 수 있어요.\n작성한 내용은 이 기기에만 저장되고, 몽이도 다른 누구도 보지 않아요.'**
  String get safetyPlanIntroLine2;

  /// 안전 계획 화면 - 섹션 저장 버튼
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get safetyPlanSaveButton;

  /// 안전 계획 화면 - 아직 작성 안 한 섹션의 안내 placeholder + 힌트
  ///
  /// In ko, this message translates to:
  /// **'{placeholder}\n(눌러서 작성하기)'**
  String safetyPlanTapToWriteHint(String placeholder);

  /// 안전 계획 화면 - 하단 긴급 연락 카드 타이틀
  ///
  /// In ko, this message translates to:
  /// **'지금 당장 힘들다면'**
  String get safetyPlanEmergencyTitle;

  /// 안전 계획 화면 - 하단 긴급 연락 카드 부제(109 안내)
  ///
  /// In ko, this message translates to:
  /// **'109(자살예방상담전화)로 바로 연결할게요'**
  String get safetyPlanEmergencySubtitle;

  /// 안전 계획 화면 - 비한국어(영어) 로케일 전용 긴급 연락 카드 부제(109 대신 글로벌 디렉토리 안내)
  ///
  /// In ko, this message translates to:
  /// **'Find A Helpline에서 내 국가의 상담 채널을 바로 찾아드릴게요'**
  String get safetyPlanGlobalEmergencySubtitle;

  /// 안전 계획 화면 - 비한국어 로케일 전용 긴급 연락 카드 버튼 라벨(전화 대신 링크 열기)
  ///
  /// In ko, this message translates to:
  /// **'열기'**
  String get safetyPlanGlobalButtonLabel;

  /// 안전 계획 화면 - 비한국어 로케일 전용 링크 열기 실패 안내(109 전화 실패와 별도)
  ///
  /// In ko, this message translates to:
  /// **'페이지를 여는 데 실패했어요. findahelpline.com으로 직접 방문해주세요.'**
  String get safetyPlanGlobalOpenFailedSnackbar;

  /// 안전 계획 화면 - '위험 신호' 섹션 제목
  ///
  /// In ko, this message translates to:
  /// **'나에게 위험 신호가 되는 것들'**
  String get safetyPlanSectionWarningSignsTitle;

  /// 안전 계획 화면 - '위험 신호' 섹션 설명
  ///
  /// In ko, this message translates to:
  /// **'이런 생각·기분·상황이 나타나면 \"지금 조심해야 할 때\"라는 뜻이에요.'**
  String get safetyPlanSectionWarningSignsHint;

  /// 안전 계획 화면 - '위험 신호' 섹션 입력 예시
  ///
  /// In ko, this message translates to:
  /// **'예) 며칠째 잠을 못 잘 때, \"다 소용없다\"는 생각이 들 때...'**
  String get safetyPlanSectionWarningSignsPlaceholder;

  /// 안전 계획 화면 - '스스로 대처하는 법' 섹션 제목
  ///
  /// In ko, this message translates to:
  /// **'혼자서 마음을 가라앉히는 나만의 방법'**
  String get safetyPlanSectionCopingStrategiesTitle;

  /// 안전 계획 화면 - '스스로 대처하는 법' 섹션 설명
  ///
  /// In ko, this message translates to:
  /// **'다른 사람 도움 없이도 스스로 해볼 수 있는 것들이에요.'**
  String get safetyPlanSectionCopingStrategiesHint;

  /// 안전 계획 화면 - '스스로 대처하는 법' 섹션 입력 예시
  ///
  /// In ko, this message translates to:
  /// **'예) 좋아하는 노래 듣기, 산책하기, 몽이랑 감정 정리하기...'**
  String get safetyPlanSectionCopingStrategiesPlaceholder;

  /// 안전 계획 화면 - '도움 요청할 사람들' 섹션 제목
  ///
  /// In ko, this message translates to:
  /// **'도움을 요청할 수 있는 사람들'**
  String get safetyPlanSectionSupportPeopleTitle;

  /// 안전 계획 화면 - '도움 요청할 사람들' 섹션 설명
  ///
  /// In ko, this message translates to:
  /// **'이름과 연락처를 적어두면, 힘든 순간에 찾아보기 쉬워져요.'**
  String get safetyPlanSectionSupportPeopleHint;

  /// 안전 계획 화면 - '도움 요청할 사람들' 섹션 입력 예시
  ///
  /// In ko, this message translates to:
  /// **'예) 친구 OOO (010-xxxx-xxxx), 언니, 상담 선생님...'**
  String get safetyPlanSectionSupportPeoplePlaceholder;

  /// 안전 계획 화면 - '안전한 장소' 섹션 제목
  ///
  /// In ko, this message translates to:
  /// **'마음이 편안해지는 장소'**
  String get safetyPlanSectionSafePlaceTitle;

  /// 안전 계획 화면 - '안전한 장소' 섹션 설명
  ///
  /// In ko, this message translates to:
  /// **'잠깐이라도 머물면 마음이 조금 놓이는 곳이 있나요?'**
  String get safetyPlanSectionSafePlaceHint;

  /// 안전 계획 화면 - '안전한 장소' 섹션 입력 예시
  ///
  /// In ko, this message translates to:
  /// **'예) 동네 카페, 가족이 있는 집, 근처 공원 벤치...'**
  String get safetyPlanSectionSafePlacePlaceholder;

  /// 안전 계획 화면 - '소중한 것들/살아야 할 이유' 섹션 제목
  ///
  /// In ko, this message translates to:
  /// **'나에게 소중한 것들 / 살아야 할 이유'**
  String get safetyPlanSectionReasonsToLiveTitle;

  /// 안전 계획 화면 - '소중한 것들/살아야 할 이유' 섹션 설명
  ///
  /// In ko, this message translates to:
  /// **'힘든 순간일수록 잊기 쉬운, 나에게 정말 소중한 것들을 적어두세요.'**
  String get safetyPlanSectionReasonsToLiveHint;

  /// 안전 계획 화면 - '소중한 것들/살아야 할 이유' 섹션 입력 예시
  ///
  /// In ko, this message translates to:
  /// **'예) 우리 강아지, 내년에 가고 싶은 여행, 사랑하는 가족...'**
  String get safetyPlanSectionReasonsToLivePlaceholder;

  /// 파워 부적 상점 시트 - 1개 구매 완료 스낵바
  ///
  /// In ko, this message translates to:
  /// **'⚡ 파워 부적 1개를 얻었어요!'**
  String get powerCharmBoughtOneSnackbar;

  /// 파워 부적 상점 시트 - 묶음 구매 완료 스낵바
  ///
  /// In ko, this message translates to:
  /// **'⚡ 파워 부적 {count}개를 얻었어요!'**
  String powerCharmBoughtBulkSnackbar(int count);

  /// 파워 부적 상점 시트 - 빛의 정수 부족 안내 스낵바
  ///
  /// In ko, this message translates to:
  /// **'💡 빛의 정수가 부족해요.'**
  String get powerCharmNotEnoughSnackbar;

  /// 파워 부적 상점 시트 - 카드 타이틀
  ///
  /// In ko, this message translates to:
  /// **'파워 부적'**
  String get powerCharmTitle;

  /// 파워 부적 상점 시트 - 효과 설명 + 보유 개수
  ///
  /// In ko, this message translates to:
  /// **'게임 중 언제든 써서 10초간 무적이 돼요\n지금 보유: {count}개'**
  String powerCharmDescription(int count);

  /// 파워 부적 상점 시트 - 1개 구매 버튼 라벨
  ///
  /// In ko, this message translates to:
  /// **'부적 1개'**
  String get powerCharmBuyOneLabel;

  /// 파워 부적 상점 시트 - 묶음 구매 버튼 라벨
  ///
  /// In ko, this message translates to:
  /// **'부적 {count}개'**
  String powerCharmBuyBulkLabel(int count);

  /// 호흡 순간 미니게임 시트 - 상단 안내 타이틀
  ///
  /// In ko, this message translates to:
  /// **'숨결 구슬을 만났어요'**
  String get breathingMomentTitle;

  /// 호흡 순간 미니게임 시트 - 들이쉬기(화면 누르기) 단계 안내
  ///
  /// In ko, this message translates to:
  /// **'들이쉬며 꾹 눌러요'**
  String get breathingMomentInhaleLabel;

  /// 호흡 순간 미니게임 시트 - 내쉬기(손 떼기) 단계 안내
  ///
  /// In ko, this message translates to:
  /// **'내쉬며 손을 떼요'**
  String get breathingMomentExhaleLabel;

  /// 가이드 호흡/명상 미니 라이브러리 화면 - 상단 헤더 타이틀
  ///
  /// In ko, this message translates to:
  /// **'🌬️ 몽이의 숨결 도감'**
  String get breathingLibraryHeaderTitle;

  /// 가이드 호흡/명상 미니 라이브러리 화면 - 소개 부제목
  ///
  /// In ko, this message translates to:
  /// **'지금 마음에 맞는 호흡을 골라 몽이와 천천히 따라해보세요.'**
  String get breathingLibrarySubtitle;

  /// 가이드 호흡/명상 미니 라이브러리 화면 - 기법 카드의 예상 소요 시간
  ///
  /// In ko, this message translates to:
  /// **'약 {seconds}초'**
  String breathingLibraryDurationLabel(int seconds);

  /// 가이드 호흡/명상 미니 라이브러리 화면 - 기법 카드의 시작 버튼
  ///
  /// In ko, this message translates to:
  /// **'시작하기'**
  String get breathingLibraryStartButton;

  /// 가이드 호흡/명상 미니 라이브러리 화면 - 오늘 이미 보상을 받은 기법에 표시되는 뱃지
  ///
  /// In ko, this message translates to:
  /// **'오늘 완료 ✓'**
  String get breathingLibraryCompletedTodayBadge;

  /// 가이드 호흡/명상 미니 라이브러리 화면 - 기법 카드의 보상 안내
  ///
  /// In ko, this message translates to:
  /// **'오늘 처음 끝까지 마치면 💡{reward} 지급'**
  String breathingLibraryRewardHint(int reward);

  /// 가이드 호흡/명상 미니 라이브러리 화면 - 완료 후 보상 획득 스낵바
  ///
  /// In ko, this message translates to:
  /// **'잘했어요 🌿 오늘의 첫 호흡 보상으로 💡{reward}를 받았어요!'**
  String breathingLibraryRewardSnackbar(int reward);

  /// 가이드 호흡/명상 미니 라이브러리 화면 - 이미 오늘 보상을 받은 뒤 완료했을 때 스낵바
  ///
  /// In ko, this message translates to:
  /// **'천천히 잘 따라했어요 🌿 (보상은 하루에 한 번만 받을 수 있어요)'**
  String get breathingLibraryNoRewardSnackbar;

  /// 호흡 기법 이름 - 기본 호흡(4-0-4-0)
  ///
  /// In ko, this message translates to:
  /// **'차분한 숨'**
  String get breathingTechniqueNameCalmBreath;

  /// 호흡 기법 설명 - 기본 호흡
  ///
  /// In ko, this message translates to:
  /// **'들이쉬고 내쉬기만 반복하는 가장 기본적인 호흡이에요. 언제든 편하게 시작해보세요.'**
  String get breathingTechniqueDescCalmBreath;

  /// 호흡 기법 이름 - 4-7-8 호흡법
  ///
  /// In ko, this message translates to:
  /// **'불안을 가라앉히는 숨'**
  String get breathingTechniqueNameAnxietyRelief;

  /// 호흡 기법 설명 - 4-7-8 호흡법
  ///
  /// In ko, this message translates to:
  /// **'4초 들이쉬고, 7초 멈추고, 8초 길게 내쉬어요. 마음이 조급할 때 특히 도움이 돼요.'**
  String get breathingTechniqueDescAnxietyRelief;

  /// 호흡 기법 이름 - 박스 호흡
  ///
  /// In ko, this message translates to:
  /// **'집중을 위한 박스 호흡'**
  String get breathingTechniqueNameBoxBreathing;

  /// 호흡 기법 설명 - 박스 호흡
  ///
  /// In ko, this message translates to:
  /// **'들이쉬고, 멈추고, 내쉬고, 멈추기를 똑같은 길이로 반복해요. 흐트러진 집중을 다잡아줘요.'**
  String get breathingTechniqueDescBoxBreathing;

  /// 호흡 기법 이름 - 잠들기 전 호흡
  ///
  /// In ko, this message translates to:
  /// **'잠들기 전 숨결'**
  String get breathingTechniqueNameSleepWindDown;

  /// 호흡 기법 설명 - 잠들기 전 호흡
  ///
  /// In ko, this message translates to:
  /// **'천천히 들이쉬고 아주 길게 내쉬며, 하루의 긴장을 몸에서 스르르 내려놓아요.'**
  String get breathingTechniqueDescSleepWindDown;

  /// 호흡 기법 이름 - 생기를 깨우는 숨(에너지가 낮은 감정용)
  ///
  /// In ko, this message translates to:
  /// **'생기를 깨우는 숨'**
  String get breathingTechniqueNameEnergizingBreath;

  /// 호흡 기법 설명 - 생기를 깨우는 숨(에너지가 낮은 감정용)
  ///
  /// In ko, this message translates to:
  /// **'들이쉬고 살짝 멈춘 뒤, 산뜻하게 내쉬기를 조금 빠른 리듬으로 반복해요. 몸과 마음이 나른할 때 기운을 깨워줘요.'**
  String get breathingTechniqueDescEnergizingBreath;

  /// 게임 시작 전 호흡 제안 시트 - 상단 헤드라인
  ///
  /// In ko, this message translates to:
  /// **'지금 이 마음, 숨결과 함께 시작해볼까요?'**
  String get breathingSuggestionTitle;

  /// 게임 시작 전 호흡 제안 시트 - 추천 기법 소개 문구
  ///
  /// In ko, this message translates to:
  /// **'{emoji} {name}을 잠깐 함께 해보면, 게임이 조금 더 편안하게 느껴질 거예요.'**
  String breathingSuggestionSubtitle(String emoji, String name);

  /// 게임 시작 전 호흡 제안 시트 - 호흡을 시작하는 버튼
  ///
  /// In ko, this message translates to:
  /// **'숨 고르고 시작하기'**
  String get breathingSuggestionStartButton;

  /// 게임 시작 전 호흡 제안 시트 - 건너뛰고 바로 게임으로 가는 버튼
  ///
  /// In ko, this message translates to:
  /// **'바로 시작할게요'**
  String get breathingSuggestionSkipButton;

  /// 몽이 돌봄 세트 시트 - 빛의 정수 부족 안내 스낵바
  ///
  /// In ko, this message translates to:
  /// **'빛의 정수가 모자라요. 게임을 플레이해서 조금 더 모아볼까요?'**
  String get mongiCareNotEnoughSnackbar;

  /// 몽이 돌봄 세트 시트 - keepsake를 처음 획득했을 때 반응 메시지 뒤에 붙는 안내
  ///
  /// In ko, this message translates to:
  /// **'{reaction}\n정원에 영구히 놓였어요!'**
  String mongiCareKeepsakePlacedSuffix(String reaction);

  /// 몽이 돌봄 세트 시트 - 상단 타이틀
  ///
  /// In ko, this message translates to:
  /// **'🍚 몽이 돌봄 세트'**
  String get mongiCareSheetTitle;

  /// 몽이 돌봄 아이템 이름 - 참치캔
  ///
  /// In ko, this message translates to:
  /// **'참치캔'**
  String get mongiCareItemNameTunaCan;

  /// 몽이 돌봄 아이템 이름 - 사료
  ///
  /// In ko, this message translates to:
  /// **'몽이 사료'**
  String get mongiCareItemNameKibble;

  /// 몽이 돌봄 아이템 이름 - 맑은 물
  ///
  /// In ko, this message translates to:
  /// **'맑은 물'**
  String get mongiCareItemNameCleanWater;

  /// 몽이 돌봄 아이템 이름 - 인절미
  ///
  /// In ko, this message translates to:
  /// **'인절미'**
  String get mongiCareItemNameInjeolmi;

  /// 몽이 돌봄 아이템 이름 - 담요(keepsake)
  ///
  /// In ko, this message translates to:
  /// **'포근한 담요'**
  String get mongiCareItemNameBlanket;

  /// 몽이 돌봄 아이템 이름 - 몽이의 집(keepsake)
  ///
  /// In ko, this message translates to:
  /// **'몽이의 집'**
  String get mongiCareItemNameMongiHouse;

  /// 몽이 돌봄 아이템 반응 대사 - 참치캔
  ///
  /// In ko, this message translates to:
  /// **'몽이가 참치캔을 냠냠 먹었어요! 세상 행복한 표정이에요 🐟'**
  String get mongiCareItemReactionTunaCan;

  /// 몽이 돌봄 아이템 반응 대사 - 사료
  ///
  /// In ko, this message translates to:
  /// **'몽이가 사료를 오독오독 씹어 먹었어요 🍚'**
  String get mongiCareItemReactionKibble;

  /// 몽이 돌봄 아이템 반응 대사 - 맑은 물
  ///
  /// In ko, this message translates to:
  /// **'몽이가 시원한 물을 마시고 개운해했어요 💧'**
  String get mongiCareItemReactionCleanWater;

  /// 몽이 돌봄 아이템 반응 대사 - 인절미
  ///
  /// In ko, this message translates to:
  /// **'몽이가 콩고물 인절미를 오물오물 먹었어요! 쫀득쫀득 맛있대요 🍡'**
  String get mongiCareItemReactionInjeolmi;

  /// 몽이 돌봄 아이템 반응 대사 - 담요(keepsake)
  ///
  /// In ko, this message translates to:
  /// **'몽이가 담요를 덮고 따뜻하게 잠들었어요. 이제 정원 한켠이 더 아늑해졌어요 🧣'**
  String get mongiCareItemReactionBlanket;

  /// 몽이 돌봄 아이템 반응 대사 - 몽이의 집(keepsake)
  ///
  /// In ko, this message translates to:
  /// **'몽이가 새 집을 마음에 들어해요! 이제 정원에 몽이만의 아늑한 집이 생겼어요 🏠'**
  String get mongiCareItemReactionMongiHouse;

  /// 몽이 돌봄 세트 시트 - 상단 보유 빛의 정수 표시
  ///
  /// In ko, this message translates to:
  /// **'빛의 정수 {amount}'**
  String mongiCareLightEssenceLabel(int amount);

  /// 몽이 돌봄 세트 시트 - 소모품 섹션 라벨
  ///
  /// In ko, this message translates to:
  /// **'먹이 · 언제든 다시 줄 수 있어요'**
  String get mongiCareConsumableSectionLabel;

  /// 몽이 돌봄 세트 시트 - keepsake 섹션 라벨
  ///
  /// In ko, this message translates to:
  /// **'특별한 선물 · 한 번 주면 정원에 계속 남아요'**
  String get mongiCareKeepsakeSectionLabel;

  /// 몽이 돌봄 세트 시트 - 이미 배치된 keepsake 상태 문구
  ///
  /// In ko, this message translates to:
  /// **'지금 정원에 놓여 있어요'**
  String get mongiCareKeepsakePlacedStatus;

  /// 몽이 돌봄 세트 시트 - 미배치 keepsake 안내 문구
  ///
  /// In ko, this message translates to:
  /// **'한 번 선물하면 정원에 영구히 남아요'**
  String get mongiCareKeepsakeHint;

  /// 몽이 돌봄 세트 시트 - 소모품을 준 횟수 표시
  ///
  /// In ko, this message translates to:
  /// **'지금까지 {count}번 줬어요'**
  String mongiCareGivenCountStatus(int count);

  /// 몽이 돌봄 세트 시트 - 소모품을 아직 한 번도 안 줬을 때 문구
  ///
  /// In ko, this message translates to:
  /// **'아직 준 적 없어요'**
  String get mongiCareNeverGivenStatus;

  /// 빛의 정수 충전 시트 - 상단 타이틀
  ///
  /// In ko, this message translates to:
  /// **'빛의 정수 충전'**
  String get lightEssenceShopTitle;

  /// 빛의 정수 충전 팩 이름 - light_essence_100 (100개)
  ///
  /// In ko, this message translates to:
  /// **'작은 빛 주머니'**
  String get lightEssencePackLabelSmall;

  /// 빛의 정수 충전 팩 이름 - light_essence_1000 (1000개)
  ///
  /// In ko, this message translates to:
  /// **'커다란 빛 항아리'**
  String get lightEssencePackLabelLarge;

  /// 빛의 정수 충전 시트 - 안내 문구 + 보유 개수
  ///
  /// In ko, this message translates to:
  /// **'플레이만 해도 계속 모을 수 있어요\n지금 보유: {count}개'**
  String lightEssenceShopDescription(int count);

  /// 빛의 정수 충전 시트 - 단가가 가장 낮은 팩에 붙는 배지
  ///
  /// In ko, this message translates to:
  /// **'더 이득'**
  String get lightEssenceShopBestValueBadge;

  /// 빛의 정수 충전 시트 - 팩 상세(수량 · 100개당 단가)
  ///
  /// In ko, this message translates to:
  /// **'💡 {amount}개 · 100개당 {pricePer100}원'**
  String lightEssenceShopPackAmountPrice(int amount, String pricePer100);

  /// 감사 & 작은 성취 화면 - 상단 헤더 타이틀
  ///
  /// In ko, this message translates to:
  /// **'🌻 감사 & 작은 성취'**
  String get gratitudeLogHeaderTitle;

  /// 감사 & 작은 성취 화면 - 안내 문구
  ///
  /// In ko, this message translates to:
  /// **'아주 사소한 것도 괜찮아요.\n매일 한 줄씩, 좋았던 순간을 남겨보세요 🌿'**
  String get gratitudeLogIntro;

  /// 감사 & 작은 성취 화면 - 기록 제출 버튼
  ///
  /// In ko, this message translates to:
  /// **'기록 남기기'**
  String get gratitudeLogSubmitButton;

  /// 감사 & 작은 성취 화면 - 기록이 없을 때 안내 타이틀
  ///
  /// In ko, this message translates to:
  /// **'아직 남긴 기록이 없어요'**
  String get gratitudeLogEmptyTitle;

  /// 감사 & 작은 성취 화면 - 기록이 없을 때 안내 서브타이틀
  ///
  /// In ko, this message translates to:
  /// **'오늘 있었던 작은 좋은 일을 남겨보세요'**
  String get gratitudeLogEmptySubtitle;

  /// 감사 & 작은 성취 화면 - 기록 제출 완료 스낵바
  ///
  /// In ko, this message translates to:
  /// **'{emoji} 오늘의 기록을 남겼어요'**
  String gratitudeLogSubmittedSnackbar(String emoji);

  /// 공통 - 체크인/기록 제출 직후 마음 마일스톤 도달 시 스낵바(홈 화면, 감사 & 작은 성취 화면에서 공용)
  ///
  /// In ko, this message translates to:
  /// **'🌿 {message}'**
  String seasonMilestoneSnackbar(String message);

  /// 감사 & 작은 성취 화면 - 기록 카드 삭제 버튼 툴팁
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get gratitudeLogDeleteTooltip;

  /// 감사 & 작은 성취 화면 - '감사' 종류 이름
  ///
  /// In ko, this message translates to:
  /// **'감사한 일'**
  String get gratitudeEntryTypeLabelGratitude;

  /// 감사 & 작은 성취 화면 - '성취' 종류 이름
  ///
  /// In ko, this message translates to:
  /// **'작은 성취'**
  String get gratitudeEntryTypeLabelAchievement;

  /// 감사 & 작은 성취 화면 - '감사' 입력창 안내문구
  ///
  /// In ko, this message translates to:
  /// **'오늘, 어떤 것에 감사했나요?'**
  String get gratitudeEntryTypeHintGratitude;

  /// 감사 & 작은 성취 화면 - '성취' 입력창 안내문구
  ///
  /// In ko, this message translates to:
  /// **'오늘, 스스로 해낸 작은 일이 있나요?'**
  String get gratitudeEntryTypeHintAchievement;

  /// 감사 & 작은 성취 화면 - '감사' 입력창 예시(placeholder)
  ///
  /// In ko, this message translates to:
  /// **'예: 오늘 햇살이 참 따뜻했어요'**
  String get gratitudeEntryTypePlaceholderGratitude;

  /// 감사 & 작은 성취 화면 - '성취' 입력창 예시(placeholder)
  ///
  /// In ko, this message translates to:
  /// **'예: 오늘은 늦지 않고 일어났어요'**
  String get gratitudeEntryTypePlaceholderAchievement;

  /// 데일리 체크인 시트 - 상단 작은 안내 문구
  ///
  /// In ko, this message translates to:
  /// **'몽이가 궁금해해요'**
  String get dailyCheckInCuriousLabel;

  /// 데일리 체크인 시트 - 메인 질문 문구
  ///
  /// In ko, this message translates to:
  /// **'오늘 기분은 어때요?'**
  String get dailyCheckInQuestion;

  /// 데일리 체크인 시트 - 연속 체크인 일수 배지
  ///
  /// In ko, this message translates to:
  /// **'🔥 연속 체크인 {streak}일째 · 오늘 하면 {streakAfter}일!'**
  String dailyCheckInStreakBadge(int streak, int streakAfter);

  /// 데일리 체크인 시트 - 오늘 체크인하면 지금까지의 개인 최고 연속일수 기록을 넘어설 때 보여주는 문구 (엔드리스 모드 최고 기록 패턴 차용, 스트릭 가시성 강화)
  ///
  /// In ko, this message translates to:
  /// **'🏆 지금 체크인하면 개인 최고 기록 경신!'**
  String get dailyCheckInBestStreakNewRecord;

  /// 데일리 체크인 시트 - 아직 최고 기록을 넘어서지 않았을 때, 참고용으로 보여주는 개인 최고 연속일수
  ///
  /// In ko, this message translates to:
  /// **'개인 최고 기록 {best}일'**
  String dailyCheckInBestStreakCompare(int best);

  /// 데일리 체크인 시트 - 스트릭이 끊긴 뒤 다시 시작할 때, 예전 최고 기록을 알려주며 재도전을 격려하는 문구
  ///
  /// In ko, this message translates to:
  /// **'이전 최고 기록은 {best}일이에요 · 다시 도전해봐요!'**
  String dailyCheckInBestStreakRestart(int best);

  /// 데일리 체크인 시트 - 건너뛰기 버튼
  ///
  /// In ko, this message translates to:
  /// **'나중에 할게요'**
  String get dailyCheckInSkipButton;

  /// 몽이의 편지 화면 - 상단 헤더 타이틀
  ///
  /// In ko, this message translates to:
  /// **'💌 몽이의 편지'**
  String get mongiLetterHeaderTitle;

  /// 몽이의 편지 화면 - 데이터가 부족할 때 안내 문구
  ///
  /// In ko, this message translates to:
  /// **'아직 몽이가 편지를 쓸 만큼\n이야기가 모이지 않았어요.\n조금 더 함께해주면 다음 주엔\n꼭 편지를 써서 보내줄게요 🐾'**
  String get mongiLetterNotEnoughMessage;

  /// 몽이의 편지 화면 - 봉투 화면, 편지가 도착했다는 타이틀
  ///
  /// In ko, this message translates to:
  /// **'몽이에게서 편지가 도착했어요'**
  String get mongiLetterArrivedTitle;

  /// 몽이의 편지 화면 - 봉투 화면, 열어보라는 안내
  ///
  /// In ko, this message translates to:
  /// **'톡 눌러서 열어보기'**
  String get mongiLetterTapToOpenHint;

  /// 몽이의 편지 화면 - 편지 첫 문단(인사)
  ///
  /// In ko, this message translates to:
  /// **'안녕, 나 몽이야 🐱\n이번 주도 네 마음을 가까이서 지켜봤어.'**
  String get mongiLetterGreeting;

  /// 몽이의 편지 화면 - 본문 문단, 특정 대상이 반복 언급됐을 때
  ///
  /// In ko, this message translates to:
  /// **'이번 주엔 \"{target}\" 이야기를 유독 많이 들려줬어.\n그만큼 네 마음에 크게 자리하고 있었나 봐.\n어떤 이야기였는지 몽이는 계속 생각하고 있었어.'**
  String mongiLetterBodyTopTarget(String target);

  /// 몽이의 편지 화면 - 본문 문단, 특정 감정이 압도적으로 많았을 때
  ///
  /// In ko, this message translates to:
  /// **'이번 주는 \"{emotion}\"을 유독 많이 만난 한 주였어.\n무슨 일이 있었는지 몽이는 궁금했지만,\n다그치지 않고 그냥 곁에서 지켜봤어.'**
  String mongiLetterBodyTopEmotion(String emotion);

  /// 몽이의 편지 화면 - 본문 문단, 메모를 많이 남긴 주
  ///
  /// In ko, this message translates to:
  /// **'이번 주는 너의 이야기를 유독 많이 들려줬어.\n짧은 한마디까지도 몽이는 하나하나\n다 소중하게 담아뒀어.'**
  String get mongiLetterBodyManyNotes;

  /// 몽이의 편지 화면 - 본문 문단, 긍정 비율이 높은 주
  ///
  /// In ko, this message translates to:
  /// **'요즘 마음이 한층 가벼워진 것 같아서\n몽이도 옆에서 덩달아 신났어.\n이런 날들이 더 많아지면 좋겠다.'**
  String get mongiLetterBodyMostlyPositive;

  /// 몽이의 편지 화면 - 본문 문단, 부정 비율이 높은 주
  ///
  /// In ko, this message translates to:
  /// **'마음이 조금 무거웠던 날들도 있었지.\n그래도 힘들 때마다 몽이에게 와줘서\n고마웠어. 혼자 견디지 않아도 괜찮아.'**
  String get mongiLetterBodyMostlyHeavy;

  /// 몽이의 편지 화면 - 본문 문단, 특별히 도드라지는 것이 없는 주
  ///
  /// In ko, this message translates to:
  /// **'이번 주도 크고 작은 마음들을\n몽이에게 나눠줘서 고마웠어.\n어떤 마음이든 괜찮다고, 몽이는 늘 그렇게 생각해.'**
  String get mongiLetterBodyDefaultThanks;

  /// 몽이의 편지 화면 - 마무리 문단, 연속 체크인 7일 이상
  ///
  /// In ko, this message translates to:
  /// **'{streak}일째 매일 몽이를 찾아와줬어.\n그게 얼마나 대단한 일인지 너는 잘 모를 수도 있지만,\n몽이는 매일 그걸 느끼고 있었어.'**
  String mongiLetterStreakLong(int streak);

  /// 몽이의 편지 화면 - 마무리 문단, 연속 체크인 3~6일
  ///
  /// In ko, this message translates to:
  /// **'{streak}일 연속으로 와줬네!\n작은 습관이 쌓이는 걸 보는 게\n몽이에겐 큰 기쁨이야.'**
  String mongiLetterStreakShort(int streak);

  /// 몽이의 편지 화면 - 마무리 문단, 연속 체크인이 거의 없을 때
  ///
  /// In ko, this message translates to:
  /// **'자주 오지 못한 주였어도 괜찮아.\n네가 오고 싶을 때, 몽이는 늘 같은 자리에 있을게.'**
  String get mongiLetterStreakNone;

  /// 몽이의 편지 화면 - 편지 마지막 문단(마무리 인사)
  ///
  /// In ko, this message translates to:
  /// **'언제나 네 곁에 있을게.\n다음 주에도 또 이야기해줘.\n\n너의 몽이가 🐾'**
  String get mongiLetterClosing;

  /// 감정 다이어리 화면 - 상단 타이틀
  ///
  /// In ko, this message translates to:
  /// **'📔 감정 다이어리'**
  String get diaryHeaderTitle;

  /// 감정 다이어리 화면 - 빈 상태 타이틀
  ///
  /// In ko, this message translates to:
  /// **'아직 남긴 기록이 없어요'**
  String get diaryEmptyTitle;

  /// 감정 다이어리 화면 - 빈 상태 서브 타이틀
  ///
  /// In ko, this message translates to:
  /// **'감정 몬스터를 마주하고 나면\n이 곳에 오늘의 이야기가 쌓여요'**
  String get diaryEmptySubtitle;

  /// 감정 다이어리 화면 - 항목 카드, 공유 버튼 툴팁
  ///
  /// In ko, this message translates to:
  /// **'카드로 공유하기'**
  String get diaryShareTooltip;

  /// 감정 다이어리 화면 - 대상이 있을 때 항목 이름 라벨
  ///
  /// In ko, this message translates to:
  /// **'{target}에 대한 {emotion}'**
  String diaryNameLabel(String target, String emotion);

  /// 점수 팝업 애니메이션 - 이번에 얻은 점수
  ///
  /// In ko, this message translates to:
  /// **'+{score}점'**
  String scorePopupGainedLabel(int score);

  /// 점수 팝업 애니메이션 - 누적 점수
  ///
  /// In ko, this message translates to:
  /// **'누적 {totalScore}점'**
  String scorePopupTotalLabel(int totalScore);

  /// 감정 라벨 - hate
  ///
  /// In ko, this message translates to:
  /// **'미움'**
  String get emotionLabelHate;

  /// 감정 라벨 - anger
  ///
  /// In ko, this message translates to:
  /// **'화'**
  String get emotionLabelAnger;

  /// 감정 라벨 - worry
  ///
  /// In ko, this message translates to:
  /// **'걱정'**
  String get emotionLabelWorry;

  /// 감정 라벨 - sadness
  ///
  /// In ko, this message translates to:
  /// **'슬픔'**
  String get emotionLabelSadness;

  /// 감정 라벨 - loneliness
  ///
  /// In ko, this message translates to:
  /// **'외로움'**
  String get emotionLabelLoneliness;

  /// 감정 라벨 - anxiety
  ///
  /// In ko, this message translates to:
  /// **'불안'**
  String get emotionLabelAnxiety;

  /// 감정 라벨 - shame
  ///
  /// In ko, this message translates to:
  /// **'부끄러움'**
  String get emotionLabelShame;

  /// 감정 라벨 - irritation
  ///
  /// In ko, this message translates to:
  /// **'짜증'**
  String get emotionLabelIrritation;

  /// 감정 라벨 - grievance
  ///
  /// In ko, this message translates to:
  /// **'억울함'**
  String get emotionLabelGrievance;

  /// 감정 라벨 - fear
  ///
  /// In ko, this message translates to:
  /// **'두려움'**
  String get emotionLabelFear;

  /// 감정 라벨 - joy
  ///
  /// In ko, this message translates to:
  /// **'기쁨'**
  String get emotionLabelJoy;

  /// 감정 라벨 - gratitude
  ///
  /// In ko, this message translates to:
  /// **'감사'**
  String get emotionLabelGratitude;

  /// 감정 라벨 - excitement
  ///
  /// In ko, this message translates to:
  /// **'설렘'**
  String get emotionLabelExcitement;

  /// 감정 라벨 - calm
  ///
  /// In ko, this message translates to:
  /// **'평온'**
  String get emotionLabelCalm;

  /// 감정 라벨 - confidence
  ///
  /// In ko, this message translates to:
  /// **'자신감'**
  String get emotionLabelConfidence;

  /// 감정 라벨 - tired
  ///
  /// In ko, this message translates to:
  /// **'피곤'**
  String get emotionLabelTired;

  /// 감정 라벨 - boredom
  ///
  /// In ko, this message translates to:
  /// **'심심함'**
  String get emotionLabelBoredom;

  /// 감정 라벨 - courage
  ///
  /// In ko, this message translates to:
  /// **'용기'**
  String get emotionLabelCourage;

  /// 감정 라벨 - thrill
  ///
  /// In ko, this message translates to:
  /// **'신남'**
  String get emotionLabelThrill;

  /// 감정 라벨 - happiness
  ///
  /// In ko, this message translates to:
  /// **'행복'**
  String get emotionLabelHappiness;

  /// 몬스터 등장 시 몽이 대사 - hate
  ///
  /// In ko, this message translates to:
  /// **'이건... 미움콩이네. 오래 가지고 있었구나.'**
  String get emotionCatQuestionHate;

  /// 몬스터 등장 시 몽이 대사 - anger
  ///
  /// In ko, this message translates to:
  /// **'화르르가 나왔네. 많이 속상했지.'**
  String get emotionCatQuestionAnger;

  /// 몬스터 등장 시 몽이 대사 - worry
  ///
  /// In ko, this message translates to:
  /// **'걱정구름이 잔뜩 끼어있었네.'**
  String get emotionCatQuestionWorry;

  /// 몬스터 등장 시 몽이 대사 - sadness
  ///
  /// In ko, this message translates to:
  /// **'슬픔물방울이구나. 많이 힘들었겠다.'**
  String get emotionCatQuestionSadness;

  /// 몬스터 등장 시 몽이 대사 - loneliness
  ///
  /// In ko, this message translates to:
  /// **'혼자 웅크리고 있었구나. 내가 옆에 있을게.'**
  String get emotionCatQuestionLoneliness;

  /// 몬스터 등장 시 몽이 대사 - anxiety
  ///
  /// In ko, this message translates to:
  /// **'불안돌이가 자꾸 떨고 있었네. 나쁜 생각이 많았구나.'**
  String get emotionCatQuestionAnxiety;

  /// 몬스터 등장 시 몽이 대사 - shame
  ///
  /// In ko, this message translates to:
  /// **'부끄럼쟁이구나. 얼굴이 발그레했겠다.'**
  String get emotionCatQuestionShame;

  /// 몬스터 등장 시 몽이 대사 - irritation
  ///
  /// In ko, this message translates to:
  /// **'까칠이가 잔뜩 곤두서 있었네. 예민했었구나.'**
  String get emotionCatQuestionIrritation;

  /// 몬스터 등장 시 몽이 대사 - grievance
  ///
  /// In ko, this message translates to:
  /// **'꽁꽁 묶인 억울함이었구나. 얼마나 답답했을까.'**
  String get emotionCatQuestionGrievance;

  /// 몬스터 등장 시 몽이 대사 - fear
  ///
  /// In ko, this message translates to:
  /// **'어둠 속에 숨어있던 두려움이네. 이제 괜찮아, 내가 있잖아.'**
  String get emotionCatQuestionFear;

  /// 몬스터 등장 시 몽이 대사 - joy
  ///
  /// In ko, this message translates to:
  /// **'반짝반짝 기쁨별이네! 오늘 좋은 일이 있었나 보다.'**
  String get emotionCatQuestionJoy;

  /// 몬스터 등장 시 몽이 대사 - gratitude
  ///
  /// In ko, this message translates to:
  /// **'따뜻한 감사하트구나. 누군가에게 고마운 마음이 있었나 봐.'**
  String get emotionCatQuestionGratitude;

  /// 몬스터 등장 시 몽이 대사 - excitement
  ///
  /// In ko, this message translates to:
  /// **'두근두근 설렘구름이네! 무슨 좋은 일을 기다리는 거야?'**
  String get emotionCatQuestionExcitement;

  /// 몬스터 등장 시 몽이 대사 - calm
  ///
  /// In ko, this message translates to:
  /// **'잔잔한 평온물결이구나. 마음이 고요하고 편안했나 봐.'**
  String get emotionCatQuestionCalm;

  /// 몬스터 등장 시 몽이 대사 - confidence
  ///
  /// In ko, this message translates to:
  /// **'씩씩한 자신감뱃지네! 오늘 뭔가 해냈구나, 대단해.'**
  String get emotionCatQuestionConfidence;

  /// 몬스터 등장 시 몽이 대사 - tired
  ///
  /// In ko, this message translates to:
  /// **'나른한 피곤이네. 오늘 많이 애썼구나.'**
  String get emotionCatQuestionTired;

  /// 몬스터 등장 시 몽이 대사 - boredom
  ///
  /// In ko, this message translates to:
  /// **'하품 나는 심심함이구나. 뭔가 재미있는 게 필요했나 봐.'**
  String get emotionCatQuestionBoredom;

  /// 몬스터 등장 시 몽이 대사 - courage
  ///
  /// In ko, this message translates to:
  /// **'씩씩한 용기 방패네! 무서운 걸 마주하고도 한 발 나아갔구나.'**
  String get emotionCatQuestionCourage;

  /// 몬스터 등장 시 몽이 대사 - thrill
  ///
  /// In ko, this message translates to:
  /// **'팡팡 튀는 신남이네! 신나는 일이 생겼구나!'**
  String get emotionCatQuestionThrill;

  /// 몬스터 등장 시 몽이 대사 - happiness
  ///
  /// In ko, this message translates to:
  /// **'포근한 행복 햇살이네. 마음 가득 따뜻했나 보다.'**
  String get emotionCatQuestionHappiness;

  /// 먹고 난 뒤 위로 메시지 - hate
  ///
  /// In ko, this message translates to:
  /// **'미움이 사라진 자리에\n작은 꽃 한 송이가 피었어요 🌸'**
  String get emotionHealMessageHate;

  /// 먹고 난 뒤 위로 메시지 - anger
  ///
  /// In ko, this message translates to:
  /// **'뜨거운 마음이 가라앉고\n따뜻한 빛이 남았어요 ✨'**
  String get emotionHealMessageAnger;

  /// 먹고 난 뒤 위로 메시지 - worry
  ///
  /// In ko, this message translates to:
  /// **'먹구름이 걷히고\n맑은 하늘이 보이기 시작해요 🌤️'**
  String get emotionHealMessageWorry;

  /// 먹고 난 뒤 위로 메시지 - sadness
  ///
  /// In ko, this message translates to:
  /// **'눈물이 마르고\n작은 연못에 별이 비쳐요 💧'**
  String get emotionHealMessageSadness;

  /// 먹고 난 뒤 위로 메시지 - loneliness
  ///
  /// In ko, this message translates to:
  /// **'그림자가 옅어지고\n곁을 지키는 온기가 남았어요 🤍'**
  String get emotionHealMessageLoneliness;

  /// 먹고 난 뒤 위로 메시지 - anxiety
  ///
  /// In ko, this message translates to:
  /// **'떨림이 잦아들고\n마음에 잔잔한 물결이 일어요 🌊'**
  String get emotionHealMessageAnxiety;

  /// 먹고 난 뒤 위로 메시지 - shame
  ///
  /// In ko, this message translates to:
  /// **'움츠렸던 어깨가 펴지고\n따뜻한 미소가 번져요 😊'**
  String get emotionHealMessageShame;

  /// 먹고 난 뒤 위로 메시지 - irritation
  ///
  /// In ko, this message translates to:
  /// **'가시가 살랑살랑 부드러워지고\n산들바람이 불어와요 🍃'**
  String get emotionHealMessageIrritation;

  /// 먹고 난 뒤 위로 메시지 - grievance
  ///
  /// In ko, this message translates to:
  /// **'엉킨 마음이 스르륵 풀리고\n숨쉬기가 편해졌어요 🎈'**
  String get emotionHealMessageGrievance;

  /// 먹고 난 뒤 위로 메시지 - fear
  ///
  /// In ko, this message translates to:
  /// **'어둠이 걷히고\n작은 별빛이 마음을 비춰요 ⭐'**
  String get emotionHealMessageFear;

  /// 먹고 난 뒤 위로 메시지 - joy
  ///
  /// In ko, this message translates to:
  /// **'기쁨이 마음 가득 채워지고\n환한 빛으로 남았어요 🌟'**
  String get emotionHealMessageJoy;

  /// 먹고 난 뒤 위로 메시지 - gratitude
  ///
  /// In ko, this message translates to:
  /// **'고마운 마음이 몽이 품에도\n따뜻하게 스며들었어요 💛'**
  String get emotionHealMessageGratitude;

  /// 먹고 난 뒤 위로 메시지 - excitement
  ///
  /// In ko, this message translates to:
  /// **'두근거림이 몽이에게도 전해져서\n마음이 살짝 붕 떠올랐어요 🎈'**
  String get emotionHealMessageExcitement;

  /// 먹고 난 뒤 위로 메시지 - calm
  ///
  /// In ko, this message translates to:
  /// **'고요한 마음이 정원에도 번져서\n잔잔한 물결이 일어요 🌊'**
  String get emotionHealMessageCalm;

  /// 먹고 난 뒤 위로 메시지 - confidence
  ///
  /// In ko, this message translates to:
  /// **'씩씩한 마음이 몽이에게도 옮아서\n어깨가 활짝 펴졌어요 💪'**
  String get emotionHealMessageConfidence;

  /// 먹고 난 뒤 위로 메시지 - tired
  ///
  /// In ko, this message translates to:
  /// **'무거웠던 눈꺼풀이 스르륵 감기고\n포근한 잠이 찾아와요 🌙'**
  String get emotionHealMessageTired;

  /// 먹고 난 뒤 위로 메시지 - boredom
  ///
  /// In ko, this message translates to:
  /// **'멍하던 마음에 작은 호기심이\n동그라미를 그리며 피어나요 🌀'**
  String get emotionHealMessageBoredom;

  /// 먹고 난 뒤 위로 메시지 - courage
  ///
  /// In ko, this message translates to:
  /// **'두근거리던 마음이 단단해지고\n몽이 가슴에도 뜨거운 힘이 차올라요 🔥'**
  String get emotionHealMessageCourage;

  /// 먹고 난 뒤 위로 메시지 - thrill
  ///
  /// In ko, this message translates to:
  /// **'통통 튀는 기운이 몽이에게도 옮아서\n온몸이 들썩들썩해졌어요 🎊'**
  String get emotionHealMessageThrill;

  /// 먹고 난 뒤 위로 메시지 - happiness
  ///
  /// In ko, this message translates to:
  /// **'따스한 볕이 마음 구석구석까지 스며들어\n은은하게 오래 남아요 ☀️'**
  String get emotionHealMessageHappiness;

  /// 감정 컬렉션 도감 스토리 - hate
  ///
  /// In ko, this message translates to:
  /// **'미움콩은 마음에 오래 담아두면 점점 딱딱해져요. 누군가를 미워하는 마음은 사실 그만큼 소중히 여겼다는 증거이기도 해요. 꺼내서 보여주면, 그 자리에 꽃이 필 수 있어요.'**
  String get emotionStoryTextHate;

  /// 감정 컬렉션 도감 스토리 - anger
  ///
  /// In ko, this message translates to:
  /// **'화르르는 마음이 지켜지지 않았을 때 확 타오르는 감정이에요. 나쁜 게 아니라, \"나를 존중해줘\"라는 신호랍니다. 잠깐 열을 식히고 나면 따뜻한 빛만 남아요.'**
  String get emotionStoryTextAnger;

  /// 감정 컬렉션 도감 스토리 - worry
  ///
  /// In ko, this message translates to:
  /// **'걱정구름은 아직 일어나지 않은 일까지 미리 대비하려는 마음이 만들어내요. 조금은 나를 지키려는 노력이었어요. 구름은 흘러가는 게 원래 하는 일이니, 잠시 지켜봐 줘도 괜찮아요.'**
  String get emotionStoryTextWorry;

  /// 감정 컬렉션 도감 스토리 - sadness
  ///
  /// In ko, this message translates to:
  /// **'슬픔물방울은 소중한 걸 잃었거나 마음이 다쳤을 때 맺혀요. 참지 않고 흘려보내면, 그 눈물이 고여 작은 연못이 되고 언젠가 별빛이 비치는 날이 와요.'**
  String get emotionStoryTextSadness;

  /// 감정 컬렉션 도감 스토리 - loneliness
  ///
  /// In ko, this message translates to:
  /// **'외로움그림자는 누군가와 연결되고 싶은 마음이 클수록 짙어져요. 혼자라는 느낌이 들 땐, 그만큼 함께하고 싶은 마음이 크다는 뜻이에요. 몽이가 옆에 있을게요.'**
  String get emotionStoryTextLoneliness;

  /// 감정 컬렉션 도감 스토리 - anxiety
  ///
  /// In ko, this message translates to:
  /// **'불안돌이는 앞일이 어떻게 될지 모를 때 자꾸만 떨려요. 확실하지 않은 걸 견디는 건 누구에게나 힘든 일이에요. 숨을 천천히 쉬면, 떨림도 조금씩 잦아들어요.'**
  String get emotionStoryTextAnxiety;

  /// 감정 컬렉션 도감 스토리 - shame
  ///
  /// In ko, this message translates to:
  /// **'부끄럼쟁이는 남들 눈에 어떻게 보일지 신경 쓸 때 얼굴을 붉혀요. 사실 그만큼 진심으로 잘 해내고 싶었다는 뜻이에요. 실수해도 괜찮아요, 몽이는 그런 모습도 좋아해요.'**
  String get emotionStoryTextShame;

  /// 감정 컬렉션 도감 스토리 - irritation
  ///
  /// In ko, this message translates to:
  /// **'까칠이는 몸과 마음이 지쳐 여유가 없을 때 가시를 세워요. 짜증이 났다는 건 쉬어야 할 때가 됐다는 신호일 수 있어요. 가시를 내려놓으면 산들바람이 불어와요.'**
  String get emotionStoryTextIrritation;

  /// 감정 컬렉션 도감 스토리 - grievance
  ///
  /// In ko, this message translates to:
  /// **'억울함 매듭은 내 진심이 제대로 전해지지 않았다고 느낄 때 꽁꽁 묶여요. 누군가에게 알아달라고 소리치고 싶었던 마음이었을 거예요. 하나씩 풀다 보면 숨쉬기가 편해져요.'**
  String get emotionStoryTextGrievance;

  /// 감정 컬렉션 도감 스토리 - fear
  ///
  /// In ko, this message translates to:
  /// **'두려움은 나를 위험으로부터 지키려는 아주 오래된 본능이에요. 무서운 게 있다는 건 그만큼 소중히 지키고 싶은 게 있다는 뜻이죠. 어둠 속에서도 몽이가 함께 있을게요.'**
  String get emotionStoryTextFear;

  /// 감정 컬렉션 도감 스토리 - joy
  ///
  /// In ko, this message translates to:
  /// **'기쁨별은 작은 행복도 놓치지 않고 알아챘을 때 반짝여요. 기쁜 순간을 마음에 오래 담아두는 연습을 하면, 별빛이 더 환하게 오래 빛난답니다.'**
  String get emotionStoryTextJoy;

  /// 감정 컬렉션 도감 스토리 - gratitude
  ///
  /// In ko, this message translates to:
  /// **'감사하트는 누군가의 다정함을 알아챘을 때 따뜻하게 커져요. 고맙다는 말 한마디가 상대의 마음에도 하트를 하나 더 심어준답니다.'**
  String get emotionStoryTextGratitude;

  /// 감정 컬렉션 도감 스토리 - excitement
  ///
  /// In ko, this message translates to:
  /// **'설렘구름은 앞으로 다가올 무언가를 기대할 때 두둥실 떠올라요. 결과가 어떻든, 기다리는 그 시간 자체가 이미 선물 같은 순간이에요.'**
  String get emotionStoryTextExcitement;

  /// 감정 컬렉션 도감 스토리 - calm
  ///
  /// In ko, this message translates to:
  /// **'평온물결은 아무 일도 없어야만 생기는 게 아니에요. 있는 그대로의 나를 받아들일 때 마음 깊은 곳에서부터 잔잔하게 퍼져 나가요.'**
  String get emotionStoryTextCalm;

  /// 감정 컬렉션 도감 스토리 - confidence
  ///
  /// In ko, this message translates to:
  /// **'자신감뱃지는 작은 시도라도 스스로 해냈을 때 반짝 달려요. 결과보다 시도한 그 순간을 인정해주는 게, 뱃지를 더 많이 모으는 비결이에요.'**
  String get emotionStoryTextConfidence;

  /// 감정 컬렉션 도감 스토리 - tired
  ///
  /// In ko, this message translates to:
  /// **'피곤이는 몸과 마음이 열심히 하루를 살아냈다는 증거예요. 애쓴 나를 다그치기보다 잠깐 눈을 감고 쉬어주면, 다음 날 다시 통통 튀어 오를 힘이 생겨요.'**
  String get emotionStoryTextTired;

  /// 감정 컬렉션 도감 스토리 - boredom
  ///
  /// In ko, this message translates to:
  /// **'심심이는 딱히 할 일이 없을 때 마음이 텅 빈 것처럼 느껴져서 찾아와요. 사실 심심함은 새로운 걸 하고 싶다는 신호이기도 해요. 가만히 있다 보면 뜻밖의 재미난 생각이 떠오르기도 한답니다.'**
  String get emotionStoryTextBoredom;

  /// 감정 컬렉션 도감 스토리 - courage
  ///
  /// In ko, this message translates to:
  /// **'용기 방패는 무섭지 않아서가 아니라, 무서워도 한 걸음 내딛었을 때 반짝 빛나요. 떨리는 마음을 안고도 해낸 그 순간이 가장 용감한 순간이에요.'**
  String get emotionStoryTextCourage;

  /// 감정 컬렉션 도감 스토리 - thrill
  ///
  /// In ko, this message translates to:
  /// **'신남이는 지금 이 순간이 너무 즐거워서 몸이 먼저 들썩일 때 튀어나와요. 설렘이 앞으로 올 일을 기대하는 두근거림이라면, 신남이는 지금 당장 터지는 신나는 에너지예요.'**
  String get emotionStoryTextThrill;

  /// 감정 컬렉션 도감 스토리 - happiness
  ///
  /// In ko, this message translates to:
  /// **'행복 햇살은 반짝하고 사라지는 기쁨과 달리, 잔잔하고 오래도록 마음을 데워줘요. 특별한 일이 없어도 하루하루가 괜찮다고 느껴질 때, 이 햇살이 은은하게 비춘답니다.'**
  String get emotionStoryTextHappiness;

  /// 진화 단계 이름 0 - hate
  ///
  /// In ko, this message translates to:
  /// **'미움콩'**
  String get evolutionNameHate0;

  /// 진화 단계 이름 1 - hate
  ///
  /// In ko, this message translates to:
  /// **'애틋콩'**
  String get evolutionNameHate1;

  /// 진화 단계 이름 2 - hate
  ///
  /// In ko, this message translates to:
  /// **'온정콩'**
  String get evolutionNameHate2;

  /// 진화 단계 이름 3 - hate
  ///
  /// In ko, this message translates to:
  /// **'다정콩순'**
  String get evolutionNameHate3;

  /// 진화 단계 이름 0 - anger
  ///
  /// In ko, this message translates to:
  /// **'화르르'**
  String get evolutionNameAnger0;

  /// 진화 단계 이름 1 - anger
  ///
  /// In ko, this message translates to:
  /// **'잔불이'**
  String get evolutionNameAnger1;

  /// 진화 단계 이름 2 - anger
  ///
  /// In ko, this message translates to:
  /// **'온기'**
  String get evolutionNameAnger2;

  /// 진화 단계 이름 3 - anger
  ///
  /// In ko, this message translates to:
  /// **'온기누리'**
  String get evolutionNameAnger3;

  /// 진화 단계 이름 0 - worry
  ///
  /// In ko, this message translates to:
  /// **'걱정구름'**
  String get evolutionNameWorry0;

  /// 진화 단계 이름 1 - worry
  ///
  /// In ko, this message translates to:
  /// **'옅은구름'**
  String get evolutionNameWorry1;

  /// 진화 단계 이름 2 - worry
  ///
  /// In ko, this message translates to:
  /// **'맑음이'**
  String get evolutionNameWorry2;

  /// 진화 단계 이름 3 - worry
  ///
  /// In ko, this message translates to:
  /// **'맑음별'**
  String get evolutionNameWorry3;

  /// 진화 단계 이름 0 - sadness
  ///
  /// In ko, this message translates to:
  /// **'슬픔물방울'**
  String get evolutionNameSadness0;

  /// 진화 단계 이름 1 - sadness
  ///
  /// In ko, this message translates to:
  /// **'잔잔물결'**
  String get evolutionNameSadness1;

  /// 진화 단계 이름 2 - sadness
  ///
  /// In ko, this message translates to:
  /// **'별빛연못'**
  String get evolutionNameSadness2;

  /// 진화 단계 이름 3 - sadness
  ///
  /// In ko, this message translates to:
  /// **'별빛은하'**
  String get evolutionNameSadness3;

  /// 진화 단계 이름 0 - loneliness
  ///
  /// In ko, this message translates to:
  /// **'외로움그림자'**
  String get evolutionNameLoneliness0;

  /// 진화 단계 이름 1 - loneliness
  ///
  /// In ko, this message translates to:
  /// **'옅은그림자'**
  String get evolutionNameLoneliness1;

  /// 진화 단계 이름 2 - loneliness
  ///
  /// In ko, this message translates to:
  /// **'온기그림자'**
  String get evolutionNameLoneliness2;

  /// 진화 단계 이름 3 - loneliness
  ///
  /// In ko, this message translates to:
  /// **'함께빛'**
  String get evolutionNameLoneliness3;

  /// 진화 단계 이름 0 - anxiety
  ///
  /// In ko, this message translates to:
  /// **'불안돌이'**
  String get evolutionNameAnxiety0;

  /// 진화 단계 이름 1 - anxiety
  ///
  /// In ko, this message translates to:
  /// **'잔잔돌이'**
  String get evolutionNameAnxiety1;

  /// 진화 단계 이름 2 - anxiety
  ///
  /// In ko, this message translates to:
  /// **'평온돌이'**
  String get evolutionNameAnxiety2;

  /// 진화 단계 이름 3 - anxiety
  ///
  /// In ko, this message translates to:
  /// **'평온지기'**
  String get evolutionNameAnxiety3;

  /// 진화 단계 이름 0 - shame
  ///
  /// In ko, this message translates to:
  /// **'부끄럼쟁이'**
  String get evolutionNameShame0;

  /// 진화 단계 이름 1 - shame
  ///
  /// In ko, this message translates to:
  /// **'발그레쟁이'**
  String get evolutionNameShame1;

  /// 진화 단계 이름 2 - shame
  ///
  /// In ko, this message translates to:
  /// **'미소쟁이'**
  String get evolutionNameShame2;

  /// 진화 단계 이름 3 - shame
  ///
  /// In ko, this message translates to:
  /// **'당당이'**
  String get evolutionNameShame3;

  /// 진화 단계 이름 0 - irritation
  ///
  /// In ko, this message translates to:
  /// **'까칠이'**
  String get evolutionNameIrritation0;

  /// 진화 단계 이름 1 - irritation
  ///
  /// In ko, this message translates to:
  /// **'산들이'**
  String get evolutionNameIrritation1;

  /// 진화 단계 이름 2 - irritation
  ///
  /// In ko, this message translates to:
  /// **'보드리'**
  String get evolutionNameIrritation2;

  /// 진화 단계 이름 3 - irritation
  ///
  /// In ko, this message translates to:
  /// **'포근보드리'**
  String get evolutionNameIrritation3;

  /// 진화 단계 이름 0 - grievance
  ///
  /// In ko, this message translates to:
  /// **'억울매듭'**
  String get evolutionNameGrievance0;

  /// 진화 단계 이름 1 - grievance
  ///
  /// In ko, this message translates to:
  /// **'느슨매듭'**
  String get evolutionNameGrievance1;

  /// 진화 단계 이름 2 - grievance
  ///
  /// In ko, this message translates to:
  /// **'풀림매듭'**
  String get evolutionNameGrievance2;

  /// 진화 단계 이름 3 - grievance
  ///
  /// In ko, this message translates to:
  /// **'자유매듭'**
  String get evolutionNameGrievance3;

  /// 진화 단계 이름 0 - fear
  ///
  /// In ko, this message translates to:
  /// **'어둠이'**
  String get evolutionNameFear0;

  /// 진화 단계 이름 1 - fear
  ///
  /// In ko, this message translates to:
  /// **'여명이'**
  String get evolutionNameFear1;

  /// 진화 단계 이름 2 - fear
  ///
  /// In ko, this message translates to:
  /// **'별빛이'**
  String get evolutionNameFear2;

  /// 진화 단계 이름 3 - fear
  ///
  /// In ko, this message translates to:
  /// **'새벽별'**
  String get evolutionNameFear3;

  /// 진화 단계 이름 0 - joy
  ///
  /// In ko, this message translates to:
  /// **'기쁨별'**
  String get evolutionNameJoy0;

  /// 진화 단계 이름 1 - joy
  ///
  /// In ko, this message translates to:
  /// **'반짝별'**
  String get evolutionNameJoy1;

  /// 진화 단계 이름 2 - joy
  ///
  /// In ko, this message translates to:
  /// **'빛나는별'**
  String get evolutionNameJoy2;

  /// 진화 단계 이름 3 - joy
  ///
  /// In ko, this message translates to:
  /// **'별무리'**
  String get evolutionNameJoy3;

  /// 진화 단계 이름 0 - gratitude
  ///
  /// In ko, this message translates to:
  /// **'감사하트'**
  String get evolutionNameGratitude0;

  /// 진화 단계 이름 1 - gratitude
  ///
  /// In ko, this message translates to:
  /// **'따뜻하트'**
  String get evolutionNameGratitude1;

  /// 진화 단계 이름 2 - gratitude
  ///
  /// In ko, this message translates to:
  /// **'빛나하트'**
  String get evolutionNameGratitude2;

  /// 진화 단계 이름 3 - gratitude
  ///
  /// In ko, this message translates to:
  /// **'은하하트'**
  String get evolutionNameGratitude3;

  /// 진화 단계 이름 0 - excitement
  ///
  /// In ko, this message translates to:
  /// **'설렘구름'**
  String get evolutionNameExcitement0;

  /// 진화 단계 이름 1 - excitement
  ///
  /// In ko, this message translates to:
  /// **'두근구름'**
  String get evolutionNameExcitement1;

  /// 진화 단계 이름 2 - excitement
  ///
  /// In ko, this message translates to:
  /// **'반짝구름'**
  String get evolutionNameExcitement2;

  /// 진화 단계 이름 3 - excitement
  ///
  /// In ko, this message translates to:
  /// **'무지개구름'**
  String get evolutionNameExcitement3;

  /// 진화 단계 이름 0 - calm
  ///
  /// In ko, this message translates to:
  /// **'평온물결'**
  String get evolutionNameCalm0;

  /// 진화 단계 이름 1 - calm
  ///
  /// In ko, this message translates to:
  /// **'잔잔바다'**
  String get evolutionNameCalm1;

  /// 진화 단계 이름 2 - calm
  ///
  /// In ko, this message translates to:
  /// **'고요한바다'**
  String get evolutionNameCalm2;

  /// 진화 단계 이름 3 - calm
  ///
  /// In ko, this message translates to:
  /// **'은빛바다'**
  String get evolutionNameCalm3;

  /// 진화 단계 이름 0 - confidence
  ///
  /// In ko, this message translates to:
  /// **'자신감뱃지'**
  String get evolutionNameConfidence0;

  /// 진화 단계 이름 1 - confidence
  ///
  /// In ko, this message translates to:
  /// **'빛나는뱃지'**
  String get evolutionNameConfidence1;

  /// 진화 단계 이름 2 - confidence
  ///
  /// In ko, this message translates to:
  /// **'황금뱃지'**
  String get evolutionNameConfidence2;

  /// 진화 단계 이름 3 - confidence
  ///
  /// In ko, this message translates to:
  /// **'전설뱃지'**
  String get evolutionNameConfidence3;

  /// 진화 단계 이름 0 - tired
  ///
  /// In ko, this message translates to:
  /// **'꾸벅이'**
  String get evolutionNameTired0;

  /// 진화 단계 이름 1 - tired
  ///
  /// In ko, this message translates to:
  /// **'나른이'**
  String get evolutionNameTired1;

  /// 진화 단계 이름 2 - tired
  ///
  /// In ko, this message translates to:
  /// **'포근이'**
  String get evolutionNameTired2;

  /// 진화 단계 이름 3 - tired
  ///
  /// In ko, this message translates to:
  /// **'포근달빛'**
  String get evolutionNameTired3;

  /// 진화 단계 이름 0 - boredom
  ///
  /// In ko, this message translates to:
  /// **'심심소용돌이'**
  String get evolutionNameBoredom0;

  /// 진화 단계 이름 1 - boredom
  ///
  /// In ko, this message translates to:
  /// **'꼬물소용돌이'**
  String get evolutionNameBoredom1;

  /// 진화 단계 이름 2 - boredom
  ///
  /// In ko, this message translates to:
  /// **'반짝소용돌이'**
  String get evolutionNameBoredom2;

  /// 진화 단계 이름 3 - boredom
  ///
  /// In ko, this message translates to:
  /// **'별빛소용돌이'**
  String get evolutionNameBoredom3;

  /// 진화 단계 이름 0 - courage
  ///
  /// In ko, this message translates to:
  /// **'용기방패'**
  String get evolutionNameCourage0;

  /// 진화 단계 이름 1 - courage
  ///
  /// In ko, this message translates to:
  /// **'단단방패'**
  String get evolutionNameCourage1;

  /// 진화 단계 이름 2 - courage
  ///
  /// In ko, this message translates to:
  /// **'빛나는방패'**
  String get evolutionNameCourage2;

  /// 진화 단계 이름 3 - courage
  ///
  /// In ko, this message translates to:
  /// **'수호방패'**
  String get evolutionNameCourage3;

  /// 진화 단계 이름 0 - thrill
  ///
  /// In ko, this message translates to:
  /// **'신남스파크'**
  String get evolutionNameThrill0;

  /// 진화 단계 이름 1 - thrill
  ///
  /// In ko, this message translates to:
  /// **'통통스파크'**
  String get evolutionNameThrill1;

  /// 진화 단계 이름 2 - thrill
  ///
  /// In ko, this message translates to:
  /// **'팡팡스파크'**
  String get evolutionNameThrill2;

  /// 진화 단계 이름 3 - thrill
  ///
  /// In ko, this message translates to:
  /// **'은하스파크'**
  String get evolutionNameThrill3;

  /// 진화 단계 이름 0 - happiness
  ///
  /// In ko, this message translates to:
  /// **'행복햇살'**
  String get evolutionNameHappiness0;

  /// 진화 단계 이름 1 - happiness
  ///
  /// In ko, this message translates to:
  /// **'따뜻햇살'**
  String get evolutionNameHappiness1;

  /// 진화 단계 이름 2 - happiness
  ///
  /// In ko, this message translates to:
  /// **'온누리햇살'**
  String get evolutionNameHappiness2;

  /// 진화 단계 이름 3 - happiness
  ///
  /// In ko, this message translates to:
  /// **'영원한햇살'**
  String get evolutionNameHappiness3;

  /// 몬스터를 먹는 순간 뜨는 한 줄(1회)
  ///
  /// In ko, this message translates to:
  /// **'냠! {label}, 마음에 품었어요'**
  String gameEatenLineSingle(String label);

  /// 몬스터를 연속으로 먹었을 때 뜨는 한 줄
  ///
  /// In ko, this message translates to:
  /// **'{label}가 {streak}번 연속!'**
  String gameEatenLineStreak(String label, int streak);

  /// 긍정 감정을 받는 순간 뜨는 한 줄(1회)
  ///
  /// In ko, this message translates to:
  /// **'포근! {label}이(가) 가슴에 스며들었어요'**
  String gameReceivedLineSingle(String label);

  /// 긍정 감정을 연속으로 받았을 때 뜨는 한 줄
  ///
  /// In ko, this message translates to:
  /// **'{label}가 {streak}번 연속으로 빛나요 ✨'**
  String gameReceivedLineStreak(String label, int streak);

  /// 처음 만난 감정 몬스터 라벨링 컷인 캡션
  ///
  /// In ko, this message translates to:
  /// **'🏷️ 처음 만난 마음이에요'**
  String get gameFirstMeetCaption;

  /// 주먹 타이밍이 완벽했을 때 뜨는 FloatingLabel
  ///
  /// In ko, this message translates to:
  /// **'완벽 타이밍! ✨'**
  String get gamePerfectTimingLabel;

  /// 돌멩이에 부딪혔을 때 뜨는 FloatingLabel
  ///
  /// In ko, this message translates to:
  /// **'아얏! 😳'**
  String get gameRockHitLabel;

  /// 부활 후 뜨는 격려 FloatingLabel
  ///
  /// In ko, this message translates to:
  /// **'다시 힘내볼게요! 💪'**
  String get gameReviveEncouragementLabel;

  /// 시간 제한으로 스테이지가 끝났을 때 뜨는 FloatingLabel
  ///
  /// In ko, this message translates to:
  /// **'시간이 다 됐어요! {count}개 만났어요 ⏰'**
  String gameTimeUpLabel(int count);

  /// 엔드리스 모드에서 목숨 소진으로 조기 종료됐을 때 뜨는 짧은 FloatingLabel
  ///
  /// In ko, this message translates to:
  /// **'오늘의 도전, {count}개까지 왔어요! 🤍'**
  String gameEarlyStopShortEndless(int count);

  /// 일반 모드에서 목숨 소진으로 조기 종료됐을 때 뜨는 짧은 FloatingLabel
  ///
  /// In ko, this message translates to:
  /// **'오늘은 {count}개 만나고 여기까지 왔어요 🤍'**
  String gameEarlyStopShortNormal(int count);

  /// 스테이지를 목표까지 다 채우고 클리어했을 때 뜨는 FloatingLabel
  ///
  /// In ko, this message translates to:
  /// **'골골~ 😽'**
  String get gameStageClearPurrLabel;

  /// 호흡 미니게임 성공으로 생명이 회복됐을 때 뜨는 FloatingLabel
  ///
  /// In ko, this message translates to:
  /// **'숨을 잘 골랐어요! 💗'**
  String get gameBreathingLifeRestoredLabel;

  /// 호흡 미니게임 성공(생명이 이미 가득 차 진행도 보너스를 받을 때) 뜨는 FloatingLabel
  ///
  /// In ko, this message translates to:
  /// **'숨을 잘 골랐어요! ✨'**
  String get gameBreathingBonusLabel;

  /// 호흡 미니게임을 건너뛰거나 실패했을 때 뜨는 FloatingLabel
  ///
  /// In ko, this message translates to:
  /// **'잠깐 쉬어갔어요 🌿'**
  String get gameBreathingSkippedLabel;

  /// 파워빛볼을 먹어 무적 모드가 시작됐을 때 뜨는 FloatingLabel
  ///
  /// In ko, this message translates to:
  /// **'무적 모드! 💥⚡'**
  String get gamePowerModeActivatedLabel;

  /// 무적 모드 중 장애물을 부수고 지나갈 때 뜨는 FloatingLabel
  ///
  /// In ko, this message translates to:
  /// **'펑! 💥'**
  String get gamePowerSmashLabel;

  /// 반짝이는 보너스 간식을 먹었을 때 뜨는 FloatingLabel
  ///
  /// In ko, this message translates to:
  /// **'반짝 보너스! ✨ +2'**
  String get gameTreatBonusLabel;

  /// 하트 아이템을 먹어 생명이 회복됐을 때 뜨는 FloatingLabel
  ///
  /// In ko, this message translates to:
  /// **'생명 회복! 💗'**
  String get gameHeartRestoredLabel;

  /// 설정 - 이용약관 카드 제목
  ///
  /// In ko, this message translates to:
  /// **'이용약관'**
  String get settingsTermsOfService;

  /// 이용약관 화면 - 헤더 제목
  ///
  /// In ko, this message translates to:
  /// **'📜 이용약관'**
  String get termsHeaderTitle;

  /// 이용약관 화면 - 상단 소개문
  ///
  /// In ko, this message translates to:
  /// **'몽이 힐링가든 서비스를 이용해주셔서 감사해요. 이 약관은 서비스 이용과 관련한 몽이(사업자)와 이용자 간의 권리·의무를 안내해요.'**
  String get termsIntro;

  /// 이용약관 화면 - 1번 섹션 제목
  ///
  /// In ko, this message translates to:
  /// **'1. 서비스의 제공'**
  String get termsSection1Title;

  /// 이용약관 화면 - 1번 섹션 본문
  ///
  /// In ko, this message translates to:
  /// **'몽이 힐링가든은 감정 기록, 마음정원 가꾸기, 미니게임 등 힐링 콘텐츠를 제공하는 모바일 애플리케이션이에요. 서비스의 일부 또는 전체는 사전 고지 없이 변경·중단될 수 있어요.'**
  String get termsSection1Body;

  /// 이용약관 화면 - 2번 섹션 제목
  ///
  /// In ko, this message translates to:
  /// **'2. 인앱 구매 및 결제'**
  String get termsSection2Title;

  /// 이용약관 화면 - 2번 섹션 본문
  ///
  /// In ko, this message translates to:
  /// **'앱 내 유료 아이템(프리미엄 프레임, 정원 장식, 시즌 패스, 빛의 정수 등)은 Google Play 결제 시스템을 통해 구매하며, 결제 즉시 디지털 콘텐츠가 제공돼요. 관련 법령이 정하는 바에 따라 청약 철회가 제한될 수 있고, 환불은 Google Play 정책을 따라요.'**
  String get termsSection2Body;

  /// 이용약관 화면 - 3번 섹션 제목
  ///
  /// In ko, this message translates to:
  /// **'3. 광고'**
  String get termsSection3Title;

  /// 이용약관 화면 - 3번 섹션 본문
  ///
  /// In ko, this message translates to:
  /// **'서비스 운영을 위해 Google AdMob을 통한 광고(배너/전면/리워드)가 표시될 수 있어요. 리워드 광고 시청은 선택 사항이며, 시청 여부와 관계없이 핵심 기능은 계속 이용할 수 있어요.'**
  String get termsSection3Body;

  /// 이용약관 화면 - 4번 섹션 제목
  ///
  /// In ko, this message translates to:
  /// **'4. 이용자의 의무'**
  String get termsSection4Title;

  /// 이용약관 화면 - 4번 섹션 본문
  ///
  /// In ko, this message translates to:
  /// **'이용자는 서비스를 부정한 방법으로 조작·변조하거나 타인의 이용을 방해하는 행위를 해서는 안 돼요. 이를 위반할 경우 서비스 이용이 제한될 수 있어요.'**
  String get termsSection4Body;

  /// 이용약관 화면 - 5번 섹션 제목
  ///
  /// In ko, this message translates to:
  /// **'5. 면책 및 정신건강 콘텐츠 안내'**
  String get termsSection5Title;

  /// 이용약관 화면 - 5번 섹션 본문
  ///
  /// In ko, this message translates to:
  /// **'몽이 안의 정신건강 지원 정보(상담 전화·문자 등)는 참고용 안내이며, 전문적인 의료·심리 상담을 대체하지 않아요. 긴급한 위기 상황에서는 반드시 각국의 응급 서비스나 전문기관에 즉시 연락해주세요.'**
  String get termsSection5Body;

  /// 이용약관 화면 - 6번 섹션 제목
  ///
  /// In ko, this message translates to:
  /// **'6. 약관의 변경'**
  String get termsSection6Title;

  /// 이용약관 화면 - 6번 섹션 본문
  ///
  /// In ko, this message translates to:
  /// **'이 약관은 관련 법령 및 서비스 변경에 따라 수정될 수 있으며, 중요한 변경 시 앱 내 공지를 통해 알려드려요. 변경된 약관에 동의하지 않는 경우 서비스 이용을 중단할 수 있어요.'**
  String get termsSection6Body;

  /// 이용약관 화면 - 마지막 개정일 값(고정된 날짜)
  ///
  /// In ko, this message translates to:
  /// **'2026년 8월 25일'**
  String get termsLastUpdatedDate;

  /// 이용약관 화면 - 마지막 개정일 라벨
  ///
  /// In ko, this message translates to:
  /// **'마지막 개정일: {date}'**
  String termsLastUpdatedLabel(String date);

  /// 홈 화면 마음 챌린지 배너 - 진행 중일 때 제목
  ///
  /// In ko, this message translates to:
  /// **'{emoji} {title} · {day}/{total}일차'**
  String mindChallengeHomeBannerTitleActive(
    String emoji,
    String title,
    int day,
    int total,
  );

  /// 홈 화면 마음 챌린지 배너 - 진행 중인 챌린지가 없을 때 제목
  ///
  /// In ko, this message translates to:
  /// **'🌿 마음 챌린지 시작하기'**
  String get mindChallengeHomeBannerTitleInactive;

  /// 홈 화면 마음 챌린지 배너 - 진행 중일 때 부제목
  ///
  /// In ko, this message translates to:
  /// **'오늘의 체크인으로 오늘 몫을 채워요'**
  String get mindChallengeHomeBannerSubtitleActive;

  /// 홈 화면 마음 챌린지 배너 - 진행 중인 챌린지가 없을 때 부제목
  ///
  /// In ko, this message translates to:
  /// **'7일 테마 여정으로 마음을 돌봐요'**
  String get mindChallengeHomeBannerSubtitleInactive;

  /// 마음 챌린지 목록 화면 앱바 제목
  ///
  /// In ko, this message translates to:
  /// **'마음 챌린지'**
  String get mindChallengeListAppBarTitle;

  /// 마음 챌린지 목록 화면 상단 헤드라인
  ///
  /// In ko, this message translates to:
  /// **'테마를 하나 골라, 7일 동안 함께해요'**
  String get mindChallengeListHeadline;

  /// 마음 챌린지 목록 화면 상단 서브 설명
  ///
  /// In ko, this message translates to:
  /// **'매일 오늘의 감정 체크인을 하면 챌린지가 자연스럽게 진행돼요'**
  String get mindChallengeListSubtitle;

  /// 챌린지 카드 - 기간 표시
  ///
  /// In ko, this message translates to:
  /// **'{days}일 여정'**
  String mindChallengeCardDurationLabel(int days);

  /// 챌린지 카드 - 시작 버튼
  ///
  /// In ko, this message translates to:
  /// **'시작하기'**
  String get mindChallengeCardStartButton;

  /// 챌린지 카드 - 진행 중인 챌린지 이어보기 버튼
  ///
  /// In ko, this message translates to:
  /// **'이어서 보기'**
  String get mindChallengeCardContinueButton;

  /// 챌린지 카드 - 진행 중 뱃지
  ///
  /// In ko, this message translates to:
  /// **'진행 중'**
  String get mindChallengeCardInProgressBadge;

  /// 챌린지 카드 - 완주 경험이 있음을 나타내는 뱃지
  ///
  /// In ko, this message translates to:
  /// **'완주함'**
  String get mindChallengeCardCompletedBadge;

  /// 챌린지 시작 확인 다이얼로그 제목
  ///
  /// In ko, this message translates to:
  /// **'이 챌린지를 시작할까요?'**
  String get mindChallengeStartConfirmTitle;

  /// 챌린지 시작 확인 다이얼로그 본문
  ///
  /// In ko, this message translates to:
  /// **'매일 감정 체크인을 하면 하루씩 진행돼요. {days}일을 모두 채우면 특별한 보상을 받을 수 있어요.'**
  String mindChallengeStartConfirmBody(int days);

  /// 이미 다른 챌린지가 진행 중일 때 교체 확인 문구
  ///
  /// In ko, this message translates to:
  /// **'다른 챌린지가 진행 중이에요. 새 챌린지를 시작하면 지금까지의 진행도는 사라져요. 계속할까요?'**
  String get mindChallengeStartConfirmReplaceBody;

  /// 챌린지 시작 확인 다이얼로그 - 확인 버튼
  ///
  /// In ko, this message translates to:
  /// **'시작하기'**
  String get mindChallengeStartConfirmButton;

  /// 챌린지 시작 완료 스낵바
  ///
  /// In ko, this message translates to:
  /// **'{title} 챌린지를 시작했어요!'**
  String mindChallengeStartedSnackbar(String title);

  /// 마음 챌린지 진행 화면 앱바 제목
  ///
  /// In ko, this message translates to:
  /// **'마음 챌린지'**
  String get mindChallengeDetailAppBarTitle;

  /// 마음 챌린지 진행 화면 - 오늘 며칠차인지
  ///
  /// In ko, this message translates to:
  /// **'{day} / {total}일차'**
  String mindChallengeDetailDayLabel(int day, int total);

  /// 마음 챌린지 진행 화면 - 전체 진행도
  ///
  /// In ko, this message translates to:
  /// **'지금까지 {done} / {total}일 완료'**
  String mindChallengeDetailProgressLabel(int done, int total);

  /// 마음 챌린지 진행 화면 - 오늘 이미 체크인 했을 때
  ///
  /// In ko, this message translates to:
  /// **'오늘 체크인 완료! 내일 또 만나요'**
  String get mindChallengeDetailCheckedInToday;

  /// 마음 챌린지 진행 화면 - 오늘 아직 체크인 안 했을 때
  ///
  /// In ko, this message translates to:
  /// **'오늘의 감정 체크인을 하면 오늘 몫이 채워져요'**
  String get mindChallengeDetailNotCheckedInYet;

  /// 마음 챌린지 진행 화면 - 완주 준비 완료 안내 제목
  ///
  /// In ko, this message translates to:
  /// **'축하해요! 챌린지를 모두 완료했어요'**
  String get mindChallengeDetailCompleteReadyTitle;

  /// 마음 챌린지 진행 화면 - 완주 보상 수령 버튼
  ///
  /// In ko, this message translates to:
  /// **'완주 보상 받기'**
  String get mindChallengeDetailCompleteButton;

  /// 마음 챌린지 완주 보상 수령 스낵바
  ///
  /// In ko, this message translates to:
  /// **'챌린지를 완주했어요! 보상을 받았어요'**
  String get mindChallengeDetailCompletedSnackbar;

  /// 마음 챌린지 진행 화면 - 포기 버튼
  ///
  /// In ko, this message translates to:
  /// **'챌린지 그만두기'**
  String get mindChallengeDetailAbandonButton;

  /// 마음 챌린지 포기 확인 다이얼로그 제목
  ///
  /// In ko, this message translates to:
  /// **'챌린지를 그만둘까요?'**
  String get mindChallengeDetailAbandonConfirmTitle;

  /// 마음 챌린지 포기 확인 다이얼로그 본문
  ///
  /// In ko, this message translates to:
  /// **'지금까지의 진행도가 사라져요. 그래도 그만둘까요?'**
  String get mindChallengeDetailAbandonConfirmBody;

  /// 마음 챌린지 포기 확인 다이얼로그 - 확인 버튼
  ///
  /// In ko, this message translates to:
  /// **'그만두기'**
  String get mindChallengeDetailAbandonConfirmButton;

  /// 마음 챌린지 진행 화면 - 일일 보상 안내
  ///
  /// In ko, this message translates to:
  /// **'하루 완료마다 💡+{reward}'**
  String mindChallengeDetailDayRewardLabel(int reward);

  /// 마음 챌린지 진행 화면 - 완주 보상 안내
  ///
  /// In ko, this message translates to:
  /// **'완주 보상 💡+{light} ⭐+{shard}'**
  String mindChallengeDetailCompletionRewardLabel(int light, int shard);

  /// 마음 챌린지 - 자존감 테마 제목
  ///
  /// In ko, this message translates to:
  /// **'자존감 돌보기'**
  String get mindChallengeTitleSelfEsteem;

  /// 마음 챌린지 - 자존감 테마 설명
  ///
  /// In ko, this message translates to:
  /// **'7일 동안 매일 나에게 다정한 말을 건네며 자존감을 천천히 채워가요.'**
  String get mindChallengeDescSelfEsteem;

  /// 마음 챌린지 - 자존감 1일차 안내
  ///
  /// In ko, this message translates to:
  /// **'1일차: 오늘 나에게 잘한 일 한 가지를 떠올려보세요.'**
  String get mindChallengeDaySelfEsteem1;

  /// 마음 챌린지 - 자존감 2일차 안내
  ///
  /// In ko, this message translates to:
  /// **'2일차: 거울 속 나에게 \"고생했어\"라고 말해보세요.'**
  String get mindChallengeDaySelfEsteem2;

  /// 마음 챌린지 - 자존감 3일차 안내
  ///
  /// In ko, this message translates to:
  /// **'3일차: 나의 장점 하나를 적어보세요.'**
  String get mindChallengeDaySelfEsteem3;

  /// 마음 챌린지 - 자존감 4일차 안내
  ///
  /// In ko, this message translates to:
  /// **'4일차: 오늘은 나를 비교하지 않는 날로 정해보세요.'**
  String get mindChallengeDaySelfEsteem4;

  /// 마음 챌린지 - 자존감 5일차 안내
  ///
  /// In ko, this message translates to:
  /// **'5일차: 작은 성취 하나에도 스스로를 칭찬해주세요.'**
  String get mindChallengeDaySelfEsteem5;

  /// 마음 챌린지 - 자존감 6일차 안내
  ///
  /// In ko, this message translates to:
  /// **'6일차: 나를 힘들게 하는 생각 하나를 조금 다르게 바라봐요.'**
  String get mindChallengeDaySelfEsteem6;

  /// 마음 챌린지 - 자존감 7일차 안내
  ///
  /// In ko, this message translates to:
  /// **'7일차: 지난 6일을 돌아보며 나에게 편지를 써보세요.'**
  String get mindChallengeDaySelfEsteem7;

  /// 마음 챌린지 - 불안 테마 제목
  ///
  /// In ko, this message translates to:
  /// **'불안 다스리기'**
  String get mindChallengeTitleAnxietyCalm;

  /// 마음 챌린지 - 불안 테마 설명
  ///
  /// In ko, this message translates to:
  /// **'7일 동안 매일 잠시 멈춰 숨을 고르며 불안한 마음을 가라앉혀요.'**
  String get mindChallengeDescAnxietyCalm;

  /// 마음 챌린지 - 불안 1일차 안내
  ///
  /// In ko, this message translates to:
  /// **'1일차: 지금 느끼는 불안에 이름을 붙여보세요.'**
  String get mindChallengeDayAnxietyCalm1;

  /// 마음 챌린지 - 불안 2일차 안내
  ///
  /// In ko, this message translates to:
  /// **'2일차: 천천히 숨을 4번 들이쉬고 내쉬어 보세요.'**
  String get mindChallengeDayAnxietyCalm2;

  /// 마음 챌린지 - 불안 3일차 안내
  ///
  /// In ko, this message translates to:
  /// **'3일차: 지금 당장 할 수 있는 아주 작은 일 하나만 해보세요.'**
  String get mindChallengeDayAnxietyCalm3;

  /// 마음 챌린지 - 불안 4일차 안내
  ///
  /// In ko, this message translates to:
  /// **'4일차: \"이 순간은 지나간다\"는 것을 떠올려보세요.'**
  String get mindChallengeDayAnxietyCalm4;

  /// 마음 챌린지 - 불안 5일차 안내
  ///
  /// In ko, this message translates to:
  /// **'5일차: 걱정을 종이에 적어 눈에 보이게 꺼내보세요.'**
  String get mindChallengeDayAnxietyCalm5;

  /// 마음 챌린지 - 불안 6일차 안내
  ///
  /// In ko, this message translates to:
  /// **'6일차: 오늘 하루, 확실한 것 세 가지를 찾아보세요.'**
  String get mindChallengeDayAnxietyCalm6;

  /// 마음 챌린지 - 불안 7일차 안내
  ///
  /// In ko, this message translates to:
  /// **'7일차: 일주일간 불안이 어떻게 변했는지 돌아보세요.'**
  String get mindChallengeDayAnxietyCalm7;

  /// 마음 챌린지 - 번아웃 테마 제목
  ///
  /// In ko, this message translates to:
  /// **'번아웃 회복'**
  String get mindChallengeTitleBurnoutRecovery;

  /// 마음 챌린지 - 번아웃 테마 설명
  ///
  /// In ko, this message translates to:
  /// **'7일 동안 매일 조금씩 쉬어가며 지친 마음을 회복해요.'**
  String get mindChallengeDescBurnoutRecovery;

  /// 마음 챌린지 - 번아웃 1일차 안내
  ///
  /// In ko, this message translates to:
  /// **'1일차: 오늘 하루, 꼭 하지 않아도 되는 일 하나를 내려놓아 보세요.'**
  String get mindChallengeDayBurnoutRecovery1;

  /// 마음 챌린지 - 번아웃 2일차 안내
  ///
  /// In ko, this message translates to:
  /// **'2일차: 잠깐이라도 아무것도 하지 않는 시간을 가져보세요.'**
  String get mindChallengeDayBurnoutRecovery2;

  /// 마음 챌린지 - 번아웃 3일차 안내
  ///
  /// In ko, this message translates to:
  /// **'3일차: 나를 지치게 하는 것 하나를 알아차려 보세요.'**
  String get mindChallengeDayBurnoutRecovery3;

  /// 마음 챌린지 - 번아웃 4일차 안내
  ///
  /// In ko, this message translates to:
  /// **'4일차: 좋아하는 것을 5분만 해보세요.'**
  String get mindChallengeDayBurnoutRecovery4;

  /// 마음 챌린지 - 번아웃 5일차 안내
  ///
  /// In ko, this message translates to:
  /// **'5일차: \"충분히 했다\"고 스스로에게 말해주세요.'**
  String get mindChallengeDayBurnoutRecovery5;

  /// 마음 챌린지 - 번아웃 6일차 안내
  ///
  /// In ko, this message translates to:
  /// **'6일차: 오늘은 평소보다 조금 일찍 쉬어보세요.'**
  String get mindChallengeDayBurnoutRecovery6;

  /// 마음 챌린지 - 번아웃 7일차 안내
  ///
  /// In ko, this message translates to:
  /// **'7일차: 이번 주 나를 돌본 방법들을 적어보세요.'**
  String get mindChallengeDayBurnoutRecovery7;

  /// 마음 챌린지 - 감사 테마 제목
  ///
  /// In ko, this message translates to:
  /// **'감사 습관 만들기'**
  String get mindChallengeTitleGratitudeHabit;

  /// 마음 챌린지 - 감사 테마 설명
  ///
  /// In ko, this message translates to:
  /// **'7일 동안 매일 감사한 순간을 찾아보며 긍정적인 시선을 길러요.'**
  String get mindChallengeDescGratitudeHabit;

  /// 마음 챌린지 - 감사 1일차 안내
  ///
  /// In ko, this message translates to:
  /// **'1일차: 오늘 감사했던 순간 하나를 떠올려보세요.'**
  String get mindChallengeDayGratitudeHabit1;

  /// 마음 챌린지 - 감사 2일차 안내
  ///
  /// In ko, this message translates to:
  /// **'2일차: 나를 도와준 사람 한 명을 생각해보세요.'**
  String get mindChallengeDayGratitudeHabit2;

  /// 마음 챌린지 - 감사 3일차 안내
  ///
  /// In ko, this message translates to:
  /// **'3일차: 당연하게 여겼던 것 하나에 감사해보세요.'**
  String get mindChallengeDayGratitudeHabit3;

  /// 마음 챌린지 - 감사 4일차 안내
  ///
  /// In ko, this message translates to:
  /// **'4일차: 오늘의 날씨나 풍경에서 좋은 점을 찾아보세요.'**
  String get mindChallengeDayGratitudeHabit4;

  /// 마음 챌린지 - 감사 5일차 안내
  ///
  /// In ko, this message translates to:
  /// **'5일차: 내가 가진 것 중 감사한 것 하나를 적어보세요.'**
  String get mindChallengeDayGratitudeHabit5;

  /// 마음 챌린지 - 감사 6일차 안내
  ///
  /// In ko, this message translates to:
  /// **'6일차: 오늘 나에게 있었던 작은 행운을 찾아보세요.'**
  String get mindChallengeDayGratitudeHabit6;

  /// 마음 챌린지 - 감사 7일차 안내
  ///
  /// In ko, this message translates to:
  /// **'7일차: 일주일간 발견한 감사한 순간들을 돌아보세요.'**
  String get mindChallengeDayGratitudeHabit7;

  /// 마음 리포트 화면 - 마음 흐름 그래프 요약 카드 제목
  ///
  /// In ko, this message translates to:
  /// **'마음 흐름 그래프'**
  String get mindReportMoodTrendTitle;

  /// 마음 리포트 화면 - 마음 흐름 그래프, 데이터 부족 안내
  ///
  /// In ko, this message translates to:
  /// **'아직 데이터가 모이고 있어요. 조금 더 함께해주세요 🌱'**
  String get mindReportMoodTrendNotEnoughData;

  /// 마음 흐름 그래프 화면 - 헤더 제목
  ///
  /// In ko, this message translates to:
  /// **'마음 흐름 그래프'**
  String get moodTrendHeaderTitle;

  /// 마음 흐름 그래프 화면 - 소개 문구
  ///
  /// In ko, this message translates to:
  /// **'매일 남긴 감정 기록을 바탕으로, 최근 마음의 흐름을 그래프로 보여드려요. 점이 위에 있을수록 편안한 날, 아래에 있을수록 힘든 날이었어요.'**
  String get moodTrendIntroText;

  /// 마음 흐름 그래프 화면 - 7일 창 토글 라벨
  ///
  /// In ko, this message translates to:
  /// **'7일'**
  String get moodTrendWindow7Days;

  /// 마음 흐름 그래프 화면 - 14일 창 토글 라벨
  ///
  /// In ko, this message translates to:
  /// **'14일'**
  String get moodTrendWindow14Days;

  /// 마음 흐름 그래프 화면 - 30일 창 토글 라벨
  ///
  /// In ko, this message translates to:
  /// **'30일'**
  String get moodTrendWindow30Days;

  /// 마음 흐름 그래프 화면 - 데이터 부족 안내 제목
  ///
  /// In ko, this message translates to:
  /// **'아직 그래프를 그리기엔 일러요'**
  String get moodTrendNotEnoughTitle;

  /// 마음 흐름 그래프 화면 - 데이터 부족 안내 본문
  ///
  /// In ko, this message translates to:
  /// **'최소 4일 이상 감정을 기록하면\n마음의 흐름을 그래프로 볼 수 있어요'**
  String get moodTrendNotEnoughBody;

  /// 마음 흐름 그래프 화면 - 그래프 카드 제목
  ///
  /// In ko, this message translates to:
  /// **'마음 흐름'**
  String get moodTrendChartTitle;

  /// 마음 흐름 그래프 화면 - 그래프 카드, 함께한 횟수
  ///
  /// In ko, this message translates to:
  /// **'· 함께한 {count}번'**
  String moodTrendSessionsLabel(int count);

  /// 마음 흐름 그래프 화면 - 범례, 긍정 점
  ///
  /// In ko, this message translates to:
  /// **'편안한 날'**
  String get moodTrendLegendPositive;

  /// 마음 흐름 그래프 화면 - 범례, 부정 점
  ///
  /// In ko, this message translates to:
  /// **'힘들었던 날'**
  String get moodTrendLegendNegative;

  /// 마음 흐름 그래프 화면 - 흐름 관찰 문구, 데이터 부족
  ///
  /// In ko, this message translates to:
  /// **'아직 흐름을 판단하기엔 데이터가 조금 부족해요.'**
  String get moodTrendDirectionNotEnoughData;

  /// 마음 흐름 그래프 화면 - 흐름 관찰 문구, 개선 흐름
  ///
  /// In ko, this message translates to:
  /// **'최근 마음이 조금씩 편안해지고 있는 흐름이에요 🌤️'**
  String get moodTrendDirectionImproving;

  /// 마음 흐름 그래프 화면 - 흐름 관찰 문구, 잔잔함
  ///
  /// In ko, this message translates to:
  /// **'마음이 잔잔하게 흐르고 있어요. 지금처럼 꾸준히 기록해봐요 🤍'**
  String get moodTrendDirectionSteady;

  /// 마음 흐름 그래프 화면 - 흐름 관찰 문구, 하락 흐름
  ///
  /// In ko, this message translates to:
  /// **'요즘 마음이 조금 무거운 날들이 이어지고 있어요. 잠시 쉬어가도 괜찮아요 🫂'**
  String get moodTrendDirectionDeclining;

  /// 홈 화면 - 응원 우편함 배너 타이틀
  ///
  /// In ko, this message translates to:
  /// **'💌 몽이의 응원 우편함'**
  String get homeCheerBannerTitle;

  /// 홈 화면 - 응원 우편함 배너 서브타이틀, 오늘 보내기/받기 모두 완료
  ///
  /// In ko, this message translates to:
  /// **'오늘의 응원을 모두 주고받았어요'**
  String get homeCheerBannerSubtitleBothDone;

  /// 홈 화면 - 응원 우편함 배너 서브타이틀, 아직 안 받은 응원 있음
  ///
  /// In ko, this message translates to:
  /// **'오늘 도착한 응원이 있어요'**
  String get homeCheerBannerSubtitleHasNew;

  /// 홈 화면 - 응원 우편함 배너 서브타이틀, 기본
  ///
  /// In ko, this message translates to:
  /// **'작은 마음을 주고받아요'**
  String get homeCheerBannerSubtitleDefault;

  /// 홈 화면 - 응원 우편함 배너, 받을 응원이 있을 때 뱃지
  ///
  /// In ko, this message translates to:
  /// **'받기'**
  String get homeCheerBannerNewBadge;

  /// 응원 우편함 화면 - 앱바 타이틀
  ///
  /// In ko, this message translates to:
  /// **'몽이의 응원 우편함'**
  String get cheerScreenAppBarTitle;

  /// 응원 우편함 화면 - 정직성 안내 문구, 화면 상단에 항상 노출
  ///
  /// In ko, this message translates to:
  /// **'이 앱은 아직 다른 사람과 직접 연결되지 않아요. 대신 몽이가 마음을 이어줘요 🐱'**
  String get cheerScreenHonestyNotice;

  /// 응원 우편함 화면 - 보내기 섹션 제목
  ///
  /// In ko, this message translates to:
  /// **'마음 보내기'**
  String get cheerSendSectionTitle;

  /// 응원 우편함 화면 - 보내기 섹션 부제
  ///
  /// In ko, this message translates to:
  /// **'골라두면 몽이가 대신 세상에 전해줘요'**
  String get cheerSendSectionSubtitle;

  /// 응원 우편함 화면 - 오늘 이미 보낸 경우 안내
  ///
  /// In ko, this message translates to:
  /// **'오늘의 마음을 몽이에게 맡겼어요'**
  String get cheerSendDoneTitle;

  /// 응원 우편함 화면 - 오늘 이미 보낸 경우 부가 안내
  ///
  /// In ko, this message translates to:
  /// **'내일 또 다른 마음을 보낼 수 있어요'**
  String get cheerSendDoneSubtitle;

  /// 응원 우편함 화면 - 보내기 완료 스낵바
  ///
  /// In ko, this message translates to:
  /// **'몽이가 마음을 잘 전달했어요 💌'**
  String get cheerSendConfirmSnackbar;

  /// 응원 우편함 화면 - 받기 섹션 제목
  ///
  /// In ko, this message translates to:
  /// **'마음 받기'**
  String get cheerReceiveSectionTitle;

  /// 응원 우편함 화면 - 받기 버튼 라벨(아직 받지 않았을 때)
  ///
  /// In ko, this message translates to:
  /// **'오늘의 응원 열어보기'**
  String get cheerReceiveButtonLabel;

  /// 응원 우편함 화면 - 받은 응원 카드 상단 라벨
  ///
  /// In ko, this message translates to:
  /// **'누군가의 마음'**
  String get cheerReceiveCardLabel;

  /// 응원 우편함 화면 - 보상 획득 표시
  ///
  /// In ko, this message translates to:
  /// **'+{amount} 빛의 정수'**
  String cheerRewardEarned(int amount);

  /// 응원 우편함 - 보내기 문구 0
  ///
  /// In ko, this message translates to:
  /// **'오늘도 애썼어요. 당신 몫을 잘 해내고 있어요.'**
  String get cheerSendOption0;

  /// 응원 우편함 - 보내기 문구 1
  ///
  /// In ko, this message translates to:
  /// **'지금 이대로도 충분해요.'**
  String get cheerSendOption1;

  /// 응원 우편함 - 보내기 문구 2
  ///
  /// In ko, this message translates to:
  /// **'당신의 하루도, 마음도 소중해요.'**
  String get cheerSendOption2;

  /// 응원 우편함 - 보내기 문구 3
  ///
  /// In ko, this message translates to:
  /// **'잠깐 쉬어가도 괜찮아요.'**
  String get cheerSendOption3;

  /// 응원 우편함 - 보내기 문구 4
  ///
  /// In ko, this message translates to:
  /// **'당신은 생각보다 훨씬 잘하고 있어요.'**
  String get cheerSendOption4;

  /// 응원 우편함 - 보내기 문구 5
  ///
  /// In ko, this message translates to:
  /// **'오늘 하루도 무사히 지나갔어요. 그거면 충분해요.'**
  String get cheerSendOption5;

  /// 응원 우편함 - 받기 문구 0
  ///
  /// In ko, this message translates to:
  /// **'오늘 하루도 버텨낸 당신, 정말 잘했어요.'**
  String get cheerReceiveMessage0;

  /// 응원 우편함 - 받기 문구 1
  ///
  /// In ko, this message translates to:
  /// **'누군가 오늘 당신을 응원하고 있어요.'**
  String get cheerReceiveMessage1;

  /// 응원 우편함 - 받기 문구 2
  ///
  /// In ko, this message translates to:
  /// **'지금까지 걸어온 길, 절대 헛되지 않았어요.'**
  String get cheerReceiveMessage2;

  /// 응원 우편함 - 받기 문구 3
  ///
  /// In ko, this message translates to:
  /// **'당신은 혼자가 아니에요.'**
  String get cheerReceiveMessage3;

  /// 응원 우편함 - 받기 문구 4
  ///
  /// In ko, this message translates to:
  /// **'작은 걸음도 걸음이에요. 잘 가고 있어요.'**
  String get cheerReceiveMessage4;

  /// 응원 우편함 - 받기 문구 5
  ///
  /// In ko, this message translates to:
  /// **'완벽하지 않아도 괜찮아요. 그게 사람이에요.'**
  String get cheerReceiveMessage5;

  /// 응원 우편함 - 받기 문구 6
  ///
  /// In ko, this message translates to:
  /// **'오늘의 당신에게 박수를 보내요 👏'**
  String get cheerReceiveMessage6;

  /// 응원 우편함 - 받기 문구 7
  ///
  /// In ko, this message translates to:
  /// **'힘든 날엔 잠시 멈춰도 괜찮아요.'**
  String get cheerReceiveMessage7;

  /// 응원 우편함 - 받기 문구 8
  ///
  /// In ko, this message translates to:
  /// **'당신의 노력을 알아주는 사람이 있어요.'**
  String get cheerReceiveMessage8;

  /// 응원 우편함 - 받기 문구 9
  ///
  /// In ko, this message translates to:
  /// **'오늘도 스스로를 조금 더 다정하게 대해줘요.'**
  String get cheerReceiveMessage9;

  /// 응원 우편함 - 받기 문구 10
  ///
  /// In ko, this message translates to:
  /// **'지금 이 순간에도 당신은 자라고 있어요.'**
  String get cheerReceiveMessage10;

  /// 응원 우편함 - 받기 문구 11
  ///
  /// In ko, this message translates to:
  /// **'괜찮지 않아도 괜찮아요. 그런 날도 있는 거예요.'**
  String get cheerReceiveMessage11;

  /// 응원 우편함 - 받기 문구 12
  ///
  /// In ko, this message translates to:
  /// **'당신이 여기 있어줘서 다행이에요.'**
  String get cheerReceiveMessage12;

  /// 응원 우편함 - 받기 문구 13
  ///
  /// In ko, this message translates to:
  /// **'오늘 하루, 스스로에게 참 잘했다고 말해줘요.'**
  String get cheerReceiveMessage13;

  /// 응원 우편함 - 받기 문구 14
  ///
  /// In ko, this message translates to:
  /// **'당신의 속도로 가도 충분해요.'**
  String get cheerReceiveMessage14;

  /// 응원 우편함 - 받기 문구 15
  ///
  /// In ko, this message translates to:
  /// **'누군가 당신의 안녕을 진심으로 바라고 있어요.'**
  String get cheerReceiveMessage15;

  /// 마음 성찰 - 감정×요일 교차 통찰
  ///
  /// In ko, this message translates to:
  /// **'{weekday}마다 {emotion} 감정이 유독 자주 떠올랐어요. 최근에 {count}번이나 나타났답니다.'**
  String mindReflectionEmotionWeekdayLink(
    String emotion,
    String weekday,
    int count,
  );

  /// 마음 성찰 - 원인×부정감정 교차 통찰
  ///
  /// In ko, this message translates to:
  /// **'\'{trigger}\'이(가) 힘든 감정과 자주 함께 나타났어요. 최근 {count}번 정도요.'**
  String mindReflectionTriggerNegativeLink(String trigger, int count);

  /// 마음 성찰 - 성장 신호 통찰
  ///
  /// In ko, this message translates to:
  /// **'예전보다 {emotion} 감정이 눈에 띄게 줄었어요. 조금씩 마음이 편해지고 있는 것 같아요.'**
  String mindReflectionGrowthSignal(String emotion);

  /// 마음 성찰 - 감사기록×무드 교차 통찰
  ///
  /// In ko, this message translates to:
  /// **'감사한 일을 기록한 날은 다른 날보다 마음이 더 편안했어요.'**
  String get mindReflectionGratitudeMoodLink;

  /// 마음 성찰 - 꾸준함 신호 통찰
  ///
  /// In ko, this message translates to:
  /// **'{streak}일 연속으로 마음을 들여다봤어요. 꾸준함 자체가 큰 힘이에요.'**
  String mindReflectionConsistencySignal(int streak);

  /// 마음 성찰 - 뚜렷한 패턴이 없을 때 기본 문구
  ///
  /// In ko, this message translates to:
  /// **'아직 뚜렷한 패턴은 안 보이지만, 계속 기록하다 보면 몽이가 더 많은 걸 발견해줄 거예요.'**
  String get mindReflectionDefaultObservation;

  /// 설정 - 마음 성찰(옵트인 AI 리플렉션) 카드 제목
  ///
  /// In ko, this message translates to:
  /// **'🌿 마음 성찰'**
  String get settingsAiReflectionTitle;

  /// 설정 - 마음 성찰 카드 설명
  ///
  /// In ko, this message translates to:
  /// **'여러 기록을 모아 몽이가 마음의 패턴을 짚어드려요. 서버로 전송되지 않고, 이 기기 안에서만 계산돼요. 원하실 때 언제든 끌 수 있어요.'**
  String get settingsAiReflectionDesc;

  /// 마음 리포트 - 마음 성찰 카드 제목
  ///
  /// In ko, this message translates to:
  /// **'몽이의 마음 성찰'**
  String get mindReportReflectionTitle;

  /// 마음 리포트 - 마음 성찰 옵트인 유도 문구
  ///
  /// In ko, this message translates to:
  /// **'여러 기록을 모아 더 깊은 통찰을 보여드릴 수 있어요. 설정에서 켜보시겠어요?'**
  String get mindReportReflectionOptInPrompt;

  /// 마음 리포트 - 마음 성찰 옵트인 유도 버튼
  ///
  /// In ko, this message translates to:
  /// **'설정에서 켜기'**
  String get mindReportReflectionOptInButton;

  /// 마음 리포트 - 마음 성찰 데이터 부족 안내
  ///
  /// In ko, this message translates to:
  /// **'아직 기록이 조금 더 필요해요. 일기를 5개 이상 남겨주세요.'**
  String get mindReportReflectionNotEnoughData;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
