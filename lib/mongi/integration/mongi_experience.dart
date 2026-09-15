import '../../theme.dart';
import '../../services/sound_service.dart';
import '../../services/media_coordinator.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/garden_provider.dart';
import '../screens/emotion_input_screen.dart';
import '../screens/onboarding_screen.dart';
import '../services/sound_manager.dart';
import '../services/notification_service.dart';
import '../l10n/gen/app_localizations.dart';

/// Original Mongi navigation stays inside the unified app's route.
class MongiExperience extends StatefulWidget {
  const MongiExperience({super.key});
  @override
  State<MongiExperience> createState() => _MongiExperienceState();
}

class _MongiExperienceState extends State<MongiExperience>
    with WidgetsBindingObserver {
  final _navigator = GlobalKey<NavigatorState>();
  late Future<void> _ready;
  @override
  void initState() {
    super.initState();
    Flame.images.prefix = 'assets/mongi/images/';
    WidgetsBinding.instance.addObserver(this);
    SoundService().gardenSuspended = true;
    _ready = _initialize();
  }

  Future<void> _initialize() async {
    await MediaCoordinator.instance.stopAll();
    await SoundService().stopAll();
    await NotificationService.instance.init();
    if (!mounted) return;
    await context.read<GardenProvider>().ensureInitialized();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      SoundManager.instance.resumeAllFromBackground();
    } else {
      SoundManager.instance.pauseAllForBackground();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SoundManager.instance.pauseAllForBackground();
    SoundService().gardenSuspended = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        '마음냥 정원 · 달려라 몽이',
        style: bodyFont(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
      ),
      toolbarHeight: 44,
      leading: BackButton(
        onPressed: () {
          if (_navigator.currentState?.canPop() ?? false) {
            _navigator.currentState!.maybePop();
          } else {
            Navigator.of(context).pop();
          }
        },
      ),
    ),
    body: FutureBuilder<void>(
      future: _ready,
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('몽이 기록을 불러오지 못했어요. 기존 기록은 유지됩니다.'),
                TextButton(
                  onPressed: () => setState(() => _ready = _initialize()),
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          );
        if (snapshot.connectionState != ConnectionState.done)
          return const Center(child: CircularProgressIndicator());
        return NavigatorPopHandler<Object?>(
          onPopWithResult: (result) => _navigator.currentState?.pop(result),
          child: MaterialApp(
            navigatorKey: _navigator,
            debugShowCheckedModeBanner: false,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale(
              context.watch<GardenProvider>().languageCode ?? 'ko',
            ),
            theme: appTheme,
            home: context.read<GardenProvider>().hasSeenOnboarding
                ? const EmotionInputScreen()
                : const OnboardingScreen(),
          ),
        );
      },
    ),
  );
}
