import 'package:budget_app/core/prefs/text_pref.dart';
import 'package:budget_app/features/ai_provider/cubit/ai_provider_cubit.dart';
import 'package:budget_app/features/ai_provider/data/ai_provider_store.dart';
import 'package:budget_app/features/ai_provider/data/secret_store.dart';
import 'package:budget_app/features/ai_provider/models/ai_provider.dart';
import 'package:budget_app/features/ai_provider/ui/ai_provider_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_provider_adapter.dart';

void main() {
  late AiProviderCubit cubit;

  // Made inside each test, so the store's change stream runs in the test's
  // fake-async zone and reaches the screen on pump.
  void newCubit() {
    cubit = AiProviderCubit(AiProviderStore(
      secrets: InMemorySecretStore(),
      prefs: InMemoryTextPref(),
      adapters: {AiProviderKind.gemini: FakeProviderAdapter(), AiProviderKind.openAi: FakeProviderAdapter()},
    ));
    addTearDown(cubit.close);
  }

  Widget screen() => MaterialApp(home: BlocProvider.value(value: cubit, child: const AiProviderScreen()));

  testWidgets('Set active on a saved provider makes it the one the Consultant answers with', (tester) async {
    newCubit();
    await cubit.save(AiProviderKind.gemini, apiKey: 'gem-key-123456789', model: 'model-a');
    await cubit.save(AiProviderKind.openAi, apiKey: 'sk-openai-987654321', model: 'gpt-x');
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    expect(find.text('••••4321 · gpt-x · active'), findsOneWidget);

    await tester.tap(find.byKey(const Key('provider-row-gemini')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('set-active-btn')));
    await tester.pumpAndSettle();

    expect(cubit.state.active, AiProviderKind.gemini);
    expect(find.text('••••6789 · model-a · active'), findsOneWidget);
    expect(find.text('••••4321 · gpt-x'), findsOneWidget);
  });

  testWidgets('the active provider offers no Set active', (tester) async {
    newCubit();
    await cubit.save(AiProviderKind.gemini, apiKey: 'gem-key-123456789', model: 'model-a');
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('provider-row-gemini')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('set-active-btn')), findsNothing);
  });
}
