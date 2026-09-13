import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 마음냥 정원 - 미니멀하고 세련된 모던 파스텔 테마
/// 따뜻한 크림/아이보리 베이스 위에, 카테고리마다 서로 다른 포인트 컬러를 사용해
/// 구분감을 주되 전체적으로는 톤을 맞춘 하나의 팔레트로 통일합니다.
class AppColors {
  // 배경: 밝고 따뜻한 크림/아이보리
  static const bg0 = Color(0xFFFAF7F2); // 가장 밝은 배경 (필드, 입력창)
  static const bg1 = Color(0xFFFFFFFF); // 카드/패널 배경 (흰색)
  static const bg2 = Color(0xFFF3EADA); // 강조 표면 (활성 탭 등, 연한 크림)

  // 카드 앞면 (기존 유지 - 크림톤이라 밝은 테마와도 잘 어울림)
  static const cardFace = Color(0xFFFFFBF2);
  static const cardFace2 = Color(0xFFFCEFD2);

  // 텍스트: 밝은 배경 위에 놓일 진한 차콜/잉크 톤 (기존보다 살짝 더 차분하고 모던하게)
  static const ink = Color(0xFF383032); // 카드 위 진한 텍스트
  static const inkSoft = Color(0xFF6F625B); // 연한 보조 텍스트

  // 메인 포인트 컬러 (기존 골드 유지 - 데일리 내면소통/성장 등 핵심 액션에 사용)
  static const gold = Color(0xFFDDA24C);
  static const goldSoft = Color(0xFFB9812E);
  static const rose = Color(0xFFD97B85);

  // 'moon' : 밝은 배경 위 진한 본문 텍스트
  static const moon = Color(0xFF564C46);
  static const line = Color(0x1A383032); // 연한 반투명 보더

  // ── 카테고리 포인트 컬러 팔레트 (부드럽고 현대적인 톤으로 통일한 6색) ──
  // 명상 · 움직임 둘러보기 = 명상 → 라벤더
  static const catLavender = Color(0xFF9C8FCB);
  static const catLavenderBg = Color(0xFFF0EDFA);
  // 마음 돌보기 (밥 · 물 · 목욕 · 청소) = 힐링 → 세이지 그린
  static const catSage = Color(0xFF80A084);
  static const catSageBg = Color(0xFFEAF1EA);
  // 마음 온도 기록 보기 = 마음기록 → 더스티 로즈
  static const catDustyRose = Color(0xFFC38D96);
  static const catDustyRoseBg = Color(0xFFF9ECEE);
  // 데일리 내면소통 = 휴식 → 딥 네이비
  static const catNavy = Color(0xFF3A4664);
  static const catNavyBg = Color(0xFFE9EBF2);
  // 그림자 고양이들 (42마리 도감) = 고양이정원 → 올리브
  static const catOlive = Color(0xFF8D8C57);
  static const catOliveBg = Color(0xFFF2F0E0);
  // 오늘의 감정 고양이 만나기 = 감정케어 → 소프트 피치
  static const catPeach = Color(0xFFE79B7E);
  static const catPeachBg = Color(0xFFFCEEE5);

  // 홈 대표 타이틀용 파스텔 그린 (귀엽고 동글동글한 폰트와 함께 사용)
  static const titlePastelGreen = Color(0xFF44775B);
  static const titlePastelGreenSoft = Color(0xFFB7D9C2);

  // ── 힐링 정원 산책로 메뉴용 파스텔 블롭 컬러 (반투명 유기적 알약 카드) ──
  static const blobMint = Color(0xFFDCEEE3);
  static const blobMintAccent = Color(0xFF6FA98A);
  static const blobPeach = Color(0xFFFBE3D9);
  static const blobPeachAccent = Color(0xFFE0916E);
  static const blobLavender = Color(0xFFE8E1F5);
  static const blobLavenderAccent = Color(0xFF9C8FCB);
  static const blobRose = Color(0xFFF6E1E6);
  static const blobRoseAccent = Color(0xFFCB8896);
  static const blobButter = Color(0xFFFBF0D9);
  static const blobButterAccent = Color(0xFFC79A47);
  static const blobPeriwinkle = Color(0xFFE6E8F5);
  static const blobPeriwinkleAccent = Color(0xFF6B74A8);
}

/// 카테고리별 포인트 컬러 쌍 (아이콘 색상 + 배경색)
class CategoryColor {
  final Color accent;
  final Color background;
  const CategoryColor(this.accent, this.background);
}

/// 제목 · 섹션 헤딩용 폰트 (Gowun Dodum) - 부드럽고 동글동글하면서도
/// 가독성이 높은 라운드 한글 폰트로 전면 교체했습니다. 자간·행간을 여유롭게
/// 주어 '힐링 정원'의 느긋한 분위기를 살립니다.
TextStyle serifFont({
  double fontSize = 16,
  FontWeight? fontWeight,
  Color? color,
  double? letterSpacing,
  double? height,
}) {
  return GoogleFonts.gowunDodum(
    fontSize: fontSize,
    fontWeight: fontWeight ?? FontWeight.w400,
    color: color,
    letterSpacing: letterSpacing ?? 0.4,
    height: height ?? 1.5,
  );
}

/// 본문 · 캡션용 폰트 (Gowun Dodum, 가독성 좋은 라운드 산세리프)
/// 자간(letterSpacing)과 행간(height)을 기본보다 넓게 잡아 여유로운 느낌을 줍니다.
TextStyle bodyFont({
  double fontSize = 14,
  FontWeight? fontWeight,
  Color? color,
  double? letterSpacing,
  double? height,
}) {
  return GoogleFonts.gowunDodum(
    fontSize: fontSize,
    fontWeight: fontWeight ?? FontWeight.w400,
    color: color,
    letterSpacing: letterSpacing ?? 0.3,
    height: height ?? 1.6,
  );
}

/// 홈 대표 타이틀 · 메뉴 라벨 전용 손글씨 폰트 (Gamja Flower) - 아주
/// 동글동글하고 몽글몽글한 손글씨 느낌으로, 정원 산책로 컨셉의 표지판 글씨처럼
/// 사용합니다. 자간을 넓게 주어 손으로 쓴 듯한 여유로운 리듬을 살립니다.
TextStyle titleFont({
  double fontSize = 30,
  FontWeight? fontWeight,
  Color? color,
  double? letterSpacing,
  double? height,
}) {
  return GoogleFonts.gamjaFlower(
    fontSize: fontSize,
    fontWeight: fontWeight ?? FontWeight.w400,
    color: color,
    letterSpacing: letterSpacing ?? 0.6,
    height: height ?? 1.3,
  );
}

/// '마음냥 정원' 브랜드 워드마크 전용 폰트 (Nanum Pen Script) - 앱 안의 다른
/// 섹션 제목들(Gamja Flower)과는 결이 다른, 붓펜으로 슥 흘려 쓴 듯한 유려한
/// 필기체입니다. 스플래시 화면·홈 대표 타이틀처럼 "브랜드가 도장처럼 찍히는"
/// 자리에만 아껴서 사용해 브랜드명이 다른 제목들 사이에 묻히지 않게 합니다.
TextStyle brandFont({
  double fontSize = 32,
  FontWeight? fontWeight,
  Color? color,
  double? letterSpacing,
  double? height,
}) {
  return GoogleFonts.nanumPenScript(
    fontSize: fontSize,
    fontWeight: fontWeight ?? FontWeight.w400,
    color: color,
    letterSpacing: letterSpacing ?? 0.8,
    height: height ?? 1.2,
  );
}

/// 정원 산책로 메뉴판 라벨 전용 폰트 (Gamja Flower) - titleFont와 같은
/// 손글씨 계열이지만 메뉴 알약 카드 안의 작은 글씨에 맞춘 별칭입니다.
TextStyle pathLabelFont({
  double fontSize = 15,
  FontWeight? fontWeight,
  Color? color,
  double? letterSpacing,
  double? height,
}) {
  return GoogleFonts.gamjaFlower(
    fontSize: fontSize,
    fontWeight: fontWeight ?? FontWeight.w400,
    color: color,
    letterSpacing: letterSpacing ?? 0.4,
    height: height ?? 1.35,
  );
}

/// 숫자(스트릭, 레벨, 온도 등) 전용 폰트 - Poppins로 살짝 다른 룩을 주어
/// 한글 본문 사이에서 숫자가 더 또렷하고 모던하게 보이도록 합니다.
TextStyle numberFont({
  double fontSize = 16,
  FontWeight? fontWeight,
  Color? color,
  double? letterSpacing,
}) {
  return GoogleFonts.poppins(
    fontSize: fontSize,
    fontWeight: fontWeight ?? FontWeight.w700,
    color: color,
    letterSpacing: letterSpacing ?? -0.2,
  );
}

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: AppColors.bg0,
  textTheme: GoogleFonts.gowunDodumTextTheme(
    ThemeData.light().textTheme,
  ).apply(bodyColor: AppColors.moon, displayColor: AppColors.moon),
  colorScheme: ColorScheme.light(
    primary: AppColors.gold,
    secondary: AppColors.goldSoft,
    surface: AppColors.bg1,
  ),
  cardTheme: CardThemeData(
    color: AppColors.bg1,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: AppColors.bg1,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
  ),
);
