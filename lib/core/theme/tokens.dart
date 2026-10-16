import 'package:flutter/material.dart';

/// Calm Ledger design tokens.
///
/// Source of truth: the "Calm Ledger" direction on the redesign canvas.
/// Reference screenshots live in `docs/design/calm-ledger/`, and every value
/// here is listed in `docs/design/calm-ledger/DESIGN_TOKENS.md`.
///
/// Principles: a quiet warm-grey canvas, white elevated cards, one blue
/// accent reserved for actions, and category colors as the only other hue.
class AppColors {
  const AppColors._();

  // ── Accent ────────────────────────────────────────────────────────────
  static const primary = Color(0xFF1F4DD8); // Action blue
  static const primaryDark = Color(0xFF163BA8); // Pressed / hover
  static const primaryLight = Color(0xFFE8EEFC); // Selected tab pill, chips
  static const primarySubtle = Color(0xFFEEF2FD); // Badges, info tint

  // ── Canvas & surfaces ─────────────────────────────────────────────────
  static const background = Color(0xFFF3F3F0); // Warm grey canvas
  static const surface = Color(0xFFFFFFFF); // Cards, sheets, nav
  static const surfaceSubtle = Color(0xFFF6F6F3); // Keypad keys, inset fields
  static const surfaceSunken = Color(0xFFF8F8F6); // Tables inside cards
  static const scrim = Color(0xFF6E6E6A); // Behind modal sheets

  // ── Text ──────────────────────────────────────────────────────────────
  static const ink = Color(0xFF111111); // Primary text, selected chip fill
  static const textPrimary = ink;
  static const textSecondary = Color(0xFF5F5F5B); // Labels, section headers
  static const textMuted = Color(0xFF6B6B66); // Timestamps, inactive tabs

  // ── Lines ─────────────────────────────────────────────────────────────
  static const divider = Color(0xFFF0F0ED); // Rows inside a card
  static const borderLight = Color(0xFFECECE8); // Unselected chips
  static const borderStrong = Color(0xFFE2E2DE); // Prompt chips
  static const borderDashed = Color(0xFFC4C4BF); // "+ New" affordances
  static const handle = Color(0xFFD6D6D2); // Sheet drag handle
  static const borderFocus = primary;

  // ── Semantic ──────────────────────────────────────────────────────────
  static const expense = Color(0xFFC8372D); // Destructive actions, errors
  static const expenseContainer = Color(0xFFFCECEA);
  static const income = Color(0xFF157F55); // Positive / tips
  static const incomeContainer = Color(0xFFEEF7F2);
  static const tipText = Color(0xFF14553A);

  // ── Dark theme ────────────────────────────────────────────────────────
  static const darkBackground = Color(0xFF111110);
  static const darkSurface = Color(0xFF1C1C1A);
  static const darkSurfaceSubtle = Color(0xFF262624);
  static const darkTextPrimary = Color(0xFFF5F5F2);
  static const darkTextSecondary = Color(0xFFA3A39D);
  static const darkBorder = Color(0xFF2E2E2B);
  static const darkPrimaryLight = Color(0xFF1E2A4F);
}

/// Category hues. The bar/legend uses [swatch]; icon tiles use a soft tint
/// of it with a darker foreground so icons pass contrast on the tint.
class CategoryPalette {
  const CategoryPalette._();

  static const food = Color(0xFFE0712B);
  static const utilities = Color(0xFF7A5AD6);
  static const transport = Color(0xFF2F7FD1);
  static const health = Color(0xFF1E9E6A);
  static const coffee = Color(0xFF8A6B3F);
  static const shopping = Color(0xFFD1497A);
  static const entertainment = Color(0xFF7A5AD6);
  static const other = Color(0xFFD3D3CE);

  /// Background of a category icon tile (≈14% of the hue over white).
  static Color tint(Color c) => Color.alphaBlend(c.withValues(alpha: 0.14), Colors.white);

  /// Icon color on top of [tint]: the hue darkened ~20% for contrast.
  static Color onTint(Color c) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness - 0.12).clamp(0.0, 1.0)).toColor();
  }
}

/// Typography families. Geist for UI text, Geist Mono for every amount so
/// digits line up in columns.
class AppFonts {
  const AppFonts._();

  static const sans = 'Geist';
  static const mono = 'GeistMono';
}

/// Type scale (px). Weights: 400 body, 500 labels, 600 titles.
class AppType {
  const AppType._();

  static const heroAmount = TextStyle(
    fontFamily: AppFonts.mono,
    fontSize: 46,
    fontWeight: FontWeight.w500,
    letterSpacing: -2,
    height: 1,
    color: AppColors.ink,
  );
  static const entryAmount = TextStyle(
    fontFamily: AppFonts.mono,
    fontSize: 56,
    fontWeight: FontWeight.w500,
    letterSpacing: -2.5,
    height: 1.1,
    color: AppColors.ink,
  );
  static const rowAmount = TextStyle(
    fontFamily: AppFonts.mono,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.ink,
  );
  static const sectionAmount = TextStyle(
    fontFamily: AppFonts.mono,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );
  static const title = TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.ink);
  static const rowTitle = TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink);
  static const body = TextStyle(fontSize: 15, height: 1.55, color: AppColors.ink);
  static const label = TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textSecondary);
  static const section = TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary);
  static const caption = TextStyle(fontSize: 13, color: AppColors.textMuted);
  static const navLabel = TextStyle(fontSize: 12, fontWeight: FontWeight.w500);
}

/// Spacing scale (px).
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
  static const gutter = 16.0;
}

/// Corner radii.
class AppRadius {
  const AppRadius._();

  static const xs = 8.0; // Small icon tiles
  static const sm = 12.0; // Row icon tiles, tip boxes
  static const md = 14.0; // Chips, keypad keys
  static const lg = 20.0; // List cards, amount field
  static const xl = 24.0; // Hero card, nav top corners
  static const sheet = 28.0; // Bottom sheets
  static const pill = 999.0;
}

/// Elevation: three levels of soft, layered shadows plus an accent glow.
class AppShadows {
  const AppShadows._();

  /// Level 1: chips, small buttons sitting just above the canvas.
  static const raised = [
    BoxShadow(color: Color(0x0F111111), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0D111111), blurRadius: 12, offset: Offset(0, 4)),
  ];

  /// Level 2: list cards and chat bubbles.
  static const card = [
    BoxShadow(color: Color(0x0D111111), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0D111111), blurRadius: 18, offset: Offset(0, 6)),
  ];

  /// Level 3: hero card and composer.
  static const heroCard = [
    BoxShadow(color: Color(0x0D111111), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x14111111), blurRadius: 30, offset: Offset(0, 10)),
  ];

  /// Blue glow under primary actions (add button, save, send).
  static const fab = [
    BoxShadow(color: Color(0x401F4DD8), blurRadius: 4, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x591F4DD8), blurRadius: 28, offset: Offset(0, 12)),
  ];

  /// Nav bar casts upward.
  static const navBar = [
    BoxShadow(color: Color(0x0A111111), blurRadius: 0, offset: Offset(0, -1)),
    BoxShadow(color: Color(0x0F111111), blurRadius: 24, offset: Offset(0, -8)),
  ];

  /// Modal sheets.
  static const sheet = [
    BoxShadow(color: Color(0x40000000), blurRadius: 40, offset: Offset(0, -12)),
  ];

  /// Selected (ink) category chip.
  static const inkChip = [
    BoxShadow(color: Color(0x33111111), blurRadius: 4, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x2E111111), blurRadius: 14, offset: Offset(0, 6)),
  ];
}
