import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.darkBackground,
    colorScheme: const ColorScheme.dark(
      surface: AppColors.darkSurface,
      primary: AppColors.darkAccent,
      error: AppColors.danger,
    ),
    textTheme: _buildTextTheme(AppColors.darkPrimaryText),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkBackground,
      foregroundColor: AppColors.darkPrimaryText,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        color: AppColors.darkPrimaryText,
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
    ),
    dividerColor: AppColors.darkBorder,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    cardColor: AppColors.darkSurface,
    inputDecorationTheme: _buildInputDecoration(
      AppColors.darkSurface,
      AppColors.darkSecondary,
    ),
  );

  static ThemeData get light => ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.lightBackground,
    colorScheme: const ColorScheme.light(
      surface: AppColors.lightSurface,
      primary: AppColors.lightAccent,
      error: AppColors.danger,
    ),
    textTheme: _buildTextTheme(AppColors.lightPrimaryText),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.lightBackground,
      foregroundColor: AppColors.lightPrimaryText,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        color: AppColors.lightPrimaryText,
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
    ),
    dividerColor: AppColors.lightBorder,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    cardColor: AppColors.lightSurface,
    inputDecorationTheme: _buildInputDecoration(
      AppColors.lightSurface,
      AppColors.lightSecondary,
    ),
  );

  static TextTheme _buildTextTheme(Color baseColor) => TextTheme(
    displayLarge: AppTextStyles.largeTitle.copyWith(color: baseColor),
    displayMedium: AppTextStyles.title1.copyWith(color: baseColor),
    displaySmall: AppTextStyles.title2.copyWith(color: baseColor),
    headlineMedium: AppTextStyles.title3.copyWith(color: baseColor),
    titleLarge: AppTextStyles.headline.copyWith(color: baseColor),
    bodyLarge: AppTextStyles.body.copyWith(color: baseColor),
    bodyMedium: AppTextStyles.callout.copyWith(color: baseColor),
    bodySmall: AppTextStyles.subheadline.copyWith(color: baseColor),
    labelLarge: AppTextStyles.footnote.copyWith(color: baseColor),
    labelSmall: AppTextStyles.caption.copyWith(color: baseColor),
  );

  static InputDecorationTheme _buildInputDecoration(
    Color fill,
    Color hint,
  ) => InputDecorationTheme(
    filled: true,
    fillColor: fill,
    hintStyle: TextStyle(color: hint),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.darkAccent, width: 0.5),
    ),
  );
}
