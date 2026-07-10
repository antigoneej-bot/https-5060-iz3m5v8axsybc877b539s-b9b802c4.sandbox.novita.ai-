import 'package:flutter/material.dart';
import '../models/shadow_cat.dart';
import '../services/daily_card_service.dart';
import '../services/sound_service.dart';

enum DailyCardStage { spread, revealed }

/// 데일리 내면소통(카드뽑기) 상태를 관리하는 Provider
class DailyCardProvider extends ChangeNotifier {
  DailyCardStage stage = DailyCardStage.spread;
  ShadowCat? drawnCard;
  bool isLoading = true;
  bool alreadyDrawnToday = false;

  Future<void> load() async {
    isLoading = true;
    notifyListeners();
    final existing = await DailyCardService.getTodayCard();
    if (existing != null) {
      drawnCard = existing;
      alreadyDrawnToday = true;
      stage = DailyCardStage.revealed;
    } else {
      drawnCard = null;
      alreadyDrawnToday = false;
      stage = DailyCardStage.spread;
    }
    isLoading = false;
    notifyListeners();
  }

  /// 스프레드에서 카드를 하나 골랐을 때 호출
  Future<void> pickCard() async {
    final cat = await DailyCardService.drawCard();
    drawnCard = cat;
    alreadyDrawnToday = true;
    stage = DailyCardStage.revealed;
    await SoundService().playMeow();
    notifyListeners();
  }

  void reset() {
    stage = DailyCardStage.spread;
    drawnCard = null;
    alreadyDrawnToday = false;
    isLoading = true;
    notifyListeners();
  }
}
