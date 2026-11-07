import '../l10n/app_language.dart';
import '../widgets/healing_activities.dart';
import 'cat_walk_screen.dart';
import 'keepsake_forest_screen.dart';
import '../widgets/garden_path_card.dart';
import '../widgets/stars_background.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../widgets/feature_scaffold.dart';
import '../theme.dart';
import 'my_garden_screen.dart';
import 'heart_letters_screen.dart';
import 'daily_card_screen.dart';
import 'pet_care_screen.dart';
import 'subscriber_journeys_screen.dart';
import 'cat_achievements_screen.dart';
import 'cat_shop_screen.dart';
import 'memory_cards_screen.dart';
import '../mongi/screens/growth_milestone_screen.dart';
import 'self_care_screen.dart';
import 'todays_promise_screen.dart';
import 'day_close_screen.dart';
import 'bubble_garden_screen.dart';
import 'emotion_statistics_screen.dart';
import 'emotion_archive_screen.dart';
import '../mongi/screens/diary_screen.dart';
import 'garden_memory_book_screen.dart';
import 'care_journal_screen.dart';
import '../mongi/screens/garden_village_screen.dart';
import 'cat_bond_screen.dart';
import 'notice_list_screen.dart';
import 'garden_updates_screen.dart';
import 'data_safety_screen.dart';
import 'account_screen.dart';
import 'premium_screen.dart';
import 'app_tutorial_screen.dart';

void openAllFeatures(BuildContext context) => Navigator.of(
  context,
).push<void>(MaterialPageRoute<void>(builder: (_) => AllFeaturesScreen()));

class AllFeaturesScreen extends StatefulWidget {
  const AllFeaturesScreen({super.key});
  @override
  State<AllFeaturesScreen> createState() => _AllFeaturesScreenState();
}

class _Feature {
  final String title, description, category;
  final WidgetBuilder? builder;
  final int? tab;
  const _Feature(
    this.title,
    this.description,
    this.category, {
    this.builder,
    this.tab,
  });
}

class _AllFeaturesScreenState extends State<AllFeaturesScreen> {
  final _search = TextEditingController();
  String _query = '';
  String? _category;
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _goToTab(int tab) {
    context.read<AppStateProvider>().requestHomeTab(tab);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  List<_Feature> get _features => [
    _Feature(
      tr("마음냥 산책"),
      tr('동반 고양이와 꽃길을 걷고 숨은 보물·간식을 찾아요. 산책 주머니는 체험용이에요.'),
      tr("명상·힐링"),
      builder: (_) => CatWalkScreen(),
    ),
    _Feature(
      tr('감정 고양이 만나기'),
      tr('감정 검색·전체 고양이·별표 즐겨찾기로 오늘의 마음을 골라요.'),
      tr('감정과 편지'),
      tab: 1,
    ),
    _Feature(
      tr('마음편지'),
      tr('감사·용서·미안함·사랑을 개인 기록으로 남겨요. 지난 편지도 다시 볼 수 있어요.'),
      tr('감정과 편지'),
      builder: (_) =>
          FeatureScaffold(title: tr('마음편지'), child: HeartLettersScreen()),
    ),
    _Feature(
      tr('오늘의 고양이 카드'),
      tr('카드를 골라 오늘의 메시지를 만나보세요.'),
      tr('감정과 편지'),
      builder: (_) =>
          FeatureScaffold(title: tr('오늘의 고양이 카드'), child: DailyCardScreen()),
    ),
    _Feature(
      tr('함께하는 고양이 돌보기'),
      tr('밥·물·목욕과 일상 돌봄을 함께해요.'),
      tr("고양이 돌보기"),
      builder: (_) =>
          FeatureScaffold(title: tr('함께하는 고양이 돌보기'), child: PetCareScreen()),
    ),
    _Feature(
      tr("고양이와 함께하는 여정"),
      tr('고양이와 함께하는 활동을 살펴봐요.'),
      tr("고양이 돌보기"),
      builder: (_) => SubscriberJourneysScreen(),
    ),
    _Feature(
      tr('뱃지 컬렉션'),
      tr('돌봄으로 쌓아온 성취와 조건을 확인해요.'),
      tr("고양이 돌보기"),
      builder: (_) =>
          FeatureScaffold(title: tr('뱃지 컬렉션'), child: CatAchievementsScreen()),
    ),
    _Feature(
      tr('돌봄 포인트 상점'),
      tr('돌봄 포인트로 아이템·액세서리·가구를 골라요. 빛의 정수와는 별개예요.'),
      tr("고양이 돌보기"),
      builder: (_) =>
          FeatureScaffold(title: tr('돌봄 포인트 상점'), child: CatShopScreen()),
    ),
    _Feature(
      tr('나의 넓은 정원'),
      tr('씨앗·식물·장식과 정원 도구를 한곳에서 만나요.'),
      tr('정원 가꾸기'),
      builder: (_) => MyGardenScreen(onGoMeetCat: () => _goToTab(1)),
    ),
    _Feature(
      tr('함께한 고양이 도감'),
      tr('만난 고양이와 만남 횟수를 확인해요. 회색 실루엣은 아직 만나지 않은 고양이예요.'),
      tr('정원 가꾸기'),
      builder: (_) => FeatureScaffold(
        title: tr('함께한 고양이 도감'),
        child: MyGardenScreen(
          onGoMeetCat: () => _goToTab(1),
          showMongiPanel: false,
        ),
      ),
    ),
    _Feature(
      tr("기억의 나무"),
      tr('사랑·용서·평화의 씨앗에 날짜와 이야기를 적고 키워요.'),
      tr('정원 가꾸기'),
      builder: (_) => KeepsakeForestScreen(),
    ),
    _Feature(
      tr('추억 카드 수집·교환'),
      tr('특별한 카드를 모으고 이웃과 교환·진열해요.'),
      tr('정원 가꾸기'),
      builder: (_) => MemoryCardsScreen(),
    ),
    _Feature(
      tr('성장 마일스톤'),
      tr('정원의 성장 과정과 달성한 단계를 확인해요.'),
      tr('정원 가꾸기'),
      builder: (_) => GrowthMilestoneScreen(),
    ),
    _Feature(tr("명상·호흡·자연음"), tr('호흡·명상과 자연음을 한곳에서 골라요.'), tr("명상·힐링"), tab: 2),
    _Feature(
      tr('마음 돌봄 기록'),
      tr('일상에서 나를 돌본 활동을 기록하고 돌아봐요.'),
      tr('마음돌보기'),
      builder: (_) => SelfCareScreen(),
    ),
    _Feature(
      tr('오늘의 작은 약속'),
      tr('나에게 할 수 있는 작은 약속을 남기고 완료해요.'),
      tr('하루 루틴'),
      builder: (_) =>
          FeatureScaffold(title: tr('오늘의 작은 약속'), child: TodaysPromiseScreen()),
    ),
    _Feature(
      tr("하루 닫기"),
      tr('하루를 돌아보고 마음을 정리해요.'),
      tr("명상·힐링"),
      builder: (_) =>
          FeatureScaffold(title: tr("하루 닫기"), child: DayCloseScreen()),
    ),
    _Feature(
      tr('마음 버블 정원'),
      tr('마음을 버블에 남기고 묻어둔 마음을 다시 살펴봐요.'),
      tr("명상·힐링"),
      builder: (_) =>
          FeatureScaffold(title: tr('마음 버블 정원'), child: BubbleGardenScreen()),
    ),
    _Feature(
      tr('고요하게 마음 마주하기'),
      tr('감정을 고르고 숨을 고르거나 한 줄을 남겨요.'),
      tr("명상·힐링"),
      builder: (_) => HealingGardenEntry(activity: HealingActivity.quiet),
    ),
    _Feature(
      tr('혼자 읽는 응원 모음'),
      tr('앱에 준비된 위로와 응원 문구를 읽어요.'),
      tr("명상·힐링"),
      builder: (_) =>
          HealingGardenEntry(activity: HealingActivity.encouragement),
    ),
    _Feature(
      tr('감사 한 줄 · 작은 성취'),
      tr('오늘 감사한 일이나 작은 성취를 남겨요.'),
      tr("명상·힐링"),
      builder: (_) => HealingGardenEntry(activity: HealingActivity.gratitude),
    ),
    _Feature(
      tr('지난 마음 기록'),
      tr('기록 탭에서 남긴 마음과 편지를 다시 읽어요.'),
      tr('기록과 돌아보기'),
      tab: 3,
    ),
    _Feature(
      tr("감정 통계"),
      tr('주간·월간 통계·만화책과 마음 리포트를 살펴봐요.'),
      tr('기록과 돌아보기'),
      builder: (_) => EmotionStatisticsScreen(),
    ),
    _Feature(
      tr("감정 캘린더"),
      tr('날짜별로 기록한 감정을 확인해요.'),
      tr('기록과 돌아보기'),
      builder: (_) => EmotionArchiveScreen(),
    ),
    _Feature(
      tr('정원 마음 일기'),
      tr('정원에서 남긴 감정 일기를 다시 읽어요.'),
      tr('기록과 돌아보기'),
      builder: (_) => DiaryScreen(),
    ),
    _Feature(
      tr("정원 기록집"),
      tr('정원 모습과 내가 고른 문장을 월별로 간직해요.'),
      tr('나만의 보관함'),
      builder: (_) => GardenMemoryBookScreen(),
    ),
    _Feature(
      tr('나를 돌보는 방법'),
      tr('도움이 됐던 행동과 간직한 말을 다시 꺼내요.'),
      tr('나만의 보관함'),
      builder: (_) => CareJournalScreen(),
    ),
    _Feature(
      tr('냥이 마을'),
      tr('이웃 정원과 공개 정원 설정을 찾아가요.'),
      tr('이웃과 소식'),
      builder: (_) => GardenVillageScreen(),
    ),
    _Feature(
      tr('고양이 코드 비교'),
      tr('묘연 코드로 두 감정 고양이를 비교해요. 이웃 초대와는 별개예요.'),
      tr('감정과 편지'),
      builder: (_) => CatBondScreen(),
    ),
    _Feature(
      tr("정원 소식"),
      tr('운영자가 올린 공지와 소식을 확인해요.'),
      tr('이웃과 소식'),
      builder: (_) =>
          FeatureScaffold(title: tr("정원 소식"), child: NoticeListScreen()),
    ),
    _Feature(
      tr('예약 변경 소식'),
      tr('로그인한 계정의 예약 변경 사항을 확인해요.'),
      tr('이웃과 소식'),
      builder: (_) => GardenUpdatesScreen(),
    ),
    _Feature(
      tr("기록 보관·백업·잠금"),
      tr('백업 내보내기·복원과 기기 잠금을 관리해요.'),
      tr('설정과 데이터'),
      builder: (_) => DataSafetyScreen(),
    ),
    _Feature(
      tr('소리·알림 설정'),
      tr('마이의 설정에서 배경음악·효과음·음량·재생 복구와 돌봄 알림을 관리해요.'),
      tr('설정과 데이터'),
      tab: 4,
    ),
    _Feature(
      tr('계정 관리'),
      tr('로그인과 계정 상태를 확인해요.'),
      tr('설정과 데이터'),
      builder: (_) => AccountScreen(),
    ),
    _Feature(
      tr('구독 안내'),
      tr('프리미엄 제공 기능과 구매 복원을 확인해요.'),
      tr('사용 안내'),
      builder: (_) => PremiumScreen(),
    ),
    _Feature(
      tr("앱 사용법"),
      tr('기본 이용 흐름을 다시 살펴봐요.'),
      tr('사용 안내'),
      builder: (_) =>
          FeatureScaffold(title: tr("앱 사용법"), child: AppTutorialScreen()),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    final features = _features;
    final categories = features.map((f) => f.category).toSet();
    if (_category != null && !categories.contains(_category)) _category = null;
    final matches = features
        .where(
          (f) =>
              (_category == null || f.category == _category) &&
              '${f.title} ${f.description} ${f.category}'
                  .toLowerCase()
                  .contains(_query.toLowerCase()),
        )
        .toList();
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return TickerMode(
      enabled: !reducedMotion,
      child: Scaffold(
        backgroundColor: AppColors.bg0,
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFF7EF), Color(0xFFF5F1FF), Color(0xFFEDF8F2)],
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(child: StarsBackground()),
              SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 540),
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(22, 8, 22, 44),
                      children: [
                        Row(
                          children: [
                            IconButton(
                              tooltip: tr('뒤로'),
                              onPressed: () => Navigator.of(context).maybePop(),
                              icon: Icon(
                                Icons.arrow_back_rounded,
                                color: AppColors.titlePastelGreen,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                tr('전체 기능'),
                                style: titleFont(
                                  fontSize: 28,
                                  color: AppColors.titlePastelGreen,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.auto_awesome_rounded,
                              color: AppColors.blobLavenderAccent,
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        TextField(
                          controller: _search,
                          style: bodyFont(fontSize: 14, color: AppColors.ink),
                          decoration: InputDecoration(
                            labelText: tr('기능 검색'),
                            hintText: tr('즐겨찾기, 백업, 음악, 도감…'),
                            labelStyle: pathLabelFont(
                              fontSize: 19,
                              color: AppColors.lavenderInk,
                            ),
                            hintStyle: bodyFont(
                              fontSize: 12.5,
                              color: AppColors.inkSoft,
                            ),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: .78),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: AppColors.lavenderInk,
                            ),
                            suffixIcon: IconButton(
                              tooltip: tr("검색 지우기"),
                              icon: Icon(Icons.close_rounded),
                              onPressed: () {
                                _search.clear();
                                setState(() => _query = '');
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(28),
                              borderSide: BorderSide(
                                color: AppColors.blobLavenderAccent,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(28),
                              borderSide: BorderSide(color: Color(0xFFD9CDEA)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(28),
                              borderSide: BorderSide(
                                color: AppColors.lavenderInk,
                                width: 1.5,
                              ),
                            ),
                          ),
                          onChanged: (value) =>
                              setState(() => _query = value.trim()),
                        ),
                        SizedBox(height: 18),
                        Wrap(
                          spacing: 8,
                          runSpacing: 10,
                          children: [
                            _categoryChip(tr('모두'), null, _directoryColors[2]),
                            for (final category in categories)
                              _categoryChip(
                                category,
                                category,
                                _directoryColors[categories.toList().indexOf(
                                      category,
                                    ) %
                                    _directoryColors.length],
                              ),
                          ],
                        ),
                        SizedBox(height: 18),
                        ExpansionTile(
                          key: PageStorageKey('directory-tips'),
                          shape: RoundedRectangleBorder(side: BorderSide.none),
                          collapsedShape: RoundedRectangleBorder(
                            side: BorderSide.none,
                          ),
                          leading: Icon(
                            Icons.lightbulb_outline_rounded,
                            color: AppColors.goldSoft,
                          ),
                          title: Text(
                            tr('살짝 알려드릴게요'),
                            style: pathLabelFont(
                              fontSize: 20,
                              color: AppColors.moon,
                            ),
                          ),
                          childrenPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                          children: [
                            Text(
                              tr(
                                '감정 고양이의 별표는 즐겨찾기예요. 마음편지는 상대에게 전송되지 않는 개인 기록이에요. 일부 기능은 구독·로그인 또는 쌓인 기록이 필요해요.',
                              ),
                              style: bodyFont(
                                fontSize: 13,
                                color: AppColors.inkSoft,
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            tr("{0}개 기능", [matches.length]),
                            style: pathLabelFont(
                              fontSize: 18,
                              color: AppColors.inkSoft,
                            ),
                          ),
                        ),
                        if (matches.isEmpty)
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: GlassBlob(
                              accent: AppColors.blobLavenderAccent,
                              background: AppColors.blobLavender,
                              child: Text(
                                tr('찾는 기능이 없어요. 검색어를 바꾸거나 ‘모두’를 눌러보세요.'),
                                style: bodyFont(
                                  fontSize: 14,
                                  color: AppColors.lavenderInk,
                                ),
                              ),
                            ),
                          ),
                        for (final category in categories)
                          if (matches.any((f) => f.category == category)) ...[
                            Padding(
                              padding: EdgeInsets.only(top: 26, bottom: 18),
                              child: Text(
                                category,
                                style: titleFont(
                                  fontSize: 27,
                                  color:
                                      _directoryColors[categories
                                                  .toList()
                                                  .indexOf(category) %
                                              _directoryColors.length]
                                          .ink,
                                ),
                              ),
                            ),
                            for (final feature in matches.where(
                              (f) => f.category == category,
                            ))
                              Padding(
                                padding: EdgeInsets.only(bottom: 20),
                                child: Semantics(
                                  button: true,
                                  child: GardenPathCard(
                                    key: ValueKey(feature.title),
                                    emoji:
                                        _directoryColors[categories
                                                    .toList()
                                                    .indexOf(category) %
                                                _directoryColors.length]
                                            .emoji,
                                    icon:
                                        _directoryColors[categories
                                                    .toList()
                                                    .indexOf(category) %
                                                _directoryColors.length]
                                            .icon,
                                    title: feature.title,
                                    subtitle: feature.description,
                                    titleSize: 22,
                                    subtitleSize: 13,
                                    accent:
                                        _directoryColors[categories
                                                    .toList()
                                                    .indexOf(category) %
                                                _directoryColors.length]
                                            .ink,
                                    background: Color.lerp(
                                      _directoryColors[categories
                                                  .toList()
                                                  .indexOf(category) %
                                              _directoryColors.length]
                                          .background,
                                      Colors.white,
                                      (features.indexOf(feature) % 3) * .08,
                                    )!,
                                    alignX: features.indexOf(feature).isEven
                                        ? -.45
                                        : .45,
                                    widthFactor:
                                        MediaQuery.textScalerOf(
                                              context,
                                            ).scale(14) >
                                            21
                                        ? 1
                                        : .96,
                                    floatSeed: features.indexOf(feature) + 11,
                                    onTap: () {
                                      if (feature.tab != null) {
                                        _goToTab(feature.tab!);
                                      } else {
                                        Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: feature.builder!,
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ),
                          ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryChip(String label, String? value, _DirectoryColor color) {
    final selected = _category == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      labelStyle: pathLabelFont(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: color.ink,
      ),
      backgroundColor: color.background.withValues(alpha: .75),
      selectedColor: color.background,
      checkmarkColor: color.ink,
      side: BorderSide(
        color: selected ? color.ink : color.ink.withValues(alpha: .22),
        width: selected ? 1.5 : 1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(selected ? 19 : 25),
      ),
      padding: EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      onSelected: (selected) =>
          setState(() => _category = selected ? value : null),
    );
  }
}

class _DirectoryColor {
  final Color background, ink;
  final String emoji;
  final IconData icon;
  const _DirectoryColor(this.background, this.ink, this.emoji, this.icon);
}

final _directoryColors = [
  const _DirectoryColor(
    Color(0xFFF8D1E1),
    Color(0xFF914B6B),
    '💌',
    Icons.favorite_rounded,
  ),
  const _DirectoryColor(
    Color(0xFFFFDFC7),
    Color(0xFF945C36),
    '🐾',
    Icons.pets_rounded,
  ),
  const _DirectoryColor(
    Color(0xFFCBEADB),
    Color(0xFF42785B),
    '🌱',
    Icons.local_florist_rounded,
  ),
  const _DirectoryColor(
    Color(0xFFDED3F6),
    Color(0xFF735993),
    '☁️',
    Icons.cloud_rounded,
  ),
  const _DirectoryColor(
    Color(0xFFFFEAB7),
    Color(0xFF896724),
    '☀️',
    Icons.wb_sunny_rounded,
  ),
  const _DirectoryColor(
    Color(0xFFCEE8F8),
    Color(0xFF436E8B),
    '📖',
    Icons.auto_stories_rounded,
  ),
  const _DirectoryColor(
    Color(0xFFF5D6F0),
    Color(0xFF85527F),
    '🎀',
    Icons.inventory_2_rounded,
  ),
  const _DirectoryColor(
    Color(0xFFDDEBC6),
    Color(0xFF637841),
    '🏡',
    Icons.home_rounded,
  ),
  const _DirectoryColor(
    Color(0xFFD9DFF7),
    Color(0xFF58648B),
    '🫧',
    Icons.tune_rounded,
  ),
  const _DirectoryColor(
    Color(0xFFF9D7CB),
    Color(0xFF965B4B),
    '✨',
    Icons.auto_awesome_rounded,
  ),
];

class FeatureDirectoryEntry extends StatelessWidget {
  const FeatureDirectoryEntry({super.key});
  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    return TickerMode(
      enabled: !MediaQuery.disableAnimationsOf(context),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: GardenPathCard(
          emoji: '🌈',
          icon: Icons.auto_awesome_rounded,
          title: tr('전체 기능'),
          subtitle: tr('정원 곳곳의 작은 즐거움을 찾아보세요'),
          titleSize: 23,
          subtitleSize: 13,
          accent: Color(0xFF735993),
          background: Color(0xFFDED3F6),
          widthFactor: .98,
          floatSeed: 23,
          onTap: () => openAllFeatures(context),
        ),
      ),
    );
  }
}
