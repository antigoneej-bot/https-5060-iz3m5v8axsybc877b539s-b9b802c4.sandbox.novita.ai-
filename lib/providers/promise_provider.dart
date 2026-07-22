import 'package:flutter/material.dart';
import '../models/promise_entry.dart';
import '../services/promise_service.dart';
import '../services/subscription_service.dart';
import '../services/sound_service.dart';

/// "오늘의 약속" 상태를 화면에 공급하는 Provider.
/// 무료/프리미엄 유저에 따라 약속을 지켰을 때의 반응(리액션 문구·성장 보너스)이
/// 달라지므로, 이 Provider가 [SubscriptionService]를 참조해 분기 처리합니다.
class PromiseProvider extends ChangeNotifier {
  List<PromiseEntry> entries = [];
  bool isLoading = true;
  bool isPremium = false;

  /// 방금 하나를 지켰을 때 보여줄 짧은 리액션 문구. 애니메이션 없이 텍스트만
  /// 노출되며, 다음 액션이 있을 때까지 유지되다가 [clearReaction]으로 지웁니다.
  String? lastReaction;

  /// 오늘 남긴 약속을 모두 지켰을 때 보여줄 "완료" 축하 메시지.
  /// null이 아니면 화면에서 골골송 + 반짝이는 효과를 보여줍니다.
  String? allKeptCelebrationMessage;

  Future<void> load() async {
    isLoading = true;
    notifyListeners();
    await PromiseService.purgeStaleEntries();
    entries = PromiseService.getTodayEntries();
    isPremium = await SubscriptionService().isPremium();
    isLoading = false;
    notifyListeners();
  }

  bool get canAddMore => entries.length < PromiseService.maxPerDay;

  int get keptCount => entries.where((e) => e.kept).length;

  /// 오늘 남긴 약속이 하나라도 있고, 그 전부를 지켰는지 여부.
  /// true가 되는 순간 화면 하단에 "완료" 버튼이 나타납니다.
  bool get allKept => entries.isNotEmpty && entries.every((e) => e.kept);

  /// 이미 오늘의 "완료"를 누른 적이 있는지(같은 날 여러 번 축하 효과가
  /// 반복되지 않도록 하는 플래그). 약속을 다시 해제하면 false로 되돌아가,
  /// 다시 전부 지켰을 때 새로 축하할 수 있습니다.
  bool _celebratedToday = false;

  Future<bool> addPromise(String text) async {
    final ok = await PromiseService.addPromise(text);
    if (ok) {
      entries = PromiseService.getTodayEntries();
      notifyListeners();
    }
    return ok;
  }

  /// 약속 체크(또는 해제)를 처리합니다. 체크한 순간에만(해제할 때는 제외)
  /// 리액션 문구를 노출하고, 마음 온도 보너스 신호를 함께 보냅니다. 약속을
  /// 지키는 기쁨은 구독 여부와 무관하므로, 누구나 약속 하나를 지킬 때마다
  /// 마음 온도가 1도씩 오릅니다(100도 초과 시 포인트 적립은 구독자 전용).
  ///
  /// 반환값: 방금 체크해서 성장 보너스(+1도)를 적용해야 하면 true.
  /// (실제 온도 적립/성장 애니메이션은 화면에서 CatCareProvider를 통해 처리)
  Future<bool> toggleKept(String id) async {
    final idx = entries.indexWhere((e) => e.id == id);
    if (idx == -1) return false;
    final current = entries[idx];
    final newKept = !current.kept;
    await PromiseService.setKept(id, newKept);
    entries = PromiseService.getTodayEntries();

    bool grantsBonus = false;
    if (newKept) {
      await SoundService().playChime();
      lastReaction = '하나를 지켰어요 — 고양이가 한 뼘 자랐어요 🌿';
      grantsBonus = true;
    } else {
      lastReaction = null;
      // 약속을 다시 해제했다면, 다음에 전부 지켰을 때 다시 축하할 수 있도록
      // 완료 축하 플래그를 초기화합니다.
      _celebratedToday = false;
    }
    notifyListeners();
    return grantsBonus;
  }

  void clearReaction() {
    lastReaction = null;
    notifyListeners();
  }

  /// 오늘 남긴 약속을 모두 지킨 뒤 "완료" 버튼을 눌렀을 때 호출합니다.
  /// 골골송 사운드를 재생하고, 화면에 반짝이는 축하 효과와 함께 보여줄
  /// 메시지를 세팅합니다.
  Future<void> celebrateAllKept() async {
    if (!allKept || _celebratedToday) return;
    _celebratedToday = true;
    await SoundService().playPurr();
    allKeptCelebrationMessage = '골골골... 오늘의 약속을 모두 지켰어요! 정말 잘했어요 😽✨';
    notifyListeners();
  }

  void clearAllKeptCelebration() {
    allKeptCelebrationMessage = null;
    notifyListeners();
  }

  Future<void> deletePromise(String id) async {
    await PromiseService.deletePromise(id);
    entries = PromiseService.getTodayEntries();
    notifyListeners();
  }

  /// 저녁 "하루 닫기"에서 쓸 요약 문구. 무료/프리미엄 모두에게 노출됩니다.
  String get eveningSummary {
    if (entries.isEmpty) return '오늘은 나를 위한 약속을 남기지 않았어요';
    return '오늘 ${entries.length}가지 중 $keptCount가지를 지켰어요';
  }

  void reset() {
    entries = [];
    isLoading = true;
    lastReaction = null;
    allKeptCelebrationMessage = null;
    _celebratedToday = false;
    notifyListeners();
  }
}
