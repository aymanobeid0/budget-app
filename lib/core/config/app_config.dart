/// Build-time configuration, supplied from root `.env` via `--dart-define-from-file=.env`.
class AppConfig {
  const AppConfig._();

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get hasSupabase => supabaseAnonKey.isNotEmpty;

  static const geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');

  static bool get hasGemini => geminiApiKey.isNotEmpty;
}
