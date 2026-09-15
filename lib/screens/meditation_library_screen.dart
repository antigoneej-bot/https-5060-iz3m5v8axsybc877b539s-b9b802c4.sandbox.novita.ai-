import '../widgets/meditation_courses_card.dart';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../data/solutions_data.dart';
import '../widgets/guide_steps.dart';
import '../widgets/meditation_favorite.dart';
import '../services/meditation_library_store.dart';

class MeditationLibraryScreen extends StatefulWidget {
  const MeditationLibraryScreen({super.key});
  @override
  State<MeditationLibraryScreen> createState() =>
      _MeditationLibraryScreenState();
}

class _MeditationLibraryScreenState extends State<MeditationLibraryScreen> {
  final store = MeditationLibraryStore.instance;
  String _duration = 'all', _voice = 'all', _shelf = 'all';
  String? _error;
  @override
  void initState() {
    super.initState();
    store.load().catchError((Object _) {
      if (mounted) setState(() => _error = '저장된 목록을 불러오지 못했어요.');
    });
  }

  Widget chips(
    Map<String, String> values,
    String selected,
    ValueChanged<String> change,
  ) => Wrap(
    spacing: 6,
    runSpacing: 4,
    children: values.entries
        .map(
          (e) => ChoiceChip(
            label: Text(e.value),
            selected: e.key == selected,
            selectedColor: AppColors.blobMint,
            onSelected: (_) => setState(() => change(e.key)),
          ),
        )
        .toList(),
  );
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: store,
    builder: (context, _) {
      final keys =
          (_shelf == 'recent' ? store.recent : publishedMeditationKeys.toList())
              .where((key) {
                final media = meditationMedia[key]!;
                return (_shelf != 'favorites' ||
                        store.favorites.contains(key)) &&
                    (_voice == 'all' ||
                        (_voice == 'voice') == media.hasVoice) &&
                    (_duration == 'all' ||
                        (_duration == 'short' && media.seconds <= 180) ||
                        (_duration == 'five' &&
                            media.seconds > 180 &&
                            media.seconds <= 300) ||
                        (_duration == 'long' && media.seconds > 300));
              })
              .toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '오디오 · 영상 명상',
            textAlign: TextAlign.center,
            style: titleFont(fontSize: 24, color: AppColors.titlePastelGreen),
          ),
          const MeditationCoursesCard(),
          const SizedBox(height: 12),
          chips(
            const {'all': '전체', 'favorites': '즐겨찾기', 'recent': '최근 들은 명상'},
            _shelf,
            (v) => _shelf = v,
          ),
          const SizedBox(height: 8),
          chips(
            const {
              'all': '모든 시간',
              'short': '3분 이내',
              'five': '3~5분',
              'long': '길게 쉬기',
            },
            _duration,
            (v) => _duration = v,
          ),
          const SizedBox(height: 8),
          chips(
            const {'all': '모든 방식', 'voice': '목소리 있음', 'silent': '목소리 없음'},
            _voice,
            (v) => _voice = v,
          ),
          if (_error != null) Text(_error!),
          const SizedBox(height: 14),
          Text(
            '${keys.length}개의 명상',
            style: bodyFont(fontSize: 12, color: AppColors.inkSoft),
          ),
          if (keys.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('해당하는 명상이 없어요. 필터를 바꾸거나 마음에 드는 명상을 즐겨찾기에 담아보세요.'),
            ),
          for (final key in keys)
            Container(
              key: ValueKey(key),
              margin: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                color: meditationMedia[key]!.hasVoice
                    ? AppColors.catLavenderBg
                    : AppColors.catSageBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.sageLine.withValues(alpha: .6),
                ),
              ),
              child: ExpansionTile(
                key: PageStorageKey('meditation-$key'),
                title: Text(
                  '${breathingGuide[key]!.icon} ${breathingGuide[key]!.title}',
                  style: bodyFont(
                    fontSize: 14,
                    color: AppColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meditationMedia[key]!.label,
                      style: bodyFont(fontSize: 13, color: AppColors.inkSoft),
                    ),
                    MeditationFavorite(guideKey: key),
                  ],
                ),
                children: [
                  GuideSteps(guide: breathingGuide[key]!, guideKey: key),
                ],
              ),
            ),
        ],
      );
    },
  );
}
