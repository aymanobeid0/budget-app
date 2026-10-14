import 'dart:io';

import 'package:flutter/foundation.dart';

/// Runtime and build-time configuration.
///
/// Priority:
/// 1. Compile-time `--dart-define` / `--dart-define-from-file=.env`.
/// 2. If running locally/desktop and empty, automatically parses the root `.env` file on disk.
class AppConfig {
  const AppConfig._();

  static String _supabaseUrl = const String.fromEnvironment('SUPABASE_URL');
  static String _supabaseAnonKey = const String.fromEnvironment('SUPABASE_ANON_KEY');
  static String _geminiApiKey = const String.fromEnvironment('GEMINI_API_KEY');

  static void load() {
    // If environment defines are already present, keep them.
    if (_supabaseAnonKey.isNotEmpty) return;

    // Fallback: parse root .env file if running on desktop or development
    try {
      final candidates = [
        File('.env'),
        File('${Directory.current.path}/.env'),
        File('${Directory.current.parent.path}/.env'),
      ];
      for (final file in candidates) {
        if (file.existsSync()) {
          final lines = file.readAsLinesSync();
          for (final line in lines) {
            final trimmed = line.trim();
            if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
            final idx = trimmed.indexOf('=');
            if (idx == -1) continue;
            final key = trimmed.substring(0, idx).trim();
            final value = trimmed.substring(idx + 1).trim();
            if (key == 'SUPABASE_URL' && _supabaseUrl.isEmpty) {
              _supabaseUrl = value;
            } else if (key == 'SUPABASE_ANON_KEY' && _supabaseAnonKey.isEmpty) {
              _supabaseAnonKey = value;
            } else if (key == 'GEMINI_API_KEY' && _geminiApiKey.isEmpty) {
              _geminiApiKey = value;
            }
          }
          if (_supabaseAnonKey.isNotEmpty) break;
        }
      }
    } catch (e) {
      debugPrint('ℹ️ AppConfig .env disk read skipped: $e');
    }
  }

  static String get supabaseUrl => _supabaseUrl;
  static String get supabaseAnonKey => _supabaseAnonKey;
  static bool get hasSupabase => _supabaseAnonKey.isNotEmpty;
  static String get geminiApiKey => _geminiApiKey;
  static bool get hasGemini => _geminiApiKey.isNotEmpty;
}
