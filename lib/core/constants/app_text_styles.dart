import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_constants.dart';

class AppTextStyles {
  // 기본 텍스트 스타일
  static const TextStyle _baseStyle = TextStyle(
    fontFamily: AppConstants.pretendardFont,
    color: AppColors.textPrimary,
  );
  
  // 제목 스타일
  static TextStyle get heading1 => _baseStyle.copyWith(
    fontSize: 32,
    fontWeight: FontWeight.bold,
  );
  
  static TextStyle get heading2 => _baseStyle.copyWith(
    fontSize: 28,
    fontWeight: FontWeight.bold,
  );
  
  static TextStyle get heading3 => _baseStyle.copyWith(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );
  
  static TextStyle get heading4 => _baseStyle.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );
  
  static TextStyle get heading5 => _baseStyle.copyWith(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );
  
  static TextStyle get heading6 => _baseStyle.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );
  
  // 본문 스타일
  static TextStyle get bodyLarge => _baseStyle.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.normal,
  );
  
  static TextStyle get bodyMedium => _baseStyle.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.normal,
  );
  
  static TextStyle get bodySmall => _baseStyle.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.normal,
  );
  
  // 버튼 스타일
  static TextStyle get buttonLarge => _baseStyle.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textWhite,
  );
  
  static TextStyle get buttonMedium => _baseStyle.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textWhite,
  );
  
  static TextStyle get buttonSmall => _baseStyle.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textWhite,
  );
  
  // 캡션 스타일
  static TextStyle get caption => _baseStyle.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );
  
  // 라벨 스타일
  static TextStyle get label => _baseStyle.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );
  
  // 앱바 제목 스타일
  static TextStyle get appBarTitle => _baseStyle.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );
  
  // 특별 스타일
  static TextStyle get splashTitle => _baseStyle.copyWith(
    fontSize: 30,
    fontWeight: FontWeight.w900,
    color: AppColors.textWhite,
  );
  
  static TextStyle get splashSubtitle => _baseStyle.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textWhite,
  );
  
  // 에러 스타일
  static TextStyle get error => _baseStyle.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.error,
  );
  
  // 성공 스타일
  static TextStyle get success => _baseStyle.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.success,
  );
  
  // 링크 스타일
  static TextStyle get link => _baseStyle.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.primary,
    decoration: TextDecoration.underline,
  );
  
  // 힌트 스타일
  static TextStyle get hint => _baseStyle.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textHint,
  );
  
  // 폰트별 스타일
  static TextStyle get hsYuji => _baseStyle.copyWith(
    fontFamily: AppConstants.hsYujiFont,
    fontSize: 16,
  );
  
  static TextStyle get bagel => _baseStyle.copyWith(
    fontFamily: AppConstants.bagelFont,
    fontSize: 16,
  );
} 