import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../services/cat_care_service.dart';
import '../services/garden_personal_gallery_store.dart';

class GardenGalleryScreen extends StatefulWidget {
  const GardenGalleryScreen({super.key});
  @override
  State<GardenGalleryScreen> createState() => _GardenGalleryScreenState();
}
class _GardenGalleryScreenState extends State<GardenGalleryScreen> {
  final owner = CatCareService.localOwner;
  Map<String, dynamic>? data;
  String? error;
  bool busy = false;
  @override
  void initState() { super.initState(); load(); }
  Future<void> load() async {
    try {
      final value = await GardenPersonalGalleryStore.read(owner);
      if (mounted) setState(() { data = value; error = null; });
    } catch (_) { if (mounted) setState(() => error = '사진첩을 불러오지 못했어요. 다시 시도해 주세요.'); }
  }
  Future<void> remove(String? id) async {
    final yes = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      title: Text(id == null ? '전시를 내릴까요?' : '사진을 지울까요?'),
      content: Text(id == null ? '색칠하기의 원본 작품은 남아 있어요.' : '이 사진만 지워요. 정원의 식물과 기록은 그대로예요.'),
      actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('취소')),
        TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('확인'))]));
    if (yes != true || !mounted) return;
    setState(() => busy = true);
    try {
      if (id == null) { await GardenPersonalGalleryStore.exhibit(owner, null); }
      else { await GardenPersonalGalleryStore.deletePhoto(owner, id); }
      await load();
    } catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('삭제하지 못했어요. 다시 시도해 주세요.'))); }
    finally { if (mounted) setState(() => busy = false); }
  }
  void view(String encoded, String title) {
    showDialog<void>(context: context, builder: (c) => Dialog.fullscreen(child: Scaffold(
      appBar: AppBar(title: Text(title)),
      body: InteractiveViewer(minScale: .5, maxScale: 5,
        child: Center(child: Image.memory(base64Decode(encoded), fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Text('그림을 읽지 못했어요.')))),
    )));
  }
  Future<void> export(String encoded) async {
    try {
      if (owner != CatCareService.localOwner) throw StateError('owner');
      final box = context.findRenderObject() as RenderBox;
      await SharePlus.instance.share(ShareParams(files: [XFile.fromData(base64Decode(encoded),
        mimeType: 'image/png', name: 'mindnyang-garden.png')],
        sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size));
    } catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('내보내기를 다시 시도해 주세요.'))); }
  }
  Widget entry(String png, String title, String? id) => Card(child: Column(children: [
    InkWell(onTap: () => view(png, title), child: SizedBox(height: 190, width: double.infinity,
      child: Image.memory(base64Decode(png), fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Center(child: Text('그림을 읽지 못했어요.'))))),
    Padding(padding: const EdgeInsets.all(8), child: Text(title)),
    Wrap(children: [TextButton.icon(onPressed: busy ? null : () => export(png), icon: const Icon(Icons.ios_share), label: const Text('내보내기')),
      TextButton.icon(onPressed: busy ? null : () => remove(id), icon: const Icon(Icons.delete_outline), label: Text(id == null ? '전시 내리기' : '사진 삭제'))]),
  ]));
  @override
  Widget build(BuildContext context) {
    final photos = (data?['photos'] as List? ?? []).reversed.toList();
    return Scaffold(appBar: AppBar(title: const Text('정원 사진첩')), body: SafeArea(child:
      owner != CatCareService.localOwner ? const Center(child: Text('계정이 바뀌었어요. 사진첩을 다시 열어 주세요.')) :
      error != null ? Center(child: TextButton(onPressed: load, child: Text(error!))) :
      data == null ? const Center(child: CircularProgressIndicator()) : ListView(padding: const EdgeInsets.all(16), children: [
        Text('나만 보는 사진 ${photos.length}/${GardenPersonalGalleryStore.maxPhotos} · 직접 내보낼 때만 다른 곳으로 보내요.'),
        const Text('사진은 저장 용량에 맞춰 작은 크기로 보관해요.'),
        if (data!['artwork'] != null) entry(data!['artwork'] as String, '정원에 전시 중인 색칠 작품', null)
        else const Padding(padding: EdgeInsets.all(16), child: Text('색칠하기 → 작품함 → 정원에 전시에서 액자를 꾸며 보세요.')),
        if (photos.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Text('정원의 카메라 버튼을 누르면 지금 모습이 남아요.')),
        for (final p in photos) entry(p['png'] as String, (p['date'] as String).replaceFirst('T', ' ').split('.').first, p['id'] as String),
      ])));
  }
}
