import 'package:flutter/material.dart';

/// AppTheme class following Clean Architecture principles
/// Requirements: 10.1, 10.4, 16.1
/// Developer: Developer 6
class AppTheme {
  AppTheme._();

  // ==========================================================================
  // COLOR SCHEME
  // ==========================================================================

  /// Primary colors - Coffee brown/green theme
  static const Color primaryColor = Color(0xFF5D4037); // Coffee brown
  static const Color primaryLight = Color(0xFF8B6B61);
  static const Color primaryDark = Color(0xFF321911);

  /// Secondary colors - Green accent
  static const Color secondaryColor = Color(0xFF4CAF50); // Green
  static const Color secondaryLight = Color(0xFF80E27E);
  static const Color secondaryDark = Color(0xFF087F23);

  /// Semantic colors
  static const Color errorColor = Color(0xFFD32F2F); // Red
  static const Color successColor = Color(0xFF388E3C); // Green
  static const Color warningColor = Color(0xFFFBC02D); // Yellow

  /// Neutral colors
  static const Color backgroundColor = Color(0xFFFAFAFA);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color onPrimaryColor = Color(0xFFFFFFFF);
  static const Color onSecondaryColor = Color(0xFFFFFFFF);
  static const Color onBackgroundColor = Color(0xFF212121);
  static const Color onSurfaceColor = Color(0xFF212121);
  static const Color onErrorColor = Color(0xFFFFFFFF);

  /// Text colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);

  // ==========================================================================
  // TEXT STYLES
  // ==========================================================================

  /// Heading 1 - 24px bold
  static const TextStyle heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    height: 1.3,
  );

  /// Heading 2 - 20px bold
  static const TextStyle heading2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    height: 1.3,
  );

  /// Body - 16px regular
  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: textPrimary,
    height: 1.5,
  );

  /// Caption - 14px light
  static const TextStyle caption = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w300,
    color: textSecondary,
    height: 1.4,
  );

  /// Button text style
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: onPrimaryColor,
    letterSpacing: 0.5,
  );

  // ==========================================================================
  // SPACING CONSTANTS
  // ==========================================================================

  /// Padding constants
  static const double padding4 = 4.0;
  static const double padding8 = 8.0;
  static const double padding12 = 12.0;
  static const double padding16 = 16.0;
  static const double padding24 = 24.0;
  static const double padding32 = 32.0;

  /// Margin constants
  static const double margin4 = 4.0;
  static const double margin8 = 8.0;
  static const double margin12 = 12.0;
  static const double margin16 = 16.0;
  static const double margin24 = 24.0;
  static const double margin32 = 32.0;

  // ==========================================================================
  // BORDER RADIUS CONSTANTS
  // ==========================================================================

  static const double borderRadiusSmall = 4.0;
  static const double borderRadiusMedium = 8.0;
  static const double borderRadiusLarge = 12.0;
  static const double borderRadiusXLarge = 16.0;
  static const double borderRadiusRound = 24.0;

  /// Pre-built BorderRadius objects
  static final BorderRadius borderRadiusSmallAll = BorderRadius.circular(
    borderRadiusSmall,
  );
  static final BorderRadius borderRadiusMediumAll = BorderRadius.circular(
    borderRadiusMedium,
  );
  static final BorderRadius borderRadiusLargeAll = BorderRadius.circular(
    borderRadiusLarge,
  );
  static final BorderRadius borderRadiusXLargeAll = BorderRadius.circular(
    borderRadiusXLarge,
  );
  static final BorderRadius borderRadiusRoundAll = BorderRadius.circular(
    borderRadiusRound,
  );

  // ==========================================================================
  // ICON SIZES
  // ==========================================================================

  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
  static const double iconSizeXLarge = 48.0;

  // ==========================================================================
  // THEME DATA
  // ==========================================================================

  /// Light theme configuration
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        primaryContainer: primaryLight,
        secondary: secondaryColor,
        secondaryContainer: secondaryLight,
        error: errorColor,
        surface: surfaceColor,
        onPrimary: onPrimaryColor,
        onSecondary: onSecondaryColor,
        onError: onErrorColor,
        onSurface: onSurfaceColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: onPrimaryColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: onPrimaryColor,
        ),
        iconTheme: IconThemeData(color: onPrimaryColor, size: iconSizeMedium),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: textSecondary,
        selectedIconTheme: IconThemeData(
          size: iconSizeMedium,
          color: primaryColor,
        ),
        unselectedIconTheme: IconThemeData(
          size: iconSizeMedium,
          color: textSecondary,
        ),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceColor,
        indicatorColor: primaryLight.withValues(alpha: 0.3),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: primaryColor,
              size: iconSizeMedium,
            );
          }
          return const IconThemeData(
            color: textSecondary,
            size: iconSizeMedium,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return caption.copyWith(
              color: primaryColor,
              fontWeight: FontWeight.w500,
            );
          }
          return caption.copyWith(color: textSecondary);
        }),
        elevation: 4,
        height: 64,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surfaceColor,
        selectedIconTheme: const IconThemeData(
          color: primaryColor,
          size: iconSizeMedium,
        ),
        unselectedIconTheme: const IconThemeData(
          color: textSecondary,
          size: iconSizeMedium,
        ),
        selectedLabelTextStyle: caption.copyWith(
          color: primaryColor,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelTextStyle: caption.copyWith(color: textSecondary),
        indicatorColor: primaryLight.withValues(alpha: 0.3),
        elevation: 4,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: onPrimaryColor,
          textStyle: button,
          padding: const EdgeInsets.symmetric(
            horizontal: padding24,
            vertical: padding12,
          ),
          shape: RoundedRectangleBorder(borderRadius: borderRadiusMediumAll),
          elevation: 2,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: button.copyWith(color: primaryColor),
          padding: const EdgeInsets.symmetric(
            horizontal: padding24,
            vertical: padding12,
          ),
          shape: RoundedRectangleBorder(borderRadius: borderRadiusMediumAll),
          side: const BorderSide(color: primaryColor, width: 1.5),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: button.copyWith(color: primaryColor),
          padding: const EdgeInsets.symmetric(
            horizontal: padding16,
            vertical: padding8,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: secondaryColor,
        foregroundColor: onSecondaryColor,
        elevation: 4,
        shape: CircleBorder(),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: padding16,
          vertical: padding12,
        ),
        border: OutlineInputBorder(
          borderRadius: borderRadiusMediumAll,
          borderSide: const BorderSide(color: textHint),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: borderRadiusMediumAll,
          borderSide: const BorderSide(color: textHint),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadiusMediumAll,
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: borderRadiusMediumAll,
          borderSide: const BorderSide(color: errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: borderRadiusMediumAll,
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        labelStyle: body.copyWith(color: textSecondary),
        hintStyle: body.copyWith(color: textHint),
        errorStyle: caption.copyWith(color: errorColor),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: borderRadiusMediumAll),
        margin: const EdgeInsets.all(margin8),
      ),
      iconTheme: const IconThemeData(color: textPrimary, size: iconSizeMedium),
      dividerTheme: const DividerThemeData(
        color: textHint,
        thickness: 1,
        space: margin16,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textPrimary,
        contentTextStyle: body.copyWith(color: onPrimaryColor),
        shape: RoundedRectangleBorder(borderRadius: borderRadiusMediumAll),
        behavior: SnackBarBehavior.floating,
      ),
      textTheme: const TextTheme(
        displayLarge: heading1,
        displayMedium: heading2,
        bodyLarge: body,
        bodyMedium: body,
        bodySmall: caption,
        labelLarge: button,
      ),
    );
  }

  /// Dark theme configuration
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryLight,
      colorScheme: const ColorScheme.dark(
        primary: primaryLight,
        primaryContainer: primaryColor,
        secondary: secondaryLight,
        secondaryContainer: secondaryColor,
        error: errorColor,
        surface: Color(0xFF1E1E1E),
        onPrimary: Color(0xFF000000),
        onSecondary: Color(0xFF000000),
        onError: onErrorColor,
        onSurface: Color(0xFFE0E0E0),
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Color(0xFFE0E0E0),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFFE0E0E0),
        ),
        iconTheme: IconThemeData(
          color: Color(0xFFE0E0E0),
          size: iconSizeMedium,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1E1E1E),
        selectedItemColor: primaryLight,
        unselectedItemColor: Color(0xFF9E9E9E),
        selectedIconTheme: IconThemeData(
          size: iconSizeMedium,
          color: primaryLight,
        ),
        unselectedIconTheme: IconThemeData(
          size: iconSizeMedium,
          color: Color(0xFF9E9E9E),
        ),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF1E1E1E),
        indicatorColor: primaryColor.withValues(alpha: 0.3),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: primaryLight,
              size: iconSizeMedium,
            );
          }
          return const IconThemeData(
            color: Color(0xFF9E9E9E),
            size: iconSizeMedium,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return caption.copyWith(
              color: primaryLight,
              fontWeight: FontWeight.w500,
            );
          }
          return caption.copyWith(color: const Color(0xFF9E9E9E));
        }),
        elevation: 4,
        height: 64,
      ),
      textTheme: TextTheme(
        displayLarge: heading1.copyWith(color: const Color(0xFFE0E0E0)),
        displayMedium: heading2.copyWith(color: const Color(0xFFE0E0E0)),
        bodyLarge: body.copyWith(color: const Color(0xFFE0E0E0)),
        bodyMedium: body.copyWith(color: const Color(0xFFE0E0E0)),
        bodySmall: caption.copyWith(color: const Color(0xFF9E9E9E)),
        labelLarge: button,
      ),
    );
  }
}
