import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/tokens.dart';
import '../theme/widgets.dart';

/// The five tabs around the current page.
///
/// On phones and tablets, the Monex tab bar: five icons, evenly spaced. Each
/// tab that adds something carries its own add button in its header.
///
/// From [AppLayout.railMinWidth] on Android and desktop, a navigation rail on
/// the left instead, as Material 3 lays out a wide window. Either way the page itself is a [ReadablePage] column.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _select(int i) => navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex);

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;
    final apple = platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
    final wide = MediaQuery.sizeOf(context).width >= AppLayout.railMinWidth;
    final page = ReadablePage(child: navigationShell);

    if (wide && !apple) {
      return Scaffold(
        body: Row(
          children: [
            AppNavRail(currentIndex: navigationShell.currentIndex, onSelect: _select),
            VerticalDivider(width: 1, color: Theme.of(context).colorScheme.outlineVariant),
            Expanded(child: page),
          ],
        ),
      );
    }
    return Scaffold(
      extendBody: true,
      body: page,
      bottomNavigationBar: AppNavBar(currentIndex: navigationShell.currentIndex, onSelect: _select),
    );
  }
}

/// The tabs as a Material 3 navigation rail, for wide windows.
class AppNavRail extends StatelessWidget {
  const AppNavRail({super.key, required this.currentIndex, required this.onSelect});

  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: currentIndex,
      onDestinationSelected: onSelect,
      labelType: NavigationRailLabelType.all,
      groupAlignment: -1,
      leading: const SizedBox(height: AppSpace.xl),
      destinations: [
        for (final item in AppNavBar._items)
          NavigationRailDestination(
            icon: Icon(item.icon),
            selectedIcon: Icon(item.selectedIcon),
            label: Text(item.label),
          ),
      ],
    );
  }
}

class _NavItem {
  const _NavItem(this.key, this.label, this.icon, this.selectedIcon);
  final String key;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// The Monex tab bar: a white bar of five evenly spaced icons, the selected
/// one in the cards' blue gradient.
class AppNavBar extends StatelessWidget {
  const AppNavBar({super.key, required this.currentIndex, required this.onSelect});

  final int currentIndex;
  final ValueChanged<int> onSelect;

  // In router branch order.
  static const _items = [
    _NavItem('home', 'Home', Icons.home_outlined, Icons.home_rounded),
    _NavItem('income', 'Income', Icons.payments_outlined, Icons.payments_rounded),
    _NavItem('expenses', 'Expenses', Icons.receipt_long_outlined, Icons.receipt_long_rounded),
    _NavItem('consultant', 'Consultant', Icons.auto_awesome_outlined, Icons.auto_awesome),
    _NavItem('settings', 'Profile', Icons.person_outline_rounded, Icons.person_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final dark = isDarkOf(context);
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: dark ? AppColors.darkSurface : AppColors.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: _NavTab(
                    item: _items[i],
                    selected: i == currentIndex,
                    color: AppColors.chevron,
                    onTap: () => onSelect(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One icon in the bar. Its label is spoken and shown on long press.
class _NavTab extends StatelessWidget {
  const _NavTab({required this.item, required this.selected, required this.color, required this.onTap});
  final _NavItem item;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      excludeSemantics: true,
      child: Tooltip(
        message: item.label,
        child: InkResponse(
          key: Key('nav-${item.key}'),
          onTap: onTap,
          radius: 28,
          child: SizedBox.expand(
            child: selected
                // The selected tab wears the cards' blue-to-sky gradient.
                ? ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: AppGradients.brand.createShader,
                    child: Icon(item.selectedIcon, size: 26, color: Colors.white),
                  )
                : Icon(item.icon, size: 26, color: color),
          ),
        ),
      ),
    );
  }
}
