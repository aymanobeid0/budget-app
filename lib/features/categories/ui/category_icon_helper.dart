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

/// Grey rounded square holding a category icon in ink, as Monex draws every
/// entry's icon (transaction list, chat). [color] is kept for callers that
/// still pass the Category's hue; the tile itself is neutral.
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
        color: isDark ? AppColors.darkBorder : AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(size >= 40 ? AppRadius.md : AppRadius.xs),
      ),
      child: Icon(icon, size: size * 0.5, color: isDark ? AppColors.darkTextPrimary : AppColors.ink),
    );
  }
}
