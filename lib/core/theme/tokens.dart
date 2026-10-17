import 'package:flutter/material.dart';

/// "Blue" design tokens.
///
/// Source of truth: row "4 · Blue" on the redesign canvas, built from the
/// user's reference screens with solid colors only (no gradients).
/// Reference screenshots: `docs/design/blue/`; full list of values:
/// `docs/design/blue/DESIGN_TOKENS.md`.
///
/// Principles: white screens, one deep-blue accent (#042895) for the hero
/// card, the add button, selected states and primary actions; soft grey
/// square buttons; solid-colored category squares; red expense amounts.
class AppColors {
  const AppColors._();

  // ── Accent ────────────────────────────────────────────────────────────
  static const primary = Color(0xFF042895); // Deep blue
  static const primaryDark = Color(0xFF031E70); // Pressed
  static const primaryLight = Color(0xFFE6EBF8); // Selected tint, chips
  static const primarySubtle = Color(0xFFE6EBF8);
  static const onPrimaryMuted = Color(0xFFD6DEF7); // Secondary text on blue

  /// Accent used on dark backgrounds, where #042895 would be too dark.
  static const primaryDarkMode = Color(0xFF3358D4);
  static const accentTextDark = Color(0xFF9DB2F7);

  // ── Canvas & surfaces ─────────────────────────────────────────────────
  static const background = Color(0xFFFFFFFF);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSubtle = Color.fromARGB(
    255,
    246,
    247,
    249,
  ); // Square buttons, chips, calendar
  static const surfaceSunken = Color(0xFFF3F5FA);
  static const scrim = Color(0xFF141A2E);

  // ── Text ──────────────────────────────────────────────────────────────
  static const ink = Color(0xFF141A2E);
  static const textPrimary = ink;
  static const textSecondary = Color(0xFF667085);
  static const textMuted = Color(0xFF667085);
  static const navInactive = Color(0xFFA9B0C2);
  static const chevron = Color(0xFF98A2B3);

  // ── Lines ─────────────────────────────────────────────────────────────
  static const divider = Color(0xFFEEF1F6);
  static const borderLight = Color(0xFFE3E7EF);
  static const borderStrong = Color(0xFFE3E7EF);
  static const borderDashed = Color(0xFFC9CFDB);
  static const handle = Color(0xFFD9DEE8);
  static const borderFocus = primary;

  // ── Semantic ──────────────────────────────────────────────────────────
  static const expense = Color(0xFFD9411F); // Expense amounts, destructive
  static const expenseContainer = Color(0xFFFDECE8);
  static const danger = Color(0xFFE5484D); // Sign-out tile
  static const income = Color(0xFF16A34A);
  static const incomeContainer = Color(0xFFEAF7EF);
  static const tipText = Color(0xFF14532D);

  // ── Dark theme ────────────────────────────────────────────────────────
  static const darkBackground = Color(0xFF0B1020);
  static const darkSurface = Color(0xFF141A2E);
  static const darkSurfaceSubtle = Color(0xFF1E2640);
  static const darkTextPrimary = Color(0xFFF4F6FB);
  static const darkTextSecondary = Color(0xFFA3ABC2);
  static const darkBorder = Color(0xFF273049);
  static const darkPrimaryLight = Color(0xFF1A2A5C);
}

/// Category hues: solid squares (Categories, Profile) use the color as-is
/// with a white icon; list tiles use [tint] with [onTint] icons.
class CategoryPalette {
  const CategoryPalette._();

  static const food = Color(0xFFE97A1F);
  static const transport = Color(0xFF3B82F6);
  static const utilities = Color(0xFF0F766E);
  static const coffee = Color(0xFF92603A);
  static const health = Color(0xFFE5484D);
  static const shopping = Color(0xFFDB2777);
  static const entertainment = Color(0xFF4F46E5);
  static const other = Color(0xFFD0D5DD);

  /// Soft background for a category icon tile.
  static Color tint(Color c) =>
      Color.alphaBlend(c.withValues(alpha: 0.12), Colors.white);

  /// Icon color on top of [tint].
  static Color onTint(Color c) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness - 0.08).clamp(0.0, 1.0)).toColor();
  }
}

class AppFonts {
  const AppFonts._();

  static const sans = 'PlusJakartaSans';

  /// Amounts use the same family with tabular figures so digits align.
  static const mono = sans;
  static const tabular = [FontFeature.tabularFigures()];
}

class AppType {
  const AppType._();

  static const heroAmount = TextStyle(
    fontFamily: AppFonts.sans,
    fontSize: 34,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    height: 1.1,
    color: Colors.white,
    fontFeatures: AppFonts.tabular,
  );
  static const entryAmount = TextStyle(
    fontFamily: AppFonts.sans,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    fontFeatures: AppFonts.tabular,
  );
  static const rowAmount = TextStyle(
    fontFamily: AppFonts.sans,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.expense,
    fontFeatures: AppFonts.tabular,
  );
  static const sectionAmount = TextStyle(
    fontFamily: AppFonts.sans,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    fontFeatures: AppFonts.tabular,
  );
  static const screenTitle = TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
  );
  static const title = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
  );
  static const fieldLabel = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
  );
  static const rowTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
  );
  static const menuTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.ink,
  );
  static const body = TextStyle(
    fontSize: 15,
    height: 1.5,
    color: AppColors.ink,
  );
  static const label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );
  static const section = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );
  static const caption = TextStyle(fontSize: 13, color: AppColors.textMuted);
  static const navLabel = TextStyle(fontSize: 12, fontWeight: FontWeight.w500);
}

class AppSpace {
  const AppSpace._();

  static const xxs = 2.0;
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;

  /// Horizontal page gutter.
  static const gutter = 24.0;
}

class AppRadius {
  const AppRadius._();

  static const xs = 8.0; // Small tiles in chat answers
  static const sm = 10.0; // Solid menu squares
  static const md = 12.0; // Square buttons, chips
  static const lg = 14.0; // List tiles, fields, primary button
  static const xl = 22.0; // Hero card
  static const sheet = 28.0;
  static const pill = 999.0;
}

class AppShadows {
  const AppShadows._();

  /// Soft lift for small elements on white.
  static const raised = [
    BoxShadow(color: Color(0x0F141A2E), blurRadius: 10, offset: Offset(0, 3)),
  ];

  /// Cards that need to separate from white (rarely used in this style).
  static const card = [
    BoxShadow(color: Color(0x0D141A2E), blurRadius: 18, offset: Offset(0, 6)),
  ];

  /// Hero card: blue-tinted glow.
  static const heroCard = [
    BoxShadow(color: Color(0x47042895), blurRadius: 30, offset: Offset(0, 14)),
  ];

  /// Add button and primary actions.
  static const fab = [
    BoxShadow(color: Color(0x66042895), blurRadius: 24, offset: Offset(0, 10)),
  ];

  static const button = [
    BoxShadow(color: Color(0x52042895), blurRadius: 26, offset: Offset(0, 12)),
  ];

  static const navBar = [
    BoxShadow(color: Color(0x0F141A2E), blurRadius: 24, offset: Offset(0, -6)),
  ];

  static const sheet = [
    BoxShadow(color: Color(0x33000000), blurRadius: 40, offset: Offset(0, -12)),
  ];

  static const inkChip = <BoxShadow>[];

  /// White icon buttons, chips and small cards: a soft drop shadow gives
  /// the raised, 3D look instead of a grey fill.
  static const iconButton = [
    BoxShadow(color: Color(0x1A141A2E), blurRadius: 14, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x14141A2E), blurRadius: 3, offset: Offset(0, 1)),
  ];

  /// Larger white panels (week strip, prompt cards).
  static const panel = [
    BoxShadow(color: Color(0x14141A2E), blurRadius: 20, offset: Offset(0, 6)),
    BoxShadow(color: Color(0x0F141A2E), blurRadius: 3, offset: Offset(0, 1)),
  ];
}
