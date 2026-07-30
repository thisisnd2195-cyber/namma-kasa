import 'package:flutter/material.dart';

/// Design tokens v2 from specs/001-waste-collection-tracking/spec.md.
///
/// The pattern language of ride-hailing apps, with orange standing in
/// wherever that language uses black (DS-01/02). Orange is for action and
/// liveness — CTAs, the auto marker, live pills — never for prose.
///
/// These values are mirrored by the portal's Tailwind theme — a change here
/// without the matching web change is a defect (DS-05).
abstract final class Tokens {
  // Ink & neutrals — light
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF6F6F8);
  static const outline = Color(0xFFECECEE);
  static const textPrimary = Color(0xFF0B0B0F);
  static const textSecondary = Color(0xFF6B7280);
  static const textDisabled = Color(0xFF9CA3AF);

  // Neutrals — dark
  static const surfaceDark = Color(0xFF131316);
  static const surfaceAltDark = Color(0xFF0B0B0F);
  static const outlineDark = Color(0xFF26262B);
  static const textPrimaryDark = Color(0xFFF4F4F5);
  static const textSecondaryDark = Color(0xFF9CA3AF);

  // The single accent (DS-02): orange where Uber uses black.
  static const primary = Color(0xFFEA580C);
  static const primaryPressed = Color(0xFFC2410C);
  static const primaryContainer = Color(0xFFFFF1E7);

  // Status — functional colour only, always paired with an icon or label.
  static const success = Color(0xFF0F8A3D);
  static const successContainer = Color(0xFFE8F6EE);
  static const warning = Color(0xFFB45309);
  static const warningContainer = Color(0xFFFEF3C7);
  static const error = Color(0xFFD92D20);
  static const errorContainer = Color(0xFFFEE4E2);

  // Spacing — 8 dp grid with 4 dp half-steps, 16 dp screen margins
  static const space1 = 4.0;
  static const space2 = 8.0;
  static const space3 = 12.0;
  static const space4 = 16.0;
  static const space6 = 24.0;
  static const space8 = 32.0;

  // Shape (DS-04)
  static const radiusInput = 12.0;
  static const radiusButton = 14.0;
  static const radiusCard = 16.0;
  static const radiusSheet = 28.0;
  static const floatButtonSize = 44.0;

  /// Floating cards and buttons over the map (DS-04).
  static const floatShadow = [
    BoxShadow(color: Color(0x240B0B0F), blurRadius: 24, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x140B0B0F), blurRadius: 6, offset: Offset(0, 2)),
  ];

  /// The bottom sheet's lift off the map.
  static const sheetShadow = [
    BoxShadow(color: Color(0x290B0B0F), blurRadius: 40, offset: Offset(0, -12)),
  ];

  /// Driver controls are glove-friendly (FR-DRV-02).
  static const driverTouchTarget = 56.0;
  static const minTouchTarget = 56.0;
}

const _textTheme = TextTheme(
  displaySmall: TextStyle(
      fontSize: 26, height: 32 / 26, fontWeight: FontWeight.w800, letterSpacing: -0.5),
  headlineSmall: TextStyle(fontSize: 22, height: 28 / 22, fontWeight: FontWeight.w800),
  titleMedium: TextStyle(fontSize: 17, height: 24 / 17, fontWeight: FontWeight.w700),
  bodyMedium: TextStyle(fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w400),
  labelSmall: TextStyle(fontSize: 13, height: 18 / 13, fontWeight: FontWeight.w600),
);

ThemeData _base(ColorScheme scheme) {
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    textTheme: _textTheme,
    // Cards float on shadow, not borders (DS-04). Screens use
    // Tokens.floatShadow directly; the Material fallback stays flat.
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Tokens.radiusCard),
      ),
    ),
    dialogTheme: DialogThemeData(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Tokens.radiusCard + 4),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Tokens.radiusInput),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(Tokens.minTouchTarget),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Tokens.radiusButton),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(Tokens.minTouchTarget),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        side: BorderSide.none,
        backgroundColor: scheme.surfaceContainerLow,
        foregroundColor: scheme.onSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Tokens.radiusButton),
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Tokens.primaryContainer,
      labelStyle: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600, color: Tokens.primaryPressed),
      side: BorderSide.none,
      shape: const StadiumBorder(),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Tokens.radiusSheet)),
      ),
      showDragHandle: true,
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      titleTextStyle: _textTheme.headlineSmall?.copyWith(color: scheme.onSurface),
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
        minimumSize: const Size.fromHeight(Tokens.driverTouchTarget),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Tokens.radiusButton),
        ),
      ),
    ),
  );
}

/// A circular floating control over the map (DS-01).
class FloatButton extends StatelessWidget {
  const FloatButton({super.key, required this.icon, required this.onTap, this.tooltip});

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip ?? '',
      child: Container(
        width: Tokens.floatButtonSize,
        height: Tokens.floatButtonSize,
        decoration: BoxDecoration(
          color: scheme.surface,
          shape: BoxShape.circle,
          boxShadow: Tokens.floatShadow,
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Icon(icon, size: 20, color: scheme.onSurface),
          ),
        ),
      ),
    );
  }
}

/// A status pill: soft tinted background, strong foreground (DS-04).
class Pill extends StatelessWidget {
  const Pill({
    super.key,
    required this.text,
    required this.background,
    required this.foreground,
    this.dot,
    this.floating = false,
  });

  final String text;
  final Color background;
  final Color foreground;
  final Color? dot;
  final bool floating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        boxShadow: floating ? Tokens.floatShadow : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot != null) ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: foreground),
          ),
        ],
      ),
    );
  }
}

/// The grabber bar at the top of a bottom sheet (DS-01).
class SheetGrabber extends StatelessWidget {
  const SheetGrabber({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 44,
        height: 4,
        margin: const EdgeInsets.only(top: 10, bottom: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFDDDDDD),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
