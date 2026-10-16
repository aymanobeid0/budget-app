import 'package:flutter/material.dart';

import '../../../core/theme/tokens.dart';

class CategoryIconHelper {
  const CategoryIconHelper._();

  /// Icon keys are persisted in the database, so keys never change.
  static const Map<String, IconData> availableIcons = {
    'restaurant': Icons.restaurant_rounded,
    'directions_car': Icons.directions_bus_rounded,
    'power': Icons.bolt_rounded,
    'movie': Icons.movie_rounded,
    'local_hospital': Icons.favorite_rounded,
    'shopping_bag': Icons.shopping_bag_rounded,
    'fitness_center': Icons.fitness_center_rounded,
    'coffee': Icons.coffee_rounded,
    'flight': Icons.flight_rounded,
    'school': Icons.school_rounded,
    'pets': Icons.pets_rounded,
    'home': Icons.home_rounded,
    'work': Icons.work_rounded,
    'receipt': Icons.receipt_long_rounded,
    'savings': Icons.savings_rounded,
  };

  static IconData getIcon(String iconName) {
    return availableIcons[iconName] ?? Icons.category_rounded;
  }
}

/// Soft tinted square holding a category icon (transaction list, chat).
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
        color: isDark ? color.withValues(alpha: 0.2) : CategoryPalette.tint(color),
        borderRadius: BorderRadius.circular(size >= 40 ? AppRadius.lg : AppRadius.xs),
      ),
      child: Icon(icon, size: size * 0.48, color: isDark ? color : CategoryPalette.onTint(color)),
    );
  }
}
