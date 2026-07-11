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

  Future<bool> addPromise(String text) async {
    final ok = await PromiseService.addPromise(text);
    if (ok) {
      entries = PromiseService.getTodayEntries();
      notifyListeners();
    }
    return ok;
  }

  /// 약속 체크(또는 해제)를 처리합니다. 체크한 순간에만(해제할 때는 제외)
  /// 리액션 문구를 노출하고, 프리미엄 유저라면 성장 보너스 신호를 함께 보냅니다.
  ///
  /// 반환값: 프리미엄 유저가 방금 체크해서 성장 보너스를 적용해야 하면 true.
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
      if (isPremium) {
        lastReaction = '하나를 지켰어요 — 고양이가 한 뼘 자랐어요 🌿';
        grantsBonus = true;
      } else {
        lastReaction = '하나를 지켰네요. 고양이가 조용히 웅크려 있어요 🐾';
      }
    } else {
      lastReaction = null;
    }
    notifyListeners();
    return grantsBonus;
  }

  void clearReaction() {
    lastReaction = null;
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
    notifyListeners();
  }
}
