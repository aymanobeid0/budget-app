import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/categories/category_store.dart';
import 'features/categories/cubit/category_cubit.dart';
import 'features/expenses/cubit/expense_cubit.dart';
import 'features/expenses/expense_ledger.dart';

class BudgetApp extends StatefulWidget {
  const BudgetApp({
    super.key,
    this.categoryStore,
    this.expenseLedger,
  });

  final CategoryStore? categoryStore;
  final ExpenseLedger? expenseLedger;

  @override
  State<BudgetApp> createState() => _BudgetAppState();
}

class _BudgetAppState extends State<BudgetApp> {
  late final _router = buildRouter();

  @override
  Widget build(BuildContext context) {
    Widget app = MaterialApp.router(
      title: 'Budget',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: _router,
    );

    final providers = <BlocProvider>[];
    if (widget.categoryStore != null) {
      providers.add(
        BlocProvider<CategoryCubit>(
          lazy: false,
          create: (_) => CategoryCubit(widget.categoryStore!)..load(),
        ),
      );
    }
    if (widget.expenseLedger != null) {
      providers.add(
        BlocProvider<ExpenseCubit>(
          lazy: false,
          create: (_) => ExpenseCubit(widget.expenseLedger!)..load(),
        ),
      );
    }

    if (providers.isNotEmpty) {
      app = MultiBlocProvider(
        providers: providers,
        child: app,
      );
    }

    return app;
  }
}
