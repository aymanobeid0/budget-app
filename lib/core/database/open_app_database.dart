import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'app_database.dart';

/// Picks the right SQLite factory per platform and opens the app database.
Future<AppDatabase> openAppDatabase() async {
  final DatabaseFactory factory;
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
    sqfliteFfiInit();
    factory = databaseFactoryFfi;
  } else {
    factory = databaseFactory;
  }
  final dir = await getApplicationSupportDirectory();
  return AppDatabase.open(
    factory: factory,
    path: p.join(dir.path, 'budget_app.db'),
  );
}
