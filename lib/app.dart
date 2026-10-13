import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/categories/category_store.dart';
import 'features/categories/cubit/category_cubit.dart';

class BudgetApp extends StatefulWidget {
  const BudgetApp({super.key, this.categoryStore});

  final CategoryStore? categoryStore;

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

    if (widget.categoryStore != null) {
      app = BlocProvider(
        lazy: false,
        create: (_) => CategoryCubit(widget.categoryStore!)..load(),
        child: app,
      );
    }

    return app;
  }
}
