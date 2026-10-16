import 'package:flutter/material.dart';

import '../../../core/theme/tokens.dart';

class CategoryIconHelper {
  const CategoryIconHelper._();

  /// Icon keys are persisted in the database, so keys never change; only the
  /// glyphs were updated to the rounded set used by Calm Ledger.
  static const Map<String, IconData> availableIcons = {
    'restaurant': Icons.restaurant_rounded,
    'directions_car': Icons.directions_bus_outlined,
    'power': Icons.bolt_rounded,
    'movie': Icons.movie_outlined,
    'local_hospital': Icons.favorite_outline_rounded,
    'shopping_bag': Icons.shopping_bag_outlined,
    'fitness_center': Icons.fitness_center_rounded,
    'coffee': Icons.coffee_outlined,
    'flight': Icons.flight_rounded,
    'school': Icons.school_outlined,
    'pets': Icons.pets_rounded,
    'home': Icons.home_outlined,
    'work': Icons.work_outline_rounded,
    'receipt': Icons.receipt_long_outlined,
    'savings': Icons.savings_outlined,
  };

  static IconData getIcon(String iconName) {
    return availableIcons[iconName] ?? Icons.category_outlined;
  }
}

/// Rounded tinted square holding a category icon: the Calm Ledger
/// signature element used in rows, chips and consultant answers.
class CategoryIconTile extends StatelessWidget {
  const CategoryIconTile({
    super.key,
    required this.icon,
    required this.color,
    this.size = 40,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isDark ? color.withValues(alpha: 0.22) : CategoryPalette.tint(color),
        borderRadius: BorderRadius.circular(size >= 36 ? AppRadius.sm : AppRadius.xs),
      ),
      child: Icon(
        icon,
        size: size * 0.5,
        color: isDark ? color : CategoryPalette.onTint(color),
      ),
    );
  }
}
