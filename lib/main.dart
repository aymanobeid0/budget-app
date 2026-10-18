import 'dart:async';

import 'package:flutter/material.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/database/open_app_database.dart';
import 'core/format/money.dart';
import 'core/month/chosen_month_cubit.dart';
import 'core/network/supabase_bootstrap.dart';
import 'core/sync/cloud_sync_client.dart';
import 'core/sync/sync_engine.dart';
import 'core/theme/theme_cubit.dart';
import 'features/account/account_service.dart';
import 'features/account/data/account_prefs.dart';
import 'features/account/data/auth_gateway.dart';
import 'features/categories/category_store.dart';
import 'features/expenses/expense_ledger.dart';
import 'features/income/cubit/net_period_cubit.dart';
import 'features/income/income_ledger.dart';
import 'features/income/net.dart';
import 'features/settings/cubit/currency_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.load();
  // Local-first: SQLite opens before anything else. Feature modules
  // receive the database via constructor injection.
  final db = await openAppDatabase();
  final supabaseClient = await initSupabase();

  SyncEngine? syncEngine;
  AccountService? accountService;
  if (supabaseClient != null) {
    final cloudClient = SupabaseCloudSyncClient(supabaseClient);
    syncEngine = SyncEngine(db: db, client: cloudClient);
    accountService = AccountService(
      db: db,
      auth: SupabaseAuthGateway(supabaseClient),
      syncEngine: syncEngine,
      prefsStorage: FileAccountPrefsStorage(),
    );
    await accountService.init();
    unawaited(syncEngine.sync().then((_) {}));
  }

  final categoryStore = CategoryStore(
    db,
    syncEngine: syncEngine,
    canSeedDefaults: accountService?.canSeedDefaults,
  );
  final expenseLedger = ExpenseLedger(db, syncEngine: syncEngine);
  final incomeLedger = IncomeLedger(
    db,
    syncEngine: syncEngine,
    canSeedDefaults: accountService?.canSeedDefaults,
  );

  // Light by default; a saved choice from a previous launch wins.
  final themeStorage = FileThemeStorage();
  final themeCubit = ThemeCubit(
    storage: themeStorage,
    initial: await themeStorage.read() ?? ThemeMode.light,
  );

  // This month by default; the period picked last time wins.
  final netPeriodStorage = NetPeriodStorage.file();
  final netPeriodCubit = NetPeriodCubit(
    storage: netPeriodStorage,
    initial: await netPeriodStorage.read() ?? NetPeriod.month,
  );

  // The month Home and the Income tab show: not saved, so every launch opens
  // on the current month.
  final chosenMonthCubit = ChosenMonthCubit();

  // Currency.fallback (MRU) by default; the Currency picked last time wins.
  final currencyStorage = CurrencyStorage.file();
  final currencyCubit = CurrencyCubit(
    storage: currencyStorage,
    initial: await currencyStorage.read() ?? Currency.fallback,
  );

  runApp(BudgetApp(
    categoryStore: categoryStore,
    expenseLedger: expenseLedger,
    incomeLedger: incomeLedger,
    syncEngine: syncEngine,
    themeCubit: themeCubit,
    netPeriodCubit: netPeriodCubit,
    chosenMonthCubit: chosenMonthCubit,
    currencyCubit: currencyCubit,
    accountService: accountService,
  ));
}
