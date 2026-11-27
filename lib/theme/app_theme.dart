import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Figma 시안(리드메이트 완독 습관 앱)에서 추출한 색상 토큰
class AppColors {
  static const background = Color(0xFFFBF1DC); // 화면 배경 (따뜻한 크림)
  static const sun = Color(0xFFEFC49F); // 햇살 배경 / 선택 강조
  static const text = Color(0xFF4A3A28); // 기본 텍스트
  static const subText = Color(0xFF786A52); // 보조 텍스트
  static const primary = Color(0xFF8C5A36); // 주요 버튼(갈색)
  static const card = Color(0xFFFFFBEF); // 카드/입력칸
  static const border = Color(0xFFEFD8B4); // 입력칸 테두리
  static const beige = Color(0xFFF5E3BD); // 진행 막대 배경, 세그먼트 배경
  static const green = Color(0xFF7FA24A); // 진행 막대, 스위치
  static const link = Color(0xFF2F6BC4); // 파란 링크
  static const shelf = Color(0xFFC69062); // 책장 나무
  static const tan = Color(0xFFDDAB82); // 책상, 빈 자리 테두리
  static const spine = Color(0xFF86A1AB); // 진행 책 책등
  static const checkbox = Color(0xFFC5CF9E);

  // ---- 동화풍 서재 리디자인 팔레트 ----
  static const cream = Color(0xFFFBF1DC); // 벽(배경)
  static const sage = Color(0xFF8FAE6B); // 세이지 그린 (강조, 진행률)
  static const sageDark = Color(0xFF6F8F4A); // 세이지 그린 (글자)
  static const sageLight = Color(0xFFDCE8C8);
  static const pink = Color(0xFFF4C6C6); // 파스텔 핑크
  static const blue = Color(0xFFB9CBEA); // 파스텔 블루
  static const woodLight = Color(0xFFE8C79E); // 책장 나무(밝은)
  static const wood = Color(0xFFD2A574); // 책장 나무
  static const woodDark = Color(0xFFAE7C4E); // 책장 테두리·선반
  static const shelfInner = Color(0xFFF8ECD6); // 책장 칸 안쪽
  static const desk = Color(0xFFE2BE8E); // 책상

  /// 카드·버튼 공통 부드러운 그림자
  static List<BoxShadow> softShadow([double strength = 1]) => [
        BoxShadow(
          color: const Color(0xFF8C6633).withValues(alpha: 0.10 * strength),
          offset: const Offset(0, 8),
          blurRadius: 24,
        ),
        BoxShadow(
          color: const Color(0xFF8C6633).withValues(alpha: 0.06 * strength),
          offset: const Offset(0, 2),
          blurRadius: 6,
        ),
      ];

  /// 표지 색 팔레트 (02 책 쌓아 두기)
  static const bookColors = <Color>[
    Color(0xFFC5D6A8), // 세이지
    Color(0xFFD7C3E6), // 라벤더
    Color(0xFFF4C6C6), // 핑크
    Color(0xFFB9CBEA), // 블루
    Color(0xFFF7E4AF), // 버터
    Color(0xFFF3CDB0), // 피치
  ];
}

/// 텍스트 스타일 (Noto Sans KR / 말풍선은 Gaegu)
class AppText {
  static TextStyle _noto(double size, FontWeight w, [Color c = AppColors.text]) =>
      GoogleFonts.notoSansKr(fontSize: size, fontWeight: w, color: c, height: 1.35);

  static TextStyle get title => _noto(26, FontWeight.w700); // 큰 제목
  static TextStyle get heading => _noto(20, FontWeight.w700);
  static TextStyle get bodyBold => _noto(16, FontWeight.w700);
  static TextStyle get label => _noto(14, FontWeight.w500);
  static TextStyle get subLabel => _noto(14, FontWeight.w500, AppColors.subText);
  static TextStyle get body => _noto(14, FontWeight.w400);
  static TextStyle get bodySub => _noto(14, FontWeight.w400, AppColors.subText);
  static TextStyle get caption => _noto(12, FontWeight.w400, AppColors.subText);
  static TextStyle get timer => _noto(64, FontWeight.w500);
  static TextStyle get bubble => _noto(15, FontWeight.w700); // 말풍선 (본문과 같은 Noto Sans KR)
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      surface: AppColors.background,
    ),
  );
  return base.copyWith(
    textTheme: GoogleFonts.notoSansKrTextTheme(base.textTheme)
        .apply(bodyColor: AppColors.text, displayColor: AppColors.text),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.text,
    ),
  );
}
