import 'dart:async';

import 'package:budget_app/core/database/app_database.dart';
import 'package:budget_app/core/format/money.dart';
import 'package:budget_app/core/theme/empty_state.dart';
import 'package:budget_app/features/ai_provider/models/ai_provider.dart';
import 'package:budget_app/features/categories/category_store.dart';
import 'package:budget_app/features/consultant/cubit/consultant_cubit.dart';
import 'package:budget_app/features/consultant/data/consultant_client.dart';
import 'package:budget_app/features/consultant/models/chat_message.dart';
import 'package:budget_app/features/consultant/ui/consultant_screen.dart';
import 'package:budget_app/features/expenses/expense.dart';
import 'package:budget_app/features/expenses/expense_ledger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class FakeConsultantClient implements ConsultantClient {
  FakeConsultantClient({
    this.chunks = const ['Your highest spend was on ', 'Food.'],
    this.shouldThrow = false,
    this.isConfigured = true,
  });

  List<String> chunks;
  bool shouldThrow;
  String? lastPrompt;

  @override
  bool isConfigured;

  @override
  String? answeredBy = 'Google Gemini · gemini-2.5-flash';

  /// Thrown instead of answering, when set.
  Object? failure;

  @override
  Stream<String> streamConsultantResponse({
    required String prompt,
    required String contextSummary,
    required Currency currency,
    List<ChatMessage> conversationHistory = const [],
  }) async* {
    lastPrompt = prompt;
    if (shouldThrow) {
      throw Exception('Network unreachable or invalid API key');
    }
    if (failure != null) throw failure!;
    for (final chunk in chunks) {
      yield chunk;
    }
  }
}

void main() {
  setUpAll(sqfliteFfiInit);

  late AppDatabase db;
  late ExpenseLedger ledger;
  late CategoryStore categoryStore;
  late FakeConsultantClient client;
  late ConsultantCubit cubit;

  setUp(() async {
    db = await AppDatabase.open(
      factory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
    ledger = ExpenseLedger(db);
    categoryStore = CategoryStore(db);
    client = FakeConsultantClient();
    cubit = ConsultantCubit(
      ledger: ledger,
      categoryStore: categoryStore,
      client: client,
    );
  });

  tearDown(() async {
    await cubit.close();
    await db.close();
  });

  Widget buildTestWidget() {
    return MaterialApp(
      home: BlocProvider<ConsultantCubit>.value(
        value: cubit,
        child: const ConsultantScreen(),
      ),
    );
  }

  testWidgets('renders welcome hero with suggested questions when chat is empty', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Meet Your Expense Consultant'), findsOneWidget);
    expect(find.text('Where did I spend the most?'), findsWidgets);
    expect(find.byKey(const Key('consultant-input-field')), findsOneWidget);
    expect(find.byKey(const Key('consultant-send-btn')), findsOneWidget);

    // Nothing to clear yet: Clear chat does nothing.
    await tester.tap(find.byKey(const Key('clear-chat-btn')));
    await tester.pumpAndSettle();
    expect(find.text('Clear this conversation?'), findsNothing);
  });

  testWidgets('before the first message the shared empty state offers the suggested questions', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    final empty = find.byType(EmptyState);
    expect(find.descendant(of: empty, matching: find.text('Where did I spend the most?')), findsOneWidget);
  });

  testWidgets('without an AI Provider key the Consultant asks to connect one before anything is typed', (tester) async {
    client.isConfigured = false;

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    final empty = find.byType(EmptyState);
    expect(find.descendant(of: empty, matching: find.text('Connect an AI provider')), findsOneWidget);
    expect(find.text('Where did I spend the most?'), findsNothing);
    expect(tester.widget<TextField>(find.byKey(const Key('consultant-input-field'))).enabled, isFalse);
  });

  testWidgets('tapping a suggested question sends prompt and renders messages', (tester) async {
    // Seed an expense
    await categoryStore.loadCategories();
    await ledger.logExpense(Expense(
      id: 'e1',
      amountMinor: 4500,
      categoryId: 'cat_food',
      spentOn: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Tap first suggested question in hero list
    await tester.tap(find.text('Where did I spend the most?').first);
    await tester.pump(); // Start streaming
    await tester.pump(const Duration(milliseconds: 100)); // Finish streaming
    await tester.pumpAndSettle();

    // User message bubble
    expect(find.text('Where did I spend the most?'), findsWidgets);
    // Assistant message response
    expect(find.text('Your highest spend was on Food.'), findsOneWidget);

    // Suggestions should now be in horizontal chip bar
    expect(find.byKey(const Key('consultant-chip-0')), findsOneWidget);
  });

  testWidgets('typing and sending custom prompt renders conversation turn', (tester) async {
    client.chunks = ['You have 0 debt. Good job!'];

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Enter custom query
    await tester.enterText(find.byKey(const Key('consultant-input-field')), 'Do I have any debt?');
    await tester.pumpAndSettle();

    // Tap send button
    await tester.tap(find.byKey(const Key('consultant-send-btn')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(find.text('Do I have any debt?'), findsOneWidget);
    expect(find.text('You have 0 debt. Good job!'), findsOneWidget);
  });

  testWidgets('renders error banner with retry option on client failure', (tester) async {
    client.shouldThrow = true;

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('consultant-input-field')), 'Hello');
    await tester.tap(find.byKey(const Key('consultant-send-btn')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    // Error banner should be visible
    expect(find.text('Retry'), findsOneWidget);
    expect(find.textContaining('Network unreachable'), findsWidgets);
  });

  testWidgets('clearing chat resets messages back to empty state', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Send a message first
    await tester.enterText(find.byKey(const Key('consultant-input-field')), 'Test query');
    await tester.tap(find.byKey(const Key('consultant-send-btn')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(find.text('Test query'), findsOneWidget);

    // Clear chat in the header
    await tester.tap(find.byTooltip('Clear chat'));
    await tester.pumpAndSettle();

    expect(find.text('Clear this conversation?'), findsOneWidget);

    // Confirm
    await tester.tap(find.text('Clear chat').last);
    await tester.pumpAndSettle();

    // Should return to welcome hero
    expect(find.text('Meet Your Expense Consultant'), findsOneWidget);
    expect(find.text('Test query'), findsNothing);
  });

  Future<void> send(WidgetTester tester, String text) async {
    await tester.enterText(find.byKey(const Key('consultant-input-field')), text);
    await tester.tap(find.byKey(const Key('consultant-send-btn')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
  }

  testWidgets('switching provider mid-conversation shows who answers now between the turns', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();
    await send(tester, 'First question');

    client.answeredBy = 'OpenAI · gpt-4.1-mini';
    await send(tester, 'Second question');

    expect(find.text('First question'), findsOneWidget);
    expect(find.text('Now answering with OpenAI · gpt-4.1-mini'), findsOneWidget);
    expect(find.text('Second question'), findsOneWidget);
  });

  testWidgets('a chat the provider refuses shows why, with a link to the AI provider settings', (tester) async {
    client.failure = const ProviderFailure(ConnectionOutcome.keyNotAccepted, 'API key not valid');
    final router = GoRouter(routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => BlocProvider<ConsultantCubit>.value(value: cubit, child: const ConsultantScreen()),
      ),
      GoRoute(path: '/ai-provider', builder: (_, _) => const Text('AI provider screen')),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await send(tester, 'Hello');

    expect(find.textContaining('Key not accepted'), findsWidgets);
    expect(find.textContaining('API key not valid'), findsWidgets);
    await tester.tap(find.byKey(const Key('consultant-settings-link')));
    await tester.pumpAndSettle();
    expect(find.text('AI provider screen'), findsOneWidget);
  });
}
