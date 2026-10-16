import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Where the chosen theme is remembered between launches.
abstract class ThemeStorage {
  Future<ThemeMode?> read();
  Future<void> write(ThemeMode mode);
}

/// Keeps the choice in memory only (tests, or before a store is wired up).
class InMemoryThemeStorage implements ThemeStorage {
  ThemeMode? _mode;

  @override
  Future<ThemeMode?> read() async => _mode;

  @override
  Future<void> write(ThemeMode mode) async => _mode = mode;
}

/// Persists the choice as a one-word file in the app support directory.
class FileThemeStorage implements ThemeStorage {
  Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File(p.join(dir.path, 'theme_mode.txt'));
  }

  @override
  Future<ThemeMode?> read() async {
    try {
      final file = await _file();
      if (!await file.exists()) return null;
      return (await file.readAsString()).trim() == 'dark' ? ThemeMode.dark : ThemeMode.light;
    } catch (_) {
      return null; // unreadable → fall back to the default
    }
  }

  @override
  Future<void> write(ThemeMode mode) async {
    try {
      final file = await _file();
      await file.parent.create(recursive: true);
      await file.writeAsString(mode == ThemeMode.dark ? 'dark' : 'light');
    } catch (_) {
      // Theme still switches for this session even if saving fails.
    }
  }
}

/// Light / dark mode. Light is the default; the app never follows the
/// system setting unless the user picks dark themselves.
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit({ThemeStorage? storage, ThemeMode initial = ThemeMode.light})
      : _storage = storage ?? InMemoryThemeStorage(),
        super(initial == ThemeMode.dark ? ThemeMode.dark : ThemeMode.light);

  final ThemeStorage _storage;

  bool get isDark => state == ThemeMode.dark;

  void toggle() => setMode(isDark ? ThemeMode.light : ThemeMode.dark);

  void setMode(ThemeMode mode) {
    final next = mode == ThemeMode.dark ? ThemeMode.dark : ThemeMode.light;
    if (next == state) return;
    emit(next);
    _storage.write(next);
  }
}
