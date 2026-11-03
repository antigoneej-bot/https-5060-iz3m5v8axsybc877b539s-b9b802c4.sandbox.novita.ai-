import '../services/garden_personal_gallery_store.dart';
import '../utils/private_gallery_png.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../models/coloring_boundaries.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import '../models/coloring_stroke.dart';
import '../services/brush_coloring_store.dart';
import '../services/cat_care_service.dart';
import 'legacy_coloring_screen.dart';

class ColoringHealingScreen extends StatefulWidget {
  const ColoringHealingScreen({super.key});
  @override
  State<ColoringHealingScreen> createState() => _ColoringHealingScreenState();
}

class _ColoringHealingScreenState extends State<ColoringHealingScreen> {
  late final owner = CatCareService.localOwner;
  late final store = BrushColoringStore(owner);
  final capture = GlobalKey();
  final transform = TransformationController();
  ui.Image? art;
  ColoringBoundaries? boundaries;
  bool filling = true, fullscreen = false, toolsOpen = true;
  Size? viewport;
  bool orientationChanged = false;
  List<ColoringStroke> strokes = [], redo = [];
  ColoringStroke? active;
  int? pointer;
  final _touches = <int>{};
  bool _multiTouch = false;
  Color selected = coloringPalette.first;
  final recent = <Color>[];
  int brush = 1;
  bool erase = false, moving = false, busy = true;
  String? error;
  bool get editable =>
      !busy && error == null && CatCareService.localOwner == owner;
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    if (orientationChanged) SystemChrome.setPreferredOrientations([]);
    transform.dispose();
    art?.dispose();
    super.dispose();
  }

  Future<void> load() async {
    try {
      final bytes = await rootBundle.load('assets/coloring/love_cat.png');
      final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
      final image = (await codec.getNextFrame()).image;
      codec.dispose();
      final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final labels = await compute(labelColoringRegions, {
        'rgba': rgba!.buffer.asUint8List(),
        'width': image.width,
        'height': image.height,
      });
      final regions = ColoringBoundaries(labels, image.width, image.height);
      final saved = await store.load();
      if (!mounted || CatCareService.localOwner != owner) {
        image.dispose();
        return;
      }
      setState(() {
        art = image;
        boundaries = regions;
        strokes = saved;
        busy = false;
      });
    } catch (_) {
      if (mounted)
        setState(() {
          busy = false;
          error = '그림을 불러오지 못했어요. 화면을 다시 열어주세요.';
        });
    }
  }

  void message(String text) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void setMoving(bool value) => setState(() {
    active = null;
    pointer = null;
    moving = value;
  });

  void choose(Color color) => setState(() {
    selected = color;
    erase = false;
    recent.remove(color);
    recent.insert(0, color);
    if (recent.length > 8) recent.removeLast();
  });
  Future<bool> save(List<ColoringStroke> next) async {
    if (!editable) return false;
    setState(() => busy = true);
    try {
      await store.save(next);
      if (mounted && CatCareService.localOwner == owner) {
        setState(() => strokes = next);
      }
      return true;
    } catch (_) {
      message('저장하지 못했어요. 다시 시도해 주세요.');
      return false;
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Offset point(Offset p, Size size) => Offset(
    (p.dx / size.width * 1024).clamp(0, 1024),
    (p.dy / size.height * 1536).clamp(0, 1536),
  );
  void begin(Offset p, Size size) {
    if (!editable || moving || strokes.length >= 5000) return;
    final at = point(p, size),
        region = boundaries?.regionAt(point(p, size)) ?? 0;
    if (region == 0) return;
    setState(
      () => active = ColoringStroke(
        selected.toARGB32(),
        coloringBrushWidths[brush],
        erase,
        [at],
        region: region,
        fill: filling,
      ),
    );
  }

  void move(Offset p, Size size) {
    if (!editable ||
        active == null ||
        active!.fill ||
        active!.points.length >= 20000)
      return;
    final v = point(p, size);
    if ((v - active!.points.last).distance >= 1)
      setState(() => active!.points.add(v));
  }

  Future<void> end() async {
    final stroke = active;
    if (stroke == null) return;
    setState(() => active = null);
    final saved = await save([...strokes, stroke]);
    if (!mounted) return;
    if (saved) {
      setState(() => redo.clear());
    } else if (CatCareService.localOwner == owner) {
      setState(() {
        active = stroke;
        error = '마지막 붓질을 저장하지 못했어요.';
      });
    }
  }

  Future<void> custom() async {
    var hsv = HSVColor.fromColor(selected);
    final c = await showDialog<Color>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => AlertDialog(
          title: const Text('나만의 색'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(height: 45, color: hsv.toColor()),
              const Text('색조'),
              Slider(
                value: hsv.hue,
                max: 360,
                onChanged: (v) => update(() => hsv = hsv.withHue(v)),
              ),
              const Text('선명함'),
              Slider(
                value: hsv.saturation,
                onChanged: (v) => update(() => hsv = hsv.withSaturation(v)),
              ),
              const Text('밝기'),
              Slider(
                value: hsv.value,
                onChanged: (v) => update(() => hsv = hsv.withValue(v)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, hsv.toColor()),
              child: const Text('이 색으로'),
            ),
          ],
        ),
      ),
    );
    if (c != null && mounted) choose(c);
  }

  Future<void> finish() async {
    if (!editable || strokes.isEmpty) return;
    setState(() => busy = true);
    try {
      await store.save(strokes, finished: true);
      message('내 작품함에 보관했어요.');
    } catch (_) {
      message('보관하지 못했어요. 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> exhibitSaved(List<ColoringStroke> saved) async {
    if (!editable || art == null || saved.isEmpty) return;
    final yes = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      title: const Text('정원에 전시할까요?'),
      content: const Text('완성한 작품을 나만 보는 정원 액자에 걸어요. 이미 전시 중인 작품은 이 그림으로 바뀌고 색칠 원본은 유지돼요.'),
      actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('취소')),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('전시하기'))]));
    if (yes != true || !mounted || !editable || art == null) return;
    setState(() => busy = true);
    try {
      final recorder = ui.PictureRecorder();
      BrushColoringPainter(art, saved, boundaries: boundaries).paint(Canvas(recorder), const Size(512, 768));
      final picture = recorder.endRecording();
      final image = await picture.toImage(512, 768);
      picture.dispose();
      try { await GardenPersonalGalleryStore.exhibit(owner, await privateGalleryPng(image)); }
      finally { image.dispose(); }
      message('내 정원의 액자에 전시했어요. 사진첩에서 내릴 수 있어요.');
    } catch (_) { message('전시하지 못했어요. 다시 시도해 주세요.'); }
    finally { if (mounted) setState(() => busy = false); }
  }

  Future<void> gallery() async {
    if (!editable) return;
    try {
      final saved = await store.load(finished: true);
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (ctx) => FractionallySizedBox(
          heightFactor: .85,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text('내 작품함 · 사랑을 안은 고양이'),
                Expanded(
                  child: saved.isEmpty
                      ? const Center(child: Text('완성한 그림을 보관해 보세요.'))
                      : AspectRatio(
                          aspectRatio: 2 / 3,
                          child: CustomPaint(
                            painter: BrushColoringPainter(
                              art,
                              saved,
                              boundaries: boundaries,
                            ),
                          ),
                        ),
                ),
                if (saved.isNotEmpty) TextButton.icon(
                  onPressed: () { Navigator.pop(ctx); exhibitSaved(saved); },
                  icon: const Icon(Icons.park_outlined), label: const Text('정원에 전시')),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('닫기'),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (_) {
      message('작품함을 불러오지 못했어요.');
    }
  }

  Future<void> share() async {
    if (!editable) return;
    try {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      final image =
          await (capture.currentContext!.findRenderObject()
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: 1);
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
              name: 'mindnyang-love-cat.png',
            ),
          ],
          sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (_) {
      message('그림 내보내기를 다시 시도해 주세요.');
    }
  }

  Widget swatch(Color c) => Padding(
    padding: const EdgeInsets.all(3),
    child: Semantics(
      label: '색상 ${c.toARGB32().toRadixString(16)}',
      selected: selected == c && !erase,
      button: true,
      child: InkWell(
        onTap: () => choose(c),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: c,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected == c && !erase
                  ? const Color(0xFF657A70)
                  : Colors.black12,
              width: selected == c && !erase ? 3 : 1,
            ),
          ),
          child: selected == c && !erase
              ? Icon(
                  Icons.check,
                  size: 18,
                  color: c.computeLuminance() > .4
                      ? Colors.black54
                      : Colors.white,
                )
              : null,
        ),
      ),
    ),
  );
  void fit({bool cover = false}) {
    final size = viewport;
    if (size == null) return;
    final scale = cover
        ? math.max(size.width / 1024, size.height / 1536)
        : math.min(size.width / 1024, size.height / 1536);
    transform.value = Matrix4.identity()
      ..translate(
        (size.width - 1024 * scale) / 2,
        (size.height - 1536 * scale) / 2,
      )
      ..scale(scale);
  }

  Widget drawing() => LayoutBuilder(
    builder: (context, c) {
      final size = Size(c.maxWidth, c.maxHeight);
      if (viewport != size) {
        viewport = size;
        fit(cover: fullscreen);
      }
      final minimum = math.min(size.width / 1024, size.height / 1536);
      return ClipRect(
        key: const Key('coloring-viewport'),
        child: InteractiveViewer(
          constrained: false,
          transformationController: transform,
          panEnabled: moving,
          scaleEnabled: true,
          minScale: minimum,
          maxScale: math.max(3, minimum * 8),
          boundaryMargin: const EdgeInsets.all(1536),
          child: SizedBox(
            width: 1024,
            height: 1536,
            child: Listener(
              onPointerDown: (e) {
                _touches.add(e.pointer);
                if (_touches.length > 1) {
                  setState(() {
                    _multiTouch = true;
                    active = null;
                    pointer = null;
                  });
                  return;
                }
                if (moving || _multiTouch) return;
                pointer = e.pointer;
                begin(e.localPosition, const Size(1024, 1536));
              },
              onPointerMove: (e) {
                if (!moving && !_multiTouch && pointer == e.pointer)
                  move(e.localPosition, const Size(1024, 1536));
              },
              onPointerUp: (e) {
                _touches.remove(e.pointer);
                if (!moving && !_multiTouch && pointer == e.pointer) {
                  pointer = null;
                  end();
                }
                if (_touches.isEmpty) setState(() => _multiTouch = false);
              },
              onPointerCancel: (e) {
                _touches.remove(e.pointer);
                setState(() {
                  active = null;
                  pointer = null;
                  if (_touches.isEmpty) _multiTouch = false;
                });
              },
              child: GestureDetector(
                onPanStart: !moving ? (_) {} : null,
                onPanUpdate: !moving ? (_) {} : null,
                child: RepaintBoundary(
                  key: capture,
                  child: Semantics(
                    label: editable ? '색칠 준비 완료' : '색칠 불러오기·저장 중',
                    child: CustomPaint(
                      key: const Key('brush-canvas'),
                      size: const Size(1024, 1536),
                      painter: BrushColoringPainter(art, [
                        ...strokes,
                        if (active != null) active!,
                      ], boundaries: boundaries),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
  Widget paintTools() => ListView(
    key: const Key('paint-tools'),
    padding: const EdgeInsets.all(12),
    children: [
      const SizedBox(height: 4),
      Wrap(
        spacing: 6,
        children: [
          ChoiceChip(
            label: const Text('영역 채우기'),
            selected: filling,
            onSelected: (_) => setState(() {
              filling = true;
              moving = false;
            }),
          ),
          ChoiceChip(
            label: const Text('붓으로 칠하기'),
            selected: !filling,
            onSelected: (_) => setState(() {
              filling = false;
              moving = false;
            }),
          ),
        ],
      ),
      Wrap(
        spacing: 6,
        children: [
          for (var i = 0; i < 3; i++)
            ChoiceChip(
              label: Text(['아주 얇은 붓', '중간 붓', '큰 붓'][i]),
              showCheckmark: false,
              avatar: Center(
                child: Container(
                  width: [3.0, 10.0, 22.0][i],
                  height: [3.0, 10.0, 22.0][i],
                  decoration: BoxDecoration(
                    color: erase ? Colors.grey : selected,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              selected: brush == i,
              onSelected: (_) => setState(() {
                brush = i;
                filling = false;
                moving = false;
              }),
            ),
        ],
      ),
      const Text('48색 · 옆으로 넘겨 골라요'),
      SizedBox(
        height: 104,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < 24; i++)
                Column(
                  children: [
                    swatch(coloringPalette[i * 2]),
                    swatch(coloringPalette[i * 2 + 1]),
                  ],
                ),
            ],
          ),
        ),
      ),
      if (recent.isNotEmpty) ...[
        const Text('최근 사용한 색'),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: recent.map(swatch).toList()),
        ),
      ],
      Wrap(
        spacing: 8,
        children: [
          TextButton.icon(
            onPressed: custom,
            icon: const Icon(Icons.palette_outlined),
            label: const Text('직접 색 만들기'),
          ),
          FilterChip(
            label: const Text('지우개'),
            selected: erase,
            onSelected: (v) => setState(() => erase = v),
          ),
          TextButton(
            onPressed: editable && strokes.isNotEmpty
                ? () async {
                    final last = strokes.last;
                    if (await save(strokes.sublist(0, strokes.length - 1)) &&
                        mounted)
                      setState(() => redo.add(last));
                  }
                : null,
            child: const Text('되돌리기'),
          ),
          TextButton(
            onPressed: editable && redo.isNotEmpty
                ? () async {
                    final last = redo.last;
                    if (await save([...strokes, last]) && mounted)
                      setState(() => redo.removeLast());
                  }
                : null,
            child: const Text('다시하기'),
          ),
          TextButton(
            onPressed: editable ? share : null,
            child: const Text('그림 내보내기'),
          ),
        ],
      ),
      FilledButton(
        onPressed: editable && strokes.isNotEmpty ? finish : null,
        child: Text(busy ? '불러오기·저장 중…' : '작품 완성 · 보관하기'),
      ),
      const Text('붓질을 마칠 때마다 이 기기에 저장돼요. 선은 지워지지 않아요. 지우개도 선택한 굵기를 사용해요.'),
      TextButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LegacyColoringScreen()),
        ),
        child: const Text('이전 도안·작품함 · 색칠 카드'),
      ),
    ],
  );
  Widget viewControls() => Wrap(
    spacing: 4,
    children: [
      IconButton(
        tooltip: fullscreen ? '전체화면 닫기' : '전체화면',
        onPressed: () => setState(() {
          fullscreen = !fullscreen;
          viewport = null;
        }),
        icon: Icon(fullscreen ? Icons.fullscreen_exit : Icons.fullscreen),
      ),
      IconButton(
        tooltip: '가로·세로 전환',
        onPressed: () async {
          orientationChanged = true;
          await SystemChrome.setPreferredOrientations(
            MediaQuery.orientationOf(context) == Orientation.portrait
                ? [
                    DeviceOrientation.landscapeLeft,
                    DeviceOrientation.landscapeRight,
                  ]
                : [DeviceOrientation.portraitUp],
          );
        },
        icon: const Icon(Icons.screen_rotation),
      ),
      IconButton(
        tooltip: '그림 전체보기',
        onPressed: () => fit(),
        icon: const Icon(Icons.fit_screen),
      ),
      FilterChip(
        key: const Key('coloring-move-mode'),
        label: Text(moving ? '이동 모드 · 색칠 멈춤' : '색칠 중 · 이동으로 전환'),
        selected: moving,
        onSelected: editable ? setMoving : null,
      ),
      IconButton(
        tooltip: toolsOpen ? '색칠 도구 접기' : '색칠 도구 펼치기',
        onPressed: () => setState(() => toolsOpen = !toolsOpen),
        icon: const Icon(Icons.palette_outlined),
      ),
    ],
  );
  @override
  Widget build(BuildContext context) {
    final landscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final canvas = drawing();
    return PopScope(
      canPop: !fullscreen,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop)
          setState(() {
            fullscreen = false;
            viewport = null;
          });
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF8F1),
        appBar: fullscreen
            ? null
            : AppBar(
                title: const Text('감정고양이 색칠'),
                actions: [
                  IconButton(
                    tooltip: '내 작품함',
                    onPressed: editable ? gallery : null,
                    icon: const Icon(Icons.collections_outlined),
                  ),
                ],
              ),
        body: fullscreen
            ? Stack(
                fit: StackFit.expand,
                children: [
                  canvas,
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      bottom: false,
                      child: Material(
                        color: const Color(0xEFFFF8F1),
                        child: viewControls(),
                      ),
                    ),
                  ),
                  if (toolsOpen)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      left: landscape ? null : 0,
                      width: landscape ? 280 : null,
                      height: MediaQuery.sizeOf(context).height * .4,
                      child: SafeArea(
                        top: false,
                        child: Material(
                          color: const Color(0xEFFFF8F1),
                          child: paintTools(),
                        ),
                      ),
                    ),
                ],
              )
            : SafeArea(
                child: Column(
                  children: [
                    viewControls(),
                    if (error != null) Text(error!),
                    if (error != null && active != null)
                      TextButton(
                        onPressed: () {
                          setState(() => error = null);
                          end();
                        },
                        child: const Text('저장 다시 시도'),
                      ),
                    if (!sameOwner) const Text('계정이 바뀌었어요. 화면을 다시 열어주세요.'),
                    Expanded(
                      child: landscape
                          ? Row(
                              children: [
                                Expanded(child: canvas),
                                if (toolsOpen)
                                  SizedBox(width: 280, child: paintTools()),
                              ],
                            )
                          : Column(
                              children: [
                                Expanded(child: canvas),
                                if (toolsOpen)
                                  SizedBox(
                                    height:
                                        MediaQuery.sizeOf(context).height * .32,
                                    child: paintTools(),
                                  ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  bool get sameOwner => CatCareService.localOwner == owner;
}

class BrushColoringPainter extends CustomPainter {
  final ui.Image? art;
  final ColoringBoundaries? boundaries;
  final List<ColoringStroke> strokes;
  BrushColoringPainter(this.art, this.strokes, {this.boundaries});
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.scale(size.width / 1024, size.height / 1536);
    const bounds = Rect.fromLTWH(0, 0, 1024, 1536);
    canvas.drawRect(bounds, Paint()..color = Colors.white);
    canvas.saveLayer(bounds, Paint());
    for (final s in strokes) {
      canvas.save();
      final regionPath = s.region == null ? null : boundaries?.path(s.region!);
      if (s.region != null && regionPath == null) {
        canvas.restore();
        continue;
      }
      if (regionPath != null) canvas.clipPath(regionPath, doAntiAlias: false);
      final paint = Paint()
        ..color = Color(s.color)
        ..strokeWidth = s.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..blendMode = s.erase ? BlendMode.clear : BlendMode.srcOver;
      if (s.fill && regionPath != null) {
        canvas.drawPath(regionPath, paint..style = PaintingStyle.fill);
      } else if (s.points.length == 1) {
        canvas.drawCircle(
          s.points.first,
          s.width / 2,
          paint..style = PaintingStyle.fill,
        );
      } else if (s.points.isNotEmpty) {
        final path = Path()..moveTo(s.points.first.dx, s.points.first.dy);
        for (final p in s.points.skip(1)) {
          path.lineTo(p.dx, p.dy);
        }
        canvas.drawPath(path, paint);
      }
      canvas.restore();
    }
    canvas.restore();
    if (art != null)
      canvas.drawImageRect(
        art!,
        Rect.fromLTWH(0, 0, art!.width.toDouble(), art!.height.toDouble()),
        bounds,
        Paint()
          ..blendMode = BlendMode.multiply
          ..filterQuality = FilterQuality.medium,
      );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant BrushColoringPainter oldDelegate) => true;
}
