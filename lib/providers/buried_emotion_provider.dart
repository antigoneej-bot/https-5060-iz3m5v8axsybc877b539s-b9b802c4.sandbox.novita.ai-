import 'package:flutter/material.dart';
import '../models/buried_emotion_entry.dart';
import '../services/buried_emotion_service.dart';

/// '그림자 방울 묻어두기'에서, 오늘 정원에 떠오른 새싹(=재부상한 묻은 감정)
/// 목록을 관리하는 Provider.
///
/// 새싹은 "미해결 알림"이 아니라 그저 조용히 나타났다가, 사용자가 원할 때만
/// 짧게 마음을 되짚어보고, 원치 않으면 조용히 사라지는 존재입니다.
class BuriedEmotionProvider extends ChangeNotifier {
  List<BuriedEmotionEntry> sprouts = [];
  bool isLoading = true;

  Future<void> load() async {
    isLoading = true;
    notifyListeners();
    sprouts = BuriedEmotionService.getPendingSprouts();
    isLoading = false;
    notifyListeners();
  }

  /// 새싹을 탭해 짧은 재기록을 남겼을 때.
  Future<void> saveReRecording(String id, String text) async {
    await BuriedEmotionService.saveReRecording(id, text);
    await load();
  }

  /// 재기록 없이 새싹을 조용히 흘려보낼 때(실패가 아닙니다).
  Future<void> skip(String id) async {
    await BuriedEmotionService.skipReRecording(id);
    await load();
  }
}
