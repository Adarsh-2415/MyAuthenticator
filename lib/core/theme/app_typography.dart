import 'package:flutter/material.dart';
import '../../ui/tokens/app_colors.dart';

/// Centralized typography definitions for MyAuthenticator.
abstract class AppTypography {
  static const String fontFamily = 'System';

  static TextStyle otpStyle({required bool isDark}) {
    return TextStyle(
      fontSize: 30.0,
      fontWeight: FontWeight.bold,
      letterSpacing: 2.0,
      fontFeatures: const [FontFeature.tabularFigures()],
      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
    );
  }

  static TextTheme createTextTheme({required bool isDark}) {
    final primaryColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return TextTheme(
      headlineLarge: TextStyle(
        fontSize: 28.0,
        fontWeight: FontWeight.bold,
        color: primaryColor,
      ),
      headlineMedium: TextStyle(
        fontSize: 22.0,
        fontWeight: FontWeight.w600,
        color: primaryColor,
      ),
      titleLarge: TextStyle(
        fontSize: 18.0,
        fontWeight: FontWeight.w600,
        color: primaryColor,
      ),
      titleMedium: TextStyle(
        fontSize: 16.0,
        fontWeight: FontWeight.w500,
        color: primaryColor,
      ),
      bodyLarge: TextStyle(
        fontSize: 16.0,
        fontWeight: FontWeight.normal,
        color: primaryColor,
      ),
      bodyMedium: TextStyle(
        fontSize: 14.0,
        fontWeight: FontWeight.normal,
        color: secondaryColor,
      ),
      labelLarge: TextStyle(
        fontSize: 14.0,
        fontWeight: FontWeight.w600,
        color: primaryColor,
      ),
    );
  }
}
