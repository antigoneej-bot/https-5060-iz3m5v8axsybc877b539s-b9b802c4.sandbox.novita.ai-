import 'package:flutter/material.dart';
import '../services/garden_style_store.dart';
import '../mongi/widgets/garden_decoration_sheet.dart';

Future<void> showGardenStyles(BuildContext context) => showModalBottomSheet<void>(
  context: context, isScrollControlled: true, useSafeArea: true, showDragHandle: true,
  builder: (_) => const _Styles());
class _Styles extends StatefulWidget {
  const _Styles();
  @override
  State<_Styles> createState() => _StylesState();
}
class _StylesState extends State<_Styles> {
  final name = TextEditingController();
  bool busy = false;
  String? message;
  @override
  void initState() { super.initState(); run(GardenStyleStore.instance.reload); }
  @override
  void dispose() { name.dispose(); super.dispose(); }
  Future<void> run(Future<void> Function() action) async {
    if (busy) return;
    setState(() { busy = true; message = null; });
    try { await action(); }
    catch (e) { if (mounted) setState(() => message = e is StateError ? e.message.toString() : '저장하지 못했어요. 다시 시도해 주세요.'); }
    finally { if (mounted) setState(() => busy = false); }
  }
  Future<bool> confirm(String title) async => await showDialog<bool>(context: context, builder: (c) => AlertDialog(
    title: Text(title), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('취소')),
      FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('확인'))])) ?? false;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: GardenStyleStore.instance, builder: (context, _) {
    final store = GardenStyleStore.instance;
    final layouts = store.layouts;
    return SizedBox(height: MediaQuery.sizeOf(context).height * .78, child: ListView(padding: const EdgeInsets.all(20), children: [
      const Text('계절과 나의 배치', style: TextStyle(fontSize: 22)),
      const Text('계절 장식은 내 화면에만 보여요. 심은 식물·성장·재화는 바뀌지 않아요.'),
      Wrap(spacing: 8, children: [for (final s in GardenStyleStore.seasons.entries)
        ChoiceChip(label: Text(s.value), selected: store.season == s.key, onSelected: busy ? null : (_) => run(() => store.setSeason(s.key)))]),
      const Text('봄 꽃장식 · 여름 파라솔 · 가을 낙엽 더미 · 겨울 눈사람'),
      TextButton.icon(onPressed: busy ? null : () => showGardenDecorationSheet(context), icon: const Icon(Icons.yard_outlined), label: const Text('계절 소품 고르기')),
      const Divider(),
      const Text('현재 배치 저장 · 최대 8개'),
      TextField(controller: name, maxLength: 30, decoration: const InputDecoration(labelText: '배치 이름'), onChanged: (_) => setState(() {})),
      FilledButton(onPressed: busy || name.text.trim().isEmpty ? null : () async {
        final key = name.text.trim();
        if (layouts.containsKey(key) && !await confirm('같은 이름의 배치를 덮어쓸까요?')) return;
        if (mounted) await run(() => store.save(key));
      }, child: const Text('현재 배치 저장')),
      for (final key in layouts.keys.cast<String>()) ListTile(title: Text(key),
        subtitle: const Text('현재 정원에 있는 아이템의 위치만 복원'),
        onTap: busy ? null : () async { if (await confirm('이 배치를 적용할까요?') && mounted) await run(() => store.apply(key)); },
        trailing: IconButton(tooltip: '저장한 배치 삭제', icon: const Icon(Icons.delete_outline), onPressed: busy ? null : () async {
          if (await confirm('저장한 배치를 지울까요?') && mounted) await run(() => store.delete(key));
        })),
      if (busy) const LinearProgressIndicator(),
      if (message != null) Text(message!),
    ]));
  });
}
