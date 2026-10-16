import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'theme_cubit.dart';
import 'tokens.dart';

/// Square sun/moon header button that flips between light and dark mode.
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = context.watch<ThemeCubit>().isDark;
    final label = isDark ? 'Switch to light mode' : 'Switch to dark mode';

    return Tooltip(
      message: label,
      child: Material(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          key: const Key('theme-toggle'),
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: () => context.read<ThemeCubit>().toggle(),
          child: SizedBox(
            width: 44,
            height: 44,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) => RotationTransition(
                turns: Tween(begin: 0.75, end: 1.0).animate(anim),
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                key: ValueKey(isDark),
                size: 21,
                color: scheme.onSurface,
                semanticLabel: label,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
