import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/shadow_cat.dart';
import '../../services/analytics_service.dart';
import 'garden_scene.dart';
import 'mongi_garden_data.dart';
import 'plant_memory_store.dart';
import 'postcard_link.dart';

class GardenPostcardScreen extends StatefulWidget {
  final MongiGardenData data;
  final List<ShadowCat> cats;
  const GardenPostcardScreen({
    super.key,
    required this.data,
    required this.cats,
  });
  @override
  State<GardenPostcardScreen> createState() => _GardenPostcardScreenState();
}

class _GardenPostcardScreenState extends State<GardenPostcardScreen> {
  final _boundary = GlobalKey();
  final _caption = TextEditingController();
  bool _busy = false;
  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  Future<void> _event(String event) async {
    try {
      await AnalyticsService().logEvent(event);
    } catch (_) {
      /* sharing remains available */
    }
  }

  Future<void> _chooseMemory() async {
    try {
      await PlantMemoryStore.instance.reload();
      if (!mounted) return;
      final memories = PlantMemoryStore.instance.value.values
          .where((m) => m.note.trim().isNotEmpty)
          .toList();
      final note = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('엽서에 담을 추억을 골라 주세요'),
          content: SizedBox(
            width: double.maxFinite,
            child: memories.isEmpty
                ? const Text('식물에 추억을 남기면 여기서 고를 수 있어요.')
                : ListView(
                    shrinkWrap: true,
                    children: memories
                        .map(
                          (m) => ListTile(
                            title: Text(m.name.isEmpty ? '이름 없는 식물' : m.name),
                            subtitle: Text(
                              m.note,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () => Navigator.pop(context, m.note),
                          ),
                        )
                        .toList(),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
          ],
        ),
      );
      if (!mounted || note == null) return;
      // The user explicitly selected this note. They can edit it before sharing.
      setState(() => _caption.text = note.characters.take(120).toString());
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('추억을 불러오지 못했어요. 문장을 직접 적어도 좋아요.')),
        );
      }
    }
  }

  Future<void> _share(BuildContext buttonContext) async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      final assets = [
        'assets/mongi/images/garden_scene_bg.png',
        ...widget.cats.take(6).map((cat) => cat.imageAsset),
      ];
      for (final asset in assets) {
        Object? error;
        await precacheImage(
          AssetImage(asset),
          context,
          onError: (e, _) {
            error = e;
          },
        );
        if (error != null) throw StateError('image unavailable');
        if (!mounted) return;
      }
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted || !buttonContext.mounted) return;
      final boundary =
          _boundary.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final anchor = buttonContext.findRenderObject() as RenderBox;
      final origin = anchor.localToGlobal(Offset.zero) & anchor.size;
      final picture = await boundary.toImage(
        pixelRatio: 1080 / boundary.size.width,
      );
      final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
      picture.dispose();
      if (bytes == null || !mounted) return;
      final link = gardenPostcardLink(
        const String.fromEnvironment('GARDEN_PUBLIC_PLAY_URL'),
      );
      await _event('garden_postcard_share_requested');
      final result = await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(bytes.buffer.asUint8List(), mimeType: 'image/png'),
          ],
          fileNameOverrides: ['garden-postcard.png'],
          text: link == null
              ? '마음냥 정원 · 몽이와 함께 가꾸는 나의 정원'
              : '마음냥 정원에서 만나요.\n$link',
          sharePositionOrigin: origin,
        ),
      );
      // OS success means a share target was chosen, not delivery or an installation.
      if (result.status == ShareResultStatus.success) {
        await _event('garden_postcard_share_target');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('엽서를 공유하지 못했어요. 다시 시도해 주세요.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('나의 정원 엽서')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RepaintBoundary(
            key: _boundary,
            child: ColoredBox(
              color: const Color(0xFFFFF9EE),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      '마음냥 정원',
                      style: TextStyle(fontSize: 22, color: Color(0xFF344B3A)),
                    ),
                    const SizedBox(height: 12),
                    GardenScene(data: widget.data, cats: widget.cats),
                    if (_caption.text.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        child: Text(
                          _caption.text.trim(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 17,
                            height: 1.5,
                            color: Color(0xFF344B3A),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    const Text(
                      '몽이와 함께, 오늘도 조금씩',
                      style: TextStyle(color: Color(0xFF526750)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _caption,
            enabled: !_busy,
            maxLength: 120,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: '엽서에 담을 문장 (선택)',
              hintText: '오늘 내 정원에 남기고 싶은 한마디',
            ),
            onChanged: (_) => setState(() {}),
          ),
          TextButton(
            onPressed: _busy ? null : _chooseMemory,
            child: const Text('식물의 추억에서 직접 고르기'),
          ),
          const Text('위 엽서에 보이는 정원과 문장만 이미지로 공유돼요.'),
          const SizedBox(height: 12),
          Builder(
            builder: (buttonContext) => FilledButton.icon(
              onPressed: _busy ? null : () => _share(buttonContext),
              icon: const Icon(Icons.ios_share),
              label: Text(_busy ? '엽서 준비 중…' : '이 엽서 공유하기'),
            ),
          ),
        ],
      ),
    ),
  );
}
