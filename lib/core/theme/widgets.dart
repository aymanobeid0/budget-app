import 'package:flutter/material.dart';

import 'tokens.dart';

bool isDarkOf(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

// Monex depth: white cards float on the grey canvas on one wide, faint
// shadow (shadows/grey-64). Dark mode lifts cards by tone instead.

/// A card on the page: total cards, Net, the week strip.
BoxDecoration panelDecoration(BuildContext context, {double radius = AppRadius.xl}) {
  final dark = isDarkOf(context);
  return BoxDecoration(
    color: dark ? AppColors.darkSurface : AppColors.surface,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: dark ? null : AppShadows.card,
  );
}

/// The brand gradient fill, with its blue glow in light mode.
BoxDecoration gradientDecoration(BuildContext context, {double radius = AppRadius.xl, bool glow = true}) =>
    BoxDecoration(
      gradient: AppGradients.brand,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: glow && !isDarkOf(context) ? AppShadows.brand : null,
    );

/// For [Material]-based chips and cards: the card's fill and shape.
Color panelColor(BuildContext context) => isDarkOf(context) ? AppColors.darkSurface : AppColors.surface;
ShapeBorder panelShape(BuildContext context, double radius) =>
    RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));

/// The grey rounded square behind a list row's icon (Monex entry rows).
class IconTile extends StatelessWidget {
  const IconTile({super.key, required this.icon, this.color, this.size = 44});

  final IconData icon;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final dark = isDarkOf(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: dark ? AppColors.darkBorder : AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Icon(icon, size: size * 0.5, color: color ?? (dark ? AppColors.darkTextPrimary : AppColors.ink)),
    );
  }
}

/// An outlined white square with a ripple: the shell of header icon buttons
/// (Monex back and "more" buttons).
class RaisedSurface extends StatelessWidget {
  const RaisedSurface({super.key, required this.child, this.onTap, this.radius = AppRadius.md, this.inkKey});

  final Widget child;
  final VoidCallback? onTap;
  final double radius;
  final Key? inkKey;

  @override
  Widget build(BuildContext context) {
    final dark = isDarkOf(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: dark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: dark ? AppColors.darkBorder : AppColors.divider),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(key: inkKey, borderRadius: BorderRadius.circular(radius), onTap: onTap, child: child),
      ),
    );
  }
}

/// 44px outlined square icon button used in every screen header.
class SquareIconButton extends StatelessWidget {
  const SquareIconButton({super.key, required this.icon, required this.tooltip, required this.onTap, this.color});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: RaisedSurface(
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 21, color: color ?? scheme.onSurface, semanticLabel: tooltip),
        ),
      ),
    );
  }
}

/// Header row: optional left/right widgets around a centered title.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({super.key, required this.title, this.leading, this.trailing});

  final String title;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.xl, AppSpace.gutter, 0),
      // At least 44 tall; taller when a large text size needs it.
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Row(
          children: [
            SizedBox(width: 44, child: leading),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppType.screenTitle.copyWith(color: scheme.onSurface),
              ),
            ),
            SizedBox(width: 44, child: trailing),
          ],
        ),
      ),
    );
  }
}

/// Solid colored square with a white icon (Categories, Profile menus).
class SolidIconTile extends StatelessWidget {
  const SolidIconTile({super.key, required this.icon, required this.color, this.size = 36});

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size >= 32 ? AppRadius.sm : AppRadius.xs),
      ),
      child: Icon(icon, size: size * 0.52, color: Colors.white),
    );
  }
}

/// Settings-style row: solid tile, title (+ subtitle), trailing, divider.
class MenuRow extends StatelessWidget {
  const MenuRow({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showDivider = true,
    this.destructive = false,
    this.leading,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;
  final bool destructive;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final row = Container(
      constraints: const BoxConstraints(minHeight: 62),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        border: showDivider ? Border(bottom: BorderSide(color: scheme.outlineVariant)) : null,
      ),
      child: Row(
        children: [
          leading ?? SolidIconTile(icon: icon, color: color),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppType.menuTitle.copyWith(color: destructive ? AppColors.expense : scheme.onSurface),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
    if (onTap == null) return row;
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(AppRadius.md), child: row);
  }
}

class Chevron extends StatelessWidget {
  const Chevron({super.key});

  @override
  Widget build(BuildContext context) => const Icon(Icons.chevron_right_rounded, size: 22, color: AppColors.chevron);
}

/// [child] as a centered column at most [AppLayout.readableWidth] wide, on
/// the page background. A no-op on phones; on tablets and desktop windows the
/// page stays readable instead of stretching.
class ReadablePage extends StatelessWidget {
  const ReadablePage({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppLayout.readableWidth),
          child: child,
        ),
      ),
    );
  }
}

/// A tab's add action ("Add Expense", "Add Income"): a plus in the same
/// outlined white square as every other header button, at the header's top
/// left. The label is its tooltip and spoken name.
class AddEntryButton extends StatelessWidget {
  const AddEntryButton({super.key, required this.label, required this.tooltip, required this.onPressed});

  final String label;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: RaisedSurface(
        onTap: onPressed,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(Icons.add_rounded, size: 24, color: scheme.onSurface, semanticLabel: label),
        ),
      ),
    );
  }
}

/// Full-width primary action: the brand gradient, an all-caps label and the
/// blue glow (Monex "ADD EXPENSE").
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, required this.onPressed, this.busy = false});

  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;
    return Opacity(
      opacity: onPressed == null ? 0.5 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppGradients.button,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: enabled && !isDarkOf(context) ? AppShadows.button : null,
        ),
        child: FilledButton(
          onPressed: busy ? null : onPressed,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            disabledForegroundColor: Colors.white,
            shadowColor: Colors.transparent,
          ),
          child: busy
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                )
              : Text(label.toUpperCase(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}
