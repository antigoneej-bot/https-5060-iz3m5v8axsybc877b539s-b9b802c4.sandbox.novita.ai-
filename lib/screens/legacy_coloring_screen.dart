import '../l10n/app_language.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import '../models/coloring_page.dart';
import '../services/coloring_store.dart';
import '../services/cat_care_service.dart';
import '../services/garden_village_service.dart';
import 'memory_cards_screen.dart';

class LegacyColoringScreen extends StatefulWidget {
  const LegacyColoringScreen({super.key});
  @override
  State<LegacyColoringScreen> createState() => _LegacyColoringScreenState();
}

class _LegacyColoringScreenState extends State<LegacyColoringScreen> {
  late final owner = CatCareService.localOwner;
  late final store = ColoringStore(owner);
  final capture = GlobalKey();
  final transform = TransformationController();
  List<int?> colors = List.filled(12, null);
  final undo = <List<int?>>[];
  int design = 0;
  Color selected = const Color(0xFFFFC6DA);
  bool erasing = false, busy = true, complete = false;
  String? error;
  final palette = const [
    Color(0xFFFFC6DA),
    Color(0xFFFFD8AE),
    Color(0xFFFFEDAA),
    Color(0xFFBFE7CF),
    Color(0xFFBBDAF4),
    Color(0xFFD6C7F0),
    Color(0xFFB8A29A),
    Color(0xFF6B6377),
    Colors.white,
  ];
  bool get sameOwner => CatCareService.localOwner == owner;
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    transform.dispose();
    super.dispose();
  }

  Future<void> load() async {
    setState(() => busy = true);
    try {
      final d = await store.load(design);
      if (!mounted) return;
      setState(() {
        colors = List<int?>.from(d['colors']);
        complete = d['complete'] == true;
        undo.clear();
        error = null;
      });
    } catch (_) {
      if (mounted) setState(() => error = tr("저장된 그림을 불러오지 못했어요. 다시 열어주세요."));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> change(List<int?> next) async {
    if (busy || !sameOwner || error != null) return;
    setState(() => busy = true);
    try {
      await store.save(design, next);
      if (mounted)
        setState(() {
          undo.add(colors);
          colors = next;
          complete = false;
        });
    } catch (_) {
      message(tr("저장하지 못했어요. 다시 시도해주세요."));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void message(String text) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> finish() async {
    if (busy || !sameOwner) return;
    setState(() => busy = true);
    try {
      await store.save(design, colors, complete: true);
      if (mounted) setState(() => complete = true);
      if (colors.any((c) => c == null)) {
        message(tr("작품을 보관했어요. 모든 영역을 칠하면 오늘의 색칠 카드를 받을 수 있어요."));
      } else {
        try {
          if (!sameOwner) throw StateError(tr("계정이 바뀌었어요."));
          final r = await GardenVillageService().memoryCards(
            'claimMemoryCard',
            {'source': 'coloring', 'colors': colors},
          );
          message(
            r['already'] == true
                ? tr("작품을 보관했어요. 오늘의 색칠 카드는 이미 받았어요.")
                : tr("작품 보관 완료! 추억 카드 한 장도 받았어요."),
          );
        } catch (_) {
          message(tr("작품은 보관했어요. 로그인과 서버 연결을 확인한 뒤 완료를 다시 눌러 카드를 받아주세요."));
        }
      }
    } catch (_) {
      message(tr("작품을 보관하지 못했어요. 다시 시도해주세요."));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> gallery() async {
    if (busy || !sameOwner) return;
    try {
      final saved = await Future.wait(List.generate(3, store.gallery));
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (ctx) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: .8,
          builder: (ctx, scroll) => ListView(
            controller: scroll,
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                tr("내 작품함"),
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text(tr("도안마다 가장 최근 완성한 작품을 보관해요.")),
              if (saved.every((d) => d == null))
                Padding(
                  padding: EdgeInsets.all(30),
                  child: Text(tr("완성한 작품을 여기에 모아드릴게요.")),
                ),
              for (var i = 0; i < saved.length; i++)
                if (saved[i] != null) ...[
                  Text(coloringTitles[i]),
                  AspectRatio(
                    aspectRatio: 1,
                    child: CustomPaint(
                      painter: ColoringPainter(
                        List<int?>.from(saved[i]!['colors']),
                        i,
                      ),
                    ),
                  ),
                ],
            ],
          ),
        ),
      );
    } catch (_) {
      message(tr("작품함을 불러오지 못했어요."));
    }
  }

  Future<void> share() async {
    try {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      final boundary =
          capture.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (bytes == null || !mounted) return;
      final box = context.findRenderObject() as RenderBox;
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              bytes.buffer.asUint8List(),
              mimeType: 'image/png',
              name: 'mindnyang-coloring.png',
            ),
          ],
          text: tr("마음냥 정원에서 색칠한 나의 작은 쉼"),
          sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (_) {
      message(tr("그림 내보내기를 다시 시도해주세요."));
    }
  }

  Future<void> custom() async {
    double r = selected.red.toDouble(),
        g = selected.green.toDouble(),
        b = selected.blue.toDouble();
    final color = await showDialog<Color>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => AlertDialog(
          title: Text(tr("나만의 색")),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 45,
                color: Color.fromARGB(255, r.round(), g.round(), b.round()),
              ),
              for (var i = 0; i < 3; i++)
                Slider(
                  value: [r, g, b][i],
                  max: 255,
                  onChanged: (v) => update(() {
                    if (i == 0)
                      r = v;
                    else if (i == 1)
                      g = v;
                    else
                      b = v;
                  }),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(tr("취소")),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                ctx,
                Color.fromARGB(255, r.round(), g.round(), b.round()),
              ),
              child: Text(tr("이 색으로")),
            ),
          ],
        ),
      ),
    );
    if (color != null && mounted)
      setState(() {
        selected = color;
        erasing = false;
      });
  }

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F1),
      appBar: AppBar(
        title: Text(tr("색칠 힐링")),
        actions: [
          IconButton(
            tooltip: tr("내 작품함"),
            onPressed: busy ? null : gallery,
            icon: const Icon(Icons.collections_outlined),
          ),
          IconButton(
            tooltip: tr("추억 카드"),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MemoryCardsScreen()),
            ),
            icon: const Icon(Icons.style_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              tr("오늘은 어떤 색으로 쉬어갈까요?"),
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            Text(tr("영역을 톡 눌러 색칠해요. 두 손가락으로 확대할 수 있어요.")),
            Wrap(
              spacing: 8,
              children: [
                for (var i = 0; i < coloringTitles.length; i++)
                  ChoiceChip(
                    label: Text(coloringTitles[i]),
                    selected: design == i,
                    onSelected: busy
                        ? null
                        : (_) {
                            design = i;
                            transform.value = Matrix4.identity();
                            load();
                          },
                  ),
              ],
            ),
            if (!sameOwner) Text(tr("계정이 바뀌었어요. 화면을 다시 열어주세요.")),
            if (error != null) Text(error!),
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: InteractiveViewer(
                  transformationController: transform,
                  minScale: 1,
                  maxScale: 4,
                  child: LayoutBuilder(
                    builder: (ctx, c) => GestureDetector(
                      onTapUp: busy || error != null || !sameOwner
                          ? null
                          : (d) {
                              final point = Offset(
                                d.localPosition.dx / c.maxWidth * 400,
                                d.localPosition.dy / c.maxHeight * 400,
                              );
                              final regions = coloringRegions(design);
                              for (var i = regions.length - 1; i >= 0; i--) {
                                if (regions[i].contains(point)) {
                                  final next = List<int?>.from(colors);
                                  next[i] = erasing
                                      ? null
                                      : selected.toARGB32();
                                  change(next);
                                  break;
                                }
                              }
                            },
                      child: RepaintBoundary(
                        key: capture,
                        child: CustomPaint(
                          painter: ColoringPainter(colors, design),
                          size: Size(c.maxWidth, c.maxHeight),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final color in palette)
                  Semantics(
                    label: tr("색상 {0}", [palette.indexOf(color) + 1]),
                    button: true,
                    selected: selected == color && !erasing,
                    child: InkWell(
                      onTap: () => setState(() {
                        selected = color;
                        erasing = false;
                      }),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected == color && !erasing
                                ? const Color(0xFF726183)
                                : Colors.white,
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                  ),
                IconButton(
                  tooltip: tr("직접 색 만들기"),
                  onPressed: custom,
                  icon: const Icon(Icons.palette_outlined),
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              children: [
                TextButton.icon(
                  onPressed: busy || undo.isEmpty || !sameOwner
                      ? null
                      : () async {
                          final prev = undo.removeLast();
                          setState(() => busy = true);
                          try {
                            await store.save(design, prev);
                            if (mounted)
                              setState(() {
                                colors = prev;
                                complete = false;
                              });
                          } catch (_) {
                            undo.add(prev);
                            message(tr("되돌리기를 저장하지 못했어요."));
                          } finally {
                            if (mounted) setState(() => busy = false);
                          }
                        },
                  icon: const Icon(Icons.undo),
                  label: Text(tr("되돌리기")),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => erasing = !erasing),
                  icon: Icon(erasing ? Icons.check : Icons.auto_fix_normal),
                  label: Text(tr("지우개")),
                ),
                TextButton(
                  onPressed: () => transform.value = Matrix4.identity(),
                  child: Text(tr("전체보기")),
                ),
                TextButton.icon(
                  onPressed: share,
                  icon: const Icon(Icons.ios_share),
                  label: Text(tr("그림 내보내기")),
                ),
              ],
            ),
            FilledButton(
              onPressed: busy || error != null || !sameOwner ? null : finish,
              child: Text(
                complete ? tr("보관한 작품 · 카드 받기 확인") : tr("작품 완성 · 보관하기"),
              ),
            ),
            Text(
              busy
                  ? tr("저장 중…")
                  : complete
                  ? tr("내 작품으로 보관했어요. 위 도안을 누르면 다시 볼 수 있어요.")
                  : tr("칠할 때마다 이 기기에 저장돼요. 완성하지 않아도 괜찮아요."),
            ),
            Text(tr("기본 도안 3종 · 무료. 색칠 카드는 모든 영역을 채우면 하루 한 장 받을 수 있어요.")),
          ],
        ),
      ),
    );
  }
}
