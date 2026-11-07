import '../l10n/app_language.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../mongi/integration/mongi_garden_store.dart';
import '../mongi/integration/plant_memory_store.dart';
import '../mongi/models/seed.dart';
import '../screens/garden_memory_book_screen.dart';
import '../services/private_letter_memory_source.dart';

/// Explicitly attaches an already selected own sentence to an existing plant.
/// The dialog is optional and never changes growth or posts to a shared garden.
Future<bool> attachLetterQuoteToPlant(
  BuildContext context, {
  required String sourceLetterId,
  required String quote,
}) async {
  var selectedQuote = quote;
  if (quote.characters.length > 300) {
    final controller = TextEditingController();
    final route = DialogRoute<String>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (dialog, update) => AlertDialog(
          title: Text(tr("나무에 남길 짧은 부분 고르기")),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  tr(
                    "간직한 말은 그대로 두고, 이 중 300자 이내를 나무에 연결해요. 아래에서 원하는 부분을 그대로 옮겨 주세요.",
                  ),
                ),
                const SizedBox(height: 12),
                SelectableText(quote),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  maxLength: 300,
                  minLines: 2,
                  maxLines: 5,
                  decoration: InputDecoration(labelText: tr("나무에 남길 부분")),
                  onChanged: (_) => update(() {}),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog),
              child: Text(tr("나중에")),
            ),
            FilledButton(
              onPressed:
                  controller.text.trim().isNotEmpty &&
                      controller.text.characters.length <= 300 &&
                      quote.contains(controller.text)
                  ? () => Navigator.pop(dialog, controller.text)
                  : null,
              child: Text(tr("이 부분으로 나무 고르기")),
            ),
          ],
        ),
      ),
    );
    final chosen = await Navigator.of(context).push(route);
    await route.completed;
    controller.dispose();
    if (chosen == null || !context.mounted) return false;
    selectedQuote = chosen;
  }
  return await showDialog<bool>(
        context: context,
        builder: (_) => _PlantQuotePicker(
          sourceLetterId: sourceLetterId,
          quote: selectedQuote,
        ),
      ) ??
      false;
}

Future<void> openPrivateLetterMemory(
  BuildContext context,
  String sourceLetterId,
) => Navigator.of(context).push<void>(
  MaterialPageRoute(
    builder: (_) => _PrivateLetterMemory(sourceId: sourceLetterId),
  ),
);

class _PlantQuotePicker extends StatefulWidget {
  const _PlantQuotePicker({required this.sourceLetterId, required this.quote});
  final String sourceLetterId, quote;
  @override
  State<_PlantQuotePicker> createState() => _PlantQuotePickerState();
}

class _PlantQuotePickerState extends State<_PlantQuotePicker> {
  bool _loading = true, _saving = false;
  String? _selected, _error;
  List<SeedType> _plants = [];
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await MongiGardenStore.instance.reload();
      await PlantMemoryStore.instance.reload();
      _plants = SeedType.all
          .where(
            (plant) =>
                (MongiGardenStore.instance.value.seeds[plant.id] ?? 0) > 0,
          )
          .toList();
      _selected = _plants.firstOrNull?.id;
    } catch (_) {
      _error = tr("내 정원의 식물을 불러오지 못했어요. 다시 시도해 주세요.");
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (_saving || _selected == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await PlantMemoryStore.instance.attachLetterQuote(
        plantId: _selected!,
        sourceLetterId: widget.sourceLetterId,
        quote: widget.quote,
      );
      if (mounted) Navigator.pop(context, true);
    } on FormatException catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = error.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = tr("나무에 문장을 저장하지 못했어요. 원본 기록과 간직한 문장은 그대로 있어요.");
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    return PopScope(
      canPop: !_saving,
      child: AlertDialog(
        title: Text(tr("내 나무에 문장 간직하기")),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(tr("내가 쓴 문장과 기록 날짜를 나무의 추억에 남겨요. 이웃에게는 공개되지 않아요.")),
                const SizedBox(height: 12),
                Text(widget.quote),
                const SizedBox(height: 12),
                if (_loading)
                  const LinearProgressIndicator()
                else if (_plants.isEmpty && _error == null)
                  Text(
                    tr("아직 심은 식물이 없어요. 내 정원에 씨앗을 심은 뒤, 간직한 문장에서 다시 연결할 수 있어요."),
                  )
                else
                  for (final plant in _plants)
                    ListTile(
                      selected: _selected == plant.id,
                      leading: Icon(
                        _selected == plant.id
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                      ),
                      onTap: _saving
                          ? null
                          : () => setState(() => _selected = plant.id),
                      title: Text(
                        PlantMemoryStore.instance.value[plant.id]?.name
                                    .trim()
                                    .isNotEmpty ==
                                true
                            ? PlantMemoryStore.instance.value[plant.id]!.name
                            : plant.label,
                      ),
                      subtitle: Text(plant.label),
                    ),
                const SizedBox(height: 8),
                Text(
                  tr("원본 기록이 삭제되거나 보관 기간을 지나면 연결한 문장도 정리돼요."),
                  style: TextStyle(fontSize: 12),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  if (_plants.isEmpty)
                    TextButton(
                      onPressed: _saving ? null : _load,
                      child: Text(tr("다시 불러오기")),
                    ),
                ],
                if (_saving) const LinearProgressIndicator(),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.pop(context, false),
            child: Text(tr("나중에")),
          ),
          FilledButton(
            onPressed: _saving || _loading || _selected == null ? null : _save,
            child: Text(tr("이 나무에 간직하기")),
          ),
        ],
      ),
    );
  }
}

class _PrivateLetterMemory extends StatefulWidget {
  const _PrivateLetterMemory({required this.sourceId});
  final String sourceId;
  @override
  State<_PrivateLetterMemory> createState() => _PrivateLetterMemoryState();
}

class _PrivateLetterMemoryState extends State<_PrivateLetterMemory> {
  late Future<PrivateLetterMemorySource?> _source;
  @override
  void initState() {
    super.initState();
    _source = PrivateLetterMemorySource.find(widget.sourceId);
  }

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    return Scaffold(
      appBar: AppBar(title: Text(tr("그날의 내 마음"))),
      body: FutureBuilder<PrivateLetterMemorySource?>(
        future: _source,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: TextButton(
                onPressed: () => setState(
                  () =>
                      _source = PrivateLetterMemorySource.find(widget.sourceId),
                ),
                child: Text(tr("편지를 불러오지 못했어요. 다시 시도하기")),
              ),
            );
          }
          final source = snapshot.data;
          if (source == null) {
            return Center(child: Text(tr("이 편지는 삭제되어 더 이상 남아 있지 않아요.")));
          }
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                DateFormat(
                  tr("yyyy년 M월 d일"),
                ).format(source.writtenAt.toLocal()),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(source.label),
              const SizedBox(height: 24),
              SelectableText(source.text, style: const TextStyle(height: 1.7)),
              const SizedBox(height: 28),
              Text(tr("그때의 마음을 지금의 내가 다시 읽어요. 다른 사람에게 공개되지 않아요.")),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GardenMemoryBookScreen(
                      initialMonth: source.writtenAt.toLocal(),
                    ),
                  ),
                ),
                icon: const Icon(Icons.menu_book_outlined),
                label: Text(tr("이 달의 정원 기록집 보기")),
              ),
            ],
          );
        },
      ),
    );
  }
}
