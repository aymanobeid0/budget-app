import 'package:flutter/material.dart';

import '../../../core/theme/empty_state.dart';

/// Placeholder until ticket 02 (Category management).
class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('categories-screen'),
      appBar: AppBar(title: const Text('Categories')),
      body: const EmptyState(
        icon: Icons.category,
        title: 'Categories',
        message: 'Organise your spending with custom categories.',
      ),
    );
  }
}
