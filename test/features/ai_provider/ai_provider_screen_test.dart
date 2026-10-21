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
  late FakeProviderAdapter gemini;

  // Made inside each test, so the store's change stream runs in the test's
  // fake-async zone and reaches the screen on pump.
  void newCubit() {
    gemini = FakeProviderAdapter();
    cubit = AiProviderCubit(AiProviderStore(
      secrets: InMemorySecretStore(),
      prefs: InMemoryTextPref(),
      adapters: {
        AiProviderKind.gemini: gemini,
        AiProviderKind.openAi: FakeProviderAdapter(),
        AiProviderKind.openRouter: FakeProviderAdapter(),
      },
    ));
    addTearDown(cubit.close);
  }

  Widget screen() => MaterialApp(home: BlocProvider.value(value: cubit, child: const AiProviderScreen()));

  /// Shows the provider screen on a phone-sized view and opens [kind]'s editor.
  Future<void> openEditor(WidgetTester tester, AiProviderKind kind) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('provider-row-${kind.name}')));
    await tester.pumpAndSettle();
  }

  Future<void> tapInSheet(WidgetTester tester, String key) async {
    await tester.ensureVisible(find.byKey(Key(key)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key(key)));
    await tester.pumpAndSettle();
  }

  Finder inTestResult(String text) =>
      find.descendant(of: find.byKey(const Key('test-result')), matching: find.text(text));

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

  testWidgets("a saved key that failed shows the provider's message in its editor", (tester) async {
    newCubit();
    await cubit.save(
      AiProviderKind.gemini,
      apiKey: 'gem-key-123456789',
      model: 'model-a',
      failure: const ProviderFailure(ConnectionOutcome.noCredit, 'You exceeded your current quota.'),
    );
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('provider-row-gemini')));
    await tester.pumpAndSettle();

    expect(find.text('No credit or rate-limited'), findsWidgets);
    expect(find.text('You exceeded your current quota.'), findsOneWidget);
  });

  testWidgets('a key that passes Test unlocks the model picker with the default model picked', (tester) async {
    newCubit();
    gemini.models = const ['gemini-2.5-flash', 'gemini-2.5-pro', 'gemma-3'];
    await openEditor(tester, AiProviderKind.gemini);
    final picker = find.byType(DropdownButton<String>);
    expect(tester.widget<DropdownButton<String>>(picker).onChanged, isNull);

    await tester.enterText(find.byKey(const Key('provider-key-field')), 'gem-key-123456789');
    await tapInSheet(tester, 'test-connection-btn');

    expect(inTestResult('Connected · 3 models'), findsOneWidget);
    expect(tester.widget<DropdownButton<String>>(picker).onChanged, isNotNull);
    expect(tester.widget<DropdownButton<String>>(picker).value, 'gemini-2.5-flash');
  });

  testWidgets("a key that fails Test shows the outcome and the provider's message", (tester) async {
    newCubit();
    gemini.listFailure = const ProviderFailure(ConnectionOutcome.keyNotAccepted, 'API key not valid.');
    await openEditor(tester, AiProviderKind.gemini);

    await tester.enterText(find.byKey(const Key('provider-key-field')), 'bad-key-123456789');
    await tapInSheet(tester, 'test-connection-btn');

    expect(inTestResult('Key not accepted'), findsOneWidget);
    expect(inTestResult('API key not valid.'), findsOneWidget);
  });

  testWidgets('Save when the model does not answer asks first, then saves anyway', (tester) async {
    newCubit();
    gemini.pingFailure = const ProviderFailure(ConnectionOutcome.noCredit, 'Quota exceeded');
    await openEditor(tester, AiProviderKind.gemini);

    await tester.enterText(find.byKey(const Key('provider-key-field')), 'gem-key-123456789');
    await tapInSheet(tester, 'save-provider-btn');

    expect(find.textContaining('Save the key anyway?'), findsOneWidget);
    expect(find.textContaining('Quota exceeded'), findsOneWidget);
    await tester.tap(find.byKey(const Key('save-anyway-btn')));
    await tester.pumpAndSettle();

    expect(cubit.state.active, AiProviderKind.gemini);
    expect(cubit.state.activeProvider!.statusLabel, 'No credit or rate-limited');
    expect(find.byKey(const Key('save-provider-btn')), findsNothing); // the sheet closed
    expect(find.text('••••6789 · gemini-2.5-flash · active'), findsOneWidget);
  });

  testWidgets('OpenRouter asks for a typed model id instead of a picker', (tester) async {
    newCubit();
    await openEditor(tester, AiProviderKind.openRouter);

    expect(find.byKey(const Key('provider-model-id-field')), findsOneWidget);
    final field = tester.widget<TextField>(find.byKey(const Key('provider-model-id-field')));
    expect(field.controller!.text, 'openai/gpt-4.1-mini');
    expect(find.byType(DropdownButton<String>), findsNothing);
  });
}
