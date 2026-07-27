import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/storage_service.dart';
import 'services/sound_service.dart';
import 'services/notification_service.dart';
import 'services/cat_care_service.dart';
import 'services/daily_card_service.dart';
import 'services/promise_service.dart';
import 'services/bubble_garden_service.dart';
import 'services/special_letter_service.dart';
import 'services/buried_emotion_service.dart';
import 'services/analytics_service.dart';
import 'services/cat_memory_service.dart';
import 'services/usage_history_service.dart';
import 'providers/app_state_provider.dart';
import 'providers/cat_care_provider.dart';
import 'providers/daily_card_provider.dart';
import 'providers/promise_provider.dart';
import 'providers/bubble_garden_provider.dart';
import 'providers/buried_emotion_provider.dart';
import 'theme.dart';
import 'widgets/stars_background.dart';
import 'screens/home_screen.dart';
import 'screens/welcome_intro_screen.dart';

/// 로그인 없이 기기 하나당 하나의 로컬 사용자로 동작합니다.
const String _localUserId = 'local_user';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }
  await StorageService.init();
  await StorageService.recordInstallDateIfNeeded();
  await AnalyticsService().logRetentionMilestoneIfNeeded();
  await SoundService().init();
  await NotificationService().init();
  await NotificationService().restoreIfEnabled();
  await initializeDateFormatting('ko_KR', null);
  runApp(const MysticCatApp());
}

class MysticCatApp extends StatelessWidget {
  const MysticCatApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
        ChangeNotifierProvider(create: (_) => CatCareProvider()),
        ChangeNotifierProvider(create: (_) => DailyCardProvider()),
        ChangeNotifierProvider(create: (_) => PromiseProvider()),
        ChangeNotifierProvider(create: (_) => BubbleGardenProvider()),
        ChangeNotifierProvider(create: (_) => BuriedEmotionProvider()),
      ],
      child: MaterialApp(
        title: '고양이 그림자 정원',
        debugShowCheckedModeBanner: false,
        theme: appTheme,
        home: const _AppRoot(),
      ),
    );
  }
}

class _AppRoot extends StatefulWidget {
  const _AppRoot();
  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  bool _dataLoaded = false;
  // "회원가입"(온보딩 완료) 여부가 인트로 게이트입니다.
  // 아직 가입하지 않았다면 앱을 실행할 때마다(재실행 포함) 3단계 웰컴
  // 투어(이름짓기 → 컨셉 소개 → 여정 시작)를 보여줍니다. 웰컴 투어를 마치면
  // 곧바로 "고양이선택" 탭으로 이동해, 사용자가 실제로 고양이를 고르고
  // 편지를 쓰려는 순간에 자연스럽게 가입유도(온보딩) 화면이 뜨게 됩니다
  // (별도 라우트). 이미 가입이 완료되어 있다면 인트로를 전부 건너뛰고
  // 곧바로 홈으로 진입합니다.
  bool _introChecked = false;
  bool _needsWelcomeIntro = false;

  @override
  void initState() {
    super.initState();
    CatCareService.setCurrentUser(_localUserId);
    DailyCardService.setCurrentUser(_localUserId);
    PromiseService.setCurrentUser(_localUserId);
    BubbleGardenService.setCurrentUser(_localUserId);
    SpecialLetterService.setCurrentUser(_localUserId);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // BuriedEmotionService는 Hive Box를 열어야 해서(비동기) 다른 서비스처럼
    // initState에서 바로 호출하지 않고, 다른 부트스트랩 작업과 함께 여기서
    // await합니다.
    await BuriedEmotionService.setCurrentUser(_localUserId);
    // 편지 생성 시스템(신규 8모듈 조합 엔진)이 사용하는 계정별 Hive Box.
    await CatMemoryService.setCurrentUser(_localUserId);
    await UsageHistoryService.setCurrentUser(_localUserId);
    final signedUp = await StorageService.isOnboardingCompleted();
    if (!mounted) return;
    setState(() {
      _needsWelcomeIntro = !signedUp;
      _introChecked = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final appState = context.read<AppStateProvider>();
      final catCare = context.read<CatCareProvider>();
      final dailyCard = context.read<DailyCardProvider>();
      final promise = context.read<PromiseProvider>();
      final buriedEmotion = context.read<BuriedEmotionProvider>();
      await appState.init(_localUserId);
      await catCare.load();
      await dailyCard.load();
      await promise.load();
      await buriedEmotion.load();
      if (!mounted) return;
      setState(() {
        _dataLoaded = true;
      });
    });
  }

  void _onWelcomeIntroFinished() async {
    await StorageService.setWelcomeIntroCompleted();
    if (!mounted) return;
    // 웰컴 투어를 마치면 홈이 아니라, 바로 "고양이선택" 탭으로 이어져
    // 곧바로 첫 감정 고양이를 만나고 첫 편지/명상 여정을 시작할 수 있게 합니다.
    context.read<AppStateProvider>().requestHomeTab(1);
    setState(() => _needsWelcomeIntro = false);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.easeIn,
      switchOutCurve: Curves.easeOut,
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: !_introChecked
          ? const _LoadingSplash(key: ValueKey('loading'))
          : !_dataLoaded
          ? const _LoadingSplash(key: ValueKey('loading'))
          : _needsWelcomeIntro
          ? WelcomeIntroScreen(
              key: const ValueKey('welcomeIntro'),
              onFinished: _onWelcomeIntroFinished,
            )
          : GestureDetector(
              key: const ValueKey('home'),
              behavior: HitTestBehavior.translucent,
              onTap: () {
                SoundService().tryStartBgm();
              },
              child: const HomeScreen(),
            ),
    );
  }
}

/// 데이터 로딩 중에만 잠깐 보이는 아주 단순한 스플래시 화면.
/// 별도의 서사 애니메이션 없이, 앱의 기본 배경(GardenScaffoldBackground)과
/// 로고, 로딩 인디케이터만 보여줍니다.
class _LoadingSplash extends StatelessWidget {
  const _LoadingSplash({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GardenScaffoldBackground(
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Color(0xFFFFF6DF),
                        AppColors.goldSoft,
                        AppColors.gold,
                      ],
                      stops: [0, 0.55, 1],
                    ),
                  ),
                  child: const Text('🐈‍⬛', style: TextStyle(fontSize: 30)),
                ),
                const SizedBox(height: 18),
                Text(
                  '고양이 그림자 정원',
                  style: titleFont(
                    fontSize: 20,
                    color: AppColors.titlePastelGreen,
                  ),
                ),
                const SizedBox(height: 20),
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: AppColors.gold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
