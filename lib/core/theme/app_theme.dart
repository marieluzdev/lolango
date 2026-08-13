import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lolango_v2/core/constants/app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryLight,
        primary: AppColors.primaryLight,
        onPrimary: Colors.black,
        secondary: AppColors.secondaryLight,
        background: AppColors.backgroundLight,
        surface: AppColors.surfaceLight,
        error: AppColors.errorLight,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.backgroundLight,
      canvasColor: AppColors.backgroundLight,
      textTheme: GoogleFonts.familjenGroteskTextTheme(ThemeData.light().textTheme).apply(
        bodyColor: AppColors.textPrimaryLight,
        displayColor: AppColors.textPrimaryLight,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceLight,
        foregroundColor: AppColors.textPrimaryLight,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark, // icônes noires (light mode)
          statusBarBrightness: Brightness.light,    // iOS
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryDark,
        primary: AppColors.primaryDark,
        onPrimary: Colors.black,
        secondary: AppColors.secondaryDark,
        background: AppColors.backgroundDark,
        surface: AppColors.surfaceDark,
        error: AppColors.errorDark,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: AppColors.backgroundDark,
      canvasColor: AppColors.backgroundDark,
      textTheme: GoogleFonts.familjenGroteskTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: AppColors.textPrimaryDark,
        displayColor: AppColors.textPrimaryDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: AppColors.textPrimaryDark,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light, // icônes blanches (dark mode)
          statusBarBrightness: Brightness.dark,       // iOS
        ),
      ),
    );
  }
}
