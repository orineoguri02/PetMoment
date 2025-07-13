import 'package:flutter/material.dart';

class AppColors {
  // 기본 색상
  static const Color primary = Color(0XFFE94A39);
  static const Color secondary = Color(0XFF693E32);
  static const Color seedColor = Color(0XFFE65951);
  
  // 배경 색상
  static const Color scaffoldBackground = Colors.white;
  static const Color appBarBackground = Colors.white;
  static const Color dialogBackground = Colors.white;
  
  // 텍스트 색상
  static const Color textPrimary = Colors.black;
  static const Color textSecondary = Colors.grey;
  static const Color textWhite = Colors.white;
  static const Color textHint = Colors.grey;
  
  // 버튼 색상
  static const Color buttonPrimary = Color(0XFFE94A39);
  static const Color buttonSecondary = Colors.grey;
  static const Color buttonDisabled = Color(0xFFE0E0E0);
  
  // 상태 색상
  static const Color success = Colors.green;
  static const Color error = Colors.red;
  static const Color warning = Colors.orange;
  static const Color info = Colors.blue;
  
  // 투명도 색상
  static const Color transparent = Colors.transparent;
  static const Color blackOverlay = Color(0x99000000);
  static const Color whiteOverlay = Color(0x99FFFFFF);
  
  // 그라데이션 색상
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // 그림자 색상
  static const Color shadowColor = Color(0x1A000000);
  static const Color cardShadow = Color(0x0F000000);
  
  // 테마별 색상 구성
  static ColorScheme get lightColorScheme => ColorScheme.fromSeed(
    seedColor: seedColor,
    primary: primary,
    secondary: secondary,
    brightness: Brightness.light,
  );
  
  static ColorScheme get darkColorScheme => ColorScheme.fromSeed(
    seedColor: seedColor,
    primary: primary,
    secondary: secondary,
    brightness: Brightness.dark,
  );
} 