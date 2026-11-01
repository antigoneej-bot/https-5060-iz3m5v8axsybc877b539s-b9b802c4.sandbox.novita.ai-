import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../services/keepsake_tree_store.dart';
import '../widgets/keepsake_tree_art.dart';
import '../widgets/premium_test_access.dart';
import '../mongi/widgets/garden_keepsake_sheets.dart' show showPlantMemoryManager;

class KeepsakeForestScreen extends StatefulWidget {
  final KeepsakeTreeStore? store;
  const KeepsakeForestScreen({super.key, this.store});
  @override
  State<KeepsakeForestScreen> createState() => _KeepsakeForestScreenState();
}

class _KeepsakeForestScreenState extends State<KeepsakeForestScreen> {
  late final store = widget.store ?? KeepsakeTreeStore.instance;
  List<KeepsakeTree> trees = [];
  bool busy = true;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => busy = true);
    try {
      final result = await store.load();
      if (mounted)
        setState(() {
          trees = result;
          error = null;
        });
    } catch (_) {
      if (mounted)
        setState(() => error = '기억의 숲을 불러오지 못했어요. 저장된 기록은 지우지 않았어요.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> plant() async {
    final tree = await Navigator.push<KeepsakeTree>(
      context,
      MaterialPageRoute(builder: (_) => _SeedEditor(store: store)),
    );
    if (!mounted) return;
    if (tree != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _TreeDetail(tree: tree, store: store),
        ),
      );
      if (mounted) await load();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFFFAF2),
    appBar: AppBar(
      title: const Text('기억의 나무'),
      actions: [
        IconButton(
          tooltip: '새로고침',
          onPressed: busy ? null : load,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            '기억하고 싶은 날,\n씨앗 하나를 심어요.',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          const Text('사랑도, 용서도, 평화도.\n내가 고른 씨앗에 날짜와 이야기를 담아 천천히 키워요.'),
          const PremiumFeatureLabel('기억의 씨앗 심기 · 나무 키우기'),
          if (busy) const LinearProgressIndicator(),
          if (error != null) ...[
            Text(error!),
            TextButton(
              onPressed: busy ? null : load,
              child: const Text('다시 불러오기'),
            ),
          ],
          FilledButton.icon(
            onPressed: busy || error != null ? null : plant,
            icon: const Icon(Icons.add),
            label: const Text('기억의 씨앗 심기'),
          ),
          const SizedBox(height: 16),
          if (!busy && trees.isEmpty && error == null) ...[
            SizedBox(
              height: 230,
              child: KeepsakeTreeArt(
                kind: KeepsakeKind.love,
                metal: KeepsakeMetal.gold,
                stage: 0,
              ),
            ),
            const Text(
              '아직 심은 씨앗이 없어요.\n처음부터 큰 나무가 생기지 않아요.',
              textAlign: TextAlign.center,
            ),
          ],
          for (final tree in trees)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                  side: BorderSide(
                    color: Color(tree.metal.color).withValues(alpha: .4),
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(28),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _TreeDetail(tree: tree, store: store),
                      ),
                    );
                    if (mounted) load();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 240,
                          child: KeepsakeTreeArt(
                            kind: tree.kind,
                            metal: tree.metal,
                            stage: tree.stage,
                          ),
                        ),
                        Text(
                          tree.name,
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${tree.kind.label} · ${tree.metal.label} · ${tree.stageLabel}',
                        ),
                        Text(
                          '${tree.notes.first.day} · 추억 ${tree.notes.length}개',
                        ),
                        Text('함께 돌본 ${tree.careDays.length}일'),
                        const SizedBox(height: 10),
                        const Text('추억 보기 · 돌보기  →'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          const Text(
            '쉬는 날에도 시들지 않아요. 기록한 날짜와 내용은 나만 볼 수 있어요. 설정의 데이터 백업에 기억의 나무도 함께 담겨요.',
            textAlign: TextAlign.center,
          ),
          TextButton(
            onPressed: () => showPlantMemoryManager(context),
            child: const Text('이전 정원 식물에 남긴 추억 보기'),
          ),
        ],
      ),
    ),
  );
}

class _SeedEditor extends StatefulWidget {
  final KeepsakeTreeStore store;
  const _SeedEditor({required this.store});
  @override
  State<_SeedEditor> createState() => _SeedEditorState();
}

class _SeedEditorState extends State<_SeedEditor> {
  final name = TextEditingController(), note = TextEditingController();
  KeepsakeKind kind = KeepsakeKind.love;
  KeepsakeMetal metal = KeepsakeMetal.gold;
  late String day = keepsakeDay(widget.store.now());
  bool busy = false;
  String? error;
  @override
  void dispose() {
    name.dispose();
    note.dispose();
    super.dispose();
  }

  Future<void> save() async {
    setState(() => busy = true);
    try {
      final tree = await widget.store.plant(
        name: name.text.trim().isEmpty ? '${kind.label}의 기억' : name.text,
        kind: kind,
        metal: metal,
        day: day,
        text: note.text,
      );
      if (mounted) Navigator.pop(context, tree);
    } catch (e) {
      if (mounted)
        setState(
          () => error = e is StateError
              ? e.message.toString()
              : e is FormatException
              ? e.message
              : '씨앗을 저장하지 못했어요. 다시 시도해주세요.',
        );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFFFAF2),
    appBar: AppBar(title: const Text('기억의 씨앗 고르기')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            '어떤 마음을 심을까요?',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final k in KeepsakeKind.values)
                ChoiceChip(
                  label: Text('${k.label}의 씨앗'),
                  selected: kind == k,
                  onSelected: busy ? null : (_) => setState(() => kind = k),
                ),
            ],
          ),
          Text(kind.description),
          SizedBox(
            height: 175,
            child: KeepsakeTreeArt(kind: kind, metal: metal, stage: 0),
          ),
          const Text('자라날 나무의 빛깔'),
          Wrap(
            spacing: 8,
            children: [
              for (final m in KeepsakeMetal.values)
                ChoiceChip(
                  label: Text(m.label),
                  avatar: CircleAvatar(
                    backgroundColor: Color(m.color),
                    radius: 7,
                  ),
                  selected: metal == m,
                  onSelected: busy ? null : (_) => setState(() => metal = m),
                ),
            ],
          ),
          TextField(
            controller: name,
            maxLength: 60,
            enabled: !busy,
            decoration: const InputDecoration(
              labelText: '나무 이름',
              hintText: '예: 엄마와의 봄날',
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('기념할 날짜'),
            subtitle: Text(day),
            trailing: const Icon(Icons.calendar_month),
            onTap: busy
                ? null
                : () async {
                    final selected = await pickKeepsakeDate(context, day);
                    if (selected != null && mounted)
                      setState(() => day = selected);
                  },
          ),
          TextField(
            controller: note,
            maxLength: 3000,
            minLines: 4,
            maxLines: 8,
            enabled: !busy,
            decoration: const InputDecoration(
              labelText: '기억하고 싶은 내용',
              hintText: '이 씨앗에 담고 싶은 사람, 순간, 약속을 적어주세요.',
              border: OutlineInputBorder(),
            ),
          ),
          const Text('기념일과 실제 심은 날은 따로 기록해요. 과거 날짜를 적어도 오늘은 씨앗부터 시작해요.'),
          if (error != null)
            Text(error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: busy ? null : save,
            child: Text(busy ? '씨앗을 심고 있어요…' : '이 기억으로 씨앗 심기'),
          ),
        ],
      ),
    ),
  );
}

Future<String?> pickKeepsakeDate(BuildContext context, String day) async {
  final d = await showDatePicker(
    context: context,
    initialDate: DateTime.parse(day),
    firstDate: DateTime(1900),
    lastDate: DateTime(2200, 12, 31),
    helpText: '기억하고 싶은 날짜',
  );
  return d == null
      ? null
      : '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class _TreeDetail extends StatefulWidget {
  final KeepsakeTree tree;
  final KeepsakeTreeStore store;
  const _TreeDetail({required this.tree, required this.store});
  @override
  State<_TreeDetail> createState() => _TreeDetailState();
}

class _TreeDetailState extends State<_TreeDetail> {
  late KeepsakeTree tree = widget.tree;
  bool busy = false;
  String? error;
  Future<void> change(Future<KeepsakeTree> Function() action) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final result = await action();
      if (mounted)
        setState(() {
          tree = result;
          error = null;
        });
    } catch (e) {
      if (mounted)
        setState(
          () => error = e is StateError
              ? e.message.toString()
              : '저장하지 못했어요. 새로고침 후 다시 시도해주세요.',
        );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> refresh() async {
    await change(() async {
      final all = await widget.store.load();
      final found = all.where((t) => t.id == tree.id).firstOrNull;
      if (found == null) throw StateError('삭제된 나무예요. 목록으로 돌아가주세요.');
      return found;
    });
  }

  Future<void> editNote([KeepsakeNote? previous]) async {
    final result = await Navigator.push<KeepsakeNote>(
      context,
      MaterialPageRoute(
        builder: (_) => _NoteEditor(
          previous: previous,
          day: keepsakeDay(widget.store.now()),
        ),
      ),
    );
    if (result != null && mounted) {
      await change(
        () => widget.store.change(
          tree,
          notes: previous == null
              ? [...tree.notes, result]
              : [
                  for (final n in tree.notes)
                    if (n.id == previous.id) result else n,
                ],
        ),
      );
    }
  }

  Future<bool> confirm(String title, String message) async =>
      await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('삭제'),
            ),
          ],
        ),
      ) ??
      false;
  Future<void> settings() async {
    final controller = TextEditingController(text: tree.name);
    var metal = tree.metal;
    final route = DialogRoute<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => AlertDialog(
          title: const Text('나무 이름과 빛깔'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  maxLength: 60,
                  decoration: const InputDecoration(labelText: '나무 이름'),
                ),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final m in KeepsakeMetal.values)
                      ChoiceChip(
                        label: Text(m.label),
                        selected: m == metal,
                        onSelected: (_) => update(() => metal = m),
                      ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('저장'),
            ),
          ],
        ),
      ),
    );
    final saved = await Navigator.of(context).push(route);
    await route.completed;
    final name = controller.text;
    controller.dispose();
    if (saved == true && mounted)
      await change(() => widget.store.change(tree, name: name, metal: metal));
  }

  @override
  Widget build(BuildContext context) {
    final canCare = tree.canCare(widget.store.now());
    final notes = [...tree.notes]..sort((a, b) => b.day.compareTo(a.day));
    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF2),
      appBar: AppBar(
        title: Text(tree.name),
        actions: [
          IconButton(
            tooltip: '이름·빛깔 수정',
            onPressed: busy ? null : settings,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: '새로고침',
            onPressed: busy ? null : refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              '${tree.kind.label}의 씨앗에서 자라는 ${tree.metal.label} 기억',
              textAlign: TextAlign.center,
            ),
            SizedBox(
              height: 320,
              child: KeepsakeTreeArt(
                kind: tree.kind,
                metal: tree.metal,
                stage: tree.stage,
              ),
            ),
            Text(
              tree.stageLabel,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            Text(
              '심은 날 ${tree.plantedDay} · 돌본 ${tree.careDays.length}일',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: (tree.careDays.length / 30).clamp(0, 1),
              color: Color(tree.metal.color),
              backgroundColor: const Color(0xFFECE5DD),
              minHeight: 7,
              borderRadius: BorderRadius.circular(9),
            ),
            const SizedBox(height: 8),
            Text(
              tree.nextCare == null
                  ? '나무는 다 자랐지만 추억은 계속 쌓을 수 있어요.'
                  : '${tree.nextCare}일 더 돌보면 다음 모습으로 자라요.',
              textAlign: TextAlign.center,
            ),
            if (busy) const LinearProgressIndicator(),
            if (error != null)
              Text(error!, style: const TextStyle(color: Colors.red)),
            FilledButton.icon(
              onPressed: busy || !canCare
                  ? null
                  : () => change(() => widget.store.change(tree, care: true)),
              icon: const Icon(Icons.water_drop_outlined),
              label: Text(canCare ? '오늘의 물과 마음 주기' : '오늘은 돌봄을 마쳤어요'),
            ),
            const Text(
              '한국 날짜 기준 하루 한 번 자라요. 씨앗 → 새싹(3일) → 어린 나무(7일) → 빛나는 나무(14일) → 보석나무(30일). 쉬어도 성장은 줄어들지 않아요.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '이 나무에 담긴 추억',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  tooltip: '추억 더하기',
                  onPressed: busy ? null : () => editNote(),
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            for (final note in notes)
              Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note.day,
                        style: TextStyle(
                          color: Color(tree.metal.color),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(note.text),
                      Wrap(
                        children: [
                          TextButton(
                            onPressed: busy ? null : () => editNote(note),
                            child: const Text('날짜·내용 수정'),
                          ),
                          if (tree.notes.length > 1)
                            TextButton(
                              onPressed: busy
                                  ? null
                                  : () async {
                                      if (await confirm(
                                        '이 추억을 삭제할까요?',
                                        '이 날짜에 남긴 내용만 삭제하며 나무의 성장은 그대로 유지해요.',
                                      ))
                                        await change(
                                          () => widget.store.change(
                                            tree,
                                            notes: tree.notes
                                                .where((n) => n.id != note.id)
                                                .toList(),
                                          ),
                                        );
                                    },
                              child: const Text('추억 삭제'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: busy
                  ? null
                  : () async {
                      if (!await confirm(
                        '기억의 나무를 삭제할까요?',
                        '이 나무의 추억 ${tree.notes.length}개와 성장 기록을 모두 삭제해요. 앱 안에서는 되돌릴 수 없어요.',
                      ))
                        return;
                      setState(() => busy = true);
                      try {
                        await widget.store.remove(tree);
                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                        if (mounted) setState(() => error = e.toString());
                      } finally {
                        if (mounted) setState(() => busy = false);
                      }
                    },
              child: const Text(
                '이 나무와 추억 전체 삭제',
                style: TextStyle(color: Color(0xFFA2646C)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteEditor extends StatefulWidget {
  final KeepsakeNote? previous;
  final String day;
  const _NoteEditor({this.previous, required this.day});
  @override
  State<_NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<_NoteEditor> {
  late final text = TextEditingController(text: widget.previous?.text ?? '');
  late String day = widget.previous?.day ?? widget.day;
  String? error;
  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.previous == null ? '추억 더하기' : '추억 수정')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ListTile(
            title: Text(day),
            trailing: const Icon(Icons.calendar_month),
            onTap: () async {
              final d = await pickKeepsakeDate(context, day);
              if (d != null && mounted) setState(() => day = d);
            },
          ),
          TextField(
            controller: text,
            minLines: 6,
            maxLines: 12,
            maxLength: 3000,
            decoration: const InputDecoration(
              labelText: '기억하고 싶은 내용',
              border: OutlineInputBorder(),
            ),
          ),
          if (error != null) Text(error!),
          FilledButton(
            onPressed: () {
              if (text.text.trim().isEmpty) {
                setState(() => error = '기억하고 싶은 내용을 적어주세요.');
                return;
              }
              Navigator.pop(
                context,
                KeepsakeNote(
                  id: widget.previous?.id ?? const Uuid().v4(),
                  day: day,
                  text: text.text.trim(),
                ),
              );
            },
            child: const Text('이 추억 저장'),
          ),
        ],
      ),
    ),
  );
}
