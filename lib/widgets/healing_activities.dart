import '../l10n/app_language.dart';
import 'package:flutter/material.dart';
import '../screens/cat_walk_screen.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../mongi/providers/garden_provider.dart';
import '../mongi/screens/garden_care_entry_screen.dart';
import '../mongi/screens/quiet_mode_screen.dart';
import '../mongi/screens/gratitude_log_screen.dart';
import '../mongi/screens/mongi_cheer_screen.dart';
import '../screens/bubble_garden_screen.dart';
import '../screens/day_close_screen.dart';
import 'feature_scaffold.dart';

enum HealingActivity {
  walk,
  bubbles,
  quiet,
  encouragement,
  gratitude,
  dayClose,
}

extension HealingActivityInfo on HealingActivity {
  String get title => switch (this) {
    HealingActivity.walk => tr("마음냥 산책"),
    HealingActivity.bubbles => tr("마음 버블 정원"),
    HealingActivity.quiet => tr("고요하게 마음 마주하기"),
    HealingActivity.encouragement => tr("혼자 읽는 응원 모음"),
    HealingActivity.gratitude => tr("감사 한 줄 · 작은 성취"),
    HealingActivity.dayClose => tr("하루 닫기"),
  };
  IconData get icon => switch (this) {
    HealingActivity.walk => Icons.pets_outlined,
    HealingActivity.bubbles => Icons.bubble_chart_outlined,
    HealingActivity.quiet => Icons.spa_outlined,
    HealingActivity.encouragement => Icons.favorite_border,
    HealingActivity.gratitude => Icons.local_florist_outlined,
    HealingActivity.dayClose => Icons.nightlight_round,
  };
  Widget screen() => switch (this) {
    HealingActivity.walk => const CatWalkScreen(),
    HealingActivity.bubbles => FeatureScaffold(
      title: tr("마음 버블 정원"),
      child: BubbleGardenScreen(),
    ),
    HealingActivity.dayClose => FeatureScaffold(
      title: tr("하루 닫기"),
      child: DayCloseScreen(),
    ),
    _ => HealingGardenEntry(activity: this),
  };
}

class HealingActivities extends StatelessWidget {
  const HealingActivities({super.key});
  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    return Column(
      children: [
        for (final activity in HealingActivity.values)
          Card(
            color: [
              AppColors.blobButter,
              AppColors.blobMint,
              AppColors.blobLavender,
              AppColors.blobRose,
              AppColors.blobButter,
              AppColors.blobPeach,
            ][activity.index],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            child: ListTile(
              key: ValueKey('healing-${activity.name}'),
              leading: Icon(activity.icon, color: AppColors.titlePastelGreen),
              title: Text(
                activity.title,
                style: titleFont(fontSize: 19, color: AppColors.ink),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => activity.screen())),
            ),
          ),
      ],
    );
  }
}

/// Initialize existing garden records before opening standalone healing routes.
class HealingGardenEntry extends StatefulWidget {
  final HealingActivity activity;
  const HealingGardenEntry({super.key, required this.activity});
  @override
  State<HealingGardenEntry> createState() => _HealingGardenEntryState();
}

class _HealingGardenEntryState extends State<HealingGardenEntry> {
  bool ready = false, failed = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final garden = context.read<GardenProvider>();
      if (!garden.isInitialized) await garden.ensureInitialized();
      if (mounted)
        setState(() {
          ready = true;
          failed = false;
        });
    } catch (_) {
      if (mounted) setState(() => failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    if (!ready)
      return Scaffold(
        appBar: AppBar(title: Text(widget.activity.title)),
        body: Center(
          child: failed
              ? TextButton(
                  onPressed: _load,
                  child: Text(tr("불러오지 못했어요 · 다시 시도")),
                )
              : const CircularProgressIndicator(),
        ),
      );
    return switch (widget.activity) {
      HealingActivity.encouragement => const MongiCheerScreen(),
      HealingActivity.gratitude => const GratitudeLogScreen(),
      _ => Scaffold(
        backgroundColor: AppColors.bg0,
        appBar: AppBar(title: Text(widget.activity.title)),
        body: SingleChildScrollView(
          child: QuietEmotionSheet(
            onContinue: (emotion) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => QuietModeScreen(emotions: [emotion]),
                ),
              );
            },
          ),
        ),
      ),
    };
  }
}
