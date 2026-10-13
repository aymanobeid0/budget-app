import 'package:flutter/material.dart';

/// Design tokens extracted directly from the modern neo-banking design mockups.
class AppColors {
  const AppColors._();

  // Primary & Accents
  static const primary = Color(0xFF6C3EE8); // Vibrant Electric Violet
  static const primaryDark = Color(0xFF5328D8);
  static const primaryLight = Color(0xFFF0EDFF); // Soft Lavender
  static const primarySubtle = Color(0xFFE8E3FA);

  // Surface & Canvas Backgrounds
  static const background = Color(0xFFF7F8FD); // Light cool canvas
  static const surface = Color(0xFFFFFFFF); // Pure white card surface
  static const surfaceSubtle = Color(0xFFF4F5FB); // Soft grayish-lavender container

  // Typography Colors
  static const textPrimary = Color(0xFF1A1D2E); // Deep midnight navy
  static const textSecondary = Color(0xFF7E84A3); // Cool slate gray
  static const textMuted = Color(0xFFA5ABC0); // Muted hint gray

  // Borders & Dividers
  static const borderLight = Color(0xFFECEEF7); // Delicate subtle outline
  static const borderFocus = Color(0xFF6C3EE8); // Focused violet border

  // Financial Semantics (Income / Expense)
  static const expense = Color(0xFFFF5B35); // Coral-red for expenses
  static const expenseContainer = Color(0xFFFFF0EC); // Soft pastel peach
  static const income = Color(0xFF00BA88); // Mint emerald for income
  static const incomeContainer = Color(0xFFE6F9F3); // Soft pastel mint container

  // Dark Theme Equivalents
  static const darkBackground = Color(0xFF10111A);
  static const darkSurface = Color(0xFF191B28);
  static const darkSurfaceSubtle = Color(0xFF222436);
  static const darkTextPrimary = Color(0xFFFFFFFF);
  static const darkTextSecondary = Color(0xFF9EA3B8);
  static const darkBorder = Color(0xFF2A2D40);
}

/// Gradients used for hero cards and balance widgets.
class AppGradients {
  const AppGradients._();

  /// Hero balance card gradient: Indigo -> Violet -> Coral-Peach
  static const balanceCard = LinearGradient(
    colors: [
      Color(0xFF5D5FEF),
      Color(0xFF984BEE),
      Color(0xFFFF6F61),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.52, 1.0],
  );

  /// Vibrant sunset gradient (Peach / Coral)
  static const cardSunset = LinearGradient(
    colors: [Color(0xFFFF9966), Color(0xFFFF5E62)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Mint-emerald gradient
  static const cardEmerald = LinearGradient(
    colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Electric purple-blue gradient
  static const cardViolet = LinearGradient(
    colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Standardized corner radii.
class AppRadius {
  const AppRadius._();

  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const sheet = 28.0;
  static const pill = 999.0;
}

/// Diffused ambient shadows.
class AppShadows {
  const AppShadows._();

  static const card = [
    BoxShadow(
      color: Color(0x081A1D2E),
      blurRadius: 16,
      offset: Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  static const heroCard = [
    BoxShadow(
      color: Color(0x3B6C3EE8),
      blurRadius: 24,
      offset: Offset(0, 10),
      spreadRadius: -2,
    ),
  ];

  static const fab = [
    BoxShadow(
      color: Color(0x456C3EE8),
      blurRadius: 18,
      offset: Offset(0, 6),
      spreadRadius: 0,
    ),
  ];

  static const navBar = [
    BoxShadow(
      color: Color(0x0C000000),
      blurRadius: 24,
      offset: Offset(0, -4),
    ),
  ];
}
