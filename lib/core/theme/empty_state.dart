import 'package:flutter/material.dart';

import 'tokens.dart';

/// A list that couldn't be read from this phone's storage. Says so plainly,
/// keeps the raw exception out of sight, and offers to try again.
class LoadErrorState extends StatelessWidget {
  const LoadErrorState({super.key, required this.what, required this.onRetry});

  /// What failed to load, e.g. "your Expenses".
  final String what;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      key: const Key('load-error'),
      icon: Icons.error_outline_rounded,
      title: "Couldn't load $what",
      message: 'Nothing was deleted. Try again, and if it keeps happening, restart the app.',
      action: OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
    );
  }
}

/// Shared empty state: an elevated icon tile, title, message and optional
/// action.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: dark ? AppColors.darkSurfaceSubtle : AppColors.surfaceSunken,
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: Icon(icon, size: 36, color: dark ? AppColors.accentTextDark : AppColors.primary),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppType.title.copyWith(color: scheme.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, height: 1.45, color: scheme.onSurfaceVariant),
            ),
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
