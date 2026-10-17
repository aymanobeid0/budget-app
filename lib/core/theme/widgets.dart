import 'package:flutter/material.dart';

import 'tokens.dart';

bool isDarkOf(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

/// Raised surface for icon buttons, chips and small panels: white with a
/// soft drop shadow in light mode (no grey fill); a lifted dark tone in dark.
BoxDecoration raisedDecoration(
  BuildContext context, {
  double radius = AppRadius.md,
  List<BoxShadow> shadow = AppShadows.iconButton,
  BoxShape shape = BoxShape.rectangle,
}) {
  final dark = isDarkOf(context);
  return BoxDecoration(
    color: dark ? AppColors.darkSurfaceSubtle : Colors.white,
    shape: shape,
    borderRadius: shape == BoxShape.circle ? null : BorderRadius.circular(radius),
    boxShadow: dark ? null : shadow,
  );
}

/// For [Material]-based chips and cards: white, lifted by elevation.
Color raisedColor(BuildContext context) => isDarkOf(context) ? AppColors.darkSurfaceSubtle : Colors.white;
double raisedElevation(BuildContext context) => isDarkOf(context) ? 0 : 3;
const raisedShadowColor = Color(0x66141A2E);

/// [Material] + [InkWell] on top of [raisedDecoration] so taps ripple.
class RaisedSurface extends StatelessWidget {
  const RaisedSurface({
    super.key,
    required this.child,
    this.onTap,
    this.radius = AppRadius.md,
    this.shadow = AppShadows.iconButton,
    this.inkKey,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double radius;
  final List<BoxShadow> shadow;
  final Key? inkKey;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: raisedDecoration(context, radius: radius, shadow: shadow),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: inkKey,
          borderRadius: BorderRadius.circular(radius),
          onTap: onTap,
          child: child,
        ),
      ),
    );
  }
}

/// 44px soft-grey square icon button used in every screen header.
class SquareIconButton extends StatelessWidget {
  const SquareIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color,
  });

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
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            SizedBox(width: 44, child: leading),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
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
                  style: AppType.menuTitle.copyWith(
                    color: destructive ? AppColors.expense : scheme.onSurface,
                  ),
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
  Widget build(BuildContext context) =>
      const Icon(Icons.chevron_right_rounded, size: 22, color: AppColors.chevron);
}

/// Full-width primary action with the blue glow.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, required this.onPressed, this.busy = false});

  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: onPressed == null || busy || isDarkOf(context) ? null : AppShadows.button,
      ),
      child: FilledButton(
        onPressed: busy ? null : onPressed,
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(58)),
        child: busy
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
              )
            : Text(label, style: const TextStyle(fontSize: 17)),
      ),
    );
  }
}
