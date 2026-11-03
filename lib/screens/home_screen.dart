import 'emotion_archive_screen.dart';
import '../mongi/screens/garden_discovery_screen.dart';
import '../services/cat_care_service.dart';
import 'garden_memory_book_screen.dart';
import 'data_safety_screen.dart';
import 'pet_care_screen.dart';
import 'premium_screen.dart';
import '../mongi/providers/garden_provider.dart';
import '../widgets/pastel_garden_shell.dart';
import '../models/companion_coat.dart';
import '../providers/cat_care_provider.dart';
import '../mongi/widgets/garden_home_preview.dart';
import '../mongi/screens/garden_world_screen.dart';
import '../mongi/screens/garden_village_screen.dart';
import 'account_screen.dart';
import 'companion_coat_screen.dart';
import 'emotion_statistics_screen.dart';
import 'keepsake_forest_screen.dart';
import 'coloring_healing_screen.dart';
import 'memory_cards_screen.dart';
import 'self_care_screen.dart';
import 'orchard_screen.dart';
import 'all_features_screen.dart';
import 'app_tutorial_screen.dart';
import 'mind_care_hub.dart';
import '../mongi/screens/public_garden_inbox_screen.dart';
import 'garden_updates_screen.dart';
import '../services/cloud_service.dart';
import '../mongi/widgets/banner_ad_slot.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../services/media_coordinator.dart';
import '../services/sound_service.dart';
import '../mongi/services/sound_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../services/notification_service.dart';
import '../theme.dart';
import '../widgets/stars_background.dart';
import '../widgets/feature_scaffold.dart';
import 'cat_flow_tab_screen.dart';
import 'history_screen.dart';
import 'my_screen.dart';
import 'day_close_screen.dart';
import 'notice_list_screen.dart';
import '../models/companion_reminder.dart';
import '../models/companion_journey.dart';
import '../widgets/companion_care_panel.dart';

/// 좌우 공간 탐색과 기존 기능 진입을 연결하는 앱 셸.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool _careSaving = false;
  bool _careRefreshing = false;
  int _activeStoryPage = 0;
  int? _pendingMood;
  static const _moodGroups = ['기쁘고 기대돼요', '편안해요', null, '슬프고 외로워요', '지치고 막막해요'];
  bool _selecting = false;
  bool _closed = false;
  bool _exiting = false;
  bool _companionSheetOpen = false;
  Future<void> _exitGarden() async {
    if (_exiting) return;
    setState(() => _exiting = true);
    SoundService().gardenSuspended = true;
    try {
      await MediaCoordinator.instance.stopAll();
      await SoundService().stopAll();
      await SoundManager.instance.pauseAllForBackground();
      if (!mounted) return;
      setState(() => _closed = true);
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        await SystemNavigator.pop();
      }
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('종료하지 못했어요. 다시 시도해 주세요.')));
    } finally {
      if (mounted) setState(() => _exiting = false);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NotificationService().deepLinkChanges.addListener(_handleDeepLink);
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleDeepLink());
  }

  @override
  void dispose() {
    NotificationService().deepLinkChanges.removeListener(_handleDeepLink);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 알림을 탭해서 백그라운드에 있던 앱이 다시 앞으로 나올 때도 딥링크를
    // 확인합니다(알림을 탭한 시점에는 이미 앱이 실행 중이라 initState가
    // 다시 호출되지 않기 때문).
    if (state == AppLifecycleState.resumed) {
      _handleDeepLink();
      if (_activeStoryPage == 3) unawaited(_refreshCare());
    }
  }

  /// 알림을 탭해서 들어온 경우, 종류별로 알맞은 화면/탭으로 이동합니다.
  void _handleDeepLink() {
    final target = NotificationService().consumePendingDeepLink();
    if (target == null || !mounted) return;
    final invitation = CompanionInvitation.parse(target);
    if (invitation != null) {
      if (_companionSheetOpen) return;
      if (_closed) setState(() => _closed = false);
      _companionSheetOpen = true;
      unawaited(
        showCompanionCare(
          context,
          invitation: invitation.day == companionDay(DateTime.now())
              ? invitation.action
              : null,
        ).whenComplete(() => _companionSheetOpen = false),
      );
      return;
    }
    if (target.startsWith('gardenPush:')) {
      if (CloudService.currentUser == null) return;
      final booking = target == 'gardenPush:booking';
      pushFullScreen(
        context,
        booking ? '내 예약' : '받은 응원·선물',
        booking ? const GardenUpdatesScreen() : const PublicGardenInboxScreen(),
      );
      return;
    }
    switch (target) {
      case 'gardenNotice':
        pushFullScreen(context, '공지사항', const NoticeListScreen());
        break;
      case 'evening':
        // 저녁 알림 → 하루 닫기 화면으로 바로 이동
        pushFullScreen(context, '하루 닫기', const DayCloseScreen());
        break;
      case 'morning':
      case 'crisis':
      case 'streak':
        // 아침 / 위기 / 스트릭 알림 → 오늘의 감정 고양이 만나기 탭으로 이동
        _goTo(1);
        break;
      case 'catReply':
      case 'heartLetterReply':
        // 이전 버전 알림은 보관된 기록으로 연결합니다.
        _goTo(3);
        break;
    }
  }

  // Legacy notifications and feature links retain their original destinations.
  void _goTo(int i) {
    switch (i) {
      case 1:
        final group = _pendingMood == null ? null : _moodGroups[_pendingMood!];
        _pendingMood = null;
        pushFullScreen(
          context,
          '마음 기록하기',
          CatFlowTabScreen(initialGroup: group),
        );
        break;
      case 2:
        pushFullScreen(context, '명상 · 힐링', const MindCareHub());
        break;
      case 3:
        pushFullScreen(context, '편지 기록', const HistoryScreen());
        break;
      case 4:
        pushFullScreen(context, '마이 · 설정', const MyScreen());
        break;
    }
  }

  Future<void> _selectCoat(CompanionCoat coat) async {
    if (_selecting) return;
    setState(() => _selecting = true);
    try {
      await context.read<CatCareProvider>().selectCoat(coat);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${coat.label}와 정원과 마음돌보기에 함께해요.')),
        );
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('선택을 저장하지 못했어요. 다시 눌러 주세요.')),
        );
    } finally {
      if (mounted) setState(() => _selecting = false);
    }
  }

  Future<void> _open(Widget screen) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => screen));
    if (mounted) setState(() {});
  }

  Future<void> _doCare(PastelAction action) async {
    if (_careSaving || _careRefreshing) return;
    final care = context.read<CatCareProvider>();
    final owner = CatCareService.localOwner;
    setState(() => _careSaving = true);
    try {
      await care.load();
      if (!mounted || owner != CatCareService.localOwner) return;
      switch (action) {
        case PastelAction.feed:
          await care.feed();
          break;
        case PastelAction.water:
          await care.water();
          break;
        case PastelAction.bath:
          await care.bath();
          break;
        case PastelAction.clean:
          await care.clean();
          break;
        default:
          return;
      }
      if (!mounted || owner != CatCareService.localOwner) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('돌봄을 기록했어요.')));
    } catch (_) {
      if (mounted && owner == CatCareService.localOwner)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('돌봄을 저장하지 못했어요. 다시 시도해 주세요.')),
        );
    } finally {
      if (mounted) setState(() => _careSaving = false);
    }
  }

  Future<void> _refreshCare() async {
    if (_careSaving || _careRefreshing || !mounted) return;
    setState(() => _careRefreshing = true);
    try {
      await context.read<CatCareProvider>().load();
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('돌봄 상태를 불러오지 못했어요. 다시 눌러 주세요.')),
        );
    } finally {
      if (mounted) setState(() => _careRefreshing = false);
    }
  }

  void _action(PastelAction action) {
    switch (action) {
      case PastelAction.companion:
        if (_companionSheetOpen) return;
        _companionSheetOpen = true;
        unawaited(
          showCompanionCare(
            context,
          ).whenComplete(() => _companionSheetOpen = false),
        );
        break;
      case PastelAction.login:
        _open(const AccountScreen());
        break;
      case PastelAction.write:
        _goTo(1);
        break;
      case PastelAction.comic:
        _open(const EmotionStatisticsScreen());
        break;
      case PastelAction.memories:
        _open(const KeepsakeForestScreen());
        break;
      case PastelAction.garden:
        _open(const GardenWorldScreen.owned());
        break;
      case PastelAction.landscape:
        _open(const GardenWorldScreen.owned(initialLandscape: true));
        break;
      case PastelAction.coats:
        showCompanionCoats(context);
        break;
      case PastelAction.orchard:
        _open(const OrchardScreen());
        break;
      case PastelAction.meditation:
        _goTo(2);
        break;
      case PastelAction.coloring:
        _open(const ColoringHealingScreen());
        break;
      case PastelAction.care:
        _open(const SelfCareScreen());
        break;
      case PastelAction.neighbors:
        _open(const GardenVillageScreen());
        break;
      case PastelAction.inbox:
        _open(const PublicGardenInboxScreen());
        break;
      case PastelAction.cards:
        _open(const MemoryCardsScreen());
        break;
      case PastelAction.records:
        _goTo(3);
        break;
      case PastelAction.settings:
      case PastelAction.sound:
        _goTo(4);
        break;
      case PastelAction.tutorial:
        pushFullScreen(context, '사용법', const AppTutorialScreen());
        break;
      case PastelAction.all:
        openAllFeatures(context);
        break;
      case PastelAction.notices:
        pushFullScreen(context, '공지사항', const NoticeListScreen());
        break;
      case PastelAction.petCare:
        pushFullScreen(context, '고양이 돌보기', const PetCareScreen());
        break;
      case PastelAction.premium:
        _open(const PremiumScreen());
        break;
      case PastelAction.discover:
        _open(const GardenDiscoveryScreen());
        break;
      case PastelAction.favorites:
        _open(const GardenDiscoveryScreen(favorites: true));
        break;
      case PastelAction.calendar:
        _open(const EmotionArchiveScreen());
        break;
      case PastelAction.emotionArchive:
        _open(const EmotionArchiveScreen(calendar: false));
        break;
      case PastelAction.memoryBook:
        _open(const GardenMemoryBookScreen());
        break;
      case PastelAction.dataSafety:
        _open(const DataSafetyScreen());
        break;
      case PastelAction.feed:
      case PastelAction.water:
      case PastelAction.bath:
      case PastelAction.clean:
        unawaited(_doCare(action));
        break;
      case PastelAction.exit:
        _exitGarden();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_closed)
      return Scaffold(
        body: GardenScaffoldBackground(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '오늘도 수고했어요 🌿',
                  style: titleFont(
                    fontSize: 24,
                    color: AppColors.titlePastelGreen,
                  ),
                ),
                const SizedBox(height: 12),
                const Text('정원을 닫았어요. 편안하게 쉬어가세요.'),
                if (kIsWeb) const Text('이 창을 닫아도 괜찮아요.'),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    SoundService().gardenSuspended = false;
                    unawaited(SoundService().tryStartBgm());
                    setState(() => _closed = false);
                  },
                  child: const Text('정원 다시 열기'),
                ),
              ],
            ),
          ),
        ),
      );
    final app = context.watch<AppStateProvider>();

    // 온보딩 종료 등에서 특정 탭으로 이동해달라는 요청이 있으면 반영합니다.
    if (app.requestedTabIndex != null) {
      final target = app.requestedTabIndex!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        app.clearRequestedTab();
        _goTo(target);
      });
    }

    final care = context.watch<CatCareProvider>();
    return Stack(
      children: [
        PastelGardenShell(
          actualGarden: const GardenWorldScreen.owned(embedded: true),
          motionEnabled: context.watch<GardenProvider>().gardenMotionEnabled,
          onAction: _action,
          onMoodSelected: (index) => _pendingMood = index,
          onPageSelected: (index) {
            _activeStoryPage = index;
            if (index == 3) unawaited(_refreshCare());
          },
          careBusy: _careSaving || _careRefreshing,
          completedCare: {
            if (care.state.fedToday) PastelAction.feed,
            if (care.state.wateredToday) PastelAction.water,
            if (care.state.bathedToday) PastelAction.bath,
            if (care.state.cleanedToday) PastelAction.clean,
          },
          onCoat: _selectCoat,
          coat: care.journey.coat,
          companionName: care.companionName,
          companionStage: care.journey.keepBaby ? 0 : care.journey.stage,
          companionBondStage: care.journey.stage,
          companionAutomaticBehavior:
              care.journeyReady && care.journey.automaticBehavior,
          companionLoading: care.isLoading && !care.journeyReady,
          companionError: care.journeyReady ? null : care.journeyError,
          onRetryCompanion: () => unawaited(_refreshCare()),
          signedIn: CloudService.currentUser != null,
          selecting: _selecting,
          footer: Column(
            children: [
              if (app.showFirstMeetingBanner)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: IgnorePointer(child: _FirstMeetingBanner()),
                ),
              const BannerAdSlot(),
            ],
          ),
          gardenPreview: GestureDetector(
            onTap: () => _action(PastelAction.garden),
            child: const GardenHomePreview(showLabel: false),
          ),
        ),
      ],
    );
  }
}

/// 홈 화면 최초 진입 시 한 번만 나타나는 작은 배너: "37마리 중 1마리를 만났어요 🐾"
/// 3초 후 자동으로 사라집니다.
class _FirstMeetingBanner extends StatefulWidget {
  const _FirstMeetingBanner();

  @override
  State<_FirstMeetingBanner> createState() => _FirstMeetingBannerState();
}

class _FirstMeetingBannerState extends State<_FirstMeetingBanner> {
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _visible = false);
      Future.delayed(const Duration(milliseconds: 400), () {
        if (!mounted) return;
        context.read<AppStateProvider>().dismissFirstMeetingBanner();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 400),
      opacity: _visible ? 1.0 : 0.0,
      child: Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.blobPeach.withValues(alpha: 0.9),
              AppColors.blobPeach.withValues(alpha: 0.65),
            ],
          ),
          border: Border.all(
            color: AppColors.blobPeachAccent.withValues(alpha: 0.3),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.blobPeachAccent.withValues(alpha: 0.16),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Text(
          '한 줄을 남겨도, 잠깐 쉬어가도 괜찮아요 🌿',
          style: pathLabelFont(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
      ),
    );
  }
}
