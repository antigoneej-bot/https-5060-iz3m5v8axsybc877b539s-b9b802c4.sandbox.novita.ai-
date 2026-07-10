import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 고양이 그림자 정원 - 미니멀하고 세련된 모던 파스텔 테마
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
  static const inkSoft = Color(0xFF9A8F86); // 연한 보조 텍스트

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
  // 그림자 고양이들 (36마리 도감) = 고양이정원 → 올리브
  static const catOlive = Color(0xFF8D8C57);
  static const catOliveBg = Color(0xFFF2F0E0);
  // 오늘의 감정 고양이 만나기 = 감정케어 → 소프트 피치
  static const catPeach = Color(0xFFE79B7E);
  static const catPeachBg = Color(0xFFFCEEE5);

  // 홈 대표 타이틀용 파스텔 그린 (귀엽고 동글동글한 폰트와 함께 사용)
  static const titlePastelGreen = Color(0xFF8FBFA0);
  static const titlePastelGreenSoft = Color(0xFFB7D9C2);
}

/// 카테고리별 포인트 컬러 쌍 (아이콘 색상 + 배경색)
class CategoryColor {
  final Color accent;
  final Color background;
  const CategoryColor(this.accent, this.background);
}

/// 제목 · 섹션 헤딩용 폰트 (Noto Sans KR, 굵고 또렷하여 위계가 잘 드러남)
TextStyle serifFont({
  double fontSize = 16,
  FontWeight? fontWeight,
  Color? color,
  double? letterSpacing,
  double? height,
}) {
  return GoogleFonts.notoSansKr(
    fontSize: fontSize,
    fontWeight: fontWeight ?? FontWeight.w700,
    color: color,
    letterSpacing: letterSpacing ?? -0.2,
    height: height,
  );
}

/// 본문 · 캡션용 폰트 (Noto Sans KR, 가독성 좋은 모던 산세리프)
TextStyle bodyFont({
  double fontSize = 14,
  FontWeight? fontWeight,
  Color? color,
  double? letterSpacing,
  double? height,
}) {
  return GoogleFonts.notoSansKr(
    fontSize: fontSize,
    fontWeight: fontWeight ?? FontWeight.w400,
    color: color,
    letterSpacing: letterSpacing ?? 0.1,
    height: height ?? 1.4,
  );
}

/// 홈 대표 타이틀 전용 폰트 (Jua) - 동글동글하고 귀여운 손글씨 느낌의
/// 한글 라운드 폰트로, 앱 대표 문구("고양이 그림자 정원")에만 사용합니다.
TextStyle titleFont({
  double fontSize = 30,
  FontWeight? fontWeight,
  Color? color,
  double? letterSpacing,
  double? height,
}) {
  return GoogleFonts.jua(
    fontSize: fontSize,
    fontWeight: fontWeight ?? FontWeight.w400,
    color: color,
    letterSpacing: letterSpacing ?? 0,
    height: height,
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
  textTheme: GoogleFonts.notoSansKrTextTheme(
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
