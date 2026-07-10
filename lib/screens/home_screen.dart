import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../data/shadow_cats_data.dart';
import '../theme.dart';
import '../widgets/stars_background.dart';
import '../widgets/sound_panel.dart';
import 'home_tab_screen.dart';
import 'cat_flow_tab_screen.dart';
import 'meditation_library_screen.dart';
import 'history_screen.dart';
import 'my_screen.dart';

/// 앱의 최상위 셸 - 하단 5개 탭(홈페이지 / 고양이선택 / 명상 / 기록 / 마이)을 관리
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;

  void _goTo(int i) => setState(() => _navIndex = i);

  @override
  Widget build(BuildContext context) {
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
      body: GardenScaffoldBackground(
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
                    child: _buildTabBody(),
                  ),
                ),
              ),
              const Positioned(top: 24, right: 24, child: SoundToggleButton()),
              if (app.showFirstMeetingBanner)
                Positioned(
                  top: 16,
                  left: 0,
                  right: 0,
                  child: Center(child: _FirstMeetingBanner()),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _BottomNavBar(index: _navIndex, onChanged: _goTo),
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
      decoration: BoxDecoration(
        color: AppColors.bg1,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: List.generate(_items.length, (i) {
              final item = _items[i];
              final active = index == i;
              return Expanded(
                child: InkWell(
                  onTap: () => onChanged(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _NavIcon(
                        icon: item.icon,
                        imageAsset: item.imageAsset,
                        active: active,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        item.label,
                        style: bodyFont(
                          fontSize: 10.5,
                          color: active
                              ? AppColors.goldSoft
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
    );
  }
}

/// 홈 화면 최초 진입 시 한 번만 나타나는 작은 배너: "36마리 중 1마리를 만났어요 🐾"
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
    final metCount = context
        .watch<AppStateProvider>()
        .history
        .map((e) => e.catId)
        .toSet()
        .length;
    final shown = metCount.clamp(1, shadowCats.length);
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 400),
      opacity: _visible ? 1.0 : 0.0,
      child: Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.bg1,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.line),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          '${shadowCats.length}마리 중 $shown마리를 만났어요 🐾',
          style: bodyFont(
            fontSize: 12.5,
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
            color: active ? AppColors.goldSoft : Colors.transparent,
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
      color: active ? AppColors.goldSoft : AppColors.inkSoft,
    );
  }
}
