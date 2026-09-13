import 'widgets/app_lock_gate.dart';
import 'screens/startup_recovery_screen.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'services/cloud_service.dart';
import 'services/auto_backup_service.dart';
import 'services/backup_service.dart';
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
import 'services/subscription_service.dart';
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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }
  var storageReady = false;
  var resuming = true;
  try {
    await AnalyticsService().loadConsent();
    await StorageService.init();
    storageReady = true;
    await BackupService.resumePending();
    resuming = false;
    await _launchGarden();
  } catch (e, st) {
    debugPrint('main() failed: $e');
    debugPrint('$st');
    runApp(StartupRecoveryApp(retry: main, canDefer: storageReady && resuming));
  }
}

Future<void> _launchGarden() async {
  if (CloudService.enabled) {
    try { await FirebaseAppCheck.instance.activate(androidProvider: AndroidProvider.playIntegrity); }
    catch (_) { /* Cloud requests remain unavailable until attestation succeeds. */ }
  }
  await StorageService.recordInstallDateIfNeeded();
  // guest → local_user 누적 데이터 복구 후, Storage도 처음부터 local_user로 연다.
  await StorageService.migrateGuestScopeIfNeeded(_localUserId);
  await StorageService.setCurrentUser(_localUserId);
  CatCareService.setCurrentUser(_localUserId);
  DailyCardService.setCurrentUser(_localUserId);
  BubbleGardenService.setCurrentUser(_localUserId);
  await PromiseService.setCurrentUser(_localUserId);
  await SpecialLetterService.setCurrentUser(_localUserId);
  await AnalyticsService().logRetentionMilestoneIfNeeded();
  await SoundService().init();
  await NotificationService().init();
  await NotificationService().restoreIfEnabled();
  await SubscriptionService().init();
  await initializeDateFormatting('ko_KR', null);
  runApp(const MysticCatApp());
  AutoBackupService.instance.start();
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
        builder: (_, child) => AppLockGate(child: child!),
        title: '마음냥 정원',
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
  bool _bootstrapFailed = false;
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
    // main()에서 이미 setCurrentUser 했지만, 위젯 재생성 시에도 동기 UID를 보장합니다.
    // (Hive 비동기 오픈은 _bootstrap에서 await)
    CatCareService.setCurrentUser(_localUserId);
    DailyCardService.setCurrentUser(_localUserId);
    BubbleGardenService.setCurrentUser(_localUserId);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    if (mounted) setState(() => _bootstrapFailed = false);
    try {
      await PromiseService.setCurrentUser(_localUserId);
      await SpecialLetterService.setCurrentUser(_localUserId);
      await BuriedEmotionService.setCurrentUser(_localUserId);
      await CatMemoryService.setCurrentUser(_localUserId);
      await UsageHistoryService.setCurrentUser(_localUserId);
      final signedUp = await StorageService.isOnboardingCompleted();
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
      if (mounted) setState(() {
        _needsWelcomeIntro = !signedUp;
        _introChecked = true;
        _dataLoaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _bootstrapFailed = true);
    }
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
    if (_bootstrapFailed) return Scaffold(body: SafeArea(child: Center(child: Column(
      mainAxisSize: MainAxisSize.min, children: [
        const Text('기록을 불러오지 못했어요. 기록을 삭제하지 않고 다시 시도할 수 있어요.'),
        FilledButton(onPressed: _bootstrap, child: const Text('다시 불러오기')),
      ],
    ))));
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
                  '마음냥 정원',
                  style: brandFont(
                    fontSize: 26,
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
