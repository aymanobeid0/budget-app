/// Build-time configuration, supplied with `--dart-define`.
///
/// Defaults target the local Supabase Docker stack (ADR 0005).
/// Android emulators must pass `SUPABASE_URL=http://10.0.2.2:54321`.
class AppConfig {
  const AppConfig._();

  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://api.itlabservice.com',
  );

  /// Printed by `supabase start` / `supabase status`.
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpYXQiOjE3OTE5OTg1NjQsImV4cCI6MTg5MzQ1NjAwMCwicm9sZSI6ImFub24iLCJpc3MiOiJzdXBhYmFzZSJ9.9eNXKCYAG4MpxmwbdQ1yBg0JTC6R9F_dXrGFIdKsEuI',
  );

  static bool get hasSupabase => supabaseAnonKey.isNotEmpty;

  /// Google Gemini API key passed via `--dart-define=GEMINI_API_KEY=...`
  static const geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');

  static bool get hasGemini => geminiApiKey.isNotEmpty;
}
