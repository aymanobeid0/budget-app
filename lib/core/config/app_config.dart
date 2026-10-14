/// Build-time configuration, supplied with `--dart-define`.
///
/// Defaults target the local Supabase Docker stack (ADR 0005).
/// Android emulators must pass `SUPABASE_URL=http://10.0.2.2:54321`.
class AppConfig {
  const AppConfig._();

  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'http://127.0.0.1:54321',
  );

  /// Printed by `supabase start` / `supabase status`.
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get hasSupabase => supabaseAnonKey.isNotEmpty;

  /// Google Gemini API key passed via `--dart-define=GEMINI_API_KEY=...`
  static const geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');

  static bool get hasGemini => geminiApiKey.isNotEmpty;
}
