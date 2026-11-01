import 'dart:async';
import '../screens/companion_coat_screen.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/companion_journey.dart';
import '../models/companion_behavior.dart';
import '../models/companion_reminder.dart';
import '../services/sound_service.dart';
import 'companion_reminder_settings.dart';
import '../providers/cat_care_provider.dart';
import 'companion_presence.dart';
import '../mongi/widgets/garden_cat_pose.dart';
import '../mongi/widgets/garden_cat_shadow.dart';
import '../mongi/widgets/companion_name_editor.dart';

Future<void> showCompanionCare(
  BuildContext context, {
  CompanionMoment? invitation,
}) {
  final care = context.read<CatCareProvider>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) => ChangeNotifierProvider.value(
      value: care,
      child: SizedBox(
        height: MediaQuery.sizeOf(sheetContext).height * .82,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          child: CompanionCarePanel(invitation: invitation),
        ),
      ),
    ),
  );
}

/// A compact, private view of the same yellow companion used in the garden.
class CompanionCarePanel extends StatefulWidget {
  final CompanionMoment? invitation;
  const CompanionCarePanel({super.key, this.invitation});
  @override
  State<CompanionCarePanel> createState() => _CompanionCarePanelState();
}

class _CompanionCarePanelState extends State<CompanionCarePanel>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _response = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );
  CompanionMoment? _action;
  String? _line, _error;
  bool _saving = false, _foreground = true;
  bool get _reduceMotion => MediaQuery.disableAnimationsOf(context);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(context.read<CatCareProvider>().loadJourney());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) _response.stop();
    if (_foreground && mounted) {
      unawaited(context.read<CatCareProvider>().loadJourney());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reduceMotion) _response.stop();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _response.dispose();
    super.dispose();
  }

  Future<void> _care(CompanionMoment action) async {
    if (_saving) return;
    final care = context.read<CatCareProvider>();
    final before = care.journey.activeGrowthDays;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (action == CompanionMoment.feed) {
        await care.feed();
      } else if (action == CompanionMoment.play) {
        await care.playWithCat();
      } else if (action == CompanionMoment.pet) {
        await care.patCat();
      } else {
        await care.rememberMoment(action, requiredSave: true);
      }
      if (!mounted) return;
      final familiar = care.journey.stage > 0;
      final reaction = switch (action) {
        CompanionMoment.feed => '맛있게 먹고 나니 든든해. 밥 챙겨 줘서 고마워!',
        CompanionMoment.play => '장난감을 눈으로 따라봐요. 같이 노니까 재밌어!',
        CompanionMoment.pet =>
          familiar ? '익숙한 손길에 눈을 감고 골골거려요.' : '손길을 느끼며 천천히 눈을 감아요.',
        CompanionMoment.brush =>
          familiar ? '빗질을 받으며 편안하게 눈을 감아요.' : '살살 빗어 주니 털이 정돈되었어요.',
        _ => '나란히 앉아 잠깐 쉬어요. 오늘은 이만큼이어도 괜찮아요.',
      };
      if ({
        CompanionMoment.pet,
        CompanionMoment.brush,
        CompanionMoment.rest,
      }.contains(action)) {
        unawaited(SoundService().playPurr().catchError((Object _) {}));
      }
      setState(() {
        _action = action;
        _line =
            '$reaction\n${care.journey.activeGrowthDays > before ? '함께 돌본 날이 하루 쌓였어요.' : '오늘의 돌봄은 이미 기억했어요. 더 함께 있어도 좋아요.'}';
      });
      if (!_reduceMotion && _foreground) {
        _response.forward(from: 0);
      } else {
        _response.value = 1;
      }
    } catch (_) {
      if (mounted) setState(() => _error = '돌봄을 저장하지 못했어요. 다시 눌러 주세요.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _keepBaby(bool value) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await context.read<CatCareProvider>().keepBabyAppearance(value);
    } catch (_) {
      if (mounted) setState(() => _error = '모습 설정을 저장하지 못했어요. 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _setAutomatic(bool value) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await context.read<CatCareProvider>().setAutomaticBehavior(value);
    } catch (_) {
      if (mounted) setState(() => _error = '움직임 설정을 저장하지 못했어요. 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  static const _memoryLabels = {
    CompanionMoment.feed: '처음 밥을 챙겨 준 날',
    CompanionMoment.play: '처음 함께 장난감으로 논 날',
    CompanionMoment.pet: '처음 쓰다듬은 날',
    CompanionMoment.brush: '처음 빗질한 날',
    CompanionMoment.rest: '처음 나란히 쉰 날',
    CompanionMoment.care: '몸과 마음을 돌본 첫날',
    CompanionMoment.letter: '함께 마음을 기록한 첫날',
    CompanionMoment.meditation: '함께 명상한 첫날',
    CompanionMoment.plant: '함께 식물을 심은 첫날',
    CompanionMoment.water: '함께 물을 준 첫날',
    CompanionMoment.garden: '거름과 햇볕으로 정원을 돌본 첫날',
  };

  @override
  Widget build(BuildContext context) {
    final care = context.watch<CatCareProvider>();
    final journey = care.journey;
    final memories = journey.firstMoments.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                care.displayName,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            IconButton(
              tooltip: '고양이 이름 변경',
              onPressed: () => editCompanionName(context),
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
        ),
        const CompanionCoatButton(),
        Text(
          '${journey.stageLabel} · ${journey.bondLabel}',
          style: TextStyle(color: muted),
        ),
        Semantics(
          label:
              '${care.displayName}, ${journey.keepBaby ? '아기 모습 유지' : journey.stageLabel}',
          button: true,
          child: GestureDetector(
            key: const Key('companion-portrait'),
            onTap: _saving || !care.journeyReady
                ? null
                : () => _care(CompanionMoment.pet),
            child: SizedBox(
              height: 188,
              child: AnimatedBuilder(
                animation: _response,
                builder: (context, _) {
                  final active = _response.isAnimating && !_reduceMotion;
                  final wave = active
                      ? math.sin(_response.value * math.pi * 4)
                      : 0.0;
                  final size = 176 * journey.visualScale;
                  return Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Positioned(
                        bottom: 0,
                        width: size,
                        height: size,
                        child: Stack(
                          children: [
                            const Positioned.fill(
                              child: CustomPaint(
                                painter: GardenCatShadowPainter(
                                  walking: false,
                                  faceLeft: false,
                                  night: false,
                                  lift: 0,
                                ),
                              ),
                            ),
                            Transform.scale(
                              alignment: Alignment.bottomCenter,
                              scaleY: 1,
                              child: GardenCatPose(
                                walking: false,
                                frame: 0,
                                child: CompanionPresence(
                                  enabled:
                                      care.journeyReady &&
                                      journey.automaticBehavior,
                                  bondStage: journey.stage,
                                  interaction: active
                                      ? switch (_action) {
                                          CompanionMoment.feed =>
                                            CompanionInteraction.eating,
                                          CompanionMoment.play =>
                                            CompanionInteraction.playing,
                                          CompanionMoment.pet ||
                                          CompanionMoment.brush =>
                                            CompanionInteraction.petting,
                                          _ => CompanionInteraction.resting,
                                        }
                                      : null,
                                  interactionProgress: _response.value,
                                  resting:
                                      _action != null &&
                                      _action != CompanionMoment.feed &&
                                      _action != CompanionMoment.play &&
                                      _reduceMotion,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if ({
                            CompanionMoment.feed,
                            CompanionMoment.play,
                          }.contains(_action) &&
                          (active || _reduceMotion))
                        Align(
                          alignment: Alignment(
                            _action == CompanionMoment.play ? wave * .6 : 0,
                            1,
                          ),
                          child: SizedBox(
                            width: 52,
                            height: 38,
                            child: CustomPaint(
                              key: const Key('companion-care-prop'),
                              painter: _CarePropPainter(
                                feeding: _action == CompanionMoment.feed,
                                progress: _response.value,
                              ),
                            ),
                          ),
                        ),
                      if (_action != null &&
                          _action != CompanionMoment.feed &&
                          _action != CompanionMoment.play &&
                          (active || _reduceMotion))
                        Positioned(
                          top: 24,
                          right:
                              32 +
                              (active && _action == CompanionMoment.brush
                                  ? wave * 8
                                  : 0),
                          child: Icon(
                            _action == CompanionMoment.brush
                                ? Icons.brush_outlined
                                : _action == CompanionMoment.rest
                                ? Icons.spa_outlined
                                : Icons.favorite,
                            color: const Color(0xFFAD7C67),
                            size: 26,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Semantics(
          liveRegion: true,
          child: Text(
            _error ??
                care.journeyError ??
                _line ??
                (widget.invitation != null
                    ? journey.didToday(widget.invitation!, DateTime.now())
                          ? '오늘도 함께해 줘서 고마워. 편하게 쉬어 가.'
                          : CompanionInvitation.message(widget.invitation!)
                    : '밥을 챙겨 주거나, 장난감으로 놀고, 손길을 건네 보세요.'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _error != null
                  ? Theme.of(context).colorScheme.error
                  : muted,
            ),
          ),
        ),
        if (!care.journeyReady)
          TextButton(
            onPressed: care.loadJourney,
            child: const Text('함께한 기록 불러오기'),
          ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final entry in const {
              CompanionMoment.feed: '밥 주기',
              CompanionMoment.play: '놀아주기',
              CompanionMoment.pet: '쓰다듬기',
              CompanionMoment.brush: '빗질하기',
              CompanionMoment.rest: '같이 쉬기',
            }.entries)
              OutlinedButton(
                key: ValueKey('companion-${entry.key.name}'),
                style: widget.invitation == entry.key
                    ? OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFFE6EEE1),
                      )
                    : null,
                onPressed: _saving || !care.journeyReady
                    ? null
                    : () => _care(entry.key),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (journey.didToday(entry.key, DateTime.now())) ...[
                      const Icon(Icons.check, size: 16),
                      const SizedBox(width: 4),
                    ],
                    Text(entry.value),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          '함께 돌본 ${journey.activeGrowthDays}일',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: journey.progress,
          semanticsLabel: '다음 성장까지 진행',
          minHeight: 6,
          borderRadius: BorderRadius.circular(8),
        ),
        const SizedBox(height: 8),
        Text(
          journey.daysToNext == null
              ? '성장은 다 자라도, 함께한 기억은 계속 쌓여요.'
              : '돌본 날이 ${journey.daysToNext}일 더 쌓이면 다음 모습이 돼요.',
        ),
        const SizedBox(height: 6),
        Text(
          '돌봄·기록·명상·정원 가꾸기 중 한 가지만 해도 하루가 쌓여요. 쉬는 날에도 줄어들지 않아요.',
          style: TextStyle(fontSize: 12, color: muted),
        ),
        SwitchListTile.adaptive(
          key: const Key('companion-automatic'),
          contentPadding: EdgeInsets.zero,
          title: const Text('고양이의 작은 움직임'),
          subtitle: const Text('홈에서 눈을 깜박이며 반겨줘요. 정원 배경 효과와 별도로 설정해요.'),
          value: journey.automaticBehavior,
          onChanged: _saving || !care.journeyReady ? null : _setAutomatic,
        ),
        SwitchListTile.adaptive(
          key: const Key('companion-keep-baby'),
          contentPadding: EdgeInsets.zero,
          title: const Text('아기 모습으로 함께하기'),
          subtitle: const Text('모습을 유지해도 함께한 날과 기억은 쌓여요.'),
          value: journey.keepBaby,
          onChanged: _saving || !care.journeyReady ? null : _keepBaby,
        ),
        const CompanionReminderSettingsTile(),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Text('우리의 작은 기억'),
          subtitle: Text(
            memories.isEmpty
                ? '오늘의 첫 손길부터 담아 둘게요.'
                : '${memories.length}개의 첫 순간',
          ),
          children: [
            if (journey.previousCareDays > 0)
              ListTile(
                title: Text('이전 돌봄 ${journey.previousCareDays}일도 이어받았어요.'),
                subtitle: const Text('이전 기록의 정확한 날짜는 새로 만들지 않아요.'),
              ),
            for (final milestone in journey.milestones.entries)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.auto_awesome_outlined),
                title: Text('함께 돌본 ${milestone.key}일'),
                subtitle: Text(milestone.value),
              ),
            for (final memory in memories)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.pets_outlined),
                title: Text(_memoryLabels[memory.key]!),
                subtitle: Text(memory.value),
              ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                '이 기억은 나만 볼 수 있어요. 기기를 바꿀 때는 기록 백업·복원으로 옮겨 주세요.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Small, original vector props. The cat and contact shadow stay grounded.
class _CarePropPainter extends CustomPainter {
  final bool feeding;
  final double progress;
  const _CarePropPainter({required this.feeding, required this.progress});
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w / 2, h - 3),
        width: feeding ? w * .9 : w * .6,
        height: 5,
      ),
      Paint()..color = const Color(0x182D3929),
    );
    if (feeding) {
      final bowl = Path()
        ..moveTo(3, h * .38)
        ..lineTo(w - 3, h * .38)
        ..quadraticBezierTo(w - 6, h - 3, w * .7, h - 3)
        ..lineTo(w * .3, h - 3)
        ..quadraticBezierTo(6, h - 3, 3, h * .38);
      canvas.drawPath(bowl, Paint()..color = const Color(0xFFDCAB8C));
      canvas.drawOval(
        Rect.fromLTWH(3, h * .2, w - 6, h * .32),
        Paint()..color = const Color(0xFF94664D),
      );
      for (var i = 0; i < 7; i++) {
        if (i / 9 > 1 - progress * .7) continue;
        canvas.drawCircle(
          Offset(w * (.25 + (i % 4) * .16), h * (.29 + (i ~/ 4) * .11)),
          2.8,
          Paint()..color = const Color(0xFFEBCB91),
        );
      }
      canvas.drawOval(
        Rect.fromCenter(center: Offset(w / 2, h * .73), width: 8, height: 6),
        Paint()..color = const Color(0xFFF6E8D7),
      );
    } else {
      final center = Offset(w / 2, h / 2 + 2);
      canvas.drawCircle(center, 15, Paint()..color = const Color(0xFFA8BEA0));
      final paint = Paint()
        ..color = const Color(0xFF718C69)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      for (var i = -1; i <= 1; i++) {
        canvas.drawArc(
          Rect.fromCenter(
            center: center + Offset(i * 4, 0),
            width: 16,
            height: 27,
          ),
          -.9,
          2.3,
          false,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CarePropPainter old) =>
      old.feeding != feeding || old.progress != progress;
}
