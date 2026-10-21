import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/month/chosen_month_cubit.dart';
import 'core/prefs/text_pref.dart';
import 'core/router/app_router.dart';
import 'core/sync/sync_engine.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'features/account/account_service.dart';
import 'features/account/cubit/account_cubit.dart';
import 'features/ai_provider/cubit/ai_provider_cubit.dart';
import 'features/ai_provider/data/ai_provider_store.dart';
import 'features/ai_provider/data/secret_store.dart';
import 'features/categories/category_store.dart';
import 'features/categories/cubit/category_cubit.dart';
import 'features/consultant/cubit/consultant_cubit.dart';
import 'features/consultant/data/consultant_client.dart';
import 'features/expenses/cubit/expense_cubit.dart';
import 'features/expenses/expense_ledger.dart';
import 'features/income/cubit/income_cubit.dart';
import 'features/income/cubit/net_period_cubit.dart';
import 'features/income/income_ledger.dart';
import 'features/settings/cubit/currency_cubit.dart';

class BudgetApp extends StatefulWidget {
  const BudgetApp({
    super.key,
    this.categoryStore,
    this.expenseLedger,
    this.incomeLedger,
    this.syncEngine,
    this.consultantClient,
    this.aiProviderStore,
    this.themeCubit,
    this.netPeriodCubit,
    this.chosenMonthCubit,
    this.currencyCubit,
    this.accountService,
  });

  final CategoryStore? categoryStore;
  final ExpenseLedger? expenseLedger;
  final IncomeLedger? incomeLedger;
  final SyncEngine? syncEngine;
  final ConsultantClient? consultantClient;

  /// The user's AI Provider keys; its client answers for the Consultant
  /// unless [consultantClient] is given. Defaults to none saved, in memory.
  final AiProviderStore? aiProviderStore;

  /// Light/dark mode. Defaults to light, kept in memory, when not given.
  final ThemeCubit? themeCubit;

  /// Home's Net period. Defaults to this month, kept in memory, when not given.
  final NetPeriodCubit? netPeriodCubit;

  /// The month Home and the Income tab show. Defaults to the current month
  /// by the device clock when not given.
  final ChosenMonthCubit? chosenMonthCubit;

  /// The Currency amounts are labelled with. Defaults to `Currency.fallback`, kept in
  /// memory, when not given.
  final CurrencyCubit? currencyCubit;

  /// Username/password accounts. Null when Supabase isn't configured.
  final AccountService? accountService;

  @override
  State<BudgetApp> createState() => _BudgetAppState();
}

class _BudgetAppState extends State<BudgetApp> {
  late final _router = buildRouter();
  late final ThemeCubit _themeCubit = widget.themeCubit ?? ThemeCubit();
  late final NetPeriodCubit _netPeriodCubit = widget.netPeriodCubit ?? NetPeriodCubit();
  late final ChosenMonthCubit _chosenMonthCubit = widget.chosenMonthCubit ?? ChosenMonthCubit();
  late final CurrencyCubit _currencyCubit = widget.currencyCubit ?? CurrencyCubit();
  late final AiProviderCubit _aiProviderCubit = AiProviderCubit(widget.aiProviderStore ??
      AiProviderStore(secrets: InMemorySecretStore(), prefs: InMemoryTextPref(), adapters: const {}));

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
              currency: () => _currencyCubit.state,
              client: widget.consultantClient ?? _aiProviderCubit.store.consultantClient,
            )
          : null;
  late final AccountCubit _accountCubit = AccountCubit(
    widget.accountService,
    onDataReplaced: _reloadAfterAccountChange,
  )..resume();

  /// Coming back to the foreground is the cheapest sign the connection may be
  /// back: sync whatever was changed while away. It's also when a new month
  /// may have begun, so the chosen month follows the clock.
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: () {
      _chosenMonthCubit.followClock();
      widget.syncEngine?.sync();
    });
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
    if (widget.chosenMonthCubit == null) _chosenMonthCubit.close();
    if (widget.currencyCubit == null) _currencyCubit.close();
    _categoryCubit?.close();
    _expenseCubit?.close();
    _incomeCubit?.close();
    _consultantCubit?.close();
    _aiProviderCubit.close();
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
      BlocProvider<ChosenMonthCubit>.value(value: _chosenMonthCubit),
      BlocProvider<CurrencyCubit>.value(value: _currencyCubit),
      BlocProvider<AccountCubit>.value(value: _accountCubit),
      BlocProvider<AiProviderCubit>.value(value: _aiProviderCubit),
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
