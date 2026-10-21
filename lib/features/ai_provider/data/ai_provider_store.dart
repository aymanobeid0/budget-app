import 'dart:convert';

import '../../../core/format/money.dart';
import '../../../core/prefs/text_pref.dart';
import '../../consultant/data/consultant_client.dart';
import '../../consultant/models/chat_message.dart';
import '../models/ai_provider.dart';
import 'provider_adapter.dart';
import 'secret_store.dart';

/// The user's AI Providers: which keys are saved, which one the Consultant
/// answers with, and whether each key works. Keys live in [SecretStore]
/// only; the rest (active provider, model, status) in one JSON pref.
class AiProviderStore {
  AiProviderStore({
    required this._secrets,
    required this._prefs,
    required this._adapters,
  });

  final SecretStore _secrets;
  final TextPref _prefs;
  final Map<AiProviderKind, ProviderAdapter> _adapters;

  final _keys = <AiProviderKind, String>{};
  AiProviderSettings _settings = const AiProviderSettings();

  /// What was last loaded or saved.
  AiProviderSettings get settings => _settings;

  /// The providers this build can talk to, in display order.
  List<AiProviderKind> get providers => [for (final kind in AiProviderKind.values) if (_adapters.containsKey(kind)) kind];

  /// Reads the saved setup. A provider whose key is gone from the secure
  /// store is dropped.
  Future<AiProviderSettings> load() async {
    Map<String, dynamic> json = const {};
    try {
      final raw = await _prefs.read();
      if (raw != null && raw.isNotEmpty) json = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      // Unreadable prefs: start with nothing saved.
    }
    final saved = <AiProviderKind, SavedProvider>{};
    final entries = json['providers'] as Map<String, dynamic>? ?? const {};
    for (final kind in providers) {
      final entry = entries[kind.name] as Map<String, dynamic>?;
      final key = await _secrets.read(_secretName(kind));
      if (entry == null || key == null || key.isEmpty) continue;
      _keys[kind] = key;
      saved[kind] = SavedProvider(
        model: entry['model'] as String? ?? kind.defaultModel,
        status: KeyStatus.values.asNameMap()[entry['status']] ?? KeyStatus.notVerified,
        outcome: ConnectionOutcome.values.asNameMap()[entry['outcome']],
        message: entry['message'] as String? ?? '',
        keyHint: _hint(key),
      );
    }
    final active = AiProviderKind.values.asNameMap()[json['active']];
    _settings = AiProviderSettings(active: saved.containsKey(active) ? active : saved.keys.firstOrNull, saved: saved);
    return _settings;
  }

  /// The Test button: lists [kind]'s chat models with [apiKey], or with the
  /// saved key when [apiKey] is null. Throws a [ProviderFailure]. Testing the
  /// saved key also updates its status, so Settings shows what Test found.
  Future<List<String>> listModels(AiProviderKind kind, [String? apiKey]) async {
    final saved = apiKey == null ? _settings.saved[kind] : null;
    try {
      final models = await _adapters[kind]!.listModels(apiKey ?? _keys[kind] ?? '');
      if (saved != null) await _recordStatus(kind, null);
      return models;
    } on ProviderFailure catch (failure) {
      if (saved != null) await _recordStatus(kind, failure);
      rethrow;
    }
  }

  /// The check before saving: a one-token request to [model]. Null when it
  /// answered, otherwise why not.
  Future<ProviderFailure?> check(AiProviderKind kind, String model, [String? apiKey]) async {
    try {
      await _adapters[kind]!.ping(apiKey ?? _keys[kind] ?? '', model);
      return null;
    } on ProviderFailure catch (failure) {
      return failure;
    }
  }

  /// Saves [kind] with [model] and makes it the active provider. [apiKey]
  /// replaces the saved key; null keeps it. [failure] is what [check] found:
  /// none is Connected, unreachable is Not verified, anything else Failed.
  Future<AiProviderSettings> save(
    AiProviderKind kind, {
    String? apiKey,
    required String model,
    ProviderFailure? failure,
  }) async {
    if (apiKey != null) {
      await _secrets.write(_secretName(kind), apiKey);
      _keys[kind] = apiKey;
    }
    final key = _keys[kind];
    if (key == null) throw StateError('No key saved for ${kind.displayName}');
    _settings = AiProviderSettings(
      active: kind,
      saved: {..._settings.saved, kind: _savedProvider(model, key, failure)},
    );
    await _persist();
    return _settings;
  }

  /// Keeps [kind]'s model and key, with the status [failure] implies.
  Future<void> _recordStatus(AiProviderKind kind, ProviderFailure? failure) async {
    final saved = _settings.saved[kind];
    final key = _keys[kind];
    if (saved == null || key == null) return;
    _settings = AiProviderSettings(
      active: _settings.active,
      saved: {..._settings.saved, kind: _savedProvider(saved.model, key, failure)},
    );
    await _persist();
  }

  /// None is Connected, unreachable is Not verified, anything else Failed.
  static SavedProvider _savedProvider(String model, String key, ProviderFailure? failure) => SavedProvider(
        model: model,
        status: switch (failure?.outcome) {
          null => KeyStatus.connected,
          ConnectionOutcome.unreachable => KeyStatus.notVerified,
          _ => KeyStatus.failed,
        },
        outcome: failure?.outcome,
        message: failure?.message ?? '',
        keyHint: _hint(key),
      );

  /// Forgets [kind]'s key. When it was active, another saved provider (if
  /// any) takes over.
  Future<AiProviderSettings> remove(AiProviderKind kind) async {
    await _secrets.delete(_secretName(kind));
    _keys.remove(kind);
    final saved = {..._settings.saved}..remove(kind);
    _settings = AiProviderSettings(
      active: _settings.active == kind ? saved.keys.firstOrNull : _settings.active,
      saved: saved,
    );
    await _persist();
    return _settings;
  }

  /// The Consultant's client: always answers with whichever provider is
  /// active at the time of the call.
  late final ConsultantClient consultantClient = _ActiveProviderClient(this);

  /// The active provider's adapter, key and model, or null when none is
  /// connected.
  ({ProviderAdapter adapter, String apiKey, String model})? _activeSetup() {
    final active = _settings.active;
    final key = active == null ? null : _keys[active];
    final saved = active == null ? null : _settings.saved[active];
    if (active == null || key == null || saved == null) return null;
    return (adapter: _adapters[active]!, apiKey: key, model: saved.model);
  }

  Future<void> _persist() => _prefs.write(jsonEncode({
        'active': _settings.active?.name,
        'providers': {
          for (final MapEntry(:key, :value) in _settings.saved.entries)
            key.name: {
              'model': value.model,
              'status': value.status.name,
              if (value.outcome != null) 'outcome': value.outcome!.name,
              if (value.message.isNotEmpty) 'message': value.message,
            },
        },
      }));

  static String _secretName(AiProviderKind kind) => 'ai_provider_key_${kind.name}';

  /// The last four characters, or nothing for a key too short to hide the rest.
  static String _hint(String key) => key.length < 12 ? '' : key.substring(key.length - 4);
}

class _ActiveProviderClient implements ConsultantClient {
  _ActiveProviderClient(this._store);

  final AiProviderStore _store;

  @override
  bool get isConfigured => _store._activeSetup() != null;

  @override
  Stream<String> streamConsultantResponse({
    required String prompt,
    required String contextSummary,
    required Currency currency,
    List<ChatMessage> conversationHistory = const [],
  }) {
    final setup = _store._activeSetup();
    if (setup == null) {
      return Stream.value('No AI Provider is connected. Add your API key in Settings → AI provider.');
    }
    return setup.adapter.streamReply(
      apiKey: setup.apiKey,
      model: setup.model,
      systemInstruction: consultantSystemInstruction(contextSummary: contextSummary, currency: currency),
      history: conversationHistory,
      prompt: prompt,
    );
  }
}
