import 'package:budget_app/core/format/money.dart';
import 'package:budget_app/core/prefs/text_pref.dart';
import 'package:budget_app/features/ai_provider/data/ai_provider_store.dart';
import 'package:budget_app/features/ai_provider/data/secret_store.dart';
import 'package:budget_app/features/ai_provider/models/ai_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_provider_adapter.dart';

void main() {
  late InMemorySecretStore secrets;
  late InMemoryTextPref prefs;
  late FakeProviderAdapter gemini;
  late FakeProviderAdapter openAi;
  late AiProviderStore store;

  AiProviderStore newStore() => AiProviderStore(
        secrets: secrets,
        prefs: prefs,
        adapters: {AiProviderKind.gemini: gemini, AiProviderKind.openAi: openAi},
      );

  setUp(() async {
    secrets = InMemorySecretStore();
    prefs = InMemoryTextPref();
    gemini = FakeProviderAdapter();
    openAi = FakeProviderAdapter();
    store = newStore();
    await store.load();
  });

  Future<List<String>> chat() => store.consultantClient
      .streamConsultantResponse(prompt: 'Hi', contextSummary: '', currency: Currency.fallback)
      .toList();

  const key = 'gem-key-123456789';

  test('a key that passes Test and Save is Connected, active, and survives a restart', () async {
    final models = await store.listModels(AiProviderKind.gemini, key);
    expect(models, ['model-a', 'model-b']);
    final failure = await store.check(AiProviderKind.gemini, 'model-b', key);
    await store.save(AiProviderKind.gemini, apiKey: key, model: 'model-b', failure: failure);

    final reloaded = await newStore().load();
    expect(reloaded.active, AiProviderKind.gemini);
    expect(reloaded.activeProvider!.status, KeyStatus.connected);
    expect(reloaded.activeProvider!.model, 'model-b');
    expect(reloaded.activeProvider!.maskedKey, '••••6789');
  });

  test('a key saved without a test that could not reach the provider is Not verified', () async {
    gemini.pingFailure = const ProviderFailure(ConnectionOutcome.unreachable);
    final failure = await store.check(AiProviderKind.gemini, 'model-a', key);
    final settings = await store.save(AiProviderKind.gemini, apiKey: key, model: 'model-a', failure: failure);

    expect(settings.activeProvider!.status, KeyStatus.notVerified);
    expect(settings.activeProvider!.statusLabel, 'Not verified');
  });

  test('a key saved anyway after the ping fails keeps the failure as its status', () async {
    gemini.pingFailure = const ProviderFailure(ConnectionOutcome.noCredit, 'insufficient_quota');
    final failure = await store.check(AiProviderKind.gemini, 'model-a', key);
    final settings = await store.save(AiProviderKind.gemini, apiKey: key, model: 'model-a', failure: failure);

    expect(settings.activeProvider!.status, KeyStatus.failed);
    expect(settings.activeProvider!.statusLabel, 'No credit or rate-limited');
    expect(settings.activeProvider!.message, 'insufficient_quota');
  });

  test('Set active switches which provider the Consultant answers with, keeping both keys', () async {
    await store.save(AiProviderKind.gemini, apiKey: key, model: 'model-a');
    await store.save(AiProviderKind.openAi, apiKey: 'sk-openai-987654321', model: 'gpt-x');
    expect(store.settings.active, AiProviderKind.openAi);

    final settings = await store.setActive(AiProviderKind.gemini);
    await chat();

    expect(settings.active, AiProviderKind.gemini);
    expect(settings.saved.keys, containsAll([AiProviderKind.gemini, AiProviderKind.openAi]));
    expect(gemini.lastChatKey, key);
    expect(openAi.lastChatKey, isNull);
    expect(store.consultantClient.answeredBy, 'Google Gemini · model-a');
    expect((await newStore().load()).active, AiProviderKind.gemini);
  });

  test('removing the active key hands the Consultant to the other saved provider', () async {
    await store.save(AiProviderKind.gemini, apiKey: key, model: 'model-a');
    await store.save(AiProviderKind.openAi, apiKey: 'sk-openai-987654321', model: 'gpt-x');

    final settings = await store.remove(AiProviderKind.openAi);

    expect(settings.active, AiProviderKind.gemini);
    expect(settings.saved.keys, [AiProviderKind.gemini]);
    expect(await secrets.read('ai_provider_key_openAi'), isNull);
    expect((await newStore().load()).saved.keys, [AiProviderKind.gemini]);
  });

  test('removing the only key turns the Consultant off', () async {
    await store.save(AiProviderKind.gemini, apiKey: key, model: 'model-a');

    await store.remove(AiProviderKind.gemini);

    expect(store.consultantClient.isConfigured, isFalse);
    expect(store.consultantClient.answeredBy, isNull);
  });

  test('a chat refused with 401 flips the active key to Key not accepted', () async {
    await store.save(AiProviderKind.gemini, apiKey: key, model: 'model-a');
    gemini.chatFailure = const ProviderFailure(ConnectionOutcome.keyNotAccepted, 'API key not valid');
    final changes = <AiProviderSettings>[];
    final sub = store.changes.listen(changes.add);

    await expectLater(chat(), throwsA(isA<ProviderFailure>()));
    await pumpEventQueue();

    expect(store.settings.activeProvider!.status, KeyStatus.failed);
    expect(store.settings.activeProvider!.statusLabel, 'Key not accepted');
    expect(changes.last.activeProvider!.statusLabel, 'Key not accepted');
    expect((await newStore().load()).activeProvider!.statusLabel, 'Key not accepted');
    await sub.cancel();
  });

  test('a chat that cannot reach the provider leaves the status as it was', () async {
    await store.save(AiProviderKind.gemini, apiKey: key, model: 'model-a');
    gemini.chatFailure = const ProviderFailure(ConnectionOutcome.unreachable);

    await expectLater(chat(), throwsA(isA<ProviderFailure>()));

    expect(store.settings.activeProvider!.status, KeyStatus.connected);
  });

  test('a chat reply makes a key saved offline Connected', () async {
    await store.save(
      AiProviderKind.gemini,
      apiKey: key,
      model: 'model-a',
      failure: const ProviderFailure(ConnectionOutcome.unreachable),
    );

    expect(await chat(), ['Hello ', 'there']);

    expect(store.settings.activeProvider!.status, KeyStatus.connected);
    expect((await newStore().load()).activeProvider!.status, KeyStatus.connected);
  });

  test('a chat the provider accepts but answers empty still makes the key Connected', () async {
    await store.save(
      AiProviderKind.gemini,
      apiKey: key,
      model: 'model-a',
      failure: const ProviderFailure(ConnectionOutcome.unreachable),
    );
    gemini.reply = const [];

    expect(await chat(), isEmpty);

    expect(store.settings.activeProvider!.status, KeyStatus.connected);
  });
}
