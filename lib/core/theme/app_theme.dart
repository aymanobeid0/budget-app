import 'package:flutter/material.dart';
import 'tokens.dart';

export 'tokens.dart';

/// App-wide theme built from the Calm Ledger tokens.
class AppTheme {
  const AppTheme._();

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final surfaceSubtle = isDark ? AppColors.darkSurfaceSubtle : AppColors.surfaceSubtle;
    final text = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final border = isDark ? AppColors.darkBorder : AppColors.borderLight;
    final selectedTint = isDark ? AppColors.darkPrimaryLight : AppColors.primaryLight;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: selectedTint,
      onPrimaryContainer: isDark ? Colors.white : AppColors.primary,
      secondary: AppColors.ink,
      onSecondary: Colors.white,
      secondaryContainer: surfaceSubtle,
      onSecondaryContainer: text,
      tertiary: AppColors.income,
      onTertiary: Colors.white,
      error: AppColors.expense,
      onError: Colors.white,
      surface: surface,
      onSurface: text,
      surfaceContainerHighest: surfaceSubtle,
      surfaceContainerLow: bg,
      onSurfaceVariant: textSecondary,
      outline: border,
      outlineVariant: isDark ? AppColors.darkBorder : AppColors.divider,
      shadow: Colors.black,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: AppFonts.sans,
      colorScheme: scheme,
    );

    return base.copyWith(
      scaffoldBackgroundColor: bg,
      textTheme: base.textTheme.apply(bodyColor: text, displayColor: text),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppType.title.copyWith(color: text, fontFamily: AppFonts.sans),
        iconTheme: IconThemeData(color: text),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? AppColors.darkBorder : AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: CircleBorder(),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        modalBarrierColor: AppColors.scrim.withValues(alpha: 0.9),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.borderFocus, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.expense),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(
            fontFamily: AppFonts.sans,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(fontFamily: AppFonts.sans, fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: AppColors.ink,
        labelStyle: TextStyle(fontFamily: AppFonts.sans, fontSize: 14, color: text),
        side: BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.primary),
    );
  }
}
