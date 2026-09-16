import '../../services/subscription_service.dart';
import '../integration/session_transaction.dart';
import '../../services/hive_encryption.dart';
import '../integration/mongi_garden_store.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/season_pass.dart';

/// 정원 진행 상태를 로컬(Hive)에 저장/불러오는 서비스.
/// 복잡한 스키마 없이 key-value 형태로 단순하게 관리한다 (MVP 원칙: 단순함).
class GardenStorage {
  static const String _boxName = 'mongi_progress_local_user';

  static const String _keyProgress = 'garden_progress'; // double 0.0 ~ 1.0
  static const String _keyTotalFed = 'total_fed_count'; // int (누적)
  static const String _keyTodayFed = 'today_fed_count'; // int (오늘)
  static const String _keyLastDate = 'last_fed_date'; // String yyyy-MM-dd
  static const String _keyStreak = 'streak_days'; // int (연속 방문일)
  static const String _keyFlowerCounts =
      'flower_counts'; // Map<String,int> (감정 타입 이름 -> 심어진 꽃 개수, 누적)
  static const String _keyDiary =
      'diary_entries'; // List<Map> (하루 한 줄 감정 일기, 최신이 앞에 오는 순)
  static const int _maxDiaryEntries = 200;
  static const String _keyPremiumFrameInterest =
      'premium_frame_interest_count'; // int (프리미엄 카드 프레임 "출시 알림 받기" 클릭 누적 수 - 결제 붙이기 전 수요 검증용)
  static const String _keyHasSeenOnboarding =
      'has_seen_onboarding'; // bool (처음 실행 시 튜토리얼을 이미 봤는지)
  static const String _keyNotifEnabled =
      'notif_enabled'; // bool (매일 리마인더 알림 켜짐 여부)
  static const String _keyNotifHour = 'notif_hour'; // int 0~23 (알림 시각 - 시)
  static const String _keyNotifMinute = 'notif_minute'; // int 0~59 (알림 시각 - 분)
  static const String _keyLanguageCode =
      'language_code'; // String? ('ko'/'en', null이면 시스템 언어를 따라감)
  static const String _keyPremiumFramesUnlocked =
      'premium_frames_unlocked'; // bool (프리미엄 카드 프레임 팩 구매 여부 - 실제 결제 완료 시 true)
  static const String _keyHasBloomedOnce =
      'has_bloomed_once'; // bool (정원을 한 번이라도 100% 만개시켰는지 - 무료 장식 잠금 해제 조건)
  static const String _keyDecorationPackUnlocked =
      'decoration_pack_unlocked'; // bool (프리미엄 정원 장식팩 구매 여부 - 실제 결제 완료 시 true)
  static const String _keyScore =
      'garden_score'; // int (누적 점수 - 스테이지를 완료할 때마다 쌓여서 "몽이의 성장나무"를 자라게 한다)
  static const String _keyTreeMilestoneClaimed =
      'tree_milestone_claimed_stage'; // int (성장나무 단계별 마일스톤 보상을 마지막으로
  // 수령한 단계 인덱스, 기본값 -1 = 아직 하나도 수령하지 않음. 나무는 절대 단계가
  // 내려가지 않으므로, 이 값보다 높은 단계에 도달하면 그 사이 단계들의 보상을
  // 한 번에 지급하고 이 값을 갱신한다.)
  static const String _keyLastCheckInDate =
      'last_checkin_date'; // String yyyy-MM-dd (오늘의 감정 체크인을 마지막으로 한 날짜)
  static const String _keyLastCheckInEmotion =
      'last_checkin_emotion'; // String (EmotionType.name) - 오늘 체크인한 감정
  static const String _keyCheckInStreak =
      'checkin_streak_days'; // int (매일 감정 체크인을 연속으로 한 일수 - Finch식 습관 리텐션 지표)
  static const String _keyBestCheckInStreak =
      'best_checkin_streak_days'; // int (지금까지 세운 감정 체크인 연속일수 개인 최고 기록 - 스트릭
  // 가시성 강화(벤치마킹 제안 #4)를 위해 "지금 기록"과 항상 비교해서 보여준다)
  static const String _keyBestEndlessCount =
      'best_endless_count'; // int (엔드리스 모드 최고기록 - 한 판에서 먹은 감정 개수)
  static const String _keyBestEndlessSeconds =
      'best_endless_seconds'; // int (엔드리스 모드 최고기록 - 그 판에서 생존한 시간(초))
  static const String _keyHasSeenGrowthMilestone =
      'has_seen_growth_milestone'; // bool (몽이의 성장나무가 마지막 단계(열매)에 도달했을 때 보여주는
  // "성장 다큐멘터리" 엔딩 화면을 이미 한 번 봤는지 여부 - 처음 도달한 순간에만 자동으로 띄우기 위함)
  static const String _keyLastWeeklyReportDate =
      'last_weekly_report_date'; // String yyyy-MM-dd (주간 감정 리포트 카드를 마지막으로 확인한 날짜 -
  // 일주일에 한 번만 자동으로 띄우기 위한 플래그. 홈 화면 배지로는 언제든 다시 볼 수 있다)
  static const String _keyGoldenFrameEmotions =
      'golden_frame_emotions'; // List<String> (EmotionType.name) - 극저확률로 획득한
  // "황금 프레임" 감정 목록. 한 번 획득하면 영구적으로 유지된다(도감에서 SNS 자랑용 표시).
  static const String _keyTranscendedEmotions =
      'transcended_emotions'; // List<String> (EmotionType.name) - 6번: 100번째
  // 마주침에 도달해 히든 4단계("초월")로 진화한 감정 목록. 이미 이 목록에 있는
  // 감정은 결과 화면에서 "초월했어요!" 축하를 다시 보여주지 않기 위한 1회성
  // 발견 기록이다(도감 카드 자체는 flowerCounts만으로 항상 최신 진화 이름을
  // 보여주므로, 이 목록이 없어도 진화 표시 자체는 영향받지 않는다).
  static const String _keyLastEasterEggDate =
      'last_easter_egg_date'; // String yyyy-MM-dd (오늘 몽이의 이스터에그 대사를 이미
  // 뽑았는지 - 하루 한 번만 랜덤으로 뽑고, 같은 날 안에는 같은 대사를 유지한다)
  static const String _keyLastEasterEggLine =
      'last_easter_egg_line'; // String (오늘 뽑힌 이스터에그 대사 - 화면을 나갔다 들어와도 유지)
  static const String _keyLastMongiLetterDate =
      'last_mongi_letter_date'; // String yyyy-MM-dd ("몽이의 주간 편지"를 마지막으로 새로
  // 도착 처리한 날짜 - 일주일에 한 번만 "새 편지 도착" 배지를 새로 띄우기 위한 플래그.
  // 주간 감정 리포트(_keyLastWeeklyReportDate)와 별개로, 이건 화면 자동 이동 없이
  // 배지만 켜두고 유저가 직접 눌러서 열어보게 한다.
  static const String _keyHasUnreadMongiLetter =
      'has_unread_mongi_letter'; // bool (지금 안 읽은 새 편지가 있는지 - 배지 표시용)

  // ── 나만의 안전 계획 ("Safety Plan") ─────────────────────────
  static const String _keySafetyPlan =
      'safety_plan_data'; // Map<String,String> (섹션 id -> 유저가 직접 적은 텍스트,
  // 전부 로컬에만 저장되고 서버로 전송되지 않는다 - 매우 민감한 개인 정보이기 때문)

  // ── F2P 이중 화폐 시스템 ─────────────────────────
  // 3번(정체성 재정렬): 엔드리스 모드 입장에 "기력"을 소비하게 만들던 에너지
  // 시스템(최대치/자동 충전/광고·재화로 충전)을 완전히 제거했다. 힐링을
  // 원하는 순간에 "기력이 없어서 못 한다"는 경험은 이 앱의 정체성과 정면으로
  // 충돌한다는 판단에 따라, 엔드리스 모드는 이제 언제든 무료로 들어갈 수
  // 있다. 화폐(빛의 정수/별조각)는 "마음 상자" 뽑기용으로만 남긴다.
  // "마음 상자" 가챠 등 일상적인 소비에 쓰인다)
  static const String _keyStarShard =
      'star_shard'; // int (별조각 - 하드 화폐. 신기록 달성 같은 특별한 순간이나 실제 결제로만
  // 얻을 수 있어 희소하며, 프리미엄 가챠 등에 쓰인다)

  // ── 파워 부적(소모품 인벤토리) ─────────────────────────
  static const String _keyPowerCharmCount =
      'power_charm_count'; // int (지금 보유한 "파워 부적" 개수 - 빛의 정수로 구매하며,
  // 게임 중 아무 때나 써서 즉시 10초 무적 모드를 발동할 수 있다)

  // ── 몽이 돌봄 세트(참치캔/사료/맑은물/담요/몽이의 집) ─────────────
  static const String _keyMongiCareCounts =
      'mongi_care_counts'; // Map<String,int> (돌봄 아이템 id -> 지금까지 준 누적 횟수.
  // keepsake(담요/몽이의 집)는 1 이상이면 "획득함"으로 취급해 정원 씬에 영구 배치한다)

  // ── "마음 상자" 가챠 (몽이 코스튬) ─────────────────────────
  static const String _keyOwnedCostumes =
      'owned_costumes'; // List<String> (보유한 코스튬 id 목록, 중복 없음)
  static const String _keyEquippedCostume =
      'equipped_costume'; // String? (지금 몽이에게 씌워둔 코스튬 id, null이면 없음)
  static const String _keyGachaTotalPulls =
      'gacha_total_pulls'; // int (지금까지 열어본 누적 상자 개수, 통계/UI용)

  // ── 시즌 패스("몽이의 마음여정") ─────────────────────────
  // 일정 기간(시즌)마다 리셋되는 경험치 트랙으로, 플레이할수록 쌓이는
  // "시즌 경험치"로 레벨을 올려 무료/프리미엄 두 트랙의 보상을 "수령"한다.
  // [_keyScore](영구 나무 성장 점수)와는 완전히 별개의 지표다.
  static const String _keySeasonStartAt =
      'season_pass_start_at'; // int (지금 시즌이 시작된 시각, epoch millis)
  static const String _keySeasonNumber =
      'season_pass_number'; // int (몇 번째 시즌인지, 1부터 시작 - UI에 "시즌 N" 표시용)
  static const String _keySeasonXp =
      'season_pass_xp'; // int (이번 시즌 누적 경험치 - 시즌이 바뀌면 0으로 리셋)
  static const String _keySeasonPremiumPurchased =
      'season_pass_premium_purchased'; // bool (이번 시즌 프리미엄 패스를 구매했는지 - 시즌이 바뀌면 리셋)
  static const String _keySeasonClaimedFree =
      'season_pass_claimed_free'; // List<int> (무료 트랙에서 이미 수령한 레벨 목록, 이번 시즌 한정)
  static const String _keySeasonClaimedPremium =
      'season_pass_claimed_premium'; // List<int> (프리미엄 트랙에서 이미 수령한 레벨 목록, 이번 시즌 한정)

  // ── 일일 미션 ─────────────────────────
  // 매일 자정(날짜 변경)에 진행도가 초기화되는 고정 3종 미션.
  // "오늘 몇 개나 했는지" 진행도 + "이미 보상을 수령했는지"를 미션 id별로
  // 각각 저장한다. 날짜가 바뀌면 진행도/수령 기록 모두 새로 시작한다.
  static const String _keyDailyMissionDate =
      'daily_mission_date'; // String yyyy-MM-dd (마지막으로 미션 진행도를 기록한 날짜 -
  // 오늘과 다르면 모든 진행도/수령 기록이 자동으로 리셋된 것으로 취급한다)
  static const String _keyDailyMissionProgress =
      'daily_mission_progress'; // Map<String,int> (미션 id -> 오늘 진행도)
  static const String _keyDailyMissionClaimed =
      'daily_mission_claimed'; // List<String> (오늘 이미 보상을 수령한 미션 id 목록)
  static const String _keyDailyMissionAllClearClaimed =
      'daily_mission_all_clear_claimed'; // bool (오늘 올클리어 보너스를 이미 수령했는지)

  // ── 마음 챌린지 (Finch "Goal Journeys" 벤치마킹) ─────────────────
  // 테마(자존감/불안/번아웃/감사)를 하나 골라 7일 동안 매일 감정 체크인을
  // 하면 진행되는 다일 여정. 하루 진행 조건은 기존 "오늘의 감정 체크인"을
  // 그대로 재사용하므로 별도의 완료 플래그 없이, 체크인한 날짜만 기록해두면
  // 챌린지 진행도를 계산할 수 있다.
  static const String _keyMindChallengeActiveId =
      'mind_challenge_active_id'; // String? (지금 진행 중인 챌린지 id, null이면 없음)
  static const String _keyMindChallengeStartDate =
      'mind_challenge_start_date'; // String yyyy-MM-dd (진행 중인 챌린지를 시작한 날짜)
  static const String _keyMindChallengeCheckedDates =
      'mind_challenge_checked_dates'; // List<String> (진행 중인 챌린지에서 체크인을 완료한
  // 날짜들, yyyy-MM-dd - 연속 여부와 무관하게 "며칠째 완료했는지"는 이 목록의 길이로 판정한다)
  static const String _keyMindChallengeCompletedIds =
      'mind_challenge_completed_ids'; // List<String> (지금까지 완주(모든 날짜 채움 + 완주
  // 보너스 수령까지 끝난) 챌린지 id 목록 - 통계/도감용, 재도전을 막지는 않는다)

  // ── 몽이의 응원 우편함 (Finch "Good Vibes" 벤치마킹) ─────────────
  // 이 앱은 서버/타인 계정이 전혀 없는 완전 로컬 우선 구조라, 실제 타인과
  // 실시간으로 메시지를 주고받는 "진짜 소셜"은 만들지 않는다. 대신 정직하게
  // 재해석한 로컬 경량판: "보내기"는 큐레이션된 응원 문구 하나를 몽이에게
  // 맡기는 제스처(실제 수신자 없음), "받기"는 하루 한 번 큐레이션된 응원
  // 풀에서 무작위로 하나를 받는 것이다. 두 동작 모두 하루 1회로 제한된다.
  static const String _keyLastCheerSentDate =
      'last_cheer_sent_date'; // String yyyy-MM-dd (마지막으로 응원을 "보낸" 날짜,
  // 오늘과 다르면 오늘 아직 보내지 않은 것으로 취급한다)
  static const String _keyLastCheerReceivedDate =
      'last_cheer_received_date'; // String yyyy-MM-dd (마지막으로 응원을 "받은" 날짜)
  static const String _keyTodayCheerReceivedIndex =
      'today_cheer_received_index'; // int (오늘 받은 응원 문구의 인덱스 - 다국어
  // 지원을 위해 문자열 대신 [MongiCheer.receiveMessageCount] 범위의 인덱스를 저장한다)
  static const String _keyCheerSentTotalCount =
      'cheer_sent_total_count'; // int (지금까지 응원을 보낸 총 횟수, 통계용)

  // ── 몽이의 숨결 도감 (Calm/Headspace 벤치마킹, 벤치마킹 제안 #5) ─────────────
  // 여러 호흡 기법(차분한 숨/불안완화/박스호흡/잠들기전) 중 하나를 골라
  // 끝까지 따라하면, 하루 처음 완료했을 때만 빛의 정수 보상을 준다(같은
  // 기법을 여러 번 반복해도 보상은 하루 한 번만 - 새로운 강제 행동을
  // 요구하지 않는 MVP 원칙에 따라, 완료 자체는 몇 번을 하든 자유롭다).
  static const String _keyLastBreathingRewardDate =
      'last_breathing_reward_date'; // String yyyy-MM-dd (오늘 이미 호흡 완료 보상을 받았는지)
  static const String _keyBreathingLibraryTotalCompletions =
      'breathing_library_total_completions'; // int (지금까지 끝까지 완료한 누적 횟수, 통계용)

  // ── 몽이의 마음 성찰 / 옵트인 AI 리플렉션 (벤치마킹 제안 #6) ─────────────
  // 서버/외부 AI 호출 없이, 이미 기기에 쌓인 감정 데이터(다이어리/감사기록/
  // 트리거/요일 패턴)를 [MindReflectionService]가 종합해서 더 깊은 통찰
  // 문단들을 만들어준다. 다만 "여러 기록을 한꺼번에 엮어서 보여준다"는 점이
  // 평소 화면들보다 더 예민하게 느껴질 수 있어, 설정에서 명시적으로 동의한
  // 사용자에게만 노출한다(기본값 꺼짐).
  static const String _keyAiReflectionOptIn =
      'ai_reflection_opt_in'; // bool (마음 성찰 기능 사용 동의 여부, 기본값 false)

  late Box _liveBox;
  dynamic get _box => SessionTransaction.draft ?? RecoveringBox(_liveBox);

  Future<void> init() async {
    await SessionTransaction.initialize();
    _liveBox = await HiveEncryption.openBox(_boxName);
    await MongiGardenStore.instance.reload();
    await _ensureSeasonFresh();
  }

  /// 지금 시즌이 아직 시작되지 않았거나(최초 실행) 이미 기간이 끝났으면,
  /// 새 시즌을 시작한다(경험치/수령 기록/프리미엄 구매 여부를 모두 리셋하고
  /// 시즌 번호를 +1). 이미 진행 중인 시즌이 남아있으면 아무 것도 하지 않는다.
  Future<void> _ensureSeasonFresh() async {
    final startedAt = _box.get(_keySeasonStartAt) as int?;
    final windowMs = seasonPassLengthMs;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (startedAt != null && now - startedAt < windowMs) return;
    final nextNumber = (_box.get(_keySeasonNumber, defaultValue: 0) as int) + 1;
    await _box.putAll({
      _keySeasonStartAt: now,
      _keySeasonNumber: nextNumber,
      _keySeasonXp: 0,
      _keySeasonPremiumPurchased: false,
      _keySeasonClaimedFree: <int>[],
      _keySeasonClaimedPremium: <int>[],
    });
  }

  String get _todayString {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  double get progress =>
      (_box.get(_keyProgress, defaultValue: 0.0) as num).toDouble();

  int get totalFedCount => _box.get(_keyTotalFed, defaultValue: 0) as int;

  int get streakDays => _box.get(_keyStreak, defaultValue: 0) as int;

  /// 몽이의 성장 스테이지 (1부터 시작). 스테이지가 오를수록:
  /// - 돌멩이가 조금씩 커진다
  /// - 2단계부터 작은 돌멩이는 손을 뻗어 부수는 기능이 생긴다 (큰 돌멩이는 항상 점프로 피함)
  int get stage => MongiGardenStore.instance.value.stage;

  Future<void> advanceStage() async {
    await MongiGardenStore.instance.advanceOriginalStage();
  }

  /// 오늘 날짜가 바뀌었으면 todayFedCount를 0으로 리셋하고, streak을 갱신한다.
  int get todayFedCount {
    final lastDate = _box.get(_keyLastDate, defaultValue: '') as String;
    if (lastDate != _todayString) {
      return 0;
    }
    return _box.get(_keyTodayFed, defaultValue: 0) as int;
  }

  /// 감정 하나를 먹였을 때 진행도를 갱신한다.
  /// 정원은 5개를 다 먹으면(스테이지1 기준) 100%가 되도록 20%씩 증가.
  Future<void> feedEmotion() async {
    await recordEaten(1, bonus: 0.0, target: 5);
  }

  /// [date]로부터 하루 전 날짜 문자열(yyyy-MM-dd)을 계산한다.
  String _dayBefore(String dateString) {
    final parts = dateString.split('-');
    if (parts.length != 3) return '';
    final d = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    ).subtract(const Duration(days: 1));
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  /// 러너 게임 한 판이 끝난 뒤, 먹은 감정 개수(및 보너스 진행도)를 한번에 기록한다.
  /// [target]: 이번 판의 목표 개수(스테이지별로 6/10/20/30... 다르다) - 진행도는
  /// 이 목표 대비 비율(count/target)로 계산되어, 목표가 커져도 한 판을 다 채우면
  /// 항상 정원이 100% 만개할 수 있도록 맞춰준다.
  Future<void> recordEaten(
    int count, {
    double bonus = 0.0,
    int target = 5,
  }) async {
    if (count <= 0 && bonus <= 0) return;
    final lastDate = _box.get(_keyLastDate, defaultValue: '') as String;
    final isNewDay = lastDate != _todayString;

    int newStreak = streakDays;
    if (isNewDay) {
      // 하루가 지나서 처음 먹이는 경우 - 어제도 방문했으면 연속 기록 +1,
      // 하루 이상 걸렀다면(또는 첫 방문이면) 스트릭은 1부터 다시 시작한다.
      final continuedStreak =
          lastDate.isNotEmpty && lastDate == _dayBefore(_todayString);
      newStreak = continuedStreak ? streakDays + 1 : 1;
    }

    final newTodayFed = (isNewDay ? 0 : todayFedCount) + count;
    final newTotalFed = totalFedCount + count;
    final currentProgress = progress;
    final safeTarget = target > 0 ? target : 5;
    final newProgress = (currentProgress + count / safeTarget + bonus).clamp(
      0.0,
      1.0,
    );

    await _box.putAll({
      _keyProgress: newProgress,
      _keyTotalFed: newTotalFed,
      _keyTodayFed: newTodayFed,
      _keyLastDate: _todayString,
      _keyStreak: newStreak,
    });
  }

  /// 정원이 만개(100%)했을 때 다음 사이클을 위해 리셋 (진행도만 리셋, 누적/연속일은 유지)
  Future<void> resetGardenCycle() async {
    await _box.put(_keyProgress, 0.0);
  }

  /// 개발/테스트용 - 이 기기에 저장된 몽이 진행도를 전부 지우고 처음(1단계,
  /// 온보딩부터)으로 되돌린다. 되돌릴 수 없는 동작이라 호출하는 쪽(UI)에서
  /// 반드시 확인 다이얼로그를 거친 뒤에만 불러야 한다.
  Future<void> resetAllProgress() async {
    throw StateError('통합 앱에서는 몽이 전체 초기화를 지원하지 않아요. 기록 보호를 위해 초기화하지 않았어요.');
  }

  /// 마지막으로 정원에 감정을 먹인 날로부터 오늘까지 며칠이 지났는지.
  /// 아직 한 번도 먹이지 않았다면(=기록 없음) 0을 반환한다(시듦 판정 대상 아님).
  int get daysSinceLastFeed {
    final lastDate = _box.get(_keyLastDate, defaultValue: '') as String;
    if (lastDate.isEmpty) return 0;
    final parts = lastDate.split('-');
    if (parts.length != 3) return 0;
    final last = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
    final now = DateTime.now();
    final todayDateOnly = DateTime(now.year, now.month, now.day);
    return todayDateOnly.difference(last).inDays;
  }

  /// 몽이의 성장나무가 살짝 시들어 보여야 하는지 여부.
  /// 어제까지는 그냥 넘어가고(방문 텀 하루는 정상 범위), 하루를 통째로 거른
  /// 경우(=이틀 이상 지남)에만 "시듦" 상태로 본다 - 절대 처벌적으로 느껴지지
  /// 않도록, 오늘 한 번만 다시 찾아와도(recordEaten 호출) 곧바로 회복된다.
  bool get isTreeWilted => daysSinceLastFeed >= 2;

  /// 감정 타입별로 지금까지 심어진 꽃 개수 (누적, 절대 리셋되지 않음 - "내 마음정원" 화면에서 사용).
  Map<String, int> get flowerCounts {
    final raw =
        _box.get(_keyFlowerCounts, defaultValue: <String, dynamic>{}) as Map;
    return raw.map(
      (key, value) => MapEntry(key.toString(), (value as num).toInt()),
    );
  }

  /// 러너 게임 한 판을 끝내고 감정을 치유했을 때, 그 감정 타입에 꽃을 [count]개 심는다.
  Future<void> plantFlower(String emotionTypeName, int count) async {
    if (count <= 0) return;
    final current = flowerCounts;
    current[emotionTypeName] = (current[emotionTypeName] ?? 0) + count;
    await _box.put(_keyFlowerCounts, current);
  }

  /// 지금까지 쓰여진 감정 일기 기록(최신순). 한 항목당:
  /// {date, emotionType, targetName, eatenCount, note, intensity, triggers}
  /// - intensity(int? 1~5)와 triggers(문자열 리스트, 트리거 태그 id들)는
  ///   나중에 추가된 필드라 과거 기록에는 없을 수 있다 - 읽을 때 null/빈
  ///   리스트로 안전하게 기본값 처리한다(하위 호환).
  List<Map<String, dynamic>> get diaryEntries {
    final raw = _box.get(_keyDiary, defaultValue: <dynamic>[]) as List;
    return raw
        .whereType<Map>()
        .map((m) => m.map((key, value) => MapEntry(key.toString(), value)))
        .toList();
  }

  /// 러너 게임 한 판이 끝난 뒤(선택 화면에서) 한 줄 일기를 새로 남긴다.
  /// [note]가 null/공백이면 글 없이 세션만 기록된다.
  /// [intensity]는 1~5(선택), [triggers]는 트리거 태그 id 목록(선택, 비어있으면
  /// 저장하지 않음).
  Future<void> addDiaryEntry({
    required String emotionTypeName,
    String? targetName,
    required int eatenCount,
    String? note,
    int? intensity,
    List<String>? triggers,
  }) async {
    final entries = diaryEntries;
    entries.insert(0, {
      'date': _todayString,
      'emotionType': emotionTypeName,
      'targetName': targetName,
      'eatenCount': eatenCount,
      'note': (note != null && note.trim().isNotEmpty) ? note.trim() : null,
      'intensity': (intensity != null && intensity >= 1 && intensity <= 5)
          ? intensity
          : null,
      'triggers': (triggers != null && triggers.isNotEmpty) ? triggers : null,
    });
    if (entries.length > _maxDiaryEntries) {
      entries.removeRange(_maxDiaryEntries, entries.length);
    }
    await _box.put(_keyDiary, entries);
  }

  /// 아직 출시되지 않은 프리미엄 카드 프레임에 대해 사용자가 "출시 알림 받기"를 누른 횟수.
  /// 실 결제 붙이기 전, 코스메틱 유료화 수요를 가늠하기 위한 최소 지표(로컬 집계).
  int get premiumFrameInterestCount =>
      _box.get(_keyPremiumFrameInterest, defaultValue: 0) as int;

  Future<void> registerPremiumFrameInterest() async {
    await _box.put(_keyPremiumFrameInterest, premiumFrameInterestCount + 1);
  }

  /// 씨앗 종류(id)별로 지금까지 물을 준(=심은) 누적 횟수. 이 숫자가 쌓일수록
  /// "몽이의 작은 정원" 화면에서 해당 씨앗이 눈에 보이게 성장한다.
  Map<String, int> get seedCounts =>
      Map.of(MongiGardenStore.instance.value.seeds);

  Future<void> plantSeed(String seedId) =>
      MongiGardenStore.instance.plantOriginalReward(seedId);

  /// 처음 실행 시 보여주는 튜토리얼(온보딩)을 이미 봤는지 여부.
  bool get hasSeenOnboarding =>
      _box.get(_keyHasSeenOnboarding, defaultValue: false) as bool;

  Future<void> markOnboardingSeen() async {
    await _box.put(_keyHasSeenOnboarding, true);
  }

  /// 매일 리마인더 알림이 켜져 있는지 여부 (기본값: 꺼짐 - 명시적으로 켜야 함).
  bool get notificationsEnabled =>
      _box.get(_keyNotifEnabled, defaultValue: false) as bool;

  /// 알림을 보낼 시각. 기본값 오후 8시(20:00) - 하루를 정리하기 좋은 시간.
  int get notificationHour => _box.get(_keyNotifHour, defaultValue: 20) as int;
  int get notificationMinute =>
      _box.get(_keyNotifMinute, defaultValue: 0) as int;

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _box.put(_keyNotifEnabled, enabled);
  }

  Future<void> setNotificationTime(int hour, int minute) async {
    await _box.putAll({_keyNotifHour: hour, _keyNotifMinute: minute});
  }

  /// 사용자가 설정 화면에서 직접 고른 언어 코드('ko'/'en').
  /// null이면 기기의 시스템 언어를 그대로 따라간다(기본값).
  String? get languageCode => _box.get(_keyLanguageCode) as String?;

  Future<void> setLanguageCode(String? code) async {
    if (code == null) {
      await _box.delete(_keyLanguageCode);
    } else {
      await _box.put(_keyLanguageCode, code);
    }
  }

  /// 프리미엄 카드 프레임 팩(벚꽃/골드 별빛)을 실제로 구매해서 잠금 해제했는지 여부.
  /// Google Play Billing 구매가 확인되면 [PurchaseService]가 이 값을 true로 저장한다.
  bool get premiumFramesUnlocked =>
      _box.get(_keyPremiumFramesUnlocked, defaultValue: false) as bool;

  Future<void> setPremiumFramesUnlocked(bool unlocked) async {
    await _box.put(_keyPremiumFramesUnlocked, unlocked);
  }

  /// 정원을 한 번이라도 100% 만개시킨 적이 있는지 여부.
  /// 무료 장식 아이템 "조약돌 오솔길"의 잠금 해제 조건으로 사용된다.
  /// 한 번 true가 되면 그 뒤로는 계속 true로 유지된다(리셋되지 않음).
  bool get hasBloomedOnce =>
      _box.get(_keyHasBloomedOnce, defaultValue: false) as bool;

  Future<void> markBloomedOnce() async {
    if (!hasBloomedOnce) {
      await _box.put(_keyHasBloomedOnce, true);
    }
  }

  /// 지금 정원에 배치해서 보여주고 있는 장식 아이템 id 목록.
  List<String> get equippedDecorations =>
      MongiGardenStore.instance.value.placed.toList();

  Future<void> setEquippedDecorations(List<String> ids) =>
      MongiGardenStore.instance.placeOriginalDecorations(ids);

  /// 프리미엄 정원 장식팩(종이등/무지개 울타리/반짝이는 별빛)을 실제로 구매해서
  /// 잠금 해제했는지 여부. [PurchaseService]가 구매 확인 시 이 값을 true로 저장한다.
  bool get decorationPackUnlocked =>
      _box.get(_keyDecorationPackUnlocked, defaultValue: false) as bool;

  Future<void> setDecorationPackUnlocked(bool unlocked) async {
    await _box.put(_keyDecorationPackUnlocked, unlocked);
  }

  /// 지금까지 쌓인 누적 점수. 스테이지를 완료할 때마다(특히 목표 감정을 모두
  /// 먹었을 때) 점수가 쌓이고, 이 점수로 "몽이의 성장나무"(새싹→나무→꽃→열매)가
  /// 자라난다 ([TreeGrowth] 참고). 절대 리셋되지 않는 영구 누적치다.
  int get score => _box.get(_keyScore, defaultValue: 0) as int;

  /// [amount]만큼 점수를 더한다. 음수/0이면 아무 것도 하지 않는다.
  Future<void> addScore(int amount) async {
    if (amount <= 0) return;
    await _box.put(_keyScore, score + amount);
  }

  /// 성장나무 마일스톤 보상을 마지막으로 수령한 단계 인덱스.
  /// -1이면 아직 하나도 수령하지 않은 상태.
  int get treeMilestoneClaimedStage =>
      _box.get(_keyTreeMilestoneClaimed, defaultValue: -1) as int;

  /// 지금 도달한 단계까지 마일스톤 수령 기록을 갱신한다.
  Future<void> markTreeMilestoneClaimed(int stageIndex) async {
    if (stageIndex <= treeMilestoneClaimedStage) return;
    await _box.put(_keyTreeMilestoneClaimed, stageIndex);
  }

  // ── 감정 체크인 데일리 루틴 (Finch식: "오늘 기분은 어때?") ─────────────────

  /// 오늘 이미 감정 체크인을 했는지 여부. 날짜가 바뀌면 자동으로 다시 false가 된다.
  bool get hasCheckedInToday {
    final lastDate = _box.get(_keyLastCheckInDate, defaultValue: '') as String;
    return lastDate == _todayString;
  }

  /// 오늘 체크인한 감정 타입 이름 (오늘 체크인하지 않았으면 null).
  String? get todayCheckInEmotionName {
    if (!hasCheckedInToday) return null;
    final v = _box.get(_keyLastCheckInEmotion) as String?;
    return v;
  }

  /// 매일 감정 체크인을 연속으로 한 일수 (하루라도 거르면 1로 리셋).
  int get checkInStreak => _box.get(_keyCheckInStreak, defaultValue: 0) as int;

  /// 지금까지 세운 감정 체크인 연속일수 개인 최고 기록(스트릭 가시성 강화,
  /// 벤치마킹 제안 #4). 지금 스트릭이 끊겨도 이 값은 절대 줄어들지 않는다.
  int get bestCheckInStreak =>
      _box.get(_keyBestCheckInStreak, defaultValue: 0) as int;

  /// 홈 화면에 처음 진입했을 때 "오늘 기분은 어때?"에 답한 감정을 기록한다.
  /// 게임 내 감정 선택(먹이기)과는 별개로, 순수하게 "오늘의 현실 감정 체크인"만 기록한다.
  /// 어제도 체크인했으면 streak +1, 하루 이상 걸렀다면 streak은 1로 리셋된다.
  Future<int> recordDailyCheckIn(String emotionTypeName) async {
    if (hasCheckedInToday) return checkInStreak;
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final yesterdayString =
        '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
    final lastDate = _box.get(_keyLastCheckInDate, defaultValue: '') as String;
    final continuedStreak = lastDate == yesterdayString;
    final newStreak = continuedStreak ? checkInStreak + 1 : 1;
    final newBest = newStreak > bestCheckInStreak
        ? newStreak
        : bestCheckInStreak;
    await _box.putAll({
      _keyLastCheckInDate: _todayString,
      _keyLastCheckInEmotion: emotionTypeName,
      _keyCheckInStreak: newStreak,
      _keyBestCheckInStreak: newBest,
    });
    return newStreak;
  }

  // ── 엔드리스 모드 + 최고기록 (무한의 계단식: "오늘 내 최고 기록") ─────────────

  /// 엔드리스 모드 최고기록 - 지금까지 한 판에서 먹은 감정의 최대 개수.
  int get bestEndlessCount =>
      _box.get(_keyBestEndlessCount, defaultValue: 0) as int;

  /// 엔드리스 모드 최고기록 - 그 기록을 세운 판에서 생존한 시간(초).
  int get bestEndlessSeconds =>
      _box.get(_keyBestEndlessSeconds, defaultValue: 0) as int;

  /// 엔드리스 모드 한 판이 끝났을 때 호출한다. 이번 판이 기존 최고기록(먹은 개수
  /// 기준)을 넘어섰으면 갱신하고 true를 반환한다 (결과 화면에서 "신기록!" 표시용).
  Future<bool> recordEndlessResult({
    required int eatenCount,
    required int survivedSeconds,
  }) async {
    final isNewRecord = eatenCount > bestEndlessCount;
    if (isNewRecord) {
      await _box.putAll({
        _keyBestEndlessCount: eatenCount,
        _keyBestEndlessSeconds: survivedSeconds,
      });
    }
    return isNewRecord;
  }

  // ── 성장 마일스톤 회고 ("감정 성장 다큐멘터리") ─────────────────────────

  /// 몽이의 성장나무가 마지막 단계(열매)에 도달했을 때 보여주는 회고 화면을
  /// 이미 한 번이라도 봤는지 여부. 처음 열매를 맺은 "그 순간"에만 자동으로
  /// 띄워주기 위한 플래그로, 그 뒤로는 도감/설정 등에서 원할 때 다시 볼 수 있다.
  bool get hasSeenGrowthMilestone =>
      _box.get(_keyHasSeenGrowthMilestone, defaultValue: false) as bool;

  Future<void> markGrowthMilestoneSeen() async {
    if (!hasSeenGrowthMilestone) {
      await _box.put(_keyHasSeenGrowthMilestone, true);
    }
  }

  // ── 주간 감정 리포트 ("이번 주 몽이의 관찰") ─────────────────────────

  /// 오늘 기준으로 최근 7일 안에 이미 주간 리포트를 자동으로 보여준 적이 있는지.
  /// (일주일에 한 번만 자동 노출하기 위함 - 홈 화면 배지로는 언제든 다시 볼 수 있다)
  bool get hasShownWeeklyReportRecently {
    final lastDate =
        _box.get(_keyLastWeeklyReportDate, defaultValue: '') as String;
    if (lastDate.isEmpty) return false;
    final parts = lastDate.split('-');
    if (parts.length != 3) return false;
    final last = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
    final now = DateTime.now();
    final todayDateOnly = DateTime(now.year, now.month, now.day);
    return todayDateOnly.difference(last).inDays < 7;
  }

  Future<void> markWeeklyReportShown() async {
    await _box.put(_keyLastWeeklyReportDate, _todayString);
  }

  // ── 몽이의 주간 편지 ("Idea #3") ─────────────────────────

  /// 오늘 기준으로 최근 7일 안에 이미 새 편지를 도착시킨 적이 있는지.
  /// (일주일에 한 번만 새 편지 배지를 새로 켜기 위함)
  bool get hasIssuedMongiLetterRecently {
    final lastDate =
        _box.get(_keyLastMongiLetterDate, defaultValue: '') as String;
    if (lastDate.isEmpty) return false;
    final parts = lastDate.split('-');
    if (parts.length != 3) return false;
    final last = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
    final now = DateTime.now();
    final todayDateOnly = DateTime(now.year, now.month, now.day);
    return todayDateOnly.difference(last).inDays < 7;
  }

  /// 지금 안 읽은 새 편지가 있는지(배지 표시용).
  bool get hasUnreadMongiLetter =>
      _box.get(_keyHasUnreadMongiLetter, defaultValue: false) as bool;

  /// 일주일에 한 번, 새 편지가 도착했다고 기록하고 배지를 켠다.
  Future<void> issueMongiLetter() async {
    await _box.put(_keyLastMongiLetterDate, _todayString);
    await _box.put(_keyHasUnreadMongiLetter, true);
  }

  /// 유저가 편지를 열어봤을 때 - 배지를 끈다(다음 주까지 다시 새로 켜지지 않음).
  Future<void> markMongiLetterRead() async {
    await _box.put(_keyHasUnreadMongiLetter, false);
  }

  // ── 감정 도감 레어도 시스템 ("황금 프레임") ─────────────────────────

  /// 지금까지 "황금 프레임"을 획득한 감정 타입 이름 목록 (영구 누적, 리셋되지 않음).
  Set<String> get goldenFrameEmotions {
    final raw =
        _box.get(_keyGoldenFrameEmotions, defaultValue: <dynamic>[]) as List;
    return raw.map((e) => e.toString()).toSet();
  }

  /// 이 감정에 대해 이미 황금 프레임을 획득했는지 여부.
  bool hasGoldenFrame(String emotionTypeName) =>
      goldenFrameEmotions.contains(emotionTypeName);

  /// 새로 황금 프레임을 획득했을 때 호출한다. 이미 갖고 있으면 아무 것도
  /// 하지 않는다(중복 없음).
  Future<void> unlockGoldenFrame(String emotionTypeName) async {
    final current = goldenFrameEmotions;
    if (current.contains(emotionTypeName)) return;
    current.add(emotionTypeName);
    await _box.put(_keyGoldenFrameEmotions, current.toList());
  }

  // ── 6번: 감정 마스터 이후 히든 4단계("초월") ─────────────────────────

  /// 지금까지 "초월"(100번째 마주침) 발견을 이미 축하해준 감정 타입 이름 목록.
  Set<String> get transcendedEmotions {
    final raw =
        _box.get(_keyTranscendedEmotions, defaultValue: <dynamic>[]) as List;
    return raw.map((e) => e.toString()).toSet();
  }

  /// 이 감정에 대해 "초월" 발견을 이미 한 번 축하해줬는지 여부.
  bool hasCelebratedTranscendence(String emotionTypeName) =>
      transcendedEmotions.contains(emotionTypeName);

  /// 새로 "초월"을 발견했을 때 호출한다. 이미 기록되어 있으면 아무 것도
  /// 하지 않는다(중복 없음) - 결과 화면 축하 팝업이 세션마다 한 번만 뜨게 한다.
  Future<void> markTranscendenceCelebrated(String emotionTypeName) async {
    final current = transcendedEmotions;
    if (current.contains(emotionTypeName)) return;
    current.add(emotionTypeName);
    await _box.put(_keyTranscendedEmotions, current.toList());
  }

  // ── 몽이의 하루 (다마고치 이스터에그) ─────────────────────────

  /// 오늘 이미 이스터에그 대사를 뽑았는지 여부.
  bool get hasDrawnEasterEggToday {
    final lastDate =
        _box.get(_keyLastEasterEggDate, defaultValue: '') as String;
    return lastDate == _todayString;
  }

  /// 오늘 뽑힌 이스터에그 대사의 인덱스(오늘 뽑지 않았으면 null). 실제 문구는
  /// [MongiMoodService.easterEggCount] 범위의 인덱스를 화면에서
  /// AppLocalizations로 변환해 사용한다(다국어 지원을 위해 문자열 자체는
  /// 저장하지 않는다).
  int? get todayEasterEggIndex {
    if (!hasDrawnEasterEggToday) return null;
    final raw = _box.get(_keyLastEasterEggLine);
    // 예전 버전에서는 이 키에 완성된 한국어 문장(String)을 저장했었다.
    // 다국어 지원을 위해 인덱스(int)로 바꿨으므로, 옛 데이터가 남아있는
    // 기기에서는 안전하게 null을 반환해 오늘 새로 하나를 뽑도록 한다.
    return raw is int ? raw : null;
  }

  /// 오늘의 이스터에그 대사 인덱스를 저장한다(하루 한 번만 호출되도록 호출부에서 관리).
  Future<void> saveTodayEasterEggIndex(int index) async {
    await _box.putAll({
      _keyLastEasterEggDate: _todayString,
      _keyLastEasterEggLine: index,
    });
  }

  // ── F2P 이중 화폐 시스템 ─────────────────────────

  /// 지금까지 쌓인 "빛의 정수"(소프트 화폐) 잔액.
  int get lightEssence => MongiGardenStore.instance.value.essence;

  Future<void> addLightEssence(int amount) =>
      MongiGardenStore.instance.addOriginalEssence(amount);
  Future<bool> spendLightEssence(int amount) =>
      MongiGardenStore.instance.spendOriginalEssence(amount);

  /// 지금까지 쌓인 "별조각"(하드 화폐) 잔액.
  int get starShard => _box.get(_keyStarShard, defaultValue: 0) as int;

  /// [amount]만큼 별조각을 더한다. 음수/0이면 아무 것도 하지 않는다.
  Future<void> addStarShard(int amount) async {
    if (amount <= 0) return;
    await _box.put(_keyStarShard, starShard + amount);
  }

  /// [amount]만큼 별조각을 소비한다. 잔액이 모자라면 false를 반환하고
  /// 아무 것도 차감하지 않는다.
  Future<bool> spendStarShard(int amount) async {
    if (amount <= 0) return true;
    if (starShard < amount) return false;
    await _box.put(_keyStarShard, starShard - amount);
    return true;
  }

  // ── 파워 부적(소모품 인벤토리) ─────────────────────────

  /// 지금 보유한 "파워 부적" 개수.
  int get powerCharmCount =>
      _box.get(_keyPowerCharmCount, defaultValue: 0) as int;

  /// [count]개만큼 파워 부적을 더한다(구매/보상 지급).
  Future<void> addPowerCharm(int count) async {
    if (count <= 0) return;
    await _box.put(_keyPowerCharmCount, powerCharmCount + count);
  }

  /// 파워 부적 1개를 사용한다. 보유 개수가 0이면 false를 반환하고 아무
  /// 것도 차감하지 않는다.
  Future<bool> consumePowerCharm() async {
    if (!await SubscriptionService().isPremium()) return false;
    if (powerCharmCount <= 0) return false;
    await _box.put(_keyPowerCharmCount, powerCharmCount - 1);
    return true;
  }

  // ── 몽이 돌봄 세트(참치캔/사료/맑은물/담요/몽이의 집) ─────────────

  /// 돌봄 아이템 id별로 지금까지 준 누적 횟수.
  Map<String, int> get mongiCareCounts {
    final raw =
        _box.get(_keyMongiCareCounts, defaultValue: <String, dynamic>{}) as Map;
    return raw.map(
      (key, value) => MapEntry(key.toString(), (value as num).toInt()),
    );
  }

  /// [itemId] 돌봄 아이템을 몽이에게 한 번 더 준다(누적 카운트 +1).
  Future<void> giveMongiCareItem(String itemId) async {
    final current = mongiCareCounts;
    current[itemId] = (current[itemId] ?? 0) + 1;
    await _box.put(_keyMongiCareCounts, current);
  }

  // ── "마음 상자" 가챠 (몽이 코스튬) ─────────────────────────

  /// 지금까지 보유한 코스튬 id 목록 (중복 없음, 영구 누적 - 리셋되지 않음).
  Set<String> get ownedCostumes {
    final raw = _box.get(_keyOwnedCostumes, defaultValue: <dynamic>[]) as List;
    return raw.map((e) => e.toString()).toSet();
  }

  /// 이 코스튬을 이미 보유하고 있는지 여부.
  bool hasCostume(String costumeId) => ownedCostumes.contains(costumeId);

  /// 새로 코스튬을 획득했을 때 호출한다. 이미 갖고 있으면 아무 것도 하지 않는다.
  /// 반환값: 처음 획득한 것이면 true (중복 획득이면 false - 호출부에서 보상으로
  /// 소프트 화폐를 대신 지급하는 등의 처리를 할 수 있다).
  Future<bool> unlockCostume(String costumeId) async {
    final current = ownedCostumes;
    if (current.contains(costumeId)) return false;
    current.add(costumeId);
    await _box.put(_keyOwnedCostumes, current.toList());
    return true;
  }

  /// 지금 몽이에게 씌워둔 코스튬 id (없으면 null - 기본 모습).
  String? get equippedCostumeId => _box.get(_keyEquippedCostume) as String?;

  /// 코스튬을 장착/해제한다. [costumeId]가 null이면 해제(기본 모습으로).
  /// 보유하지 않은 코스튬은 장착할 수 없다.
  Future<void> setEquippedCostume(String? costumeId) async {
    if (costumeId != null && !hasCostume(costumeId)) return;
    await _box.put(_keyEquippedCostume, costumeId);
  }

  /// 지금까지 열어본 누적 상자 개수.
  int get gachaTotalPulls =>
      _box.get(_keyGachaTotalPulls, defaultValue: 0) as int;

  /// 상자를 하나 열었음을 기록한다(누적 카운트 +1).
  Future<void> recordGachaPull() async {
    await _box.put(_keyGachaTotalPulls, gachaTotalPulls + 1);
  }

  // ── 시즌 패스("몽이의 마음여정") ─────────────────────────

  /// 시즌 하나의 길이(밀리초). [SeasonPass.seasonLengthDays] 기준.
  static const int seasonPassLengthMs =
      SeasonPass.seasonLengthDays * 24 * 60 * 60 * 1000;

  /// 지금 시즌이 시작된 시각(epoch millis).
  int get seasonStartAt => _box.get(_keySeasonStartAt, defaultValue: 0) as int;

  /// 지금 몇 번째 시즌인지(1부터 시작).
  int get seasonNumber => _box.get(_keySeasonNumber, defaultValue: 1) as int;

  /// 이번 시즌이 끝나기까지 남은 시간(초). 이미 지났으면 0(다음 [init]/
  /// [refreshSeasonIfNeeded] 호출 시 새 시즌으로 넘어간다).
  int get seasonSecondsRemaining {
    final started = seasonStartAt;
    if (started == 0) return seasonPassLengthMs ~/ 1000;
    final elapsedMs = DateTime.now().millisecondsSinceEpoch - started;
    final remainingMs = seasonPassLengthMs - elapsedMs;
    return remainingMs <= 0 ? 0 : (remainingMs / 1000).ceil();
  }

  /// 화면에 돌아올 때마다 호출해서, 시즌 기간이 끝났다면 새 시즌으로 넘긴다.
  Future<void> refreshSeasonIfNeeded() async {
    await _ensureSeasonFresh();
  }

  /// 이번 시즌 누적 경험치(절대 음수가 되지 않고, 시즌이 바뀌면 0으로 리셋됨).
  int get seasonXp => _box.get(_keySeasonXp, defaultValue: 0) as int;

  /// [amount]만큼 시즌 경험치를 더한다. 음수/0이면 아무 것도 하지 않는다.
  /// 이미 최고 레벨(경험치 상한)에 도달했다면 더 쌓이지 않도록 상한을 둔다
  /// (프리미엄 구매를 나중에 해도 그동안 쌓아온 레벨이 그대로 인정되도록).
  Future<void> addSeasonXp(int amount) async {
    if (amount <= 0) return;
    final capped = (seasonXp + amount).clamp(0, SeasonPass.totalXpForMaxLevel);
    await _box.put(_keySeasonXp, capped);
  }

  /// 이번 시즌 프리미엄 패스를 구매했는지 여부(시즌이 바뀌면 리셋됨).
  bool get seasonPremiumPurchased =>
      _box.get(_keySeasonPremiumPurchased, defaultValue: false) as bool;

  Future<void> setSeasonPremiumPurchased(bool purchased) async {
    await _box.put(_keySeasonPremiumPurchased, purchased);
  }

  /// 무료 트랙에서 이미 보상을 수령한 레벨 목록(이번 시즌 한정).
  Set<int> get seasonClaimedFreeLevels {
    final raw =
        _box.get(_keySeasonClaimedFree, defaultValue: <dynamic>[]) as List;
    return raw.map((e) => (e as num).toInt()).toSet();
  }

  /// 프리미엄 트랙에서 이미 보상을 수령한 레벨 목록(이번 시즌 한정).
  Set<int> get seasonClaimedPremiumLevels {
    final raw =
        _box.get(_keySeasonClaimedPremium, defaultValue: <dynamic>[]) as List;
    return raw.map((e) => (e as num).toInt()).toSet();
  }

  /// [level] 무료 보상을 수령 처리한다. 이미 수령했으면 false를 반환한다.
  Future<bool> claimSeasonFreeLevel(int level) async {
    final current = seasonClaimedFreeLevels;
    if (current.contains(level)) return false;
    current.add(level);
    await _box.put(_keySeasonClaimedFree, current.toList());
    return true;
  }

  /// [level] 프리미엄 보상을 수령 처리한다. 이미 수령했으면 false를 반환한다.
  Future<bool> claimSeasonPremiumLevel(int level) async {
    final current = seasonClaimedPremiumLevels;
    if (current.contains(level)) return false;
    current.add(level);
    await _box.put(_keySeasonClaimedPremium, current.toList());
    return true;
  }

  // ── 일일 미션 ─────────────────────────

  /// 오늘 날짜와 마지막으로 기록된 미션 날짜가 다르면, 어제(또는 그 이전)의
  /// 진행도/수령 기록을 모두 지우고 오늘 날짜로 갱신한다. 미션 관련 getter를
  /// 호출하기 전에 항상 먼저 호출해서 "날짜가 바뀌면 자동으로 새로 시작"되게 한다.
  Future<void> _ensureDailyMissionFresh() async {
    final lastDate = _box.get(_keyDailyMissionDate, defaultValue: '') as String;
    if (lastDate == _todayString) return;
    await _box.putAll({
      _keyDailyMissionDate: _todayString,
      _keyDailyMissionProgress: <String, dynamic>{},
      _keyDailyMissionClaimed: <dynamic>[],
      _keyDailyMissionAllClearClaimed: false,
    });
  }

  /// 화면에 들어올 때마다 호출해서, 날짜가 바뀌었으면 미션을 새로 리셋한다.
  Future<void> refreshDailyMissionsIfNeeded() => _ensureDailyMissionFresh();

  /// 미션 id별 오늘 진행도. 날짜가 바뀌었는데 아직 [refreshDailyMissionsIfNeeded]가
  /// 호출되지 않았다면 어제 값이 섞여 보일 수 있으므로, 호출부(Provider)에서
  /// init/화면 진입 시 항상 먼저 리프레시를 호출하는 것을 전제로 한다.
  Map<String, int> get dailyMissionProgress {
    final raw =
        _box.get(_keyDailyMissionProgress, defaultValue: <String, dynamic>{})
            as Map;
    return raw.map(
      (key, value) => MapEntry(key.toString(), (value as num).toInt()),
    );
  }

  /// 오늘 이미 보상을 수령한 미션 id 목록.
  Set<String> get dailyMissionClaimed {
    final raw =
        _box.get(_keyDailyMissionClaimed, defaultValue: <dynamic>[]) as List;
    return raw.map((e) => e.toString()).toSet();
  }

  /// 오늘 올클리어 보너스를 이미 수령했는지 여부.
  bool get dailyMissionAllClearClaimed =>
      _box.get(_keyDailyMissionAllClearClaimed, defaultValue: false) as bool;

  /// [missionId] 진행도를 [amount]만큼 더한다(누적, 하루 안에서만 유효).
  /// 게임 플레이 중 자연스럽게 채워지는 값이므로 상한을 두지 않고 그대로
  /// 더하며, UI에서 target과 비교해 클램프해서 보여준다.
  Future<void> addDailyMissionProgress(String missionId, int amount) async {
    if (amount <= 0) return;
    await _ensureDailyMissionFresh();
    final current = dailyMissionProgress;
    current[missionId] = (current[missionId] ?? 0) + amount;
    await _box.put(_keyDailyMissionProgress, current);
  }

  /// [missionId] 보상을 수령 처리한다. 이미 수령했으면 false를 반환한다.
  Future<bool> claimDailyMission(String missionId) async {
    await _ensureDailyMissionFresh();
    final current = dailyMissionClaimed;
    if (current.contains(missionId)) return false;
    current.add(missionId);
    await _box.put(_keyDailyMissionClaimed, current.toList());
    return true;
  }

  /// 오늘의 올클리어 보너스를 수령 처리한다. 이미 수령했으면 false를 반환한다.
  Future<bool> claimDailyMissionAllClearBonus() async {
    await _ensureDailyMissionFresh();
    if (dailyMissionAllClearClaimed) return false;
    await _box.put(_keyDailyMissionAllClearClaimed, true);
    return true;
  }

  // ── 마음 챌린지 (Finch "Goal Journeys" 벤치마킹) ─────────────────

  /// 지금 진행 중인 챌린지 id (null이면 진행 중인 챌린지 없음).
  String? get mindChallengeActiveId =>
      _box.get(_keyMindChallengeActiveId) as String?;

  /// 진행 중인 챌린지를 시작한 날짜.
  String? get mindChallengeStartDate =>
      _box.get(_keyMindChallengeStartDate) as String?;

  /// 진행 중인 챌린지에서 체크인을 완료한 날짜 목록(순서 무관, 중복 없음).
  Set<String> get mindChallengeCheckedDates {
    final raw =
        _box.get(_keyMindChallengeCheckedDates, defaultValue: <dynamic>[])
            as List;
    return raw.map((e) => e.toString()).toSet();
  }

  /// 지금까지 완주한 챌린지 id 목록(중복 없음).
  Set<String> get mindChallengeCompletedIds {
    final raw =
        _box.get(_keyMindChallengeCompletedIds, defaultValue: <dynamic>[])
            as List;
    return raw.map((e) => e.toString()).toSet();
  }

  /// [challengeId] 챌린지를 새로 시작한다. 이미 다른 챌린지가 진행 중이면
  /// 그 진행 기록을 지우고 새 챌린지로 덮어쓴다(동시에 하나만 진행 가능).
  Future<void> startMindChallenge(String challengeId) async {
    await _box.putAll({
      _keyMindChallengeActiveId: challengeId,
      _keyMindChallengeStartDate: _todayString,
      _keyMindChallengeCheckedDates: <String>[],
    });
  }

  /// 진행 중인 챌린지를 중도에 그만둔다(포기). 완주 기록에는 영향 없다.
  Future<void> abandonMindChallenge() async {
    await _box.putAll({
      _keyMindChallengeActiveId: null,
      _keyMindChallengeStartDate: null,
      _keyMindChallengeCheckedDates: <String>[],
    });
  }

  /// 오늘 날짜를 진행 중인 챌린지의 완료 날짜 목록에 추가한다. 이미 오늘
  /// 기록되어 있으면 아무 것도 하지 않는다(하루에 한 번만 의미가 있음 - 실제
  /// 호출부([GardenProvider.recordDailyCheckIn])에서도 하루 체크인당 한 번만
  /// 호출된다).
  Future<void> markMindChallengeDayDone() async {
    if (mindChallengeActiveId == null) return;
    final dates = mindChallengeCheckedDates;
    dates.add(_todayString);
    await _box.put(_keyMindChallengeCheckedDates, dates.toList());
  }

  /// 진행 중인 챌린지를 완주 처리(모든 날짜를 채운 뒤 완주 보너스를 수령)
  /// 하고, 완주 목록에 추가하면서 활성 챌린지를 비운다.
  Future<void> completeMindChallenge(String challengeId) async {
    final completed = mindChallengeCompletedIds;
    completed.add(challengeId);
    await _box.putAll({
      _keyMindChallengeCompletedIds: completed.toList(),
      _keyMindChallengeActiveId: null,
      _keyMindChallengeStartDate: null,
      _keyMindChallengeCheckedDates: <String>[],
    });
  }

  // ── 몽이의 응원 우편함 (Finch "Good Vibes" 벤치마킹) ─────────────

  /// 오늘 이미 응원을 "보냈는지" 여부(하루 1회 제한).
  bool get hasSentCheerToday {
    final lastDate =
        _box.get(_keyLastCheerSentDate, defaultValue: '') as String;
    return lastDate == _todayString;
  }

  /// 오늘 이미 응원을 "받았는지" 여부(하루 1회 제한).
  bool get hasReceivedCheerToday {
    final lastDate =
        _box.get(_keyLastCheerReceivedDate, defaultValue: '') as String;
    return lastDate == _todayString;
  }

  /// 오늘 받은 응원 문구의 인덱스(오늘 아직 받지 않았으면 null). 실제 문구는
  /// [MongiCheer.receiveMessageCount] 범위의 인덱스를 화면에서
  /// AppLocalizations로 변환해 사용한다(다국어 지원을 위해 문자열 자체는
  /// 저장하지 않는다).
  int? get todayCheerReceivedIndex {
    if (!hasReceivedCheerToday) return null;
    final raw = _box.get(_keyTodayCheerReceivedIndex);
    return raw is int ? raw : null;
  }

  /// 지금까지 응원을 보낸 총 횟수(통계/도감용).
  int get cheerSentTotalCount =>
      _box.get(_keyCheerSentTotalCount, defaultValue: 0) as int;

  /// 오늘의 응원을 "보낸다"(실제 수신자 없이 몽이에게 맡기는 제스처). 이미
  /// 오늘 보냈으면 아무 것도 하지 않는다(호출부에서 [hasSentCheerToday]로
  /// 먼저 확인하는 게 원칙이지만, 여기서도 안전하게 한 번 더 막는다).
  Future<void> markCheerSentToday() async {
    if (hasSentCheerToday) return;
    await _box.putAll({
      _keyLastCheerSentDate: _todayString,
      _keyCheerSentTotalCount: cheerSentTotalCount + 1,
    });
  }

  /// 오늘의 응원 문구 인덱스를 저장한다(하루 한 번만 호출되도록 호출부에서 관리).
  Future<void> saveTodayCheerReceivedIndex(int index) async {
    await _box.putAll({
      _keyLastCheerReceivedDate: _todayString,
      _keyTodayCheerReceivedIndex: index,
    });
  }

  // ── 나만의 안전 계획 ("Safety Plan") ─────────────────────────

  /// 지금까지 저장된 안전 계획 내용(섹션 id -> 텍스트). 아무 것도 작성하지
  /// 않았으면 빈 맵을 반환한다. 완전히 로컬 전용 데이터로, 서버 전송이나
  /// 분석에 절대 쓰이지 않는다.
  Map<String, String> get safetyPlan {
    final raw =
        _box.get(_keySafetyPlan, defaultValue: <String, dynamic>{}) as Map;
    return raw.map((key, value) => MapEntry(key.toString(), value.toString()));
  }

  /// 안전 계획 섹션 하나를 저장/수정한다. [text]가 비어있으면 그 섹션을 지운다.
  Future<void> saveSafetyPlanSection(String sectionId, String text) async {
    final current = safetyPlan;
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      current.remove(sectionId);
    } else {
      current[sectionId] = trimmed;
    }
    await _box.put(_keySafetyPlan, current);
  }

  /// 안전 계획을 완전히 작성한 적이 있는지 여부(하나라도 내용이 있으면 true).
  bool get hasSafetyPlan => safetyPlan.isNotEmpty;

  // ── 감사 한 줄 / 작은 성취 기록 ("Gratitude Log") ─────────────────
  // 감정 다이어리(diaryEntries)는 러너 게임 세션이 끝난 뒤에만 남길 수 있는
  // 반면, 이 기록은 게임과 무관하게 하루 중 언제든 가볍게 남길 수 있는
  // "오늘 감사했던 것 / 작은 성취" 한 줄이다. 형식은 diaryEntries와 비슷하게
  // 맞춰 재사용성을 높인다.
  static const String _keyGratitudeLog =
      'gratitude_log_entries'; // List<Map> (최신이 앞에 오는 순): {date, type, text}
  static const int _maxGratitudeEntries = 200;

  /// 지금까지 남긴 감사/성취 기록(최신순). 한 항목당:
  /// {date, type(gratitude 또는 achievement), text}
  List<Map<String, dynamic>> get gratitudeEntries {
    final raw = _box.get(_keyGratitudeLog, defaultValue: <dynamic>[]) as List;
    return raw
        .whereType<Map>()
        .map((m) => m.map((key, value) => MapEntry(key.toString(), value)))
        .toList();
  }

  /// 감사(gratitude) 또는 작은 성취(achievement) 한 줄을 새로 남긴다.
  /// [text]가 공백이면 아무 것도 하지 않는다.
  Future<void> addGratitudeEntry({
    required String type,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final entries = gratitudeEntries;
    entries.insert(0, {'date': _todayString, 'type': type, 'text': trimmed});
    if (entries.length > _maxGratitudeEntries) {
      entries.removeRange(_maxGratitudeEntries, entries.length);
    }
    await _box.put(_keyGratitudeLog, entries);
  }

  /// [entryIndex]번째(최신순 인덱스) 기록을 지운다.
  Future<void> removeGratitudeEntry(int entryIndex) async {
    final entries = gratitudeEntries;
    if (entryIndex < 0 || entryIndex >= entries.length) return;
    entries.removeAt(entryIndex);
    await _box.put(_keyGratitudeLog, entries);
  }

  /// 오늘 이미 감사/성취 기록을 하나라도 남겼는지 여부(홈 화면 "오늘 남겼어요"
  /// 배지에 사용).
  bool get hasGratitudeEntryToday {
    final today = _todayString;
    return gratitudeEntries.any((e) => e['date'] == today);
  }

  // ── 몽이의 숨결 도감 (Calm/Headspace 벤치마킹) ─────────────

  /// 오늘 이미 호흡 완료 보상을 받았는지 여부(하루 1회 제한).
  bool get hasBreathingRewardToday {
    final lastDate =
        _box.get(_keyLastBreathingRewardDate, defaultValue: '') as String;
    return lastDate == _todayString;
  }

  /// 지금까지 끝까지 완료한 누적 호흡 횟수(통계용).
  int get breathingLibraryTotalCompletions =>
      _box.get(_keyBreathingLibraryTotalCompletions, defaultValue: 0) as int;

  /// 호흡 기법 하나를 끝까지 마쳤을 때 호출한다. 누적 완료 횟수는 항상
  /// 1 늘어나고, 오늘 아직 보상을 받지 않았다면 보상 자격이 있는 것으로
  /// 표시하며 날짜를 기록한다. 반환값: 오늘 처음 완료해 보상을 받을
  /// 자격이 생겼는지 여부(true면 호출부에서 빛의 정수를 지급해야 함).
  Future<bool> recordBreathingCompletion() async {
    final rewardEligible = !hasBreathingRewardToday;
    final updates = <String, dynamic>{
      _keyBreathingLibraryTotalCompletions:
          breathingLibraryTotalCompletions + 1,
    };
    if (rewardEligible) {
      updates[_keyLastBreathingRewardDate] = _todayString;
    }
    await _box.putAll(updates);
    return rewardEligible;
  }

  // ── 몽이의 마음 성찰 / 옵트인 AI 리플렉션 (벤치마킹 제안 #6) ─────────────

  /// "마음 성찰" 기능(여러 감정 기록을 종합한 리플렉션) 사용에 동의했는지
  /// 여부. 기본값은 false - 반드시 설정 화면에서 명시적으로 켜야 한다.
  bool get aiReflectionOptIn =>
      _box.get(_keyAiReflectionOptIn, defaultValue: false) as bool;

  Future<void> setAiReflectionOptIn(bool value) async {
    await _box.put(_keyAiReflectionOptIn, value);
  }
}
