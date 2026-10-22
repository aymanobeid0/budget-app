import 'package:budget_app/app.dart';
import 'package:budget_app/core/database/app_database.dart';
import 'package:budget_app/core/prefs/text_pref.dart';
import 'package:budget_app/features/ai_provider/data/ai_provider_store.dart';
import 'package:budget_app/features/ai_provider/data/secret_store.dart';
import 'package:budget_app/features/ai_provider/models/ai_provider.dart';
import 'package:budget_app/features/categories/category_store.dart';
import 'package:budget_app/features/expenses/expense_ledger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'fake_provider_adapter.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  late AppDatabase db;
  late AiProviderStore store;

  setUp(() async {
    db = await AppDatabase.open(factory: databaseFactoryFfiNoIsolate, path: inMemoryDatabasePath);
    store = AiProviderStore(
      secrets: InMemorySecretStore(),
      prefs: InMemoryTextPref(),
      adapters: {AiProviderKind.gemini: FakeProviderAdapter(), AiProviderKind.openAi: FakeProviderAdapter()},
    );
    await store.load();
  });

  tearDown(() => db.close());

  /// Launches the app and opens Settings, scrolled to the AI provider row.
  Future<Finder> openSettings(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(BudgetApp(
      categoryStore: CategoryStore(db),
      expenseLedger: ExpenseLedger(db),
      aiProviderStore: store,
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-settings')));
    await tester.pumpAndSettle();
    final row = find.byKey(const Key('profile-ai-provider-row'));
    await tester.ensureVisible(row);
    await tester.pumpAndSettle();
    return row;
  }

  testWidgets('with no key saved the row invites connecting one', (tester) async {
    final row = await openSettings(tester);

    expect(find.descendant(of: row, matching: find.text('Connect your own key for the Consultant')), findsOneWidget);
  });

  testWidgets('with a key saved the row names the active provider, its model and status', (tester) async {
    await store.save(
      AiProviderKind.gemini,
      apiKey: 'gem-key-123456789',
      model: 'model-a',
      failure: const ProviderFailure(ConnectionOutcome.keyNotAccepted, 'API key not valid'),
    );

    final row = await openSettings(tester);

    expect(find.descendant(of: row, matching: find.text('Google Gemini · model-a')), findsOneWidget);
    expect(find.descendant(of: row, matching: find.text('Key not accepted')), findsOneWidget);
  });

  testWidgets('tapping the row opens the AI provider screen', (tester) async {
    final row = await openSettings(tester);

    await tester.tap(row);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('ai-provider-screen')), findsOneWidget);
    expect(find.byKey(const Key('provider-row-gemini')), findsOneWidget);
  });
}
