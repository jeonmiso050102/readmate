import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Figma 시안(리드메이트 완독 습관 앱)에서 추출한 색상 토큰
class AppColors {
  static const background = Color(0xFFFCF6D7); // 화면 배경
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

  /// 표지 색 팔레트 (02 책 쌓아 두기)
  static const bookColors = <Color>[
    Color(0xFFC5CF9E),
    Color(0xFFD0ABC5),
    Color(0xFFF9BDA6),
    Color(0xFFA1B5DB),
    Color(0xFFF7E4AF),
    Color(0xFFE1A2A5),
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
