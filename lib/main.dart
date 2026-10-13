import 'package:flutter/material.dart';

import 'app.dart';
import 'core/database/open_app_database.dart';
import 'core/network/supabase_bootstrap.dart';
import 'features/categories/category_store.dart';
import 'features/expenses/expense_ledger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Local-first: SQLite opens before anything else. Feature modules
  // receive the database via constructor injection.
  final db = await openAppDatabase();
  final categoryStore = CategoryStore(db);
  final expenseLedger = ExpenseLedger(db);
  await initSupabase();
  runApp(BudgetApp(
    categoryStore: categoryStore,
    expenseLedger: expenseLedger,
  ));
}
