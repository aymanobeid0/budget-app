import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';

/// Initialises the Supabase client against the local Docker stack.
///
/// Returns `null` when no anon key is configured so the app still runs
/// fully offline (local-first); sync simply stays disabled.
Future<SupabaseClient?> initSupabase() async {
  if (!AppConfig.hasSupabase) {
    debugPrint('ℹ️ Supabase disabled: SUPABASE_ANON_KEY not provided.');
    return null;
  }
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabaseAnonKey,
  );
  final client = Supabase.instance.client;
  debugPrint('✅ Supabase connected: ${AppConfig.supabaseUrl}');

  // Non-blocking anonymous sign-in for seamless onboarding
  if (client.auth.currentSession == null) {
    client.auth.signInAnonymously().then((res) {
      debugPrint('👤 Supabase Auth OK: Anonymous user ${res.user?.id}');
    }).catchError((e) {
      debugPrint('⚠️ Supabase Auth error: $e');
    });
  } else {
    debugPrint('👤 Supabase Auth OK: Active user ${client.auth.currentUser?.id}');
  }

  return client;
}
