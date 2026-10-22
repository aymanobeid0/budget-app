import 'package:bloc_test/bloc_test.dart';
import 'package:budget_app/core/format/money.dart';
import 'package:budget_app/core/prefs/text_pref.dart';
import 'package:budget_app/features/ai_provider/cubit/ai_provider_cubit.dart';
import 'package:budget_app/features/ai_provider/data/ai_provider_store.dart';
import 'package:budget_app/features/ai_provider/data/secret_store.dart';
import 'package:budget_app/features/ai_provider/models/ai_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_provider_adapter.dart';

void main() {
  late FakeProviderAdapter gemini;
  late AiProviderStore store;

  const geminiKey = 'gem-key-123456789';

  setUp(() async {
    gemini = FakeProviderAdapter();
    store = AiProviderStore(
      secrets: InMemorySecretStore(),
      prefs: InMemoryTextPref(),
      adapters: {AiProviderKind.gemini: gemini, AiProviderKind.openAi: FakeProviderAdapter()},
    );
    await store.load();
  });

  blocTest<AiProviderCubit, AiProviderSettings>(
    'saving a key that passed the ping makes it the active, Connected provider',
    build: () => AiProviderCubit(store),
    act: (cubit) async {
      final failure = await cubit.ping(AiProviderKind.gemini, 'model-a', geminiKey);
      await cubit.save(AiProviderKind.gemini, apiKey: geminiKey, model: 'model-a', failure: failure);
    },
    expect: () => [
      isA<AiProviderSettings>()
          .having((s) => s.active, 'active', AiProviderKind.gemini)
          .having((s) => s.activeProvider!.status, 'status', KeyStatus.connected),
    ],
  );

  blocTest<AiProviderCubit, AiProviderSettings>(
    "ping reports why the model didn't answer",
    build: () => AiProviderCubit(store),
    setUp: () => gemini.pingFailure = const ProviderFailure(ConnectionOutcome.modelNotFound, 'no such model'),
    act: (cubit) async {
      final failure = await cubit.ping(AiProviderKind.gemini, 'nope', geminiKey);
      expect(failure?.outcome, ConnectionOutcome.modelNotFound);
    },
    expect: () => <AiProviderSettings>[],
  );

  blocTest<AiProviderCubit, AiProviderSettings>(
    'lists the providers this build can talk to',
    build: () => AiProviderCubit(store),
    verify: (cubit) => expect(cubit.providers, [AiProviderKind.gemini, AiProviderKind.openAi]),
  );

  blocTest<AiProviderCubit, AiProviderSettings>(
    'a chat the provider refuses shows up in Settings without reopening it',
    setUp: () async {
      await store.save(AiProviderKind.gemini, apiKey: geminiKey, model: 'model-a');
      gemini.chatFailure = const ProviderFailure(ConnectionOutcome.noCredit, 'quota');
    },
    build: () => AiProviderCubit(store),
    act: (cubit) async {
      await expectLater(
        store.consultantClient
            .streamConsultantResponse(prompt: 'Hi', contextSummary: '', currency: Currency.fallback)
            .toList(),
        throwsA(isA<ProviderFailure>()),
      );
    },
    expect: () => [
      isA<AiProviderSettings>()
          .having((s) => s.activeProvider!.statusLabel, 'status', 'No credit or rate-limited')
          .having((s) => s.activeProvider!.message, 'message', 'quota'),
    ],
  );

  blocTest<AiProviderCubit, AiProviderSettings>(
    'Set active makes another saved provider the active one',
    setUp: () async {
      await store.save(AiProviderKind.gemini, apiKey: geminiKey, model: 'model-a');
      await store.save(AiProviderKind.openAi, apiKey: 'sk-openai-987654321', model: 'gpt-x');
    },
    build: () => AiProviderCubit(store),
    act: (cubit) => cubit.setActive(AiProviderKind.gemini),
    expect: () => [
      isA<AiProviderSettings>().having((s) => s.active, 'active', AiProviderKind.gemini),
    ],
  );

  blocTest<AiProviderCubit, AiProviderSettings>(
    'removing the active key hands over to the other saved provider',
    setUp: () async {
      await store.save(AiProviderKind.gemini, apiKey: geminiKey, model: 'model-a');
      await store.save(AiProviderKind.openAi, apiKey: 'sk-openai-987654321', model: 'gpt-x');
    },
    build: () => AiProviderCubit(store),
    act: (cubit) => cubit.remove(AiProviderKind.openAi),
    expect: () => [
      isA<AiProviderSettings>()
          .having((s) => s.active, 'active', AiProviderKind.gemini)
          .having((s) => s.saved.keys, 'saved', [AiProviderKind.gemini]),
    ],
  );
}
