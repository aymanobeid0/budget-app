import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/tokens.dart';

/// Bottom-navigation scaffold: five icon-only tabs, each opening its page.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: AppNavBar(
        currentIndex: navigationShell.currentIndex,
        onSelect: (i) => navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex,
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.branch, this.key, this.label, this.icon, this.selectedIcon, {this.badge});
  final int branch; // index in the router's branches
  final String key;
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  /// A small glyph on the icon's top-right corner, like the arrow of money
  /// leaving the Expenses wallet.
  final IconData? badge;
}

class AppNavBar extends StatelessWidget {
  const AppNavBar({
    super.key,
    required this.currentIndex,
    required this.onSelect,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;

  static const _items = [
    _NavItem(0, 'home', 'Home', Icons.home_outlined, Icons.home_rounded),
    _NavItem(1, 'income', 'Income', Icons.payments_outlined, Icons.payments_rounded),
    _NavItem(2, 'expenses', 'Expenses', Icons.account_balance_wallet_outlined, Icons.account_balance_wallet_rounded,
        badge: Icons.north_east_rounded),
    _NavItem(3, 'consultant', 'Consultant', Icons.auto_awesome_outlined, Icons.auto_awesome),
    _NavItem(4, 'settings', 'Profile and settings', Icons.person_outline_rounded, Icons.person_rounded),
  ];

  static const _barHeight = 72.0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    Widget tab(_NavItem item) => Expanded(
          child: _NavTab(
            item: item,
            selected: currentIndex == item.branch,
            onTap: () => onSelect(item.branch),
          ),
        );

    return Container(
      height: _barHeight + bottomInset,
      padding: EdgeInsets.only(left: 12, right: 12, bottom: bottomInset),
      decoration: BoxDecoration(
        color: scheme.surface,
        boxShadow: isDark ? null : AppShadows.navBar,
        border: isDark ? const Border(top: BorderSide(color: AppColors.darkBorder)) : null,
      ),
      child: Row(children: _items.map(tab).toList()),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({required this.item, required this.selected, required this.onTap});
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final active = isDark ? AppColors.accentTextDark : AppColors.primary;
    final color = selected ? active : (isDark ? AppColors.darkTextSecondary : AppColors.navInactive);

    return Tooltip(
      message: item.label,
      child: Semantics(
        button: true,
        selected: selected,
        label: item.label,
        excludeSemantics: true,
        child: InkWell(
          key: Key('nav-${item.key}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: SizedBox(
            height: 56,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _TabIcon(icon: selected ? item.selectedIcon : item.icon, badge: item.badge, color: color),
                const SizedBox(height: 5),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: selected ? active : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabIcon extends StatelessWidget {
  const _TabIcon({required this.icon, required this.badge, required this.color});
  final IconData icon;
  final IconData? badge;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final glyph = Icon(icon, size: 26, color: color);
    if (badge == null) return glyph;
    return SizedBox(
      width: 30,
      height: 26,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(left: 0, bottom: 0, child: glyph),
          Positioned(
            right: -2,
            top: -3,
            // Cut out of the icon in the bar's colour, so the badge reads apart.
            child: Container(
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, shape: BoxShape.circle),
              padding: const EdgeInsets.all(1),
              child: Icon(badge, size: 14, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
