import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Color tokens pulled from the CheckMe Stitch design.
class AppColors {
  AppColors._();

  static const primary = Color(0xFF006D3B);
  static const primaryContainer = Color(0xFF2FBF71);
  static const onPrimaryContainer = Color(0xFF004724);

  static const secondary = Color(0xFF1E6B47);
  static const secondaryContainer = Color(0xFFA4F0C2);
  static const onSecondaryContainer = Color(0xFF246F4B);

  /// Used for out-of-stock / attention states (the mockup's "tertiary").
  static const alert = Color(0xFFBF0715);
  static const alertContainer = Color(0xFFFFDAD6);
  static const onAlertContainer = Color(0xFF93000A);

  static const surface = Color(0xFFF8F9FB);
  static const surfaceContainerLowest = Colors.white;
  static const surfaceContainerLow = Color(0xFFF2F4F6);
  static const surfaceContainer = Color(0xFFEDEEF0);
  static const surfaceContainerHigh = Color(0xFFE7E8EA);
  static const surfaceContainerHighest = Color(0xFFE1E2E4);

  static const onSurface = Color(0xFF191C1E);
  static const onSurfaceVariant = Color(0xFF3D4A3F);
  static const outline = Color(0xFF6D7B6E);
}

ThemeData buildAppTheme() {
  final colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: Colors.white,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.onPrimaryContainer,
    secondary: AppColors.secondary,
    onSecondary: Colors.white,
    secondaryContainer: AppColors.secondaryContainer,
    onSecondaryContainer: AppColors.onSecondaryContainer,
    tertiary: AppColors.alert,
    onTertiary: Colors.white,
    tertiaryContainer: AppColors.alertContainer,
    onTertiaryContainer: AppColors.onAlertContainer,
    error: const Color(0xFFBA1A1A),
    onError: Colors.white,
    errorContainer: AppColors.alertContainer,
    onErrorContainer: AppColors.onAlertContainer,
    surface: AppColors.surface,
    onSurface: AppColors.onSurface,
    onSurfaceVariant: AppColors.onSurfaceVariant,
    surfaceContainerLowest: AppColors.surfaceContainerLowest,
    surfaceContainerLow: AppColors.surfaceContainerLow,
    surfaceContainer: AppColors.surfaceContainer,
    surfaceContainerHigh: AppColors.surfaceContainerHigh,
    surfaceContainerHighest: AppColors.surfaceContainerHighest,
    outline: AppColors.outline,
    outlineVariant: const Color(0xFFBCCABC),
    surfaceTint: AppColors.primary,
  );

  final textTheme = GoogleFonts.plusJakartaSansTextTheme().apply(
    bodyColor: AppColors.onSurface,
    displayColor: AppColors.onSurface,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.surface,
    textTheme: textTheme,
    fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.onSurface,
      elevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 68,
      backgroundColor: AppColors.surfaceContainerLowest,
      indicatorColor: AppColors.secondaryContainer,
      surfaceTintColor: Colors.transparent,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryContainer,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: const CircleBorder(),
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.primaryContainer
            : AppColors.surfaceContainerHigh,
      ),
    ),
  );
}
