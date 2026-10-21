import 'package:go_router/go_router.dart';

import '../../features/ai_provider/ui/ai_provider_screen.dart';
import '../../features/categories/ui/categories_screen.dart';
import '../../features/consultant/ui/consultant_screen.dart';
import '../../features/expenses/ui/expense_list_screen.dart';
import '../../features/expenses/ui/expenses_screen.dart';
import '../../features/income/ui/income_screen.dart';
import '../../features/income/ui/income_sources_screen.dart';
import '../../features/settings/ui/settings_screen.dart';
import 'app_shell.dart';

GoRouter buildRouter() => GoRouter(
      initialLocation: '/home',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => AppShell(navigationShell: shell),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/home',
                builder: (_, _) => const ExpensesScreen(),
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/income',
                builder: (_, _) => const IncomeScreen(),
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/expenses',
                builder: (_, _) => const ExpenseListScreen(),
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/consultant',
                builder: (_, _) => const ConsultantScreen(),
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/settings',
                builder: (_, _) => const SettingsScreen(),
              ),
            ]),
          ],
        ),
        // Outside the shell and opened with push, so they cover the tab bar
        // and Back returns to whichever tab opened them.
        GoRoute(
          path: '/categories',
          builder: (_, _) => const CategoriesScreen(),
        ),
        GoRoute(
          path: '/income-sources',
          builder: (_, _) => const IncomeSourcesScreen(),
        ),
        GoRoute(
          path: '/ai-provider',
          builder: (_, _) => const AiProviderScreen(),
        ),
      ],
    );
