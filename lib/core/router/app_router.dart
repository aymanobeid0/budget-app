import 'package:go_router/go_router.dart';

import '../../features/categories/ui/categories_screen.dart';
import '../../features/consultant/ui/consultant_screen.dart';
import '../../features/expenses/ui/expenses_screen.dart';
import 'app_shell.dart';

GoRouter buildRouter() => GoRouter(
      initialLocation: '/expenses',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => AppShell(navigationShell: shell),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/expenses',
                builder: (_, _) => const ExpensesScreen(),
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/categories',
                builder: (_, _) => const CategoriesScreen(),
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/consultant',
                builder: (_, _) => const ConsultantScreen(),
              ),
            ]),
          ],
        ),
      ],
    );
