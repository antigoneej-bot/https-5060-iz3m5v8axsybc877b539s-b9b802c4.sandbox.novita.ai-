import '../l10n/app_language.dart';
import 'dart:async';
import '../services/social_auth_service.dart';
import 'package:provider/provider.dart';
import '../mongi/integration/mongi_garden_store.dart';
import '../providers/cat_care_provider.dart';
import '../services/sound_service.dart';
import '../services/cat_care_service.dart';
import 'neighbor_news_bubble.dart';
import 'package:flutter/material.dart';
import '../models/companion_behavior.dart';
import 'companion_presence.dart';

/// First daily touch greets; subsequent touches only pet the companion.
class HomeCompanionTouch extends StatefulWidget {
  const HomeCompanionTouch({
    super.key,
    required this.name,
    required this.enabled,
    required this.bondStage,
  });
  final String name;
  final bool enabled;
  final int bondStage;
  @override
  State<HomeCompanionTouch> createState() => _HomeCompanionTouchState();
}

class _HomeCompanionTouchState extends State<HomeCompanionTouch>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final _reaction = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 3200),
  );
  bool _foreground = true, _saving = false, _heart = false;
  Timer? _heartTimer;
  String _greeting = tr("집사야, 오늘도 수고했어. 사랑해 ♡");
  String _kind = 'heart';
  String? _greetingOwner;

  bool get _showGreeting =>
      _heart &&
      _greetingOwner == CatCareService.localOwner &&
      _foreground &&
      TickerMode.of(context) &&
      (ModalRoute.of(context)?.isCurrent ?? true);

  bool get _canMove =>
      widget.enabled &&
      _foreground &&
      TickerMode.of(context) &&
      !MediaQuery.disableAnimationsOf(context) &&
      (ModalRoute.of(context)?.isCurrent ?? true);

  @override
  void initState() {
    super.initState();
    _reaction.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _heart = false);
      }
    });
    WidgetsBinding.instance.addObserver(this);
    final state = WidgetsBinding.instance.lifecycleState;
    _foreground = state == null || state == AppLifecycleState.resumed;
  }

  void _stopIfNeeded() {
    if (!_canMove) {
      _reaction.reset();
      unawaited(SoundService().stopPurr());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _stopIfNeeded();
  }

  @override
  void didUpdateWidget(covariant HomeCompanionTouch oldWidget) {
    super.didUpdateWidget(oldWidget);
    _stopIfNeeded();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) _heart = false;
    _stopIfNeeded();
  }

  Future<void> _pet() async {
    if (_saving || _reaction.isAnimating) return;
    setState(() => _saving = true);
    final owner = CatCareService.localOwner;
    try {
      final care = context.read<CatCareProvider>();
      final result = await MongiGardenStore.instance.greetCompanion();
      if (!mounted || owner != CatCareService.localOwner) return;
      await care
          .greetToday(); // own once-per-day marker; retry repairs an interrupted count.
      if (!mounted || owner != CatCareService.localOwner) return;
      final fresh = result['fresh'] == true;
      setState(() {
        _heart = true;
        _greetingOwner = owner;
        final keeper = SocialAuthService.currentUser?.displayName?.trim();
        _greeting = keeper == null || keeper.isEmpty
            ? tr("집사야, 오늘도 수고했어. 사랑해 ♡")
            : tr('{0}님, 오늘도 수고했어요. 사랑해요 ♡', [keeper]);
        _kind = result['kind'] as String;
      });
      if (_foreground &&
          TickerMode.of(context) &&
          (ModalRoute.of(context)?.isCurrent ?? true)) {
        unawaited(
          fresh ? SoundService().playMeow() : SoundService().playPurr(),
        );
      }
      _heartTimer?.cancel();
      _heartTimer = Timer(Duration(seconds: 4), () {
        if (mounted) setState(() => _heart = false);
      });
      if (_canMove && !_reaction.isAnimating) _reaction.forward(from: 0);
      if (fresh)
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: Text(
              _kind == 'gold'
                  ? tr("황금하트! 출석 완료 · 빛의 정수 15개")
                  : _kind == 'churu'
                  ? tr("하트 인사 ♡ 오늘의 행운은 츄르! 출석 완료 · 빛의 정수 5개와 츄르 1개")
                  : tr("오늘도 만나서 반가워요 · 출석 완료 · 빛의 정수 5개"),
            ),
          ),
        );
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(content: Text(tr("인사를 저장하지 못했어요. 다시 톡 눌러 주세요."))),
        );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(SoundService().stopPurr());
    _heartTimer?.cancel();
    _reaction.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: !_saving,
    label: tr('{0}에게 인사하고 출석하기. 다시 누르면 쓰다듬어요', [widget.name]),
    child: GestureDetector(
      key: Key('home-companion-touch'),
      behavior: HitTestBehavior.opaque,
      onTap: _saving ? null : _pet,
      child: AnimatedBuilder(
        animation: _reaction,
        builder: (context, _) {
          final reacting = _reaction.isAnimating && _canMove;
          return Stack(
            fit: StackFit.expand,
            children: [
              Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.textScalerOf(context).scale(12) * 2.7 + 8,
                ),
                child: CompanionPresence(
                  key: Key('home-companion-presence'),
                  enabled: widget.enabled,
                  bondStage: widget.bondStage,
                  interaction: reacting ? CompanionInteraction.petting : null,
                  interactionProgress: _reaction.value,
                ),
              ),
              Positioned(top: 0, left: 0, child: NeighborNewsBubble()),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: ValueListenableBuilder(
                    valueListenable: MongiGardenStore.instance,
                    builder: (context, data, _) => Container(
                      key: Key('home-greeting-status'),
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      decoration: _showGreeting
                          ? BoxDecoration(
                              color: Color(0xF2FFF8EF),
                              borderRadius: BorderRadius.circular(14),
                            )
                          : null,
                      child: Text(
                        _showGreeting
                            ? _greeting
                            : _saving
                            ? tr("인사 저장 중…")
                            : data.claimedGiftReceipts.contains(
                                'greeting_${MongiGardenData.dayKey(DateTime.now())}',
                              )
                            ? tr("오늘 인사 완료 ✓")
                            : tr("나를 톡 눌러줘 · 하루 한 번 출석"),
                        textAlign: TextAlign.center,
                        key: _showGreeting ? Key('home-loving-greeting') : null,
                        style: TextStyle(fontSize: 12, height: 1.3),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ),
              if (_showGreeting)
                Positioned(
                  top: 10,
                  right: 18,
                  child: IgnorePointer(
                    child: Transform.translate(
                      offset: Offset(0, -24 * _reaction.value),
                      child: Icon(
                        Icons.favorite_rounded,
                        key: Key('home-petting-heart'),
                        color: _kind == 'gold'
                            ? Color(0xffd8a52e)
                            : Color(0xFFE6A5A0),
                        size: 36,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    ),
  );
}
