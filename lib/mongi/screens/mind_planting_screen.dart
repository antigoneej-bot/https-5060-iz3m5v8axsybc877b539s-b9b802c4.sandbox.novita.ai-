import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../data/shadow_cats_data.dart';
import '../../l10n/app_language.dart';
import '../../models/shadow_cat.dart';
import '../../providers/cat_care_provider.dart';
import '../../widgets/companion_coat_art.dart';
import '../../widgets/companion_presence.dart';
import '../integration/mongi_garden_store.dart';
import '../integration/planting_mind.dart';
import '../integration/session_transaction.dart';
import '../models/seed.dart';
import '../integration/plant_memory_store.dart';
import '../integration/plant_memory_editor.dart';
import '../../services/cat_care_service.dart';
import '../../providers/app_state_provider.dart';
import '../../screens/cat_flow_tab_screen.dart';
import '../../screens/mind_care_hub.dart';
import '../../widgets/feature_scaffold.dart';
import '../widgets/garden_plant_picker.dart';

class MindPlantingChoice {
  final SeedType seed;
  final PlantingMind? mind;
  final bool openMemory;
  final bool savedMind;
  const MindPlantingChoice(
    this.seed, {
    this.mind,
    this.openMemory = false,
    this.savedMind = false,
  });
}

/// A private draft only: choosing an emotion does not replace the active
/// companion, create a letter, award currency, or persist a planting.
class MindPlantingScreen extends StatefulWidget {
  const MindPlantingScreen({super.key, this.initialEmotionId});
  final String? initialEmotionId;
  @override
  State<MindPlantingScreen> createState() => _MindPlantingScreenState();
}

class _MindPlantingScreenState extends State<MindPlantingScreen> {
  final _note = TextEditingController();
  final _requestId = 'mind-${SessionTransaction.newId()}';
  ShadowCat? _emotion;
  bool _choosingPlant = false, _returned = false, _saving = false;
  bool _childRouteOpen = false;
  final _owner = CatCareService.localOwner;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    final id = widget.initialEmotionId;
    if (id != null && shadowCats.any((cat) => cat.id == id)) {
      _emotion = shadowCatById(id);
      _choosingPlant = true;
    }
  }

  PlantingMind get _draft => PlantingMind(
    id: _requestId,
    emotionCatId: _emotion!.id,
    note: _note.text.trim(),
  );

  Future<void> _saveToPlant(SeedType seed) async {
    if (_saving) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      await PlantMemoryStore.instance.appendMind(
        seed.id,
        _draft,
        owner: _owner,
      );
      if (mounted) _finish(MindPlantingChoice(seed, savedMind: true));
    } on PlantMemoryCapacityException {
      if (mounted) {
        setState(
          () => _saveError = tr('이 식물의 추억이 60개예요. 추억 보기에서 살펴본 뒤 다시 남겨 주세요.'),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _saveError = tr(
            _owner != CatCareService.localOwner
                ? '계정이 바뀌었어요. 마음 심기를 다시 열어 주세요.'
                : '마음을 저장하지 못했어요. 적은 내용은 그대로 있어요. 다시 시도해 주세요.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _readMemories(SeedType seed) async {
    if (_saving || _childRouteOpen) return;
    setState(() => _childRouteOpen = true);
    try {
      await PlantMemoryStore.instance.reload();
      if (!mounted || _owner != CatCareService.localOwner) return;
      await showDialog<void>(
        context: context,
        builder: (_) => PlantMemoryEditor(plant: seed),
      );
    } catch (_) {
      if (mounted) {
        setState(() => _saveError = tr('마음 기록을 불러오지 못했어요. 다시 열어 주세요.'));
      }
    } finally {
      if (mounted) setState(() => _childRouteOpen = false);
    }
  }

  Future<void> _seedActivity(bool record) async {
    if (_saving || _childRouteOpen) return;
    setState(() => _childRouteOpen = true);
    try {
      FocusManager.instance.primaryFocus?.unfocus();
      if (record) {
        final app = context.read<AppStateProvider?>();
        if (app?.currentLetterId != null) app!.restartFlow();
      }
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => FeatureScaffold(
            title: tr(record ? '마음 기록하기' : '명상·호흡·자연음'),
            child: record ? const CatFlowTabScreen() : const MindCareHub(),
          ),
        ),
      );
      if (!mounted || _owner != CatCareService.localOwner) return;
      try {
        await MongiGardenStore.instance.reload();
      } catch (_) {
        if (mounted) {
          setState(() => _saveError = tr('정원과 씨앗을 불러오지 못했어요. 다시 열어 주세요.'));
        }
      }
    } finally {
      if (mounted) setState(() => _childRouteOpen = false);
    }
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _finish(MindPlantingChoice result) {
    if (_returned) return;
    _returned = true;
    Navigator.pop(context, result);
  }

  Future<void> _allEmotions() async {
    final choice = await showModalBottomSheet<ShadowCat>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _AllMindEmotions(),
    );
    if (mounted && choice != null) setState(() => _emotion = choice);
  }

  Widget _emotionButton(ShadowCat cat, double width) {
    final selected = _emotion?.id == cat.id;
    return SizedBox(
      width: width,
      child: Semantics(
        selected: selected,
        button: true,
        label: cat.displayKeyword,
        excludeSemantics: true,
        onTap: () => setState(() => _emotion = cat),
        child: InkWell(
          key: ValueKey('mind-emotion-${cat.id}'),
          borderRadius: BorderRadius.circular(18),
          onTap: () => setState(() => _emotion = cat),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFF0E8F7) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected
                    ? const Color(0xFF8B72A4)
                    : const Color(0xFFE5E0D5),
                width: selected ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Image.asset(cat.imageAsset, height: 62, fit: BoxFit.contain),
                Text(cat.displayKeyword, textAlign: TextAlign.center),
                if (selected) const Icon(Icons.check_circle, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chooseMind() {
    final care = context.watch<CatCareProvider?>();
    final suggestions = ['joyful', 'serene', 'indifferent', 'sad', 'weary'];
    final shown = suggestions.map(shadowCatById).toList();
    if (_emotion != null && !suggestions.contains(_emotion!.id)) {
      shown.add(_emotion!);
    }
    return SingleChildScrollView(
      key: const Key('mind-emotion-scroll'),
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF5EBDD),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height:
                      MediaQuery.sizeOf(context).height < 500 ||
                          MediaQuery.textScalerOf(context).scale(16) > 24
                      ? 96
                      : 185,
                  child: CompanionCoatScope(
                    useLocalChoice: true,
                    coat: care?.journey.coat,
                    growthStage: care == null
                        ? 0
                        : care.journey.keepBaby
                        ? 0
                        : care.journey.stage,
                    child: CompanionPresence(
                      enabled: care?.journey.automaticBehavior ?? false,
                      bondStage: care?.journey.stage ?? 0,
                    ),
                  ),
                ),
                if (care != null) Text(care.displayName),
                const SizedBox(height: 6),
                Text(tr('지친 마음도 그대로 괜찮아.'), textAlign: TextAlign.center),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            tr('지금 내 마음'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (_, box) {
              final columns = MediaQuery.textScalerOf(context).scale(14) > 20
                  ? 3
                  : 5;
              return Wrap(
                spacing: 6,
                runSpacing: 8,
                children: [
                  for (final cat in shown)
                    _emotionButton(
                      cat,
                      (box.maxWidth - 6 * (columns - 1)) / columns,
                    ),
                ],
              );
            },
          ),
          TextButton.icon(
            key: const Key('mind-all-emotions'),
            onPressed: _allEmotions,
            icon: const Icon(Icons.search),
            label: Text(tr('다른 마음 찾아보기')),
          ),
          FilledButton(
            key: const Key('mind-continue'),
            onPressed: _emotion == null
                ? null
                : () => setState(() => _choosingPlant = true),
            child: Text(tr('이 마음 담아두기')),
          ),
          const SizedBox(height: 8),
          if (MediaQuery.textScalerOf(context).scale(16) <= 24)
            Text(tr('잘 정리되지 않아도 괜찮아요.'), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _plants() => ValueListenableBuilder<MongiGardenData>(
    valueListenable: MongiGardenStore.instance,
    builder: (_, data, __) => GardenPlantPicker(
      tokens: data.seedTokens,
      seeds: data.seeds,
      chooseLocation: true,
      mindPlanting: true,
      plantingDetails: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(tr('담아둘 마음 · {0}', [_emotion!.displayKeyword])),
          const SizedBox(height: 8),
          TextField(
            key: const Key('mind-note'),
            controller: _note,
            maxLength: 300,
            minLines: 2,
            maxLines: 4,
            inputFormatters: [LengthLimitingTextInputFormatter(300)],
            decoration: InputDecoration(
              labelText: tr('남기고 싶은 한마디 · 선택'),
              hintText: tr('오늘도 하루를 보낸 나에게…'),
              border: const OutlineInputBorder(),
            ),
          ),
          Wrap(
            spacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 17),
              Text(tr('나만 보는 마음 기록')),
            ],
          ),
          Text(tr('글 없이 심어도 괜찮아요.')),
          if (_saveError != null)
            Text(
              _saveError!,
              key: const Key('mind-save-error'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          const SizedBox(height: 12),
        ],
      ),
      onAddMind: _saveToPlant,
      onRecord: () => _seedActivity(true),
      onMeditate: () => _seedActivity(false),
      onLocate: (seed) => _finish(MindPlantingChoice(seed)),
      onCare: (seed) => _readMemories(seed),
      onPlant: (seed) async {
        FocusManager.instance.primaryFocus?.unfocus();
        _finish(
          MindPlantingChoice(
            seed,
            mind: PlantingMind(
              id: _requestId,
              emotionCatId: _emotion!.id,
              note: _note.text.trim(),
            ),
          ),
        );
      },
    ),
  );

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    return PopScope(
      canPop: (!_choosingPlant || widget.initialEmotionId != null) && !_saving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && mounted && !_saving) {
          setState(() => _choosingPlant = false);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFCF9F3),
        appBar: AppBar(
          title: Text(tr('마음 심기')),
          leading: BackButton(
            onPressed: _saving
                ? null
                : () {
                    if (_choosingPlant && widget.initialEmotionId == null) {
                      setState(() => _choosingPlant = false);
                    } else {
                      Navigator.pop(context);
                    }
                  },
          ),
        ),
        body: SafeArea(
          child: AbsorbPointer(
            key: const Key('mind-form-body'),
            absorbing: _saving || _childRouteOpen,
            child: _choosingPlant ? _plants() : _chooseMind(),
          ),
        ),
      ),
    );
  }
}

class _AllMindEmotions extends StatefulWidget {
  const _AllMindEmotions();
  @override
  State<_AllMindEmotions> createState() => _AllMindEmotionsState();
}

class _AllMindEmotionsState extends State<_AllMindEmotions> {
  String _query = '';
  @override
  Widget build(BuildContext context) {
    final cats = shadowCats
        .where((cat) => cat.selectable)
        .where(
          (cat) => '${cat.displayName} ${cat.displayKeyword}'
              .toLowerCase()
              .contains(_query.toLowerCase()),
        )
        .toList();
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * .8,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              key: const Key('mind-emotion-search'),
              onChanged: (text) => setState(() => _query = text),
              decoration: InputDecoration(
                labelText: tr('마음 검색'),
                prefixIcon: const Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: cats.length,
              itemBuilder: (_, index) {
                final cat = cats[index];
                return ListTile(
                  key: ValueKey('mind-all-${cat.id}'),
                  leading: Image.asset(
                    cat.imageAsset,
                    width: 56,
                    fit: BoxFit.contain,
                  ),
                  title: Text(cat.displayKeyword),
                  subtitle: Text(cat.displayName),
                  onTap: () => Navigator.pop(context, cat),
                );
              },
            ),
          ),
          if (cats.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(tr('다른 말로 마음을 찾아보세요.')),
            ),
        ],
      ),
    );
  }
}
