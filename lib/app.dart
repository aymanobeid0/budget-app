import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/config/app_config.dart';
import 'core/router/app_router.dart';
import 'core/sync/sync_engine.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'features/account/account_service.dart';
import 'features/account/cubit/account_cubit.dart';
import 'features/categories/category_store.dart';
import 'features/categories/cubit/category_cubit.dart';
import 'features/consultant/cubit/consultant_cubit.dart';
import 'features/consultant/data/consultant_client.dart';
import 'features/expenses/cubit/expense_cubit.dart';
import 'features/expenses/expense_ledger.dart';
import 'features/income/cubit/income_cubit.dart';
import 'features/income/cubit/net_period_cubit.dart';
import 'features/income/income_ledger.dart';

class BudgetApp extends StatefulWidget {
  const BudgetApp({
    super.key,
    this.categoryStore,
    this.expenseLedger,
    this.incomeLedger,
    this.syncEngine,
    this.consultantClient,
    this.themeCubit,
    this.netPeriodCubit,
    this.accountService,
  });

  final CategoryStore? categoryStore;
  final ExpenseLedger? expenseLedger;
  final IncomeLedger? incomeLedger;
  final SyncEngine? syncEngine;
  final ConsultantClient? consultantClient;

  /// Light/dark mode. Defaults to light, kept in memory, when not given.
  final ThemeCubit? themeCubit;

  /// Home's Net period. Defaults to this month, kept in memory, when not given.
  final NetPeriodCubit? netPeriodCubit;

  /// Username/password accounts. Null when Supabase isn't configured.
  final AccountService? accountService;

  @override
  State<BudgetApp> createState() => _BudgetAppState();
}

class _BudgetAppState extends State<BudgetApp> {
  late final _router = buildRouter();
  late final ThemeCubit _themeCubit = widget.themeCubit ?? ThemeCubit();
  late final NetPeriodCubit _netPeriodCubit = widget.netPeriodCubit ?? NetPeriodCubit();

  late final CategoryCubit? _categoryCubit =
      widget.categoryStore == null ? null : (CategoryCubit(widget.categoryStore!)..load());
  late final ExpenseCubit? _expenseCubit =
      widget.expenseLedger == null ? null : (ExpenseCubit(widget.expenseLedger!)..load());
  late final IncomeCubit? _incomeCubit =
      widget.incomeLedger == null ? null : (IncomeCubit(widget.incomeLedger!)..load());
  late final ConsultantCubit? _consultantCubit =
      (widget.categoryStore != null && widget.expenseLedger != null)
          ? ConsultantCubit(
              ledger: widget.expenseLedger!,
              categoryStore: widget.categoryStore!,
              incomeLedger: widget.incomeLedger,
              client: widget.consultantClient ??
                  GeminiConsultantClient(apiKey: AppConfig.geminiApiKey),
            )
          : null;
  late final AccountCubit _accountCubit = AccountCubit(
    widget.accountService,
    onDataReplaced: _reloadAfterAccountChange,
  )..resume();

  /// Coming back to the foreground is the cheapest sign the connection may be
  /// back: sync whatever was changed while away.
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: () => widget.syncEngine?.sync());
  }

  /// The phone now holds a different account's data: reload every list and
  /// drop the previous account's chat.
  Future<void> _reloadAfterAccountChange() async {
    await _categoryCubit?.load();
    await _expenseCubit?.load();
    await _incomeCubit?.load();
    _consultantCubit?.clearChat();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    if (widget.themeCubit == null) _themeCubit.close();
    if (widget.netPeriodCubit == null) _netPeriodCubit.close();
    _categoryCubit?.close();
    _expenseCubit?.close();
    _incomeCubit?.close();
    _consultantCubit?.close();
    _accountCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget app = BlocBuilder<ThemeCubit, ThemeMode>(
      bloc: _themeCubit,
      builder: (context, mode) => MaterialApp.router(
        title: 'Budget',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: mode,
        routerConfig: _router,
      ),
    );

    final providers = <BlocProvider>[
      BlocProvider<ThemeCubit>.value(value: _themeCubit),
      BlocProvider<NetPeriodCubit>.value(value: _netPeriodCubit),
      BlocProvider<AccountCubit>.value(value: _accountCubit),
      if (_categoryCubit != null) BlocProvider<CategoryCubit>.value(value: _categoryCubit),
      if (_expenseCubit != null) BlocProvider<ExpenseCubit>.value(value: _expenseCubit),
      if (_incomeCubit != null) BlocProvider<IncomeCubit>.value(value: _incomeCubit),
      if (_consultantCubit != null) BlocProvider<ConsultantCubit>.value(value: _consultantCubit),
    ];

    if (providers.isNotEmpty) {
      app = MultiBlocProvider(
        providers: providers,
        child: app,
      );
    }

    if (widget.syncEngine != null) {
      app = RepositoryProvider<SyncEngine>.value(
        value: widget.syncEngine!,
        child: app,
      );
    }

    return app;
  }
}
