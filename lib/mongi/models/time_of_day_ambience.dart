import 'package:flutter/material.dart';

/// 실제 기기 시각을 기준으로 한 "아침 정원 / 밤 정원" 분위기.
///
/// 스테이지 진행에 따라 바뀌는 [ScenePalette](게임 배경, `scenery_layer.dart`)와는
/// 완전히 별개의 레이어다. ScenePalette는 "몇 번째 스테이지인지"에 따라 하늘색이
/// 아침->한낮->노을->밤으로 진행되지만, 이 [TimeOfDayAmbience]는 "사용자가 지금
/// 실제로 몇 시에 플레이하고 있는지"를 반영해 아주 은은한 색감 오버레이와
/// 반딧불이 장식을 살짝 더해준다. 낮 시간에는 아무 변화도 주지 않아 기존
/// 스테이지 테마를 해치지 않는다.
enum TimeOfDayAmbience {
  dawn,
  day,
  night;

  static TimeOfDayAmbience fromHour(int hour) {
    if (hour >= 5 && hour < 7) return TimeOfDayAmbience.dawn;
    if (hour >= 20 || hour < 5) return TimeOfDayAmbience.night;
    return TimeOfDayAmbience.day;
  }

  /// 기기의 현재 시각(로컬 타임)을 기준으로 지금의 분위기를 계산한다.
  static TimeOfDayAmbience current() => fromHour(DateTime.now().hour);

  bool get isDay => this == TimeOfDayAmbience.day;

  String get emoji {
    switch (this) {
      case TimeOfDayAmbience.dawn:
        return '🌅';
      case TimeOfDayAmbience.night:
        return '🌙';
      case TimeOfDayAmbience.day:
        return '☀️';
    }
  }

  String get label {
    switch (this) {
      case TimeOfDayAmbience.dawn:
        return '아침 정원';
      case TimeOfDayAmbience.night:
        return '밤 정원';
      case TimeOfDayAmbience.day:
        return '';
    }
  }

  /// 게임 화면 위에 아주 얇게 덮이는 색감 오버레이 색상.
  Color get overlayColor {
    switch (this) {
      case TimeOfDayAmbience.dawn:
        return const Color(0xFFFFC8A2);
      case TimeOfDayAmbience.night:
        return const Color(0xFF1B2A55);
      case TimeOfDayAmbience.day:
        return Colors.transparent;
    }
  }

  /// 오버레이 불투명도. 너무 진하면 스테이지 팔레트를 가려버리므로 아주
  /// 은은한 값만 사용한다(밤에도 0.2를 넘지 않음).
  double get overlayAlpha {
    switch (this) {
      case TimeOfDayAmbience.dawn:
        return 0.10;
      case TimeOfDayAmbience.night:
        return 0.20;
      case TimeOfDayAmbience.day:
        return 0.0;
    }
  }

  /// 밤에만 화면에 떠다니는 반딧불이 개수(낮/새벽에는 0).
  int get fireflyCount => this == TimeOfDayAmbience.night ? 7 : 0;
}
