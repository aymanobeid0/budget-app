import 'package:flutter/material.dart';

import 'app.dart';
import 'core/database/open_app_database.dart';
import 'core/network/supabase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Local-first: SQLite opens before anything else. Feature modules
  // (tickets 02+) will receive these via constructor injection.
  await openAppDatabase();
  await initSupabase();
  runApp(const BudgetApp());
}
