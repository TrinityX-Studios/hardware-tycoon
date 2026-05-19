/// Hardware Tycoon — Dark Industrial Terminal Theme
///
/// A dense, high-contrast design system inspired by 1960s CRT terminals
/// and industrial control panels. Optimized for data-heavy management UIs.
library;

import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Color Palette
// ---------------------------------------------------------------------------

abstract final class HTColors {
  // Backgrounds
  static const Color background = Color(0xFF0A0E17);
  static const Color surface = Color(0xFF111827);
  static const Color surfaceVariant = Color(0xFF1E293B);
  static const Color surfaceElevated = Color(0xFF243348);

  // Primary accent — terminal cyan
  static const Color primary = Color(0xFF22D3EE);
  static const Color primaryDim = Color(0xFF0E7490);
  static const Color primaryGlow = Color(0x3322D3EE);

  // Secondary accent — soft violet
  static const Color secondary = Color(0xFFA78BFA);
  static const Color secondaryDim = Color(0xFF6D28D9);

  // Semantic
  static const Color success = Color(0xFF34D399);
  static const Color warning = Color(0xFFFBBF24);
  static const Color error = Color(0xFFF87171);
  static const Color info = Color(0xFF60A5FA);

  // Text hierarchy
  static const Color textPrimary = Color(0xFFE2E8F0);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textOnPrimary = Color(0xFF0A0E17);

  // Borders & dividers
  static const Color border = Color(0xFF1E293B);
  static const Color borderFocused = Color(0xFF22D3EE);
  static const Color divider = Color(0xFF1E293B);

  // Financial indicators
  static const Color profitGreen = Color(0xFF34D399);
  static const Color lossRed = Color(0xFFF87171);
}

// ---------------------------------------------------------------------------
// Spacing Constants
// ---------------------------------------------------------------------------

abstract final class HTSpacing {
  static const double dense = 4.0;
  static const double compact = 6.0;
  static const double standard = 8.0;
  static const double comfortable = 12.0;
  static const double spacious = 16.0;
  static const double section = 24.0;

  // Edge insets shortcuts
  static const EdgeInsets paddingDense = EdgeInsets.all(4.0);
  static const EdgeInsets paddingCompact = EdgeInsets.all(6.0);
  static const EdgeInsets paddingStandard = EdgeInsets.all(8.0);
  static const EdgeInsets paddingComfortable = EdgeInsets.all(12.0);

  static const EdgeInsets paddingHorizontalCompact =
      EdgeInsets.symmetric(horizontal: 6.0);
  static const EdgeInsets paddingHorizontalStandard =
      EdgeInsets.symmetric(horizontal: 8.0);
  static const EdgeInsets paddingHorizontalComfortable =
      EdgeInsets.symmetric(horizontal: 12.0);

  static const EdgeInsets paddingBarItem =
      EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0);
}

// ---------------------------------------------------------------------------
// Typography
// ---------------------------------------------------------------------------

abstract final class HTTypography {
  static const String _fontFamily = 'IBMPlexMono';

  // Top bar metrics
  static const TextStyle metricValue = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12.0,
    fontWeight: FontWeight.w500,
    color: HTColors.textPrimary,
    letterSpacing: 0.3,
  );

  static const TextStyle metricLabel = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 10.0,
    fontWeight: FontWeight.w400,
    color: HTColors.textMuted,
    letterSpacing: 0.5,
  );

  // Date display
  static const TextStyle dateDisplay = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13.0,
    fontWeight: FontWeight.w700,
    color: HTColors.primary,
    letterSpacing: 1.2,
  );

  // Panel headers
  static const TextStyle panelHeader = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13.0,
    fontWeight: FontWeight.w700,
    color: HTColors.textPrimary,
    letterSpacing: 1.0,
  );

  // Tab labels
  static const TextStyle tabLabel = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11.0,
    fontWeight: FontWeight.w500,
    color: HTColors.textSecondary,
    letterSpacing: 0.8,
  );

  static const TextStyle tabLabelActive = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11.0,
    fontWeight: FontWeight.w700,
    color: HTColors.primary,
    letterSpacing: 0.8,
  );

  // List items
  static const TextStyle listTitle = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12.0,
    fontWeight: FontWeight.w500,
    color: HTColors.textPrimary,
    letterSpacing: 0.2,
  );

  static const TextStyle listSubtitle = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 10.0,
    fontWeight: FontWeight.w400,
    color: HTColors.textSecondary,
  );

  // Body text
  static const TextStyle body = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12.0,
    fontWeight: FontWeight.w400,
    color: HTColors.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 10.0,
    fontWeight: FontWeight.w400,
    color: HTColors.textSecondary,
  );

  // Large stats / KPI
  static const TextStyle statLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 28.0,
    fontWeight: FontWeight.w700,
    color: HTColors.primary,
    letterSpacing: -0.5,
  );

  static const TextStyle statMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18.0,
    fontWeight: FontWeight.w700,
    color: HTColors.textPrimary,
  );

  // Category badge
  static const TextStyle badge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 9.0,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.0,
  );
}

// ---------------------------------------------------------------------------
// Decoration Helpers
// ---------------------------------------------------------------------------

abstract final class HTDecorations {
  /// Standard panel border
  static BoxDecoration panelBox({Color? borderColor}) => BoxDecoration(
        color: HTColors.surface,
        border: Border.all(
          color: borderColor ?? HTColors.border,
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(4.0),
      );

  /// Elevated card-style panel
  static BoxDecoration cardBox({Color? color}) => BoxDecoration(
        color: color ?? HTColors.surfaceVariant,
        border: Border.all(color: HTColors.border, width: 1.0),
        borderRadius: BorderRadius.circular(4.0),
      );

  /// Top bar container
  static const BoxDecoration topBar = BoxDecoration(
    color: HTColors.surface,
    border: Border(
      bottom: BorderSide(color: HTColors.border, width: 1.0),
    ),
  );

  /// Glowing focus border
  static BoxDecoration focusedBox() => BoxDecoration(
        color: HTColors.surfaceVariant,
        border: Border.all(color: HTColors.borderFocused, width: 1.5),
        borderRadius: BorderRadius.circular(4.0),
        boxShadow: const [
          BoxShadow(
            color: HTColors.primaryGlow,
            blurRadius: 8.0,
            spreadRadius: 0,
          ),
        ],
      );
}

// ---------------------------------------------------------------------------
// Theme Data
// ---------------------------------------------------------------------------

final ThemeData hardwareTycoonTheme = ThemeData(
  brightness: Brightness.dark,
  fontFamily: 'IBMPlexMono',
  scaffoldBackgroundColor: HTColors.background,
  colorScheme: const ColorScheme.dark(
    primary: HTColors.primary,
    secondary: HTColors.secondary,
    surface: HTColors.surface,
    error: HTColors.error,
    onPrimary: HTColors.textOnPrimary,
    onSecondary: HTColors.textPrimary,
    onSurface: HTColors.textPrimary,
    onError: HTColors.textPrimary,
  ),
  dividerColor: HTColors.divider,
  dividerTheme: const DividerThemeData(
    color: HTColors.divider,
    thickness: 1.0,
    space: 1.0,
  ),
  iconTheme: const IconThemeData(
    color: HTColors.textSecondary,
    size: 16.0,
  ),
  tooltipTheme: TooltipThemeData(
    decoration: BoxDecoration(
      color: HTColors.surfaceElevated,
      border: Border.all(color: HTColors.border),
      borderRadius: BorderRadius.circular(4.0),
    ),
    textStyle: HTTypography.bodySmall,
    waitDuration: const Duration(milliseconds: 400),
  ),
  scrollbarTheme: ScrollbarThemeData(
    thumbColor: WidgetStateProperty.all(HTColors.textMuted),
    thickness: WidgetStateProperty.all(4.0),
    radius: const Radius.circular(2.0),
  ),
);
