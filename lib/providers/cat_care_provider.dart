import 'package:flutter/material.dart';
import '../models/cat_care_state.dart';
import '../services/cat_care_service.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../data/shadow_cats_data.dart';

/// 다마고치식 '마음 돌보기' 상태를 화면에 공급하는 Provider
class CatCareProvider extends ChangeNotifier {
  CatCareState state = CatCareState(
    temperature: CatCareService.startTemperature,
    fedToday: false,
    wateredToday: false,
    bathedToday: false,
    cleanedToday: false,
    companionCatId: shadowCats.first.id,
    growthDays: 0,
  );
  bool isLoading = true;

  /// 웰컴 투어에서 사용자가 지어준 아기고양이의 이름. 없으면 null.
  String? companionName;

  /// 방금 성장 단계가 올라간 경우, 새로 도달한 단계. 레벨업 애니메이션을
  /// 보여준 뒤 [clearLevelUp]으로 비워줍니다. 평소에는 null.
  CatGrowthStage? justReachedStage;

  void clearLevelUp() {
    justReachedStage = null;
  }

  Future<void> load() async {
    isLoading = true;
    notifyListeners();
    state = await CatCareService.loadAndApplyDailyDecay(
      defaultCompanionCatId: shadowCats.first.id,
    );
    companionName = await StorageService.getCompanionName();
    isLoading = false;
    notifyListeners();
  }

  /// 이름이 지어져 있으면 이름을, 없으면 기본 문구를 반환합니다.
  String get displayName =>
      (companionName != null && companionName!.trim().isNotEmpty)
      ? companionName!.trim()
      : '아기 고양이';

  Future<void> _complete(CareTask task) async {
    final prevStage = state.growthStage;
    state = await CatCareService.completeTask(task);
    await SoundService().playMeow();
    final newStage = state.growthStage;
    if (newStage != prevStage) {
      // 성장 단계가 올라간 순간 - 화면에서 레벨업 애니메이션을 띄울 수 있도록 표시
      justReachedStage = newStage;
    }
    notifyListeners();
  }

  Future<void> feed() => _complete(CareTask.feed);
  Future<void> water() => _complete(CareTask.water);
  Future<void> bath() => _complete(CareTask.bath);
  Future<void> clean() => _complete(CareTask.clean);
  Future<void> breathing() => _complete(CareTask.breathing);
  Future<void> walking() => _complete(CareTask.walking);
  Future<void> journaling() => _complete(CareTask.journaling);
  Future<void> gratitude() => _complete(CareTask.gratitude);

  Future<void> setCompanionCat(String catId) async {
    await CatCareService.setCompanionCat(catId);
    state = CatCareState(
      temperature: state.temperature,
      fedToday: state.fedToday,
      wateredToday: state.wateredToday,
      bathedToday: state.bathedToday,
      cleanedToday: state.cleanedToday,
      breathingDoneToday: state.breathingDoneToday,
      walkingDoneToday: state.walkingDoneToday,
      journalingDoneToday: state.journalingDoneToday,
      gratitudeDoneToday: state.gratitudeDoneToday,
      companionCatId: catId,
      growthDays: state.growthDays,
    );
    notifyListeners();
  }

  void reset() {
    state = CatCareState(
      temperature: CatCareService.startTemperature,
      fedToday: false,
      wateredToday: false,
      bathedToday: false,
      cleanedToday: false,
      companionCatId: shadowCats.first.id,
      growthDays: 0,
    );
    isLoading = true;
    notifyListeners();
  }
}
