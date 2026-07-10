import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/storage_service.dart';
import 'services/sound_service.dart';
import 'services/cat_care_service.dart';
import 'services/daily_card_service.dart';
import 'services/emotion_service.dart';
import 'providers/app_state_provider.dart';
import 'providers/cat_care_provider.dart';
import 'providers/daily_card_provider.dart';
import 'providers/emotion_provider.dart';
import 'theme.dart';
import 'widgets/stars_background.dart';
import 'screens/home_screen.dart';
import 'screens/welcome_intro_screen.dart';
import 'screens/video_intro_screen.dart';

/// 로그인 없이 기기 하나당 하나의 로컬 사용자로 동작합니다.
/// (추후 로그인 기능을 다시 켤 수 있도록 auth 관련 파일들은 삭제하지 않고 보존합니다)
const String _localUserId = 'local_user';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  await SoundService().init();
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
        ChangeNotifierProvider(create: (_) => EmotionProvider()),
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
  bool _needsWelcomeIntro = false;
  bool _needsVideoIntro = true;

  @override
  void initState() {
    super.initState();
    CatCareService.setCurrentUser(_localUserId);
    DailyCardService.setCurrentUser(_localUserId);
    EmotionService.setCurrentUser(_localUserId);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final appState = context.read<AppStateProvider>();
      final catCare = context.read<CatCareProvider>();
      final dailyCard = context.read<DailyCardProvider>();
      final emotion = context.read<EmotionProvider>();
      await appState.init(_localUserId);
      await catCare.load();
      await dailyCard.load();
      await emotion.load();
      if (!mounted) return;
      setState(() {
        // 웰컴 투어는 최초 1회가 아니라, 인트로 영상처럼 앱에 들어갈 때마다 보여줍니다.
        _needsWelcomeIntro = true;
        _dataLoaded = true;
      });
    });
  }

  void _onWelcomeIntroFinished() {
    // 웰컴 투어를 마치면 홈이 아니라, 바로 "고양이선택" 탭으로 이어져
    // 곧바로 첫 감정 고양이를 만나고 첫 편지/명상 여정을 시작할 수 있게 합니다.
    context.read<AppStateProvider>().requestHomeTab(1);
    setState(() => _needsWelcomeIntro = false);
  }

  void _onVideoIntroFinished() {
    setState(() => _needsVideoIntro = false);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.easeIn,
      switchOutCurve: Curves.easeOut,
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: _needsVideoIntro
          ? VideoIntroScreen(
              key: const ValueKey('videoIntro'),
              onFinished: _onVideoIntroFinished,
            )
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
