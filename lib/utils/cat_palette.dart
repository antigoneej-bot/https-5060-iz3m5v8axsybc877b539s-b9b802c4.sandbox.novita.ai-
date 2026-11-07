import 'package:flutter/material.dart';
import '../theme.dart';
import '../data/shadow_cats_data.dart';

/// 그림자 고양이별 고유 '브랜드 컬러'를 결정하는 공용 헬퍼.
///
/// 감정에 좋다/나쁘다 낙인을 찍는 색상 매핑(예: 분노=빨강)은 절대 쓰지 않고,
/// cat_selection_screen.dart의 카드 팔레트와 동일한 6색 파스텔 팔레트를
/// 고양이 id(=도감 내 순서)를 시드로 순환시켜 배정합니다. 같은 고양이는
/// 앱 어디서나(주간 흐름 바, 도감, 회고 화면 등) 항상 같은 색을 갖습니다.
class CatPalette {
  CatPalette._();

  static const List<Color> _accents = [
    AppColors.blobMintAccent,
    AppColors.blobPeachAccent,
    AppColors.blobLavenderAccent,
    AppColors.blobRoseAccent,
    AppColors.blobButterAccent,
    AppColors.blobPeriwinkleAccent,
  ];

  static const List<Color> _backgrounds = [
    AppColors.blobMint,
    AppColors.blobPeach,
    AppColors.blobLavender,
    AppColors.blobRose,
    AppColors.blobButter,
    AppColors.blobPeriwinkle,
  ];

  /// 고양이 id에 대응하는 도감 내 인덱스를 찾습니다(못 찾으면 id의 해시값 사용).
  static int _indexForCatId(String catId) {
    final idx = shadowCats.indexWhere((c) => c.id == catId);
    if (idx >= 0) return idx;
    return catId.hashCode.abs();
  }

  /// 고양이의 진한 포인트 색(accent). 텍스트/아이콘/보더 등에 사용합니다.
  static Color accentFor(String catId) {
    final i = _indexForCatId(catId);
    return _accents[i % _accents.length];
  }

  /// 고양이의 은은한 배경색. 카드/바 채우기 등에 사용합니다.
  static Color backgroundFor(String catId) {
    final i = _indexForCatId(catId);
    return _backgrounds[i % _backgrounds.length];
  }

  /// 기록이 없는 날/빈 상태에 쓰는 연한 회색(부정적 낙인 없는 중립색).
  static const Color emptyDay = Color(0xFFE9E4DC);
}
