import 'dart:ui';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../services/media_coordinator.dart';
import '../services/sound_service.dart';
import '../mongi/services/sound_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../data/shadow_cats_data.dart';
import '../services/notification_service.dart';
import '../theme.dart';
import '../widgets/stars_background.dart';
import '../widgets/sound_panel.dart';
import '../widgets/feature_scaffold.dart';
import '../services/notice_service.dart';
import 'home_tab_screen.dart';
import 'cat_flow_tab_screen.dart';
import 'meditation_library_screen.dart';
import 'history_screen.dart';
import 'my_screen.dart';
import 'day_close_screen.dart';
import 'notice_list_screen.dart';

/// 앱의 최상위 셸 - 하단 5개 탭(홈페이지 / 고양이선택 / 명상 / 기록 / 마이)을 관리
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _navIndex = 0;
  Timer? _replyRefresh;
  bool _closed = false;
  bool _exiting = false;
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
    // 앱이 이미 실행 중(warm)일 때 알림을 탭해도 즉시 따라가도록, 그리고
    // 홍면을 열어둔 채 자정을 넘어 답장이 도착하는 경우에도 배너가 자동으로
    // 갱신되도록, 주기적으로 화면을 갱신합니다.
    NotificationService().deepLinkChanges.addListener(_handleDeepLink);
    _replyRefresh = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleDeepLink());
  }

  @override
  void dispose() {
    _replyRefresh?.cancel();
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
    }
  }

  /// 알림을 탭해서 들어온 경우, 종류별로 알맞은 화면/탭으로 이동합니다.
  void _handleDeepLink() {
    final target = NotificationService().consumePendingDeepLink();
    if (target == null || !mounted) return;
    switch (target) {
      case 'evening':
        // 저녁 알림 → 하루 닫기 화면으로 바로 이동
        pushFullScreen(context, '하루 닫기', const DayCloseScreen());
        break;
      case 'morning':
      case 'crisis':
      case 'streak':
        // 아침 / 위기 / 스트릭 알림 → 오늘의 감정 고양이 만나기 탭으로 이동
        setState(() => _navIndex = 1);
        break;
      case 'catReply':
      case 'heartLetterReply':
        // 답장 도착 알림 → 기록 탭으로 이동해 바로 열어볼 수 있게 함
        setState(() => _navIndex = 3);
        break;
    }
  }

  void _goTo(int i) => setState(() => _navIndex = i);

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
        setState(() => _navIndex = target);
      });
    }

    return Scaffold(
      extendBody: true,
      body: GardenScaffoldBackground(
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 56, 24, 118),
                    child: _buildTabBody(),
                  ),
                ),
              ),
              const Positioned(top: 2, right: 24, child: SoundToggleButton()),
              const Positioned(top: 2, right: 72, child: _NoticeBellButton()),
              Positioned(
                top: 2,
                left: 16,
                child: TextButton.icon(
                  onPressed: _exiting ? null : _exitGarden,
                  icon: const Icon(Icons.power_settings_new, size: 18),
                  label: const Text('종료'),
                ),
              ),
              if (app.showFirstMeetingBanner)
                Positioned(
                  top: 16,
                  left: 0,
                  right: 0,
                  child: Center(child: _FirstMeetingBanner()),
                ),
              // 정원 배경 위에 '떠 있는' 반투명 하단 내비게이션
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: _BottomNavBar(index: _navIndex, onChanged: _goTo),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBody() {
    switch (_navIndex) {
      case 0:
        return HomeTabScreen(
          onGoToCatSelect: () => _goTo(1),
          onGoToMeditation: () => _goTo(2),
          onGoToRecords: () => _goTo(3),
        );
      case 1:
        return const CatFlowTabScreen();
      case 2:
        return const MeditationLibraryScreen();
      case 3:
        return const HistoryScreen();
      case 4:
        return const MyScreen();
      default:
        return const SizedBox.shrink();
    }
  }
}

/// 하단 탐색 - 딱딱한 흰 사각 박스 대신, 정원 바닥에 살짝 '떠 있는' 반투명
/// 유리질감의 알약형 내비게이션 바입니다. 화면 가장자리에 붙지 않고
/// 사방에 여백을 두어 부유하는 느낌을 살렸습니다.
class _BottomNavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  const _BottomNavBar({required this.index, required this.onChanged});

  static const _items = [
    (icon: Icons.home_rounded, label: '홈페이지', imageAsset: null),
    (icon: Icons.pets_rounded, label: '고양이선택', imageAsset: null),
    (
      icon: null,
      label: '명상',
      imageAsset: 'assets/nav_icons/cat_meditating.png',
    ),
    (icon: Icons.device_thermostat_rounded, label: '기록', imageAsset: null),
    (icon: null, label: '마이', imageAsset: 'assets/nav_icons/cat_profile.png'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: SafeArea(
        top: false,
        minimum: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              height: 66,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.blobMint.withValues(alpha: 0.75),
                    AppColors.blobLavender.withValues(alpha: 0.62),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.55),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.blobMintAccent.withValues(alpha: 0.2),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: List.generate(_items.length, (i) {
                  final item = _items[i];
                  final active = index == i;
                  return Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(32),
                      onTap: () => onChanged(i),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _NavIcon(
                            icon: item.icon,
                            imageAsset: item.imageAsset,
                            active: active,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.label,
                            style: bodyFont(
                              fontSize: 10.5,
                              color: active
                                  ? AppColors.titlePastelGreen
                                  : AppColors.inkSoft,
                              fontWeight: active
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 공지사항 진입 버튼 - 사운드 토글과 같은 톤의 반투명 원형 버튼이며,
/// 읽지 않은 공지가 있으면 작은 배지를 함께 보여줍니다.
class _NoticeBellButton extends StatefulWidget {
  const _NoticeBellButton();

  @override
  State<_NoticeBellButton> createState() => _NoticeBellButtonState();
}

class _NoticeBellButtonState extends State<_NoticeBellButton> {
  int _unread = 0;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final count = await NoticeService.unreadCount();
    if (!mounted) return;
    setState(() => _unread = count);
  }

  Future<void> _open() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            const FeatureScaffold(title: '공지사항', child: NoticeListScreen()),
      ),
    );
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: _open,
        child: Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.55),
            border: Border.all(
              color: AppColors.blobMintAccent.withValues(alpha: 0.35),
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.notifications_none_rounded,
                color: AppColors.ink,
                size: 21,
              ),
              if (_unread > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 15,
                    height: 15,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.blobRoseAccent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      _unread > 9 ? '9+' : '$_unread',
                      style: const TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 홈 화면 최초 진입 시 한 번만 나타나는 작은 배너: "42마리 중 1마리를 만났어요 🐾"
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
    final metCount = context.watch<AppStateProvider>().metCatCount;
    // ⚠️ 유료(Basic 구독) 고양이는 잠겨있으면 탭해도 "만남" 처리가 되지
    // 않아, 비구독자는 42마리를 넘어 "만날" 수 없습니다. shadowCats.length
    // (52)를 분모로 쓰면 영원히 채울 수 없는 목표가 되므로 무료 42마리
    // 기준으로 표시합니다.
    final shown = metCount.clamp(1, freeShadowCats.length);
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
          '${freeShadowCats.length}마리 중 $shown마리를 만났어요 🐾',
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

/// 하단 탭 아이콘 - 기본 Material 아이콘 또는 커스텀 고양이 이미지를 표시
class _NavIcon extends StatelessWidget {
  final IconData? icon;
  final String? imageAsset;
  final bool active;
  const _NavIcon({
    required this.icon,
    required this.imageAsset,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    if (imageAsset != null) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: active ? AppColors.titlePastelGreen : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: ClipOval(
          child: Opacity(
            opacity: active ? 1.0 : 0.55,
            child: Image.asset(imageAsset!, fit: BoxFit.cover),
          ),
        ),
      );
    }
    return Icon(
      icon,
      size: 22,
      color: active ? AppColors.titlePastelGreen : AppColors.inkSoft,
    );
  }
}
