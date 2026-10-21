/// The AI Providers a user can connect with their own API key.
enum AiProviderKind {
  gemini('Google Gemini', 'gemini-2.5-flash', 'aistudio.google.com/apikey');

  const AiProviderKind(this.displayName, this.defaultModel, this.keyUrl);

  final String displayName;

  /// The cheap chat model preselected after a key passes the test.
  final String defaultModel;

  /// Where the user gets a key, shown under the key field.
  final String keyUrl;
}

/// What a test, a save check or a chat call found out about a key.
enum ConnectionOutcome {
  connected('Connected'),
  keyNotAccepted('Key not accepted'),
  noCredit('No credit or rate-limited'),
  modelNotFound('Model not found'),
  unreachable("Can't reach provider"),
  providerError('Provider error');

  const ConnectionOutcome(this.label);

  final String label;

  /// Maps a provider's HTTP status the way every provider means it.
  static ConnectionOutcome fromStatusCode(int code) => switch (code) {
        401 || 403 => keyNotAccepted,
        402 || 429 => noCredit,
        404 => modelNotFound,
        _ => providerError,
      };
}

/// A failed call to a provider: the [outcome] the user sees and the
/// provider's own [message] shown underneath.
class ProviderFailure implements Exception {
  const ProviderFailure(this.outcome, [this.message = '']);

  final ConnectionOutcome outcome;
  final String message;

  @override
  String toString() => message.isEmpty ? outcome.label : '${outcome.label}: $message';
}

/// Whether a saved key is known to work.
enum KeyStatus { connected, notVerified, failed }

/// One provider's saved setup. The key itself lives in the SecretStore;
/// [keyHint] is its last four characters for the masked display.
class SavedProvider {
  const SavedProvider({
    required this.model,
    required this.status,
    required this.keyHint,
    this.outcome,
    this.message = '',
  });

  final String model;
  final KeyStatus status;
  final String keyHint;

  /// Why the key failed, when [status] is [KeyStatus.failed] or
  /// [KeyStatus.notVerified] after an unreachable check.
  final ConnectionOutcome? outcome;
  final String message;

  String get maskedKey => keyHint.isEmpty ? '••••' : '••••$keyHint';

  String get statusLabel => switch (status) {
        KeyStatus.connected => 'Connected',
        KeyStatus.notVerified => 'Not verified',
        KeyStatus.failed => outcome?.label ?? 'Not working',
      };
}

/// Every saved provider and which one the Consultant answers with.
class AiProviderSettings {
  const AiProviderSettings({this.active, this.saved = const {}});

  final AiProviderKind? active;
  final Map<AiProviderKind, SavedProvider> saved;

  SavedProvider? get activeProvider => active == null ? null : saved[active];
}
