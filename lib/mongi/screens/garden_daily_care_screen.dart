import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_language.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/cat_care_provider.dart';
import '../../screens/cat_flow_tab_screen.dart';
import '../../screens/mind_care_hub.dart';
import '../../widgets/companion_care_panel.dart';
import '../../widgets/companion_coat_art.dart';
import '../../widgets/companion_presence.dart';
import '../../widgets/feature_scaffold.dart';
import '../integration/mongi_garden_store.dart';
import '../widgets/garden_essence_chip.dart';

/// Garden's care and receipt pages reuse existing activities and saved receipts.
/// Opening, returning to, or repeatedly viewing this page never grants a reward.
class GardenDailyCareScreen extends StatefulWidget {
  const GardenDailyCareScreen({super.key});

  @override
  State<GardenDailyCareScreen> createState() => _GardenDailyCareScreenState();
}

class _GardenDailyCareScreenState extends State<GardenDailyCareScreen> {
  bool _receipt = false, _busy = false;
  String? _error;

  Future<void> _activity(Future<void> Function() open) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await open();
      if (!mounted) return;
      await MongiGardenStore.instance.reload();
      if (!mounted) return;
      final today = MongiGardenData.dayKey(DateTime.now());
      setState(
        () =>
            _receipt = MongiGardenStore.instance.value.careDays.contains(today),
      );
    } catch (_) {
      if (mounted) setState(() => _error = tr('돌봄 상태를 불러오지 못했어요. 다시 눌러 주세요.'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _record() async {
    final app = context.read<AppStateProvider>();
    if (app.currentLetterId != null) app.restartFlow();
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (routeContext) => FeatureScaffold(
          title: tr('마음 기록하기'),
          child: CatFlowTabScreen(
            onCareCompleted: () => Navigator.of(routeContext).pop(),
          ),
        ),
      ),
    );
    // A saved letter and its daily reward are independent. Use the existing
    // idempotent retry path; do not manufacture a success receipt on failure.
    await app.retryGardenRewards();
  }

  @override
  Widget build(BuildContext context) {
    final companion = context.watch<CatCareProvider>();
    return ValueListenableBuilder<MongiGardenData>(
      valueListenable: MongiGardenStore.instance,
      builder: (context, data, _) => Scaffold(
        backgroundColor: const Color(0xFFFFF9ED),
        appBar: AppBar(
          backgroundColor: const Color(0xFFFFF9ED),
          title: Text(tr('오늘의 마음돌봄')),
        ),
        body: ListView(
          padding: EdgeInsets.zero,
          children: [
            DecoratedBox(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/storybook_ui_v2/home-room.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: GardenEssenceChip(amount: data.essence),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: Text(
                      companion.displayName,
                      key: const Key('garden-care-companion-name'),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(tr('왔구나, 여기서 같이 쉬자.'), textAlign: TextAlign.center),
                  SizedBox(
                    width: double.infinity,
                    height: (MediaQuery.sizeOf(context).height * .3).clamp(
                      150,
                      260,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: CompanionCoatScope(
                        useLocalChoice: true,
                        coat: companion.journey.coat,
                        growthStage: companion.journey.keepBaby
                            ? 0
                            : companion.journey.stage,
                        child: CompanionPresence(
                          enabled:
                              companion.journeyReady &&
                              companion.journey.automaticBehavior,
                          bondStage: companion.journey.stage,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _receipt ? tr('오늘의 마음을 돌봤어요') : tr('오늘은 하나만 해도 좋아요'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_receipt) ...[
                    GardenDailyRewardReceipt(data: data),
                    const SizedBox(height: 16),
                    FilledButton(
                      key: const Key('garden-care-plant'),
                      onPressed: _busy
                          ? null
                          : () => Navigator.of(context).pop(true),
                      child: Text(tr('정원에서 심어보기')),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(tr('오늘은 여기까지')),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _receipt = false),
                      child: Text(tr('다른 돌봄 살펴보기')),
                    ),
                  ] else ...[
                    FilledButton.icon(
                      key: const Key('garden-care-record'),
                      onPressed: _busy ? null : () => _activity(_record),
                      icon: const Icon(Icons.edit_outlined),
                      label: Text(tr('마음 기록하기')),
                    ),
                    const SizedBox(height: 10),
                    LayoutBuilder(
                      builder: (context, box) {
                        final columns =
                            MediaQuery.textScalerOf(context).scale(14) > 22
                            ? 1
                            : 2;
                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            SizedBox(
                              width:
                                  (box.maxWidth - 8 * (columns - 1)) / columns,
                              child: OutlinedButton.icon(
                                key: const Key('garden-care-rest'),
                                onPressed: _busy
                                    ? null
                                    : () => _activity(
                                        () => Navigator.of(context).push<void>(
                                          MaterialPageRoute(
                                            builder: (_) => const MindCareHub(),
                                          ),
                                        ),
                                      ),
                                icon: const Icon(Icons.spa_outlined),
                                label: Text(tr('잠깐 쉬기')),
                              ),
                            ),
                            SizedBox(
                              width:
                                  (box.maxWidth - 8 * (columns - 1)) / columns,
                              child: OutlinedButton.icon(
                                key: const Key('garden-care-cat'),
                                onPressed: _busy
                                    ? null
                                    : () => _activity(
                                        () => showCompanionCare(context),
                                      ),
                                icon: const Icon(Icons.favorite_border),
                                label: Text(tr('고양이 돌보기')),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      key: const Key('garden-care-return'),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(tr('우리 정원 둘러보기')),
                    ),
                    if (data.careDays.contains(
                      MongiGardenData.dayKey(DateTime.now()),
                    ))
                      TextButton(
                        key: const Key('garden-care-receipt'),
                        onPressed: () => setState(() => _receipt = true),
                        child: Text(tr('오늘의 보상 확인')),
                      ),
                  ],
                  if (_busy) const Center(child: CircularProgressIndicator()),
                  if (_error != null)
                    Text(_error!, textAlign: TextAlign.center),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A daily receipt, not a claim button: repeats show the same saved allowance.
class GardenDailyRewardReceipt extends StatelessWidget {
  const GardenDailyRewardReceipt({super.key, required this.data});
  final MongiGardenData data;

  @override
  Widget build(BuildContext context) {
    final claimed = data.careDays.contains(
      MongiGardenData.dayKey(DateTime.now()),
    );
    return Container(
      key: const Key('garden-daily-reward-receipt'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF3),
        border: Border.all(color: const Color(0xFFE6D5B7)),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          if (claimed) ...[
            Text(
              tr('빛의 정수 +20'),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF527C50),
              ),
            ),
            const SizedBox(height: 6),
            Text(tr('정원을 꾸미는 데 쓸 수 있어요'), textAlign: TextAlign.center),
            const Divider(height: 28),
            Text(
              tr('심을 씨앗 1개'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              tr('오늘의 돌봄 보상 완료 · 하루 한 번'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF527C50)),
            ),
          ] else
            Text(tr('아직 오늘의 돌봄 보상이 저장되지 않았어요.'), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
