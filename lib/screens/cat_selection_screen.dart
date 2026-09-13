import 'package:shared_preferences/shared_preferences.dart';
import '../data/cat_browse_groups.dart';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/shadow_cats_data.dart';
import '../data/alternative_emotion_mapping.dart';
import '../models/shadow_cat.dart';
import '../providers/app_state_provider.dart';
import '../services/storage_service.dart';
import '../services/subscription_service.dart';
import '../theme.dart';
import '../widgets/garden_path_card.dart';
import 'premium_screen.dart';

/// 42마리 무료 + 10마리 유료(Basic 구독) 그림자 감정 고양이 카드 그리드에서
/// 지금 내 기분과 닮은 고양이 한 마리를 골라 선택하는 화면.
/// 딱딱한 사각 카드 그리드 대신, 카드마다 조금씩 다른 유기적인 블롭
/// 모양과 파스텔 톤을 주어 정원의 화단처럼 느껴지도록 합니다.
///
/// 유료 캐릭터는 항상 그리드에 노출되지만(절대 완전히 숨기지 않음), 흐림+저채도의
/// '안개' 처리로 표시됩니다. 탭하면 곧바로 결제창으로 보내지 않고, 먼저 그
/// 캐릭터를 짧게 소개한 뒤 가장 가까운 무료 캐릭터를 대안으로 안내합니다.
class CatSelectionScreen extends StatefulWidget {
  const CatSelectionScreen({super.key});

  @override
  State<CatSelectionScreen> createState() => _CatSelectionScreenState();
}

class _CatSelectionScreenState extends State<CatSelectionScreen>
    with TickerProviderStateMixin {
  String? _group;
  String _query = '';
  bool _showAll = false;
  bool _favoritesOnly = false;
  final Set<String> _favorites = {};
  final TextEditingController _search = TextEditingController();

  // 감정 필터 알약 태그마다 순환 배정되는 파스텔 색상 쌍 (정원 산책로와 같은 팔레트)
  static const _pillColors = [
    (bg: AppColors.blobMint, accent: AppColors.blobMintAccent),
    (bg: AppColors.blobPeach, accent: AppColors.blobPeachAccent),
    (bg: AppColors.blobLavender, accent: AppColors.blobLavenderAccent),
    (bg: AppColors.blobRose, accent: AppColors.blobRoseAccent),
    (bg: AppColors.blobButter, accent: AppColors.blobButterAccent),
    (bg: AppColors.blobPeriwinkle, accent: AppColors.blobPeriwinkleAccent),
  ];

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _favorites.addAll(prefs.getStringList('cat_browse_favorites_v1') ?? []));
  }
  Future<void> _toggleFavorite(String id) async {
    setState(() { if (!_favorites.add(id)) _favorites.remove(id); });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('cat_browse_favorites_v1', _favorites.toList());
  }
  bool _showReassurance = false;
  bool _checkedReassurance = false;

  // 성능 최적화: 카드마다 독립된 AnimationController(Ticker)를 두면 52개의
  // 타이머가 동시에 매 프레임 재계산되어 화면이 느려지고 터치 반응이
  // 늦어집니다. 대신 화면 전체가 공유하는 단 하나의 Ticker만 두고, 카드별로
  // 속도/위상(phase)만 다르게 주어 여전히 '화단처럼 제각각 살아있는' 느낌은
  // 유지하면서 Ticker 개수를 52개 에서 1개로 줄입니다.
  late final AnimationController _sharedFloat;
  final Map<int, _CardMotion> _motionCache = {};

  _CardMotion _motionFor(int seed) {
    return _motionCache.putIfAbsent(seed, () {
      final rng = Random(seed * 41 + 9);
      return _CardMotion(
        speedMul: 0.75 + rng.nextDouble() * 0.6,
        phase: rng.nextDouble(),
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _sharedFloat = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _maybeShowReassurance(),
    );
  }

  @override
  void dispose() {
    _search.dispose();
    _sharedFloat.dispose();
    super.dispose();
  }

  Future<void> _maybeShowReassurance() async {
    final seen = await StorageService.hasSeenFreeTierReassurance();
    if (!mounted) return;
    if (!seen) {
      setState(() {
        _showReassurance = true;
        _checkedReassurance = true;
      });
      await StorageService.markFreeTierReassuranceSeen();
    } else {
      setState(() => _checkedReassurance = true);
    }
  }

  void _dismissReassurance() {
    setState(() => _showReassurance = false);
  }

  Future<void> _onTapPremiumCat(ShadowCat cat) async {
    await StorageService.recordPremiumCatAttempt(cat.id);
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PremiumCatIntroSheet(cat: cat),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppStateProvider>();
    final catalog = shadowCats.where((c) => c.selectable).toList();
    final recent = app.history.map((e) => e.catId).toSet().take(3).toList();
    final filtered = catalog.where((cat) {
      if (_favoritesOnly && !_favorites.contains(cat.id)) return false;
      if (_query.isNotEmpty) return '${cat.keyword} ${cat.nameKr}'.contains(_query);
      return _group == null || catBrowseGroups[_group]!.contains(cat.id);
    }).toList();
    final browsing = _group != null || _query.isNotEmpty || _showAll || _favoritesOnly;
    final allCats = browsing ? (_showAll || _query.isNotEmpty || _favoritesOnly
        ? filtered : filtered.take(6).toList()) : <ShadowCat>[];
    final isPremiumUser = context.watch<AppStateProvider>().isPremiumUser;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '지금 내 기분과 가장 닮은\n고양이를 골라보세요',
          textAlign: TextAlign.center,
          style: titleFont(
            fontSize: 19,
            color: AppColors.titlePastelGreen,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '먼저 가까운 마음을 골라주세요.\n오늘 고른 감정이 함께 키우는 고양이를 바꾸지는 않아요.',
          textAlign: TextAlign.center,
          style: bodyFont(
            fontSize: 12.5,
            color: AppColors.inkSoft,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        _EmotionSearchField(
          controller: _search,
          onChanged: (value) => setState(() => _query = value.trim()),
        ),
        const SizedBox(height: 14),
        Wrap(spacing: 8, runSpacing: 10, children: [
          for (final entry in catBrowseGroups.keys.toList().asMap().entries)
            _EmotionFilterPill(
              label: entry.value,
              selected: _group == entry.value,
              colorSet: _pillColors[entry.key % _pillColors.length],
              onTap: () => setState(() {
                _group = _group == entry.value ? null : entry.value;
                _showAll = false; _favoritesOnly = false;
                _search.clear(); _query = '';
              }),
            ),
          _EmotionFilterPill(
            label: '전체 고양이',
            selected: _showAll && _group == null,
            colorSet: _pillColors[catBrowseGroups.length % _pillColors.length],
            onTap: () => setState(() {
              _group = null; _showAll = true; _favoritesOnly = false;
              _search.clear(); _query = '';
            }),
          ),
          _EmotionFilterPill(
            label: '즐겨찾기',
            icon: Icons.star_rounded,
            selected: _favoritesOnly,
            colorSet: _pillColors[(catBrowseGroups.length + 1) % _pillColors.length],
            onTap: () => setState(() {
              _favoritesOnly = !_favoritesOnly; _group = null; _showAll = false;
              _search.clear(); _query = '';
            }),
          ),
        ]),
        if (!browsing && recent.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text('최근에 고른 마음', style: bodyFont(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.inkSoft)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [for (final id in recent)
            _RecentEmotionChip(
              label: shadowCatById(id).keyword,
              onTap: () {
                final cat = shadowCatById(id);
                if (cat.isPremium && !isPremiumUser) {
                  _onTapPremiumCat(cat);
                } else { app.selectCat(cat); }
              },
            ),
          ]),
        ],
        if (browsing && allCats.isEmpty)
          const Padding(padding: EdgeInsets.all(16), child: Text('찾는 고양이가 없어요. 다른 감정이나 전체 고양이를 골라보세요.')),
        if (_checkedReassurance)
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            child: _showReassurance
                ? Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: _ReassuranceBanner(onDismiss: _dismissReassurance),
                  )
                : const SizedBox.shrink(),
          ),
        const SizedBox(height: 18),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: allCats.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.78,
          ),
          itemBuilder: (context, index) {
            final cat = allCats[index];
            final locked = cat.isPremium && !isPremiumUser;
            return Stack(children: [ _CatCard(
              cat: cat,
              seed: index,
              locked: locked,
              motion: _motionFor(index),
              sharedAnimation: _sharedFloat,
              onTap: locked
                  ? () => _onTapPremiumCat(cat)
                  : () => context.read<AppStateProvider>().selectCat(cat),
            ), Positioned(top: 0, right: 0, child: IconButton(
              tooltip: _favorites.contains(cat.id) ? '즐겨찾기 해제' : '즐겨찾기 추가',
              onPressed: () => _toggleFavorite(cat.id),
              icon: Icon(_favorites.contains(cat.id) ? Icons.star : Icons.star_border,
                color: AppColors.ink),
            )) ]);
          },
        ),
        if (browsing && !_showAll && _query.isEmpty && !_favoritesOnly && filtered.length > 6)
          TextButton(onPressed: () => setState(() => _showAll = true),
            child: Text('이 마음의 고양이 더 보기 (${filtered.length - 6})')),
      ],
    );
  }
}

/// 감정체크 화면 최초 진입 시 1회만 보여주는, 부담을 낮추는 안내 문구.
/// '유료 캐릭터를 못 봐서 아쉽다'는 느낌이 아니라, 지금 가진 것만으로도
/// 충분하다는 다정한 톤을 유지합니다.
class _ReassuranceBanner extends StatelessWidget {
  final VoidCallback onDismiss;
  const _ReassuranceBanner({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return GlassBlob(
      accent: AppColors.blobMintAccent,
      background: AppColors.blobMint,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Text('🌿', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '42가지 감정으로도 충분히 마음을 표현할 수 있어요',
              style: bodyFont(fontSize: 12, color: AppColors.ink, height: 1.4),
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: AppColors.inkSoft,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 유료 캐릭터를 탭했을 때 나타나는 바텀시트.
/// 1단계: 캐릭터 이름 + 짧은 설명 + 가장 가까운 무료 캐릭터 대안 안내
/// 2단계: "더 자세히 표현하고 싶다면?" + 구독 CTA + 동일한 크기의 "나중에" 버튼
/// (다크패턴 방지: CTA와 '나중에' 버튼은 항상 같은 크기/시각적 비중으로 노출)
class _PremiumCatIntroSheet extends StatelessWidget {
  final ShadowCat cat;
  const _PremiumCatIntroSheet({required this.cat});

  @override
  Widget build(BuildContext context) {
    final altIds = alternativeFreeCatIdsFor(cat.id);
    final altCats = <ShadowCat>[];
    for (final id in altIds) {
      for (final c in shadowCats) {
        if (c.id == id) {
          altCats.add(c);
          break;
        }
      }
    }

    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.bg0,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Opacity(
                    opacity: 0.85,
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                      child: Image.asset(
                        cat.imageAsset,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        cacheWidth: 160,
                        cacheHeight: 160,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${cat.emoji} ${cat.nameKr}',
                        style: titleFont(fontSize: 17, color: AppColors.ink),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '정원 플러스 Basic 캐릭터',
                        style: bodyFont(
                          fontSize: 11,
                          color: AppColors.blobButterAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '${cat.keyword}과는 다른, 더 섬세한 감정이에요',
              style: bodyFont(
                fontSize: 13.5,
                color: AppColors.ink,
                height: 1.6,
              ),
            ),
            if (altCats.isNotEmpty) ...[
              const SizedBox(height: 14),
              GlassBlob(
                accent: AppColors.blobLavenderAccent,
                background: AppColors.blobLavender,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '지금은 ${altCats.map((c) => "${c.emoji} ${c.nameKr}").join(" 또는 ")}로도\n비슷한 마음을 표현해볼 수 있어요',
                        style: bodyFont(
                          fontSize: 12.5,
                          color: AppColors.ink,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.read<AppStateProvider>().selectCat(altCats.first);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ink,
                    side: BorderSide(
                      color: AppColors.blobLavenderAccent.withValues(
                        alpha: 0.4,
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: Text(
                    '${altCats.first.emoji} ${altCats.first.nameKr}로 기록하기',
                    style: bodyFont(fontSize: 13, color: AppColors.ink),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Text(
              '더 자세히 표현하고 싶다면?',
              textAlign: TextAlign.center,
              style: titleFont(fontSize: 15, color: AppColors.titlePastelGreen),
            ),
            const SizedBox(height: 12),
            // 다크패턴 방지: CTA와 '나중에' 버튼을 같은 높이/같은 시각적 비중으로 배치
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.inkSoft,
                        side: BorderSide(color: AppColors.line),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: Text(
                        '나중에',
                        style: bodyFont(fontSize: 14, color: AppColors.inkSoft),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PremiumScreen(),
                          ),
                        );
                        if (context.mounted) {
                          await context
                              .read<AppStateProvider>()
                              .refreshPremiumStatus();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: Text(
                        '자세히 보기',
                        style: serifFont(fontSize: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                SubscriptionService.displayPrice,
                style: bodyFont(fontSize: 11, color: AppColors.inkSoft),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardMotion {
  final double speedMul;
  final double phase;
  const _CardMotion({required this.speedMul, required this.phase});
}

class _CatCard extends StatefulWidget {
  final ShadowCat cat;
  final int seed;
  final bool locked;
  final _CardMotion motion;
  final Animation<double> sharedAnimation;
  final VoidCallback onTap;
  const _CatCard({
    required this.cat,
    required this.seed,
    required this.onTap,
    required this.motion,
    required this.sharedAnimation,
    this.locked = false,
  });

  @override
  State<_CatCard> createState() => _CatCardState();
}

class _CatCardState extends State<_CatCard> {
  bool _hovering = false;
  bool _pressed = false;

  // 디자인 리팩토링: 52장 전부 다른 랜덤 코너를 쓰던 '블롭' 프레임을 없애고,
  // 카드 이미지 자체에 이미 그려진 프레임과 충돌하지 않도록 통일된 라운드
  // 사각형 하나로 정리했습니다. 3열 그리드의 코너 라인이 모두 맞아 훨씬
  // 정돈되어 보입니다.
  static const _cardRadius = BorderRadius.all(Radius.circular(20));
  static const _imageRadius = BorderRadius.all(Radius.circular(14));

  static const _accents = [
    AppColors.blobMintAccent,
    AppColors.blobPeachAccent,
    AppColors.blobLavenderAccent,
    AppColors.blobRoseAccent,
    AppColors.blobButterAccent,
    AppColors.blobPeriwinkleAccent,
  ];

  @override
  Widget build(BuildContext context) {
    final accent = _accents[widget.seed % _accents.length];
    // 눌림(press)과 호버를 하나의 "활성" 상태로 합쳐, 터치 디바이스에서도
    // 탭하는 순간 즉시 카드가 살짝 눌리는 피드백을 받도록 합니다.
    final active = _hovering || _pressed;
    final scale = _pressed ? 0.94 : (_hovering ? 1.04 : 1.0);
    // RepaintBoundary: 카드 하나가 애니메이션으로 다시 그려질 때 다른 51개
    // 카드나 배경까지 함께 리페인트되지 않도록 화면을 여기서 잘라줍니다.
    return RepaintBoundary(
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedBuilder(
            animation: widget.sharedAnimation,
            builder: (context, child) {
              final t =
                  (widget.sharedAnimation.value * widget.motion.speedMul +
                      widget.motion.phase) %
                  1.0;
              // 눌린 상태에서는 흔들림 애니메이션을 잠시 멈춰 "지금 눌렸다"는
              // 느낌이 미세한 흔들림에 묻히지 않도록 합니다.
              final dy = _pressed ? 0.0 : sin(t * 2 * pi) * 2.6;
              final angle = _pressed ? 0.0 : sin(t * 2 * pi) * 0.018;
              return Transform.translate(
                offset: Offset(0, dy),
                child: Transform.rotate(angle: angle, child: child),
              );
            },
            child: AnimatedScale(
              scale: scale,
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOut,
              // 카드 프레임: 52장 모두 같은 라운드 사각형으로 통일해 3열 그리드의
              // 라인이 서로 맞도록 정리했습니다. 이미지 자체에 이미 크림색
              // 액자 테두리가 그려져 있으므로, 카드 배경은 짙은 색 그라데이션
              // 대신 차분한 아이보리 톤 하나로 단순화해 "액자 안의 액자"처럼
              // 겹쳐 보이던 문제를 없앴습니다. 포인트 컬러는 대신 감정 키워드
              // 태그에 담아 정보 전달 용도로 사용합니다.
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  borderRadius: _cardRadius,
                  color: AppColors.bg1,
                  border: Border.all(
                    color: accent.withValues(alpha: active ? 0.4 : 0.16),
                    width: active ? 1.4 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.ink.withValues(
                        alpha: _pressed ? 0.03 : (active ? 0.1 : 0.06),
                      ),
                      blurRadius: active ? 14 : 8,
                      offset: Offset(0, _pressed ? 1 : 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: _imageRadius,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            widget.locked
                                ? ColorFiltered(
                                    colorFilter: const ColorFilter.matrix([
                                      0.35, 0.35, 0.35, 0, 0, //
                                      0.35, 0.35, 0.35, 0, 0, //
                                      0.35, 0.35, 0.35, 0, 0, //
                                      0, 0, 0, 1, 0, //
                                    ]),
                                    child: ImageFiltered(
                                      imageFilter: ImageFilter.blur(
                                        sigmaX: 3.2,
                                        sigmaY: 3.2,
                                      ),
                                      child: Opacity(
                                        opacity: 0.55,
                                        child: Image.asset(
                                          widget.cat.imageAsset,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          cacheWidth: 200,
                                          cacheHeight: 200,
                                        ),
                                      ),
                                    ),
                                  )
                                : Image.asset(
                                    widget.cat.imageAsset,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    cacheWidth: 200,
                                    cacheHeight: 200,
                                  ),
                            // 감정 키워드 태그: 색을 카드 전체에 칠하는 대신
                            // 이미지 위 좌상단에 작은 알약 태그로만 얹어, 한눈에
                            // 스캔이 빠르면서도 이미지 원본 프레임을 가리지 않게
                            // 했습니다.
                            if (!widget.locked)
                              Positioned(
                                left: 5,
                                top: 5,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.82),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    widget.cat.keyword,
                                    style: bodyFont(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: accent,
                                      height: 1,
                                    ),
                                  ),
                                ),
                              ),
                            if (widget.locked)
                              Positioned.fill(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.white.withValues(alpha: 0.05),
                                        Colors.white.withValues(alpha: 0.32),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            if (widget.locked)
                              Positioned(
                                bottom: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.75),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    '✨',
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      widget.locked
                          ? '？？？'
                          : '${widget.cat.emoji} ${widget.cat.keyword}',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: pathLabelFont(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: widget.locked
                            ? AppColors.inkSoft
                            : AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 감정 검색창 - 앱 전체의 유리질감 파스텔 톤(GlassBlob)과 어울리도록,
/// 딱딱한 흰 사각 인풋 대신 은은한 라벤더 톤 알약형 검색창으로 디자인했습니다.
class _EmotionSearchField extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _EmotionSearchField({required this.controller, required this.onChanged});

  @override
  State<_EmotionSearchField> createState() => _EmotionSearchFieldState();
}

class _EmotionSearchFieldState extends State<_EmotionSearchField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final active = _focused || widget.controller.text.isNotEmpty;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.blobLavender.withValues(alpha: active ? 0.9 : 0.7),
            AppColors.blobPeriwinkle.withValues(alpha: active ? 0.75 : 0.5),
          ],
        ),
        border: Border.all(
          color: AppColors.blobLavenderAccent.withValues(alpha: active ? 0.45 : 0.22),
          width: active ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.blobLavenderAccent.withValues(alpha: active ? 0.16 : 0.08),
            blurRadius: active ? 18 : 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Focus(
        onFocusChange: (v) => setState(() => _focused = v),
        child: TextField(
          controller: widget.controller,
          onChanged: widget.onChanged,
          style: bodyFont(fontSize: 14, color: AppColors.ink),
          cursorColor: AppColors.blobLavenderAccent,
          decoration: InputDecoration(
            isDense: true,
            border: InputBorder.none,
            hintText: '감정 찾기 · 예: 서운함, 감사',
            hintStyle: bodyFont(fontSize: 13, color: AppColors.inkSoft.withValues(alpha: 0.75)),
            prefixIcon: Icon(Icons.search_rounded, color: AppColors.blobLavenderAccent, size: 22),
            suffixIcon: widget.controller.text.isEmpty
                ? null
                : IconButton(
                    icon: Icon(Icons.close_rounded, size: 18, color: AppColors.blobLavenderAccent),
                    onPressed: () {
                      widget.controller.clear();
                      widget.onChanged('');
                    },
                  ),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }
}

/// 감정 카테고리 필터 알약 - ChoiceChip 대신, 카테고리마다 다른 파스텔
/// 색상(정원 산책로 팔레트)을 순환 배정해 화단처럼 알록달록하지만 톤은
/// 통일된 필 버튼으로 디자인했습니다.
class _EmotionFilterPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final ({Color bg, Color accent}) colorSet;
  final VoidCallback onTap;
  const _EmotionFilterPill({
    required this.label,
    required this.selected,
    required this.colorSet,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: selected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorSet.accent.withValues(alpha: 0.92),
                    colorSet.accent.withValues(alpha: 0.72),
                  ],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorSet.bg.withValues(alpha: 0.75),
                    colorSet.bg.withValues(alpha: 0.45),
                  ],
                ),
          border: Border.all(
            color: colorSet.accent.withValues(alpha: selected ? 0.55 : 0.24),
            width: selected ? 1.4 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: colorSet.accent.withValues(alpha: 0.22),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: selected ? Colors.white : colorSet.accent),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: bodyFont(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 최근 고른 마음 - 작은 골드 톤 알약 칩 (메인 CTA 톤과 통일해 '빠른 선택'
/// 임을 은근히 드러내면서도 과하지 않게 처리)
class _RecentEmotionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _RecentEmotionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: AppColors.gold.withValues(alpha: 0.12),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.35), width: 1),
        ),
        child: Text(
          label,
          style: bodyFont(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.goldSoft),
        ),
      ),
    );
  }
}
