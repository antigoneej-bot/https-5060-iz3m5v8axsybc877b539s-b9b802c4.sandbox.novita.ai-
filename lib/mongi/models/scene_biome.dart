import 'package:flutter/material.dart';

/// 스테이지가 오를수록 배경 테마 자체가 완전히 바뀌는 "지역(바이옴)" 시스템.
///
/// 시간대([TimeOfDayAmbience])나 스테이지 진행에 따른 하늘 조명
/// ([ScenePalette], scenery_layer.dart)과는 완전히 별개의 축이다. 저 둘은
/// "몇 시인지" / "몇 단계인지"에 따라 하늘색이 아침->한낮->노을->밤으로
/// 은은하게 바뀌는 반면, 이 [SceneBiome]은 "몽이가 지금 어떤 풍경 속을
/// 달리고 있는지" 자체를 바꾼다 - 벚꽃마을 -> 한옥마을 -> 대나무숲 -> 고요한
/// 산사를 순환하며 매 몇 단계마다 완전히 새로운, 한국적인 무대에서 뛰는 듯한
/// 신선함을 준다. (아침의 산사, 밤의 한옥마을처럼 두 축이 자유롭게 조합된다.)
enum SceneBiome {
  garden,
  city,
  ocean,
  mountain;

  /// 스테이지 몇 개당 배경이 한 번씩 바뀌는지.
  static const int stagesPerBiome = 2;

  static SceneBiome forStage(int stage) {
    final idx = ((stage - 1) ~/ stagesPerBiome) % values.length;
    return values[idx];
  }

  String get emoji {
    switch (this) {
      case SceneBiome.garden:
        return '🌸';
      case SceneBiome.city:
        return '🏮';
      case SceneBiome.ocean:
        return '🎋';
      case SceneBiome.mountain:
        return '⛰️';
    }
  }

  /// 지역 이름. 한국적인 사계절/풍경 테마로 구성되어 있다.
  String get label {
    switch (this) {
      case SceneBiome.garden:
        return '벚꽃마을';
      case SceneBiome.city:
        return '한옥마을';
      case SceneBiome.ocean:
        return '대나무숲';
      case SceneBiome.mountain:
        return '고요한 산사';
    }
  }

  /// 배경 실루엣(언덕/기와지붕/대나무/산봉우리)의 기본 색.
  Color get backdropColor {
    switch (this) {
      case SceneBiome.garden:
        return const Color(0xFF8FC48A);
      case SceneBiome.city:
        return const Color(0xFF56606E);
      case SceneBiome.ocean:
        return const Color(0xFF6FA35E);
      case SceneBiome.mountain:
        return const Color(0xFF8B8477);
    }
  }

  /// 실루엣 위에 얹는 포인트 색(벚꽃 캐노피 / 처마 밑 홍등 / 대나무 잎 / 산사
  /// 눈덮인 봉우리 등).
  Color get accentColor {
    switch (this) {
      case SceneBiome.garden:
        return const Color(0xFFFFD6E8);
      case SceneBiome.city:
        return const Color(0xFFFF7A45);
      case SceneBiome.ocean:
        return const Color(0xFFCFE8A0);
      case SceneBiome.mountain:
        return const Color(0xFFF4F1EA);
    }
  }

  /// 길 옆에 스쳐 지나가는 작은 소품(벚꽃나무/홍등/대나무 잎/돌탑)의 색.
  Color get decorColor {
    switch (this) {
      case SceneBiome.garden:
        return const Color(0xFFFF9EC4);
      case SceneBiome.city:
        return const Color(0xFFB33B3B);
      case SceneBiome.ocean:
        return const Color(0xFF7BB369);
      case SceneBiome.mountain:
        return const Color(0xFF9C948A);
    }
  }
}
