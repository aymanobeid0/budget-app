import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';

/// Initialises the Supabase client against the local Docker stack.
///
/// Returns `null` when no anon key is configured so the app still runs
/// fully offline (local-first); sync simply stays disabled.
Future<SupabaseClient?> initSupabase() async {
  if (!AppConfig.hasSupabase) {
    debugPrint('Supabase disabled: SUPABASE_ANON_KEY not provided.');
    return null;
  }
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabaseAnonKey,
  );
  return Supabase.instance.client;
}
