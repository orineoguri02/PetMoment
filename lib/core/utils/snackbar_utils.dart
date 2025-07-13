import 'package:flutter/material.dart';
import '../constants/index.dart';

class SnackbarUtils {
  static void showCustomSnackbar(BuildContext context, String message) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    double snackbarHeight = message.contains('e') ? 62 : 25;
    final snackbar = SnackBar(
      content: SizedBox(
        height: snackbarHeight,
        width: double.infinity,
        child: Center(
          child: Text(
            message,
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
        ),
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 0,
      duration: const Duration(seconds: 1),
      backgroundColor: const Color(0XFF212121),
    );
    scaffoldMessenger.showSnackBar(snackbar);
  }

  static void showSuccessSnackbar(BuildContext context, String message) {
    _showColoredSnackbar(context, message, AppColors.success);
  }

  static void showErrorSnackbar(BuildContext context, String message) {
    _showColoredSnackbar(context, message, AppColors.error);
  }

  static void showWarningSnackbar(BuildContext context, String message) {
    _showColoredSnackbar(context, message, AppColors.warning);
  }

  static void showInfoSnackbar(BuildContext context, String message) {
    _showColoredSnackbar(context, message, AppColors.info);
  }

  static void _showColoredSnackbar(BuildContext context, String message, Color backgroundColor) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final snackbar = SnackBar(
      content: Text(
        message,
        style: const TextStyle(color: Colors.white, fontSize: 15),
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 0,
      duration: const Duration(seconds: 2),
      backgroundColor: backgroundColor,
    );
    scaffoldMessenger.showSnackBar(snackbar);
  }
}

// 기존 함수와의 호환성을 위해 유지
void showCustomSnackbar(BuildContext context, String message) {
  SnackbarUtils.showCustomSnackbar(context, message);
} 