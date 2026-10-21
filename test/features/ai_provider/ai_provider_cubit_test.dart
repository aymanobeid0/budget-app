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
  late AiProviderCubit cubit;

  setUp(() async {
    gemini = FakeProviderAdapter();
    store = AiProviderStore(
      secrets: InMemorySecretStore(),
      prefs: InMemoryTextPref(),
      adapters: {AiProviderKind.gemini: gemini, AiProviderKind.openAi: FakeProviderAdapter()},
    );
    cubit = AiProviderCubit(store);
    await cubit.load();
  });

  tearDown(() => cubit.close());

  test('a chat the provider refuses shows up in Settings without reopening it', () async {
    await cubit.save(AiProviderKind.gemini, apiKey: 'gem-key-123456789', model: 'model-a');
    gemini.chatFailure = const ProviderFailure(ConnectionOutcome.noCredit, 'quota');

    await expectLater(
      store.consultantClient
          .streamConsultantResponse(prompt: 'Hi', contextSummary: '', currency: Currency.fallback)
          .toList(),
      throwsA(isA<ProviderFailure>()),
    );
    await pumpEventQueue();

    expect(cubit.state.activeProvider!.statusLabel, 'No credit or rate-limited');
  });

  test('Set active makes another saved provider the active one', () async {
    await cubit.save(AiProviderKind.gemini, apiKey: 'gem-key-123456789', model: 'model-a');
    await cubit.save(AiProviderKind.openAi, apiKey: 'sk-openai-987654321', model: 'gpt-x');

    await cubit.setActive(AiProviderKind.gemini);

    expect(cubit.state.active, AiProviderKind.gemini);
  });
}
