import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/expenses/ui/expense_form_sheet.dart';
import '../theme/tokens.dart';

/// Bottom-navigation scaffold: icon-only tabs with a raised blue
/// "add expense" button in the centre.
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
        onAdd: () => showExpenseSheet(context),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.branch, this.key, this.label, this.icon, this.selectedIcon);
  final int branch; // index in the router's branches
  final String key;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class AppNavBar extends StatelessWidget {
  const AppNavBar({
    super.key,
    required this.currentIndex,
    required this.onSelect,
    required this.onAdd,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onAdd;

  // Visual order: Home, [+], Consultant, Profile. Categories live in Profile.
  static const _left = [
    _NavItem(0, 'expenses', 'Home', Icons.home_outlined, Icons.home_rounded),
  ];
  static const _right = [
    _NavItem(1, 'consultant', 'Consultant', Icons.auto_awesome_outlined, Icons.auto_awesome),
    _NavItem(2, 'settings', 'Profile and settings', Icons.person_outline_rounded, Icons.person_rounded),
  ];

  static const _barHeight = 72.0;
  static const _rise = 30.0;
  static const _addSize = 60.0;
  static const _ring = 5.0;

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

    return SizedBox(
      height: _barHeight + bottomInset + _rise,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: _barHeight + bottomInset,
            child: Container(
              padding: EdgeInsets.only(left: 12, right: 12, bottom: bottomInset),
              decoration: BoxDecoration(
                color: scheme.surface,
                boxShadow: isDark ? null : AppShadows.navBar,
                border: isDark ? const Border(top: BorderSide(color: AppColors.darkBorder)) : null,
              ),
              child: Row(
                children: [
                  ..._left.map(tab),
                  const SizedBox(width: _addSize + _ring * 2 + 12),
                  ..._right.map(tab),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Tooltip(
                message: 'Add expense',
                child: Container(
                  key: const Key('add-expense-fab'),
                  width: _addSize + _ring * 2,
                  height: _addSize + _ring * 2,
                  decoration: BoxDecoration(color: scheme.surface, shape: BoxShape.circle),
                  padding: const EdgeInsets.all(_ring),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: isDark ? null : AppShadows.fab,
                    ),
                    child: Material(
                      color: scheme.primary,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onAdd,
                        child: const Center(
                          child: Icon(Icons.add_rounded, size: 30, color: Colors.white, semanticLabel: 'Add expense'),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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
                Icon(selected ? item.selectedIcon : item.icon, size: 26, color: color),
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
