import 'package:flutter/material.dart';
import 'package:bookease/core/constants/app_colors.dart';
import 'package:bookease/core/theme/app_text_styles.dart';

/// Light and dark themes. Visual values are unchanged from the original app;
/// the duplicated builder code is now shared.
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      secondary: AppColors.accentTeal,
      surface: AppColors.surfaceLight,
    );

    return _build(
      colorScheme: colorScheme,
      textTheme: AppTextStyles.textTheme(),
      scaffoldColor: AppColors.surfaceLight,
      cardColor: AppColors.cardLight,
      cardBorderColor: Colors.grey.withAlpha(25),
      buttonColor: AppColors.primary,
      inputFill: Colors.white,
      inputBorderColor: Colors.grey.withAlpha(50),
      focusColor: AppColors.primary,
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      primary: AppColors.primaryDark,
      secondary: AppColors.accentTealDark,
      surface: AppColors.surfaceDark,
    );

    return _build(
      colorScheme: colorScheme,
      textTheme: AppTextStyles.textTheme(ThemeData.dark().textTheme),
      scaffoldColor: AppColors.surfaceDark,
      cardColor: AppColors.cardDark,
      cardBorderColor: Colors.white.withAlpha(15),
      buttonColor: AppColors.buttonDark,
      inputFill: AppColors.cardDark,
      inputBorderColor: Colors.white.withAlpha(25),
      focusColor: AppColors.primaryDark,
    );
  }

  static ThemeData _build({
    required ColorScheme colorScheme,
    required TextTheme textTheme,
    required Color scaffoldColor,
    required Color cardColor,
    required Color cardBorderColor,
    required Color buttonColor,
    required Color inputFill,
    required Color inputBorderColor,
    required Color focusColor,
  }) {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldColor,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: scaffoldColor,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: cardBorderColor, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: AppTextStyles.button,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: border(inputBorderColor),
        enabledBorder: border(inputBorderColor),
        focusedBorder: border(focusColor, 1.5),
        errorBorder: border(AppColors.error, 1.5),
      ),
    );
  }
}
