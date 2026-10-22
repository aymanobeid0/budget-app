import 'package:flutter/material.dart';

/// Monex design tokens.
///
/// Source of truth: the "Expense management app UI kit" Figma file (Monex),
/// pages "Visual design light/dark", "Colors" and "Typography".
///
/// Principles: a soft grey canvas with white cards that float on a wide, faint
/// shadow; one electric blue (#0E33F3) that runs into sky blue as a gradient
/// on the hero card, the add button, selected chips and primary actions;
/// Inter throughout; amounts in ink with a +/- sign.
class AppColors {
  const AppColors._();

  // ── Accent ────────────────────────────────────────────────────────────
  static const primary = Color(0xFF0E33F3); // primary/brand
  static const primaryDark = Color(0xFF0B27C2); // Pressed
  static const primaryLight = Color(0xFFE7EBFE); // Selected tint, chips
  static const primarySubtle = Color(0xFFE7EBFE);
  static const onPrimaryMuted = Color(0xFFDCE4FF); // Secondary text on blue
  static const sky = Color(0xFF2BB0ED); // Primary/Blue-Light, gradient end
  static const focusGlow = Color(0x331890FF); // glows/focus blue

  /// Accent used on dark backgrounds. The brand blue holds up on night.
  static const primaryDarkMode = Color(0xFF2E50FF);
  static const accentTextDark = Color(0xFF8FA6FF);

  // ── Canvas & surfaces ─────────────────────────────────────────────────
  static const background = Color(0xFFF5F6F7); // neutrals/100
  static const surface = Color(0xFFFFFFFF); // neutrals/00
  static const surfaceSubtle = Color(0xFFEBEEF0); // neutrals/200: icon tiles, chips
  static const surfaceSunken = Color(0xFFFAFAFB); // neutrals/50
  static const scrim = Color(0xFF0F1B26);

  // ── Text ──────────────────────────────────────────────────────────────
  static const ink = Color(0xFF242D35); // neutrals/800
  static const textPrimary = ink;
  static const textSecondary = Color(0xFF6B7580); // neutrals/600
  static const textMuted = Color(0xFF6B7580);
  static const chevron = Color(0xFF9BA1A8); // neutrals/500

  // ── Lines ─────────────────────────────────────────────────────────────
  static const divider = Color(0xFFEBEEF0);
  static const borderLight = Color(0xFFDCDFE3);
  static const borderStrong = Color(0xFFB0B8BF); // neutrals/400
  static const borderDashed = Color(0xFFB0B8BF);
  static const handle = Color(0xFFDCDFE3);
  static const borderFocus = primary;

  // ── Semantic ──────────────────────────────────────────────────────────
  // Monex prints amounts in ink with a sign; red stays for errors and
  // destructive actions, green for success.
  static const expense = Color(0xFFEF4E4E); // system/red: errors, destructive
  static const expenseContainer = Color(0xFFFDE8E8);
  static const danger = Color(0xFFEF4E4E);
  static const income = Color(0xFF3EBD93); // system/green
  static const incomeContainer = Color(0xFFE3F7F0);
  static const tipText = Color(0xFF014D40); // Secondary/Green Dark

  // ── Dark theme ────────────────────────────────────────────────────────
  static const darkBackground = Color(0xFF0F1B26); // neutrals [night]/00
  static const darkSurface = Color(0xFF17232F);
  static const darkSurfaceSubtle = Color(0xFF242D35); // neutrals [night]/100
  static const darkTextPrimary = Color(0xFFF5F6F7); // neutrals [night]/800
  static const darkTextSecondary = Color(0xFFB0B8BF); // neutrals [night]/600
  static const darkBorder = Color(0xFF3E4C59); // neutrals [night]/200
  static const darkPrimaryLight = Color(0xFF1B2A6B);
}

/// The Monex brand gradient: deep brand blue at the bottom left running into
/// sky blue at the top right.
class AppGradients {
  const AppGradients._();

  static const brand = LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [AppColors.primary, AppColors.sky],
  );

  /// Buttons are wide and short: the same run, left to right.
  static const button = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AppColors.primary, AppColors.sky],
  );
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

  static const sans = 'Inter';

  /// Amounts use the same family with tabular figures so digits align.
  static const mono = sans;
  static const tabular = [FontFeature.tabularFigures()];
}

class AppType {
  const AppType._();

  // Monex scale (Typography page): Heading 36/24, Subheading 20/18/16/14,
  // Body 16/14/12, Small 10. Semi Bold carries every title and amount.

  static const heroAmount = TextStyle(
    fontFamily: AppFonts.sans,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: Colors.white,
    fontFeatures: AppFonts.tabular,
  );
  static const entryAmount = TextStyle(
    fontFamily: AppFonts.sans,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
    fontFeatures: AppFonts.tabular,
  );
  static const rowAmount = TextStyle(
    fontFamily: AppFonts.sans,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.25,
    color: AppColors.ink,
    fontFeatures: AppFonts.tabular,
  );
  static const sectionAmount = TextStyle(
    fontFamily: AppFonts.sans,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    fontFeatures: AppFonts.tabular,
  );
  static const screenTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
  );
  static const title = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
  );
  static const fieldLabel = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.chevron,
  );
  static const rowTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.25,
    color: AppColors.ink,
  );
  static const menuTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.ink,
  );
  static const body = TextStyle(
    fontSize: 16,
    height: 1.5,
    color: AppColors.ink,
  );
  static const label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );
  static const section = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
  );
  static const caption = TextStyle(fontSize: 14, height: 1.43, color: AppColors.textMuted);
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
  static const gutter = 24.0; // Monex screens sit 24 in from each edge
}

/// How screens adapt to the window's width.
class AppLayout {
  const AppLayout._();

  /// The widest a page's content grows. Past it, the page stays a centered
  /// column instead of stretching rows and cards across a tablet or desktop.
  static const readableWidth = 640.0;

  /// From this width (Material's "expanded" window class) Android and
  /// desktop swap the bottom tab bar for a navigation rail. iPad keeps its
  /// tab bar, which is native there.
  static const railMinWidth = 840.0;
}

class AppRadius {
  const AppRadius._();

  static const xs = 8.0; // border-200
  static const sm = 10.0; // border-250: chips
  static const md = 12.0; // border-300: icon tiles, square buttons
  static const lg = 16.0; // border-400: fields, buttons, list tiles
  static const xl = 24.0; // border-600: cards, hero card
  static const sheet = 32.0;
  static const pill = 999.0;
}

class AppShadows {
  const AppShadows._();

  /// shadows/[day]/grey-64: the wide, faint lift under every white card.
  static const card = [
    BoxShadow(color: Color(0x1F1D3A58), blurRadius: 64, offset: Offset(0, 8)),
  ];

  /// shadows/brand-24: the blue glow under gradient elements.
  static const brand = [
    BoxShadow(color: Color(0x591D41F9), blurRadius: 24, offset: Offset(0, 12)),
  ];

  /// The floating add button.
  static const fab = brand;

  /// The full-width primary button.
  static const button = brand;

  static const sheet = [
    BoxShadow(color: Color(0x33000000), blurRadius: 40, offset: Offset(0, -12)),
  ];
}
