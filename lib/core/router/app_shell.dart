import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/expenses/ui/expense_form_sheet.dart';
import '../theme/tokens.dart';

/// Bottom-navigation scaffold: four tabs with a raised "add expense" button
/// docked in the centre of the bar.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: CalmNavBar(
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
  const _NavItem(this.label, this.icon, this.selectedIcon);
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class CalmNavBar extends StatelessWidget {
  const CalmNavBar({
    super.key,
    required this.currentIndex,
    required this.onSelect,
    required this.onAdd,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onAdd;

  static const items = [
    _NavItem('Expenses', Icons.format_list_bulleted_rounded, Icons.format_list_bulleted_rounded),
    _NavItem('Categories', Icons.grid_view_outlined, Icons.grid_view_rounded),
    _NavItem('Consultant', Icons.auto_awesome_outlined, Icons.auto_awesome_rounded),
    _NavItem('Settings', Icons.tune_rounded, Icons.tune_rounded),
  ];

  static const _barHeight = 72.0;
  static const _rise = 26.0; // how far the add button sits above the bar
  static const _addSize = 60.0;
  static const _ring = 5.0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    Widget tab(int i) => Expanded(
          child: _NavTab(
            item: items[i],
            selected: currentIndex == i,
            onTap: () => onSelect(i),
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
              padding: EdgeInsets.only(left: 6, right: 6, bottom: bottomInset),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
                boxShadow: isDark ? null : AppShadows.navBar,
                border: isDark ? const Border(top: BorderSide(color: AppColors.darkBorder)) : null,
              ),
              child: Row(
                children: [
                  tab(0),
                  tab(1),
                  const SizedBox(width: _addSize + _ring * 2 + 8),
                  tab(2),
                  tab(3),
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
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(_ring),
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: AppShadows.fab,
                    ),
                    child: Material(
                      color: AppColors.primary,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onAdd,
                        child: const Center(
                          child: Icon(
                            Icons.add_rounded,
                            size: 30,
                            color: Colors.white,
                            semanticLabel: 'Add expense',
                          ),
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
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? AppColors.primary : AppColors.textMuted;

    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        key: Key('nav-${item.label.toLowerCase()}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 56,
              height: 30,
              decoration: BoxDecoration(
                color: selected ? scheme.primaryContainer : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Icon(selected ? item.selectedIcon : item.icon, size: 21, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
              style: AppType.navLabel.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
