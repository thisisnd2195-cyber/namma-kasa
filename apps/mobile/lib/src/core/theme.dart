import 'package:flutter/material.dart';

/// Design tokens v1 from specs/001-waste-collection-tracking/spec.md.
/// These values are mirrored by the portal's Tailwind theme — a change here
/// without the matching web change is a defect (DS-05).
abstract final class Tokens {
  // Neutrals — light
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF8F9FA);
  static const outline = Color(0xFFDADCE0);
  static const textPrimary = Color(0xFF202124);
  static const textSecondary = Color(0xFF5F6368);
  static const textDisabled = Color(0xFF9AA0A6);

  // Neutrals — dark
  static const surfaceDark = Color(0xFF202124);
  static const surfaceAltDark = Color(0xFF292A2D);
  static const outlineDark = Color(0xFF3C4043);
  static const textPrimaryDark = Color(0xFFE8EAED);
  static const textSecondaryDark = Color(0xFF9AA0A6);

  // The single accent (DS-01)
  static const primary = Color(0xFF1A73E8);
  static const primaryPressed = Color(0xFF185ABC);
  static const primaryContainer = Color(0xFFE8F0FE);

  // Status — functional colour only, always paired with an icon or label (DS-02)
  static const success = Color(0xFF188038);
  static const successContainer = Color(0xFFE6F4EA);
  static const warning = Color(0xFFF9AB00);
  static const warningContainer = Color(0xFFFEF7E0);
  static const error = Color(0xFFD93025);
  static const errorContainer = Color(0xFFFCE8E6);

  // Spacing — 8 dp grid with 4 dp half-steps, 16 dp screen margins
  static const space1 = 4.0;
  static const space2 = 8.0;
  static const space3 = 12.0;
  static const space4 = 16.0;
  static const space6 = 24.0;
  static const space8 = 32.0;

  // Shape
  static const radiusInput = 8.0;
  static const radiusCard = 12.0;
  static const radiusSheet = 16.0;

  /// Driver controls are glove-friendly (FR-DRV-02).
  static const driverTouchTarget = 56.0;
  static const minTouchTarget = 48.0;
}

const _textTheme = TextTheme(
  displaySmall: TextStyle(fontSize: 28, height: 36 / 28, fontWeight: FontWeight.w400),
  headlineSmall: TextStyle(fontSize: 22, height: 28 / 22, fontWeight: FontWeight.w400),
  titleMedium: TextStyle(fontSize: 16, height: 24 / 16, fontWeight: FontWeight.w500),
  bodyMedium: TextStyle(fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w400),
  labelSmall: TextStyle(fontSize: 12, height: 16 / 12, fontWeight: FontWeight.w500),
);

ThemeData _base(ColorScheme scheme) {
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    textTheme: _textTheme,
    // Near-flat by default; elevation is 1 for cards, 3 for dialogs (DS-04).
    cardTheme: CardThemeData(
      elevation: 1,
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Tokens.radiusCard),
        side: BorderSide(color: scheme.outline),
      ),
    ),
    dialogTheme: DialogThemeData(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Tokens.radiusSheet),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Tokens.radiusInput),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, Tokens.minTouchTarget),
        shape: const StadiumBorder(),
      ),
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 1,
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
    ),
  );
}

ThemeData buildLightTheme() => _base(
      const ColorScheme.light(
        primary: Tokens.primary,
        onPrimary: Colors.white,
        primaryContainer: Tokens.primaryContainer,
        onPrimaryContainer: Tokens.primaryPressed,
        surface: Tokens.surface,
        onSurface: Tokens.textPrimary,
        surfaceContainerLow: Tokens.surfaceAlt,
        onSurfaceVariant: Tokens.textSecondary,
        outline: Tokens.outline,
        error: Tokens.error,
        errorContainer: Tokens.errorContainer,
      ),
    );

ThemeData buildDarkTheme() => _base(
      const ColorScheme.dark(
        primary: Tokens.primary,
        onPrimary: Colors.white,
        primaryContainer: Tokens.primaryPressed,
        onPrimaryContainer: Tokens.primaryContainer,
        surface: Tokens.surfaceDark,
        onSurface: Tokens.textPrimaryDark,
        surfaceContainerLow: Tokens.surfaceAltDark,
        onSurfaceVariant: Tokens.textSecondaryDark,
        outline: Tokens.outlineDark,
        error: Tokens.error,
      ),
    );

/// Driver surfaces scale text up: body >= 16, control labels >= 18 (FR-DRV-02).
ThemeData applyDriverScale(ThemeData theme) {
  return theme.copyWith(
    textTheme: theme.textTheme.copyWith(
      bodyMedium: theme.textTheme.bodyMedium?.copyWith(fontSize: 16, height: 24 / 16),
      titleMedium: theme.textTheme.titleMedium?.copyWith(fontSize: 18, height: 26 / 18),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, Tokens.driverTouchTarget),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        shape: const StadiumBorder(),
      ),
    ),
  );
}
