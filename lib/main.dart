import 'dart:async';

import 'package:flutter/material.dart';

import 'app.dart';
import 'core/database/open_app_database.dart';
import 'core/network/supabase_bootstrap.dart';
import 'core/sync/cloud_sync_client.dart';
import 'core/sync/sync_engine.dart';
import 'features/categories/category_store.dart';
import 'features/expenses/expense_ledger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Local-first: SQLite opens before anything else. Feature modules
  // receive the database via constructor injection.
  final db = await openAppDatabase();
  final supabaseClient = await initSupabase();

  SyncEngine? syncEngine;
  if (supabaseClient != null) {
    final cloudClient = SupabaseCloudSyncClient(supabaseClient);
    syncEngine = SyncEngine(db: db, client: cloudClient);
    unawaited(syncEngine.sync().then((_) {}));
  }

  final categoryStore = CategoryStore(db, syncEngine: syncEngine);
  final expenseLedger = ExpenseLedger(db, syncEngine: syncEngine);

  runApp(BudgetApp(
    categoryStore: categoryStore,
    expenseLedger: expenseLedger,
    syncEngine: syncEngine,
  ));
}
