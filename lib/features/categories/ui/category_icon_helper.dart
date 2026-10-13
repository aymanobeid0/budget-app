import 'package:flutter/material.dart';

class CategoryIconHelper {
  const CategoryIconHelper._();

  static const Map<String, IconData> availableIcons = {
    'restaurant': Icons.restaurant,
    'directions_car': Icons.directions_car,
    'power': Icons.power,
    'movie': Icons.movie,
    'local_hospital': Icons.local_hospital,
    'shopping_bag': Icons.shopping_bag,
    'fitness_center': Icons.fitness_center,
    'coffee': Icons.coffee,
    'flight': Icons.flight,
    'school': Icons.school,
    'pets': Icons.pets,
    'home': Icons.home,
    'work': Icons.work,
    'receipt': Icons.receipt,
    'savings': Icons.savings,
  };

  static IconData getIcon(String iconName) {
    return availableIcons[iconName] ?? Icons.category;
  }
}
