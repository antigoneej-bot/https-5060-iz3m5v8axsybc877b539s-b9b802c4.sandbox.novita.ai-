import 'package:flutter/material.dart';

/// "정원의 계절 변화" - 실제 달력의 월(1~12월)을 기준으로 정원 씬에 계절감을
/// 은은하게 입힌다. 서버/AI/저장소 없이 [DateTime.now]만으로 계산하는 순수
/// 함수라서, 유저가 아무것도 하지 않아도 정원이 "그날그날 살아있는 곳"처럼
/// 느껴지게 하는 가장 저비용의 장치다.
///
/// 새로운 배경 이미지를 새로 그리는 대신, 기존 [GardenSceneView] 위에
/// 계절별 색 틴트(ColorFilter)와 가벼운 파티클(꽃잎/반짝임/낙엽/눈)만
/// 오버레이해서 "같은 정원인데 계절이 다르다"는 느낌을 낸다.
enum GardenSeason {
  spring,
  summer,
  autumn,
  winter;

  /// 달력 월(1~12)을 기준으로 계절을 계산한다(북반구 기준, 앱이 한국어
  /// 전용이므로 한국 절기감에 맞춘다). 3-5월 봄, 6-8월 여름, 9-11월 가을,
  /// 12-2월 겨울.
  static GardenSeason fromMonth(int month) {
    if (month >= 3 && month <= 5) return GardenSeason.spring;
    if (month >= 6 && month <= 8) return GardenSeason.summer;
    if (month >= 9 && month <= 11) return GardenSeason.autumn;
    return GardenSeason.winter;
  }

  static GardenSeason get current => fromMonth(DateTime.now().month);

  String get label {
    switch (this) {
      case GardenSeason.spring:
        return '봄';
      case GardenSeason.summer:
        return '여름';
      case GardenSeason.autumn:
        return '가을';
      case GardenSeason.winter:
        return '겨울';
    }
  }

  String get emoji {
    switch (this) {
      case GardenSeason.spring:
        return '🌸';
      case GardenSeason.summer:
        return '☀️';
      case GardenSeason.autumn:
        return '🍁';
      case GardenSeason.winter:
        return '❄️';
    }
  }

  /// 정원 씬 위에 얹을 은은한 색 틴트 - 배경 이미지를 새로 그리지 않고도
  /// 계절 분위기를 낸다. alpha가 낮아 원래 그림을 거의 가리지 않는다.
  Color get tintColor {
    switch (this) {
      case GardenSeason.spring:
        return const Color(0xFFFFC1D9); // 연분홍 (벚꽃)
      case GardenSeason.summer:
        return const Color(0xFF7FE0D6); // 청록 (싱그러움)
      case GardenSeason.autumn:
        return const Color(0xFFE0A72E); // 주황 (단풍)
      case GardenSeason.winter:
        return const Color(0xFFAFD8FF); // 옅은 파랑 (눈)
    }
  }

  double get tintAlpha {
    switch (this) {
      case GardenSeason.spring:
        return 0.10;
      case GardenSeason.summer:
        return 0.07;
      case GardenSeason.autumn:
        return 0.12;
      case GardenSeason.winter:
        return 0.14;
    }
  }

  /// 떠다니는 파티클 하나의 이모지 - 계절마다 다른 것이 흩날린다.
  String get particleEmoji {
    switch (this) {
      case GardenSeason.spring:
        return '🌸';
      case GardenSeason.summer:
        return '✨';
      case GardenSeason.autumn:
        return '🍂';
      case GardenSeason.winter:
        return '❄️';
    }
  }

  /// 화면에 동시에 떠다니는 파티클 개수 - 너무 많으면 정원이 정신없어
  /// 보이므로 계절마다 은은한 정도로만 조절한다.
  int get particleCount {
    switch (this) {
      case GardenSeason.spring:
        return 7;
      case GardenSeason.summer:
        return 5;
      case GardenSeason.autumn:
        return 6;
      case GardenSeason.winter:
        return 8;
    }
  }

  /// 정원 화면 상단에 계절을 살짝 알려주는 한 줄 문구.
  String get greetingLine {
    switch (this) {
      case GardenSeason.spring:
        return '몽이의 정원에 벚꽃이 흩날리고 있어요';
      case GardenSeason.summer:
        return '몽이의 정원이 싱그러운 여름빛으로 반짝여요';
      case GardenSeason.autumn:
        return '몽이의 정원에 낙엽이 살랑살랑 내려요';
      case GardenSeason.winter:
        return '몽이의 정원에 눈이 소복하게 쌓이고 있어요';
    }
  }
}
