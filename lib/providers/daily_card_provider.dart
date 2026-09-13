import 'dart:async';

import 'package:flutter/material.dart';
import '../models/shadow_cat.dart';
import '../services/daily_card_service.dart';
import '../services/sound_service.dart';

/// shuffling: 카드가 뒤섞이는 3초 연출(셔플 사운드와 함께) 단계
/// spread: 부채꼴로 펼쳐진 카드 중 한 장을 고르는 단계
/// revealed: 고른 카드가 뒤집혀 결과를 보여주는 단계
enum DailyCardStage { shuffling, spread, revealed }

/// 데일리 내면소통(카드뽑기) 상태를 관리하는 Provider
class DailyCardProvider extends ChangeNotifier {
  DailyCardStage stage = DailyCardStage.shuffling;
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
      stage = DailyCardStage.shuffling;
      // UI 먼저, 셔플 사운드는 뒤에
      unawaited(SoundService().playShuffle());
    }
    isLoading = false;
    notifyListeners();
  }

  /// 셔플 연출(3초)이 끝났을 때 호출 - 카드를 고를 수 있는 스프레드 단계로 전환
  void finishShuffle() {
    if (stage != DailyCardStage.shuffling) return;
    stage = DailyCardStage.spread;
    notifyListeners();
  }

  /// 스프레드에서 카드를 하나 골랐을 때 호출
  Future<void> pickCard() async {
    final cat = await DailyCardService.drawCard();
    drawnCard = cat;
    alreadyDrawnToday = true;
    stage = DailyCardStage.revealed;
    notifyListeners();
    unawaited(SoundService().playMeow());
  }

  void reset() {
    stage = DailyCardStage.shuffling;
    drawnCard = null;
    alreadyDrawnToday = false;
    isLoading = true;
    notifyListeners();
  }
}
