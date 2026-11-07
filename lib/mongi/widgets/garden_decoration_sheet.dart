import '../../l10n/app_language.dart';
import '../../widgets/subscription_gate.dart';
import '../../screens/account_screen.dart';
import '../../services/subscription_service.dart';
import '../../theme.dart' show AppColors;
import '../../providers/cat_care_provider.dart';
import '../../models/companion_coat.dart';
import '../integration/garden_layout_store.dart';
import '../integration/mongi_garden_store.dart';
import 'garden_essence_chip.dart';
import 'garden_basic_item_art.dart';
import 'garden_world_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/garden_decoration_l10n.dart' as garden_deco_l10n;
import '../l10n/gen/app_localizations.dart';
import '../models/garden_decoration.dart';
import '../providers/garden_provider.dart';

/// "정원 꾸미기" 바텀시트 - [GardenDecoration.all]을 그대로 순회해서 그리므로
/// 새 장식 아이템을 추가해도 이 화면 코드는 수정할 필요가 없다.
/// - 기본 장식: 기록·명상으로 모은 빛의 정수 60개로 받아 배치한다.
/// - 구독 장식: 구독 권한을 확인하고 받은 뒤 계속 소유한다.
/// 이전에 획득하거나 잠금 해제한 장식은 그대로 사용할 수 있다.
void showGardenDecorationSheet(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const GardenDecorationSheet()),
  );
}

class GardenDecorationSheet extends StatefulWidget {
  const GardenDecorationSheet({
    super.key,
    this.ensureSignedIn = AccountScreen.ensureSignedIn,
  });

  final Future<bool> Function(BuildContext) ensureSignedIn;

  @override
  State<GardenDecorationSheet> createState() => _GardenDecorationSheetState();
}

class _GardenDecorationSheetState extends State<GardenDecorationSheet> {
  bool _purchasing = false;
  String? _notice;
  GardenDecoration _selected = GardenDecoration.byId('daisy_pot');

  String _status(GardenProvider garden, GardenDecoration deco) {
    if (garden.isDecorationUnlocked(deco)) {
      return garden.isDecorationEquipped(deco)
          ? tr("정원에 놓여 있어요")
          : tr("보유한 장식");
    }
    return deco.isPremium
        ? tr("구독자를 위한 선물 · 한 번 받으면 계속 소유해요")
        : tr("빛의 정수 60개");
  }

  Future<void> _onTapDecoration(GardenDecoration deco) async {
    if (_purchasing) return;
    final garden = context.read<GardenProvider>();
    setState(() {
      _purchasing = true;
      _notice = null;
    });
    try {
      await garden.refreshSubscription();
      if (!mounted) return;
      if (garden.isDecorationUnlocked(deco)) {
        await garden.toggleDecorationEquipped(deco);
      } else if (deco.isPremium) {
        await _showPurchaseConfirm();
      } else {
        await garden.obtainDecoration(deco);
        if (mounted) _showSnack(tr('{0}을 정원에 놓았어요.', [deco.label]));
      }
    } catch (error) {
      if (mounted) {
        _showSnack(
          error is StateError
              ? error.message
              : tr("장식을 저장하지 못했어요. 다시 시도해 주세요."),
        );
      }
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  Future<void> _showPurchaseConfirm() async {
    await requestSubscription(context);
    if (!mounted) return;
    await context.read<GardenProvider>().refreshSubscription();
  }

  Future<void> _onRestore() async {
    if (_purchasing) return;
    final garden = context.read<GardenProvider>();
    setState(() {
      _purchasing = true;
      _notice = null;
    });
    try {
      if (!await widget.ensureSignedIn(context) || !mounted) return;
      final result = await garden.restoreDecorationPackPurchase();
      if (mounted) _showSnack(result.message);
    } catch (_) {
      if (mounted) {
        _showSnack(
          const SubscriptionRestoreResult(
            SubscriptionRestoreStatus.unavailable,
          ).message,
        );
      }
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  void _showSnack(String message) {
    setState(() => _notice = message);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final garden = context.watch<GardenProvider>();
    final unlocked = garden.isDecorationUnlocked(_selected);
    final equipped = garden.isDecorationEquipped(_selected);
    final label = garden_deco_l10n.decorationLabel(l10n, _selected);
    final featured = ['daisy_pot', 'cat_cushion', 'bird_house', 'moon_lamp'];
    final basic = [
      ...featured.map(GardenDecoration.byId),
      ...GardenDecoration.all.where(
        (d) => !d.isPremium && !featured.contains(d.id),
      ),
    ];
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9ED),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF9ED),
        title: Text(
          tr('우리 정원 꾸미기'),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              key: const Key('decoration-catalog-scroll'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Stack(
                    children: [
                      SizedBox(
                        height: 210,
                        width: double.infinity,
                        child: _preview(garden),
                      ),
                      Positioned(
                        top: 8,
                        right: 10,
                        child: GardenEssenceChip(amount: garden.lightEssence),
                      ),
                      Positioned(
                        bottom: 8,
                        left: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xEFFFFFF5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            tr('미리보기 · {0}', [label]),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      tr('모은 빛으로 골라보세요'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _grid(garden, basic, l10n),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      tr('구독자 정원 선물'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _grid(
                    garden,
                    GardenDecoration.all.where((d) => d.isPremium).toList(),
                    l10n,
                  ),
                  if (!garden.decorationPackUnlocked)
                    TextButton(
                      onPressed: _purchasing ? null : _onRestore,
                      child: Text(tr('구독 복원하기')),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_notice != null)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 72),
                      child: SingleChildScrollView(
                        child: Semantics(
                          liveRegion: true,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(_notice!, textAlign: TextAlign.center),
                          ),
                        ),
                      ),
                    ),
                  Text(
                    _status(garden, _selected),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.inkSoft,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      key: const Key('decoration-confirm'),
                      onPressed: _purchasing
                          ? null
                          : () => _onTapDecoration(_selected),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF527C50),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(48, 48),
                      ),
                      icon: Icon(
                        _purchasing
                            ? Icons.hourglass_top
                            : equipped
                            ? Icons.inventory_2_outlined
                            : Icons.auto_awesome,
                      ),
                      label: Text(
                        _purchasing
                            ? tr('저장 중…')
                            : equipped
                            ? tr('{0} 보관하기', [label])
                            : unlocked
                            ? tr('{0} 놓기', [label])
                            : _selected.isPremium
                            ? tr('구독 혜택 확인')
                            : tr('{0} 놓기 · 빛의 정수 60', [label]),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _preview(GardenProvider garden) {
    final companion = context.watch<CatCareProvider?>();
    return IgnorePointer(
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: Listenable.merge([
            MongiGardenStore.instance,
            GardenLayoutStore.instance,
          ]),
          builder: (context, _) {
            final data = MongiGardenStore.instance.value;
            return GardenWorldView(
              key: const Key('decoration-garden-preview'),
              preview: true,
              previewDecorationId: _selected.id,
              readOnly: true,
              motionEnabled: false,
              originalScenery: true,
              cultivationMode: true,
              fillViewport: true,
              companionName: companion?.displayName ?? '',
              activeCoat: companion?.journey.coat ?? CompanionCoat.ginger,
              companionScale: companion?.journey.visualScale ?? 1,
              companionAutomaticBehavior: false,
              layout: GardenLayoutStore.instance.value,
              seeds: data.seeds,
              careRemainders: data.careRemainders,
              wateredOn: data.wateredOn,
              decorations: {
                ...garden.equippedDecorationIds,
                _selected.id,
              }.toList(),
              onMove: (_, __) async {},
              onMemory: (_) {},
              onPlant: () {},
              onDecorate: () {},
            );
          },
        ),
      ),
    );
  }

  Widget _grid(
    GardenProvider garden,
    List<GardenDecoration> items,
    AppLocalizations l10n,
  ) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14),
    child: LayoutBuilder(
      builder: (context, box) {
        final large = MediaQuery.textScalerOf(context).scale(14) > 22;
        final columns = large && box.maxWidth < 350 ? 1 : 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final deco in items)
              SizedBox(
                width: (box.maxWidth - 10 * (columns - 1)) / columns,
                child: Semantics(
                  selected: _selected.id == deco.id,
                  child: Material(
                    color: _selected.id == deco.id
                        ? const Color(0xFFF0F3E4)
                        : const Color(0xFFFFFCF4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(
                        color: _selected.id == deco.id
                            ? const Color(0xFF527C50)
                            : const Color(0xFFEADAC1),
                        width: _selected.id == deco.id ? 2 : 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      key: ValueKey('decoration-select-' + deco.id),
                      onTap: _purchasing
                          ? null
                          : () => setState(() {
                              _selected = deco;
                              _notice = null;
                            }),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          children: [
                            Stack(
                              alignment: Alignment.topRight,
                              children: [
                                SizedBox(
                                  height: 90,
                                  width: double.infinity,
                                  child:
                                      GardenBasicItemArt.ids.contains(deco.id)
                                      ? GardenBasicItemArt(id: deco.id)
                                      : deco.id == 'bench'
                                      ? Image.asset(
                                          'assets/living_garden/bench.webp',
                                          fit: BoxFit.contain,
                                          excludeFromSemantics: true,
                                        )
                                      : Center(
                                          child: Text(
                                            deco.emoji,
                                            style: const TextStyle(
                                              fontSize: 48,
                                            ),
                                          ),
                                        ),
                                ),
                                if (_selected.id == deco.id)
                                  const Icon(
                                    Icons.check_circle,
                                    size: 23,
                                    color: Color(0xFF527C50),
                                  ),
                              ],
                            ),
                            Text(
                              garden_deco_l10n.decorationLabel(l10n, deco),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              garden.isDecorationUnlocked(deco)
                                  ? garden.isDecorationEquipped(deco)
                                        ? tr('배치됨')
                                        : tr('보유 중')
                                  : deco.isPremium
                                  ? tr('구독 선물')
                                  : tr('빛의 정수 60개'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}
