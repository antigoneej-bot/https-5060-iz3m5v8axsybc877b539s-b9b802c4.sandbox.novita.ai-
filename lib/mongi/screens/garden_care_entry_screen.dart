import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme.dart' show AppColors;
import '../l10n/emotion_l10n.dart';
import '../l10n/gen/app_localizations.dart';
import '../models/emotion.dart';
import '../providers/garden_provider.dart';
import '../widgets/daily_checkin_sheet.dart';
import 'breathing_library_screen.dart';
import 'mind_challenge_list_screen.dart';
import 'mongi_cheer_screen.dart';
import 'mongi_letter_screen.dart';
import 'quiet_mode_screen.dart';

/// Optional care activities remain accessible after the runner is separated.
/// These routes use the existing garden records and never start a game.
class GardenCareEntryScreen extends StatefulWidget {
  const GardenCareEntryScreen({super.key});

  @override
  State<GardenCareEntryScreen> createState() => _GardenCareEntryScreenState();
}

class _GardenCareEntryScreenState extends State<GardenCareEntryScreen> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final garden = context.read<GardenProvider>();
      if (!garden.isInitialized) await garden.ensureInitialized();
      if (!mounted) return;
      await action();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('돌봄 기록을 불러오지 못했어요. 다시 시도해 주세요.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _open(Widget screen) async {
    await Navigator.of(
      context,
    ).push<void>(MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _openQuietMode() async {
    final emotion = await showModalBottomSheet<Emotion>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _QuietEmotionSheet(),
    );
    if (emotion == null || !mounted) return;
    await _open(QuietModeScreen(emotions: [emotion]));
  }

  @override
  Widget build(BuildContext context) {
    final garden = context.watch<GardenProvider>();
    final l10n = AppLocalizations.of(context);
    final checkedEmotion = garden.todayCheckInEmotionName;
    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(title: const Text('마음 돌보기')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 0, 4, 16),
            child: Text(
              '정원에서 잠깐 쉬어가요. 지금 필요한 것 하나만 골라도 괜찮아요.',
              style: TextStyle(color: AppColors.inkSoft, height: 1.5),
            ),
          ),
          _tile(
            key: 'garden-care-checkin',
            icon: Icons.favorite_border,
            title: garden.hasCheckedInToday ? '오늘의 마음을 살펴봤어요' : '오늘의 마음 체크인',
            subtitle: garden.hasCheckedInToday
                ? checkedEmotion == null
                      ? '오늘 남긴 마음은 감정 캘린더에서 다시 볼 수 있어요.'
                      : '오늘 고른 마음: ${emotionLabel(l10n, Emotion.byTypeName(checkedEmotion).type)}'
                : '감정 하나를 골라 오늘의 마음을 남겨요.',
            onTap: garden.hasCheckedInToday
                ? null
                : () => _run(() async {
                    await DailyCheckInSheet.showIfNeeded(context);
                  }),
          ),
          _tile(
            key: 'garden-care-quiet',
            icon: Icons.spa_outlined,
            title: '고요하게 마음 마주하기',
            subtitle: '감정 하나를 고르고, 숨을 고르거나 한 줄을 남겨요.',
            onTap: () => _run(_openQuietMode),
          ),
          _tile(
            key: 'garden-care-breathing',
            icon: Icons.air,
            title: '짧은 호흡 가이드',
            subtitle: '불안할 때, 쉬고 싶을 때 필요한 호흡을 골라요.',
            onTap: () => _run(() => _open(const BreathingLibraryScreen())),
          ),
          _tile(
            key: 'garden-care-challenge',
            icon: Icons.eco_outlined,
            title: '작은 실천 이어가기',
            subtitle: '마음 챌린지를 고르고 오늘의 체크인으로 이어가요.',
            onTap: () => _run(() => _open(const MindChallengeListScreen())),
          ),
          _tile(
            key: 'garden-care-letter',
            icon: Icons.mail_outline,
            title: '한 주를 돌아보는 편지',
            subtitle: '정원에 남긴 감정 기록을 고양이와 함께 돌아봐요.',
            onTap: () => _run(() => _open(const MongiLetterScreen())),
          ),
          _tile(
            key: 'garden-care-comfort',
            icon: Icons.chat_bubble_outline,
            title: '혼자 읽는 응원 모음',
            subtitle: '앱에 준비된 위로 문구예요. 이웃이 보낸 메시지와는 별개예요.',
            onTap: () => _run(() => _open(const MongiCheerScreen())),
          ),
        ],
      ),
    );
  }

  Widget _tile({
    required String key,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      key: ValueKey(key),
      leading: Icon(icon, color: AppColors.catSage),
      title: Text(title),
      subtitle: Text(subtitle),
      isThreeLine: true,
      trailing: onTap == null
          ? const Icon(Icons.check, color: AppColors.catSage)
          : const Icon(Icons.chevron_right),
      onTap: _busy ? null : onTap,
    ),
  );
}

/// Selecting an emotion here is temporary. QuietModeScreen saves only when
/// the user chooses to finish their reflection; closing this sheet writes none.
class _QuietEmotionSheet extends StatefulWidget {
  const _QuietEmotionSheet();

  @override
  State<_QuietEmotionSheet> createState() => _QuietEmotionSheetState();
}

class _QuietEmotionSheetState extends State<_QuietEmotionSheet> {
  Emotion? _selected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * .72,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      '지금 마음에 가까운 감정',
                      style: TextStyle(fontSize: 19),
                    ),
                  ),
                  IconButton(
                    tooltip: '닫기',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Text('하나만 골라 주세요. 어떤 감정이든 괜찮아요.'),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final emotion in Emotion.all)
                        ChoiceChip(
                          key: ValueKey('quiet-emotion-${emotion.type.name}'),
                          label: Text(
                            '${emotion.emoji} ${emotionLabel(l10n, emotion.type)}',
                          ),
                          selected: _selected?.type == emotion.type,
                          onSelected: (selected) => setState(
                            () => _selected = selected ? emotion : null,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                key: const ValueKey('quiet-emotion-continue'),
                onPressed: _selected == null
                    ? null
                    : () => Navigator.of(context).pop(_selected),
                child: const Text('이 마음과 잠깐 쉬기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
